import 'package:flutter/material.dart';

import '../../services/notification_service.dart';
import '../../theme/color_presets.dart';

class SettingsPage extends StatefulWidget {
  final bool isDark;
  final String colorPreset;
  final int workDurationSeconds;
  final int breakDurationSeconds;
  final int streakCount;
  final int dailyGoal;
  final bool notificationsEnabled;
  final bool longBreakEnabled;
  final int longBreakDurationSeconds;
  final int longBreakEveryCycles;
  final bool autoRunEnabled;
  final int autoRunCycleLimit;
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
  final void Function({
    required bool enabled,
    required int durationSeconds,
    required int everyCycles,
  })
  saveLongBreakSettings;
  final void Function({required bool enabled, required int cycleLimit})
  saveAutoRunSettings;
  final Future<void> Function() openNotificationSettings;
  final Future<NotificationPermissionStatus> Function()
  refreshNotificationPermissionStatus;
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
    required this.longBreakEnabled,
    required this.longBreakDurationSeconds,
    required this.longBreakEveryCycles,
    required this.autoRunEnabled,
    required this.autoRunCycleLimit,
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
    required this.saveLongBreakSettings,
    required this.saveAutoRunSettings,
    required this.openNotificationSettings,
    required this.refreshNotificationPermissionStatus,
    required this.openHistory,
    required this.resetStreak,
  });

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
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
  static const List<int> _breakDurationSeconds = [20, 30, 45, 60, 90, 120, 300];
  static const List<int> _longBreakDurationSeconds = [180, 300, 600, 900];
  static const List<int> _longBreakCycles = [2, 3, 4, 5, 6];
  static const List<int> _autoRunCycleLimits = [0, 1, 2, 3, 4, 6, 8, 10, 12];
  static const List<int> _dailyGoals = [3, 4, 6, 8, 10, 12];

  late NotificationPermissionStatus _permissionStatus;
  late bool _autoRunEnabled;
  late int _autoRunCycleLimit;

  @override
  void initState() {
    super.initState();
    _permissionStatus = widget.notificationPermissionStatus;
    _autoRunEnabled = widget.autoRunEnabled;
    _autoRunCycleLimit = widget.autoRunCycleLimit;
  }

  @override
  void didUpdateWidget(covariant SettingsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.notificationPermissionStatus !=
        widget.notificationPermissionStatus) {
      _permissionStatus = widget.notificationPermissionStatus;
    }
  }

  Future<void> _openSystemNotificationSettings() async {
    await widget.openNotificationSettings();
    final status = await widget.refreshNotificationPermissionStatus();
    if (!mounted) {
      return;
    }
    setState(() {
      _permissionStatus = status;
    });
  }

  void _applyPreset(int workSeconds, int breakSeconds) {
    if (!widget.canChangeDurations) {
      return;
    }
    widget.saveDurations(workSeconds, breakSeconds);
  }

  void _saveLongBreak({bool? enabled, int? durationSeconds, int? everyCycles}) {
    widget.saveLongBreakSettings(
      enabled: enabled ?? widget.longBreakEnabled,
      durationSeconds: durationSeconds ?? widget.longBreakDurationSeconds,
      everyCycles: everyCycles ?? widget.longBreakEveryCycles,
    );
  }

  void _saveAutoRun({bool? enabled, int? cycleLimit}) {
    final nextEnabled = enabled ?? _autoRunEnabled;
    final nextCycleLimit = cycleLimit ?? _autoRunCycleLimit;
    setState(() {
      _autoRunEnabled = nextEnabled;
      _autoRunCycleLimit = nextCycleLimit;
    });
    widget.saveAutoRunSettings(
      enabled: nextEnabled,
      cycleLimit: nextCycleLimit,
    );
  }

  String _cycleLimitLabel(int cycleLimit) {
    return cycleLimit == 0 ? 'Unlimited' : '$cycleLimit cycles';
  }

  String _durationLabel(int seconds) {
    if (seconds < 60) {
      return '$seconds sec';
    }
    final minutes = seconds ~/ 60;
    return '$minutes min';
  }

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
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _PresetChip(
                    label: '20-20-20',
                    selected:
                        widget.workDurationSeconds == 20 * 60 &&
                        widget.breakDurationSeconds == 20,
                    enabled: widget.canChangeDurations,
                    onSelected: () => _applyPreset(20 * 60, 20),
                  ),
                  _PresetChip(
                    label: '25 / 5',
                    selected:
                        widget.workDurationSeconds == 25 * 60 &&
                        widget.breakDurationSeconds == 5 * 60,
                    enabled: widget.canChangeDurations,
                    onSelected: () => _applyPreset(25 * 60, 5 * 60),
                  ),
                  _PresetChip(
                    label: '45 / 5',
                    selected:
                        widget.workDurationSeconds == 45 * 60 &&
                        widget.breakDurationSeconds == 5 * 60,
                    enabled: widget.canChangeDurations,
                    onSelected: () => _applyPreset(45 * 60, 5 * 60),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.work_outline),
                title: const Text('Work duration'),
                subtitle: widget.canChangeDurations
                    ? null
                    : const Text('Pause or cancel the timer to change this'),
                trailing: DropdownButton<int>(
                  value: widget.workDurationSeconds ~/ 60,
                  items: _workDurationMinutes
                      .map(
                        (minutes) => DropdownMenuItem<int>(
                          value: minutes,
                          child: Text('$minutes min'),
                        ),
                      )
                      .toList(),
                  onChanged: widget.canChangeDurations
                      ? (value) {
                          if (value == null) {
                            return;
                          }
                          widget.saveDurations(
                            value * 60,
                            widget.breakDurationSeconds,
                          );
                        }
                      : null,
                ),
              ),
              const Divider(height: 1),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.visibility_outlined),
                title: const Text('Break duration'),
                subtitle: widget.canChangeDurations
                    ? null
                    : const Text('Pause or cancel the timer to change this'),
                trailing: DropdownButton<int>(
                  value: widget.breakDurationSeconds,
                  items: _breakDurationSeconds
                      .map(
                        (seconds) => DropdownMenuItem<int>(
                          value: seconds,
                          child: Text(_durationLabel(seconds)),
                        ),
                      )
                      .toList(),
                  onChanged: widget.canChangeDurations
                      ? (value) {
                          if (value == null) {
                            return;
                          }
                          widget.saveDurations(
                            widget.workDurationSeconds,
                            value,
                          );
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
                secondary: Icon(
                  widget.isDark ? Icons.dark_mode : Icons.light_mode,
                ),
                title: const Text('Dark mode'),
                value: widget.isDark,
                onChanged: (_) => widget.toggleTheme(),
              ),
              const Divider(height: 1),
              ...ColorPresets.names.map(
                (preset) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    radius: 10,
                    backgroundColor: ColorPresets.swatchColor(
                      preset,
                      widget.isDark,
                    ),
                  ),
                  title: Text(preset),
                  trailing: preset == widget.colorPreset
                      ? const Icon(Icons.check)
                      : null,
                  onTap: () => widget.setPreset(preset),
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
                value: widget.hapticsEnabled,
                onChanged: widget.setHapticsEnabled,
              ),
              const Divider(height: 1),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                secondary: const Icon(Icons.volume_up_outlined),
                title: const Text('Sound'),
                subtitle: const Text('Play a short system alert at phase end'),
                value: widget.soundEnabled,
                onChanged: widget.setSoundEnabled,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _Section(
            title: 'Auto run',
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                secondary: const Icon(Icons.autorenew),
                title: const Text('Run schedule automatically'),
                subtitle: Text(
                  widget.canChangeDurations
                      ? 'Continue work and break cycles until stopped or limit is reached'
                      : 'Pause or cancel the timer to change this',
                ),
                value: _autoRunEnabled,
                onChanged: widget.canChangeDurations
                    ? (enabled) => _saveAutoRun(enabled: enabled)
                    : null,
              ),
              const Divider(height: 1),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.flag_circle_outlined),
                title: const Text('Cycle limit'),
                subtitle: const Text('Completed work cycles in one run'),
                trailing: DropdownButton<int>(
                  value: _autoRunCycleLimit,
                  items: _autoRunCycleLimits
                      .map(
                        (limit) => DropdownMenuItem<int>(
                          value: limit,
                          child: Text(_cycleLimitLabel(limit)),
                        ),
                      )
                      .toList(),
                  onChanged: widget.canChangeDurations && _autoRunEnabled
                      ? (value) {
                          if (value != null) {
                            _saveAutoRun(cycleLimit: value);
                          }
                        }
                      : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _Section(
            title: 'Long break',
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                secondary: const Icon(Icons.coffee_outlined),
                title: const Text('Long break mode'),
                subtitle: Text(
                  'After ${widget.longBreakEveryCycles} work cycles, rest for ${_durationLabel(widget.longBreakDurationSeconds)}',
                ),
                value: widget.longBreakEnabled,
                onChanged: (enabled) => _saveLongBreak(enabled: enabled),
              ),
              const Divider(height: 1),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.repeat),
                title: const Text('Cycle interval'),
                trailing: DropdownButton<int>(
                  value: widget.longBreakEveryCycles,
                  items: _longBreakCycles
                      .map(
                        (cycles) => DropdownMenuItem<int>(
                          value: cycles,
                          child: Text('$cycles cycles'),
                        ),
                      )
                      .toList(),
                  onChanged: widget.longBreakEnabled
                      ? (value) {
                          if (value != null) {
                            _saveLongBreak(everyCycles: value);
                          }
                        }
                      : null,
                ),
              ),
              const Divider(height: 1),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.self_improvement_outlined),
                title: const Text('Long break duration'),
                trailing: DropdownButton<int>(
                  value: widget.longBreakDurationSeconds,
                  items: _longBreakDurationSeconds
                      .map(
                        (seconds) => DropdownMenuItem<int>(
                          value: seconds,
                          child: Text(_durationLabel(seconds)),
                        ),
                      )
                      .toList(),
                  onChanged: widget.longBreakEnabled
                      ? (value) {
                          if (value != null) {
                            _saveLongBreak(durationSeconds: value);
                          }
                        }
                      : null,
                ),
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
                value: widget.notificationsEnabled,
                onChanged: widget.setNotificationsEnabled,
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
              if (_permissionStatus == NotificationPermissionStatus.disabled)
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: _openSystemNotificationSettings,
                    icon: const Icon(Icons.settings_outlined),
                    label: const Text('Open system settings'),
                  ),
                ),
              if (!widget.notificationsEnabled)
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
                subtitle: Text(
                  '${widget.streakCount} / ${widget.dailyGoal} breaks today',
                ),
                trailing: DropdownButton<int>(
                  value: widget.dailyGoal,
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
                      widget.setDailyGoal(value);
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
                onTap: () => widget.openHistory(context),
              ),
              const Divider(height: 1),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.local_fire_department_outlined),
                title: Text('Today: ${widget.streakCount} cycles'),
                trailing: TextButton(
                  onPressed: widget.streakCount == 0
                      ? null
                      : widget.resetStreak,
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
    return switch (_permissionStatus) {
      NotificationPermissionStatus.allowed => Icons.check_circle_outline,
      NotificationPermissionStatus.disabled => Icons.error_outline,
      NotificationPermissionStatus.unsupported => Icons.info_outline,
      NotificationPermissionStatus.unknown => Icons.hourglass_empty,
    };
  }

  Color? _notificationPermissionColor(BuildContext context) {
    return switch (_permissionStatus) {
      NotificationPermissionStatus.allowed => Colors.green,
      NotificationPermissionStatus.disabled => Theme.of(
        context,
      ).colorScheme.error,
      NotificationPermissionStatus.unsupported => null,
      NotificationPermissionStatus.unknown => null,
    };
  }

  String _notificationPermissionLabel() {
    return switch (_permissionStatus) {
      NotificationPermissionStatus.allowed => 'System permission allowed',
      NotificationPermissionStatus.disabled => 'System permission blocked',
      NotificationPermissionStatus.unsupported =>
        'Status unavailable on this platform',
      NotificationPermissionStatus.unknown => 'Checking system permission',
    };
  }
}

class _PresetChip extends StatelessWidget {
  final String label;
  final bool selected;
  final bool enabled;
  final VoidCallback onSelected;

  const _PresetChip({
    required this.label,
    required this.selected,
    required this.enabled,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: enabled ? (_) => onSelected() : null,
      avatar: selected ? const Icon(Icons.check, size: 18) : null,
    );
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
