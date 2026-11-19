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
import '../models/youtube_video.dart';
import '../data/static_data.dart';
import '../pip_state.dart';
import '../services/youtube_service.dart';
import '../widgets/app_youtube_player.dart';
import '../widgets/frequency_strip.dart';
import '../widgets/menu_button.dart';
import '../widgets/video_card.dart';

const _homePipChannel = MethodChannel('makkah.tv/pip');

/// Home, same layout as the web: live player → الأكثر مشاهدة (real API) →
/// channel frequencies → social accounts.
class HomeScreen extends StatefulWidget {
  final VoidCallback? onOpenMenu;
  final VoidCallback? onGoToLibrary;
  const HomeScreen({super.key, this.onOpenMenu, this.onGoToLibrary});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _scrollCtrl = ScrollController();
  String? _selectedYoutubeUrl;
  String? _selectedTitle;
  // Bumped on every tap so re-tapping the same video restarts it.
  int _selectionSeq = 0;

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onVideoSelected(String url, String title) {
    setState(() {
      _selectedYoutubeUrl = url;
      _selectedTitle = title;
      _selectionSeq++;
    });
    if (_scrollCtrl.hasClients) {
      _scrollCtrl.animateTo(
        0,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOut,
      );
    }
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
          youtubeUrl: _selectedYoutubeUrl,
          youtubeTitle: _selectedTitle,
          selectionSeq: _selectionSeq,
          onBackToLive: _onBackToLive,
          onOpenMenu: widget.onOpenMenu,
        )),
        SliverToBoxAdapter(
          child: _MostViewedSection(onVideoSelected: _onVideoSelected),
        ),
        SliverToBoxAdapter(
          child: _LatestVideosSection(
            onVideoSelected: _onVideoSelected,
            onShowMore: widget.onGoToLibrary,
          ),
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
  final String? youtubeUrl;
  final String? youtubeTitle;
  final int selectionSeq;
  final VoidCallback? onBackToLive;
  final VoidCallback? onOpenMenu;
  const _HeroSection({
    this.youtubeUrl,
    this.youtubeTitle,
    this.selectionSeq = 0,
    this.onBackToLive,
    this.onOpenMenu,
  });

  @override
  State<_HeroSection> createState() => _HeroSectionState();
}

class _HeroSectionState extends State<_HeroSection> with WidgetsBindingObserver {
  static const _maxAutoRetries = 4;

  VideoPlayerController? _videoCtrl;
  YoutubePlayerController? _ytCtrl;
  bool _isLoading = true;
  bool _hasError = false;
  bool _inPipMode = false;
  StreamSubscription? _pipSub;
  bool _pendingPipExit = false;

  // The home tab stays alive inside MainScaffold's IndexedStack. While it's
  // hidden (or the app is in background) the live stream is fully released
  // — not just paused — and restarted fresh on return. A paused live HLS
  // stream goes stale and errors/freezes when resumed, and keeping it would
  // mean two live players running at once with the live tab.
  bool _tabVisible = true;
  bool _inBackground = false;
  bool _autoResume = false;

  int _retries = 0;
  Timer? _retryTimer;
  Timer? _stallTimer;
  Duration _lastPos = Duration.zero;
  int _stallTicks = 0;
  FullscreenPlayer? _liveFs;

  // After a pause the stream resumes where it stopped, i.e. behind the live
  // edge. Tracked so the player can offer "back to live" (latest second).
  final _behindLive = ValueNotifier<bool>(false);
  bool _hasPlayed = false;

  // Audio-only mode: the live stream keeps playing (sound only) with the
  // screen off / app in background. On Android a foreground service keeps
  // the process, CPU and Wi-Fi awake meanwhile.
  bool _audioOnly = false;

  bool get _youtubeActive => widget.youtubeUrl != null;
  bool get _canPlayLive => mounted &&
      _tabVisible &&
      (!_inBackground || _audioOnly) &&
      !_youtubeActive;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (Platform.isAndroid) {
      _pipSub = pipEvents.listen(_onPipEvent);
    }
    if (widget.youtubeUrl != null) {
      _isLoading = false;
      _loadYoutube(widget.youtubeUrl!);
    } else {
      // Auto-start live stream when the home page opens
      WidgetsBinding.instance.addPostFrameCallback((_) => _startStream());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pipSub?.cancel();
    _retryTimer?.cancel();
    _stallTimer?.cancel();
    final fs = _liveFs;
    if (fs != null) clearFullscreen(fs);
    if (homePipVideoNotifier.value == _videoCtrl) homePipVideoNotifier.value = null;
    if (_audioOnly) _setAudioService(false);
    _videoCtrl?.removeListener(_onVideoStatus);
    _videoCtrl?.dispose();
    _ytCtrl?.dispose();
    _behindLive.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final visible = TickerMode.valuesOf(context).enabled;
    if (visible == _tabVisible) return;
    _tabVisible = visible;
    if (!visible) {
      _ytCtrl?.pause();
      if (_videoCtrl != null || _isLoading) {
        _releaseLive();
        _autoResume = true;
      }
    } else if (_autoResume && !_youtubeActive) {
      _autoResume = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_canPlayLive && _videoCtrl == null) _startStream();
      });
    }
  }

  @override
  void didUpdateWidget(_HeroSection old) {
    super.didUpdateWidget(old);
    final urlChanged = widget.youtubeUrl != old.youtubeUrl;
    if (!urlChanged && widget.selectionSeq == old.selectionSeq) return;
    if (widget.youtubeUrl != null) {
      // Switch to YouTube: fully stop the live stream so it can't keep
      // loading/playing underneath the video.
      _releaseLive();
      _autoResume = false;
      _loadYoutube(widget.youtubeUrl!);
    } else if (urlChanged) {
      // Back to live: always a fresh stream (an old paused one is stale).
      _disposeYoutube();
      _isLoading = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_youtubeActive) _startStream(manual: true);
      });
    }
  }

  // ── YouTube ────────────────────────────────────────────────────────────────

  void _loadYoutube(String url) {
    final id = YoutubePlayer.convertUrlToId(url);
    if (id == null) return;
    final current = _ytCtrl;
    if (current != null && current.value.isReady) {
      // Reuse the loaded player: instant switch, keeps fullscreen state.
      if (current.metadata.videoId == id) {
        current.seekTo(Duration.zero);
        current.play();
      } else {
        current.load(id);
      }
      return;
    }
    _ytCtrl = YoutubePlayerController(
      initialVideoId: id,
      flags: const YoutubePlayerFlags(autoPlay: true, mute: false, enableCaption: false),
    );
    // Dispose the previous controller only after its widget left the tree.
    if (current != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => current.dispose());
    }
  }

  void _disposeYoutube() {
    final c = _ytCtrl;
    _ytCtrl = null;
    if (c != null) {
      c.pause();
      WidgetsBinding.instance.addPostFrameCallback((_) => c.dispose());
    }
  }

  // ── PiP / lifecycle ───────────────────────────────────────────────────────

  void _onPipEvent(bool isInPip) {
    if (!mounted || pipOwner != 'home') return;
    if (isInPip && _videoCtrl == null) return;
    pipModeNotifier.value = isInPip;
    setState(() => _inPipMode = isInPip);
    if (!isInPip) {
      pipOwner = null;
      // PiP exited: set flag so lifecycle:resumed can resume playback.
      // If the app stays in background (PiP dismissed), the paused
      // lifecycle event will release the stream instead.
      _pendingPipExit = true;
      Future.delayed(const Duration(milliseconds: 2000), () {
        if (mounted) _pendingPipExit = false;
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!mounted) return;
    if (state == AppLifecycleState.resumed) {
      _inBackground = false;
      if (_pendingPipExit) {
        // User expanded PiP back to full screen — resume playback.
        _pendingPipExit = false;
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted && _videoCtrl?.value.isInitialized == true) _videoCtrl?.play();
        });
      } else if (_autoResume && _canPlayLive && _videoCtrl == null) {
        _autoResume = false;
        _startStream();
      }
    } else if ((state == AppLifecycleState.paused ||
            state == AppLifecycleState.hidden) &&
        !_inPipMode) {
      _inBackground = true;
      _ytCtrl?.pause();
      // Audio-only: keep the live sound going with the screen off.
      if (_audioOnly) return;
      if (_videoCtrl != null || _isLoading) {
        _releaseLive();
        _autoResume = true;
        setState(() {});
      }
    }
  }

  Future<void> _setVideoPlaying(bool playing) async {
    try {
      if (Platform.isAndroid) {
        await _homePipChannel.invokeMethod('setVideoPlaying', playing);
      }
    } catch (_) {}
  }

  Future<void> _setAudioService(bool on) async {
    try {
      if (Platform.isAndroid) {
        await _homePipChannel.invokeMethod(
            on ? 'startAudioService' : 'stopAudioService');
      }
    } catch (_) {}
  }

  void _toggleAudioOnly() {
    final on = !_audioOnly;
    setState(() => _audioOnly = on);
    _setAudioService(on);
    final c = _videoCtrl;
    if (on && c != null && c.value.isInitialized && !c.value.isPlaying) c.play();
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

  // ── Live stream ───────────────────────────────────────────────────────────

  Future<void> _startStream({bool manual = false, bool fullscreen = false}) async {
    if (!mounted || _youtubeActive) return;
    if (manual) _retries = 0;
    _retryTimer?.cancel();
    _disposeLiveCtrl();
    _behindLive.value = false;
    _hasPlayed = false;
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    final ctrl = VideoPlayerController.networkUrl(
      Uri.parse(StaticData.liveStream.streamUrl),
      httpHeaders: const {'User-Agent': 'MakkahTV/1.0 Flutter'},
      formatHint: VideoFormat.hls,
      // We pause/release on background ourselves; this only lets the
      // audio-only mode keep playing with the screen off.
      videoPlayerOptions: VideoPlayerOptions(allowBackgroundPlayback: true),
    );
    _videoCtrl = ctrl;
    // Tab switch / YouTube / stop can replace the controller while we're
    // awaiting below — bail out quietly instead of erroring.
    bool stale() => !mounted || _videoCtrl != ctrl;
    try {
      await ctrl.initialize().timeout(const Duration(seconds: 20));
      if (stale()) return;
      ctrl.addListener(_onVideoStatus);
      if (_canPlayLive) await ctrl.play();
      if (stale()) return;
      _retries = 0;
      setState(() => _isLoading = false);
      homePipVideoNotifier.value = ctrl;
      _setVideoPlaying(true);
      _startStallWatch();
      if (fullscreen) _enterLiveFullscreen();
    } catch (_) {
      if (stale()) return;
      _scheduleRetry();
    }
  }

  /// Network hiccups (very common right after launch, before Wi-Fi is fully
  /// up) retry automatically with backoff before showing an error.
  void _scheduleRetry() {
    if (!mounted) return;
    _disposeLiveCtrl();
    if (_retries >= _maxAutoRetries) {
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
      return;
    }
    _retries++;
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    _retryTimer?.cancel();
    _retryTimer = Timer(Duration(seconds: 1 << (_retries - 1)), () {
      if (_canPlayLive) _startStream();
    });
  }

  void _onVideoStatus() {
    final c = _videoCtrl;
    if (!mounted || c == null) return;
    if (c.value.hasError) {
      c.removeListener(_onVideoStatus);
      // Not inside the controller's own notifyListeners (it gets disposed).
      scheduleMicrotask(_scheduleRetry);
      return;
    }
    if (c.value.isPlaying) {
      _hasPlayed = true;
    } else if (_hasPlayed && c.value.isInitialized) {
      _behindLive.value = true;
    }
  }

  /// Jumps to the latest second of the broadcast. A fresh HLS session always
  /// starts at the live edge, so the stream is restarted (keeping fullscreen).
  void _goLive() {
    final wasFullscreen = _liveFs != null;
    _startStream(manual: true, fullscreen: wasFullscreen);
  }

  Widget _liveButton() =>
      _GoLiveButton(behindLive: _behindLive, onTap: _goLive);

  /// Restarts the stream if it's "playing" but frozen for ~15s.
  void _startStallWatch() {
    _stallTimer?.cancel();
    _stallTicks = 0;
    _lastPos = Duration.zero;
    _stallTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      final c = _videoCtrl;
      if (!mounted || c == null || !c.value.isInitialized) return;
      if (!c.value.isPlaying) {
        _stallTicks = 0;
        return;
      }
      final pos = c.value.position;
      _stallTicks = pos == _lastPos ? _stallTicks + 1 : 0;
      _lastPos = pos;
      if (_stallTicks >= 3) {
        _retries = 0;
        _scheduleRetry();
      }
    });
  }

  void _disposeLiveCtrl() {
    _stallTimer?.cancel();
    _stallTimer = null;
    final c = _videoCtrl;
    if (c == null) return;
    _videoCtrl = null;
    c.removeListener(_onVideoStatus);
    if (homePipVideoNotifier.value == c) homePipVideoNotifier.value = null;
    _exitLiveFullscreen();
    _setVideoPlaying(false);
    c.dispose();
  }

  /// Stops everything live-related without calling setState (safe from
  /// didChangeDependencies / didUpdateWidget, which rebuild right after).
  void _releaseLive() {
    _retryTimer?.cancel();
    _pendingPipExit = false;
    if (pipOwner == 'home') pipOwner = null;
    if (_audioOnly) {
      _audioOnly = false;
      _setAudioService(false);
    }
    _disposeLiveCtrl();
    _isLoading = false;
    _hasError = false;
    _retries = 0;
  }

  void _retry() => _startStream(manual: true);

  /// Stop button: back to the cover image.
  void _resetPlayer() {
    _releaseLive();
    _autoResume = false;
    pipModeNotifier.value = false;
    setState(() => _inPipMode = false);
  }

  void _enterLiveFullscreen() {
    final c = _videoCtrl;
    if (c == null || !c.value.isInitialized) return;
    final entry = FullscreenPlayer(
      child: _LiveFullscreenView(
        controller: c,
        onExit: _exitLiveFullscreen,
        liveButton: _liveButton(),
      ),
      exit: _exitLiveFullscreen,
    );
    _liveFs = entry;
    showFullscreen(entry);
    enterLandscapeFullscreen();
  }

  void _exitLiveFullscreen() {
    final fs = _liveFs;
    _liveFs = null;
    if (fs != null) clearFullscreen(fs);
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
            _TopBar(onOpenMenu: widget.onOpenMenu),
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

  Widget _overlayButton({
    required IconData icon,
    required VoidCallback onTap,
    double size = 20,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black54,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, color: Colors.white, size: size),
        ),
      ),
    );
  }

  Widget _buildPlayerArea() {
    // ── YouTube mode ──
    if (_youtubeActive) {
      final yt = _ytCtrl;
      if (yt == null) return const ColoredBox(color: Colors.black);
      return AppYoutubePlayer(
        key: ObjectKey(yt),
        controller: yt,
        overlays: [
          // Stop button → back to live
          Positioned(
            top: 8,
            left: 8,
            child: _overlayButton(
              icon: Icons.stop_rounded,
              onTap: () => widget.onBackToLive?.call(),
            ),
          ),
        ],
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
              child: _overlayButton(
                icon: Icons.stop_rounded,
                onTap: _resetPlayer,
                size: 18,
              ),
            ),
          ],
        ),
      );
    }
    // Error
    if (_hasError) return _PlayerError(onRetry: _retry);
    // Playing — plain VideoPlayer + non-intercepting overlay buttons
    final ctrl = _videoCtrl;
    if (ctrl != null && ctrl.value.isInitialized) {
      if (_inPipMode) return VideoPlayer(ctrl);
      if (_audioOnly) return _buildAudioOnly(ctrl);
      return Stack(
        fit: StackFit.expand,
        children: [
          GestureDetector(
            onTap: () {
              if (ctrl.value.isPlaying) {
                ctrl.pause();
              } else {
                ctrl.play();
              }
            },
            child: VideoPlayer(ctrl),
          ),
          // Paused indicator
          ValueListenableBuilder<VideoPlayerValue>(
            valueListenable: ctrl,
            builder: (_, val, __) {
              if (val.isPlaying) return const SizedBox.shrink();
              return IgnorePointer(
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: const BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.play_arrow_rounded,
                        color: Colors.white, size: 40),
                  ),
                ),
              );
            },
          ),
          // PiP button top-left
          Positioned(
            top: 8, left: 8,
            child: _overlayButton(
              icon: Icons.picture_in_picture_alt_rounded,
              onTap: _enterPip,
            ),
          ),
          // Audio-only toggle top-right
          Positioned(
            top: 8, right: 8,
            child: _overlayButton(
              icon: Icons.headphones_rounded,
              onTap: _toggleAudioOnly,
            ),
          ),
          // Fullscreen button bottom-right
          Positioned(
            bottom: 8, right: 8,
            child: _overlayButton(
              icon: Icons.fullscreen_rounded,
              onTap: _enterLiveFullscreen,
            ),
          ),
          // Live badge bottom-left — becomes "back to live" after a pause
          Positioned(
            bottom: 8, left: 8,
            child: _liveButton(),
          ),
        ],
      );
    }
    // Cover / tap to play
    return GestureDetector(
      onTap: _retry,
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
          const Positioned(
            top: 10, right: 10,
            child: _LiveBadge(),
          ),
        ],
      ),
    );
  }
}

extension on _HeroSectionState {
  /// Audio-only view: cover image + headphones, tap to play/pause.
  Widget _buildAudioOnly(VideoPlayerController ctrl) {
    return Stack(
      fit: StackFit.expand,
      children: [
        CachedNetworkImage(
          imageUrl: 'https://makkahlive.net/images/MakkahLiveCover.jpg',
          fit: BoxFit.cover,
          errorWidget: (_, _, _) => const ColoredBox(color: Colors.black),
        ),
        const DecoratedBox(decoration: BoxDecoration(color: Color(0x99000000))),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => ctrl.value.isPlaying ? ctrl.pause() : ctrl.play(),
          child: Center(
            child: ValueListenableBuilder<VideoPlayerValue>(
              valueListenable: ctrl,
              builder: (_, val, _) => Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.black38,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.gold, width: 2),
                    ),
                    child: Icon(
                      val.isPlaying
                          ? Icons.headphones_rounded
                          : Icons.play_arrow_rounded,
                      color: AppColors.gold,
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    val.isPlaying ? 'وضع الصوت فقط' : 'متوقف مؤقتاً',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ),
        // Back to video
        Positioned(
          top: 8, right: 8,
          child: _overlayButton(
            icon: Icons.videocam_rounded,
            onTap: _toggleAudioOnly,
          ),
        ),
        Positioned(bottom: 8, left: 8, child: _liveButton()),
      ],
    );
  }
}

class _LiveBadge extends StatelessWidget {
  const _LiveBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
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
    );
  }
}

/// Red "مباشر" badge while at the live edge; after a pause it turns into a
/// "back to live" button that jumps to the latest second of the broadcast.
class _GoLiveButton extends StatelessWidget {
  final ValueNotifier<bool> behindLive;
  final VoidCallback onTap;
  const _GoLiveButton({required this.behindLive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: behindLive,
      builder: (_, behind, _) {
        if (!behind) return const _LiveBadge();
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.livePulse),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.circle, color: AppColors.livePulse, size: 8),
                  SizedBox(width: 6),
                  Text('العودة للبث المباشر',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold)),
                  SizedBox(width: 4),
                  Icon(Icons.fast_forward_rounded, color: Colors.white, size: 16),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Live stream shown in the app-wide fullscreen layer (landscape).
class _LiveFullscreenView extends StatelessWidget {
  final VideoPlayerController controller;
  final VoidCallback onExit;
  final Widget liveButton;
  const _LiveFullscreenView({
    required this.controller,
    required this.onExit,
    required this.liveButton,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        GestureDetector(
          onTap: () =>
              controller.value.isPlaying ? controller.pause() : controller.play(),
          child: Center(
            child: AspectRatio(
              aspectRatio: controller.value.aspectRatio > 0
                  ? controller.value.aspectRatio
                  : 16 / 9,
              child: VideoPlayer(controller),
            ),
          ),
        ),
        ValueListenableBuilder<VideoPlayerValue>(
          valueListenable: controller,
          builder: (_, val, __) {
            if (val.isPlaying) return const SizedBox.shrink();
            return const IgnorePointer(
              child: Center(
                child: Icon(Icons.play_circle_fill_rounded,
                    color: Colors.white70, size: 64),
              ),
            );
          },
        ),
        Positioned(
          top: 16,
          left: 16,
          child: Material(
            color: Colors.black54,
            shape: const CircleBorder(),
            child: IconButton(
              icon: const Icon(Icons.fullscreen_exit_rounded, color: Colors.white),
              onPressed: onExit,
            ),
          ),
        ),
        Positioned(top: 24, right: 20, child: liveButton),
      ],
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
  final VoidCallback? onOpenMenu;
  const _TopBar({this.onOpenMenu});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconColor = isDark ? Colors.white : AppColors.lightText;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Row(
        children: [
          // ── Side menu toggle (like the web header's ☰) ──
          if (onOpenMenu != null)
            MenuButton(onPressed: onOpenMenu!)
          else
            const SizedBox(width: 48),
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
        ],
      ),
    );
  }
}

// ─── Most viewed section (الأكثر مشاهدة) ──────────────────────────────────────
// Same as the web: the channel's real top 7 from the YouTube API. Falls back
// to the static list (with real view counts) only if that can't be fetched.

class _TopItem {
  final String title;
  final String url;
  final String thumbnail;

  /// null = still loading, -1 = unavailable.
  final int? views;
  const _TopItem({required this.title, required this.url, this.thumbnail = '', this.views});

  _TopItem withViews(int v) =>
      _TopItem(title: title, url: url, thumbnail: thumbnail, views: v);
}

class _MostViewedSection extends StatefulWidget {
  final void Function(String url, String title) onVideoSelected;
  const _MostViewedSection({required this.onVideoSelected});

  @override
  State<_MostViewedSection> createState() => _MostViewedSectionState();
}

class _MostViewedSectionState extends State<_MostViewedSection> {
  static const _limit = 5;
  static final _channelSuffix = RegExp(r'\s*\|\s*قناة مكة\s*$');

  List<_TopItem>? _items; // null = loading

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final top = await YouTubeService.fetchTopVideos(limit: _limit);
    if (!mounted) return;
    if (top.isNotEmpty) {
      setState(() => _items = [
            for (final v in top)
              _TopItem(
                title: v.title.replaceAll(_channelSuffix, ''),
                url: v.url,
                thumbnail: v.thumbnail,
                views: v.viewCount,
              ),
          ]);
      return;
    }

    // Fallback: static list, real counts only (never fake numbers).
    final fallback = [
      for (final e in StaticData.mostViewed.take(_limit)) _TopItem(title: e.title, url: e.url),
    ];
    setState(() => _items = fallback);
    final ids = fallback.map((e) => YouTubeService.extractVideoId(e.url) ?? '').toList();
    final counts = await YouTubeService.fetchViewCounts(ids);
    if (!mounted) return;
    setState(() => _items = [
          for (var i = 0; i < fallback.length; i++)
            fallback[i].withViews(counts[ids[i]] ?? -1),
        ]);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppColors.lightText;
    final subColor = isDark ? Colors.white54 : AppColors.lightTextSub;
    final skeleton = isDark ? AppColors.darkSurface2 : AppColors.lightSurface3;
    final items = _items;

    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(title: 'الأكثر مشاهدة', textColor: textColor),
          // Same gap as between the last video and the ترددات title (7 + 40).
          const SizedBox(height: 40),
          if (items == null)
            for (var i = 0; i < _limit; i++)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Container(
                      width: 96,
                      height: 54,
                      decoration: BoxDecoration(
                          color: skeleton, borderRadius: BorderRadius.circular(6)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        height: 12,
                        decoration: BoxDecoration(
                            color: skeleton, borderRadius: BorderRadius.circular(4)),
                      ),
                    ),
                  ],
                ),
              )
          else
            for (var i = 0; i < items.length; i++)
              _buildRow(items[i], i, textColor, subColor, skeleton),
        ],
      ),
    );
  }

  Widget _buildRow(_TopItem item, int i, Color textColor, Color subColor, Color skeleton) {
    final Widget views;
    if (item.views == null) {
      views = Container(
        width: 36,
        height: 10,
        decoration: BoxDecoration(color: skeleton, borderRadius: BorderRadius.circular(4)),
      );
    } else {
      views = Text(
        item.views! < 0 ? 'غير متاح' : YouTubeService.formatViewCount(item.views!),
        style: TextStyle(color: subColor, fontSize: 12),
      );
    }
    return InkWell(
      onTap: () => widget.onVideoSelected(item.url, item.title),
      child: Padding(
        // Thumbnails a bit inset; section titles stick out past them (RTL).
        padding: const EdgeInsetsDirectional.fromSTEB(32, 7, 16, 7),
        child: Row(
          children: [
            if (item.thumbnail.isNotEmpty) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: CachedNetworkImage(
                  imageUrl: item.thumbnail,
                  width: 96,
                  height: 54,
                  fit: BoxFit.cover,
                  errorWidget: (_, _, _) =>
                      Container(width: 96, height: 54, color: skeleton),
                ),
              ),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: Text(item.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: textColor, fontSize: 13, height: 1.35)),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.remove_red_eye_outlined, size: 13, color: AppColors.gold),
            const SizedBox(width: 4),
            views,
          ],
        ),
      ),
    );
  }
}

// ─── Latest videos (أحدث الفيديوهات) ──────────────────────────────────────────
// 8 videos picked at random from the channel's newest uploads, in a
// horizontal slider. Tapping one plays it in the player at the top.

class _LatestVideosSection extends StatefulWidget {
  final void Function(String url, String title) onVideoSelected;

  /// "عرض المزيد" card at the end of the slider → مكتبة البرامج tab.
  final VoidCallback? onShowMore;
  const _LatestVideosSection({required this.onVideoSelected, this.onShowMore});

  @override
  State<_LatestVideosSection> createState() => _LatestVideosSectionState();
}

class _LatestVideosSectionState extends State<_LatestVideosSection> {
  static const _count = 8;
  static const _pool = 24; // newest uploads to pick the random 8 from

  List<YouTubeVideo>? _videos; // null = loading
  int _attempts = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final latest = await YouTubeService.fetchLatestVideos(limit: _pool);
    if (!mounted) return;
    if (latest.isEmpty && YouTubeService.isConfigured && _attempts < 3) {
      _attempts++;
      Future.delayed(Duration(seconds: 3 * _attempts), () {
        if (mounted) _load();
      });
      return;
    }
    setState(() => _videos = (List.of(latest)..shuffle()).take(_count).toList());
  }

  @override
  Widget build(BuildContext context) {
    final videos = _videos;
    // Nothing to show (API unavailable) → hide the section entirely.
    if (videos != null && videos.isEmpty) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppColors.lightText;
    final cardW = MediaQuery.of(context).size.width * 0.55;

    return Padding(
      // Same spacing as the other home sections (see _MostViewedSection).
      padding: const EdgeInsets.only(top: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(title: 'أحدث الفيديوهات', textColor: textColor),
          const SizedBox(height: 20),
          SizedBox(
            height: 210,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              itemCount: videos == null
                  ? 3
                  : videos.length + (widget.onShowMore != null ? 1 : 0),
              itemBuilder: (_, i) {
                if (videos != null && i == videos.length) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: _ShowMoreCard(onTap: widget.onShowMore!),
                  );
                }
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: SizedBox(
                    width: cardW,
                    child: videos == null
                        ? const VideoCardSkeleton()
                        : VideoCard(
                            video: videos[i],
                            onTap: () =>
                                widget.onVideoSelected(videos[i].url, videos[i].title),
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

class _ShowMoreCard extends StatelessWidget {
  final VoidCallback onTap;
  const _ShowMoreCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 130,
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.gold.withValues(alpha: 0.5)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.gold.withValues(alpha: 0.15),
                border: Border.all(color: AppColors.gold),
              ),
              child: const Icon(Icons.arrow_forward_rounded, color: AppColors.gold, size: 26),
            ),
            const SizedBox(height: 12),
            const Text('عرض المزيد',
                style: TextStyle(
                    color: AppColors.gold, fontSize: 14, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('مكتبة البرامج',
                style: TextStyle(
                    color: isDark ? Colors.white54 : AppColors.lightTextSub, fontSize: 11)),
          ],
        ),
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
      // Titles stick out toward the edge (RTL); same inset as the ترددات header.
      padding: const EdgeInsetsDirectional.fromSTEB(4, 0, 16, 0),
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
