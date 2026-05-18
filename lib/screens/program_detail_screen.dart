import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../app_theme.dart';
import '../models/program.dart';
import '../widgets/social_bar.dart';

class ProgramDetailScreen extends StatefulWidget {
  final Program program;
  const ProgramDetailScreen({super.key, required this.program});

  @override
  State<ProgramDetailScreen> createState() => _ProgramDetailScreenState();
}

class _ProgramDetailScreenState extends State<ProgramDetailScreen> {
  YoutubePlayerController? _ytCtrl;
  bool _showPlayer = false;

  @override
  void initState() {
    super.initState();
    final url = widget.program.youtubeUrl;
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

  Widget _buildPage(BuildContext context, Widget? player) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.darkBg : AppColors.lightBg;
    final textColor = isDark ? Colors.white : AppColors.lightText;
    final subColor = isDark ? Colors.white60 : AppColors.lightTextSub;

    final prog = widget.program;

    // Decide thumbnail
    final effectiveImage = prog.localImage != null
        ? null // handled below as asset
        : prog.imageUrl;

    return Scaffold(
      backgroundColor: bgColor,
      body: CustomScrollView(
        slivers: [
          // ── Hero image / video area ──
          SliverAppBar(
            expandedHeight: 240,
            pinned: true,
            backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            leading: IconButton(
              icon: Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Background
                  if (!_showPlayer)
                    (prog.localImage != null
                        ? Image.asset(prog.localImage!, fit: BoxFit.cover,
                            errorBuilder: (ctx, e, _) => _defaultBg())
                        : (effectiveImage != null
                            ? CachedNetworkImage(
                                imageUrl: effectiveImage,
                                fit: BoxFit.cover,
                                errorWidget: (ctx, e, s) => _defaultBg(),
                              )
                            : _defaultBg())),
                  if (!_showPlayer)
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0x44000000), Color(0xCC000000)],
                        ),
                      ),
                    ),
                  if (_showPlayer && player != null) player,
                  if (!_showPlayer && _ytCtrl != null)
                    Center(
                      child: GestureDetector(
                        onTap: () {
                          setState(() => _showPlayer = true);
                          _ytCtrl!.play();
                        },
                        child: Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.gold.withValues(alpha: 0.9),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.gold.withValues(alpha: 0.5),
                                blurRadius: 20,
                              ),
                            ],
                          ),
                          child: const Icon(Icons.play_arrow_rounded, color: Colors.black, size: 36),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // ── Content ──
          SliverToBoxAdapter(
            child: Container(
              color: bgColor,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title
                        Text(
                          prog.nameAr,
                          style: GoogleFonts.cairo(
                            color: textColor,
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 10),
                        // Meta row
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            if (prog.scheduleTime != null)
                              _MetaChip(
                                icon: Icons.schedule_rounded,
                                label: prog.scheduleTime!,
                                isDark: isDark,
                              ),
                            if (prog.presenterAr != null)
                              _MetaChip(
                                icon: Icons.person_rounded,
                                label: prog.presenterAr!,
                                isDark: isDark,
                              ),
                            if (prog.episodeCount > 0)
                              _MetaChip(
                                icon: Icons.play_circle_outline_rounded,
                                label: '${prog.episodeCount} حلقة',
                                isDark: isDark,
                              ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        // Description
                        if (prog.descriptionAr != null)
                          Text(
                            prog.descriptionAr!,
                            style: GoogleFonts.cairo(
                              color: subColor,
                              fontSize: 15,
                              height: 2.0,
                            ),
                          ),
                        const SizedBox(height: 28),
                        // Watch button
                        if (prog.youtubeUrl != null)
                          _buildWatchButton(isDark),
                        const SizedBox(height: 24),
                        // Social media icons
                        Center(child: const SocialBar()),
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWatchButton(bool isDark) {
    return GestureDetector(
      onTap: () {
        if (_ytCtrl == null) return;
        if (_showPlayer) {
          // already showing, scroll up handled by user
        } else {
          setState(() => _showPlayer = true);
          _ytCtrl!.play();
        }
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.goldDim, AppColors.gold],
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: AppColors.gold.withValues(alpha: 0.35),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.play_arrow_rounded, color: Colors.black, size: 26),
            const SizedBox(width: 10),
            Text(
              _showPlayer ? 'يتم التشغيل...' : 'مشاهدة البرنامج',
              style: GoogleFonts.cairo(
                color: Colors.black,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _defaultBg() => Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF2E1A00), AppColors.darkSurface],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: const Center(
          child: Icon(Icons.tv_rounded, color: AppColors.gold, size: 60),
        ),
      );

  @override
  Widget build(BuildContext context) {
    if (_ytCtrl != null && _showPlayer) {
      return PopScope(
        canPop: true,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) _ytCtrl?.pause();
        },
        child: YoutubePlayerBuilder(
          player: YoutubePlayer(
            controller: _ytCtrl!,
            showVideoProgressIndicator: true,
            progressIndicatorColor: AppColors.gold,
          ),
          builder: (ctx, player) => _buildPage(ctx, player),
        ),
      );
    }
    return _buildPage(context, null);
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;
  const _MetaChip({required this.icon, required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface2 : AppColors.lightSurface3,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.gold, size: 13),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.cairo(
              color: isDark ? Colors.white70 : AppColors.lightTextSub,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}