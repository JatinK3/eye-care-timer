import 'package:flutter/material.dart';

import '../../models/timer_settings.dart';
import '../../services/break_overlay_service.dart';
import '../../services/desktop_integration_service.dart';
import '../../services/notification_service.dart';
import '../../services/permissions_service.dart';
import '../../theme/color_presets.dart';

class SettingsPage extends StatefulWidget {
  final bool isDark;
  final String colorPreset;
  final int workDurationSeconds;
  final int breakDurationSeconds;
  final int streakCount;
  final int dailyGoal;
  final bool allowSkip;
  final bool allowPostpone;
  final int postponeDurationSeconds;
  final bool smartIdleEnabled;
  final String breakVisualizerStyle;
  final void Function(bool) setAllowSkip;
  final void Function(bool) setAllowPostpone;
  final void Function(int) setPostponeDurationSeconds;
  final void Function(bool) setSmartIdleEnabled;
  final void Function(String) setBreakVisualizerStyle;
  final bool notificationsEnabled;
  final bool longBreakEnabled;
  final int longBreakDurationSeconds;
  final int longBreakEveryCycles;
  final bool autoRunEnabled;
  final int autoRunCycleLimit;
  final NotificationPermissionStatus notificationPermissionStatus;
  final ExactAlarmStatus exactAlarmStatus;
  final BatteryOptimizationStatus batteryOptimizationStatus;
  final OverlayPermissionStatus overlayPermissionStatus;
  final bool hapticsEnabled;
  final bool soundEnabled;
  final bool canChangeDurations;
  final BreakMode breakMode;
  final void Function(BreakMode breakMode) setBreakMode;
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
  final Future<void> Function() openReminderChannelSettings;
  final Future<bool> Function() showTestReminder;
  final Future<NotificationReliabilityStatus> Function()
  refreshNotificationReliabilityStatus;
  final Future<void> Function() requestExactAlarmPermission;
  final Future<void> Function() openBatteryOptimizationSettings;
  final Future<void> Function() openOverlayPermissionSettings;
  final Future<bool> Function() showOverlayPreview;
  final Future<OverlayPermissionStatus> Function()
  refreshOverlayPermissionStatus;
  final UsageAccessStatus usageAccessStatus;
  final Future<UsageAccessStatus> Function() refreshUsageAccessStatus;
  final Future<void> Function() openUsageAccessSettings;
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
    required this.breakMode,
    required this.setBreakMode,
    required this.allowSkip,
    required this.allowPostpone,
    required this.postponeDurationSeconds,
    required this.smartIdleEnabled,
    required this.breakVisualizerStyle,
    required this.setAllowSkip,
    required this.setAllowPostpone,
    required this.setPostponeDurationSeconds,
    required this.setSmartIdleEnabled,
    required this.setBreakVisualizerStyle,
    required this.notificationPermissionStatus,
    required this.exactAlarmStatus,
    required this.batteryOptimizationStatus,
    required this.overlayPermissionStatus,
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
    required this.openReminderChannelSettings,
    required this.showTestReminder,
    required this.refreshNotificationReliabilityStatus,
    required this.requestExactAlarmPermission,
    required this.openBatteryOptimizationSettings,
    required this.openOverlayPermissionSettings,
    required this.showOverlayPreview,
    required this.refreshOverlayPermissionStatus,
    required this.usageAccessStatus,
    required this.refreshUsageAccessStatus,
    required this.openUsageAccessSettings,
    required this.openHistory,
    required this.resetStreak,
  });

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage>
    with WidgetsBindingObserver {
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
  static const List<int> _postponeDurations = [60, 120, 300, 600];

  late NotificationPermissionStatus _permissionStatus;
  late ExactAlarmStatus _exactAlarmStatus;
  late BatteryOptimizationStatus _batteryOptimizationStatus;
  late OverlayPermissionStatus _overlayPermissionStatus;
  late UsageAccessStatus _usageAccessStatus;
  late bool _autoRunEnabled;
  late int _autoRunCycleLimit;
  late BreakMode _breakMode;
  bool _isTestingReminder = false;
  bool _launchAtStartup = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _permissionStatus = widget.notificationPermissionStatus;
    _exactAlarmStatus = widget.exactAlarmStatus;
    _batteryOptimizationStatus = widget.batteryOptimizationStatus;
    _overlayPermissionStatus = widget.overlayPermissionStatus;
    _usageAccessStatus = widget.usageAccessStatus;
    _autoRunEnabled = widget.autoRunEnabled;
    _autoRunCycleLimit = widget.autoRunCycleLimit;
    _breakMode = widget.breakMode;
    _loadDesktopSettings();
  }

  Future<void> _loadDesktopSettings() async {
    if (DesktopIntegrationService.instance.isSupported) {
      final isEnabled = await DesktopIntegrationService.instance
          .isLaunchAtStartupEnabled();
      if (mounted) {
        setState(() {
          _launchAtStartup = isEnabled;
        });
      }
    }
  }

  @override
  void didUpdateWidget(covariant SettingsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.notificationPermissionStatus !=
        widget.notificationPermissionStatus) {
      _permissionStatus = widget.notificationPermissionStatus;
    }
    if (oldWidget.exactAlarmStatus != widget.exactAlarmStatus) {
      _exactAlarmStatus = widget.exactAlarmStatus;
    }
    if (oldWidget.batteryOptimizationStatus !=
        widget.batteryOptimizationStatus) {
      _batteryOptimizationStatus = widget.batteryOptimizationStatus;
    }
    if (oldWidget.overlayPermissionStatus != widget.overlayPermissionStatus) {
      _overlayPermissionStatus = widget.overlayPermissionStatus;
    }
    if (oldWidget.usageAccessStatus != widget.usageAccessStatus) {
      _usageAccessStatus = widget.usageAccessStatus;
    }
    if (oldWidget.breakMode != widget.breakMode) {
      _breakMode = widget.breakMode;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshSystemStatuses();
    }
  }

  Future<void> _refreshSystemStatuses() async {
    final notificationStatus = await widget
        .refreshNotificationReliabilityStatus();
    final overlayStatus = await widget.refreshOverlayPermissionStatus();
    final usageStatus = await widget.refreshUsageAccessStatus();
    if (!mounted) return;
    setState(() {
      _permissionStatus = notificationStatus.permission;
      _exactAlarmStatus = notificationStatus.exactAlarms;
      _batteryOptimizationStatus = notificationStatus.batteryOptimization;
      _overlayPermissionStatus = overlayStatus;
      _usageAccessStatus = usageStatus;
    });
  }

  Future<void> _showOverlayPreview() async {
    final shown = await widget.showOverlayPreview();
    if (!mounted || shown) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Allow display over other apps first.')),
    );
  }

  Future<void> _showTestReminder() async {
    setState(() => _isTestingReminder = true);
    final shown = await widget.showTestReminder();
    if (!mounted) return;
    setState(() => _isTestingReminder = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          shown
              ? 'Test reminder sent. Check sound and vibration.'
              : 'Test failed. Allow notifications and try again.',
        ),
      ),
    );
  }

  Future<void> _openSystemNotificationSettings() async {
    await widget.openNotificationSettings();
  }

  Future<void> _requestExactAlarmPermission() async {
    await widget.requestExactAlarmPermission();
  }

  Future<void> _openBatteryOptimizationSettings() async {
    await widget.openBatteryOptimizationSettings();
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
          if (_overlayPermissionStatus !=
              OverlayPermissionStatus.unsupported) ...[
            _Section(
              title: 'Break screen',
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    _overlayPermissionStatus == OverlayPermissionStatus.allowed
                        ? Icons.layers_outlined
                        : Icons.layers_clear_outlined,
                  ),
                  title: const Text('Display over other apps'),
                  subtitle: Text(_overlayPermissionLabel()),
                  trailing:
                      _overlayPermissionStatus ==
                          OverlayPermissionStatus.disabled
                      ? TextButton(
                          key: const ValueKey('overlay_allow_button'),
                          onPressed: widget.openOverlayPermissionSettings,
                          child: const Text('Allow'),
                        )
                      : null,
                ),
                const Divider(height: 1),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.fullscreen),
                  title: const Text('Preview break screen'),
                  subtitle: const Text('Show a 10-second black overlay'),
                  trailing: IconButton(
                    onPressed:
                        _overlayPermissionStatus ==
                            OverlayPermissionStatus.allowed
                        ? _showOverlayPreview
                        : null,
                    icon: const Icon(Icons.play_arrow),
                    tooltip: 'Preview break overlay',
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.security_outlined),
                  title: const Text('Break screen mode'),
                  subtitle: const Text('Strict mode blocks easy exit'),
                  trailing: DropdownButton<BreakMode>(
                    value: _breakMode,
                    underline: const SizedBox(),
                    items: BreakMode.values
                        .map(
                          (mode) => DropdownMenuItem<BreakMode>(
                            value: mode,
                            child: Text(_breakModeLabel(mode)),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _breakMode = value);
                        widget.setBreakMode(value);
                      }
                    },
                  ),
                ),
                if (_breakMode == BreakMode.gentle) ...[
                  const Divider(height: 1),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    secondary: const Icon(Icons.skip_next_outlined),
                    title: const Text('Allow skip'),
                    subtitle: const Text('Allow skipping the break early'),
                    value: widget.allowSkip,
                    onChanged: widget.setAllowSkip,
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    secondary: const Icon(Icons.snooze_outlined),
                    title: const Text('Allow postpone'),
                    subtitle: const Text('Allow postponing the break'),
                    value: widget.allowPostpone,
                    onChanged: widget.setAllowPostpone,
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    secondary: const Icon(Icons.psychology_outlined),
                    title: const Text('Smart Pause & Postpone'),
                    subtitle: const Text(
                      'Pause on screen-off / system idle; delay breaks for games or videos',
                    ),
                    value: widget.smartIdleEnabled,
                    onChanged: widget.setSmartIdleEnabled,
                  ),
                  const Divider(height: 1),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.style_outlined),
                    title: const Text('Break visualizer style'),
                    subtitle: const Text('Choose ambient effect during breaks'),
                    trailing: DropdownButton<String>(
                      value: widget.breakVisualizerStyle,
                      underline: const SizedBox(),
                      dropdownColor: Theme.of(context).cardColor,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                      onChanged: (String? val) {
                        if (val != null) {
                          widget.setBreakVisualizerStyle(val);
                        }
                      },
                      items: const [
                        DropdownMenuItem(
                          value: 'Random',
                          child: Text('Random/All'),
                        ),
                        DropdownMenuItem(
                          value: 'Breathing',
                          child: Text('Calm Breathing'),
                        ),
                        DropdownMenuItem(
                          value: 'BoxBreathing',
                          child: Text('Box Breathing (4-4-4-4)'),
                        ),
                        DropdownMenuItem(
                          value: 'EyeExercise',
                          child: Text('Eye Exercises'),
                        ),
                        DropdownMenuItem(
                          value: 'Ambient',
                          child: Text('Ambient Flow'),
                        ),
                        DropdownMenuItem(
                          value: 'Starry',
                          child: Text('Starry Sky'),
                        ),
                      ],
                    ),
                  ),
                  // Usage Access permission tile — only shown when smart idle is
                  // on and the user hasn't yet granted the permission.
                  if (widget.smartIdleEnabled &&
                      _usageAccessStatus !=
                          UsageAccessStatus.unsupported) ...[
                    const Divider(height: 1),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        _usageAccessStatus == UsageAccessStatus.allowed
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: _usageAccessStatus == UsageAccessStatus.allowed
                            ? Colors.green
                            : Theme.of(context).colorScheme.error,
                      ),
                      title: const Text('Usage access'),
                      subtitle: Text(
                        _usageAccessStatus == UsageAccessStatus.allowed
                            ? 'App detection enabled'
                            : 'Required to detect games & videos',
                      ),
                      trailing:
                          _usageAccessStatus != UsageAccessStatus.allowed
                          ? TextButton(
                              onPressed: () async {
                                await widget.openUsageAccessSettings();
                                if (!mounted) return;
                                final status =
                                    await widget.refreshUsageAccessStatus();
                                setState(
                                  () => _usageAccessStatus = status,
                                );
                              },
                              child: const Text('Allow'),
                            )
                          : null,
                    ),
                  ],
                  if (widget.allowPostpone) ...[
                    const Divider(height: 1),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.timer_outlined),
                      title: const Text('Postpone duration'),
                      subtitle: const Text('How long to delay the break'),
                      trailing: DropdownButton<int>(
                        value: widget.postponeDurationSeconds,
                        underline: const SizedBox(),
                        items: _postponeDurations
                            .map(
                              (seconds) => DropdownMenuItem<int>(
                                value: seconds,
                                child: Text('${seconds ~/ 60} min'),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            widget.setPostponeDurationSeconds(value);
                          }
                        },
                      ),
                    ),
                  ],
                ],
              ],
            ),
            const SizedBox(height: 16),
          ],
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
                title: const Text('In-app sound'),
                subtitle: const Text(
                  'Play an extra system alert while BlinkKind is open',
                ),
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
                leading: const Icon(Icons.volume_up_outlined),
                title: const Text('Notification sound'),
                subtitle: const Text('Uses system notification sound settings'),
                trailing: _exactAlarmStatus == ExactAlarmStatus.unsupported
                    ? null
                    : IconButton(
                        onPressed: widget.openReminderChannelSettings,
                        icon: const Icon(Icons.tune),
                        tooltip: 'Notification sound settings',
                      ),
              ),
              const Divider(height: 1),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.play_circle_outline),
                title: const Text('Test reminder'),
                subtitle: const Text('Play the actual reminder sound now'),
                trailing: _isTestingReminder
                    ? const SizedBox.square(
                        dimension: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : IconButton(
                        onPressed: widget.notificationsEnabled
                            ? _showTestReminder
                            : null,
                        icon: const Icon(Icons.play_arrow),
                        tooltip: 'Send test reminder',
                      ),
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
              if (_exactAlarmStatus != ExactAlarmStatus.unsupported) ...[
                const Divider(height: 1),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    _exactAlarmStatus == ExactAlarmStatus.allowed
                        ? Icons.alarm_on_outlined
                        : Icons.alarm_off_outlined,
                  ),
                  title: const Text('Precise reminders'),
                  subtitle: Text(
                    _exactAlarmStatus == ExactAlarmStatus.allowed
                        ? 'Exact timing allowed'
                        : 'May arrive a little late',
                  ),
                  trailing: _exactAlarmStatus == ExactAlarmStatus.disabled
                      ? TextButton(
                          onPressed: _requestExactAlarmPermission,
                          child: const Text('Allow'),
                        )
                      : null,
                ),
              ],
              if (_batteryOptimizationStatus !=
                  BatteryOptimizationStatus.unsupported) ...[
                const Divider(height: 1),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    _batteryOptimizationStatus ==
                            BatteryOptimizationStatus.unrestricted
                        ? Icons.battery_saver_outlined
                        : Icons.battery_alert_outlined,
                  ),
                  title: const Text('Background reliability'),
                  subtitle: Text(
                    _batteryOptimizationStatus ==
                            BatteryOptimizationStatus.unrestricted
                        ? 'Battery use is unrestricted'
                        : 'Battery optimization may delay alerts',
                  ),
                  trailing:
                      _batteryOptimizationStatus ==
                          BatteryOptimizationStatus.restricted
                      ? TextButton(
                          onPressed: _openBatteryOptimizationSettings,
                          child: const Text('Review'),
                        )
                      : null,
                ),
              ],
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
          if (DesktopIntegrationService.instance.isSupported) ...[
            const SizedBox(height: 16),
            _Section(
              title: 'Desktop Options',
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  secondary: const Icon(Icons.rocket_launch_outlined),
                  title: const Text('Launch at Startup'),
                  subtitle: const Text(
                    'Start BlinkKind automatically when you log in',
                  ),
                  value: _launchAtStartup,
                  onChanged: (value) async {
                    await DesktopIntegrationService.instance.setLaunchAtStartup(
                      value,
                    );
                    final isEnabled = await DesktopIntegrationService.instance
                        .isLaunchAtStartupEnabled();
                    setState(() {
                      _launchAtStartup = isEnabled;
                    });
                  },
                ),
              ],
            ),
          ],
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

  String _overlayPermissionLabel() {
    return switch (_overlayPermissionStatus) {
      OverlayPermissionStatus.allowed => 'Allowed on this device',
      OverlayPermissionStatus.disabled =>
        'Permission required for enforced breaks',
      OverlayPermissionStatus.unknown => 'Checking overlay permission',
      OverlayPermissionStatus.unsupported => 'Unavailable on this platform',
    };
  }

  String _breakModeLabel(BreakMode mode) {
    return switch (mode) {
      BreakMode.off => 'Off',
      BreakMode.gentle => 'Gentle',
      BreakMode.strict => 'Strict',
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
