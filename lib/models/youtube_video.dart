/// Manual title overrides for specific videos/playlists whose YouTube title
/// should be shown differently in the app. Matched case-insensitively,
/// ignoring extra whitespace.
/// Matched as "contains", so it also fixes titles already saved in the
/// phone's cache by an older version of the app (e.g. "قصة سيدنا يوسف – …").
const Map<String, String> _titleOverrides = {
  'from darkness to light': 'من الظلام إلى النور',
  'من الظلام إلى النور': 'من الظلام إلى النور',
};

String fixTitle(String title) {
  final key = title.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();
  for (final e in _titleOverrides.entries) {
    if (key.contains(e.key)) return e.value;
  }
  return title;
}

class YouTubeVideo {
  final String id;
  final String title;
  final String thumbnail;
  final DateTime publishedAt;
  final int viewCount;
  final int duration; // seconds

  const YouTubeVideo({
    required this.id,
    required this.title,
    required this.thumbnail,
    required this.publishedAt,
    this.viewCount = 0,
    this.duration = 0,
  });

  String get url => 'https://www.youtube.com/watch?v=$id';

  YouTubeVideo copyWith({int? viewCount, int? duration}) => YouTubeVideo(
        id: id,
        title: title,
        thumbnail: thumbnail,
        publishedAt: publishedAt,
        viewCount: viewCount ?? this.viewCount,
        duration: duration ?? this.duration,
      );

  factory YouTubeVideo.fromJson(Map<String, dynamic> json) => YouTubeVideo(
        id: json['id']?.toString() ?? '',
        title: fixTitle(json['title']?.toString() ?? ''),
        thumbnail: json['thumbnail']?.toString() ?? '',
        publishedAt: DateTime.tryParse(json['publishedAt']?.toString() ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0),
        viewCount: (json['viewCount'] as num?)?.toInt() ?? 0,
        duration: (json['duration'] as num?)?.toInt() ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'thumbnail': thumbnail,
        'publishedAt': publishedAt.toIso8601String(),
        'viewCount': viewCount,
        'duration': duration,
      };
}

class YouTubePlaylist {
  final String id;
  final String title;
  final String thumbnail;
  final int itemCount;

  const YouTubePlaylist({
    required this.id,
    required this.title,
    required this.thumbnail,
    this.itemCount = 0,
  });

  factory YouTubePlaylist.fromJson(Map<String, dynamic> json) => YouTubePlaylist(
        id: json['id']?.toString() ?? '',
        title: fixTitle(json['title']?.toString() ?? ''),
        thumbnail: json['thumbnail']?.toString() ?? '',
        itemCount: (json['itemCount'] as num?)?.toInt() ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'thumbnail': thumbnail,
        'itemCount': itemCount,
      };
}
