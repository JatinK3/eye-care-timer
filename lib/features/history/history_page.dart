import 'package:flutter/material.dart';

class HistoryPage extends StatefulWidget {
  final Map<String, int> history;
  final int dailyGoal;
  final VoidCallback resetHistory;

  const HistoryPage({
    super.key,
    required this.history,
    required this.dailyGoal,
    required this.resetHistory,
  });

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  late Map<String, int> _history;

  @override
  void initState() {
    super.initState();
    _history = Map<String, int>.from(widget.history);
  }

  @override
  Widget build(BuildContext context) {
    final lastSevenDays = _lastSevenDays();
    final bestEntry = _bestEntry();
    final currentGoalStreak = _currentGoalStreak();

    return Scaffold(
      appBar: AppBar(title: const Text('History')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(
                child: _MetricCard(
                  icon: Icons.emoji_events_outlined,
                  label: 'Best day',
                  value: bestEntry == null
                      ? '0 breaks'
                      : '${bestEntry.value} breaks',
                  detail: bestEntry == null ? 'No history yet' : bestEntry.key,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MetricCard(
                  icon: Icons.calendar_month_outlined,
                  label: 'Goal streak',
                  value: '$currentGoalStreak days',
                  detail: '${widget.dailyGoal} breaks/day',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Last 7 days',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...lastSevenDays.map(
                    (date) => _HistoryRow(
                      label: _friendlyDateLabel(date),
                      count: _history[_dateKey(date)] ?? 0,
                      dailyGoal: widget.dailyGoal,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _history.isEmpty
                ? null
                : () {
                    widget.resetHistory();
                    setState(() {
                      _history = <String, int>{};
                    });
                  },
            icon: const Icon(Icons.delete_outline),
            label: const Text('Reset history'),
          ),
        ],
      ),
    );
  }

  List<DateTime> _lastSevenDays() {
    final today = DateTime.now();
    return List<DateTime>.generate(
      7,
      (index) => DateTime(today.year, today.month, today.day - index),
    );
  }

  MapEntry<String, int>? _bestEntry() {
    if (_history.isEmpty) {
      return null;
    }

    return _history.entries.reduce(
      (best, entry) => entry.value > best.value ? entry : best,
    );
  }

  int _currentGoalStreak() {
    final today = DateTime.now();
    var streak = 0;
    for (var index = 0; index < 365; index++) {
      final date = DateTime(today.year, today.month, today.day - index);
      final count = _history[_dateKey(date)] ?? 0;
      if (count < widget.dailyGoal) {
        break;
      }
      streak++;
    }
    return streak;
  }

  String _dateKey(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  String _friendlyDateLabel(DateTime date) {
    final today = DateTime.now();
    final normalizedToday = DateTime(today.year, today.month, today.day);
    final normalizedDate = DateTime(date.year, date.month, date.day);
    final difference = normalizedToday.difference(normalizedDate).inDays;

    if (difference == 0) {
      return 'Today';
    }
    if (difference == 1) {
      return 'Yesterday';
    }
    return '${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
  }
}

class _MetricCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String detail;

  const _MetricCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.detail,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon),
            const SizedBox(height: 10),
            Text(label, style: Theme.of(context).textTheme.labelMedium),
            const SizedBox(height: 4),
            Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 2),
            Text(detail, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  final String label;
  final int count;
  final int dailyGoal;

  const _HistoryRow({
    required this.label,
    required this.count,
    required this.dailyGoal,
  });

  @override
  Widget build(BuildContext context) {
    final double progress = dailyGoal <= 0
        ? 0.0
        : (count / dailyGoal).clamp(0.0, 1.0);
    final goalReached = dailyGoal > 0 && count >= dailyGoal;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(label)),
              Text(
                '$count / $dailyGoal',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(width: 8),
              Icon(
                goalReached ? Icons.check_circle : Icons.radio_button_unchecked,
                size: 18,
                color: goalReached ? Colors.green : null,
              ),
            ],
          ),
          const SizedBox(height: 6),
          LinearProgressIndicator(value: progress),
        ],
      ),
    );
  }
}
