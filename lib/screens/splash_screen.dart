import 'package:flutter/material.dart';
import '../app_theme.dart';
import '../data/static_data.dart';
import '../pip_state.dart';
import 'main_scaffold.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _fadeCtrl;
  late final AnimationController _loadCtrl;
  late final AnimationController _shineCtrl;

  late final Animation<double> _logoOpacity;
  late final Animation<double> _loadProgress;
  late final Animation<double> _shinePos;

  @override
  void initState() {
    super.initState();

    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );
    _loadCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 6000),
    );
    _shineCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _logoOpacity = Tween<double>(begin: 0.2, end: 1.0).animate(
      CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeIn),
    );
    _loadProgress = CurvedAnimation(
      parent: _loadCtrl,
      curve: Curves.easeInOut,
    );
    // shine sweeps from -0.4 to 1.4 (off-screen left → off-screen right)
    _shinePos = Tween<double>(begin: -0.4, end: 1.4).animate(
      CurvedAnimation(parent: _shineCtrl, curve: Curves.easeInOut),
    );

    _runSequence();
  }

  Future<void> _runSequence() async {
    _fadeCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 400));
    _loadCtrl.forward();
    // Start pre-loading the live stream in the background during splash.
    LiveStreamPreloader.start(StaticData.liveStream.streamUrl);
    // wait for logo to be fully visible (~3s), then flash shine
    await Future.delayed(const Duration(milliseconds: 2800));
    if (!mounted) return;
    await _shineCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const MainScaffold(),
        transitionDuration: const Duration(milliseconds: 600),
        transitionsBuilder: (_, anim, ___, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _loadCtrl.dispose();
    _shineCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final logoSize = size.shortestSide * 0.5;

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Logo fades from 20% → 100% opacity, with shine flash on top
            AnimatedBuilder(
              animation: Listenable.merge([_logoOpacity, _shinePos]),
              builder: (_, __) {
                final pos = _shinePos.value; // -0.4 → 1.4
                final isSweeping = _shineCtrl.isAnimating || _shineCtrl.value > 0;
                return Opacity(
                  opacity: _logoOpacity.value,
                  // ShaderMask with BlendMode.srcIn → gradient is clipped to
                  // exactly the logo's non-transparent pixels
                  child: ShaderMask(
                    blendMode: BlendMode.srcIn,
                    shaderCallback: (bounds) {
                      if (!isSweeping) {
                        // Plain white
                        return const LinearGradient(
                          colors: [Colors.white, Colors.white],
                        ).createShader(bounds);
                      }
                      final cx = pos * bounds.width;
                      final band = bounds.width * 0.30;
                      final lo0 = ((cx - band) / bounds.width).clamp(0.0, 1.0);
                      final lo1 = ((cx - band * 0.4) / bounds.width).clamp(0.0, 1.0);
                      final mid = (cx / bounds.width).clamp(0.0, 1.0);
                      final hi1 = ((cx + band * 0.4) / bounds.width).clamp(0.0, 1.0);
                      final hi0 = ((cx + band) / bounds.width).clamp(0.0, 1.0);
                      return LinearGradient(
                        begin: const Alignment(-1.5, -1.0),
                        end: const Alignment(1.5, 1.0),
                        colors: const [
                          Colors.white,
                          Colors.white,
                          Color(0xFFE0E0E0), // soft silver edge
                          Color(0xFFFFFFFF), // bright peak
                          Color(0xFFE0E0E0), // soft silver edge
                          Colors.white,
                          Colors.white,
                        ],
                        stops: [0.0, lo0, lo1, mid, hi1, hi0, 1.0],
                      ).createShader(bounds);
                    },
                    child: Image.asset(
                      'assets/images/makkah-logo.png',
                      width: logoSize,
                      height: logoSize,
                      fit: BoxFit.contain,
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 44),

            // Loading bar
            AnimatedBuilder(
              animation: _loadProgress,
              builder: (_, __) => SizedBox(
                width: size.width * 0.55,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: _loadProgress.value,
                    backgroundColor: Colors.white12,
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(AppColors.gold),
                    minHeight: 3,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Loading text
            const Text(
              'تحميل البيانات ...',
              style: TextStyle(
                color: Colors.white38,
                fontSize: 12,
                letterSpacing: 2.0,
                fontWeight: FontWeight.w300,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShineOverlay extends StatelessWidget {
  final double progress; // -0.4 → 1.4
  final double size;

  const _ShineOverlay({required this.progress, required this.size});

  @override
  Widget build(BuildContext context) {
    // Shine band center mapped to actual pixel position
    final center = progress;
    return CustomPaint(
      painter: _ShinePainter(center: center),
      size: Size(size, size),
    );
  }
}

class _ShinePainter extends CustomPainter {
  final double center; // 0.0 = left edge, 1.0 = right edge

  const _ShinePainter({required this.center});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = center * size.width;
    final bandHalfWidth = size.width * 0.28;

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final gradient = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: const [
        Colors.transparent,
        Colors.transparent,
        Color(0x55FFFFFF),
        Color(0xAAFFFFFF),
        Color(0x55FFFFFF),
        Colors.transparent,
        Colors.transparent,
      ],
      stops: [
        0.0,
        ((cx - bandHalfWidth) / size.width).clamp(0.0, 1.0),
        ((cx - bandHalfWidth * 0.5) / size.width).clamp(0.0, 1.0),
        (cx / size.width).clamp(0.0, 1.0),
        ((cx + bandHalfWidth * 0.5) / size.width).clamp(0.0, 1.0),
        ((cx + bandHalfWidth) / size.width).clamp(0.0, 1.0),
        1.0,
      ],
    );

    final paint = Paint()..shader = gradient.createShader(rect);
    canvas.drawRect(rect, paint);
  }

  @override
  bool shouldRepaint(_ShinePainter old) => old.center != center;
}
