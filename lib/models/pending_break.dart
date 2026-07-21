enum PendingBreakReason { postponed, skippedLong }

/// A break already earned by a completed work phase that must be delivered
/// after the current work window. Its reason determines whether that current
/// work window creates another completed cycle.
class PendingBreak {
  final int durationSeconds;
  final PendingBreakReason reason;

  const PendingBreak({required this.durationSeconds, required this.reason})
    : assert(durationSeconds > 0);

  bool get isPostponed => reason == PendingBreakReason.postponed;

  bool get isSkippedLong => reason == PendingBreakReason.skippedLong;

  Map<String, Object> toJson() => <String, Object>{
    'durationSeconds': durationSeconds,
    'reason': reason.name,
  };

  static PendingBreak? fromJson(Object? value) {
    if (value is! Map) return null;
    final rawDuration = value['durationSeconds'];
    final duration = rawDuration is int
        ? rawDuration
        : rawDuration is num
        ? rawDuration.toInt()
        : rawDuration is String
        ? int.tryParse(rawDuration) ?? 0
        : 0;
    if (duration <= 0) return null;
    final rawReason = value['reason'];
    PendingBreakReason? reason;
    for (final candidate in PendingBreakReason.values) {
      if (candidate.name == rawReason) {
        reason = candidate;
        break;
      }
    }
    if (reason == null) return null;
    return PendingBreak(durationSeconds: duration, reason: reason);
  }

  /// Converts sessions saved before [PendingBreak] was introduced.
  static PendingBreak? fromLegacy({
    required Object? duration,
    required Object? deferredBreakWasSkipped,
  }) {
    final parsedDuration = duration is int
        ? duration
        : duration is num
        ? duration.toInt()
        : duration is String
        ? int.tryParse(duration) ?? 0
        : 0;
    if (parsedDuration <= 0) return null;
    final wasSkipped = deferredBreakWasSkipped is bool
        ? deferredBreakWasSkipped
        : deferredBreakWasSkipped is String
        ? deferredBreakWasSkipped.toLowerCase() == 'true'
        : false;
    return PendingBreak(
      durationSeconds: parsedDuration,
      reason: wasSkipped
          ? PendingBreakReason.skippedLong
          : PendingBreakReason.postponed,
    );
  }
}
