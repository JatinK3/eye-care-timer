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

  const WeeklyHealthReportPage({
    super.key,
    required this.history,
    required this.waterHistory,
    required this.workSessions,
    required this.timerEvents,
    required this.dailyGoal,
    required this.waterDailyGoalGlasses,
    required this.waterGlassSizeMl,
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

      // Daily breaks
      final dayEvents = timerEvents.where((e) => dateKey(e.timestamp) == key);
      final dayCompleted = dayEvents
          .where((e) => e.type == TimerEventType.breakCompleted)
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
}
