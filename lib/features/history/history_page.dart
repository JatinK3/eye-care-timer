import "package:flutter/material.dart";

import "../../models/work_session_record.dart";

enum HistoryRange { sevenDays, thirtyDays, all }

class HistoryPage extends StatefulWidget {
  final Map<String, int> history;
  final List<WorkSessionRecord> workSessions;
  final int dailyGoal;
  final VoidCallback resetHistory;

  const HistoryPage({
    super.key,
    required this.history,
    required this.workSessions,
    required this.dailyGoal,
    required this.resetHistory,
  });

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  late Map<String, int> _history;
  late List<WorkSessionRecord> _workSessions;
  HistoryRange _range = HistoryRange.sevenDays;

  @override
  void initState() {
    super.initState();
    _history = Map<String, int>.from(widget.history);
    _workSessions = List<WorkSessionRecord>.from(widget.workSessions);
  }

  @override
  Widget build(BuildContext context) {
    final dates = _datesForRange();
    final best = _bestEntry();
    final goalDays = dates
        .where((date) => (_history[_dateKey(date)] ?? 0) >= widget.dailyGoal)
        .length;
    final goalRate = dates.isEmpty
        ? 0
        : ((goalDays / dates.length) * 100).round();
    final recentSessions = _sessionsForRange().take(10);

    return Scaffold(
      appBar: AppBar(title: const Text("History")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _MetricRow(
            first: _MetricCard(
              icon: Icons.calendar_month_outlined,
              label: "This month",
              value: "${_currentMonthTotal()} cycles",
              detail: _monthLabel(DateTime.now()),
            ),
            second: _MetricCard(
              icon: Icons.track_changes_outlined,
              label: "Goal rate",
              value: "$goalRate%",
              detail: "$goalDays of ${dates.length} days",
            ),
          ),
          const SizedBox(height: 12),
          _MetricRow(
            first: _MetricCard(
              icon: Icons.emoji_events_outlined,
              label: "Best day",
              value: best == null ? "0 cycles" : "${best.value} cycles",
              detail: best?.key ?? "No history yet",
            ),
            second: _MetricCard(
              icon: Icons.trending_up_outlined,
              label: "7-day trend",
              value: _trendValue(),
              detail: _trendDetail(),
            ),
          ),
          const SizedBox(height: 16),
          SegmentedButton<HistoryRange>(
            segments: const [
              ButtonSegment(
                value: HistoryRange.sevenDays,
                label: Text("7 days"),
              ),
              ButtonSegment(
                value: HistoryRange.thirtyDays,
                label: Text("30 days"),
              ),
              ButtonSegment(value: HistoryRange.all, label: Text("All")),
            ],
            selected: {_range},
            onSelectionChanged: (selection) =>
                setState(() => _range = selection.first),
          ),
          const SizedBox(height: 16),
          _HistorySection(
            title: _rangeTitle(),
            child: dates.isEmpty
                ? const _EmptyMessage("No activity in this range")
                : Column(
                    children: dates
                        .map(
                          (date) => _HistoryRow(
                            label: _friendlyDateLabel(date),
                            count: _history[_dateKey(date)] ?? 0,
                            dailyGoal: widget.dailyGoal,
                          ),
                        )
                        .toList(),
                  ),
          ),
          const SizedBox(height: 16),
          _HistorySection(
            title: "Recent completed sessions",
            child: recentSessions.isEmpty
                ? const _EmptyMessage("New completed sessions will appear here")
                : Column(
                    children: recentSessions
                        .map(
                          (record) => ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.check_circle_outline),
                            title: Text(_sessionDateLabel(record.completedAt)),
                            subtitle: Text(
                              "Focused for ${_durationLabel(record.durationSeconds)}",
                            ),
                            trailing: Text(_timeLabel(record.completedAt)),
                          ),
                        )
                        .toList(),
                  ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _history.isEmpty && _workSessions.isEmpty
                ? null
                : _confirmResetHistory,
            icon: const Icon(Icons.delete_outline),
            label: const Text("Clear activity history"),
          ),
        ],
      ),
    );
  }

  List<DateTime> _datesForRange() {
    final today = _startOfDay(DateTime.now());
    final count = switch (_range) {
      HistoryRange.sevenDays => 7,
      HistoryRange.thirtyDays => 30,
      HistoryRange.all => 0,
    };
    if (count > 0) {
      return List.generate(
        count,
        (index) => today.subtract(Duration(days: index)),
      );
    }
    final dates =
        _history.keys
            .map(DateTime.tryParse)
            .whereType<DateTime>()
            .map(_startOfDay)
            .toList()
          ..sort((a, b) => b.compareTo(a));
    return dates;
  }

  Iterable<WorkSessionRecord> _sessionsForRange() {
    if (_range == HistoryRange.all) return _workSessions;
    final days = _range == HistoryRange.sevenDays ? 7 : 30;
    final cutoff = _startOfDay(
      DateTime.now(),
    ).subtract(Duration(days: days - 1));
    return _workSessions.where(
      (record) => !record.completedAt.isBefore(cutoff),
    );
  }

  MapEntry<String, int>? _bestEntry() {
    if (_history.isEmpty) return null;
    return _history.entries.reduce(
      (best, entry) => entry.value > best.value ? entry : best,
    );
  }

  int _currentMonthTotal() {
    final now = DateTime.now();
    return _history.entries.fold(0, (total, entry) {
      final date = DateTime.tryParse(entry.key);
      return date != null && date.year == now.year && date.month == now.month
          ? total + entry.value
          : total;
    });
  }

  int _weekTotal(int startDaysAgo) {
    final today = _startOfDay(DateTime.now());
    return List.generate(7, (index) => startDaysAgo + index).fold(
      0,
      (total, daysAgo) =>
          total +
          (_history[_dateKey(today.subtract(Duration(days: daysAgo)))] ?? 0),
    );
  }

  String _trendValue() {
    final difference = _weekTotal(0) - _weekTotal(7);
    return difference > 0 ? "+$difference" : "$difference";
  }

  String _trendDetail() {
    final current = _weekTotal(0);
    final previous = _weekTotal(7);
    if (current == previous) return "Same as previous week";
    return current > previous
        ? "More than previous week"
        : "Fewer than previous week";
  }

  Future<void> _confirmResetHistory() async {
    final shouldReset = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Clear activity history?"),
        content: const Text(
          "This removes daily totals and completed session details. This cannot be undone.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text("Cancel"),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text("Clear"),
          ),
        ],
      ),
    );
    if (shouldReset != true || !mounted) return;
    widget.resetHistory();
    setState(() {
      _history = <String, int>{};
      _workSessions = <WorkSessionRecord>[];
    });
  }

  DateTime _startOfDay(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  String _dateKey(DateTime date) {
    final year = date.year.toString().padLeft(4, "0");
    final month = date.month.toString().padLeft(2, "0");
    final day = date.day.toString().padLeft(2, "0");
    return "$year-$month-$day";
  }

  String _rangeTitle() => switch (_range) {
    HistoryRange.sevenDays => "Last 7 days",
    HistoryRange.thirtyDays => "Last 30 days",
    HistoryRange.all => "All active days",
  };

  String _friendlyDateLabel(DateTime date) {
    final difference = _startOfDay(
      DateTime.now(),
    ).difference(_startOfDay(date)).inDays;
    if (difference == 0) return "Today";
    if (difference == 1) return "Yesterday";
    return "${date.month.toString().padLeft(2, "0")}/${date.day.toString().padLeft(2, "0")}";
  }

  String _sessionDateLabel(DateTime date) {
    final label = _friendlyDateLabel(date);
    return label == "Today" || label == "Yesterday"
        ? label
        : "$label/${date.year}";
  }

  String _timeLabel(DateTime date) {
    final hour = date.hour == 0
        ? 12
        : date.hour > 12
        ? date.hour - 12
        : date.hour;
    final minute = date.minute.toString().padLeft(2, "0");
    return "$hour:$minute ${date.hour >= 12 ? "PM" : "AM"}";
  }

  String _durationLabel(int seconds) =>
      seconds < 60 ? "$seconds sec" : "${seconds ~/ 60} min";

  String _monthLabel(DateTime date) {
    const months = [
      "January",
      "February",
      "March",
      "April",
      "May",
      "June",
      "July",
      "August",
      "September",
      "October",
      "November",
      "December",
    ];
    return "${months[date.month - 1]} ${date.year}";
  }
}

class _MetricRow extends StatelessWidget {
  final Widget first;
  final Widget second;
  const _MetricRow({required this.first, required this.second});

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(child: first),
      const SizedBox(width: 12),
      Expanded(child: second),
    ],
  );
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
  Widget build(BuildContext context) => Card(
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

class _HistorySection extends StatelessWidget {
  final String title;
  final Widget child;
  const _HistorySection({required this.title, required this.child});

  @override
  Widget build(BuildContext context) => Card(
    elevation: 1,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    child: Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    ),
  );
}

class _EmptyMessage extends StatelessWidget {
  final String message;
  const _EmptyMessage(this.message);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 20),
    child: Center(child: Text(message, textAlign: TextAlign.center)),
  );
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
    final progress = dailyGoal <= 0 ? 0.0 : (count / dailyGoal).clamp(0.0, 1.0);
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
                "$count / $dailyGoal",
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
