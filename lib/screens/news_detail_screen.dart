import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../app_theme.dart';
import '../models/article.dart';

class NewsDetailScreen extends StatefulWidget {
  final Article article;
  const NewsDetailScreen({super.key, required this.article});

  @override
  State<NewsDetailScreen> createState() => _NewsDetailScreenState();
}

class _NewsDetailScreenState extends State<NewsDetailScreen> {
  YoutubePlayerController? _ytCtrl;

  @override
  void initState() {
    super.initState();
    final url = widget.article.youtubeUrl;
    if (url != null) {
      final id = YoutubePlayer.convertUrlToId(url);
      if (id != null) {
        _ytCtrl = YoutubePlayerController(
          initialVideoId: id,
          flags: const YoutubePlayerFlags(
            autoPlay: false,
            mute: false,
            enableCaption: false,
            forceHD: false,
            useHybridComposition: false,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _ytCtrl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.darkBg : AppColors.lightBg;
    final textColor = isDark ? Colors.white : AppColors.lightText;
    final subColor = isDark ? Colors.white60 : AppColors.lightTextSub;

    Widget body = CustomScrollView(
      slivers: [
        SliverAppBar(
          backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          leading: IconButton(
            icon: Icon(Icons.arrow_forward_ios_rounded, color: textColor, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            widget.article.category ?? 'الأخبار',
            style: GoogleFonts.cairo(
              color: AppColors.gold,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
          pinned: true,
          expandedHeight: 0,
        ),
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero image or YouTube
              if (_ytCtrl != null)
                YoutubePlayerBuilder(
                  player: YoutubePlayer(
                    controller: _ytCtrl!,
                    showVideoProgressIndicator: true,
                    progressIndicatorColor: AppColors.gold,
                  ),
                  builder: (ctx, player) => player,
                )
              else if (widget.article.imageUrl != null)
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: CachedNetworkImage(
                    imageUrl: widget.article.imageUrl!,
                    fit: BoxFit.cover,
                    errorWidget: (ctx, e, s) => _imgFallback(),
                  ),
                )
              else
                _imgFallback(),

              // Content
              Container(
                color: bgColor,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Category chip
                    if (widget.article.category != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.gold.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          widget.article.category!,
                          style: GoogleFonts.cairo(
                            color: AppColors.gold,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],

                    // Title
                    Text(
                      widget.article.title,
                      style: GoogleFonts.cairo(
                        color: textColor,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Date
                    if (widget.article.publishedAt != null)
                      Row(
                        children: [
                          Icon(Icons.access_time_rounded, color: subColor, size: 14),
                          const SizedBox(width: 5),
                          Text(
                            '${widget.article.publishedAt!.day}/${widget.article.publishedAt!.month}/${widget.article.publishedAt!.year}',
                            style: GoogleFonts.cairo(color: subColor, fontSize: 12),
                          ),
                        ],
                      ),

                    Divider(
                      color: isDark ? Colors.white12 : const Color(0x22D4AF37),
                      height: 28,
                    ),

                    // Excerpt / body
                    if (widget.article.body != null)
                      ..._buildBody(widget.article.body!, textColor, subColor)
                    else if (widget.article.excerpt != null)
                      Text(
                        widget.article.excerpt!,
                        style: GoogleFonts.cairo(
                          color: subColor,
                          fontSize: 15,
                          height: 1.9,
                        ),
                      ),

                    const SizedBox(height: 30),

                    // Related video button if no embedded player
                    if (_ytCtrl == null && widget.article.youtubeUrl != null)
                      _WatchVideoButton(url: widget.article.youtubeUrl!),

                    const SizedBox(height: 60),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );

    if (_ytCtrl != null) {
      body = YoutubePlayerBuilder(
        player: YoutubePlayer(
          controller: _ytCtrl!,
          showVideoProgressIndicator: true,
          progressIndicatorColor: AppColors.gold,
        ),
        builder: (ctx, player) {
          return Scaffold(
            backgroundColor: bgColor,
            body: CustomScrollView(
              slivers: [
                SliverAppBar(
                  backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                  leading: IconButton(
                    icon: Icon(Icons.arrow_forward_ios_rounded, color: textColor, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                  title: Text(
                    widget.article.category ?? 'الأخبار',
                    style: GoogleFonts.cairo(
                      color: AppColors.gold,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  centerTitle: true,
                  pinned: true,
                  expandedHeight: 0,
                ),
                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      player,
                      Container(
                        color: bgColor,
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (widget.article.category != null) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.gold.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
                                ),
                                child: Text(
                                  widget.article.category!,
                                  style: GoogleFonts.cairo(
                                    color: AppColors.gold,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 14),
                            ],
                            Text(
                              widget.article.title,
                              style: GoogleFonts.cairo(
                                color: textColor,
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 12),
                            if (widget.article.publishedAt != null)
                              Row(
                                children: [
                                  Icon(Icons.access_time_rounded, color: subColor, size: 14),
                                  const SizedBox(width: 5),
                                  Text(
                                    '${widget.article.publishedAt!.day}/${widget.article.publishedAt!.month}/${widget.article.publishedAt!.year}',
                                    style: GoogleFonts.cairo(color: subColor, fontSize: 12),
                                  ),
                                ],
                              ),
                            Divider(
                              color: isDark ? Colors.white12 : const Color(0x22D4AF37),
                              height: 28,
                            ),
                            if (widget.article.body != null)
                              ..._buildBody(widget.article.body!, textColor, subColor)
                            else if (widget.article.excerpt != null)
                              Text(
                                widget.article.excerpt!,
                                style: GoogleFonts.cairo(color: subColor, fontSize: 15, height: 1.9),
                              ),
                            const SizedBox(height: 60),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      );
    } else {
      body = Scaffold(
        backgroundColor: bgColor,
        body: body,
      );
    }

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) _ytCtrl?.pause();
      },
      child: body,
    );
  }

  List<Widget> _buildBody(String body, Color textColor, Color subColor) {
    return body.split('\n\n').where((p) => p.trim().isNotEmpty).map((paragraph) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Text(
          paragraph.trim(),
          style: GoogleFonts.cairo(
            color: subColor,
            fontSize: 15,
            height: 2.0,
          ),
        ),
      );
    }).toList();
  }

  Widget _imgFallback() => AspectRatio(
        aspectRatio: 16 / 9,
        child: Container(
          color: AppColors.darkSurface2,
          child: const Center(
            child: Icon(Icons.article_rounded, color: AppColors.gold, size: 60),
          ),
        ),
      );
}

class _WatchVideoButton extends StatelessWidget {
  final String url;
  const _WatchVideoButton({required this.url});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        final id = YoutubePlayer.convertUrlToId(url);
        if (id == null) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => _YoutubeFullScreen(videoId: id),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFF0000), Color(0xFFCC0000)],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.play_circle_fill_rounded, color: Colors.white, size: 22),
            const SizedBox(width: 10),
            Text(
              'مشاهدة الفيديو',
              style: GoogleFonts.cairo(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _YoutubeFullScreen extends StatefulWidget {
  final String videoId;
  const _YoutubeFullScreen({required this.videoId});

  @override
  State<_YoutubeFullScreen> createState() => _YoutubeFullScreenState();
}

class _YoutubeFullScreenState extends State<_YoutubeFullScreen> {
  late final YoutubePlayerController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = YoutubePlayerController(
      initialVideoId: widget.videoId,
      flags: const YoutubePlayerFlags(autoPlay: true, enableCaption: false),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return YoutubePlayerBuilder(
      player: YoutubePlayer(
        controller: _ctrl,
        showVideoProgressIndicator: true,
        progressIndicatorColor: AppColors.gold,
      ),
      builder: (ctx, player) => Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          leading: IconButton(
            icon: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(child: player),
      ),
    );
  }
}