import '../../models/timer_event_record.dart';
import 'eye_strain_calculator.dart';

enum FatigueRecommendationAction { recoveryBreak, shortenNextFocus }

class FatigueRecommendation {
  final String id;
  final String title;
  final String detail;
  final FatigueRecommendationAction action;

  const FatigueRecommendation({
    required this.id,
    required this.title,
    required this.detail,
    required this.action,
  });
}

/// Produces one conservative, explainable fatigue intervention at a time.
/// This deliberately uses local session data rather than an AI decision so a
/// recommendation remains predictable and works without network access.
class FatigueRecommendationEngine {
  static FatigueRecommendation? evaluate({
    required EyeStrainRiskScore riskScore,
    required List<TimerEventRecord> todaysEvents,
    required int breakDebtSeconds,
  }) {
    final skippedBreaks = todaysEvents
        .where((event) => event.type == TimerEventType.breakSkipped)
        .length;
    final postponedBreaks = todaysEvents
        .where((event) => event.type == TimerEventType.breakPostponed)
        .length;

    if (breakDebtSeconds >= 180 || riskScore.totalScore >= 70) {
      return const FatigueRecommendation(
        id: 'recovery_break',
        title: 'A recovery break is due',
        detail:
            'Your recent focus pattern needs a longer screen-free reset before the next block.',
        action: FatigueRecommendationAction.recoveryBreak,
      );
    }

    if (riskScore.totalScore >= 45 ||
        skippedBreaks >= 2 ||
        postponedBreaks >= 3) {
      return const FatigueRecommendation(
        id: 'shorten_next_focus',
        title: 'Shorten the next focus block',
        detail:
            'A smaller next block can help you recover without interrupting the work already in progress.',
        action: FatigueRecommendationAction.shortenNextFocus,
      );
    }

    return null;
  }
}
