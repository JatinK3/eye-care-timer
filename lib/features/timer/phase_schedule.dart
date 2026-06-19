/// Pure, side-effect-free model of the work/break phase state machine.
///
/// The timer's visible countdown is animation-driven while the app is in the
/// foreground, but elapsed time is always reconciled against an absolute
/// wall-clock deadline (`phaseEndsAt`). When the app is backgrounded, locked,
/// or killed, no in-app ticker runs; on launch or resume we "fast-forward"
/// from the persisted deadline through every phase boundary that has elapsed
/// and land on the phase that should currently be active.
///
/// [projectPhase] is the single source of truth for that fast-forward so the
/// launch-restore and resume paths behave identically and can be unit tested
/// without a widget tree.
library;

/// Immutable description of the timer cadence used to project future phases.
class PhasePlan {
  final int workDurationSeconds;
  final int breakDurationSeconds;
  final bool longBreakEnabled;
  final int longBreakDurationSeconds;
  final int longBreakEveryCycles;
  final bool autoRunEnabled;
  final int autoRunCycleLimit;

  const PhasePlan({
    required this.workDurationSeconds,
    required this.breakDurationSeconds,
    required this.longBreakEnabled,
    required this.longBreakDurationSeconds,
    required this.longBreakEveryCycles,
    required this.autoRunEnabled,
    required this.autoRunCycleLimit,
  });

  /// Break length to use after [completedCycles] work phases have completed.
  /// Mirrors the long-break cadence used elsewhere in the app.
  int breakDurationForCompletedCycle(int completedCycles) {
    if (!longBreakEnabled || longBreakEveryCycles <= 0) {
      return breakDurationSeconds;
    }
    return completedCycles % longBreakEveryCycles == 0
        ? longBreakDurationSeconds
        : breakDurationSeconds;
  }

  /// Whether a finished break should automatically roll into the next work
  /// phase given how many auto-run cycles have already completed.
  bool shouldContinueAutoRun(int autoRunCompletedCycles) {
    return autoRunEnabled &&
        (autoRunCycleLimit <= 0 ||
            autoRunCompletedCycles < autoRunCycleLimit);
  }
}

/// A work phase that finished during the fast-forward and should be recorded
/// in history / counted toward the streak.
class CompletedWork {
  final DateTime completedAt;
  final int durationSeconds;

  const CompletedWork({
    required this.completedAt,
    required this.durationSeconds,
  });
}

/// Result of [projectPhase]: the phase that should be active "now" after
/// crossing every elapsed boundary, plus the side effects the caller must
/// apply (completed work sessions, updated streak / auto-run counters).
class PhaseProjection {
  /// True when fast-forwarding lands on no active phase (timer should be idle).
  final bool isIdle;

  /// Landing phase type. Only meaningful when [isIdle] is false.
  final bool isBreak;

  /// Absolute start of the landing phase (a past boundary). Null when idle.
  final DateTime? phaseStartedAt;

  /// Absolute deadline of the landing phase (in the future). Null when idle.
  final DateTime? phaseEndsAt;

  /// Full duration of the landing phase in seconds (0 when idle).
  final int initialDurationSeconds;

  /// Seconds remaining in the landing phase (>= 1 when running, 0 when idle).
  final int remainingSeconds;

  /// Streak count after applying every completed work phase.
  final int streakCount;

  /// Auto-run cycles completed after the fast-forward.
  final int autoRunCompletedCycles;

  /// Work phases that completed during the fast-forward, oldest first.
  final List<CompletedWork> completedWorkSessions;

  /// Number of phase boundaries crossed (0 means the original phase is still
  /// running and only the remaining time changed).
  final int boundariesCrossed;

  const PhaseProjection({
    required this.isIdle,
    required this.isBreak,
    required this.phaseStartedAt,
    required this.phaseEndsAt,
    required this.initialDurationSeconds,
    required this.remainingSeconds,
    required this.streakCount,
    required this.autoRunCompletedCycles,
    required this.completedWorkSessions,
    required this.boundariesCrossed,
  });

  PhaseProjection._idle({
    required this.streakCount,
    required this.autoRunCompletedCycles,
    required this.completedWorkSessions,
    required this.boundariesCrossed,
  }) : isIdle = true,
       isBreak = false,
       phaseStartedAt = null,
       phaseEndsAt = null,
       initialDurationSeconds = 0,
       remainingSeconds = 0;
}

/// Safety cap so a corrupt deadline or zero-length phase can never spin
/// forever. Far above any realistic number of cycles a backgrounded app could
/// accumulate (e.g. a 1-minute cadence for a full year is ~525k phases).
const int _maxBoundaries = 1000000;

/// Fast-forward from the [phaseEndsAt] deadline of the currently-stored phase
/// through every boundary that has elapsed before [now], returning the phase
/// that should be active now.
///
/// This is pure: it performs no I/O and mutates nothing the caller owns.
PhaseProjection projectPhase({
  required DateTime now,
  required bool isBreak,
  required DateTime phaseEndsAt,
  required int currentPhaseDurationSeconds,
  required int streakCount,
  required int autoRunCompletedCycles,
  required PhasePlan plan,
}) {
  var curIsBreak = isBreak;
  var curEndsAt = phaseEndsAt;
  var curDuration = currentPhaseDurationSeconds;
  var streak = streakCount;
  var cycles = autoRunCompletedCycles;
  final completed = <CompletedWork>[];
  var boundaries = 0;

  while (boundaries < _maxBoundaries) {
    if (curEndsAt.isAfter(now)) {
      // Landing on a phase that is still running.
      final phaseStartedAt = curEndsAt.subtract(
        Duration(seconds: curDuration),
      );
      var remaining = curEndsAt.difference(now).inSeconds;
      // Guard against a backward clock jump leaving more time than the phase
      // ever had, and never report a non-positive remaining for a live phase.
      if (curDuration > 0 && remaining > curDuration) {
        remaining = curDuration;
      }
      if (remaining < 1) {
        remaining = 1;
      }
      return PhaseProjection(
        isIdle: false,
        isBreak: curIsBreak,
        phaseStartedAt: phaseStartedAt,
        phaseEndsAt: curEndsAt,
        initialDurationSeconds: curDuration,
        remainingSeconds: remaining,
        streakCount: streak,
        autoRunCompletedCycles: cycles,
        completedWorkSessions: completed,
        boundariesCrossed: boundaries,
      );
    }

    // The current phase completed at curEndsAt.
    boundaries++;

    if (curIsBreak) {
      if (!plan.shouldContinueAutoRun(cycles)) {
        return PhaseProjection._idle(
          streakCount: streak,
          autoRunCompletedCycles: 0,
          completedWorkSessions: completed,
          boundariesCrossed: boundaries,
        );
      }
      final dur = plan.workDurationSeconds;
      if (dur <= 0) {
        return PhaseProjection._idle(
          streakCount: streak,
          autoRunCompletedCycles: 0,
          completedWorkSessions: completed,
          boundariesCrossed: boundaries,
        );
      }
      curIsBreak = false;
      curDuration = dur;
      curEndsAt = curEndsAt.add(Duration(seconds: dur));
    } else {
      // Work completed: count it and roll into the appropriate break.
      streak += 1;
      cycles += 1;
      completed.add(
        CompletedWork(completedAt: curEndsAt, durationSeconds: curDuration),
      );
      final dur = plan.breakDurationForCompletedCycle(streak);
      if (dur <= 0) {
        return PhaseProjection._idle(
          streakCount: streak,
          autoRunCompletedCycles: 0,
          completedWorkSessions: completed,
          boundariesCrossed: boundaries,
        );
      }
      curIsBreak = true;
      curDuration = dur;
      curEndsAt = curEndsAt.add(Duration(seconds: dur));
    }
  }

  // Pathological input (e.g. zero-length phases): fall back to idle.
  return PhaseProjection._idle(
    streakCount: streak,
    autoRunCompletedCycles: 0,
    completedWorkSessions: completed,
    boundariesCrossed: boundaries,
  );
}
