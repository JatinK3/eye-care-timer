import 'package:flutter_test/flutter_test.dart';

import 'package:eyeapptimer/features/insights/eye_strain_calculator.dart';
import 'package:eyeapptimer/features/insights/fatigue_recommendation.dart';
import 'package:eyeapptimer/models/timer_event_record.dart';

TimerEventRecord event(TimerEventType type) {
  final now = DateTime.now();
  return TimerEventRecord(
    id: '${type.name}-${now.microsecondsSinceEpoch}',
    timestamp: now,
    type: type,
    durationSeconds: 0,
  );
}

void main() {
  const lowRisk = EyeStrainRiskScore(
    totalScore: 10,
    riskLevel: 'Low',
    contributingFactors: [],
  );

  test('prioritizes a recovery break for significant break debt', () {
    final recommendation = FatigueRecommendationEngine.evaluate(
      riskScore: lowRisk,
      todaysEvents: const [],
      breakDebtSeconds: 180,
    );

    expect(recommendation?.action, FatigueRecommendationAction.recoveryBreak);
  });

  test('recommends a shorter focus block after repeated skipped breaks', () {
    final recommendation = FatigueRecommendationEngine.evaluate(
      riskScore: lowRisk,
      todaysEvents: [
        event(TimerEventType.breakSkipped),
        event(TimerEventType.breakSkipped),
      ],
      breakDebtSeconds: 0,
    );

    expect(
      recommendation?.action,
      FatigueRecommendationAction.shortenNextFocus,
    );
  });

  test('stays quiet when no fatigue threshold is met', () {
    final recommendation = FatigueRecommendationEngine.evaluate(
      riskScore: lowRisk,
      todaysEvents: const [],
      breakDebtSeconds: 0,
    );

    expect(recommendation, isNull);
  });
}
