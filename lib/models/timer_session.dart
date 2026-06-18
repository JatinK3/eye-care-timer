class TimerSession {
  final bool isActive;
  final bool isBreak;
  final bool isPaused;
  final int initialDurationSeconds;
  final int remainingSeconds;
  final DateTime? phaseStartedAt;
  final DateTime? phaseEndsAt;
  final int completedAutoRunCycles;

  const TimerSession({
    required this.isActive,
    required this.isBreak,
    required this.isPaused,
    required this.initialDurationSeconds,
    required this.remainingSeconds,
    required this.phaseStartedAt,
    required this.phaseEndsAt,
    this.completedAutoRunCycles = 0,
  });

  const TimerSession.idle()
    : isActive = false,
      isBreak = false,
      isPaused = false,
      initialDurationSeconds = 0,
      remainingSeconds = 0,
      phaseStartedAt = null,
      phaseEndsAt = null,
      completedAutoRunCycles = 0;
}
