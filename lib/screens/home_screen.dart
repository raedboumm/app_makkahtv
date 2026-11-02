import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:provider/provider.dart';
import '../app_theme.dart';
import '../data/static_data.dart';
import '../models/article.dart';
import '../models/youtube_video.dart';
import '../models/schedule_entry.dart';
import '../pip_state.dart';
import '../services/youtube_service.dart';
import '../widgets/program_card.dart';
import '../widgets/frequency_strip.dart';
import '../widgets/video_card.dart';
import 'news_detail_screen.dart';
import 'program_detail_screen.dart';

const _homePipChannel = MethodChannel('makkah.tv/pip');

class HomeScreen extends StatefulWidget {
  final VoidCallback? onWatchLive;
  final VoidCallback? onGoToPrograms;
  const HomeScreen({super.key, this.onWatchLive, this.onGoToPrograms});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _scrollCtrl = ScrollController();
  String? _selectedYoutubeUrl;
  String? _selectedTitle;

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onVideoSelected(String url, String title) {
    // If the same URL is already playing, briefly null it so didUpdateWidget fires
    if (_selectedYoutubeUrl == url) {
      setState(() { _selectedYoutubeUrl = null; });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() { _selectedYoutubeUrl = url; _selectedTitle = title; });
      });
    } else {
      setState(() { _selectedYoutubeUrl = url; _selectedTitle = title; });
    }
    _scrollCtrl.animateTo(
      0,
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOut,
    );
  }

  void _onBackToLive() {
    setState(() {
      _selectedYoutubeUrl = null;
      _selectedTitle = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      controller: _scrollCtrl,
      slivers: [
        SliverToBoxAdapter(child: _HeroSection(
          onWatchLive: widget.onWatchLive,
          youtubeUrl: _selectedYoutubeUrl,
          youtubeTitle: _selectedTitle,
          onBackToLive: _onBackToLive,
        )),
        SliverToBoxAdapter(
          child: _DailyScheduleSection(onVideoSelected: _onVideoSelected),
        ),
        SliverToBoxAdapter(
          child: _ProgramsSection(
            onViewAll: widget.onGoToPrograms,
            onVideoSelected: _onVideoSelected,
          ),
        ),
        SliverToBoxAdapter(
          child: _MostViewedSection(onVideoSelected: _onVideoSelected),
        ),
        SliverToBoxAdapter(
          child: const _ChannelInfoSection(),
        ),
        SliverToBoxAdapter(
          child: const _SocialSection(),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 90)),
      ],
    );
  }
}

// ─── Hero ─────────────────────────────────────────────────────────────────────

class _HeroSection extends StatefulWidget {
  final VoidCallback? onWatchLive;
  final String? youtubeUrl;
  final String? youtubeTitle;
  final VoidCallback? onBackToLive;
  const _HeroSection({this.onWatchLive, this.youtubeUrl, this.youtubeTitle, this.onBackToLive});

  @override
  State<_HeroSection> createState() => _HeroSectionState();
}

class _HeroSectionState extends State<_HeroSection> with WidgetsBindingObserver {
  VideoPlayerController? _videoCtrl;
  YoutubePlayerController? _ytCtrl;
  bool _isLoading = true;
  bool _hasError = false;
  bool _inPipMode = false;
  StreamSubscription? _pipSub;
  bool _pendingPipExit = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (Platform.isAndroid) {
      _pipSub = pipEvents.listen(_onPipEvent);
    }
    // Auto-start live stream when the home page opens
    WidgetsBinding.instance.addPostFrameCallback((_) => _startStream());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pipSub?.cancel();
    homePipVideoNotifier.value = null;
    _videoCtrl?.dispose();
    _ytCtrl?.dispose();
    super.dispose();
  }

  // The home tab stays alive inside MainScaffold's IndexedStack, so pause
  // its players while another tab is showing (otherwise the live tab and
  // this one play two streams at once).
  bool _tabVisible = true;
  bool _resumeOnShow = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final visible = TickerMode.valuesOf(context).enabled;
    if (visible == _tabVisible) return;
    _tabVisible = visible;
    if (!visible) {
      _resumeOnShow = _ytCtrl == null && _videoCtrl?.value.isPlaying == true;
      _videoCtrl?.pause();
      _ytCtrl?.pause();
    } else if (_resumeOnShow) {
      _resumeOnShow = false;
      _videoCtrl?.play();
    }
  }

  @override
  void didUpdateWidget(_HeroSection old) {
    super.didUpdateWidget(old);
    if (widget.youtubeUrl != old.youtubeUrl) {
      if (widget.youtubeUrl != null) {
        // Pause live stream, switch to YouTube
        _videoCtrl?.pause();
        _loadYoutube(widget.youtubeUrl!);
      } else {
        // Back to live
        _ytCtrl?.dispose();
        _ytCtrl = null;
        _videoCtrl?.play();
        if (mounted) setState(() {});
      }
    }
  }

  void _loadYoutube(String url) {
    final id = YoutubePlayer.convertUrlToId(url);
    if (id == null) return;
    _ytCtrl?.dispose();
    _ytCtrl = YoutubePlayerController(
      initialVideoId: id,
      flags: const YoutubePlayerFlags(autoPlay: true, mute: false),
    );
    if (mounted) setState(() {});
  }

  void _onPipEvent(bool isInPip) {
    if (!mounted || pipOwner != 'home') return;
    if (isInPip && _videoCtrl == null) return;
    pipModeNotifier.value = isInPip;
    setState(() => _inPipMode = isInPip);
    if (!isInPip) {
      pipOwner = null;
      // PiP exited: set flag so lifecycle:resumed can resume playback.
      // If the app stays in background (PiP dismissed), the paused
      // lifecycle event will pause the video instead.
      _pendingPipExit = true;
      Future.delayed(const Duration(milliseconds: 2000), () {
        if (mounted) _pendingPipExit = false;
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _pendingPipExit) {
      // User expanded PiP back to full screen — resume playback.
      _pendingPipExit = false;
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted && _videoCtrl?.value.isInitialized == true) _videoCtrl?.play();
      });
    }
    if ((state == AppLifecycleState.paused ||
            state == AppLifecycleState.hidden) &&
        !_inPipMode) {
      _videoCtrl?.pause();
    }
  }

  Future<void> _setVideoPlaying(bool playing) async {
    try {
      if (Platform.isAndroid) {
        await _homePipChannel.invokeMethod('setVideoPlaying', playing);
      }
    } catch (_) {}
  }

  Future<void> _enterPip() async {
    if (_videoCtrl == null) return;
    pipOwner = 'home';
    // Set fullscreen state NOW so Flutter rebuilds before Android captures the frame.
    pipModeNotifier.value = true;
    setState(() => _inPipMode = true);
    // Wait for the new frame (black + video only) to be rendered on screen.
    await WidgetsBinding.instance.endOfFrame;
    try {
      await _homePipChannel.invokeMethod('enterPip');
    } catch (_) {
      // PiP not supported — revert
      pipOwner = null;
      pipModeNotifier.value = false;
      if (mounted) setState(() => _inPipMode = false);
    }
  }

  Future<void> _startStream() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    try {
      // Always use a fresh controller for live HLS — preloaded buffers
      // start at a stale position and stall after ~1 second.
      LiveStreamPreloader.clear();
      final ctrl = VideoPlayerController.networkUrl(
        Uri.parse(StaticData.liveStream.streamUrl),
        httpHeaders: const {'User-Agent': 'MakkahTV/1.0 Flutter'},
        formatHint: VideoFormat.hls,
      );
      _videoCtrl = ctrl;
      // The stop button (_resetPlayer) can dispose/replace the controller
      // while we're awaiting below — bail out quietly instead of erroring.
      bool stale() => !mounted || _videoCtrl != ctrl;
      try {
        await ctrl.initialize();
        if (stale()) return;
        await ctrl.setLooping(false);
        // Seek to the live edge before playing to avoid starting from stale buffer.
        final dur = ctrl.value.duration;
        if (dur > Duration.zero) await ctrl.seekTo(dur);
        if (stale()) return;
        if (_tabVisible) {
          await ctrl.play();
        } else {
          _resumeOnShow = true;
        }
      } catch (_) {
        if (stale()) return;
        rethrow;
      }
      if (stale()) return;
      setState(() => _isLoading = false);
      homePipVideoNotifier.value = ctrl;
      _setVideoPlaying(true);
      // Add a listener: if the stream stalls/errors, show error state.
      ctrl.addListener(_onVideoStatus);
    } catch (_) {
      if (mounted) setState(() { _isLoading = false; _hasError = true; });
    }
  }

  bool _stalled = false;
  void _onVideoStatus() {
    if (!mounted || _videoCtrl == null) return;
    final val = _videoCtrl!.value;
    if (val.hasError && !_stalled) {
      _stalled = true;
      setState(() { _hasError = true; });
    }
  }

  void _retry() {
    _resetPlayer();
    _startStream();
  }

  void _resetPlayer() {
    _pendingPipExit = false;
    _stalled = false;
    _resumeOnShow = false;
    if (pipOwner == 'home') pipOwner = null;
    _setVideoPlaying(false);
    pipModeNotifier.value = false;
    homePipVideoNotifier.value = null;
    _videoCtrl?.removeListener(_onVideoStatus);
    _videoCtrl?.dispose();
    setState(() {
      _videoCtrl = null;
      _isLoading = false;
      _hasError = false;
      _inPipMode = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      color: isDark ? AppColors.darkBg : Colors.white,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // ── Top bar ──
            _TopBar(),
            const SizedBox(height: 6),
            // ── Player area (live OR YouTube) ──
            AspectRatio(
              aspectRatio: 16 / 9,
              child: _buildPlayerArea(),
            ),
            // ── Back-to-live bar (shown when a YouTube video is selected) ──
            if (widget.youtubeUrl != null)
              _BackToLiveBar(
                title: widget.youtubeTitle,
                onBack: widget.onBackToLive,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerArea() {
    // ── YouTube mode ──
    if (widget.youtubeUrl != null && _ytCtrl != null) {
      return YoutubePlayerBuilder(
        player: YoutubePlayer(
          controller: _ytCtrl!,
          showVideoProgressIndicator: true,
          progressColors: const ProgressBarColors(
            playedColor: AppColors.gold,
            handleColor: AppColors.gold,
          ),
        ),
        builder: (ctx, player) => Stack(
          children: [
            player,
            // Stop button
            Positioned(
              top: 8,
              left: 8,
              child: GestureDetector(
                onTap: widget.onBackToLive,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.stop_rounded,
                      color: Colors.white, size: 20),
                ),
              ),
            ),
          ],
        ),
      );
    }
    // Loading
    if (_isLoading) {
      return Container(
        color: Colors.black,
        child: Stack(
          children: [
            const Center(
              child: CircularProgressIndicator(color: AppColors.gold),
            ),
            Positioned(
              top: 8, right: 8,
              child: GestureDetector(
                onTap: _resetPlayer,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.stop_rounded,
                      color: Colors.white, size: 18),
                ),
              ),
            ),
          ],
        ),
      );
    }
    // Error
    if (_hasError) return _PlayerError(onRetry: _retry);
    // Playing — plain VideoPlayer + non-intercepting overlay buttons
    if (_videoCtrl != null && _videoCtrl!.value.isInitialized) {
      if (_inPipMode) return VideoPlayer(_videoCtrl!);
      return Stack(
        fit: StackFit.expand,
        children: [
          GestureDetector(
            onTap: () {
              if (_videoCtrl!.value.isPlaying) {
                _videoCtrl!.pause();
              } else {
                _videoCtrl!.play();
              }
              setState(() {});
            },
            child: VideoPlayer(_videoCtrl!),
          ),
          // Paused indicator
          ValueListenableBuilder<VideoPlayerValue>(
            valueListenable: _videoCtrl!,
            builder: (_, val, __) {
              if (val.isPlaying) return const SizedBox.shrink();
              return Center(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.play_arrow_rounded,
                      color: Colors.white, size: 40),
                ),
              );
            },
          ),
          // PiP button top-left
          Positioned(
            top: 8, left: 8,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _enterPip,
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.picture_in_picture_alt_rounded,
                      color: Colors.white, size: 20),
                ),
              ),
            ),
          ),
          // Live badge bottom-left
          Positioned(
            bottom: 8, left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.livePulse,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.circle, color: Colors.white, size: 6),
                  SizedBox(width: 4),
                  Text('مباشر',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
        ],
      );
    }
    // Cover / tap to play
    return GestureDetector(
      onTap: _startStream,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CachedNetworkImage(
            imageUrl: 'https://makkahlive.net/images/MakkahLiveCover.jpg',
            fit: BoxFit.cover,
            placeholder: (ctx, url) => Container(
              color: Colors.black,
              child: Center(
                child: Image.asset(
                  'assets/images/makkah-logo.png',
                  width: 100,
                  color: Colors.white.withValues(alpha: 0.15),
                  colorBlendMode: BlendMode.srcIn,
                ),
              ),
            ),
            errorWidget: (ctx, e, s) => Container(
              color: Colors.black,
              child: Center(
                child: Image.asset(
                  'assets/images/makkah-logo.png',
                  width: 100,
                  color: Colors.white.withValues(alpha: 0.25),
                  colorBlendMode: BlendMode.srcIn,
                ),
              ),
            ),
          ),
          const DecoratedBox(
            decoration: BoxDecoration(color: Color(0x66000000)),
          ),
          Center(
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.black38,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.gold, width: 2),
              ),
              child: const Icon(Icons.play_arrow_rounded, color: AppColors.gold, size: 48),
            ),
          ),
          Positioned(
            top: 10, right: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.livePulse,
                borderRadius: BorderRadius.circular(5),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.circle, color: Colors.white, size: 6),
                  SizedBox(width: 5),
                  Text('مباشر', style: TextStyle(
                    color: Colors.white, fontSize: 11,
                    fontWeight: FontWeight.bold,
                  )),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlayerError extends StatelessWidget {
  final VoidCallback onRetry;
  const _PlayerError({required this.onRetry});
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.wifi_off_rounded, color: AppColors.gold, size: 36),
          const SizedBox(height: 8),
          const Text('تعذر تحميل البث', style: TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 10),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, color: AppColors.gold, size: 18),
            label: const Text('إعادة المحاولة', style: TextStyle(color: AppColors.gold, fontSize: 12)),
          ),
        ],
      ),
    );
  }
}

// ─── Back-to-live bar ─────────────────────────────────────────────────────────

class _BackToLiveBar extends StatelessWidget {
  final String? title;
  final VoidCallback? onBack;
  const _BackToLiveBar({this.title, this.onBack});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.play_circle_outline_rounded,
              color: AppColors.gold, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title ?? 'فيديو مختار',
              style: TextStyle(
                color: isDark ? Colors.white70 : AppColors.lightText,
                fontSize: 12,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          GestureDetector(
            onTap: onBack,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.livePulse,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.live_tv_rounded,
                      color: Colors.white, size: 13),
                  SizedBox(width: 4),
                  Text('رجوع للبث',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconColor = isDark ? Colors.white : AppColors.lightText;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Row(
        children: [
          // ── Dark / Light mode toggle ──
          IconButton(
            icon: Icon(
              isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
              color: AppColors.gold,
              size: 25,
            ),
            tooltip: isDark ? 'الوضع النهاري' : 'الوضع الليلي',
            onPressed: () => context.read<ThemeProvider>().toggle(),
          ),
          const Spacer(),
          // ── Centered logo ──
          Image.asset(
            'assets/images/makkah-logo.png',
            height: 70,
            color: iconColor,
            colorBlendMode: BlendMode.srcIn,
            errorBuilder: (ctx, e, _) => const Text(
              'قناة مكة',
              style: TextStyle(color: AppColors.gold, fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          const Spacer(),
          // Placeholder to keep logo centred
          const SizedBox(width: 48),
        ],
      ),
    );
  }
}

// ─── Daily schedule section ───────────────────────────────────────────────────

class _DailyScheduleSection extends StatefulWidget {
  final void Function(String url, String title) onVideoSelected;
  const _DailyScheduleSection({required this.onVideoSelected});
  @override
  State<_DailyScheduleSection> createState() => _DailyScheduleSectionState();
}

class _DailyScheduleSectionState extends State<_DailyScheduleSection> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppColors.lightText;
    final cardBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    const items = StaticData.dailySchedule;

    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            title: 'البث اليومي',
            textColor: textColor,
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 200,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemCount: items.length,
              itemBuilder: (ctx, i) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width * 0.44,
                    child: _ScheduleCard(
                      entry: items[i],
                      cardBg: cardBg,
                      textColor: textColor,
                      onVideoSelected: widget.onVideoSelected,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ScheduleCard extends StatelessWidget {
  final ScheduleEntry entry;
  final Color cardBg;
  final Color textColor;
  final void Function(String url, String title) onVideoSelected;
  const _ScheduleCard({
    required this.entry,
    required this.cardBg,
    required this.textColor,
    required this.onVideoSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF2C2C2C) : const Color(0xFFF8F8F8);
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.10)
        : Colors.black.withValues(alpha: 0.08);
    return GestureDetector(
      onTap: entry.youtubeUrl != null
          ? () => onVideoSelected(entry.youtubeUrl!, entry.nameAr)
          : null,
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          color: bg,
          border: Border.all(color: borderColor, width: 1),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(45),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Thumbnail with play button ──
            SizedBox(
              height: 130,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Image
                  entry.localImage != null
                      ? Image.asset(entry.localImage!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _netImage(entry.imageUrl))
                      : _netImage(entry.imageUrl),
                  // Bottom gradient
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Color(0xAA000000)],
                        stops: [0.4, 1.0],
                      ),
                    ),
                  ),
                  // Play icon
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.gold.withValues(alpha: 0.9),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.play_arrow_rounded,
                          color: Colors.black, size: 20),
                    ),
                  ),
                ],
              ),
            ),
            // ── Info rows ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // التوقيت row
                  Row(
                    children: [
                      Text(
                        'التوقيت: ',
                        style: TextStyle(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.55)
                              : Colors.black,
                          fontSize: 10,
                        ),
                      ),
                      Text(
                        entry.timeAr,
                        style: const TextStyle(
                          color: AppColors.gold,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // البرنامج row
                  Row(
                    children: [
                      Text(
                        'البرنامج: ',
                        style: TextStyle(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.55)
                              : Colors.black,
                          fontSize: 10,
                        ),
                      ),
                      Flexible(
                        child: Text(
                          entry.nameAr,
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.black87,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _netImage(String url) => CachedNetworkImage(
        imageUrl: url,
        fit: BoxFit.cover,
        placeholder: (_, __) => Container(color: const Color(0xFF1A1A1A)),
        errorWidget: (_, __, ___) => Container(color: const Color(0xFF1A1A1A)),
      );
}

// ─── Programs section ─────────────────────────────────────────────────────────

class _ProgramsSection extends StatefulWidget {
  final VoidCallback? onViewAll;
  final void Function(String url, String title) onVideoSelected;
  const _ProgramsSection({this.onViewAll, required this.onVideoSelected});

  @override
  State<_ProgramsSection> createState() => _ProgramsSectionState();
}

class _ProgramsSectionState extends State<_ProgramsSection> {
  // null = still loading; empty = API unavailable → static fallback
  List<YouTubeVideo>? _latest;

  @override
  void initState() {
    super.initState();
    YouTubeService.fetchLatestVideos(limit: 10).then((v) {
      if (mounted) setState(() => _latest = v);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppColors.lightText;
    final cardW = MediaQuery.of(context).size.width * 0.55;
    final latest = _latest;

    Widget list;
    if (latest == null) {
      list = ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemCount: 3,
        itemBuilder: (_, i) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: SizedBox(width: cardW, child: const VideoCardSkeleton()),
        ),
      );
    } else if (latest.isNotEmpty) {
      list = ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemCount: latest.length,
        itemBuilder: (_, i) {
          final v = latest[i];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: SizedBox(
              width: cardW,
              child: VideoCard(
                video: v,
                onTap: () => widget.onVideoSelected(v.url, v.title),
              ),
            ),
          );
        },
      );
    } else {
      final programs = StaticData.programs;
      list = ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemCount: programs.length,
        itemBuilder: (ctx, i) {
          final p = programs[i];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: ProgramCard(
              program: p,
              cardWidth: MediaQuery.of(context).size.width * 0.40,
              onTap: p.youtubeUrl != null
                  ? () => widget.onVideoSelected(p.youtubeUrl!, p.nameAr)
                  : () => Navigator.push(
                        ctx,
                        MaterialPageRoute(
                          builder: (_) => ProgramDetailScreen(program: p),
                        ),
                      ),
            ),
          );
        },
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            title: 'أحدث البرامج',
            onViewAll: widget.onViewAll,
            textColor: textColor,
          ),
          const SizedBox(height: 10),
          SizedBox(height: latest != null && latest.isEmpty ? 200 : 210, child: list),
        ],
      ),
    );
  }
}

// ─── Most viewed section (الأكثر مشاهدة) ──────────────────────────────────────

class _MostViewedSection extends StatefulWidget {
  final void Function(String url, String title) onVideoSelected;
  const _MostViewedSection({required this.onVideoSelected});

  @override
  State<_MostViewedSection> createState() => _MostViewedSectionState();
}

class _MostViewedSectionState extends State<_MostViewedSection> {
  // Real counts only: null = still loading, missing id = API couldn't resolve it.
  Map<String, int>? _counts;

  @override
  void initState() {
    super.initState();
    final ids = StaticData.mostViewed
        .map((e) => YouTubeService.extractVideoId(e.url) ?? '')
        .toList();
    YouTubeService.fetchViewCounts(ids).then((c) {
      if (mounted) setState(() => _counts = c);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppColors.lightText;
    final subColor = isDark ? Colors.white54 : AppColors.lightTextSub;
    const items = StaticData.mostViewed;

    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(title: 'الأكثر مشاهدة', textColor: textColor),
          const SizedBox(height: 6),
          ...List.generate(items.length, (i) {
            final item = items[i];
            final id = YouTubeService.extractVideoId(item.url) ?? '';
            final counts = _counts;
            final Widget views;
            if (counts == null) {
              views = Container(
                width: 36,
                height: 10,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface2 : AppColors.lightSurface3,
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            } else {
              final c = counts[id];
              views = Text(
                c == null ? 'غير متاح' : YouTubeService.formatViewCount(c),
                style: TextStyle(color: subColor, fontSize: 11),
              );
            }
            return InkWell(
              onTap: () => widget.onVideoSelected(item.url, item.title),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Container(
                      width: 26,
                      height: 26,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.gold.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text('${i + 1}',
                          style: const TextStyle(
                              color: AppColors.gold, fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(item.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: textColor, fontSize: 14)),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.remove_red_eye_outlined, size: 13, color: AppColors.gold),
                    const SizedBox(width: 4),
                    views,
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ─── Channel info section (أحداثيات القناة / ترددات) ─────────────────────────

class _ChannelInfoSection extends StatelessWidget {
  const _ChannelInfoSection();

  @override
  Widget build(BuildContext context) => const FrequencyStrip();
}

// ─── Section header ───────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onViewAll;
  final String? viewAllLabel;
  final Color textColor;
  const _SectionHeader({required this.title, this.onViewAll, this.viewAllLabel, required this.textColor});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              ColorFiltered(
                colorFilter: ColorFilter.mode(
                  isDark ? Colors.white : AppColors.lightText,
                  BlendMode.srcIn,
                ),
                child: Image.asset(
                  'assets/images/makkah-logo cicle.png',
                  height: 42,
                  errorBuilder: (_, __, ___) => Container(
                    width: 4, height: 22,
                    decoration: BoxDecoration(
                      color: AppColors.gold,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(title,
                  style: TextStyle(
                      color: textColor, fontSize: 17, fontWeight: FontWeight.bold)),
            ],
          ),
          if (onViewAll != null)
            GestureDetector(
              onTap: onViewAll,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.gold.withOpacity(0.15),
                  border: Border.all(color: AppColors.gold, width: 1.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  (viewAllLabel != null && viewAllLabel!.startsWith('عرض أقل'))
                      ? Icons.remove
                      : Icons.add,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── News card ────────────────────────────────────────────────────────────────

class _NewsCard extends StatelessWidget {
  final Article article;
  const _NewsCard({required this.article});

  Future<void> _openYoutube(BuildContext context) async {
    final url = article.youtubeUrl;
    if (url == null) return;
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final borderColor = isDark ? Colors.white10 : const Color(0x22D4AF37);
    final titleColor = isDark ? Colors.white : AppColors.lightText;

    return GestureDetector(
      onTap: () {
        if (article.youtubeUrl != null) {
          _openYoutube(context);
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => NewsDetailScreen(article: article)),
          );
        }
      },
      child: Container(
      width: 245,
      margin: const EdgeInsets.only(left: 12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
        boxShadow: isDark ? [] : [
          BoxShadow(color: AppColors.gold.withValues(alpha: 0.06), blurRadius: 8),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(12),
              bottomRight: Radius.circular(12),
            ),
            child: SizedBox(
              width: 85,
              height: double.infinity,
              child: article.imageUrl != null
                  ? (article.imageUrl!.startsWith('asset:')
                      ? Image.asset(
                          article.imageUrl!.substring(6),
                          fit: BoxFit.cover,
                          errorBuilder: (ctx, e, s) => _imgPlaceholder(isDark),
                        )
                      : CachedNetworkImage(
                          imageUrl: article.imageUrl!,
                          fit: BoxFit.cover,
                          errorWidget: (ctx, e, s) => _imgPlaceholder(isDark),
                        ))
                  : _imgPlaceholder(isDark),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (article.category != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.gold.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(article.category!,
                          style: const TextStyle(color: AppColors.gold, fontSize: 9)),
                    ),
                  Text(
                    article.title,
                    style: TextStyle(
                        color: titleColor, fontSize: 12, fontWeight: FontWeight.w600),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
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

  Widget _imgPlaceholder(bool isDark) => Container(
        color: isDark ? AppColors.darkSurface2 : AppColors.lightSurface3,
        child: const Center(
            child: Icon(Icons.article_rounded, color: AppColors.gold, size: 28)),
      );
}

// ─── Social section (bottom of home scroll) ────────────────────────────────

class _SocialSection extends StatelessWidget {
  const _SocialSection();

  static const List<_SocialItem> _socials = [
    _SocialItem(icon: FontAwesomeIcons.facebook,  url: 'https://www.facebook.com/makkahtv'),
    _SocialItem(icon: FontAwesomeIcons.xTwitter,  url: 'https://twitter.com/makkahtv'),
    _SocialItem(icon: FontAwesomeIcons.youtube,   url: 'https://www.youtube.com/makkahtv'),
    _SocialItem(icon: FontAwesomeIcons.instagram, url: 'https://www.instagram.com/makkahtv'),
    _SocialItem(icon: FontAwesomeIcons.tiktok,    url: 'https://www.tiktok.com/@makkahtv.tv'),
  ];

  Future<void> _launch(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconColor = isDark ? Colors.white : AppColors.lightText;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28),
      child: Column(
        children: [
          const Divider(color: Color(0x22D4AF37), indent: 32, endIndent: 32),
          const SizedBox(height: 16),
          const Text(
            'تابعونا',
            style: TextStyle(
              color: AppColors.gold,
              fontSize: 13,
              letterSpacing: 1.5,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: _socials
                .map((s) => GestureDetector(
                      onTap: () => _launch(s.url),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: AppColors.gold.withValues(alpha: 0.35), width: 1),
                          color: AppColors.gold.withValues(alpha: 0.08),
                        ),
                        child: FaIcon(s.icon, color: iconColor, size: 18),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 16),
          const Divider(color: Color(0x22D4AF37), indent: 32, endIndent: 32),
        ],
      ),
    );
  }
}

class _SocialItem {
  final FaIconData icon;
  final String url;
  const _SocialItem({required this.icon, required this.url});
}
