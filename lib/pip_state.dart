import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:video_player/video_player.dart';

/// Global flag so MainScaffold can hide the bottom bar while any player is in PiP mode.
final pipModeNotifier = ValueNotifier<bool>(false);

/// The single subscription to the native PiP events. An EventChannel only
/// supports one listener, so every screen must share this stream instead of
/// calling receiveBroadcastStream() itself (the last caller would steal it).
final Stream<bool> pipEvents = const EventChannel('makkah.tv/pip_events')
    .receiveBroadcastStream()
    .map((e) => e as bool);

/// Which player asked for PiP ('home' / 'live'), so only that one reacts.
String? pipOwner;

/// The active VideoPlayerController from the home page inline player.
/// MainScaffold uses this to render a fullscreen video-only layer during PiP.
final homePipVideoNotifier = ValueNotifier<VideoPlayerController?>(null);

// ─── App-wide fullscreen layer ───────────────────────────────────────────────

/// A player shown full-screen. MainScaffold renders [child] above every tab
/// (and hides the bottom bar), so fullscreen video is never drawn under it.
class FullscreenPlayer {
  final Widget child;

  /// Leaves fullscreen (used by the system back button).
  final VoidCallback exit;
  const FullscreenPlayer({required this.child, required this.exit});
}

final fullscreenPlayerNotifier = ValueNotifier<FullscreenPlayer?>(null);

Future<void> enterLandscapeFullscreen() async {
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  await SystemChrome.setPreferredOrientations(const [
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
}

Future<void> exitLandscapeFullscreen() async {
  await SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.manual,
    overlays: SystemUiOverlay.values,
  );
  await SystemChrome.setPreferredOrientations(const [DeviceOrientation.portraitUp]);
}

void showFullscreen(FullscreenPlayer entry) {
  fullscreenPlayerNotifier.value = entry;
}

/// Removes [entry] from the fullscreen layer (if it's still the one shown)
/// and restores portrait. Safe to call from dispose / build: the notifier is
/// then updated after the current frame instead of while the tree is locked.
void clearFullscreen(FullscreenPlayer entry) {
  void run() {
    if (fullscreenPlayerNotifier.value != entry) return;
    fullscreenPlayerNotifier.value = null;
    exitLandscapeFullscreen();
  }

  final phase = SchedulerBinding.instance.schedulerPhase;
  if (phase == SchedulerPhase.idle || phase == SchedulerPhase.postFrameCallbacks) {
    run();
  } else {
    SchedulerBinding.instance.addPostFrameCallback((_) => run());
  }
}
