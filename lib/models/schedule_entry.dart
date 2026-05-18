class ScheduleEntry {
  final String nameAr;
  final String timeAr;
  final String imageUrl;
  final String? localImage;
  final String? youtubeUrl;
  final int sortMinutes; // minutes since midnight for sorting

  const ScheduleEntry({
    required this.nameAr,
    required this.timeAr,
    required this.imageUrl,
    this.localImage,
    this.youtubeUrl,
    required this.sortMinutes,
  });
}
