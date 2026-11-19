import 'dart:math';
import 'package:flutter/material.dart';
import '../app_theme.dart';
import '../models/youtube_video.dart';
import '../services/youtube_service.dart';
import '../widgets/library_widgets.dart';
import '../widgets/video_card.dart';

/// "سلاسل البرامج" — the channel's YouTube playlists, same as the web's
/// /series page. Opening a series shows its episodes; playing one keeps the
/// rest of the series under the video.
class ProgramSeriesScreen extends StatefulWidget {
  final VoidCallback? onOpenMenu;
  const ProgramSeriesScreen({super.key, this.onOpenMenu});

  @override
  State<ProgramSeriesScreen> createState() => _ProgramSeriesScreenState();
}

class _ProgramSeriesScreenState extends State<ProgramSeriesScreen> {
  List<YouTubePlaylist>? _playlists; // null = loading
  String _query = '';
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load({int attempt = 0}) async {
    final data = await YouTubeService.fetchChannelPlaylists();
    if (!mounted) return;
    if (data.isEmpty && YouTubeService.isConfigured && attempt < 2) {
      await Future.delayed(Duration(seconds: 3 * (attempt + 1)));
      if (mounted) _load(attempt: attempt + 1);
      return;
    }
    // New random order on every app launch, like the web's useRandomOrder.
    setState(() => _playlists = List.of(data)..shuffle(Random()));
  }

  void _retry() {
    setState(() => _playlists = null);
    _load();
  }

  void _open(YouTubePlaylist p) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => SeriesEpisodesScreen(playlist: p)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(height: MediaQuery.of(context).padding.top),
        LibraryHeader(
          title: 'سلاسل البرامج',
          icon: Icons.layers_rounded,
          hint: 'ابحث عن سلسلة...',
          controller: _searchCtrl,
          query: _query,
          onQueryChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
          onOpenMenu: widget.onOpenMenu,
        ),
        const SizedBox(height: 8),
        Expanded(child: _buildBody()),
      ],
    );
  }

  Widget _buildBody() {
    if (!YouTubeService.isConfigured) {
      return const LibraryMessage('لم يتم إعداد مفتاح YouTube API.');
    }
    final playlists = _playlists;
    if (playlists == null) return const LibrarySkeletonGrid(count: 8);
    if (playlists.isEmpty) {
      return LibraryMessage('تعذر تحميل سلاسل البرامج الآن. تحقق من الاتصال ثم أعد المحاولة.',
          onRetry: _retry);
    }
    final filtered = _query.isEmpty
        ? playlists
        : playlists.where((p) => p.title.toLowerCase().contains(_query)).toList();
    if (filtered.isEmpty) return const LibraryMessage('لا توجد نتائج مطابقة لبحثك.');
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 90),
      gridDelegate: libraryGridDelegate,
      itemCount: filtered.length,
      itemBuilder: (_, i) =>
          PlaylistCard(playlist: filtered[i], onTap: () => _open(filtered[i])),
    );
  }
}

/// Episodes of one series.
class SeriesEpisodesScreen extends StatefulWidget {
  final YouTubePlaylist playlist;
  const SeriesEpisodesScreen({super.key, required this.playlist});

  @override
  State<SeriesEpisodesScreen> createState() => _SeriesEpisodesScreenState();
}

class _SeriesEpisodesScreenState extends State<SeriesEpisodesScreen> {
  static const _pageSize = 24;

  List<YouTubeVideo>? _videos;
  int _visibleCount = _pageSize;
  String _query = '';
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final data = await YouTubeService.fetchPlaylistVideos(widget.playlist.id);
    if (mounted) setState(() => _videos = data);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppColors.lightText;
    final videos = _videos;

    Widget body;
    if (videos == null) {
      body = const LibrarySkeletonGrid(count: 8);
    } else if (videos.isEmpty) {
      body = LibraryMessage('تعذر تحميل حلقات هذه السلسلة أو أنها فارغة.', onRetry: () {
        setState(() => _videos = null);
        _load();
      });
    } else {
      final filtered = _query.isEmpty
          ? videos
          : videos.where((v) => v.title.toLowerCase().contains(_query)).toList();
      body = filtered.isEmpty
          ? const LibraryMessage('لا توجد نتائج مطابقة لبحثك في هذه السلسلة.')
          : LibraryVideoGrid(
              videos: filtered.take(_visibleCount).toList(),
              // The whole series plays under the video, in order.
              queue: filtered,
              queueTitle: widget.playlist.title,
              hasMore: _visibleCount < filtered.length,
              onLoadMore: () => setState(() => _visibleCount += _pageSize),
            );
    }

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
      body: Column(
        children: [
          SizedBox(height: MediaQuery.of(context).padding.top),
          LibraryHeader(
            title: 'سلاسل البرامج',
            icon: Icons.layers_rounded,
            hint: 'ابحث عن حلقة...',
            controller: _searchCtrl,
            query: _query,
            onQueryChanged: (v) => setState(() {
              _query = v.trim().toLowerCase();
              _visibleCount = _pageSize;
            }),
          ),
          InkWell(
            onTap: () => Navigator.maybePop(context),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  const Icon(Icons.arrow_forward_rounded, color: AppColors.gold, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.playlist.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: textColor, fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                  ),
                  if (videos != null && videos.isNotEmpty)
                    Text('${videos.length} حلقة',
                        style: const TextStyle(color: AppColors.gold, fontSize: 12)),
                ],
              ),
            ),
          ),
          Expanded(child: body),
        ],
      ),
    );
  }
}
