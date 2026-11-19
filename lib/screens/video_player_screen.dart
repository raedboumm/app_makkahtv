import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../app_theme.dart';
import '../models/youtube_video.dart';
import '../services/youtube_service.dart';
import '../widgets/app_youtube_player.dart';

/// Plays a video with the rest of its playlist (or list) right underneath:
/// tap any episode to switch in place, and the next one starts by itself
/// when the current one ends — no need to go back and pick it.
class VideoPlayerScreen extends StatefulWidget {
  final List<YouTubeVideo> videos;
  final int initialIndex;

  /// Playlist / section name shown above the episode list.
  final String? title;

  const VideoPlayerScreen({
    super.key,
    required this.videos,
    this.initialIndex = 0,
    this.title,
  });

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  static const double _itemExtent = 86;

  late int _index;
  late YoutubePlayerController _ctrl;
  bool _autoNext = true;
  final _listCtrl = ScrollController();

  List<YouTubeVideo> get _videos => widget.videos;
  YouTubeVideo get _current => _videos[_index];

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex.clamp(0, _videos.length - 1);
    _ctrl = _newController(_current.id);
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToCurrent(animate: false));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _listCtrl.dispose();
    super.dispose();
  }

  YoutubePlayerController _newController(String id) => YoutubePlayerController(
        initialVideoId: id,
        flags: const YoutubePlayerFlags(autoPlay: true, enableCaption: false),
      );

  void _playAt(int i) {
    if (i < 0 || i >= _videos.length) return;
    if (i == _index) {
      _ctrl.play();
      return;
    }
    setState(() => _index = i);
    final id = _videos[i].id;
    if (_ctrl.value.isReady) {
      // Same player, new video: instant and keeps fullscreen if active.
      _ctrl.load(id);
    } else {
      final old = _ctrl;
      setState(() => _ctrl = _newController(id));
      WidgetsBinding.instance.addPostFrameCallback((_) => old.dispose());
    }
    _scrollToCurrent();
  }

  void _onEnded() {
    if (_autoNext && _index + 1 < _videos.length) _playAt(_index + 1);
  }

  void _scrollToCurrent({bool animate = true}) {
    if (!_listCtrl.hasClients) return;
    final target = (_index * _itemExtent - _itemExtent)
        .clamp(0.0, _listCtrl.position.maxScrollExtent);
    if (animate) {
      _listCtrl.animateTo(target,
          duration: const Duration(milliseconds: 350), curve: Curves.easeOut);
    } else {
      _listCtrl.jumpTo(target);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBg : AppColors.lightBg;
    final textColor = isDark ? Colors.white : AppColors.lightText;
    final subColor = isDark ? Colors.white54 : AppColors.lightTextSub;
    final v = _current;
    final hasList = _videos.length > 1;

    return Scaffold(
      backgroundColor: bg,
      body: Column(
        children: [
          Container(
            color: Colors.black,
            padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
            child: Column(
              children: [
                // ── Top bar ──
                SizedBox(
                  height: 44,
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_forward_ios_rounded,
                            color: Colors.white, size: 20),
                        onPressed: () => Navigator.maybePop(context),
                      ),
                      Expanded(
                        child: Text(
                          widget.title ?? 'مشاهدة',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                  ),
                ),
                // ── Player ──
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: AppYoutubePlayer(
                    key: ObjectKey(_ctrl),
                    controller: _ctrl,
                    onEnded: _onEnded,
                  ),
                ),
              ],
            ),
          ),
          // ── Current video info ──
          Container(
            width: double.infinity,
            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  v.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      color: textColor,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      height: 1.4),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.remove_red_eye_outlined,
                        size: 13, color: AppColors.gold),
                    const SizedBox(width: 4),
                    Text(YouTubeService.formatViewCount(v.viewCount),
                        style: TextStyle(color: subColor, fontSize: 11)),
                    const SizedBox(width: 12),
                    Text(_formatDate(v.publishedAt),
                        style: TextStyle(color: subColor, fontSize: 11)),
                    const Spacer(),
                    if (hasList)
                      Text('${_index + 1} / ${_videos.length}',
                          style: const TextStyle(
                              color: AppColors.gold,
                              fontSize: 12,
                              fontWeight: FontWeight.bold)),
                  ],
                ),
                if (hasList) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _NavButton(
                        icon: Icons.skip_next_rounded, // RTL: "previous" is on the right
                        label: 'السابق',
                        onTap: _index > 0 ? () => _playAt(_index - 1) : null,
                      ),
                      const SizedBox(width: 8),
                      _NavButton(
                        icon: Icons.skip_previous_rounded,
                        label: 'التالي',
                        onTap: _index + 1 < _videos.length
                            ? () => _playAt(_index + 1)
                            : null,
                      ),
                      const Spacer(),
                      Text('تشغيل تلقائي',
                          style: TextStyle(color: subColor, fontSize: 11)),
                      Switch(
                        value: _autoNext,
                        activeThumbColor: AppColors.gold,
                        onChanged: (val) => setState(() => _autoNext = val),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          // ── Rest of the playlist ──
          if (hasList)
            Expanded(
              child: ListView.builder(
                controller: _listCtrl,
                padding: const EdgeInsets.only(top: 6, bottom: 90),
                itemExtent: _itemExtent,
                itemCount: _videos.length,
                itemBuilder: (_, i) => _EpisodeTile(
                  video: _videos[i],
                  number: i + 1,
                  isCurrent: i == _index,
                  onTap: () => _playAt(i),
                ),
              ),
            )
          else
            const Spacer(),
        ],
      ),
    );
  }
}

String _formatDate(DateTime d) =>
    '${d.year}/${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}';

class _NavButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  const _NavButton({required this.icon, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return OutlinedButton.icon(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.gold,
        side: BorderSide(
            color: enabled ? AppColors.gold : AppColors.gold.withValues(alpha: 0.25)),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        minimumSize: const Size(0, 32),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      icon: Icon(icon, size: 18),
      label: Text(label, style: const TextStyle(fontSize: 12)),
    );
  }
}

class _EpisodeTile extends StatelessWidget {
  final YouTubeVideo video;
  final int number;
  final bool isCurrent;
  final VoidCallback onTap;
  const _EpisodeTile({
    required this.video,
    required this.number,
    required this.isCurrent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppColors.lightText;
    final subColor = isDark ? Colors.white54 : AppColors.lightTextSub;

    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: isCurrent
              ? AppColors.gold.withValues(alpha: isDark ? 0.14 : 0.18)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isCurrent ? AppColors.gold : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 24,
              child: isCurrent
                  ? const Icon(Icons.play_arrow_rounded, color: AppColors.gold, size: 20)
                  : Text('$number',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: subColor, fontSize: 12)),
            ),
            const SizedBox(width: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: SizedBox(
                width: 112,
                height: 63,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    video.thumbnail.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: video.thumbnail,
                            fit: BoxFit.cover,
                            errorWidget: (_, _, _) =>
                                const ColoredBox(color: AppColors.darkSurface2),
                          )
                        : const ColoredBox(color: AppColors.darkSurface2),
                    if (video.duration > 0)
                      Positioned(
                        bottom: 3,
                        left: 3,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.75),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Text(
                            YouTubeService.formatDuration(video.duration),
                            style: const TextStyle(color: Colors.white, fontSize: 9),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    video.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isCurrent ? AppColors.gold : textColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isCurrent
                        ? 'يعرض الآن'
                        : '${YouTubeService.formatViewCount(video.viewCount)} مشاهدة',
                    style: TextStyle(
                        color: isCurrent ? AppColors.gold : subColor, fontSize: 10),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
