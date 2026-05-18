import 'package:flutter/foundation.dart';
import 'package:video_player/video_player.dart';

/// Global flag so MainScaffold can hide the bottom bar while any player is in PiP mode.
final pipModeNotifier = ValueNotifier<bool>(false);

/// The active VideoPlayerController from the home page inline player.
/// MainScaffold uses this to render a fullscreen video-only layer during PiP.
final homePipVideoNotifier = ValueNotifier<VideoPlayerController?>(null);

/// Starts initializing the live stream during the splash screen so the home
/// page can begin playback without waiting for a fresh network init.
class LiveStreamPreloader {
  static VideoPlayerController? _ctrl;

  static bool get isReady => _ctrl?.value.isInitialized == true;

  /// Begin loading [url] in the background. Safe to call multiple times.
  static Future<void> start(String url) async {
    if (_ctrl != null) return;
    try {
      _ctrl = VideoPlayerController.networkUrl(
        Uri.parse(url),
        httpHeaders: const {'User-Agent': 'MakkahTV/1.0 Flutter'},
      );
      await _ctrl!.initialize();
    } catch (_) {
      _ctrl?.dispose();
      _ctrl = null;
    }
  }

  /// Take ownership of the pre-initialized controller (caller must dispose it).
  static VideoPlayerController? consume() {
    final ctrl = _ctrl;
    _ctrl = null;
    return ctrl;
  }

  static void clear() {
    _ctrl?.dispose();
    _ctrl = null;
  }
}
