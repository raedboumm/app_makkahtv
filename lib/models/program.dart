class Program {
  final int id;
  final String nameAr;
  final String? descriptionAr;
  final String? scheduleTime;
  final String? presenterAr;
  final String? imageUrl;
  final String? localImage; // asset path e.g. 'assets/episode/post1.png'
  final int episodeCount;
  final String? youtubeUrl;  // YouTube playlist or video URL

  const Program({
    required this.id,
    required this.nameAr,
    this.descriptionAr,
    this.scheduleTime,
    this.presenterAr,
    this.imageUrl,
    this.localImage,
    this.episodeCount = 0,
    this.youtubeUrl,
  });

  factory Program.fromJson(Map<String, dynamic> json) => Program(
        id: (json['id'] as num?)?.toInt() ?? 0,
        nameAr: json['name_ar']?.toString() ?? json['name']?.toString() ?? '',
        descriptionAr: json['description_ar']?.toString(),
        scheduleTime: json['schedule_time']?.toString(),
        presenterAr: json['presenter_ar']?.toString(),
        imageUrl: json['image_url']?.toString(),
        episodeCount: (json['episode_count'] as num?)?.toInt() ?? 0,
      );

  static List<Program> get samples => const [
        Program(
          id: 1,
          nameAr: 'البث المباشر',
          descriptionAr: 'البث المباشر من المسجد الحرام',
          scheduleTime: '٢٤/٧',
          imageUrl: 'https://makkahlive.net/images/MakkahLiveCover.jpg',
        ),
        Program(
          id: 2,
          nameAr: 'خواطر رمضانية',
          descriptionAr: 'برامج رمضانية متنوعة',
          scheduleTime: 'رمضان',
        ),
        Program(
          id: 3,
          nameAr: 'الدروس الدينية',
          descriptionAr: 'دروس ومحاضرات دينية',
          scheduleTime: 'يومي',
        ),
        Program(
          id: 4,
          nameAr: 'تلاوات القرآن',
          descriptionAr: 'تلاوات من المسجد الحرام',
          scheduleTime: 'يومي',
        ),
        Program(
          id: 5,
          nameAr: 'أخبار الحج',
          descriptionAr: 'أخبار وتقارير الحج والعمرة',
          scheduleTime: 'موسمي',
        ),
        Program(
          id: 6,
          nameAr: 'نور على نور',
          descriptionAr: 'برنامج ديني تثقيفي',
          scheduleTime: 'أسبوعي',
        ),
      ];
}
