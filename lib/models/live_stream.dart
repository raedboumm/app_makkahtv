class LiveStream {
  final int id;
  final String title;
  final String streamUrl;
  final bool isActive;
  final String? thumbnailUrl;
  final String? description;

  const LiveStream({
    required this.id,
    required this.title,
    required this.streamUrl,
    this.isActive = true,
    this.thumbnailUrl,
    this.description,
  });

  factory LiveStream.fromJson(Map<String, dynamic> json) => LiveStream(
        id: (json['id'] as num?)?.toInt() ?? 0,
        title: json['title']?.toString() ?? 'البث المباشر',
        streamUrl: json['stream_url']?.toString() ?? defaultStreamUrl,
        isActive: json['is_active'] == 1 || json['is_active'] == true,
        thumbnailUrl: json['thumbnail_url']?.toString(),
        description: json['description']?.toString(),
      );

  static const String defaultStreamUrl =
      'https://media2.streambrothers.com:1936/8122/8122/playlist.m3u8';

  static LiveStream get fallback => const LiveStream(
        id: 1,
        title: 'قناة مكة المباشر',
        streamUrl: defaultStreamUrl,
        isActive: true,
        thumbnailUrl: 'https://makkahlive.net/images/MakkahLiveCover.jpg',
        description: 'البث المباشر من المسجد الحرام والمسجد النبوي على مدار الساعة',
      );
}
