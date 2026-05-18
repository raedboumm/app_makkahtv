import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:share_plus/share_plus.dart';
import '../app_theme.dart';
import '../data/static_data.dart';
import '../pip_state.dart';
import '../widgets/frequency_strip.dart';

// Channels for PiP on Android
const _pipChannel = MethodChannel('makkah.tv/pip');
const _pipEvents  = EventChannel('makkah.tv/pip_events');

class LiveTab extends StatefulWidget {
  const LiveTab({super.key});

  @override
  State<LiveTab> createState() => _LiveTabState();
}

class _LiveTabState extends State<LiveTab> with WidgetsBindingObserver {
  VideoPlayerController? _videoCtrl;
  ChewieController? _chewieCtrl;
  bool _isLoading = false;
  bool _hasError = false;
  bool _playerStarted = false;
  bool _audioOnly = false;
  bool _inPipMode = false;
  StreamSubscription? _pipSub;
  bool _pendingPipExit = false;
  bool _resumedBeforePipExit = false;
  final _freqKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (Platform.isAndroid) {
      _pipSub = _pipEvents.receiveBroadcastStream().listen(_onPipEvent);
    }
    // didChangeDependencies handles auto-start
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pipSub?.cancel();
    _setVideoPlaying(false);
    _videoCtrl?.dispose();
    _chewieCtrl?.dispose();
    super.dispose();
  }

  void _onPipEvent(dynamic event) {
    if (!mounted) return;
    final isInPip = event as bool;
    if (isInPip && _chewieCtrl == null) return;
    pipModeNotifier.value = isInPip;
    setState(() => _inPipMode = isInPip);
    if (!isInPip) {
      if (_resumedBeforePipExit) {
        // resumed already fired before this event — user expanded back to fullscreen
        _resumedBeforePipExit = false;
        _pendingPipExit = false;
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted && _videoCtrl?.value.isInitialized == true) _videoCtrl?.play();
        });
      } else {
        // resumed hasn't fired yet — could be expand or dismiss, start timer
        _pendingPipExit = true;
        Future.delayed(const Duration(milliseconds: 800), () {
          if (mounted && _pendingPipExit) _resetPlayer();
        });
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (_pendingPipExit) {
        // Case A: onPipEvent(false) fired first, then resumed — user expanded
        _pendingPipExit = false;
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted && _videoCtrl?.value.isInitialized == true) _videoCtrl?.play();
        });
      } else if (_inPipMode) {
        // Case B: resumed fired first, onPipEvent(false) coming shortly
        _resumedBeforePipExit = true;
      }
    }
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      if (_audioOnly && _videoCtrl?.value.isInitialized == true) {
        Future.delayed(const Duration(milliseconds: 400), () {
          if (mounted && _audioOnly && _videoCtrl?.value.isInitialized == true) {
            _videoCtrl?.play();
          }
        });
      } else if (!_inPipMode && !_pendingPipExit && !_resumedBeforePipExit) {
        _videoCtrl?.pause();
      }
    }
  }

  Future<void> _setVideoPlaying(bool playing) async {
    try {
      if (Platform.isAndroid) {
        await _pipChannel.invokeMethod('setVideoPlaying', playing);
      }
    } catch (_) {}
  }

  Future<void> _startStream() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _playerStarted = true;
    });

    final stream = StaticData.liveStream;

    try {
      _videoCtrl = VideoPlayerController.networkUrl(
        Uri.parse(stream.streamUrl),
        httpHeaders: const {'User-Agent': 'MakkahTV/1.0 Flutter'},
      );
      await _videoCtrl!.initialize();

      _chewieCtrl = ChewieController(
        videoPlayerController: _videoCtrl!,
        autoPlay: true,
        looping: false,
        isLive: true,
        allowFullScreen: true,
        allowMuting: true,
        showControlsOnInitialize: false,
        errorBuilder: (_, msg) => _ErrorWidget(
          message: msg,
          onRetry: _resetPlayer,
        ),
      );

      if (mounted) setState(() => _isLoading = false);
      _setVideoPlaying(true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  void _resetPlayer() {
    _pendingPipExit = false;
    _resumedBeforePipExit = false;
    _setVideoPlaying(false);
    pipModeNotifier.value = false;
    _videoCtrl?.dispose();
    _chewieCtrl?.dispose();
    setState(() {
      _videoCtrl = null;
      _chewieCtrl = null;
      _playerStarted = false;
      _hasError = false;
      _inPipMode = false;
    });
  }

  Future<void> _enterPip() async {
    try {
      await _pipChannel.invokeMethod('enterPip');
    } on PlatformException {
      // PiP not supported on this device/platform — ignore silently
    }
  }

  // Auto-start when tab becomes visible, stop when hidden
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final tickersEnabled = TickerMode.of(context);
    if (tickersEnabled && !_playerStarted && !_isLoading) {
      _startStream();
    } else if (!tickersEnabled) {
      _videoCtrl?.pause();
    }
  }

  @override
  Widget build(BuildContext context) {
    // PiP mode: show only the video full-screen so the PiP window fills with video
    if (_inPipMode && _chewieCtrl != null) {
      return Material(
        color: Colors.black,
        child: Chewie(controller: _chewieCtrl!),
      );
    }
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      color: isDark ? AppColors.darkBg : AppColors.lightBg,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildHeader(),
            AspectRatio(
              aspectRatio: 16 / 9,
              child: _buildPlayerArea(),
            ),
            Expanded(child: _buildInfo()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          // gold accent bar
          Container(
            width: 4, height: 22,
            decoration: BoxDecoration(
              color: AppColors.gold,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          const Icon(Icons.live_tv_rounded, color: AppColors.gold, size: 20),
          const SizedBox(width: 8),
          Text(
            'البث المباشر',
            style: TextStyle(
              color: Theme.of(context).brightness == Brightness.dark ? Colors.white : AppColors.lightText,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          // live badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.livePulse,
              borderRadius: BorderRadius.circular(5),
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
          if (_playerStarted && !_isLoading) ...[
            const SizedBox(width: 4),
            // Audio-only toggle
            IconButton(
              tooltip: _audioOnly ? 'عرض الفيديو' : 'صوت فقط',
              constraints: const BoxConstraints(),
              padding: const EdgeInsets.all(4),
              icon: Icon(
                _audioOnly ? Icons.videocam_rounded : Icons.headphones_rounded,
                color: _audioOnly ? AppColors.gold : (Theme.of(context).brightness == Brightness.dark ? Colors.white70 : AppColors.lightText.withValues(alpha: 0.6)),
                size: 22,
              ),
              onPressed: () => setState(() => _audioOnly = !_audioOnly),
            ),
            // PiP (picture-in-picture)
            IconButton(
              tooltip: 'تصغير مع الاستمرار',
              constraints: const BoxConstraints(),
              padding: const EdgeInsets.all(4),
              icon: Icon(Icons.picture_in_picture_alt_rounded,
                  color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : AppColors.lightText.withValues(alpha: 0.6), size: 22),
              onPressed: _enterPip,
            ),
            // Refresh
            IconButton(
              constraints: const BoxConstraints(),
              padding: const EdgeInsets.all(4),
              icon: const Icon(Icons.refresh_rounded, color: AppColors.gold, size: 22),
              onPressed: _resetPlayer,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPlayerArea() {
    if (!_playerStarted) return _buildStartScreen();
    if (_isLoading) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: AppColors.gold),
              SizedBox(height: 14),
              Text('جاري تحميل البث...',
                  style: TextStyle(color: Colors.white54, fontSize: 13)),
            ],
          ),
        ),
      );
    }
    if (_hasError) {
      return _ErrorWidget(message: 'تعذر الاتصال بالبث المباشر', onRetry: _resetPlayer);
    }
    // ── Audio-only mode ──
    if (_audioOnly && _videoCtrl != null) {
      return GestureDetector(
        onTap: () => setState(() => _audioOnly = false),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF1A1200), AppColors.darkBg],
                ),
              ),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.gold.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.gold, width: 2),
                  ),
                  child: const Icon(Icons.headphones_rounded,
                      color: AppColors.gold, size: 52),
                ),
                const SizedBox(height: 16),
                const Text('وضع الصوت فقط',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                const Text('اضغط للعودة إلى الفيديو',
                    style: TextStyle(color: Colors.white54, fontSize: 12)),
              ],
            ),
          ],
        ),
      );
    }
    if (_chewieCtrl != null) {
      return Chewie(controller: _chewieCtrl!);
    }
    return const SizedBox.shrink();
  }

  Widget _buildStartScreen() {
    return GestureDetector(
      onTap: _startStream,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            'https://makkahlive.net/images/MakkahLiveCover.jpg',
            fit: BoxFit.cover,
            errorBuilder: (ctx, e, _) => Container(
              color: Colors.black,
              child: Center(
                child: Image.asset(
                  'assets/images/makkah-logo.png',
                  width: 130,
                  color: Colors.white.withValues(alpha: 0.25),
                  colorBlendMode: BlendMode.srcIn,
                ),
              ),
            ),
          ),
          const DecoratedBox(
            decoration: BoxDecoration(color: Color(0x88000000)),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black38,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.gold, width: 2),
                  ),
                  child: const Icon(Icons.play_arrow_rounded,
                      color: AppColors.gold, size: 52),
                ),
                const SizedBox(height: 14),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                  decoration: BoxDecoration(
                    color: Colors.black45,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'اضغط لتشغيل البث المباشر',
                    style: TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _shareChannelInfo() async {
    try {
      final boundary =
          _freqKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final pixelRatio = MediaQuery.of(context).devicePixelRatio;
      final image = await boundary.toImage(pixelRatio: pixelRatio);
      final byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      final bytes = byteData!.buffer.asUint8List();
      final tmpFile =
          File('${Directory.systemTemp.path}/makkah_tv_freq.png');
      await tmpFile.writeAsBytes(bytes);
      await Share.shareXFiles(
        [XFile(tmpFile.path)],
        text:
            'تابعونا على قناة مكة التلفزيونية  حمّل التطبيق الآن:\nhttps://makkahtv.tv',
        subject: 'ترددات قناة مكة الفضائية',
      );
    } catch (_) {
      // Fallback: text-only share
      Share.share(
        '📡 ترددات قناة مكة الفضائية\n\nالقمر الصناعي: عربسات بدر\nالتردد: 11398 MHz\nالاستقطاب: عمودي\nمعدل الترميز: 27500\n\n📱 https://makkahtv.com',
        subject: 'ترددات قناة مكة الفضائية',
      );
    }
  }

  Widget _buildInfo() {
    return Container(
      color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkBg : AppColors.lightBg,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            RepaintBoundary(
              key: _freqKey,
              child: const FrequencyStrip(),
            ),
            // Share button
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: OutlinedButton.icon(
                onPressed: _shareChannelInfo,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.gold,
                  side: const BorderSide(color: AppColors.gold),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.share_rounded, size: 18),
                label: const Text(
                  'مشاركة التردد',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorWidget extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorWidget({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off_rounded, color: AppColors.gold, size: 44),
            const SizedBox(height: 14),
            const Text('تعذر تحميل البث',
                style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(message, style: const TextStyle(color: Colors.white54, fontSize: 12), textAlign: TextAlign.center),
            const SizedBox(height: 20),
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, color: AppColors.gold),
              label: const Text('إعادة المحاولة', style: TextStyle(color: AppColors.gold)),
            ),
          ],
        ),
      ),
    );
  }
}