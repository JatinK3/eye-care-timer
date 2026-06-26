import "dart:convert";
import "dart:io";
import "dart:math" as math;
import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";

import "../../models/timer_event_record.dart";
import "../../models/work_session_record.dart";
import "../../generated/l10n/app_localizations.dart";

enum HistoryRange { sevenDays, thirtyDays, all }

class HistoryPage extends StatefulWidget {
  final Map<String, int> history;
  final List<WorkSessionRecord> workSessions;
  final List<TimerEventRecord> timerEvents;
  final int dailyGoal;
  final VoidCallback resetHistory;

  const HistoryPage({
    super.key,
    required this.history,
    required this.workSessions,
    required this.timerEvents,
    required this.dailyGoal,
    required this.resetHistory,
  });

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  late Map<String, int> _history;
  late List<WorkSessionRecord> _workSessions;
  late List<TimerEventRecord> _timerEvents;
  HistoryRange _range = HistoryRange.sevenDays;

  @override
  void initState() {
    super.initState();
    _history = Map<String, int>.from(widget.history);
    _workSessions = List<WorkSessionRecord>.from(widget.workSessions);
    _timerEvents = List<TimerEventRecord>.from(widget.timerEvents);
  }

  @override
  Widget build(BuildContext context) {
    final dates = _datesForRange();
    final rangeSessions = _sessionsForRange();
    final rangeEvents = _eventsForRange();

    final completedWorkCount =
        rangeEvents.where((e) => e.type == TimerEventType.workCompleted).length;
    final cancelledWorkCount =
        rangeEvents.where((e) => e.type == TimerEventType.workCancelled).length;
    final skippedBreakCount =
        rangeEvents.where((e) => e.type == TimerEventType.breakSkipped).length;
    final postponedBreakCount =
        rangeEvents.where((e) => e.type == TimerEventType.breakPostponed).length;
    final blinksLoggedCount =
        rangeEvents.where((e) => e.type == TimerEventType.blinkReminderAcknowledged).length;

    // Calculate range-specific statistics
    final goalDays = dates
        .where((date) => (_history[_dateKey(date)] ?? 0) >= widget.dailyGoal)
        .length;
    final goalRate = dates.isEmpty
        ? 0
        : ((goalDays / dates.length) * 100).round();

    final totalFocusSeconds = rangeSessions.fold<int>(0, (sum, record) => sum + record.durationSeconds);
    final longestStreak = _longestGoalStreak(dates);
    final peakHour = _peakFocusHour(rangeSessions);

    final breakDecisionCount = completedWorkCount + skippedBreakCount + postponedBreakCount;
    final complianceRate = breakDecisionCount == 0
        ? 0
        : ((completedWorkCount / breakDecisionCount) * 100).round();
    final achievements = _achievementsFor(
      completedWorkCount: completedWorkCount,
      totalFocusSeconds: totalFocusSeconds,
      goalDays: goalDays,
      longestStreak: longestStreak,
      complianceRate: complianceRate,
      skippedBreakCount: skippedBreakCount,
      postponedBreakCount: postponedBreakCount,
    );

    final recentSessions = rangeSessions.take(10);

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.historyTitle),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // Range Switcher
          Center(
            child: SegmentedButton<HistoryRange>(
              segments: [
                ButtonSegment(
                  value: HistoryRange.sevenDays,
                  label: Text(AppLocalizations.of(context)!.sevenDays),
                ),
                ButtonSegment(
                  value: HistoryRange.thirtyDays,
                  label: Text(AppLocalizations.of(context)!.thirtyDays),
                ),
                ButtonSegment(
                  value: HistoryRange.all,
                  label: Text(AppLocalizations.of(context)!.allTime),
                ),
              ],
              selected: {_range},
              onSelectionChanged: (selection) =>
                  setState(() => _range = selection.first),
            ),
          ),
          const SizedBox(height: 16),

          // Visual Activity Chart
          _HistorySection(
            title: AppLocalizations.of(context)!.dailyActivityPattern,
            child: dates.isEmpty
                ? _EmptyMessage(AppLocalizations.of(context)!.noActivityRange)
                : _ActivityBarChart(
                    dates: dates,
                    history: _history,
                    dailyGoal: widget.dailyGoal,
                  ),
          ),
          const SizedBox(height: 16),

          // Range Specific Statistics Cards Grid
          _MetricRow(
            first: _MetricCard(
              icon: Icons.access_time_outlined,
              label: AppLocalizations.of(context)!.focusDuration,
              value: _formatTotalFocusTime(totalFocusSeconds),
              detail: "${rangeSessions.length} total sessions",
            ),
            second: _MetricCard(
              icon: Icons.track_changes_outlined,
              label: AppLocalizations.of(context)!.goalRate,
              value: "$goalRate%",
              detail: "$goalDays of ${dates.length} days met",
            ),
          ),
          const SizedBox(height: 12),
          _MetricRow(
            first: _MetricCard(
              icon: Icons.bolt_outlined,
              label: AppLocalizations.of(context)!.longestStreakLabel,
              value: "$longestStreak days",
              detail: "Consecutive goal days",
            ),
            second: _MetricCard(
              icon: Icons.star_outline,
              label: AppLocalizations.of(context)!.peakFocusHourLabel,
              value: peakHour,
              detail: "Most active time",
            ),
          ),
          const SizedBox(height: 12),
          _MetricRow(
            first: _MetricCard(
              icon: Icons.verified_outlined,
              label: AppLocalizations.of(context)!.breakComplianceLabel,
              value: "$complianceRate%",
              detail: "$completedWorkCount taken, ${skippedBreakCount + postponedBreakCount} deferred",
            ),
            second: _MetricCard(
              icon: Icons.emoji_events_outlined,
              label: AppLocalizations.of(context)!.milestonesEarnedLabel,
              value: "${achievements.where((item) => item.unlocked).length}/${achievements.length}",
              detail: "Based on this range",
            ),
          ),
          const SizedBox(height: 16),

          _HistorySection(
            title: AppLocalizations.of(context)!.achievementsTitle,
            child: _AchievementGrid(achievements: achievements),
          ),
          const SizedBox(height: 16),

          // Insights Card
          _HistorySection(
            title: AppLocalizations.of(context)!.productivityInsights,
            child: Column(
              children: [
                _InsightRow(
                  label: AppLocalizations.of(context)!.completedFocusSessions,
                  value: "$completedWorkCount",
                  icon: Icons.check_circle_outline,
                  color: Colors.green,
                ),
                _InsightRow(
                  label: AppLocalizations.of(context)!.cancelledSessions,
                  value: "$cancelledWorkCount",
                  icon: Icons.cancel_outlined,
                  color: Colors.red,
                ),
                _InsightRow(
                  label: AppLocalizations.of(context)!.skippedBreaks,
                  value: "$skippedBreakCount",
                  icon: Icons.skip_next_outlined,
                  color: Colors.orange,
                ),
                _InsightRow(
                  label: AppLocalizations.of(context)!.postponedBreaks,
                  value: "$postponedBreakCount",
                  icon: Icons.snooze_outlined,
                  color: Colors.blue,
                ),
                _InsightRow(
                  label: AppLocalizations.of(context)!.consciousBlinksLogged,
                  value: "$blinksLoggedCount",
                  icon: Icons.remove_red_eye_outlined,
                  color: Colors.teal,
                ),
                _InsightRow(
                  label: AppLocalizations.of(context)!.complianceRate,
                  value: "$complianceRate%",
                  icon: Icons.verified_outlined,
                  color: Colors.teal,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Daily Logs List
          _HistorySection(
            title: _rangeTitle(),
            child: dates.isEmpty
                ? _EmptyMessage(AppLocalizations.of(context)!.noActivityRange)
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

          // Recent Completed Sessions
          _HistorySection(
            title: AppLocalizations.of(context)!.recentCompletedSessions,
            child: recentSessions.isEmpty
                ? _EmptyMessage(AppLocalizations.of(context)!.newSessionsAppearHere)
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
          const SizedBox(height: 24),

          // Export Card
          _HistorySection(
            title: AppLocalizations.of(context)!.exportActivityData,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!.exportActivityDescription,
                ),
                const SizedBox(height: 16),
                if (!kIsWeb) ...[
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            foregroundColor: Theme.of(context).colorScheme.onPrimary,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: () => _exportToFile(context, isCsv: true),
                          icon: const Icon(Icons.download_outlined),
                          label: Text(AppLocalizations.of(context)!.saveCsv),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: () => _exportToFile(context, isCsv: false),
                          icon: const Icon(Icons.download_outlined),
                          label: Text(AppLocalizations.of(context)!.saveJson),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () => _exportToClipboard(context, isCsv: true),
                        icon: const Icon(Icons.description_outlined),
                        label: Text(AppLocalizations.of(context)!.copyCsv),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () => _exportToClipboard(context, isCsv: false),
                        icon: const Icon(Icons.code_outlined),
                        label: Text(AppLocalizations.of(context)!.copyJson),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Clear History Action Button
          OutlinedButton.icon(
            onPressed: _history.isEmpty && _workSessions.isEmpty
                ? null
                : _confirmResetHistory,
            icon: const Icon(Icons.delete_outline),
            label: Text(AppLocalizations.of(context)!.clearActivityHistory),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(height: 16),
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
    final dates = _history.keys
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

  int _longestGoalStreak(List<DateTime> rangeDates) {
    if (rangeDates.isEmpty) return 0;

    final end = _startOfDay(DateTime.now());
    final start = switch (_range) {
      HistoryRange.sevenDays => end.subtract(const Duration(days: 6)),
      HistoryRange.thirtyDays => end.subtract(const Duration(days: 29)),
      HistoryRange.all => rangeDates.last,
    };

    int currentStreak = 0;
    int maxStreak = 0;

    final daysCount = end.difference(start).inDays + 1;
    for (int i = 0; i < daysCount; i++) {
      final date = start.add(Duration(days: i));
      final count = _history[_dateKey(date)] ?? 0;
      if (widget.dailyGoal > 0 && count >= widget.dailyGoal) {
        currentStreak++;
        if (currentStreak > maxStreak) {
          maxStreak = currentStreak;
        }
      } else {
        currentStreak = 0;
      }
    }
    return maxStreak;
  }

  String _peakFocusHour(Iterable<WorkSessionRecord> sessions) {
    if (sessions.isEmpty) return "N/A";
    final hourCounts = <int, int>{};
    for (final session in sessions) {
      final hour = session.completedAt.hour;
      hourCounts[hour] = (hourCounts[hour] ?? 0) + 1;
    }
    final peakHour = hourCounts.entries.reduce((a, b) => a.value > b.value ? a : b).key;
    final endHour = (peakHour + 1) % 24;
    String formatHour(int h) {
      final suffix = h >= 12 ? "PM" : "AM";
      final displayH = h == 0 ? 12 : (h > 12 ? h - 12 : h);
      return "$displayH $suffix";
    }
    return "${formatHour(peakHour)} - ${formatHour(endHour)}";
  }

  List<_Achievement> _achievementsFor({
    required int completedWorkCount,
    required int totalFocusSeconds,
    required int goalDays,
    required int longestStreak,
    required int complianceRate,
    required int skippedBreakCount,
    required int postponedBreakCount,
  }) {
    return [
      _Achievement(
        icon: Icons.visibility_outlined,
        title: "First reset",
        detail: "Complete one eye break",
        unlocked: completedWorkCount >= 1,
      ),
      _Achievement(
        icon: Icons.local_fire_department_outlined,
        title: "Goal streak",
        detail: "Meet your daily goal 3 days in a row",
        unlocked: longestStreak >= 3,
      ),
      _Achievement(
        icon: Icons.timelapse_outlined,
        title: "Focused hour",
        detail: "Record 1 hour of focus time",
        unlocked: totalFocusSeconds >= 3600,
      ),
      _Achievement(
        icon: Icons.workspace_premium_outlined,
        title: "Consistency",
        detail: "Hit your daily goal on 5 days",
        unlocked: goalDays >= 5,
      ),
      _Achievement(
        icon: Icons.verified_outlined,
        title: "Kind discipline",
        detail: "Keep break compliance at 80% or higher",
        unlocked: completedWorkCount > 0 && complianceRate >= 80,
      ),
      _Achievement(
        icon: Icons.spa_outlined,
        title: "No rush rest",
        detail: "Avoid skips and postpones in this range",
        unlocked: completedWorkCount > 0 && skippedBreakCount == 0 && postponedBreakCount == 0,
      ),
    ];
  }

  String _formatTotalFocusTime(int totalSeconds) {
    if (totalSeconds < 60) {
      return "${totalSeconds}s";
    }
    if (totalSeconds < 3600) {
      return "${totalSeconds ~/ 60}m";
    }
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    if (minutes == 0) return "${hours}h";
    return "${hours}h ${minutes}m";
  }

  Future<void> _confirmResetHistory() async {
    final shouldReset = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.clearHistoryConfirmTitle),
        content: Text(
          AppLocalizations.of(context)!.clearHistoryConfirmBody,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(AppLocalizations.of(context)!.clear),
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
        HistoryRange.sevenDays => "Last 7 days logs",
        HistoryRange.thirtyDays => "Last 30 days logs",
        HistoryRange.all => "All active days logs",
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

  Iterable<TimerEventRecord> _eventsForRange() {
    if (_range == HistoryRange.all) return _timerEvents;
    final days = _range == HistoryRange.sevenDays ? 7 : 30;
    final cutoff = _startOfDay(
      DateTime.now(),
    ).subtract(Duration(days: days - 1));
    return _timerEvents.where(
      (record) => !record.timestamp.isBefore(cutoff),
    );
  }

  void _exportToClipboard(BuildContext context, {required bool isCsv}) {
    final String content;
    final String formatName;
    if (isCsv) {
      content = _generateCSV(_workSessions, _timerEvents);
      formatName = "CSV";
    } else {
      content = _generateJSON(_workSessions, _timerEvents);
      formatName = "JSON";
    }

    Clipboard.setData(ClipboardData(text: content));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context)!.copiedToClipboard(formatName))),
    );
  }

  Future<void> _exportToFile(BuildContext context, {required bool isCsv}) async {
    try {
      final String content = isCsv
          ? _generateCSV(_workSessions, _timerEvents)
          : _generateJSON(_workSessions, _timerEvents);

      final extension = isCsv ? 'csv' : 'json';
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').split('.').first;
      final fileName = 'blinkkind_history_$timestamp.$extension';
      
      String? dirPath;
      if (!kIsWeb) {
        if (Platform.isWindows) {
          dirPath = Platform.environment['USERPROFILE'] != null
              ? '${Platform.environment['USERPROFILE']}\\Downloads'
              : null;
        } else if (Platform.isLinux || Platform.isMacOS) {
          dirPath = Platform.environment['HOME'] != null
              ? '${Platform.environment['HOME']}/Downloads'
              : null;
        }
      }

      if (dirPath == null) {
        throw Exception("Could not determine Downloads directory path");
      }

      final dir = Directory(dirPath);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }

      final file = File('${dir.path}/$fileName');
      await file.writeAsString(content);

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.exportedToFile(fileName)),
          action: SnackBarAction(
            label: AppLocalizations.of(context)!.openFolder,
            onPressed: () {
              _openFolder(dir.path);
            },
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.failedToExport(e.toString()))),
      );
    }
  }

  void _openFolder(String path) {
    if (kIsWeb) return;
    if (Platform.isLinux) {
      Process.run('xdg-open', [path]);
    } else if (Platform.isMacOS) {
      Process.run('open', [path]);
    } else if (Platform.isWindows) {
      Process.run('explorer.exe', [path]);
    }
  }

  String _generateCSV(List<WorkSessionRecord> workSessions, List<TimerEventRecord> events) {
    final buffer = StringBuffer();
    buffer.writeln("Event Type,Timestamp,Duration (seconds)");
    for (final event in events) {
      final type = event.type.name;
      final date = event.timestamp.toIso8601String();
      final duration = event.durationSeconds;
      buffer.writeln("$type,$date,$duration");
    }
    return buffer.toString();
  }

  String _generateJSON(List<WorkSessionRecord> workSessions, List<TimerEventRecord> events) {
    final Map<String, dynamic> exportData = {
      "exportDate": DateTime.now().toIso8601String(),
      "completedWorkSessions": workSessions.map((s) => s.toJson()).toList(),
      "timerEvents": events.map((e) => e.toJson()).toList(),
    };
    return const JsonEncoder.withIndent('  ').convert(exportData);
  }
}

class _Achievement {
  final IconData icon;
  final String title;
  final String detail;
  final bool unlocked;

  const _Achievement({
    required this.icon,
    required this.title,
    required this.detail,
    required this.unlocked,
  });
}

class _AchievementGrid extends StatelessWidget {
  final List<_Achievement> achievements;

  const _AchievementGrid({required this.achievements});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final useTwoColumns = constraints.maxWidth >= 560;
        final children = achievements
            .map((achievement) => _AchievementTile(achievement: achievement))
            .toList();
        if (!useTwoColumns) {
          return Column(children: children);
        }
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: children
              .map(
                (child) => SizedBox(
                  width: (constraints.maxWidth - 12) / 2,
                  child: child,
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _AchievementTile extends StatelessWidget {
  final _Achievement achievement;

  const _AchievementTile({required this.achievement});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = achievement.unlocked
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurfaceVariant;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: achievement.unlocked
            ? theme.colorScheme.primaryContainer.withValues(alpha: 0.28)
            : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: achievement.unlocked
              ? theme.colorScheme.primary.withValues(alpha: 0.28)
              : theme.colorScheme.outlineVariant,
        ),
      ),
      child: Row(
        children: [
          Icon(achievement.unlocked ? achievement.icon : Icons.lock_outline, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  achievement.title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(achievement.detail, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InsightRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _InsightRow({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
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
              Icon(icon, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 10),
              Text(
                label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                detail,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                    ),
              ),
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
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
              ),
              const SizedBox(height: 12),
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
        padding: const EdgeInsets.symmetric(vertical: 30),
        child: Center(
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ),
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
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(width: 8),
              Icon(
                goalReached ? Icons.check_circle : Icons.radio_button_unchecked,
                size: 18,
                color: goalReached
                    ? Colors.green
                    : Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
              ),
            ],
          ),
          const SizedBox(height: 6),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation<Color>(
              goalReached
                  ? Colors.green
                  : Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityBarChart extends StatefulWidget {
  final List<DateTime> dates;
  final Map<String, int> history;
  final int dailyGoal;

  const _ActivityBarChart({
    required this.dates,
    required this.history,
    required this.dailyGoal,
  });

  @override
  State<_ActivityBarChart> createState() => _ActivityBarChartState();
}

class _ActivityBarChartState extends State<_ActivityBarChart> {
  int? _selectedIndex;

  @override
  void didUpdateWidget(covariant _ActivityBarChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.dates.length != oldWidget.dates.length) {
      _selectedIndex = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.dates.isEmpty) return const SizedBox();

    final chronologicalDates = widget.dates.reversed.toList();
    final counts = chronologicalDates.map((d) {
      final key = _dateKey(d);
      return widget.history[key] ?? 0;
    }).toList();

    final maxCount = counts.fold<int>(
      widget.dailyGoal,
      (prev, element) => element > prev ? element : prev,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_selectedIndex != null && _selectedIndex! < chronologicalDates.length) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _fullDateLabel(chronologicalDates[_selectedIndex!]),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Text(
                  "${counts[_selectedIndex!]} cycles / goal: ${widget.dailyGoal}",
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
        Container(
          height: 180,
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              // Y-Axis Labels
              Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text("$maxCount", style: Theme.of(context).textTheme.labelSmall),
                  if (widget.dailyGoal > 0 && widget.dailyGoal < maxCount)
                    Text(
                      "${widget.dailyGoal}",
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  Text("0", style: Theme.of(context).textTheme.labelSmall),
                ],
              ),
              const SizedBox(width: 8),
              // Chart Area
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final chartHeight = constraints.maxHeight - 24;
                    final goalRatio = maxCount > 0 ? widget.dailyGoal / maxCount : 0.0;
                    final goalY = chartHeight * (1 - goalRatio);

                    final barWidth = widget.dates.length > 7 ? 24.0 : 36.0;
                    final spacing = widget.dates.length > 7 ? 8.0 : 16.0;

                    Widget buildBar(int index) {
                      final date = chronologicalDates[index];
                      final count = counts[index];
                      final ratio = maxCount > 0 ? count / maxCount : 0.0;
                      final barHeight = chartHeight * ratio;
                      final isGoalReached = widget.dailyGoal > 0 && count >= widget.dailyGoal;
                      final isSelected = _selectedIndex == index;

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedIndex = isSelected ? null : index;
                          });
                        },
                        behavior: HitTestBehavior.opaque,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TweenAnimationBuilder<double>(
                              tween: Tween<double>(
                                begin: 0.0,
                                end: math.max(2.0, barHeight),
                              ),
                              duration: const Duration(milliseconds: 400),
                              curve: Curves.easeOutCubic,
                              builder: (context, value, child) {
                                return Container(
                                  width: barWidth,
                                  height: value,
                                  decoration: BoxDecoration(
                                    gradient: isGoalReached
                                        ? LinearGradient(
                                            colors: [
                                              Colors.green,
                                              Colors.green.withValues(alpha: 0.8),
                                            ],
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                          )
                                        : LinearGradient(
                                            colors: [
                                              Theme.of(context).colorScheme.primary,
                                              Theme.of(context).colorScheme.primary.withValues(alpha: 0.7),
                                            ],
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                          ),
                                    borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                                    boxShadow: isSelected
                                        ? [
                                            BoxShadow(
                                              color: (isGoalReached ? Colors.green : Theme.of(context).colorScheme.primary).withValues(alpha: 0.4),
                                              blurRadius: 8,
                                              spreadRadius: 2,
                                            )
                                          ]
                                        : null,
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 6),
                            SizedBox(
                              width: barWidth,
                              child: Text(
                                _shortDateLabel(date),
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                      color: isSelected
                                          ? Theme.of(context).colorScheme.primary
                                          : Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                                      fontWeight: isSelected ? FontWeight.bold : null,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return Stack(
                      children: [
                        // Goal Line (Dashed)
                        if (widget.dailyGoal > 0)
                          Positioned(
                            left: 0,
                            right: 0,
                            top: goalY,
                            child: Row(
                              children: List.generate(
                                40,
                                (i) => Expanded(
                                  child: Container(
                                    height: 1,
                                    color: i % 2 == 0
                                        ? (Colors.green).withValues(alpha: 0.4)
                                        : Colors.transparent,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        // Bars
                        Positioned.fill(
                          child: widget.dates.length > 7
                              ? SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  physics: const BouncingScrollPhysics(),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 4),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: List.generate(chronologicalDates.length, (index) {
                                        return Padding(
                                          padding: EdgeInsets.symmetric(horizontal: spacing / 2),
                                          child: buildBar(index),
                                        );
                                      }),
                                    ),
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: List.generate(chronologicalDates.length, (index) {
                                    return buildBar(index);
                                  }),
                                ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _dateKey(DateTime date) {
    final year = date.year.toString().padLeft(4, "0");
    final month = date.month.toString().padLeft(2, "0");
    final day = date.day.toString().padLeft(2, "0");
    return "$year-$month-$day";
  }

  String _shortDateLabel(DateTime date) {
    if (widget.dates.length <= 7) {
      const weekdays = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
      return weekdays[date.weekday - 1];
    }
    return "${date.day}";
  }

  String _fullDateLabel(DateTime date) {
    const months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
    const weekdays = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"];
    return "${weekdays[date.weekday - 1]}, ${months[date.month - 1]} ${date.day}";
  }
}
