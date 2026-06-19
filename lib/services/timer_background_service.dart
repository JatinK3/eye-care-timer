import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Dart bridge to the native Android foreground service that owns the active
/// timer phase while BlinkKind is backgrounded or the screen is locked.
///
/// The native side shows an ongoing notification with a live countdown and
/// arms an exact alarm at the phase deadline. The Flutter timer remains the
/// single source of truth for phase logic; this just keeps a native owner in
/// sync with the current deadline. All methods are safe no-ops on non-Android
/// platforms and in tests (where the platform channel is absent).
class TimerBackgroundService {
  static const MethodChannel _channel = MethodChannel(
    'blinkkind/timer_background',
  );

  bool get _isSupported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// Hands the current phase deadline to the native owner.
  Future<void> startPhase({
    required DateTime phaseEndsAt,
    required bool isBreak,
    required int remainingSeconds,
  }) async {
    if (!_isSupported) return;
    try {
      await _channel.invokeMethod<void>('startPhase', <String, dynamic>{
        'phaseEndsAtMillis': phaseEndsAt.millisecondsSinceEpoch,
        'isBreak': isBreak,
        'remainingSeconds': remainingSeconds,
      });
    } on PlatformException catch (error) {
      debugPrint('Unable to start background phase: $error');
    } on MissingPluginException {
      // Native side unavailable (e.g. tests); ignore.
    }
  }

  /// Tears down the native owner when the timer stops or goes idle.
  Future<void> stopPhase() async {
    if (!_isSupported) return;
    try {
      await _channel.invokeMethod<void>('stopPhase');
    } on PlatformException catch (error) {
      debugPrint('Unable to stop background phase: $error');
    } on MissingPluginException {
      // Native side unavailable (e.g. tests); ignore.
    }
  }
}
