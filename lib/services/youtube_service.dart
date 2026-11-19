import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/youtube_video.dart';

/// Real YouTube Data API v3 access for the Makkah TV channel — mirrors the
/// web version's src/services/youtube.js (same channel, same cache TTLs).
class YouTubeService {
  // Supplied at build time: flutter run --dart-define-from-file=env.json
  static const String _apiKey = String.fromEnvironment('YOUTUBE_API_KEY');
  // SHA-1 of the signing certificate registered on the key (env.json).
  static const String _androidCert = String.fromEnvironment('YOUTUBE_ANDROID_CERT');
  static const String _androidPackage = 'com.md.makkatv';
  static const String _iosBundleId = 'com.erstream.MakkahTV';
  static const String _base = 'https://www.googleapis.com/youtube/v3';
  static const Duration _timeout = Duration(seconds: 15);

  // A channel's id / uploads playlist never change, so they're hardcoded
  // instead of burning quota resolving them on every launch.
  static const String channelId = 'UCGJ2xTzBAM-uuxCShVDY88g';
  static const String _uploadsPlaylistId = 'UUGJ2xTzBAM-uuxCShVDY88g';

  static const Duration _viewCountTtl = Duration(minutes: 15);
  static const Duration _listTtl = Duration(hours: 3);

  static const String _viewCountsKey = 'makkah_yt_view_counts';
  static const String _channelKey = 'makkah_yt_channel_videos';
  static const String _latestKey = 'makkah_yt_latest_videos';
  static const String _playlistsKey = 'makkah_yt_playlists';
  static String _playlistKey(String id) => 'makkah_yt_playlist_$id';

  static bool get isConfigured => _apiKey.isNotEmpty;

  // ── Helpers ────────────────────────────────────────────────────────────────

  static String? extractVideoId(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return null;
    if (uri.host.contains('youtu.be')) {
      return uri.pathSegments.isNotEmpty ? uri.pathSegments.first : null;
    }
    if (uri.host.contains('youtube.com')) return uri.queryParameters['v'];
    return null;
  }

  /// 1234567 -> "1.2M", 4500 -> "4.5K".
  static String formatViewCount(int n) {
    String trim(double v) => v.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '');
    if (n >= 1000000) return '${trim(n / 1000000)}M';
    if (n >= 1000) return '${trim(n / 1000)}K';
    return '$n';
  }

  /// 3723 -> "1:02:03", 125 -> "2:05".
  static String formatDuration(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    String two(int v) => v.toString().padLeft(2, '0');
    return h > 0 ? '$h:${two(m)}:${two(s)}' : '$m:${two(s)}';
  }

  /// "PT1H2M3S" -> 3723
  static int _parseIsoDuration(String iso) {
    final m = RegExp(r'^PT(?:(\d+)H)?(?:(\d+)M)?(?:(\d+)S)?$').firstMatch(iso);
    if (m == null) return 0;
    int g(int i) => int.tryParse(m.group(i) ?? '') ?? 0;
    return g(1) * 3600 + g(2) * 60 + g(3);
  }

  static String _bestThumb(Map? thumbs) {
    if (thumbs == null) return '';
    for (final k in ['high', 'medium', 'default']) {
      final url = (thumbs[k] as Map?)?['url'];
      if (url != null) return url.toString();
    }
    return '';
  }

  // An app-restricted API key only accepts REST calls that identify the app,
  // and plain HTTP requests don't do that on their own.
  static Map<String, String> get _appHeaders {
    if (Platform.isAndroid) {
      return {
        'X-Android-Package': _androidPackage,
        if (_androidCert.isNotEmpty) 'X-Android-Cert': _androidCert.replaceAll(':', '').toUpperCase(),
      };
    }
    if (Platform.isIOS) return {'X-Ios-Bundle-Identifier': _iosBundleId};
    return {};
  }

  /// GET with retries: right after launch (or on flaky Wi-Fi) the first
  /// request often fails with a DNS/socket error even though the network is
  /// fine a second later. Retries network errors / timeouts / 5xx; API
  /// errors like 403 (quota, key) fail fast.
  static Future<Map<String, dynamic>> _get(String path, Map<String, String> params) async {
    final uri = Uri.parse('$_base/$path').replace(queryParameters: {...params, 'key': _apiKey});
    Object lastError = Exception('YouTube API request failed');
    for (var attempt = 0; attempt < 3; attempt++) {
      if (attempt > 0) await Future.delayed(Duration(milliseconds: 1500 * attempt));
      try {
        final res = await http.get(uri, headers: _appHeaders).timeout(_timeout);
        if (res.statusCode == 200) {
          return json.decode(res.body) as Map<String, dynamic>;
        }
        final error = Exception('YouTube API ${res.statusCode}: ${res.body}');
        if (res.statusCode < 500) throw _ApiError(error);
        lastError = error;
      } on _ApiError catch (e) {
        throw e.error;
      } catch (e) {
        lastError = e; // SocketException, TimeoutException, ClientException…
      }
    }
    throw lastError;
  }

  // ── Cache (shared_preferences) ─────────────────────────────────────────────

  /// [allowStale] returns an expired cache too — used as an offline
  /// fallback so a failed refresh still shows the last known videos.
  static Future<List<Map<String, dynamic>>?> _readList(String key, {bool allowStale = false}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(key);
      if (raw == null) return null;
      final decoded = json.decode(raw) as Map<String, dynamic>;
      final ts = DateTime.fromMillisecondsSinceEpoch((decoded['ts'] as num).toInt());
      if (!allowStale && DateTime.now().difference(ts) > _listTtl) return null;
      final list = (decoded['list'] as List).cast<Map<String, dynamic>>();
      // Reject an empty list — it was likely written while the API key was missing.
      if (list.isEmpty) return null;
      return list;
    } catch (_) {
      return null;
    }
  }

  static Future<void> _writeList(String key, List<Map<String, dynamic>> list) async {
    // Never cache an empty result — it prevents real data from loading later.
    if (list.isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        key,
        json.encode({'ts': DateTime.now().millisecondsSinceEpoch, 'list': list}),
      );
    } catch (_) {}
  }

  /// Wipes all locally-cached YouTube data so the next call fetches fresh data
  /// from the network. Call this after an API key change or for debugging.
  static Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((k) => k.startsWith('makkah_yt_')).toList();
      for (final k in keys) {
        await prefs.remove(k);
      }
    } catch (_) {}
  }

  // ── View counts ────────────────────────────────────────────────────────────

  /// Returns {videoId: viewCount}. Serves fresh ids from a 15-minute cache and
  /// fetches only the missing/stale ones in a single batched request.
  static Future<Map<String, int>> fetchViewCounts(List<String> videoIds) async {
    final ids = videoIds.where((e) => e.isNotEmpty).toSet().toList();
    if (!isConfigured || ids.isEmpty) return {};

    final prefs = await SharedPreferences.getInstance();
    Map<String, dynamic> cache = {};
    try {
      cache = json.decode(prefs.getString(_viewCountsKey) ?? '{}') as Map<String, dynamic>;
    } catch (_) {}

    final now = DateTime.now().millisecondsSinceEpoch;
    final result = <String, int>{};
    final stale = <String>[];
    for (final id in ids) {
      final entry = cache[id] as Map<String, dynamic>?;
      if (entry != null && now - (entry['ts'] as num) < _viewCountTtl.inMilliseconds) {
        result[id] = (entry['count'] as num).toInt();
      } else {
        stale.add(id);
      }
    }
    if (stale.isEmpty) return result;

    try {
      for (var i = 0; i < stale.length; i += 50) {
        final chunk = stale.sublist(i, (i + 50).clamp(0, stale.length));
        final data = await _get('videos', {'part': 'statistics', 'id': chunk.join(',')});
        for (final item in (data['items'] as List? ?? [])) {
          final id = item['id'].toString();
          final count = int.tryParse(item['statistics']?['viewCount']?.toString() ?? '') ?? 0;
          result[id] = count;
          cache[id] = {'count': count, 'ts': DateTime.now().millisecondsSinceEpoch};
        }
      }
      await prefs.setString(_viewCountsKey, json.encode(cache));
    } catch (_) {
      // Offline: fall back to the last known (expired) counts.
      for (final id in stale) {
        final entry = cache[id] as Map<String, dynamic>?;
        if (entry != null && !result.containsKey(id)) {
          result[id] = (entry['count'] as num).toInt();
        }
      }
    }
    return result;
  }

  // ── Playlist items ─────────────────────────────────────────────────────────

  static Future<(List<YouTubeVideo>, String)> _playlistItemsPage(
      String playlistId, String pageToken, {int maxResults = 50}) async {
    final data = await _get('playlistItems', {
      'part': 'snippet,contentDetails',
      'playlistId': playlistId,
      'maxResults': '$maxResults',
      if (pageToken.isNotEmpty) 'pageToken': pageToken,
    });

    final items = <YouTubeVideo>[];
    for (final item in (data['items'] as List? ?? [])) {
      final videoId = item['contentDetails']?['videoId']?.toString();
      final published = item['contentDetails']?['videoPublishedAt'] ?? item['snippet']?['publishedAt'];
      if (videoId == null || published == null) continue; // private/unpublished
      items.add(YouTubeVideo(
        id: videoId,
        title: fixTitle(item['snippet']?['title']?.toString() ?? ''),
        thumbnail: _bestThumb(item['snippet']?['thumbnails'] as Map?),
        publishedAt: DateTime.tryParse(published.toString()) ?? DateTime.fromMillisecondsSinceEpoch(0),
      ));
    }
    return (items, data['nextPageToken']?.toString() ?? '');
  }

  /// Merges real view counts + durations in, 50 ids per call, in parallel.
  static Future<List<YouTubeVideo>> _withStats(List<YouTubeVideo> items) async {
    final stats = <String, (int, int)>{};
    final futures = <Future<void>>[];
    for (var i = 0; i < items.length; i += 50) {
      final ids = items.sublist(i, (i + 50).clamp(0, items.length)).map((v) => v.id).join(',');
      futures.add(_get('videos', {'part': 'statistics,contentDetails', 'id': ids}).then((data) {
        for (final v in (data['items'] as List? ?? [])) {
          stats[v['id'].toString()] = (
            int.tryParse(v['statistics']?['viewCount']?.toString() ?? '') ?? 0,
            _parseIsoDuration(v['contentDetails']?['duration']?.toString() ?? ''),
          );
        }
      }));
    }
    await Future.wait(futures);
    return items
        .map((v) => v.copyWith(viewCount: stats[v.id]?.$1 ?? 0, duration: stats[v.id]?.$2 ?? 0))
        .toList();
  }

  // ── Latest uploads (home "أحدث البرامج") ───────────────────────────────────

  /// The channel's most recent uploads with real stats. Reuses the full
  /// catalog cache when it already exists.
  static Future<List<YouTubeVideo>> fetchLatestVideos({int limit = 10}) async {
    final catalog = await _readList(_channelKey);
    if (catalog != null && catalog.isNotEmpty) {
      final list = catalog.map(YouTubeVideo.fromJson).toList()
        ..sort((a, b) => b.publishedAt.compareTo(a.publishedAt));
      return list.take(limit).toList();
    }

    final cached = await _readList(_latestKey);
    if (cached != null && cached.length >= limit) {
      return cached.map(YouTubeVideo.fromJson).take(limit).toList();
    }

    if (!isConfigured) return [];
    try {
      final (items, _) = await _playlistItemsPage(_uploadsPlaylistId, '', maxResults: limit);
      final videos = await _withStats(items);
      await _writeList(_latestKey, videos.map((v) => v.toJson()).toList());
      return videos;
    } catch (_) {
      final stale = await _readList(_channelKey, allowStale: true) ??
          await _readList(_latestKey, allowStale: true);
      if (stale == null) return [];
      final list = stale.map(YouTubeVideo.fromJson).toList()
        ..sort((a, b) => b.publishedAt.compareTo(a.publishedAt));
      return list.take(limit).toList();
    }
  }

  // ── Most viewed (home "الأكثر مشاهدة") ─────────────────────────────────────
  // Same as the web's fetchTopChannelVideos: the channel's real top videos.

  static const String _topKey = 'makkah_yt_top_videos';
  // search.list costs 100 quota units per call and the ranking barely moves,
  // so this cache lives much longer than the others.
  static const Duration _topTtl = Duration(hours: 24);
  static final Map<int, Future<List<YouTubeVideo>>> _topInFlight = {};

  // A duration of 0 means a live/upcoming broadcast, not a finished video.
  static List<YouTubeVideo> _rankByViews(Iterable<YouTubeVideo> videos, int limit) =>
      (videos.where((v) => v.duration > 0).toList()
            ..sort((a, b) => b.viewCount.compareTo(a.viewCount)))
          .take(limit)
          .toList();

  static Future<List<YouTubeVideo>> fetchTopVideos({int limit = 7}) async {
    final catalog = await _readList(_channelKey);
    if (catalog != null && catalog.isNotEmpty) {
      return _rankByViews(catalog.map(YouTubeVideo.fromJson), limit);
    }

    final key = '${_topKey}_$limit';
    final cached = await _readTopCache(key);
    if (cached != null) return cached;

    final inFlight = _topInFlight[limit];
    if (inFlight != null) return inFlight;

    final future = () async {
      if (!isConfigured) return <YouTubeVideo>[];
      try {
        // Ask for extra results so live broadcasts filtered out below
        // don't leave the list short.
        final search = await _get('search', {
          'part': 'id',
          'channelId': channelId,
          'type': 'video',
          'order': 'viewCount',
          'maxResults': '${limit + 5}',
        });
        final ids = (search['items'] as List? ?? [])
            .map((e) => e['id']?['videoId']?.toString())
            .whereType<String>()
            .toList();
        if (ids.isEmpty) return <YouTubeVideo>[];

        // Titles come from videos.list because search.list HTML-escapes them.
        final data = await _get('videos', {
          'part': 'snippet,statistics,contentDetails',
          'id': ids.join(','),
        });
        final videos = _rankByViews(
          (data['items'] as List? ?? []).map((v) => YouTubeVideo(
                id: v['id'].toString(),
                title: fixTitle(v['snippet']?['title']?.toString() ?? ''),
                thumbnail: _bestThumb(v['snippet']?['thumbnails'] as Map?),
                publishedAt:
                    DateTime.tryParse(v['snippet']?['publishedAt']?.toString() ?? '') ??
                        DateTime.fromMillisecondsSinceEpoch(0),
                viewCount: int.tryParse(v['statistics']?['viewCount']?.toString() ?? '') ?? 0,
                duration: _parseIsoDuration(v['contentDetails']?['duration']?.toString() ?? ''),
              )),
          limit,
        );
        await _writeList(key, videos.map((v) => v.toJson()).toList());
        return videos;
      } catch (_) {
        // Offline: last known ranking (top cache, else the full catalog).
        final stale = await _readList(key, allowStale: true);
        if (stale != null) return stale.map(YouTubeVideo.fromJson).toList();
        final staleCatalog = await _readList(_channelKey, allowStale: true);
        if (staleCatalog != null) {
          return _rankByViews(staleCatalog.map(YouTubeVideo.fromJson), limit);
        }
        return <YouTubeVideo>[];
      } finally {
        _topInFlight.remove(limit);
      }
    }();
    _topInFlight[limit] = future;
    return future;
  }

  /// Like [_readList] but with the 24h TTL of the top-videos cache.
  static Future<List<YouTubeVideo>?> _readTopCache(String key) async {
    final list = await _readList(key, allowStale: true);
    if (list == null) return null;
    try {
      final prefs = await SharedPreferences.getInstance();
      final decoded = json.decode(prefs.getString(key)!) as Map<String, dynamic>;
      final ts = DateTime.fromMillisecondsSinceEpoch((decoded['ts'] as num).toInt());
      if (DateTime.now().difference(ts) > _topTtl) return null;
    } catch (_) {
      return null;
    }
    return list.map(YouTubeVideo.fromJson).toList();
  }

  // ── Full channel catalog (مكتبة البرامج) ────────────────────────────────────

  static Future<List<YouTubeVideo>>? _channelInFlight;
  static final Set<void Function(List<YouTubeVideo>)> _channelListeners = {};
  static List<YouTubeVideo> _channelSnapshot = [];

  /// Every video ever uploaded to the channel, with real stats. Served from a
  /// 3h cache when possible; concurrent calls share one fetch. [onProgress]
  /// receives the real results as each page lands so the UI can show them
  /// right away instead of waiting for the whole catalog.
  static Future<List<YouTubeVideo>> fetchAllChannelVideos({
    void Function(List<YouTubeVideo>)? onProgress,
  }) async {
    final cached = await _readList(_channelKey);
    if (cached != null) return cached.map(YouTubeVideo.fromJson).toList();

    if (onProgress != null) {
      _channelListeners.add(onProgress);
      if (_channelSnapshot.isNotEmpty) onProgress(List.of(_channelSnapshot));
    }

    final inFlight = _channelInFlight;
    if (inFlight != null) return inFlight;

    _channelSnapshot = [];
    final future = () async {
      if (!isConfigured) return <YouTubeVideo>[];
      final all = <YouTubeVideo>[];
      try {
        var pageToken = '';
        do {
          final (items, next) = await _playlistItemsPage(_uploadsPlaylistId, pageToken);
          all.addAll(await _withStats(items));
          _channelSnapshot = List.of(all);
          for (final cb in List.of(_channelListeners)) {
            cb(List.of(_channelSnapshot));
          }
          pageToken = next;
        } while (pageToken.isNotEmpty);
        await _writeList(_channelKey, all.map((v) => v.toJson()).toList());
      } catch (_) {
        // Return what already streamed in, but don't cache it: a partial
        // catalog would otherwise be served as the full one for 3 hours.
        // Nothing at all (offline) → last known catalog, even if expired.
        if (all.isEmpty) {
          final stale = await _readList(_channelKey, allowStale: true);
          if (stale != null) all.addAll(stale.map(YouTubeVideo.fromJson));
        }
      } finally {
        _channelInFlight = null;
        _channelListeners.clear();
      }
      return all;
    }();
    _channelInFlight = future;
    return future;
  }

  static void removeChannelListener(void Function(List<YouTubeVideo>) cb) =>
      _channelListeners.remove(cb);

  // ── Playlists (قوائم التشغيل) ───────────────────────────────────────────────

  static Future<List<YouTubePlaylist>>? _playlistsInFlight;

  static Future<List<YouTubePlaylist>> fetchChannelPlaylists() async {
    final cached = await _readList(_playlistsKey);
    if (cached != null) return cached.map(YouTubePlaylist.fromJson).toList();

    final inFlight = _playlistsInFlight;
    if (inFlight != null) return inFlight;

    final future = () async {
      if (!isConfigured) return <YouTubePlaylist>[];
      try {
        final playlists = <YouTubePlaylist>[];
        var pageToken = '';
        do {
          final data = await _get('playlists', {
            'part': 'snippet,contentDetails',
            'channelId': channelId,
            'maxResults': '50',
            if (pageToken.isNotEmpty) 'pageToken': pageToken,
          });
          for (final p in (data['items'] as List? ?? [])) {
            playlists.add(YouTubePlaylist(
              id: p['id'].toString(),
              title: fixTitle(p['snippet']?['title']?.toString() ?? ''),
              thumbnail: _bestThumb(p['snippet']?['thumbnails'] as Map?),
              itemCount: (p['contentDetails']?['itemCount'] as num?)?.toInt() ?? 0,
            ));
          }
          pageToken = data['nextPageToken']?.toString() ?? '';
        } while (pageToken.isNotEmpty);
        await _writeList(_playlistsKey, playlists.map((p) => p.toJson()).toList());
        return playlists;
      } catch (_) {
        final stale = await _readList(_playlistsKey, allowStale: true);
        return stale?.map(YouTubePlaylist.fromJson).toList() ?? <YouTubePlaylist>[];
      } finally {
        _playlistsInFlight = null;
      }
    }();
    _playlistsInFlight = future;
    return future;
  }

  static final Map<String, Future<List<YouTubeVideo>>> _playlistVideosInFlight = {};

  /// The real videos inside one playlist, in the playlist's own order.
  static Future<List<YouTubeVideo>> fetchPlaylistVideos(String playlistId) async {
    if (playlistId.isEmpty) return [];
    final cached = await _readList(_playlistKey(playlistId));
    if (cached != null) return cached.map(YouTubeVideo.fromJson).toList();

    final inFlight = _playlistVideosInFlight[playlistId];
    if (inFlight != null) return inFlight;

    final future = () async {
      if (!isConfigured) return <YouTubeVideo>[];
      try {
        final items = <YouTubeVideo>[];
        var pageToken = '';
        do {
          final (page, next) = await _playlistItemsPage(playlistId, pageToken);
          items.addAll(page);
          pageToken = next;
        } while (pageToken.isNotEmpty);
        final videos = await _withStats(items);
        await _writeList(_playlistKey(playlistId), videos.map((v) => v.toJson()).toList());
        return videos;
      } catch (_) {
        final stale = await _readList(_playlistKey(playlistId), allowStale: true);
        return stale?.map(YouTubeVideo.fromJson).toList() ?? <YouTubeVideo>[];
      } finally {
        _playlistVideosInFlight.remove(playlistId);
      }
    }();
    _playlistVideosInFlight[playlistId] = future;
    return future;
  }
}

/// Non-retryable API response (4xx) — see [YouTubeService._get].
class _ApiError implements Exception {
  final Exception error;
  const _ApiError(this.error);
}
