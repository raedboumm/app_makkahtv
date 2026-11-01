import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../app_theme.dart';
import '../pip_state.dart';
import 'home_screen.dart';
import 'live_tab.dart';
import 'programs_library_screen.dart';

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _currentIndex = 0;

  // One navigator key per tab — keeps bottom bar visible on every push
  final List<GlobalKey<NavigatorState>> _navKeys = List.generate(
    3, (_) => GlobalKey<NavigatorState>(),
  );

  void _setIndex(int index) {
    if (_currentIndex == index) {
      // Re-tap same tab → pop to root of that tab
      _navKeys[index].currentState?.popUntil((r) => r.isFirst);
    } else {
      setState(() => _currentIndex = index);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          final canPop =
              _navKeys[_currentIndex].currentState?.canPop() ?? false;
          if (canPop) {
            _navKeys[_currentIndex].currentState?.pop();
          }
        }
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        extendBodyBehindAppBar: true,
        extendBody: true,
        body: Stack(
          children: [
            IndexedStack(
              index: _currentIndex,
              children: [
                _NestedNav(
                  navKey: _navKeys[0],
                  child: HomeScreen(
                    onWatchLive: () => _setIndex(1),
                    onGoToPrograms: () => _setIndex(2),
                  ),
                ),
                _NestedNav(navKey: _navKeys[1], child: const LiveTab()),
                _NestedNav(navKey: _navKeys[2], child: const ProgramsLibraryScreen()),
              ],
            ),
            // Full-screen cover for home-page PiP — raw video-only layer.
            // Using VideoPlayer (not Chewie) keeps the original Chewie's
            // VideoPlayer texture alive in the home tab, preventing freezes.
            ValueListenableBuilder<bool>(
              valueListenable: pipModeNotifier,
              builder: (context, inPip, child) {
                if (!inPip) return const SizedBox.shrink();
                return ValueListenableBuilder<VideoPlayerController?>(
                  valueListenable: homePipVideoNotifier,
                  builder: (context, videoCtrl, child) {
                    if (videoCtrl == null) return const SizedBox.shrink();
                    return Material(
                      color: Colors.black,
                      child: VideoPlayer(videoCtrl),
                    );
                  },
                );
              },
            ),
          ],
        ),
        bottomNavigationBar: ValueListenableBuilder<bool>(
          valueListenable: pipModeNotifier,
          builder: (context, inPip, child) =>
              inPip ? const SizedBox.shrink() : _buildBottomNav(),
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        boxShadow: const [
          BoxShadow(
            color: Colors.black54,
            blurRadius: 12,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _setIndex,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: 'الرئيسية',
          ),
          BottomNavigationBarItem(
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.live_tv_rounded),
                Positioned(
                  top: -2,
                  left: -2,
                  child: _LiveDot(),
                ),
              ],
            ),
            label: 'البث المباشر',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.video_library_rounded),
            label: 'مكتبة البرامج',
          ),
        ],
      ),
    );
  }
}

// ─── Per-tab nested navigator ─────────────────────────────────────────────────

class _NestedNav extends StatelessWidget {
  final GlobalKey<NavigatorState> navKey;
  final Widget child;
  const _NestedNav({required this.navKey, required this.child});

  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: navKey,
      onGenerateRoute: (settings) => MaterialPageRoute(
        settings: settings,
        builder: (_) => child,
      ),
    );
  }
}

class _LiveDot extends StatefulWidget {
  @override
  State<_LiveDot> createState() => _LiveDotState();
}

class _LiveDotState extends State<_LiveDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _opacity = Tween<double>(begin: 0.2, end: 1.0).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: Container(
        width: 7,
        height: 7,
        decoration: const BoxDecoration(
          color: AppColors.livePulse,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
