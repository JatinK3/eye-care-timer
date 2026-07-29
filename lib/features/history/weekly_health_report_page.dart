import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../../models/timer_event_record.dart';
import '../../models/work_session_record.dart';

class WeeklyHealthReportPage extends StatelessWidget {
  final Map<String, int> history;
  final Map<String, int> waterHistory;
  final List<WorkSessionRecord> workSessions;
  final List<TimerEventRecord> timerEvents;
  final int dailyGoal;
  final int waterDailyGoalGlasses;
  final int waterGlassSizeMl;
  final ValueChanged<int>? setDailyGoal;
  final ValueChanged<int>? setWaterDailyGoalGlasses;

  const WeeklyHealthReportPage({
    super.key,
    required this.history,
    required this.waterHistory,
    required this.workSessions,
    required this.timerEvents,
    required this.dailyGoal,
    required this.waterDailyGoalGlasses,
    required this.waterGlassSizeMl,
    this.setDailyGoal,
    this.setWaterDailyGoalGlasses,
  });

  @override
  Widget build(BuildContext context) {
    // 1. Filter data to last 7 days
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dates = List.generate(
      7,
      (i) => today.subtract(Duration(days: 6 - i)),
    );

    String dateKey(DateTime d) =>
        '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

    // 2. Aggregate Data
    int totalFocusSeconds = 0;
    int totalWaterGlasses = 0;
    int completedBreaks = 0;
    int missedBreaks = 0;
    final weeklyBreaks = <int>[];
    final weeklyWater = <int>[];
    int breakGoalDays = 0;
    int waterGoalDays = 0;
    int currentCombinedStreak = 0;
    int longestCombinedStreak = 0;

    double maxScore = -1;
    double minScore = 999999;
    DateTime? bestDay;
    DateTime? worstDay;

    for (var date in dates) {
      final key = dateKey(date);

      // Daily focus
      final daySessions = workSessions.where(
        (s) => dateKey(s.completedAt) == key,
      );
      final dayFocusSecs = daySessions.fold<int>(
        0,
        (sum, s) => sum + s.durationSeconds,
      );
      totalFocusSeconds += dayFocusSecs;

      // Daily water
      final dayWater = waterHistory[key] ?? 0;
      totalWaterGlasses += dayWater;
      weeklyWater.add(dayWater);
      final dayBreaks = history[key] ?? 0;
      weeklyBreaks.add(dayBreaks);
      final breakGoalMet = dailyGoal > 0 && dayBreaks >= dailyGoal;
      final waterGoalMet =
          waterDailyGoalGlasses > 0 && dayWater >= waterDailyGoalGlasses;
      if (breakGoalMet) breakGoalDays++;
      if (waterGoalMet) waterGoalDays++;
      if (breakGoalMet && waterGoalMet) {
        currentCombinedStreak++;
        longestCombinedStreak = math.max(
          longestCombinedStreak,
          currentCombinedStreak,
        );
      } else {
        currentCombinedStreak = 0;
      }

      // Daily breaks
      final dayEvents = timerEvents.where((e) => dateKey(e.timestamp) == key);
      final dayCompleted = dayEvents
          .where(
            (e) =>
                e.type == TimerEventType.breakCompleted ||
                e.type == TimerEventType.naturalBreakCredited,
          )
          .length;
      final dayMissed = dayEvents
          .where(
            (e) =>
                e.type == TimerEventType.breakSkipped ||
                e.type == TimerEventType.breakPostponed,
          )
          .length;

      completedBreaks += dayCompleted;
      missedBreaks += dayMissed;

      // Calculate score for the day
      double score = 0;
      if (dayFocusSecs > 0) {
        // Only score days with activity
        final compliance = dayCompleted + dayMissed > 0
            ? dayCompleted / (dayCompleted + dayMissed)
            : 1.0;
        final hydration = waterDailyGoalGlasses > 0
            ? (dayWater / waterDailyGoalGlasses).clamp(0.0, 1.0)
            : 1.0;

        // 50% break compliance, 30% hydration, 20% focus time (capped at 4 hours for score)
        final focusScore = (dayFocusSecs / (4 * 3600)).clamp(0.0, 1.0);

        score = (compliance * 50) + (hydration * 30) + (focusScore * 20);

        if (score > maxScore) {
          maxScore = score;
          bestDay = date;
        }
        if (score < minScore) {
          minScore = score;
          worstDay = date;
        }
      }
    }

    final totalWaterMl = totalWaterGlasses * waterGlassSizeMl;
    final totalBreaks = completedBreaks + missedBreaks;
    final breakCompliance = totalBreaks > 0
        ? ((completedBreaks / totalBreaks) * 100).round()
        : 100;
    final activeDays = List<int>.generate(7, (index) => index)
        .where((index) => weeklyBreaks[index] > 0 || weeklyWater[index] > 0)
        .length;

    final weeklyTakeaway = activeDays == 0
        ? 'Your week is ready when you are. Log a break or a glass of water to start building your trend.'
        : waterGoalDays < breakGoalDays
        ? 'Hydration is the clearest opportunity this week. A glass near each focus break can make the habit easier.'
        : breakGoalDays < waterGoalDays
        ? 'Your water habit is leading your break routine. Try protecting one more eye break on your busiest days.'
        : longestCombinedStreak >= 3
        ? 'Great rhythm: you met both daily goals for $longestCombinedStreak days in a row.'
        : 'Your break and hydration habits are moving together. Aim for both goals on your next active day.';
    final breakSuggestion = _goalSuggestion(
      currentGoal: dailyGoal,
      goalDays: breakGoalDays,
      activeDays: activeDays,
      metricName: 'break',
    );
    final waterSuggestion = _goalSuggestion(
      currentGoal: waterDailyGoalGlasses,
      goalDays: waterGoalDays,
      activeDays: activeDays,
      metricName: 'water',
    );

    String formatDuration(int seconds) {
      final h = seconds ~/ 3600;
      final m = (seconds % 3600) ~/ 60;
      if (h > 0) return '${h}h ${m}m';
      return '${m}m';
    }

    String formatDate(DateTime d) {
      const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return '${weekdays[d.weekday - 1]}, ${d.month}/${d.day}';
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Weekly Health Report')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Your last 7 days',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            'Break and hydration progress, normalized against your daily goals.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          _WeeklyTrendCard(
            dates: dates,
            breaks: weeklyBreaks,
            water: weeklyWater,
            dailyBreakGoal: dailyGoal,
            dailyWaterGoal: waterDailyGoalGlasses,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _GoalProgressCard(
                  icon: Icons.visibility_outlined,
                  label: 'Break goals',
                  value: '$breakGoalDays/7',
                  detail: 'days met',
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _GoalProgressCard(
                  icon: Icons.water_drop_outlined,
                  label: 'Water goals',
                  value: '$waterGoalDays/7',
                  detail: 'days met',
                  color: const Color(0xFF3BA7E6),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _GoalProgressCard(
                  icon: Icons.local_fire_department_outlined,
                  label: 'Best streak',
                  value: '$longestCombinedStreak',
                  detail: 'both goals',
                  color: Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _WeeklyTakeawayCard(message: weeklyTakeaway, activeDays: activeDays),
          if (breakSuggestion != null || waterSuggestion != null) ...[
            const SizedBox(height: 16),
            _GoalCalibrationCard(
              breakSuggestion: breakSuggestion,
              waterSuggestion: waterSuggestion,
              onApplyBreak: setDailyGoal,
              onApplyWater: setWaterDailyGoalGlasses,
            ),
          ],
          const SizedBox(height: 16),
          _buildReportCard(
            context,
            title: 'Focus Time',
            value: formatDuration(totalFocusSeconds),
            icon: Icons.timer,
            color: Colors.blue,
            subtitle: 'Total focus duration this week',
          ),
          const SizedBox(height: 12),
          _buildReportCard(
            context,
            title: 'Break Compliance',
            value: '$breakCompliance%',
            icon: Icons.self_improvement,
            color: breakCompliance >= 80 ? Colors.green : Colors.orange,
            subtitle: '$completedBreaks taken, $missedBreaks skipped/postponed',
          ),
          const SizedBox(height: 12),
          _buildReportCard(
            context,
            title: 'Hydration',
            value: '${totalWaterMl ~/ 1000}L ${totalWaterMl % 1000}ml',
            icon: Icons.water_drop,
            color: Colors.cyan,
            subtitle: '$totalWaterGlasses glasses total',
          ),
          const SizedBox(height: 12),
          if (bestDay != null)
            _buildDayCard(
              context,
              title: 'Best Day',
              date: formatDate(bestDay),
              icon: Icons.star,
              color: Colors.amber,
              score: maxScore.round(),
            ),
          const SizedBox(height: 12),
          if (worstDay != null && worstDay != bestDay)
            _buildDayCard(
              context,
              title: 'Needs Improvement',
              date: formatDate(worstDay),
              icon: Icons.trending_down,
              color: Colors.red,
              score: minScore.round(),
            ),
        ],
      ),
    );
  }

  Widget _buildReportCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required String subtitle,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withAlpha(51),
              foregroundColor: color,
              child: Icon(icon),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.grey),
                  ),
                ],
              ),
            ),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDayCard(
    BuildContext context, {
    required String title,
    required String date,
    required IconData icon,
    required Color color,
    required int score,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(date, style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: color.withAlpha(25),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                'Score: $score',
                style: TextStyle(color: color, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  _GoalSuggestion? _goalSuggestion({
    required int currentGoal,
    required int goalDays,
    required int activeDays,
    required String metricName,
  }) {
    if (currentGoal <= 0 || activeDays < 4) return null;
    if (goalDays >= 6 && currentGoal < 20) {
      return _GoalSuggestion(
        currentGoal: currentGoal,
        suggestedGoal: currentGoal + 1,
        metricName: metricName,
        reason: 'You met this goal on $goalDays of the last 7 days.',
      );
    }
    if (goalDays <= 1 && currentGoal > 1) {
      return _GoalSuggestion(
        currentGoal: currentGoal,
        suggestedGoal: currentGoal - 1,
        metricName: metricName,
        reason: 'This goal was met on $goalDays of $activeDays active days.',
      );
    }
    return null;
  }
}

class _GoalSuggestion {
  final int currentGoal;
  final int suggestedGoal;
  final String metricName;
  final String reason;

  const _GoalSuggestion({
    required this.currentGoal,
    required this.suggestedGoal,
    required this.metricName,
    required this.reason,
  });

  bool get isIncrease => suggestedGoal > currentGoal;
}

class _GoalCalibrationCard extends StatefulWidget {
  final _GoalSuggestion? breakSuggestion;
  final _GoalSuggestion? waterSuggestion;
  final ValueChanged<int>? onApplyBreak;
  final ValueChanged<int>? onApplyWater;

  const _GoalCalibrationCard({
    required this.breakSuggestion,
    required this.waterSuggestion,
    required this.onApplyBreak,
    required this.onApplyWater,
  });

  @override
  State<_GoalCalibrationCard> createState() => _GoalCalibrationCardState();
}

class _GoalCalibrationCardState extends State<_GoalCalibrationCard> {
  bool _breakApplied = false;
  bool _waterApplied = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;
    final canApplyBreak = widget.onApplyBreak != null;
    final canApplyWater = widget.onApplyWater != null;

    Widget suggestionRow({
      required _GoalSuggestion suggestion,
      required IconData icon,
      required Color color,
      required bool applied,
      required bool canApply,
      required VoidCallback onApply,
    }) {
      final noun = suggestion.metricName == 'water' ? 'glasses' : 'breaks';
      final direction = suggestion.isIncrease ? 'Raise' : 'Lower';
      return Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$direction ${suggestion.metricName} goal: ${suggestion.currentGoal} → ${suggestion.suggestedGoal} $noun',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      suggestion.reason,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.tonal(
                onPressed: !canApply || applied ? null : onApply,
                style: FilledButton.styleFrom(
                  foregroundColor: color,
                  minimumSize: const Size(0, 36),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                ),
                child: Text(applied ? 'Applied' : 'Apply'),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.tune_rounded, color: accent),
              const SizedBox(width: 8),
              Text(
                'Goal calibration',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              Text(
                'Optional',
                style: theme.textTheme.labelMedium?.copyWith(color: accent),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'These are small, rule-based suggestions from your recent week. Nothing changes until you apply it.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (widget.breakSuggestion case final suggestion?)
            suggestionRow(
              suggestion: suggestion,
              icon: Icons.visibility_outlined,
              color: accent,
              applied: _breakApplied,
              canApply: canApplyBreak,
              onApply: () {
                widget.onApplyBreak?.call(suggestion.suggestedGoal);
                setState(() => _breakApplied = true);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Break goal updated to ${suggestion.suggestedGoal}.',
                    ),
                    duration: const Duration(seconds: 3),
                    behavior: SnackBarBehavior.floating,
                    margin: const EdgeInsets.fromLTRB(16, 0, 16, 104),
                  ),
                );
              },
            ),
          if (widget.waterSuggestion case final suggestion?)
            suggestionRow(
              suggestion: suggestion,
              icon: Icons.water_drop_outlined,
              color: const Color(0xFF3BA7E6),
              applied: _waterApplied,
              canApply: canApplyWater,
              onApply: () {
                widget.onApplyWater?.call(suggestion.suggestedGoal);
                setState(() => _waterApplied = true);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Water goal updated to ${suggestion.suggestedGoal} glasses.',
                    ),
                    duration: const Duration(seconds: 3),
                    behavior: SnackBarBehavior.floating,
                    margin: const EdgeInsets.fromLTRB(16, 0, 16, 104),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _GoalProgressCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String detail;
  final Color color;

  const _GoalProgressCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.detail,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 10),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            detail,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _WeeklyTakeawayCard extends StatelessWidget {
  final String message;
  final int activeDays;

  const _WeeklyTakeawayCard({required this.message, required this.activeDays});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.16),
            Theme.of(context).colorScheme.secondary.withValues(alpha: 0.10),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.20)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.16),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.auto_awesome_outlined, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Weekly takeaway',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$activeDays active ${activeDays == 1 ? 'day' : 'days'} this week',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WeeklyTrendCard extends StatelessWidget {
  final List<DateTime> dates;
  final List<int> breaks;
  final List<int> water;
  final int dailyBreakGoal;
  final int dailyWaterGoal;

  const _WeeklyTrendCard({
    required this.dates,
    required this.breaks,
    required this.water,
    required this.dailyBreakGoal,
    required this.dailyWaterGoal,
  });

  String _weekday(DateTime date) {
    const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return labels[date.weekday - 1];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final breakColor = theme.colorScheme.primary;
    const waterColor = Color(0xFF3BA7E6);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.60),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.show_chart_rounded, color: breakColor),
              const SizedBox(width: 8),
              Text(
                'Goal progress trend',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              Text(
                'Goal = 100%',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'A day can rise above the line when you exceed a goal.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 154,
            width: double.infinity,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 700),
              curve: Curves.easeOutCubic,
              builder: (context, progress, _) => CustomPaint(
                painter: _WeeklyTrendPainter(
                  breaks: breaks,
                  water: water,
                  dailyBreakGoal: dailyBreakGoal,
                  dailyWaterGoal: dailyWaterGoal,
                  breakColor: breakColor,
                  waterColor: waterColor,
                  gridColor: theme.colorScheme.outlineVariant.withValues(
                    alpha: 0.45,
                  ),
                  progress: progress,
                ),
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: dates
                .map(
                  (date) => Text(
                    _weekday(date),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 14,
            runSpacing: 6,
            children: [
              _TrendLegend(color: breakColor, label: 'Break goal'),
              const _TrendLegend(color: waterColor, label: 'Water goal'),
              _TrendLegend(
                color: theme.colorScheme.onSurfaceVariant,
                label: '100% target',
                dashed: true,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TrendLegend extends StatelessWidget {
  final Color color;
  final String label;
  final bool dashed;

  const _TrendLegend({
    required this.color,
    required this.label,
    this.dashed = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 18,
          child: dashed
              ? Row(
                  children: List.generate(
                    3,
                    (_) => Expanded(
                      child: Container(
                        height: 2,
                        margin: const EdgeInsets.only(right: 2),
                        color: color.withValues(alpha: 0.65),
                      ),
                    ),
                  ),
                )
              : Container(
                  height: 3,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
        ),
        const SizedBox(width: 6),
        Text(label, style: Theme.of(context).textTheme.labelSmall),
      ],
    );
  }
}

class _WeeklyTrendPainter extends CustomPainter {
  final List<int> breaks;
  final List<int> water;
  final int dailyBreakGoal;
  final int dailyWaterGoal;
  final Color breakColor;
  final Color waterColor;
  final Color gridColor;
  final double progress;

  const _WeeklyTrendPainter({
    required this.breaks,
    required this.water,
    required this.dailyBreakGoal,
    required this.dailyWaterGoal,
    required this.breakColor,
    required this.waterColor,
    required this.gridColor,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const topPadding = 10.0;
    const bottomPadding = 12.0;
    final chartHeight = size.height - topPadding - bottomPadding;
    final chartRect = Rect.fromLTWH(0, topPadding, size.width, chartHeight);

    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    for (final ratio in [0.0, 0.5, 1.0]) {
      final y = chartRect.bottom - chartHeight * ratio;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
    _drawDashedLine(
      canvas,
      Offset(0, chartRect.top),
      Offset(size.width, chartRect.top),
      gridPaint..color = gridColor.withValues(alpha: 0.9),
    );

    _drawSeries(canvas, chartRect, breaks, dailyBreakGoal, breakColor);
    _drawSeries(
      canvas,
      chartRect,
      water,
      dailyWaterGoal,
      waterColor,
      maxRatio: 1.0,
    );
  }

  void _drawSeries(
    Canvas canvas,
    Rect chartRect,
    List<int> values,
    int goal,
    Color color, {
    double maxRatio = 1.25,
  }) {
    if (values.isEmpty) return;
    final effectiveGoal = math.max(1, goal);
    final stepX = values.length == 1
        ? 0.0
        : chartRect.width / (values.length - 1);
    final points = <Offset>[];
    for (var index = 0; index < values.length; index++) {
      final ratio =
          (values[index] / effectiveGoal).clamp(0.0, maxRatio) / maxRatio;
      final animatedRatio = ratio * progress;
      points.add(
        Offset(
          index * stepX,
          chartRect.bottom - chartRect.height * animatedRatio,
        ),
      );
    }

    final line = Path()..moveTo(points.first.dx, points.first.dy);
    for (var index = 1; index < points.length; index++) {
      final previous = points[index - 1];
      final current = points[index];
      final controlX = (previous.dx + current.dx) / 2;
      line.cubicTo(
        controlX,
        previous.dy,
        controlX,
        current.dy,
        current.dx,
        current.dy,
      );
    }

    final area = Path.from(line)
      ..lineTo(points.last.dx, chartRect.bottom)
      ..lineTo(points.first.dx, chartRect.bottom)
      ..close();
    canvas.drawPath(
      area,
      Paint()
        ..shader = LinearGradient(
          colors: [color.withValues(alpha: 0.28), color.withValues(alpha: 0)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(chartRect),
    );
    canvas.drawPath(
      line,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    for (final point in points) {
      canvas.drawCircle(point, 3.5, Paint()..color = color);
      canvas.drawCircle(
        point,
        1.5,
        Paint()..color = Colors.white.withValues(alpha: 0.95),
      );
    }

    // Draw today's exact value as a dotted line to the Y-axis if != goal
    final todayValue = values.last;
    if (todayValue != goal && progress > 0.9) {
      final todayPoint = points.last;
      _drawDashedLine(
        canvas,
        Offset(0, todayPoint.dy),
        todayPoint,
        Paint()
          ..color = color.withValues(alpha: 0.6)
          ..strokeWidth = 1.0,
      );

      final textPainter = TextPainter(
        text: TextSpan(
          text: todayValue.toString(),
          style: TextStyle(
            color: color,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      textPainter.paint(
        canvas,
        Offset(-textPainter.width - 4, todayPoint.dy - textPainter.height / 2),
      );
    }
  }

  void _drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint) {
    const dash = 5.0;
    const gap = 4.0;
    var x = start.dx;
    while (x < end.dx) {
      canvas.drawLine(
        Offset(x, start.dy),
        Offset(math.min(x + dash, end.dx), end.dy),
        paint,
      );
      x += dash + gap;
    }
  }

  @override
  bool shouldRepaint(covariant _WeeklyTrendPainter oldDelegate) {
    return oldDelegate.breaks != breaks ||
        oldDelegate.water != water ||
        oldDelegate.dailyBreakGoal != dailyBreakGoal ||
        oldDelegate.dailyWaterGoal != dailyWaterGoal ||
        oldDelegate.progress != progress ||
        oldDelegate.breakColor != breakColor ||
        oldDelegate.waterColor != waterColor ||
        oldDelegate.gridColor != gridColor;
  }
}
