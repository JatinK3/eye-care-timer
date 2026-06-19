import 'package:flutter_test/flutter_test.dart';

import 'package:eyeapptimer/features/timer/phase_schedule.dart';

PhasePlan planWith({
  int work = 1200,
  int breakSeconds = 20,
  bool longBreakEnabled = false,
  int longBreak = 300,
  int longBreakEvery = 4,
  bool autoRun = false,
  int autoRunLimit = 0,
}) {
  return PhasePlan(
    workDurationSeconds: work,
    breakDurationSeconds: breakSeconds,
    longBreakEnabled: longBreakEnabled,
    longBreakDurationSeconds: longBreak,
    longBreakEveryCycles: longBreakEvery,
    autoRunEnabled: autoRun,
    autoRunCycleLimit: autoRunLimit,
  );
}

void main() {
  final now = DateTime(2026, 6, 19, 12, 0, 0);

  group('projectPhase', () {
    test(
      'keeps the current phase when the deadline is still in the future',
      () {
        final projection = projectPhase(
          now: now,
          isBreak: false,
          phaseEndsAt: now.add(const Duration(seconds: 300)),
          currentPhaseDurationSeconds: 1200,
          streakCount: 0,
          autoRunCompletedCycles: 0,
          plan: planWith(),
        );

        expect(projection.isIdle, isFalse);
        expect(projection.isBreak, isFalse);
        expect(projection.boundariesCrossed, 0);
        expect(projection.remainingSeconds, 300);
        expect(projection.initialDurationSeconds, 1200);
        expect(projection.completedWorkSessions, isEmpty);
      },
    );

    test('advances an expired work phase into the remaining break', () {
      // Work ended 5s ago; a 20s break should have 15s left.
      final projection = projectPhase(
        now: now,
        isBreak: false,
        phaseEndsAt: now.subtract(const Duration(seconds: 5)),
        currentPhaseDurationSeconds: 1200,
        streakCount: 0,
        autoRunCompletedCycles: 0,
        plan: planWith(breakSeconds: 20),
      );

      expect(projection.isIdle, isFalse);
      expect(projection.isBreak, isTrue);
      expect(projection.boundariesCrossed, 1);
      expect(projection.remainingSeconds, 15);
      expect(projection.initialDurationSeconds, 20);
      expect(projection.streakCount, 1);
      expect(projection.completedWorkSessions, hasLength(1));
      expect(projection.completedWorkSessions.single.durationSeconds, 1200);
    });

    test('goes idle when work and its break both elapsed without auto-run', () {
      // Work ended 30s ago, 20s break also fully elapsed, auto-run off.
      final projection = projectPhase(
        now: now,
        isBreak: false,
        phaseEndsAt: now.subtract(const Duration(seconds: 30)),
        currentPhaseDurationSeconds: 1200,
        streakCount: 2,
        autoRunCompletedCycles: 0,
        plan: planWith(breakSeconds: 20),
      );

      expect(projection.isIdle, isTrue);
      expect(projection.boundariesCrossed, 2);
      expect(projection.streakCount, 3);
      expect(projection.completedWorkSessions, hasLength(1));
    });

    test('expired break rolls into the next work phase under auto-run', () {
      final projection = projectPhase(
        now: now,
        isBreak: true,
        phaseEndsAt: now.subtract(const Duration(seconds: 5)),
        currentPhaseDurationSeconds: 20,
        streakCount: 1,
        autoRunCompletedCycles: 1,
        plan: planWith(autoRun: true, autoRunLimit: 3),
      );

      expect(projection.isIdle, isFalse);
      expect(projection.isBreak, isFalse);
      expect(projection.boundariesCrossed, 1);
      expect(projection.remainingSeconds, 1195);
      expect(projection.initialDurationSeconds, 1200);
    });

    test('expired break goes idle when the auto-run limit is reached', () {
      final projection = projectPhase(
        now: now,
        isBreak: true,
        phaseEndsAt: now.subtract(const Duration(seconds: 5)),
        currentPhaseDurationSeconds: 20,
        streakCount: 1,
        autoRunCompletedCycles: 1,
        plan: planWith(autoRun: true, autoRunLimit: 1),
      );

      expect(projection.isIdle, isTrue);
      expect(projection.autoRunCompletedCycles, 0);
      expect(projection.boundariesCrossed, 1);
    });

    test('fast-forwards through multiple auto-run cycles', () {
      // 100s work + 20s break = 120s cycle. After 5 minutes (300s) backgrounded
      // starting at the beginning of a work phase, 2 full cycles complete
      // (240s) and we land 60s into the third work phase (40s remaining).
      final projection = projectPhase(
        now: now,
        isBreak: false,
        phaseEndsAt: now.subtract(const Duration(seconds: 200)),
        currentPhaseDurationSeconds: 100,
        streakCount: 0,
        autoRunCompletedCycles: 0,
        plan: planWith(work: 100, breakSeconds: 20, autoRun: true),
      );

      // Boundaries: work#1 end, break#1 end, work#2 end, break#2 end -> work#3.
      expect(projection.isIdle, isFalse);
      expect(projection.isBreak, isFalse);
      expect(projection.boundariesCrossed, 4);
      expect(projection.streakCount, 2);
      expect(projection.autoRunCompletedCycles, 2);
      expect(projection.completedWorkSessions, hasLength(2));
      expect(projection.remainingSeconds, 40);
      expect(projection.initialDurationSeconds, 100);
    });

    test(
      'stops after the configured cycle limit when several phases elapsed',
      () {
        final projection = projectPhase(
          now: now,
          isBreak: false,
          phaseEndsAt: now.subtract(const Duration(seconds: 500)),
          currentPhaseDurationSeconds: 100,
          streakCount: 3,
          autoRunCompletedCycles: 0,
          plan: planWith(
            work: 100,
            breakSeconds: 20,
            autoRun: true,
            autoRunLimit: 2,
          ),
        );

        expect(projection.isIdle, isTrue);
        expect(projection.boundariesCrossed, 4);
        expect(projection.streakCount, 5);
        expect(projection.completedWorkSessions, hasLength(2));
        expect(projection.autoRunCompletedCycles, 0);
      },
    );

    test('uses the long-break duration on the configured cadence', () {
      // Long break every 1 cycle -> the very first break is the long one.
      final projection = projectPhase(
        now: now,
        isBreak: false,
        phaseEndsAt: now.subtract(const Duration(seconds: 5)),
        currentPhaseDurationSeconds: 1,
        streakCount: 0,
        autoRunCompletedCycles: 0,
        plan: planWith(
          breakSeconds: 20,
          longBreakEnabled: true,
          longBreak: 180,
          longBreakEvery: 1,
        ),
      );

      expect(projection.isBreak, isTrue);
      expect(projection.initialDurationSeconds, 180);
      expect(projection.remainingSeconds, 175);
    });

    test('clamps remaining time when the clock jumps backward', () {
      // Deadline is further away than a full phase (device clock moved back).
      final projection = projectPhase(
        now: now,
        isBreak: true,
        phaseEndsAt: now.add(const Duration(seconds: 5000)),
        currentPhaseDurationSeconds: 20,
        streakCount: 0,
        autoRunCompletedCycles: 0,
        plan: planWith(),
      );

      expect(projection.isBreak, isTrue);
      expect(projection.remainingSeconds, 20);
      expect(projection.boundariesCrossed, 0);
    });
  });
}
