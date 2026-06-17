class TimerSession {
  final bool isActive;
  final bool isBreak;
  final bool isPaused;
  final int initialDurationSeconds;
  final int remainingSeconds;
  final DateTime? phaseStartedAt;
  final DateTime? phaseEndsAt;

  const TimerSession({
    required this.isActive,
    required this.isBreak,
    required this.isPaused,
    required this.initialDurationSeconds,
    required this.remainingSeconds,
    required this.phaseStartedAt,
    required this.phaseEndsAt,
  });

  const TimerSession.idle()
    : isActive = false,
      isBreak = false,
      isPaused = false,
      initialDurationSeconds = 0,
      remainingSeconds = 0,
      phaseStartedAt = null,
      phaseEndsAt = null;
}
