import 'package:flutter_test/flutter_test.dart';

import 'package:eyeapptimer/models/pending_break.dart';
import 'package:eyeapptimer/models/timer_session.dart';

void main() {
  group('TimerSession serialization', () {
    test('round-trips an active session through JSON', () {
      final startedAt = DateTime(2026, 6, 19, 12, 0, 0);
      final endsAt = startedAt.add(const Duration(minutes: 20));
      final session = TimerSession(
        isActive: true,
        isBreak: true,
        isPaused: false,
        initialDurationSeconds: 1200,
        remainingSeconds: 600,
        phaseStartedAt: startedAt,
        phaseEndsAt: endsAt,
        completedAutoRunCycles: 2,
      );

      final restored = TimerSession.fromJson(session.toJson());

      expect(restored.isActive, isTrue);
      expect(restored.isBreak, isTrue);
      expect(restored.isPaused, isFalse);
      expect(restored.initialDurationSeconds, 1200);
      expect(restored.remainingSeconds, 600);
      expect(restored.phaseStartedAt, startedAt);
      expect(restored.phaseEndsAt, endsAt);
      expect(restored.completedAutoRunCycles, 2);
    });

    test('round-trips a reasoned pending break', () {
      const session = TimerSession(
        isActive: true,
        isBreak: false,
        isPaused: false,
        initialDurationSeconds: 120,
        remainingSeconds: 100,
        phaseStartedAt: null,
        phaseEndsAt: null,
        pendingBreak: PendingBreak(
          durationSeconds: 900,
          reason: PendingBreakReason.skippedLong,
        ),
      );

      final restored = TimerSession.fromJson(session.toJson());

      expect(restored.pendingBreak?.durationSeconds, 900);
      expect(restored.pendingBreak?.reason, PendingBreakReason.skippedLong);
    });

    test('migrates the legacy deferred-break fields', () {
      final restored = TimerSession.fromJson(<String, dynamic>{
        'isActive': true,
        'postponedBreakDuration': 600,
        'deferredBreakWasSkipped': true,
      });

      expect(restored.pendingBreak?.durationSeconds, 600);
      expect(restored.pendingBreak?.reason, PendingBreakReason.skippedLong);
    });

    test('round-trips the active-session automatic-pause override', () {
      const session = TimerSession(
        isActive: true,
        isBreak: false,
        isPaused: false,
        initialDurationSeconds: 1200,
        remainingSeconds: 900,
        phaseStartedAt: null,
        phaseEndsAt: null,
        automaticPauseOverride: true,
      );

      expect(
        TimerSession.fromJson(session.toJson()).automaticPauseOverride,
        isTrue,
      );
    });

    test('round-trips an idle session with null timestamps', () {
      const session = TimerSession.idle();
      final restored = TimerSession.fromJson(session.toJson());

      expect(restored.isActive, isFalse);
      expect(restored.phaseStartedAt, isNull);
      expect(restored.phaseEndsAt, isNull);
      expect(restored.completedAutoRunCycles, 0);
    });

    test('falls back to safe defaults on a malformed payload', () {
      final restored = TimerSession.fromJson(<String, dynamic>{
        'isActive': 'nope',
        'initialDurationSeconds': '900',
        'phaseEndsAt': 'not-a-number',
      });

      expect(restored.isActive, isFalse);
      expect(restored.initialDurationSeconds, 900);
      expect(restored.phaseEndsAt, isNull);
    });
  });
}
