import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../models/timer_settings.dart';

/// Dart bridge to the native Android foreground service that owns active timer
/// phase deadlines while BlinkKind is backgrounded or the screen is locked.
///
/// Flutter remains the source of truth. Android receives a cadence snapshot so
/// it can continue automatic work/break boundaries until Flutter resumes.
class TimerBackgroundService {
  static const MethodChannel _channel = MethodChannel(
    'blinkkind/timer_background',
  );

  bool get _isSupported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  Future<void> startPhase({
    required DateTime phaseEndsAt,
    required bool isBreak,
    required BreakMode breakMode,
    required int workDurationSeconds,
    required int breakDurationSeconds,
    required bool longBreakEnabled,
    required int longBreakDurationSeconds,
    required int longBreakEveryCycles,
    required bool autoRunEnabled,
    required int autoRunCycleLimit,
    required int streakCount,
    required int completedAutoRunCycles,
  }) async {
    if (!_isSupported) return;
    try {
      await _channel.invokeMethod<void>('startPhase', <String, dynamic>{
        'phaseEndsAtMillis': phaseEndsAt.millisecondsSinceEpoch,
        'isBreak': isBreak,
        'breakMode': breakMode.name,
        'workDurationSeconds': workDurationSeconds,
        'breakDurationSeconds': breakDurationSeconds,
        'longBreakEnabled': longBreakEnabled,
        'longBreakDurationSeconds': longBreakDurationSeconds,
        'longBreakEveryCycles': longBreakEveryCycles,
        'autoRunEnabled': autoRunEnabled,
        'autoRunCycleLimit': autoRunCycleLimit,
        'streakCount': streakCount,
        'completedAutoRunCycles': completedAutoRunCycles,
      });
    } on PlatformException catch (error) {
      debugPrint('Unable to start background phase: $error');
    } on MissingPluginException {
      // Native side unavailable (e.g. tests); ignore.
    }
  }

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
