import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import '../app_theme.dart';
import '../pip_state.dart';
import '../widgets/main_drawer.dart';
import 'home_screen.dart';
import 'program_series_screen.dart';
import 'programs_library_screen.dart';

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  // Tabs = the web's menu: الرئيسية / مكتبة البرامج / سلاسل البرامج.
  // (Live plays on the home page, so there's no separate live tab.)
  int _currentIndex = 0;
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  void _openMenu() => _scaffoldKey.currentState?.openDrawer();

  // One navigator key per tab — keeps bottom bar visible on every push
  final List<GlobalKey<NavigatorState>> _navKeys = List.generate(
    appMenuItems.length, (_) => GlobalKey<NavigatorState>(),
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
        if (didPop) return;
        // Back while the side menu is open → close it.
        final scaffold = _scaffoldKey.currentState;
        if (scaffold?.isDrawerOpen ?? false) {
          scaffold!.closeDrawer();
          return;
        }
        // Back while a video is fullscreen → leave fullscreen first.
        final fs = fullscreenPlayerNotifier.value;
        if (fs != null) {
          fs.exit();
          return;
        }
        final nav = _navKeys[_currentIndex].currentState;
        if (nav?.canPop() ?? false) {
          nav!.pop();
        } else if (_currentIndex != 0) {
          // At the root of another tab → go back to the home tab.
          setState(() => _currentIndex = 0);
        } else {
          // At the root of the home tab → leave the app.
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        key: _scaffoldKey,
        // Opened with the ☰ toggle (an edge swipe would fight the players).
        drawerEnableOpenDragGesture: false,
        drawer: MainDrawer(currentIndex: _currentIndex, onNavigate: _setIndex),
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
                    onOpenMenu: _openMenu,
                    onGoToLibrary: () => _setIndex(1),
                  ),
                ),
                _NestedNav(
                  navKey: _navKeys[1],
                  child: ProgramsLibraryScreen(onOpenMenu: _openMenu),
                ),
                _NestedNav(
                  navKey: _navKeys[2],
                  child: ProgramSeriesScreen(onOpenMenu: _openMenu),
                ),
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
            // App-wide fullscreen layer: any player that goes fullscreen is
            // drawn here, above every tab, with the bottom bar hidden.
            ValueListenableBuilder<FullscreenPlayer?>(
              valueListenable: fullscreenPlayerNotifier,
              builder: (context, fs, child) {
                if (fs == null) return const SizedBox.shrink();
                return Positioned.fill(
                  child: Material(
                    color: Colors.black,
                    child: SizedBox.expand(child: fs.child),
                  ),
                );
              },
            ),
          ],
        ),
        bottomNavigationBar: ListenableBuilder(
          listenable: Listenable.merge([pipModeNotifier, fullscreenPlayerNotifier]),
          builder: (context, child) =>
              (pipModeNotifier.value || fullscreenPlayerNotifier.value != null)
                  ? const SizedBox.shrink()
                  : _buildBottomNav(),
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
          for (final item in appMenuItems)
            BottomNavigationBarItem(icon: Icon(item.icon), label: item.label),
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
