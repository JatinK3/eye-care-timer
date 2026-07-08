import '../../models/timer_event_record.dart';

class EyeStrainRiskScore {
  final int totalScore;
  final String riskLevel; // 'Low', 'Moderate', 'High', 'Severe'
  final List<String> contributingFactors;

  const EyeStrainRiskScore({
    required this.totalScore,
    required this.riskLevel,
    required this.contributingFactors,
  });
}

class EyeStrainCalculator {
  /// Calculates the Eye Strain Risk Score for a given set of parameters.
  /// 
  /// The score ranges from 0 to 100, where 0 is perfect (no risk) and 100 is severe risk.
  /// Factors evaluated:
  /// - Break Debt (missed/accumulated break time)
  /// - Skipped/Postponed break events
  /// - Hydration compliance
  /// - Focus time density (continuous work without adequate breaks)
  static EyeStrainRiskScore calculate({
    required List<TimerEventRecord> todaysEvents,
    required int breakDebtSeconds,
    required int waterGlassesToday,
    required int dailyWaterGoal,
  }) {
    int score = 0;
    List<String> factors = [];

    // 1. Break Debt Penalty (Max 40 points)
    // 1 point for every 30 seconds of debt.
    int debtScore = (breakDebtSeconds / 30).floor();
    if (debtScore > 40) debtScore = 40;
    score += debtScore;
    if (debtScore > 10) {
      final mins = (breakDebtSeconds / 60).round();
      factors.add('High break debt ($mins mins)');
    }

    // 2. Skipped/Postponed Breaks (Max 30 points)
    // 10 points per skip, 5 points per postpone
    final skipCount = todaysEvents.where((e) => e.type == TimerEventType.breakSkipped).length;
    final postponeCount = todaysEvents.where((e) => e.type == TimerEventType.breakPostponed).length;
    
    int skipScore = (skipCount * 10) + (postponeCount * 5);
    if (skipScore > 30) skipScore = 30;
    score += skipScore;
    
    if (skipCount > 0) {
      factors.add('Skipped $skipCount break${skipCount > 1 ? 's' : ''}');
    }
    if (postponeCount > 0) {
      factors.add('Postponed $postponeCount break${postponeCount > 1 ? 's' : ''}');
    }

    // 3. Hydration Penalty (Max 20 points)
    // Lack of hydration exacerbates dry eyes. 
    int hydrationPenalty = 0;
    if (dailyWaterGoal > 0) {
      final missingGlasses = dailyWaterGoal - waterGlassesToday;
      if (missingGlasses > 0) {
        hydrationPenalty = ((missingGlasses / dailyWaterGoal) * 20).round();
      }
    } else if (waterGlassesToday == 0) {
      hydrationPenalty = 10;
    }
    
    if (hydrationPenalty > 20) hydrationPenalty = 20;
    score += hydrationPenalty;
    if (hydrationPenalty > 10) {
      factors.add('Low hydration ($waterGlassesToday/$dailyWaterGoal glasses)');
    }

    // 4. Focus Density Penalty (Max 10 points)
    // Overworking heavily without any breaks
    final workCount = todaysEvents.where((e) => e.type == TimerEventType.workCompleted).length;
    if (workCount > 5 && skipScore > 15) {
      score += 10;
      factors.add('Intense focus with poor break compliance');
    }

    // Bound the final score
    score = score.clamp(0, 100);

    // Determine level
    String level = 'Low';
    if (score >= 70) {
      level = 'Severe';
    } else if (score >= 45) {
      level = 'High';
    } else if (score >= 20) {
      level = 'Moderate';
    }

    if (score < 20 && workCount > 0) {
      factors.add('Great break compliance today!');
    } else if (score == 0 && workCount == 0) {
      factors.add('No activity recorded yet');
    }

    return EyeStrainRiskScore(
      totalScore: score,
      riskLevel: level,
      contributingFactors: factors,
    );
  }
}
