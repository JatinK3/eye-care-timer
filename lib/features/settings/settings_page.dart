import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';

import '../../models/timer_settings.dart';
import '../../services/ai_service.dart';
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
  final String chimeStyle;
  final void Function(String) setChimeStyle;
  final bool blinkRemindersEnabled;
  final int blinkRemindersCadenceSeconds;
  final void Function(bool) setBlinkRemindersEnabled;
  final void Function(int) setBlinkRemindersCadenceSeconds;
  final bool canChangeDurations;
  final BreakMode breakMode;
  final void Function(BreakMode breakMode) setBreakMode;
  final VoidCallback toggleTheme;
  final void Function(bool enabled) setNotificationsEnabled;
  final void Function(bool enabled) setHapticsEnabled;
  final void Function(bool enabled) setSoundEnabled;
  final void Function(String preset) setPreset;
  final void Function(int workDurationSeconds, int breakDurationSeconds) saveDurations;
  final void Function(int dailyGoal) setDailyGoal;
  final void Function({
    required bool enabled,
    required int durationSeconds,
    required int everyCycles,
  }) saveLongBreakSettings;
  final void Function({required bool enabled, required int cycleLimit}) saveAutoRunSettings;
  final Future<void> Function() openNotificationSettings;
  final Future<void> Function() openReminderChannelSettings;
  final Future<bool> Function() showTestReminder;
  final Future<NotificationReliabilityStatus> Function() refreshNotificationReliabilityStatus;
  final Future<void> Function() requestExactAlarmPermission;
  final Future<void> Function() openBatteryOptimizationSettings;
  final Future<void> Function() openOverlayPermissionSettings;
  final Future<bool> Function() showOverlayPreview;
  final Future<bool> Function() showRealBreakTest;
  final Future<OverlayPermissionStatus> Function() refreshOverlayPermissionStatus;
  final UsageAccessStatus usageAccessStatus;
  final Future<UsageAccessStatus> Function() refreshUsageAccessStatus;
  final Future<void> Function() openUsageAccessSettings;
  final void Function(BuildContext context) openHistory;
  final VoidCallback resetStreak;
  final bool workHoursEnabled;
  final int workHoursStartHour;
  final int workHoursStartMinute;
  final int workHoursEndHour;
  final int workHoursEndMinute;
  final String workDays;
  final bool naturalBreakCreditEnabled;
  final void Function(bool) setWorkHoursEnabled;
  final void Function(int) setWorkHoursStartHour;
  final void Function(int) setWorkHoursStartMinute;
  final void Function(int) setWorkHoursEndHour;
  final void Function(int) setWorkHoursEndMinute;
  final void Function(String) setWorkDays;
  final void Function(bool) setNaturalBreakCreditEnabled;

  // New customizations parameters
  final bool amoledDarkEnabled;
  final String customAccentColorHex;
  final bool useSystemAccent;
  final void Function(bool) setAmoledDarkEnabled;
  final void Function(String) setCustomAccentColorHex;
  final void Function(bool) setUseSystemAccent;

  // AI Motivation parameters
  final bool aiMotivationEnabled;
  final String aiProvider;
  final String aiApiKey;
  final String aiModel;
  final String aiCustomSystemPrompt;
  final void Function(bool) setAiMotivationEnabled;
  final void Function(String) setAiProvider;
  final void Function(String) setAiApiKey;
  final void Function(String) setAiModel;
  final void Function(String) setAiCustomSystemPrompt;

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
    required this.chimeStyle,
    required this.setChimeStyle,
    required this.blinkRemindersEnabled,
    required this.blinkRemindersCadenceSeconds,
    required this.setBlinkRemindersEnabled,
    required this.setBlinkRemindersCadenceSeconds,
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
    required this.showRealBreakTest,
    required this.refreshOverlayPermissionStatus,
    required this.usageAccessStatus,
    required this.refreshUsageAccessStatus,
    required this.openUsageAccessSettings,
    required this.openHistory,
    required this.resetStreak,
    required this.workHoursEnabled,
    required this.workHoursStartHour,
    required this.workHoursStartMinute,
    required this.workHoursEndHour,
    required this.workHoursEndMinute,
    required this.workDays,
    required this.naturalBreakCreditEnabled,
    required this.setWorkHoursEnabled,
    required this.setWorkHoursStartHour,
    required this.setWorkHoursStartMinute,
    required this.setWorkHoursEndHour,
    required this.setWorkHoursEndMinute,
    required this.setWorkDays,
    required this.setNaturalBreakCreditEnabled,

    // New customizations constructor parameters
    required this.amoledDarkEnabled,
    required this.customAccentColorHex,
    required this.useSystemAccent,
    required this.setAmoledDarkEnabled,
    required this.setCustomAccentColorHex,
    required this.setUseSystemAccent,

    // AI Motivation constructor parameters
    required this.aiMotivationEnabled,
    required this.aiProvider,
    required this.aiApiKey,
    required this.aiModel,
    required this.aiCustomSystemPrompt,
    required this.setAiMotivationEnabled,
    required this.setAiProvider,
    required this.setAiApiKey,
    required this.setAiModel,
    required this.setAiCustomSystemPrompt,
  });

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> with WidgetsBindingObserver {
  static const List<int> _workDurationMinutes = [1, 2, 5, 10, 15, 20, 25, 30, 45, 60];
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

  // AI settings UI state
  List<String> _aiAvailableModels = [];
  bool _aiLoadingModels = false;
  String? _aiModelsError;
  bool _aiApiKeyObscured = true;
  final TextEditingController _aiApiKeyController = TextEditingController();
  final TextEditingController _aiModelCustomController = TextEditingController();
  Timer? _aiApiKeyDebounce;

  String _searchQuery = '';
  final _searchController = TextEditingController();
  AudioPlayer? _audioPlayer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _audioPlayer = AudioPlayer();
    _permissionStatus = widget.notificationPermissionStatus;
    _exactAlarmStatus = widget.exactAlarmStatus;
    _batteryOptimizationStatus = widget.batteryOptimizationStatus;
    _overlayPermissionStatus = widget.overlayPermissionStatus;
    _usageAccessStatus = widget.usageAccessStatus;
    _autoRunEnabled = widget.autoRunEnabled;
    _autoRunCycleLimit = widget.autoRunCycleLimit;
    _breakMode = widget.breakMode;
    _aiApiKeyController.text = widget.aiApiKey;
    _aiAvailableModels = AiService.instance.getDefaultModels(widget.aiProvider);
    _loadDesktopSettings();
    if (widget.aiApiKey.isNotEmpty) {
      unawaited(_fetchAiModels(widget.aiApiKey, widget.aiProvider));
    }
  }

  Future<void> _loadDesktopSettings() async {
    if (DesktopIntegrationService.instance.isSupported) {
      final isEnabled = await DesktopIntegrationService.instance.isLaunchAtStartupEnabled();
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
    if (oldWidget.notificationPermissionStatus != widget.notificationPermissionStatus) {
      _permissionStatus = widget.notificationPermissionStatus;
    }
    if (oldWidget.exactAlarmStatus != widget.exactAlarmStatus) {
      _exactAlarmStatus = widget.exactAlarmStatus;
    }
    if (oldWidget.batteryOptimizationStatus != widget.batteryOptimizationStatus) {
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
    _searchController.dispose();
    _audioPlayer?.dispose();
    _aiApiKeyController.dispose();
    _aiModelCustomController.dispose();
    _aiApiKeyDebounce?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _playChimePreview(String style) async {
    if (style == 'system_alert') {
      await SystemSound.play(SystemSoundType.alert);
    } else {
      try {
        await _audioPlayer?.stop();
        await _audioPlayer?.play(AssetSource('sounds/$style.wav'));
      } catch (e) {
        await SystemSound.play(SystemSoundType.alert);
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshSystemStatuses();
    }
  }

  Future<void> _refreshSystemStatuses() async {
    final notificationStatus = await widget.refreshNotificationReliabilityStatus();
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

  Future<void> _showRealBreakTest() async {
    final shown = await widget.showRealBreakTest();
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
    if (!widget.canChangeDurations) return;
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
    if (seconds < 60) return '$seconds sec';
    final minutes = seconds ~/ 60;
    return '$minutes min';
  }

  String _getDayNameShort(int day) {
    switch (day) {
      case 1: return 'Mon';
      case 2: return 'Tue';
      case 3: return 'Wed';
      case 4: return 'Thu';
      case 5: return 'Fri';
      case 6: return 'Sat';
      case 7: return 'Sun';
      default: return '';
    }
  }

  String _notificationPermissionLabel() {
    return switch (_permissionStatus) {
      NotificationPermissionStatus.allowed => 'System permission allowed',
      NotificationPermissionStatus.disabled => 'System permission blocked',
      NotificationPermissionStatus.unsupported => 'Status unavailable on this platform',
      NotificationPermissionStatus.unknown => 'Checking system permission',
    };
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
      NotificationPermissionStatus.disabled => Theme.of(context).colorScheme.error,
      NotificationPermissionStatus.unsupported => null,
      NotificationPermissionStatus.unknown => null,
    };
  }

  String _overlayPermissionLabel() {
    return switch (_overlayPermissionStatus) {
      OverlayPermissionStatus.allowed => 'Allowed on this device',
      OverlayPermissionStatus.disabled => 'Permission required for enforced breaks',
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

  List<SettingItem> _allSettingItems(BuildContext context) {
    final theme = Theme.of(context);
    final isDesktop = DesktopIntegrationService.instance.isSupported;

    return [
      // 1. General Schedule
      SettingItem(
        title: 'Quick presets',
        subtitle: '20-20-20, 25/5, 45/5, 10s/10s (Test)',
        keywords: ['preset', '20-20-20', 'quick', 'duration', 'time', '25', '45', '10'],
        category: 'General Schedule',
        widget: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _PresetChip(
                label: '20-20-20',
                selected: widget.workDurationSeconds == 20 * 60 && widget.breakDurationSeconds == 20,
                enabled: widget.canChangeDurations,
                onSelected: () => _applyPreset(20 * 60, 20),
              ),
              _PresetChip(
                label: '10s / 10s (Test)',
                selected: widget.workDurationSeconds == 10 && widget.breakDurationSeconds == 10,
                enabled: widget.canChangeDurations,
                onSelected: () => _applyPreset(10, 10),
              ),
              _PresetChip(
                label: '25 / 5',
                selected: widget.workDurationSeconds == 25 * 60 && widget.breakDurationSeconds == 5 * 60,
                enabled: widget.canChangeDurations,
                onSelected: () => _applyPreset(25 * 60, 5 * 60),
              ),
              _PresetChip(
                label: '45 / 5',
                selected: widget.workDurationSeconds == 45 * 60 && widget.breakDurationSeconds == 5 * 60,
                enabled: widget.canChangeDurations,
                onSelected: () => _applyPreset(45 * 60, 5 * 60),
              ),
            ],
          ),
        ),
      ),
      SettingItem(
        title: 'Work duration',
        subtitle: widget.canChangeDurations ? 'Choose work interval' : 'Pause/cancel timer to change',
        keywords: ['work', 'duration', 'minutes', 'time'],
        category: 'General Schedule',
        widget: ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.work_outline),
          title: const Text('Work duration'),
          subtitle: widget.canChangeDurations ? null : const Text('Pause or cancel the timer to change this'),
          trailing: DropdownButton<int>(
            value: widget.workDurationSeconds < 60 ? 0 : widget.workDurationSeconds ~/ 60,
            items: [
              if (widget.workDurationSeconds < 60)
                DropdownMenuItem<int>(
                  value: 0,
                  child: Text('${widget.workDurationSeconds}s'),
                ),
              ..._workDurationMinutes.map(
                (minutes) => DropdownMenuItem<int>(
                  value: minutes,
                  child: Text('$minutes min'),
                ),
              ),
            ],
            onChanged: widget.canChangeDurations
                ? (value) {
                    if (value == null) return;
                    final nextSeconds = value == 0 ? widget.workDurationSeconds : value * 60;
                    widget.saveDurations(nextSeconds, widget.breakDurationSeconds);
                  }
                : null,
          ),
        ),
      ),
      SettingItem(
        title: 'Break duration',
        subtitle: widget.canChangeDurations ? 'Choose break length' : 'Pause/cancel timer to change',
        keywords: ['break', 'duration', 'seconds', 'time'],
        category: 'General Schedule',
        widget: ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.visibility_outlined),
          title: const Text('Break duration'),
          subtitle: widget.canChangeDurations ? null : const Text('Pause or cancel the timer to change this'),
          trailing: DropdownButton<int>(
            value: widget.breakDurationSeconds,
            items: [
              if (!_breakDurationSeconds.contains(widget.breakDurationSeconds))
                DropdownMenuItem<int>(
                  value: widget.breakDurationSeconds,
                  child: Text(_durationLabel(widget.breakDurationSeconds)),
                ),
              ..._breakDurationSeconds.map(
                (seconds) => DropdownMenuItem<int>(
                  value: seconds,
                  child: Text(_durationLabel(seconds)),
                ),
              ),
            ],
            onChanged: widget.canChangeDurations
                ? (value) {
                    if (value == null) return;
                    widget.saveDurations(widget.workDurationSeconds, value);
                  }
                : null,
          ),
        ),
      ),
      SettingItem(
        title: 'Daily goal',
        subtitle: '${widget.streakCount} / ${widget.dailyGoal} breaks today',
        keywords: ['daily', 'goal', 'streak', 'target', 'breaks'],
        category: 'General Schedule',
        widget: ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.flag_outlined),
          title: const Text('Daily goal'),
          subtitle: Text('${widget.streakCount} / ${widget.dailyGoal} breaks today'),
          trailing: DropdownButton<int>(
            value: widget.dailyGoal,
            items: _dailyGoals.map(
              (goal) => DropdownMenuItem<int>(
                value: goal,
                child: Text('$goal'),
              ),
            ).toList(),
            onChanged: (value) {
              if (value != null) widget.setDailyGoal(value);
            },
          ),
        ),
      ),
      SettingItem(
        title: 'History',
        subtitle: 'Review your recent eye breaks',
        keywords: ['history', 'recent', 'breaks', 'insights', 'statistics', 'csv', 'json'],
        category: 'General Schedule',
        widget: ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.history),
          title: const Text('History'),
          subtitle: const Text('Review your recent eye breaks'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => widget.openHistory(context),
        ),
      ),
      SettingItem(
        title: 'Today\'s progress',
        subtitle: 'Reset today\'s streak',
        keywords: ['streak', 'today', 'progress', 'reset'],
        category: 'General Schedule',
        widget: ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.local_fire_department_outlined),
          title: Text('Today: ${widget.streakCount} cycles'),
          trailing: TextButton(
            onPressed: widget.streakCount == 0 ? null : widget.resetStreak,
            child: const Text('Reset'),
          ),
        ),
      ),
      SettingItem(
        title: 'Active work hours & days',
        subtitle: 'Only run the timer cycles during specific hours and days',
        keywords: ['schedule', 'work', 'hours', 'days', 'time', 'start', 'end', 'calendar'],
        category: 'General Schedule',
        widget: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              secondary: const Icon(Icons.calendar_today_outlined),
              title: const Text('Active work hours & days'),
              subtitle: const Text('Only run the timer cycles during specific hours and days'),
              value: widget.workHoursEnabled,
              onChanged: widget.setWorkHoursEnabled,
            ),
            if (widget.workHoursEnabled) ...[
              const Divider(height: 1),
              const SizedBox(height: 8),
              const Text(
                'Active Days',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (int i = 1; i <= 7; i++)
                    FilterChip(
                      label: Text(_getDayNameShort(i)),
                      selected: widget.workDays
                          .split(',')
                          .where((e) => e.isNotEmpty)
                          .map(int.parse)
                          .contains(i),
                      onSelected: (selected) {
                        final activeDays = widget.workDays
                            .split(',')
                            .where((e) => e.isNotEmpty)
                            .map(int.parse)
                            .toList();
                        if (selected) {
                          if (!activeDays.contains(i)) activeDays.add(i);
                        } else {
                          if (activeDays.length > 1) activeDays.remove(i);
                        }
                        activeDays.sort();
                        widget.setWorkDays(activeDays.join(','));
                      },
                    ),
                ],
              ),
              const SizedBox(height: 8),
              const Divider(height: 1),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.access_time, size: 20),
                  const SizedBox(width: 12),
                  const Text('Start Time', style: TextStyle(fontSize: 15)),
                  const Spacer(),
                  DropdownButton<int>(
                    value: widget.workHoursStartHour,
                    onChanged: (val) {
                      if (val != null) widget.setWorkHoursStartHour(val);
                    },
                    underline: const SizedBox(),
                    items: List.generate(24, (index) {
                      final displayHour = index.toString().padLeft(2, '0');
                      return DropdownMenuItem<int>(
                        value: index,
                        child: Text(displayHour),
                      );
                    }),
                  ),
                  const Text(' : '),
                  DropdownButton<int>(
                    value: widget.workHoursStartMinute,
                    onChanged: (val) {
                      if (val != null) widget.setWorkHoursStartMinute(val);
                    },
                    underline: const SizedBox(),
                    items: List.generate(60, (index) {
                      final displayMinute = index.toString().padLeft(2, '0');
                      return DropdownMenuItem<int>(
                        value: index,
                        child: Text(displayMinute),
                      );
                    }),
                  ),
                ],
              ),
              const Divider(height: 1),
              Row(
                children: [
                  const Icon(Icons.access_time_filled, size: 20),
                  const SizedBox(width: 12),
                  const Text('End Time', style: TextStyle(fontSize: 15)),
                  const Spacer(),
                  DropdownButton<int>(
                    value: widget.workHoursEndHour,
                    onChanged: (val) {
                      if (val != null) widget.setWorkHoursEndHour(val);
                    },
                    underline: const SizedBox(),
                    items: List.generate(24, (index) {
                      final displayHour = index.toString().padLeft(2, '0');
                      return DropdownMenuItem<int>(
                        value: index,
                        child: Text(displayHour),
                      );
                    }),
                  ),
                  const Text(' : '),
                  DropdownButton<int>(
                    value: widget.workHoursEndMinute,
                    onChanged: (val) {
                      if (val != null) widget.setWorkHoursEndMinute(val);
                    },
                    underline: const SizedBox(),
                    items: List.generate(60, (index) {
                      final displayMinute = index.toString().padLeft(2, '0');
                      return DropdownMenuItem<int>(
                        value: index,
                        child: Text(displayMinute),
                      );
                    }),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),

      // 2. Break Screen & Behavior
      SettingItem(
        title: 'Break screen mode',
        subtitle: 'Off, Gentle, or Strict break enforcement mode',
        keywords: ['break', 'mode', 'strict', 'gentle', 'off', 'enforcement'],
        category: 'Break Screen & Behavior',
        widget: ListTile(
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
      ),
      if (_breakMode == BreakMode.gentle) ...[
        SettingItem(
          title: 'Allow skip',
          subtitle: 'Allow skipping the break early',
          keywords: ['skip', 'break', 'allow', 'gentle'],
          category: 'Break Screen & Behavior',
          widget: SwitchListTile(
            contentPadding: EdgeInsets.zero,
            secondary: const Icon(Icons.skip_next_outlined),
            title: const Text('Allow skip'),
            subtitle: const Text('Allow skipping the break early'),
            value: widget.allowSkip,
            onChanged: widget.setAllowSkip,
          ),
        ),
        SettingItem(
          title: 'Allow postpone',
          subtitle: 'Allow postponing the break',
          keywords: ['postpone', 'break', 'allow', 'gentle', 'delay'],
          category: 'Break Screen & Behavior',
          widget: SwitchListTile(
            contentPadding: EdgeInsets.zero,
            secondary: const Icon(Icons.snooze_outlined),
            title: const Text('Allow postpone'),
            subtitle: const Text('Allow postponing the break'),
            value: widget.allowPostpone,
            onChanged: widget.setAllowPostpone,
          ),
        ),
        SettingItem(
          title: 'Smart Pause & Postpone',
          subtitle: 'Pause on screen-off / system idle; delay breaks for games or videos',
          keywords: ['smart', 'pause', 'postpone', 'idle', 'game', 'video', 'cast', 'dnd'],
          category: 'Break Screen & Behavior',
          widget: SwitchListTile(
            contentPadding: EdgeInsets.zero,
            secondary: const Icon(Icons.psychology_outlined),
            title: const Text('Smart Pause & Postpone'),
            subtitle: const Text('Pause on screen-off / system idle; delay breaks for games or videos'),
            value: widget.smartIdleEnabled,
            onChanged: widget.setSmartIdleEnabled,
          ),
        ),
        SettingItem(
          title: 'Natural break credit',
          subtitle: 'Credit a completed break if you are idle/away for longer than the break duration',
          keywords: ['natural', 'break', 'credit', 'idle', 'away', 'keyboard'],
          category: 'Break Screen & Behavior',
          widget: SwitchListTile(
            contentPadding: EdgeInsets.zero,
            secondary: const Icon(Icons.check_circle_outline),
            title: const Text('Natural break credit'),
            subtitle: const Text('Credit a completed break if you are idle/away for longer than the break duration'),
            value: widget.naturalBreakCreditEnabled,
            onChanged: widget.setNaturalBreakCreditEnabled,
          ),
        ),
        SettingItem(
          title: 'Break visualizer style',
          subtitle: 'Choose ambient effect during breaks',
          keywords: ['visualizer', 'style', 'breathing', 'box', 'exercise', 'blink', 'ambient', 'starry', 'random'],
          category: 'Break Screen & Behavior',
          widget: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.style_outlined),
            title: const Text('Break visualizer style'),
            subtitle: const Text('Choose ambient effect during breaks'),
            trailing: DropdownButton<String>(
              value: widget.breakVisualizerStyle,
              underline: const SizedBox(),
              dropdownColor: theme.cardColor,
              style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
              onChanged: (String? val) {
                if (val != null) widget.setBreakVisualizerStyle(val);
              },
              items: const [
                DropdownMenuItem(value: 'Random', child: Text('Random/All')),
                DropdownMenuItem(value: 'Breathing', child: Text('Calm Breathing')),
                DropdownMenuItem(value: 'BoxBreathing', child: Text('Box Breathing (4-4-4-4)')),
                DropdownMenuItem(value: 'EyeExercise', child: Text('Eye Exercises')),
                DropdownMenuItem(value: 'BlinkTraining', child: Text('Blink Training (Blink Pacing)')),
                DropdownMenuItem(value: 'Ambient', child: Text('Ambient Flow')),
                DropdownMenuItem(value: 'Starry', child: Text('Starry Sky')),
              ],
            ),
          ),
        ),
        if (widget.allowPostpone)
          SettingItem(
            title: 'Postpone duration',
            subtitle: 'How long to delay the break',
            keywords: ['postpone', 'duration', 'minutes', 'delay'],
            category: 'Break Screen & Behavior',
            widget: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.timer_outlined),
              title: const Text('Postpone duration'),
              subtitle: const Text('How long to delay the break'),
              trailing: DropdownButton<int>(
                value: widget.postponeDurationSeconds,
                underline: const SizedBox(),
                items: _postponeDurations.map(
                  (seconds) => DropdownMenuItem<int>(
                    value: seconds,
                    child: Text('${seconds ~/ 60} min'),
                  ),
                ).toList(),
                onChanged: (value) {
                  if (value != null) widget.setPostponeDurationSeconds(value);
                },
              ),
            ),
          ),
      ],
      if (_overlayPermissionStatus != OverlayPermissionStatus.unsupported) ...[
        SettingItem(
          title: 'Display over other apps',
          subtitle: _overlayPermissionLabel(),
          keywords: ['display', 'permission', 'overlay', 'allow'],
          category: 'Break Screen & Behavior',
          widget: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              _overlayPermissionStatus == OverlayPermissionStatus.allowed
                  ? Icons.layers_outlined
                  : Icons.layers_clear_outlined,
            ),
            title: const Text('Display over other apps'),
            subtitle: Text(_overlayPermissionLabel()),
            trailing: _overlayPermissionStatus == OverlayPermissionStatus.disabled
                ? TextButton(
                    key: const ValueKey('overlay_allow_button'),
                    onPressed: widget.openOverlayPermissionSettings,
                    child: const Text('Allow'),
                  )
                : null,
          ),
        ),
        SettingItem(
          title: 'Preview break screen',
          subtitle: 'Show a 10-second black overlay',
          keywords: ['preview', 'break', 'screen', 'test'],
          category: 'Break Screen & Behavior',
          widget: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.fullscreen),
            title: const Text('Preview break screen'),
            subtitle: const Text('Show a 10-second black overlay'),
            trailing: IconButton(
              onPressed: _overlayPermissionStatus == OverlayPermissionStatus.allowed ? _showOverlayPreview : null,
              icon: const Icon(Icons.play_arrow),
              tooltip: 'Preview break overlay',
            ),
          ),
        ),
        SettingItem(
          title: 'Test 20s break screen',
          subtitle: 'Launch a real 20-second eye break',
          keywords: ['test', '20s', 'break', 'overlay', 'real'],
          category: 'Break Screen & Behavior',
          widget: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.timer),
            title: const Text('Test 20s break screen'),
            subtitle: const Text('Launch a real 20-second eye break'),
            trailing: IconButton(
              onPressed: _overlayPermissionStatus == OverlayPermissionStatus.allowed ? _showRealBreakTest : null,
              icon: const Icon(Icons.play_arrow),
              tooltip: 'Test real break overlay',
            ),
          ),
        ),
      ],
      if (widget.smartIdleEnabled && _usageAccessStatus != UsageAccessStatus.unsupported)
        SettingItem(
          title: 'Usage access',
          subtitle: _usageAccessStatus == UsageAccessStatus.allowed ? 'App detection enabled' : 'Required to detect games & videos',
          keywords: ['usage', 'access', 'apps', 'detection', 'game', 'video', 'permission'],
          category: 'Break Screen & Behavior',
          widget: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              _usageAccessStatus == UsageAccessStatus.allowed
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              color: _usageAccessStatus == UsageAccessStatus.allowed
                  ? Colors.green
                  : theme.colorScheme.error,
            ),
            title: const Text('Usage access'),
            subtitle: Text(
              _usageAccessStatus == UsageAccessStatus.allowed
                  ? 'App detection enabled'
                  : 'Required to detect games & videos',
            ),
            trailing: _usageAccessStatus != UsageAccessStatus.allowed
                ? TextButton(
                    onPressed: () async {
                      await widget.openUsageAccessSettings();
                      if (!mounted) return;
                      final status = await widget.refreshUsageAccessStatus();
                      setState(() => _usageAccessStatus = status);
                    },
                    child: const Text('Allow'),
                  )
                : null,
          ),
        ),

      // 3. Theme & Appearance
      SettingItem(
        title: 'Dark mode',
        subtitle: 'Toggle dark or light theme interface',
        keywords: ['dark', 'light', 'mode', 'theme', 'appearance'],
        category: 'Theme & Appearance',
        widget: SwitchListTile(
          contentPadding: EdgeInsets.zero,
          secondary: Icon(widget.isDark ? Icons.dark_mode : Icons.light_mode),
          title: const Text('Dark mode'),
          value: widget.isDark,
          onChanged: (_) => widget.toggleTheme(),
        ),
      ),
      if (widget.isDark)
        SettingItem(
          title: 'AMOLED dark mode',
          subtitle: 'Use pure black (#000000) backgrounds for battery saving and higher contrast',
          keywords: ['amoled', 'pure', 'black', 'battery', 'contrast', 'dark'],
          category: 'Theme & Appearance',
          widget: SwitchListTile(
            contentPadding: EdgeInsets.zero,
            secondary: const Icon(Icons.power_settings_new_outlined),
            title: const Text('AMOLED dark mode'),
            subtitle: const Text('Use pure black backgrounds for battery saving'),
            value: widget.amoledDarkEnabled,
            onChanged: widget.setAmoledDarkEnabled,
          ),
        ),
      SettingItem(
        title: 'Use system accent color',
        subtitle: 'Automatically follow Material You / OS system-accent dynamic colors',
        keywords: ['system', 'accent', 'color', 'material you', 'dynamic', 'os'],
        category: 'Theme & Appearance',
        widget: SwitchListTile(
          contentPadding: EdgeInsets.zero,
          secondary: const Icon(Icons.color_lens_outlined),
          title: const Text('Use system accent color'),
          subtitle: const Text('Follow OS system-accent dynamic colors'),
          value: widget.useSystemAccent,
          onChanged: widget.setUseSystemAccent,
        ),
      ),
      if (!widget.useSystemAccent) ...[
        SettingItem(
          title: 'Color preset',
          subtitle: 'Choose your preferred accent color theme preset',
          keywords: ['color', 'preset', 'theme', 'pastel', 'blue', 'green', 'rose', 'graphite', 'sunrise', 'custom'],
          category: 'Theme & Appearance',
          widget: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              const Text(
                'Color Preset',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              ...ColorPresets.names.map(
                (preset) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    radius: 10,
                    backgroundColor: ColorPresets.swatchColor(preset, widget.isDark, customHex: widget.customAccentColorHex),
                  ),
                  title: Text(preset),
                  trailing: preset == widget.colorPreset ? const Icon(Icons.check) : null,
                  onTap: () => widget.setPreset(preset),
                ),
              ),
              if (widget.colorPreset == 'Custom') ...[
                const Divider(),
                const SizedBox(height: 8),
                const Text(
                  'Custom Accent Palette',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    for (final color in [
                      Colors.teal,
                      Colors.blue,
                      Colors.indigo,
                      Colors.purple,
                      Colors.pink,
                      Colors.red,
                      Colors.orange,
                      Colors.amber,
                      Colors.green,
                      Colors.blueGrey,
                    ])
                      GestureDetector(
                        onTap: () {
                          final hex = '#${color.toARGB32().toRadixString(16).substring(2, 8)}';
                          widget.setCustomAccentColorHex(hex);
                        },
                        child: CircleAvatar(
                          radius: 18,
                          backgroundColor: color,
                          child: widget.customAccentColorHex.toLowerCase() ==
                                  '#${color.toARGB32().toRadixString(16).substring(2, 8)}'.toLowerCase()
                              ? const Icon(Icons.check, color: Colors.white, size: 18)
                              : null,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  initialValue: widget.customAccentColorHex,
                  key: ValueKey(widget.customAccentColorHex),
                  decoration: const InputDecoration(
                    labelText: 'Accent Color Hex Code',
                    hintText: '#009688',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  style: theme.textTheme.bodyMedium,
                  onFieldSubmitted: (val) {
                    if (val.startsWith('#') && (val.length == 7 || val.length == 9)) {
                      widget.setCustomAccentColorHex(val);
                    } else if (!val.startsWith('#') && (val.length == 6 || val.length == 8)) {
                      widget.setCustomAccentColorHex('#$val');
                    }
                  },
                ),
              ],
            ],
          ),
        ),
      ],

      // 4. Notifications & Sounds
      SettingItem(
        title: 'Notifications',
        subtitle: 'Remind me when work or break time ends',
        keywords: ['notification', 'reminders', 'alert', 'popups'],
        category: 'Notifications & Sounds',
        widget: SwitchListTile(
          contentPadding: EdgeInsets.zero,
          secondary: const Icon(Icons.notifications_active_outlined),
          title: const Text('Notifications'),
          subtitle: const Text('Remind me when work or break time ends'),
          value: widget.notificationsEnabled,
          onChanged: widget.setNotificationsEnabled,
        ),
      ),
      SettingItem(
        title: 'Notification sound tune',
        subtitle: 'Uses system notification sound settings',
        keywords: ['sound', 'tune', 'chime', 'notification', 'volume'],
        category: 'Notifications & Sounds',
        widget: ListTile(
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
      ),
      SettingItem(
        title: 'Test reminder alert',
        subtitle: 'Play the actual reminder alert sound now',
        keywords: ['test', 'reminder', 'alert', 'play', 'sound', 'vibration'],
        category: 'Notifications & Sounds',
        widget: ListTile(
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
                  onPressed: widget.notificationsEnabled ? _showTestReminder : null,
                  icon: const Icon(Icons.play_arrow),
                  tooltip: 'Send test reminder',
                ),
        ),
      ),
      SettingItem(
        title: 'Permission status info',
        subtitle: _notificationPermissionLabel(),
        keywords: ['permission', 'status', 'blocked', 'allowed', 'system'],
        category: 'Notifications & Sounds',
        widget: Column(
          children: [
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
                padding: EdgeInsets.only(bottom: 8, top: 4),
                child: Text('Timer alerts are off. The countdown still works in the app.'),
              ),
          ],
        ),
      ),
      if (_exactAlarmStatus != ExactAlarmStatus.unsupported)
        SettingItem(
          title: 'Precise reminders permission',
          subtitle: _exactAlarmStatus == ExactAlarmStatus.allowed ? 'Exact timing allowed' : 'May arrive a little late',
          keywords: ['precise', 'reminders', 'exact', 'timing', 'alarm', 'permission'],
          category: 'Notifications & Sounds',
          widget: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              _exactAlarmStatus == ExactAlarmStatus.allowed ? Icons.alarm_on_outlined : Icons.alarm_off_outlined,
            ),
            title: const Text('Precise reminders'),
            subtitle: Text(
              _exactAlarmStatus == ExactAlarmStatus.allowed ? 'Exact timing allowed' : 'May arrive a little late',
            ),
            trailing: _exactAlarmStatus == ExactAlarmStatus.disabled
                ? TextButton(
                    onPressed: _requestExactAlarmPermission,
                    child: const Text('Allow'),
                  )
                : null,
          ),
        ),
      if (_batteryOptimizationStatus != BatteryOptimizationStatus.unsupported)
        SettingItem(
          title: 'Background reliability battery optimization',
          subtitle: _batteryOptimizationStatus == BatteryOptimizationStatus.unrestricted
              ? 'Battery use is unrestricted'
              : 'Battery optimization may delay alerts',
          keywords: ['battery', 'reliability', 'optimization', 'background', 'delay'],
          category: 'Notifications & Sounds',
          widget: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              _batteryOptimizationStatus == BatteryOptimizationStatus.unrestricted
                  ? Icons.battery_saver_outlined
                  : Icons.battery_alert_outlined,
            ),
            title: const Text('Background reliability'),
            subtitle: Text(
              _batteryOptimizationStatus == BatteryOptimizationStatus.unrestricted
                  ? 'Battery use is unrestricted'
                  : 'Battery optimization may delay alerts',
            ),
            trailing: _batteryOptimizationStatus == BatteryOptimizationStatus.restricted
                ? TextButton(
                    onPressed: _openBatteryOptimizationSettings,
                    child: const Text('Review'),
                  )
                : null,
          ),
        ),
      SettingItem(
        title: 'Haptic feedback vibration',
        subtitle: 'Vibrate when a timer phase ends',
        keywords: ['haptics', 'vibration', 'vibrate', 'feedback'],
        category: 'Notifications & Sounds',
        widget: SwitchListTile(
          contentPadding: EdgeInsets.zero,
          secondary: const Icon(Icons.vibration),
          title: const Text('Haptics'),
          subtitle: const Text('Vibrate when a timer phase ends'),
          value: widget.hapticsEnabled,
          onChanged: widget.setHapticsEnabled,
        ),
      ),
      SettingItem(
        title: 'In-app sound alerts',
        subtitle: 'Play an extra alert sound while BlinkKind is open',
        keywords: ['sound', 'alert', 'chime', 'bell', 'zen', 'chimes', 'bowl'],
        category: 'Notifications & Sounds',
        widget: Column(
          children: [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              secondary: const Icon(Icons.volume_up_outlined),
              title: const Text('In-app sound'),
              subtitle: const Text('Play an extra system alert while BlinkKind is open'),
              value: widget.soundEnabled,
              onChanged: widget.setSoundEnabled,
            ),
            if (widget.soundEnabled) ...[
              const Divider(height: 1),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.music_note_outlined),
                title: const Text('Chime style'),
                subtitle: const Text('Sound to play when a break starts or ends'),
                trailing: DropdownButton<String>(
                  value: widget.chimeStyle,
                  items: const [
                    DropdownMenuItem(value: 'tibetan_bowl', child: Text('Tibetan Bowl')),
                    DropdownMenuItem(value: 'wind_chimes', child: Text('Wind Chimes')),
                    DropdownMenuItem(value: 'zen_bell', child: Text('Zen Bell')),
                    DropdownMenuItem(value: 'system_alert', child: Text('System Alert')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      widget.setChimeStyle(value);
                      unawaited(_playChimePreview(value));
                    }
                  },
                ),
              ),
            ],
          ],
        ),
      ),
      SettingItem(
        title: 'Blink nudges (micro-reminders)',
        subtitle: 'Flashes the system tray icon or pulses UI to encourage healthy blinking',
        keywords: ['blink', 'nudges', 'micro-reminders', 'tray', 'flash', 'eye'],
        category: 'Notifications & Sounds',
        widget: Column(
          children: [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              secondary: const Icon(Icons.remove_red_eye_outlined),
              title: const Text('Blink nudges (micro-reminders)'),
              subtitle: const Text('Flashes the system tray icon or pulses UI to encourage healthy blinking'),
              value: widget.blinkRemindersEnabled,
              onChanged: widget.setBlinkRemindersEnabled,
            ),
            if (widget.blinkRemindersEnabled) ...[
              const Divider(height: 1),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.timer_outlined),
                title: const Text('Nudge cadence'),
                subtitle: const Text('Interval between blink reminders'),
                trailing: DropdownButton<int>(
                  value: widget.blinkRemindersCadenceSeconds,
                  items: const [
                    DropdownMenuItem(value: 3, child: Text('Every 3s')),
                    DropdownMenuItem(value: 4, child: Text('Every 4s')),
                    DropdownMenuItem(value: 5, child: Text('Every 5s')),
                    DropdownMenuItem(value: 6, child: Text('Every 6s')),
                    DropdownMenuItem(value: 8, child: Text('Every 8s')),
                    DropdownMenuItem(value: 10, child: Text('Every 10s')),
                  ],
                  onChanged: (value) {
                    if (value != null) widget.setBlinkRemindersCadenceSeconds(value);
                  },
                ),
              ),
            ],
          ],
        ),
      ),

      // 5. Auto Run & Long Breaks
      SettingItem(
        title: 'Run schedule automatically auto run',
        subtitle: 'Continue work and break cycles until stopped or limit is reached',
        keywords: ['auto', 'run', 'autorenew', 'schedule', 'cycles', 'loop'],
        category: 'Auto Run & Long Breaks',
        widget: Column(
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
              onChanged: widget.canChangeDurations ? (enabled) => _saveAutoRun(enabled: enabled) : null,
            ),
            const Divider(height: 1),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.flag_circle_outlined),
              title: const Text('Cycle limit'),
              subtitle: const Text('Completed work cycles in one run'),
              trailing: DropdownButton<int>(
                value: _autoRunCycleLimit,
                items: _autoRunCycleLimits.map(
                  (limit) => DropdownMenuItem<int>(
                    value: limit,
                    child: Text(_cycleLimitLabel(limit)),
                  ),
                ).toList(),
                onChanged: widget.canChangeDurations && _autoRunEnabled
                    ? (value) {
                        if (value != null) _saveAutoRun(cycleLimit: value);
                      }
                    : null,
              ),
            ),
          ],
        ),
      ),
      SettingItem(
        title: 'Long break mode config',
        subtitle: 'Take a longer rest break after a set number of work cycles',
        keywords: ['long', 'break', 'interval', 'rest', 'cycles', 'coffee'],
        category: 'Auto Run & Long Breaks',
        widget: Column(
          children: [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              secondary: const Icon(Icons.coffee_outlined),
              title: const Text('Long break mode'),
              subtitle: Text('After ${widget.longBreakEveryCycles} work cycles, rest for ${_durationLabel(widget.longBreakDurationSeconds)}'),
              value: widget.longBreakEnabled,
              onChanged: (enabled) => _saveLongBreak(enabled: enabled),
            ),
            if (widget.longBreakEnabled) ...[
              const Divider(height: 1),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.repeat),
                title: const Text('Cycle interval'),
                trailing: DropdownButton<int>(
                  value: widget.longBreakEveryCycles,
                  items: _longBreakCycles.map(
                    (cycles) => DropdownMenuItem<int>(
                      value: cycles,
                      child: Text('$cycles cycles'),
                    ),
                  ).toList(),
                  onChanged: widget.longBreakEnabled
                      ? (value) {
                          if (value != null) _saveLongBreak(everyCycles: value);
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
                  items: _longBreakDurationSeconds.map(
                    (seconds) => DropdownMenuItem<int>(
                      value: seconds,
                      child: Text(_durationLabel(seconds)),
                    ),
                  ).toList(),
                  onChanged: widget.longBreakEnabled
                      ? (value) {
                          if (value != null) _saveLongBreak(durationSeconds: value);
                        }
                      : null,
                ),
              ),
            ],
          ],
        ),
      ),

      // 6. Desktop Options
      if (isDesktop)
        SettingItem(
          title: 'Launch at Startup autostart',
          subtitle: 'Start BlinkKind automatically when you log in to your desktop',
          keywords: ['launch', 'startup', 'login', 'autostart', 'boot', 'desktop'],
          category: 'Desktop Options',
          widget: SwitchListTile(
            contentPadding: EdgeInsets.zero,
            secondary: const Icon(Icons.rocket_launch_outlined),
            title: const Text('Launch at Startup'),
            subtitle: const Text('Start BlinkKind automatically when you log in'),
            value: _launchAtStartup,
            onChanged: (value) async {
              await DesktopIntegrationService.instance.setLaunchAtStartup(value);
              final isEnabled = await DesktopIntegrationService.instance.isLaunchAtStartupEnabled();
              setState(() {
                _launchAtStartup = isEnabled;
              });
            },
          ),
        ),

      // 7. AI Motivation & Prompts
      SettingItem(
        title: 'AI Motivation & Prompts',
        subtitle: 'Generate personalised eye-care quotes during breaks',
        keywords: ['ai', 'motivation', 'llm', 'openai', 'groq', 'gemini', 'api', 'key', 'model', 'quote', 'prompt'],
        category: 'AI Motivation & Prompts',
        widget: _buildAiMotivationSettings(theme),
      ),
    ];
  }

  Widget _buildAiMotivationSettings(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          secondary: const Icon(Icons.auto_awesome_outlined),
          title: const Text('Enable AI motivation'),
          subtitle: const Text('Generate personalised quotes during breaks'),
          value: widget.aiMotivationEnabled,
          onChanged: widget.setAiMotivationEnabled,
        ),
        if (widget.aiMotivationEnabled) ...[
          const Divider(height: 1),
          const SizedBox(height: 8),
          // Provider
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.cloud_outlined),
            title: const Text('AI Provider'),
            trailing: DropdownButton<String>(
              value: widget.aiProvider,
              underline: const SizedBox(),
              items: const [
                DropdownMenuItem(value: 'Gemini', child: Text('Google Gemini')),
                DropdownMenuItem(value: 'OpenAI', child: Text('OpenAI (ChatGPT)')),
                DropdownMenuItem(value: 'Groq', child: Text('Groq (Fast)')),
              ],
              onChanged: (val) {
                if (val == null) return;
                widget.setAiProvider(val);
                setState(() {
                  _aiAvailableModels = AiService.instance.getDefaultModels(val);
                  _aiModelsError = null;
                });
                if (widget.aiApiKey.isNotEmpty) {
                  unawaited(_fetchAiModels(widget.aiApiKey, val));
                }
              },
            ),
          ),
          const Divider(height: 1),
          // API Key
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _aiApiKeyController,
                    obscureText: _aiApiKeyObscured,
                    decoration: InputDecoration(
                      labelText: 'API Key',
                      hintText: 'Paste your API key here',
                      border: const OutlineInputBorder(),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      suffixIcon: IconButton(
                        icon: Icon(_aiApiKeyObscured ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                        onPressed: () => setState(() => _aiApiKeyObscured = !_aiApiKeyObscured),
                      ),
                    ),
                    onChanged: (val) {
                      _aiApiKeyDebounce?.cancel();
                      _aiApiKeyDebounce = Timer(const Duration(milliseconds: 800), () {
                        widget.setAiApiKey(val.trim());
                        if (val.trim().isNotEmpty) {
                          unawaited(_fetchAiModels(val.trim(), widget.aiProvider));
                        }
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Model selector
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: _aiLoadingModels
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.memory_outlined),
            title: const Text('Model'),
            subtitle: _aiModelsError != null
                ? Text(_aiModelsError!, style: TextStyle(color: theme.colorScheme.error, fontSize: 12))
                : null,
            trailing: DropdownButton<String>(
              value: _aiAvailableModels.contains(widget.aiModel) ? widget.aiModel : (_aiAvailableModels.isNotEmpty ? _aiAvailableModels.first : null),
              underline: const SizedBox(),
              items: [
                ..._aiAvailableModels.map(
                  (m) => DropdownMenuItem(value: m, child: Text(m, overflow: TextOverflow.ellipsis)),
                ),
                const DropdownMenuItem(value: '__custom__', child: Text('Custom...')),
              ],
              onChanged: (val) {
                if (val == null) return;
                if (val == '__custom__') {
                  _showCustomModelDialog();
                } else {
                  widget.setAiModel(val);
                }
              },
            ),
          ),
          const Divider(height: 1),
          // System prompt
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: TextFormField(
              initialValue: widget.aiCustomSystemPrompt,
              key: ValueKey(widget.aiCustomSystemPrompt.hashCode),
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'System prompt',
                hintText: 'Describe what kind of quote you want...',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              onChanged: (val) => widget.setAiCustomSystemPrompt(val),
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _fetchAiModels(String apiKey, String provider) async {
    if (apiKey.isEmpty) return;
    setState(() {
      _aiLoadingModels = true;
      _aiModelsError = null;
    });
    try {
      final models = await AiService.instance.fetchModels(provider: provider, apiKey: apiKey);
      if (!mounted) return;
      setState(() {
        _aiAvailableModels = models.isNotEmpty ? models : AiService.instance.getDefaultModels(provider);
        _aiLoadingModels = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _aiAvailableModels = AiService.instance.getDefaultModels(provider);
        _aiLoadingModels = false;
        _aiModelsError = 'Could not load models. Using defaults.';
      });
    }
  }

  void _showCustomModelDialog() {
    _aiModelCustomController.text = widget.aiModel;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Custom model'),
        content: TextField(
          controller: _aiModelCustomController,
          decoration: const InputDecoration(
            labelText: 'Model name',
            hintText: 'e.g. gpt-4o, gemini-2.0-flash',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final val = _aiModelCustomController.text.trim();
              if (val.isNotEmpty) widget.setAiModel(val);
              Navigator.of(ctx).pop();
            },
            child: const Text('Set'),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    final items = _allSettingItems(context);
    final filtered = items.where((item) {
      final text = '${item.title} ${item.subtitle ?? ''} ${item.category} ${item.keywords.join(' ')}'.toLowerCase();
      return text.contains(_searchQuery);
    }).toList();

    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'No settings matching "$_searchQuery"',
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final item = filtered[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    item.category,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                item.widget,
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCollapsibleGroups() {
    final items = _allSettingItems(context);
    final Map<String, List<Widget>> groups = {};
    for (final item in items) {
      groups.putIfAbsent(item.category, () => []).add(item.widget);
    }

    final categories = [
      'General Schedule',
      'Break Screen & Behavior',
      'Theme & Appearance',
      'Notifications & Sounds',
      'Auto Run & Long Breaks',
      if (groups.containsKey('Desktop Options')) 'Desktop Options',
      'AI Motivation & Prompts',
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        final list = groups[category] ?? [];

        final children = <Widget>[];
        for (int i = 0; i < list.length; i++) {
          children.add(list[i]);
          if (i < list.length - 1) {
            children.add(const Divider(height: 1));
          }
        }

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              title: Text(
                category,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              leading: Icon(_categoryIcon(category)),
              childrenPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: children,
            ),
          ),
        );
      },
    );
  }

  IconData _categoryIcon(String category) {
    switch (category) {
      case 'General Schedule': return Icons.calendar_today;
      case 'Break Screen & Behavior': return Icons.visibility;
      case 'Theme & Appearance': return Icons.color_lens;
      case 'Notifications & Sounds': return Icons.notifications_active;
      case 'Auto Run & Long Breaks': return Icons.repeat;
      case 'Desktop Options': return Icons.desktop_windows;
      case 'AI Motivation & Prompts': return Icons.auto_awesome;
      default: return Icons.settings;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search settings...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
              onChanged: (val) {
                setState(() {
                  _searchQuery = val.trim().toLowerCase();
                });
              },
            ),
          ),
          Expanded(
            child: _searchQuery.isNotEmpty
                ? _buildSearchResults()
                : _buildCollapsibleGroups(),
          ),
        ],
      ),
    );
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

class SettingItem {
  final String title;
  final String? subtitle;
  final List<String> keywords;
  final Widget widget;
  final String category;

  SettingItem({
    required this.title,
    this.subtitle,
    required this.keywords,
    required this.widget,
    required this.category,
  });
}
