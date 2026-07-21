class TimerSession {
  final bool isActive;
  final bool isBreak;
  final bool isPaused;
  final int initialDurationSeconds;
  final int remainingSeconds;
  final DateTime? phaseStartedAt;
  final DateTime? phaseEndsAt;
  final int completedAutoRunCycles;
  final int? postponedBreakDuration;
  /// True when [postponedBreakDuration] is a skipped break held for the next
  /// work boundary, rather than a user-initiated postpone work window.
  final bool deferredBreakWasSkipped;
  final int breakDebtSeconds;
  /// Wall-clock time at which this session snapshot was last persisted.
  /// Used to detect cross-day stale sessions even when both [phaseStartedAt]
  /// and [phaseEndsAt] are null (e.g. a manually paused session).
  final DateTime? savedAt;

  const TimerSession({
    required this.isActive,
    required this.isBreak,
    required this.isPaused,
    required this.initialDurationSeconds,
    required this.remainingSeconds,
    required this.phaseStartedAt,
    required this.phaseEndsAt,
    this.completedAutoRunCycles = 0,
    this.postponedBreakDuration,
    this.deferredBreakWasSkipped = false,
    this.breakDebtSeconds = 0,
    this.savedAt,
  });

  const TimerSession.idle()
    : isActive = false,
      isBreak = false,
      isPaused = false,
      initialDurationSeconds = 0,
      remainingSeconds = 0,
      phaseStartedAt = null,
      phaseEndsAt = null,
      completedAutoRunCycles = 0,
      postponedBreakDuration = null,
      deferredBreakWasSkipped = false,
      breakDebtSeconds = 0,
      savedAt = null;

  /// Serializes the session to a plain JSON map. Timestamps are stored as epoch
  /// milliseconds so the same representation can be shared with the native
  /// background timer owner across the platform channel.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'isActive': isActive,
      'isBreak': isBreak,
      'isPaused': isPaused,
      'initialDurationSeconds': initialDurationSeconds,
      'remainingSeconds': remainingSeconds,
      'phaseStartedAt': phaseStartedAt?.millisecondsSinceEpoch,
      'phaseEndsAt': phaseEndsAt?.millisecondsSinceEpoch,
      'completedAutoRunCycles': completedAutoRunCycles,
      'postponedBreakDuration': postponedBreakDuration,
      'deferredBreakWasSkipped': deferredBreakWasSkipped,
      'breakDebtSeconds': breakDebtSeconds,
      'savedAt': savedAt?.millisecondsSinceEpoch,
    };
  }

  /// Rebuilds a session from [toJson] output. Unknown or malformed fields fall
  /// back to idle-equivalent defaults so a corrupt payload can never throw.
  factory TimerSession.fromJson(Map<String, dynamic> json) {
    return TimerSession(
      isActive: _asBool(json['isActive']),
      isBreak: _asBool(json['isBreak']),
      isPaused: _asBool(json['isPaused']),
      initialDurationSeconds: _asInt(json['initialDurationSeconds']),
      remainingSeconds: _asInt(json['remainingSeconds']),
      phaseStartedAt: _dateTimeFromMillis(json['phaseStartedAt']),
      phaseEndsAt: _dateTimeFromMillis(json['phaseEndsAt']),
      completedAutoRunCycles: _asInt(json['completedAutoRunCycles']),
      postponedBreakDuration: json['postponedBreakDuration'] != null ? _asInt(json['postponedBreakDuration']) : null,
      deferredBreakWasSkipped: _asBool(json['deferredBreakWasSkipped']),
      breakDebtSeconds: _asInt(json['breakDebtSeconds']),
      savedAt: _dateTimeFromMillis(json['savedAt']),
    );
  }

  static bool _asBool(Object? value) {
    if (value is bool) return value;
    if (value is String) return value.toLowerCase() == 'true';
    return false;
  }

  static int _asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static DateTime? _dateTimeFromMillis(Object? value) {
    final millis = _asInt(value);
    if (value == null || millis == 0) {
      return null;
    }
    return DateTime.fromMillisecondsSinceEpoch(millis);
  }
}
