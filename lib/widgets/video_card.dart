import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../app_theme.dart';
import '../models/youtube_video.dart';
import '../screens/video_player_screen.dart';
import '../services/youtube_service.dart';

/// Opens [v] in the player screen. When [queue] is given (a playlist or the
/// list the video was picked from), the rest of it is shown under the video
/// and plays next automatically.
void openYouTubeVideo(
  BuildContext context,
  YouTubeVideo v, {
  List<YouTubeVideo>? queue,
  String? title,
}) {
  final list = (queue == null || queue.isEmpty) ? [v] : queue;
  var index = list.indexWhere((e) => e.id == v.id);
  final videos = index < 0 ? [v, ...list] : list;
  if (index < 0) index = 0;
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => VideoPlayerScreen(videos: videos, initialIndex: index, title: title),
    ),
  );
}

String _formatDate(DateTime d) =>
    '${d.year}/${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}';

class VideoCard extends StatelessWidget {
  final YouTubeVideo video;
  final VoidCallback? onTap;
  const VideoCard({super.key, required this.video, this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppColors.lightText;
    final subColor = isDark ? Colors.white54 : AppColors.lightTextSub;

    return GestureDetector(
      onTap: onTap ?? () => openYouTubeVideo(context, video),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.gold.withValues(alpha: 0.25)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  video.thumbnail.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: video.thumbnail,
                          fit: BoxFit.cover,
                          errorWidget: (ctx, e, s) => _placeholder(),
                        )
                      : _placeholder(),
                  if (video.duration > 0)
                    Positioned(
                      bottom: 6,
                      left: 6,
                      child: _Badge(text: YouTubeService.formatDuration(video.duration)),
                    ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        video.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            color: textColor, fontSize: 12, fontWeight: FontWeight.bold, height: 1.4),
                      ),
                    ),
                    Row(
                      children: [
                        Icon(Icons.remove_red_eye_outlined, size: 12, color: AppColors.gold),
                        const SizedBox(width: 3),
                        Text(YouTubeService.formatViewCount(video.viewCount),
                            style: TextStyle(color: subColor, fontSize: 10)),
                        const Spacer(),
                        Text(_formatDate(video.publishedAt),
                            style: TextStyle(color: subColor, fontSize: 10)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PlaylistCard extends StatelessWidget {
  final YouTubePlaylist playlist;
  final VoidCallback onTap;
  const PlaylistCard({super.key, required this.playlist, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppColors.lightText;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.gold.withValues(alpha: 0.25)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  playlist.thumbnail.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: playlist.thumbnail,
                          fit: BoxFit.cover,
                          errorWidget: (ctx, e, s) => _placeholder(),
                        )
                      : _placeholder(),
                  Positioned(
                    bottom: 6,
                    left: 6,
                    child: _Badge(
                      icon: Icons.playlist_play_rounded,
                      text: '${playlist.itemCount} فيديو',
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Text(
                  playlist.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      color: textColor, fontSize: 12, fontWeight: FontWeight.bold, height: 1.4),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Loading placeholder shaped like a [VideoCard].
class VideoCardSkeleton extends StatelessWidget {
  const VideoCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = isDark ? AppColors.darkSurface2 : AppColors.lightSurface3;
    Widget line(double widthFactor) => FractionallySizedBox(
          widthFactor: widthFactor,
          child: Container(
            height: 10,
            decoration: BoxDecoration(color: base, borderRadius: BorderRadius.circular(4)),
          ),
        );
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(aspectRatio: 16 / 9, child: Container(color: base)),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [line(0.9), const SizedBox(height: 6), line(0.5)],
            ),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;
  final IconData? icon;
  const _Badge({required this.text, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, color: Colors.white, size: 12),
            const SizedBox(width: 3),
          ],
          Text(text, style: const TextStyle(color: Colors.white, fontSize: 10)),
        ],
      ),
    );
  }
}

Widget _placeholder() => Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.darkSurface2, AppColors.darkSurface],
        ),
      ),
      child: const Center(child: Icon(Icons.tv_rounded, color: AppColors.gold, size: 36)),
    );
