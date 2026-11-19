import 'package:flutter/material.dart';
import '../app_theme.dart';
import '../models/youtube_video.dart';
import 'menu_button.dart';
import 'video_card.dart';

// Shared pieces of the مكتبة البرامج / سلاسل البرامج screens.

const libraryGridDelegate = SliverGridDelegateWithFixedCrossAxisCount(
  crossAxisCount: 2,
  childAspectRatio: 0.92,
  crossAxisSpacing: 10,
  mainAxisSpacing: 10,
);

class LibraryVideoGrid extends StatelessWidget {
  final List<YouTubeVideo> videos;

  /// Full list the tapped video belongs to (shown under it in the player).
  final List<YouTubeVideo> queue;
  final String? queueTitle;
  final bool hasMore;
  final VoidCallback onLoadMore;
  final bool loadingMore;
  const LibraryVideoGrid({
    super.key,
    required this.videos,
    required this.queue,
    this.queueTitle,
    required this.hasMore,
    required this.onLoadMore,
    this.loadingMore = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
          sliver: SliverGrid(
            gridDelegate: libraryGridDelegate,
            delegate: SliverChildBuilderDelegate(
              (ctx, i) => VideoCard(
                video: videos[i],
                onTap: () => openYouTubeVideo(ctx, videos[i],
                    queue: queue, title: queueTitle),
              ),
              childCount: videos.length,
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 90),
            child: Column(
              children: [
                if (loadingMore)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.gold),
                        ),
                        const SizedBox(width: 8),
                        Text('جاري تحميل المزيد من الفيديوهات...',
                            style: TextStyle(
                                color: isDark ? Colors.white54 : AppColors.lightTextSub,
                                fontSize: 12)),
                      ],
                    ),
                  ),
                if (hasMore)
                  OutlinedButton(
                    onPressed: onLoadMore,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.gold,
                      side: const BorderSide(color: AppColors.gold),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 10),
                    ),
                    child: const Text('تحميل المزيد'),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class LibrarySkeletonGrid extends StatelessWidget {
  final int count;
  const LibrarySkeletonGrid({super.key, this.count = 12});

  @override
  Widget build(BuildContext context) => GridView.builder(
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 90),
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: libraryGridDelegate,
        itemCount: count,
        itemBuilder: (_, i) => const VideoCardSkeleton(),
      );
}

class LibraryMessage extends StatelessWidget {
  final String text;
  final VoidCallback? onRetry;
  const LibraryMessage(this.text, {super.key, this.onRetry});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (onRetry != null) ...[
              const Icon(Icons.wifi_off_rounded, color: AppColors.gold, size: 36),
              const SizedBox(height: 12),
            ],
            Text(
              text,
              textAlign: TextAlign.center,
              style: TextStyle(color: isDark ? Colors.white54 : AppColors.lightTextSub, fontSize: 14),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: onRetry,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.gold,
                  side: const BorderSide(color: AppColors.gold),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                ),
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('إعادة المحاولة'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}


/// Title row (with the side-menu toggle) + search field.
class LibraryHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final String hint;
  final TextEditingController controller;
  final String query;
  final ValueChanged<String> onQueryChanged;
  final VoidCallback? onOpenMenu;

  const LibraryHeader({
    super.key,
    required this.title,
    required this.icon,
    required this.hint,
    required this.controller,
    required this.query,
    required this.onQueryChanged,
    this.onOpenMenu,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppColors.lightText;
    final subColor = isDark ? Colors.white54 : AppColors.lightTextSub;
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(24),
      borderSide: BorderSide(color: AppColors.gold.withValues(alpha: 0.3)),
    );
    return Container(
      color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      padding: const EdgeInsetsDirectional.fromSTEB(4, 4, 16, 10),
      child: Column(
        children: [
          Row(
            children: [
              if (onOpenMenu != null)
                MenuButton(onPressed: onOpenMenu!)
              else
                const SizedBox(width: 12),
              Icon(icon, color: AppColors.gold, size: 22),
              const SizedBox(width: 10),
              Text(title,
                  style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsetsDirectional.only(start: 12),
            child: TextField(
              controller: controller,
              onChanged: onQueryChanged,
              style: TextStyle(color: textColor, fontSize: 14),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(color: subColor, fontSize: 13),
                prefixIcon: const Icon(Icons.search_rounded, color: AppColors.gold),
                suffixIcon: query.isEmpty
                    ? null
                    : IconButton(
                        icon: Icon(Icons.close_rounded, color: subColor, size: 18),
                        onPressed: () {
                          controller.clear();
                          onQueryChanged('');
                        },
                      ),
                isDense: true,
                filled: true,
                fillColor: isDark ? AppColors.darkSurface2 : AppColors.lightSurface2,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                border: border,
                enabledBorder: border,
                focusedBorder: border.copyWith(
                  borderSide: const BorderSide(color: AppColors.gold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
