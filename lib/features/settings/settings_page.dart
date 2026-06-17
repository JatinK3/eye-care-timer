import 'package:flutter/material.dart';

import '../../services/notification_service.dart';

class SettingsPage extends StatelessWidget {
  final bool isDark;
  final String colorPreset;
  final int workDurationSeconds;
  final int breakDurationSeconds;
  final int streakCount;
  final int dailyGoal;
  final bool notificationsEnabled;
  final NotificationPermissionStatus notificationPermissionStatus;
  final bool hapticsEnabled;
  final bool soundEnabled;
  final bool canChangeDurations;
  final VoidCallback toggleTheme;
  final void Function(bool enabled) setNotificationsEnabled;
  final void Function(bool enabled) setHapticsEnabled;
  final void Function(bool enabled) setSoundEnabled;
  final void Function(String preset) setPreset;
  final void Function(int workDurationSeconds, int breakDurationSeconds)
  saveDurations;
  final void Function(int dailyGoal) setDailyGoal;
  final void Function(BuildContext context) openHistory;
  final VoidCallback resetStreak;

  const SettingsPage({
    super.key,
    required this.isDark,
    required this.colorPreset,
    required this.workDurationSeconds,
    required this.breakDurationSeconds,
    required this.streakCount,
    required this.dailyGoal,
    required this.notificationsEnabled,
    required this.notificationPermissionStatus,
    required this.hapticsEnabled,
    required this.soundEnabled,
    required this.canChangeDurations,
    required this.toggleTheme,
    required this.setNotificationsEnabled,
    required this.setHapticsEnabled,
    required this.setSoundEnabled,
    required this.setPreset,
    required this.saveDurations,
    required this.setDailyGoal,
    required this.openHistory,
    required this.resetStreak,
  });

  static const List<int> _workDurationMinutes = [
    1,
    2,
    5,
    10,
    15,
    20,
    25,
    30,
    45,
    60,
  ];
  static const List<int> _breakDurationSeconds = [20, 30, 45, 60, 90, 120];
  static const List<String> _colorPresets = ['Pastel', 'Calm Blue'];
  static const List<int> _dailyGoals = [3, 4, 6, 8, 10, 12];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _Section(
            title: 'Timer',
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.work_outline),
                title: const Text('Work duration'),
                subtitle: canChangeDurations
                    ? null
                    : const Text('Pause or cancel the timer to change this'),
                trailing: DropdownButton<int>(
                  value: workDurationSeconds ~/ 60,
                  items: _workDurationMinutes
                      .map(
                        (minutes) => DropdownMenuItem<int>(
                          value: minutes,
                          child: Text('$minutes min'),
                        ),
                      )
                      .toList(),
                  onChanged: canChangeDurations
                      ? (value) {
                          if (value == null) {
                            return;
                          }
                          saveDurations(value * 60, breakDurationSeconds);
                        }
                      : null,
                ),
              ),
              const Divider(height: 1),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.visibility_outlined),
                title: const Text('Break duration'),
                subtitle: canChangeDurations
                    ? null
                    : const Text('Pause or cancel the timer to change this'),
                trailing: DropdownButton<int>(
                  value: breakDurationSeconds,
                  items: _breakDurationSeconds
                      .map(
                        (seconds) => DropdownMenuItem<int>(
                          value: seconds,
                          child: Text('$seconds sec'),
                        ),
                      )
                      .toList(),
                  onChanged: canChangeDurations
                      ? (value) {
                          if (value == null) {
                            return;
                          }
                          saveDurations(workDurationSeconds, value);
                        }
                      : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _Section(
            title: 'Appearance',
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                secondary: Icon(isDark ? Icons.dark_mode : Icons.light_mode),
                title: const Text('Dark mode'),
                value: isDark,
                onChanged: (_) => toggleTheme(),
              ),
              const Divider(height: 1),
              ..._colorPresets.map(
                (preset) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    radius: 10,
                    backgroundColor: _presetColor(preset, isDark),
                  ),
                  title: Text(preset),
                  trailing: preset == colorPreset
                      ? const Icon(Icons.check)
                      : null,
                  onTap: () => setPreset(preset),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _Section(
            title: 'Feedback',
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                secondary: const Icon(Icons.vibration),
                title: const Text('Haptics'),
                subtitle: const Text('Vibrate when a timer phase ends'),
                value: hapticsEnabled,
                onChanged: setHapticsEnabled,
              ),
              const Divider(height: 1),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                secondary: const Icon(Icons.volume_up_outlined),
                title: const Text('Sound'),
                subtitle: const Text('Play a short system alert at phase end'),
                value: soundEnabled,
                onChanged: setSoundEnabled,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _Section(
            title: 'Reminders',
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                secondary: const Icon(Icons.notifications_active_outlined),
                title: const Text('Notifications'),
                subtitle: const Text('Remind me when work or break time ends'),
                value: notificationsEnabled,
                onChanged: setNotificationsEnabled,
              ),
              const Divider(height: 1),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  _notificationPermissionIcon(),
                  color: _notificationPermissionColor(context),
                ),
                title: const Text('Permission status'),
                subtitle: Text(_notificationPermissionLabel()),
              ),
              if (!notificationsEnabled)
                const Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Text(
                    'Timer alerts are off. The countdown still works in the app.',
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          _Section(
            title: 'Progress',
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.flag_outlined),
                title: const Text('Daily goal'),
                subtitle: Text('$streakCount / $dailyGoal breaks today'),
                trailing: DropdownButton<int>(
                  value: dailyGoal,
                  items: _dailyGoals
                      .map(
                        (goal) => DropdownMenuItem<int>(
                          value: goal,
                          child: Text('$goal'),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setDailyGoal(value);
                    }
                  },
                ),
              ),
              const Divider(height: 1),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.history),
                title: const Text('History'),
                subtitle: const Text('Review your recent eye breaks'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => openHistory(context),
              ),
              const Divider(height: 1),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.local_fire_department_outlined),
                title: Text('Today: $streakCount cycles'),
                trailing: TextButton(
                  onPressed: streakCount == 0 ? null : resetStreak,
                  child: const Text('Reset'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _notificationPermissionIcon() {
    return switch (notificationPermissionStatus) {
      NotificationPermissionStatus.allowed => Icons.check_circle_outline,
      NotificationPermissionStatus.disabled => Icons.error_outline,
      NotificationPermissionStatus.unsupported => Icons.info_outline,
      NotificationPermissionStatus.unknown => Icons.hourglass_empty,
    };
  }

  Color? _notificationPermissionColor(BuildContext context) {
    return switch (notificationPermissionStatus) {
      NotificationPermissionStatus.allowed => Colors.green,
      NotificationPermissionStatus.disabled => Theme.of(
        context,
      ).colorScheme.error,
      NotificationPermissionStatus.unsupported => null,
      NotificationPermissionStatus.unknown => null,
    };
  }

  String _notificationPermissionLabel() {
    return switch (notificationPermissionStatus) {
      NotificationPermissionStatus.allowed => 'System permission allowed',
      NotificationPermissionStatus.disabled => 'System permission blocked',
      NotificationPermissionStatus.unsupported =>
        'Status unavailable on this platform',
      NotificationPermissionStatus.unknown => 'Checking system permission',
    };
  }

  Color _presetColor(String preset, bool isDark) {
    switch (preset) {
      case 'Calm Blue':
        return isDark ? Colors.lightBlueAccent.shade100 : Colors.blue;
      default:
        return isDark ? Colors.tealAccent.shade100 : Colors.teal;
    }
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _Section({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
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
            ...children,
          ],
        ),
      ),
    );
  }
}
