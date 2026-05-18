class Article {
  final int id;
  final String title;
  final String? excerpt;
  final String? imageUrl;
  final String? category;
  final DateTime? publishedAt;
  final String? youtubeUrl;
  final String? body;

  const Article({
    required this.id,
    required this.title,
    this.excerpt,
    this.imageUrl,
    this.category,
    this.publishedAt,
    this.youtubeUrl,
    this.body,
  });

  factory Article.fromJson(Map<String, dynamic> json) => Article(
        id: (json['id'] as num?)?.toInt() ?? 0,
        title: json['title']?.toString() ?? '',
        excerpt: json['excerpt']?.toString() ?? json['content']?.toString(),
        imageUrl: json['image_url']?.toString() ?? json['featured_image']?.toString(),
        category: json['category']?.toString(),
        publishedAt: json['published_at'] != null
            ? DateTime.tryParse(json['published_at'].toString())
            : null,
        youtubeUrl: json['youtube_url']?.toString(),
        body: json['body']?.toString(),
      );
}
