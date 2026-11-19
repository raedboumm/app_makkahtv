import 'dart:async';
import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../app_theme.dart';
import '../pip_state.dart';

/// The one YouTube player used across the app.
///
/// * Fullscreen is shown in MainScaffold's app-wide layer (above the bottom
///   bar). The same player element is moved there with a GlobalKey, so the
///   video keeps playing without reloading.
/// * Doesn't use YoutubePlayerBuilder: every builder listens to rotation
///   globally, so players in other tabs fought over fullscreen.
/// * Pauses itself when its tab/route is hidden or the app goes to background.
/// * Give each controller its own widget (`key: ObjectKey(controller)`): the
///   package's YoutubePlayer ignores a controller swapped in on rebuild.
class AppYoutubePlayer extends StatefulWidget {
  final YoutubePlayerController controller;
  final VoidCallback? onEnded;

  /// Extra widgets drawn over the inline player (not in fullscreen).
  final List<Widget> overlays;

  const AppYoutubePlayer({
    super.key,
    required this.controller,
    this.onEnded,
    this.overlays = const [],
  });

  @override
  State<AppYoutubePlayer> createState() => _AppYoutubePlayerState();
}

class _AppYoutubePlayerState extends State<AppYoutubePlayer>
    with WidgetsBindingObserver {
  final _playerKey = GlobalKey();
  FullscreenPlayer? _fsEntry;
  bool _wasFullScreen = false;
  bool _autoPlayChecked = false;
  Timer? _autoPlayTimer;

  YoutubePlayerController get _ctrl => widget.controller;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _ctrl.addListener(_onValue);
  }

  @override
  void didUpdateWidget(AppYoutubePlayer old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      old.controller.removeListener(_onValue);
      widget.controller.addListener(_onValue);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Tab switched / another route pushed on top → don't keep playing unseen.
    if (!TickerMode.valuesOf(context).enabled && _fsEntry == null) {
      _ctrl.pause();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.hidden) {
      _ctrl.pause();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _autoPlayTimer?.cancel();
    _ctrl.removeListener(_onValue);
    final fs = _fsEntry;
    if (fs != null) clearFullscreen(fs);
    super.dispose();
  }

  void _onValue() {
    final v = _ctrl.value;
    if (v.isFullScreen != _wasFullScreen) {
      _wasFullScreen = v.isFullScreen;
      v.isFullScreen ? _enterFullscreen() : _leaveFullscreen();
    }
    // Safety net: some WebViews ignore the iframe autoplay on first load,
    // which made users tap the video a second time.
    if (v.isReady && !_autoPlayChecked && _ctrl.flags.autoPlay) {
      _autoPlayChecked = true;
      _autoPlayTimer = Timer(const Duration(milliseconds: 1500), () {
        if (!mounted || !TickerMode.valuesOf(context).enabled) return;
        final s = _ctrl.value.playerState;
        if (s == PlayerState.unknown ||
            s == PlayerState.unStarted ||
            s == PlayerState.cued) {
          _ctrl.play();
        }
      });
    }
  }

  void _enterFullscreen() {
    final entry = FullscreenPlayer(child: _player(), exit: _requestExit);
    _fsEntry = entry;
    showFullscreen(entry);
    // toggleFullScreenMode already rotated to landscape; also hide system bars.
    enterLandscapeFullscreen();
  }

  void _requestExit() {
    if (_ctrl.value.isFullScreen) {
      _ctrl.toggleFullScreenMode(); // → listener → _leaveFullscreen
    } else {
      _leaveFullscreen();
    }
  }

  void _leaveFullscreen() {
    final fs = _fsEntry;
    _fsEntry = null;
    if (fs != null) clearFullscreen(fs);
  }

  Widget _player() => KeyedSubtree(
        key: _playerKey,
        child: YoutubePlayer(
          controller: _ctrl,
          showVideoProgressIndicator: true,
          progressIndicatorColor: AppColors.gold,
          progressColors: const ProgressBarColors(
            playedColor: AppColors.gold,
            handleColor: AppColors.gold,
          ),
          onEnded: (_) => widget.onEnded?.call(),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<FullscreenPlayer?>(
      valueListenable: fullscreenPlayerNotifier,
      builder: (context, fs, _) {
        final inFullscreen = fs != null && identical(fs, _fsEntry);
        return Stack(
          fit: StackFit.expand,
          children: [
            if (inFullscreen)
              const ColoredBox(color: Colors.black)
            else
              _player(),
            if (!inFullscreen) ...widget.overlays,
          ],
        );
      },
    );
  }
}
