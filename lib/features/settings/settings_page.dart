import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:file_picker/file_picker.dart';

import '../../models/timer_settings.dart';
import '../../services/ai_service.dart';
import '../../services/break_overlay_service.dart';
import '../../services/desktop_integration_service.dart';
import '../../services/notification_service.dart';
import '../../services/permissions_service.dart';
import '../../theme/color_presets.dart';
import '../../generated/l10n/app_localizations.dart';

class SettingsPage extends StatefulWidget {
  final bool isDark;
  final String colorPreset;
  final int workDurationSeconds;
  final int breakDurationSeconds;
  final int streakCount;
  final int dailyGoal;
  final bool allowSkip;
  final int maxConsecutiveSkips;
  final bool allowPostpone;
  final int postponeDurationSeconds;
  final bool smartIdleEnabled;
  final String breakVisualizerStyle;
  final bool breakShowClock;
  final bool breakShowTips;
  final bool breakShowProgress;
  final String breakCustomMessage;
  final void Function(bool) setAllowSkip;
  final void Function(int) setMaxConsecutiveSkips;
  final void Function(bool) setAllowPostpone;
  final void Function(int) setPostponeDurationSeconds;
  final void Function(bool) setSmartIdleEnabled;
  final void Function(String) setBreakVisualizerStyle;
  final void Function(bool) setBreakShowClock;
  final void Function(bool) setBreakShowTips;
  final void Function(bool) setBreakShowProgress;
  final void Function(String) setBreakCustomMessage;
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
  final bool trayBlinkNudgesEnabled;
  final int trayBlinkNudgeCadenceSeconds;
  final void Function(bool) setTrayBlinkNudgesEnabled;
  final void Function(int) setTrayBlinkNudgeCadenceSeconds;
  final bool blinkReminderAiEnabled;
  final String blinkReminderCustomMessage;
  final bool cameraMicAutoPostponeEnabled;
  final bool autoPauseOnMediaEnabled;
  final bool wellnessRemindersEnabled;
  final int wellnessReminderCadenceSeconds;
  final bool blinkReminderInteractiveEnabled;
  final void Function(bool) setBlinkReminderInteractiveEnabled;
  final void Function(bool) setCameraMicAutoPostponeEnabled;
  final void Function(bool) setAutoPauseOnMediaEnabled;
  final void Function(bool) setWellnessRemindersEnabled;
  final void Function(int) setWellnessReminderCadenceSeconds;
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
  final Future<bool> Function() showRealBreakTest;
  final Future<OverlayPermissionStatus> Function()
  refreshOverlayPermissionStatus;
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
  final bool startMinimized;
  final void Function(bool) setStartMinimized;
  final bool autoStartSchedule;
  final void Function(bool) setAutoStartSchedule;

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

  final bool osFocusDndEnabled;
  final void Function(bool) setOsFocusDndEnabled;
  final VoidCallback restoreDefaultSettings;
  final Future<void> Function(TimerSettings) importSettings;

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
    required this.maxConsecutiveSkips,
    required this.setMaxConsecutiveSkips,
    required this.allowPostpone,
    required this.postponeDurationSeconds,
    required this.smartIdleEnabled,
    required this.breakVisualizerStyle,
    required this.breakShowClock,
    required this.breakShowTips,
    required this.breakShowProgress,
    required this.breakCustomMessage,
    required this.setAllowSkip,
    required this.setAllowPostpone,
    required this.setPostponeDurationSeconds,
    required this.setSmartIdleEnabled,
    required this.setBreakVisualizerStyle,
    required this.setBreakShowClock,
    required this.setBreakShowTips,
    required this.setBreakShowProgress,
    required this.setBreakCustomMessage,
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
    required this.trayBlinkNudgesEnabled,
    required this.trayBlinkNudgeCadenceSeconds,
    required this.setTrayBlinkNudgesEnabled,
    required this.setTrayBlinkNudgeCadenceSeconds,
    required this.blinkReminderAiEnabled,
    required this.blinkReminderCustomMessage,
    required this.cameraMicAutoPostponeEnabled,
    required this.autoPauseOnMediaEnabled,
    required this.wellnessRemindersEnabled,
    required this.wellnessReminderCadenceSeconds,
    required this.blinkReminderInteractiveEnabled,
    required this.setBlinkReminderInteractiveEnabled,
    required this.setCameraMicAutoPostponeEnabled,
    required this.setAutoPauseOnMediaEnabled,
    required this.setWellnessRemindersEnabled,
    required this.setWellnessReminderCadenceSeconds,
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
    required this.startMinimized,
    required this.setStartMinimized,
    required this.autoStartSchedule,
    required this.setAutoStartSchedule,

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
    required this.osFocusDndEnabled,
    required this.setOsFocusDndEnabled,
    required this.restoreDefaultSettings,
    required this.importSettings,
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

  // Snap a stored cadence value (possibly old seconds-based) to the nearest
  // valid minute-based dropdown option.
  static int _nearestBlinkCadence(int seconds) {
    const valid = [2, 3, 5, 10, 15, 20, 30, 60, 120, 300, 600, 900];
    if (valid.contains(seconds)) return seconds;
    return valid.reduce(
      (a, b) => (a - seconds).abs() < (b - seconds).abs() ? a : b,
    );
  }

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
  final TextEditingController _aiModelCustomController =
      TextEditingController();
  final TextEditingController _dailyGoalCustomController =
      TextEditingController();
  Timer? _aiApiKeyDebounce;

  String _searchQuery = '';
  final _searchController = TextEditingController();
  AudioPlayer? _audioPlayer;
  Process? _activeChimeProcess;
  String? _playingChimeStyle;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _audioPlayer = AudioPlayer();
    _audioPlayer?.onPlayerComplete.listen((_) {
      if (mounted) {
        setState(() {
          _playingChimeStyle = null;
        });
      }
    });
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
    _searchController.dispose();
    _activeChimeProcess?.kill();
    _audioPlayer?.dispose();
    _aiApiKeyController.dispose();
    _aiModelCustomController.dispose();
    _dailyGoalCustomController.dispose();
    _aiApiKeyDebounce?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _playChimePreview(String style) async {
    setState(() {
      _playingChimeStyle = style;
    });
    if (style == 'system_alert') {
      await SystemSound.play(SystemSoundType.alert);
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted && _playingChimeStyle == 'system_alert') {
          setState(() {
            _playingChimeStyle = null;
          });
        }
      });
    } else {
      if (!kIsWeb && Platform.isLinux) {
        try {
          _activeChimeProcess?.kill();
          _activeChimeProcess = null;

          final byteData = await rootBundle.load('assets/sounds/$style.wav');
          final tempDir = Directory.systemTemp;
          final file = File('${tempDir.path}/blinkkind_sounds/$style.wav');
          if (!await file.exists()) {
            await file.create(recursive: true);
            await file.writeAsBytes(byteData.buffer.asUint8List(), flush: true);
          }

          bool played = false;
          final audioUtils = ['pw-play', 'paplay', 'aplay'];
          for (final util in audioUtils) {
            try {
              final process = await Process.start(util, [file.path]);
              _activeChimeProcess = process;
              played = true;
              unawaited(process.exitCode.then((code) {
                if (_activeChimeProcess == process) {
                  _activeChimeProcess = null;
                }
                if (mounted && _playingChimeStyle == style) {
                  setState(() {
                    _playingChimeStyle = null;
                  });
                }
              }));
              break;
            } catch (_) {}
          }
          if (played) return;
        } catch (e) {
          debugPrint('Error playing Linux chime preview: $e');
        }
      }
      try {
        await _audioPlayer?.stop();
        await _audioPlayer?.play(AssetSource('sounds/$style.wav'));
      } catch (e) {
        await SystemSound.play(SystemSoundType.alert);
        setState(() {
          _playingChimeStyle = null;
        });
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
      SnackBar(
        duration: const Duration(seconds: 4),
        content: const Text('Allow display over other apps first.'),
        action: SnackBarAction(
          label: 'OK',
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  Future<void> _showRealBreakTest() async {
    final shown = await widget.showRealBreakTest();
    if (!mounted || shown) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 4),
        content: const Text('Allow display over other apps first.'),
        action: SnackBarAction(
          label: 'OK',
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  Future<void> _showTestReminder() async {
    setState(() => _isTestingReminder = true);
    final shown = await widget.showTestReminder();
    if (!mounted) return;
    setState(() => _isTestingReminder = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 4),
        content: Text(
          shown
              ? 'Test reminder sent. Check sound and vibration.'
              : 'Test failed. Allow notifications and try again.',
        ),
        action: SnackBarAction(
          label: 'OK',
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
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
    final l10n = AppLocalizations.of(context)!;
    if (seconds < 60) return l10n.settingsDurationSeconds(seconds);
    final minutes = seconds ~/ 60;
    return l10n.settingsDurationMinutes(minutes);
  }

  String _getDayNameShort(int day) {
    final l10n = AppLocalizations.of(context)!;
    switch (day) {
      case 1:
        return l10n.mon;
      case 2:
        return l10n.tue;
      case 3:
        return l10n.wed;
      case 4:
        return l10n.thu;
      case 5:
        return l10n.fri;
      case 6:
        return l10n.sat;
      case 7:
        return l10n.sun;
      default:
        return '';
    }
  }

  String _notificationPermissionLabel() {
    final l10n = AppLocalizations.of(context)!;
    return switch (_permissionStatus) {
      NotificationPermissionStatus.allowed => l10n.settingsPermissionAllowed,
      NotificationPermissionStatus.disabled => l10n.settingsPermissionBlocked,
      NotificationPermissionStatus.unsupported =>
        l10n.settingsPermissionUnavailable,
      NotificationPermissionStatus.unknown => l10n.settingsPermissionChecking,
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
      NotificationPermissionStatus.disabled => Theme.of(
        context,
      ).colorScheme.error,
      NotificationPermissionStatus.unsupported => null,
      NotificationPermissionStatus.unknown => null,
    };
  }

  String _overlayPermissionLabel() {
    final l10n = AppLocalizations.of(context)!;
    return switch (_overlayPermissionStatus) {
      OverlayPermissionStatus.allowed => l10n.settingsOverlayAllowed,
      OverlayPermissionStatus.disabled => l10n.settingsOverlayRequired,
      OverlayPermissionStatus.unknown => l10n.settingsOverlayChecking,
      OverlayPermissionStatus.unsupported => l10n.settingsOverlayUnavailable,
    };
  }

  String _breakModeLabel(BreakMode mode) {
    final l10n = AppLocalizations.of(context)!;
    return switch (mode) {
      BreakMode.off => l10n.settingsBreakModeOff,
      BreakMode.gentle => l10n.settingsBreakModeGentle,
      BreakMode.strict => l10n.settingsBreakModeStrict,
    };
  }

  List<SettingItem> _allSettingItems(BuildContext context) {
    final theme = Theme.of(context);
    final isDesktop = DesktopIntegrationService.instance.isSupported;
    final l10n = AppLocalizations.of(context)!;

    return [
      // 1. General Schedule
      SettingItem(
        title: l10n.settingsQuickPresets,
        subtitle: l10n.settingsQuickPresetsSubtitle,
        keywords: [
          'preset',
          '20-20-20',
          'quick',
          'duration',
          'time',
          '25',
          '45',
          '10',
        ],
        category: 'General Schedule',
        widget: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Wrap(
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
                label: '10s / 10s (Test)',
                selected:
                    widget.workDurationSeconds == 10 &&
                    widget.breakDurationSeconds == 10,
                enabled: widget.canChangeDurations,
                onSelected: () => _applyPreset(10, 10),
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
        ),
      ),
      SettingItem(
        title: l10n.settingsWorkDuration,
        subtitle: widget.canChangeDurations
            ? l10n.settingsWorkDurationChoose
            : l10n.settingsPauseCancelToChange,
        keywords: ['work', 'duration', 'minutes', 'time'],
        category: 'General Schedule',
        widget: ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.work_outline),
          title: Text(l10n.settingsWorkDuration),
          subtitle: widget.canChangeDurations
              ? null
              : Text(l10n.settingsPauseCancelToChangeDesc),
          trailing: DropdownButton<int>(
            value: widget.workDurationSeconds < 60
                ? 0
                : widget.workDurationSeconds ~/ 60,
            items: [
              if (widget.workDurationSeconds < 60)
                DropdownMenuItem<int>(
                  value: 0,
                  child: Text(
                    l10n.settingsDurationSeconds(widget.workDurationSeconds),
                  ),
                ),
              ..._workDurationMinutes.map(
                (minutes) => DropdownMenuItem<int>(
                  value: minutes,
                  child: Text(l10n.settingsDurationMinutes(minutes)),
                ),
              ),
            ],
            onChanged: widget.canChangeDurations
                ? (value) {
                    if (value == null) return;
                    final nextSeconds = value == 0
                        ? widget.workDurationSeconds
                        : value * 60;
                    widget.saveDurations(
                      nextSeconds,
                      widget.breakDurationSeconds,
                    );
                  }
                : null,
          ),
        ),
      ),
      SettingItem(
        title: l10n.settingsBreakDuration,
        subtitle: widget.canChangeDurations
            ? l10n.settingsBreakDurationChoose
            : l10n.settingsPauseCancelToChange,
        keywords: ['break', 'duration', 'seconds', 'time'],
        category: 'General Schedule',
        widget: ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.visibility_outlined),
          title: Text(l10n.settingsBreakDuration),
          subtitle: widget.canChangeDurations
              ? null
              : Text(l10n.settingsPauseCancelToChangeDesc),
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
        title: l10n.settingsDailyGoal,
        subtitle: l10n.settingsDailyGoalProgress(
          widget.streakCount,
          widget.dailyGoal,
        ),
        keywords: ['daily', 'goal', 'streak', 'target', 'breaks'],
        category: 'General Schedule',
        widget: ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.flag_outlined),
          title: Text(l10n.settingsDailyGoal),
          subtitle: Text(
            l10n.settingsDailyGoalProgress(
              widget.streakCount,
              widget.dailyGoal,
            ),
          ),
          trailing: DropdownButton<int>(
            value: widget.dailyGoal,
            items: [
              ..._dailyGoals.map(
                (goal) =>
                    DropdownMenuItem<int>(value: goal, child: Text('$goal')),
              ),
              DropdownMenuItem<int>(
                value: -1,
                child: Text(l10n.settingsCustom),
              ),
              if (!_dailyGoals.contains(widget.dailyGoal))
                DropdownMenuItem<int>(
                  value: widget.dailyGoal,
                  child: Text('${widget.dailyGoal}'),
                ),
            ],
            onChanged: (value) {
              if (value == null) return;
              if (value == -1) {
                _showCustomDailyGoalDialog();
              } else {
                widget.setDailyGoal(value);
              }
            },
          ),
        ),
      ),
      SettingItem(
        title: l10n.settingsHistory,
        subtitle: l10n.settingsHistorySubtitle,
        keywords: [
          'history',
          'recent',
          'breaks',
          'insights',
          'statistics',
          'csv',
          'json',
        ],
        category: 'General Schedule',
        widget: ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.history),
          title: Text(l10n.settingsHistory),
          subtitle: Text(l10n.settingsHistorySubtitle),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => widget.openHistory(context),
        ),
      ),
      SettingItem(
        title: l10n.settingsTodayProgressTitle,
        subtitle: l10n.settingsResetStreak,
        keywords: ['streak', 'today', 'progress', 'reset'],
        category: 'General Schedule',
        widget: ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.local_fire_department_outlined),
          title: Text(l10n.settingsTodayProgress(widget.streakCount)),
          trailing: TextButton(
            onPressed: widget.streakCount == 0 ? null : widget.resetStreak,
            child: Text(l10n.settingsReset),
          ),
        ),
      ),
      SettingItem(
        title: l10n.settingsActiveWorkHours,
        subtitle: l10n.settingsActiveWorkHoursSubtitle,
        keywords: [
          'schedule',
          'work',
          'hours',
          'days',
          'time',
          'start',
          'end',
          'calendar',
        ],
        category: 'General Schedule',
        widget: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              secondary: const Icon(Icons.calendar_today_outlined),
              title: Text(l10n.settingsActiveWorkHours),
              subtitle: Text(l10n.settingsActiveWorkHoursSubtitle),
              value: widget.workHoursEnabled,
              onChanged: widget.setWorkHoursEnabled,
            ),
            if (widget.workHoursEnabled) ...[
              const Divider(height: 1),
              const SizedBox(height: 8),
              Text(
                l10n.settingsActiveDays,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
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
                  Text(
                    l10n.settingsStartTime,
                    style: const TextStyle(fontSize: 15),
                  ),
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
                  Text(
                    l10n.settingsEndTime,
                    style: const TextStyle(fontSize: 15),
                  ),
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
      SettingItem(
        title: l10n.settingsAutoStartSchedule,
        subtitle: l10n.settingsAutoStartScheduleSubtitle,
        keywords: ['auto', 'start', 'schedule', 'launch', 'run', 'boot'],
        category: 'General Schedule',
        widget: SwitchListTile(
          contentPadding: EdgeInsets.zero,
          secondary: const Icon(Icons.play_circle_outline),
          title: Text(l10n.settingsAutoStartSchedule),
          subtitle: Text(l10n.settingsAutoStartScheduleSubtitle),
          value: widget.autoStartSchedule,
          onChanged: widget.setAutoStartSchedule,
        ),
      ),
      SettingItem(
        title: l10n.settingsOsFocusMode,
        subtitle: l10n.settingsOsFocusModeSubtitle,
        keywords: [
          'focus',
          'dnd',
          'do not disturb',
          'os',
          'notification',
          'quiet',
          'system',
        ],
        category: 'General Schedule',
        widget: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              secondary: const Icon(Icons.do_not_disturb_on),
              title: Text(l10n.settingsOsFocusMode),
              subtitle: Text(l10n.settingsOsFocusModeToggle),
              value: widget.osFocusDndEnabled,
              onChanged: widget.setOsFocusDndEnabled,
            ),
            if (widget.osFocusDndEnabled)
              Padding(
                padding: const EdgeInsets.only(
                  left: 48.0,
                  top: 4.0,
                  bottom: 8.0,
                ),
                child: Text(
                  l10n.settingsOsFocusModeGnomeNote,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.textTheme.bodySmall?.color?.withValues(
                      alpha: 0.7,
                    ),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
          ],
        ),
      ),

      // 2. Break Screen & Behavior
      SettingItem(
        title: l10n.settingsBreakScreenMode,
        subtitle: l10n.settingsBreakScreenModeSubtitle,
        keywords: ['break', 'mode', 'strict', 'gentle', 'off', 'enforcement'],
        category: 'Break Screen & Behavior',
        widget: ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.security_outlined),
          title: Text(l10n.settingsBreakScreenMode),
          subtitle: Text(l10n.settingsStrictBlocksExit),
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
          title: l10n.settingsAllowSkip,
          subtitle: l10n.settingsAllowSkipSubtitle,
          keywords: ['skip', 'break', 'allow', 'gentle'],
          category: 'Break Screen & Behavior',
          widget: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                secondary: const Icon(Icons.skip_next_outlined),
                title: Text(l10n.settingsAllowSkip),
                subtitle: Text(l10n.settingsAllowSkipSubtitle),
                value: widget.allowSkip,
                onChanged: widget.setAllowSkip,
              ),
              if (widget.allowSkip) ...[
                Padding(
                  padding: const EdgeInsets.only(left: 40.0, top: 4.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          "Max consecutive skips",
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.8),
                          ),
                        ),
                      ),
                      DropdownButton<int>(
                        value: widget.maxConsecutiveSkips,
                        underline: const SizedBox(),
                        items: const [
                          DropdownMenuItem(
                            value: 0,
                            child: Text("No Limit"),
                          ),
                          DropdownMenuItem(
                            value: 1,
                            child: Text("1 skip"),
                          ),
                          DropdownMenuItem(
                            value: 2,
                            child: Text("2 skips"),
                          ),
                          DropdownMenuItem(
                            value: 3,
                            child: Text("3 skips"),
                          ),
                          DropdownMenuItem(
                            value: 5,
                            child: Text("5 skips"),
                          ),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            widget.setMaxConsecutiveSkips(val);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        SettingItem(
          title: l10n.settingsAllowPostpone,
          subtitle: l10n.settingsAllowPostponeSubtitle,
          keywords: ['postpone', 'break', 'allow', 'gentle', 'delay'],
          category: 'Break Screen & Behavior',
          widget: SwitchListTile(
            contentPadding: EdgeInsets.zero,
            secondary: const Icon(Icons.snooze_outlined),
            title: Text(l10n.settingsAllowPostpone),
            subtitle: Text(l10n.settingsAllowPostponeSubtitle),
            value: widget.allowPostpone,
            onChanged: widget.setAllowPostpone,
          ),
        ),
        SettingItem(
          title: l10n.settingsSmartPausePostpone,
          subtitle: l10n.settingsSmartPausePostponeSubtitle,
          keywords: [
            'smart',
            'pause',
            'postpone',
            'idle',
            'game',
            'video',
            'cast',
            'dnd',
          ],
          category: 'Break Screen & Behavior',
          widget: SwitchListTile(
            contentPadding: EdgeInsets.zero,
            secondary: const Icon(Icons.psychology_outlined),
            title: Text(l10n.settingsSmartPausePostpone),
            subtitle: Text(l10n.settingsSmartPausePostponeSubtitle),
            value: widget.smartIdleEnabled,
            onChanged: widget.setSmartIdleEnabled,
          ),
        ),
        SettingItem(
          title: l10n.settingsCameraMicAutoPostpone,
          subtitle: l10n.settingsCameraMicAutoPostponeSubtitle,
          keywords: [
            'camera',
            'mic',
            'microphone',
            'video',
            'call',
            'meeting',
            'zoom',
            'teams',
            'postpone',
          ],
          category: 'Break Screen & Behavior',
          widget: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                secondary: const Icon(Icons.videocam_outlined),
                title: Text(l10n.settingsCameraMicAutoPostpone),
                subtitle: Text(l10n.settingsCameraMicAutoPostponeSubtitle),
                value: widget.cameraMicAutoPostponeEnabled,
                onChanged: widget.setCameraMicAutoPostponeEnabled,
              ),
              if (widget.cameraMicAutoPostponeEnabled)
                Padding(
                  padding: const EdgeInsets.only(left: 48.0, top: 4.0, bottom: 8.0),
                  child: Text(
                    l10n.settingsCameraMicAutoPostponeDesc,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
            ],
          ),
        ),
        SettingItem(
          title: l10n.settingsAutoPauseOnMedia,
          subtitle: l10n.settingsAutoPauseOnMediaSubtitle,
          keywords: ['media', 'music', 'video', 'audio', 'pause', 'playback', 'background'],
          category: 'Break Screen & Behavior',
          widget: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                secondary: const Icon(Icons.music_note_outlined),
                title: Text(l10n.settingsAutoPauseOnMedia),
                subtitle: Text(l10n.settingsAutoPauseOnMediaSubtitle),
                value: widget.autoPauseOnMediaEnabled,
                onChanged: widget.setAutoPauseOnMediaEnabled,
              ),
              if (widget.autoPauseOnMediaEnabled)
                Padding(
                  padding: const EdgeInsets.only(left: 48.0, top: 4.0, bottom: 8.0),
                  child: Text(
                    l10n.settingsAutoPauseOnMediaDesc,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
            ],
          ),
        ),
        SettingItem(
          title: l10n.settingsNaturalBreakCredit,
          subtitle: l10n.settingsNaturalBreakCreditSubtitle,
          keywords: ['natural', 'break', 'credit', 'idle', 'away', 'keyboard'],
          category: 'Break Screen & Behavior',
          widget: SwitchListTile(
            contentPadding: EdgeInsets.zero,
            secondary: const Icon(Icons.check_circle_outline),
            title: Text(l10n.settingsNaturalBreakCredit),
            subtitle: Text(l10n.settingsNaturalBreakCreditSubtitle),
            value: widget.naturalBreakCreditEnabled,
            onChanged: widget.setNaturalBreakCreditEnabled,
          ),
        ),
        SettingItem(
          title: l10n.settingsBreakVisualizerStyle,
          subtitle: l10n.settingsBreakVisualizerStyleSubtitle,
          keywords: [
            'visualizer',
            'style',
            'breathing',
            'box',
            'exercise',
            'blink',
            'ambient',
            'starry',
            'random',
          ],
          category: 'Break Screen & Behavior',
          widget: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.style_outlined),
            title: Text(l10n.settingsBreakVisualizerStyle),
            subtitle: Text(l10n.settingsBreakVisualizerStyleSubtitle),
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
              items: [
                DropdownMenuItem(
                  value: 'Random',
                  child: Text(l10n.settingsVisualizerRandom),
                ),
                DropdownMenuItem(
                  value: 'Breathing',
                  child: Text(l10n.settingsVisualizerBreathing),
                ),
                DropdownMenuItem(
                  value: 'BoxBreathing',
                  child: Text(l10n.settingsVisualizerBoxBreathing),
                ),
                DropdownMenuItem(
                  value: 'EyeExercise',
                  child: Text(l10n.settingsVisualizerEyeExercise),
                ),
                DropdownMenuItem(
                  value: 'BlinkTraining',
                  child: Text(l10n.settingsVisualizerBlinkTraining),
                ),
                DropdownMenuItem(
                  value: 'Ambient',
                  child: Text(l10n.settingsVisualizerAmbient),
                ),
                DropdownMenuItem(
                  value: 'Starry',
                  child: Text(l10n.settingsVisualizerStarry),
                ),
              ],
            ),
          ),
        ),
        SettingItem(
          title: l10n.settingsBreakScreenContent,
          subtitle: l10n.settingsBreakScreenContentSubtitle,
          keywords: ['break', 'screen', 'content', 'clock', 'tips', 'progress'],
          category: 'Break Screen & Behavior',
          widget: Column(
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                secondary: const Icon(Icons.schedule_outlined),
                title: Text(l10n.settingsShowCountdown),
                subtitle: Text(l10n.settingsShowCountdownDesc),
                value: widget.breakShowClock,
                onChanged: widget.setBreakShowClock,
              ),
              const Divider(height: 1),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                secondary: const Icon(Icons.lightbulb_outline),
                title: Text(l10n.settingsShowTips),
                subtitle: Text(l10n.settingsShowTipsDesc),
                value: widget.breakShowTips,
                onChanged: widget.setBreakShowTips,
              ),
              const Divider(height: 1),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                secondary: const Icon(Icons.donut_large_outlined),
                title: Text(l10n.settingsShowProgress),
                subtitle: Text(l10n.settingsShowProgressDesc),
                value: widget.breakShowProgress,
                onChanged: widget.setBreakShowProgress,
              ),
            ],
          ),
        ),
        SettingItem(
          title: l10n.settingsCustomBreakMessage,
          subtitle: l10n.settingsCustomBreakMessageSubtitle,
          keywords: ['custom', 'message', 'quote', 'break', 'text'],
          category: 'Break Screen & Behavior',
          widget: TextFormField(
            initialValue: widget.breakCustomMessage,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.edit_note_outlined),
              labelText: l10n.settingsCustomBreakMessage,
              hintText: l10n.settingsCustomBreakMessageHint,
              border: const OutlineInputBorder(),
            ),
            maxLength: 120,
            minLines: 1,
            maxLines: 3,
            onChanged: widget.setBreakCustomMessage,
          ),
        ),
        if (widget.allowPostpone)
          SettingItem(
            title: l10n.settingsPostponeDuration,
            subtitle: l10n.settingsPostponeDurationSubtitle,
            keywords: ['postpone', 'duration', 'minutes', 'delay'],
            category: 'Break Screen & Behavior',
            widget: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.timer_outlined),
              title: Text(l10n.settingsPostponeDuration),
              subtitle: Text(l10n.settingsPostponeDurationSubtitle),
              trailing: DropdownButton<int>(
                value: widget.postponeDurationSeconds,
                underline: const SizedBox(),
                items: _postponeDurations
                    .map(
                      (seconds) => DropdownMenuItem<int>(
                        value: seconds,
                        child: Text(
                          l10n.settingsDurationMinutes(seconds ~/ 60),
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) widget.setPostponeDurationSeconds(value);
                },
              ),
            ),
          ),
      ],
      if (_overlayPermissionStatus != OverlayPermissionStatus.unsupported) ...[
        SettingItem(
          title: l10n.settingsDisplayOverApps,
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
            title: Text(l10n.settingsDisplayOverApps),
            subtitle: Text(_overlayPermissionLabel()),
            trailing:
                _overlayPermissionStatus == OverlayPermissionStatus.disabled
                ? TextButton(
                    key: const ValueKey('overlay_allow_button'),
                    onPressed: widget.openOverlayPermissionSettings,
                    child: Text(l10n.settingsAllow),
                  )
                : null,
          ),
        ),
      ],
      SettingItem(
        title: l10n.settingsPreviewBreakScreen,
        subtitle: l10n.settingsPreviewBreakScreenSubtitle,
        keywords: ['preview', 'break', 'screen', 'test'],
        category: 'Break Screen & Behavior',
        widget: ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.fullscreen),
          title: Text(l10n.settingsPreviewBreakScreen),
          subtitle: Text(l10n.settingsPreviewBreakScreenSubtitle),
          trailing: IconButton(
            onPressed:
                (_overlayPermissionStatus == OverlayPermissionStatus.allowed ||
                    _overlayPermissionStatus ==
                        OverlayPermissionStatus.unsupported)
                ? _showOverlayPreview
                : null,
            icon: const Icon(Icons.play_arrow),
            tooltip: 'Preview break overlay',
          ),
        ),
      ),
      SettingItem(
        title: l10n.settingsTest20sBreak,
        subtitle: l10n.settingsTest20sBreakSubtitle,
        keywords: ['test', '20s', 'break', 'overlay', 'real'],
        category: 'Break Screen & Behavior',
        widget: ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.timer),
          title: Text(l10n.settingsTest20sBreak),
          subtitle: Text(l10n.settingsTest20sBreakSubtitle),
          trailing: IconButton(
            onPressed:
                (_overlayPermissionStatus == OverlayPermissionStatus.allowed ||
                    _overlayPermissionStatus ==
                        OverlayPermissionStatus.unsupported)
                ? _showRealBreakTest
                : null,
            icon: const Icon(Icons.play_arrow),
            tooltip: 'Test real break overlay',
          ),
        ),
      ),
      if (widget.smartIdleEnabled &&
          _usageAccessStatus != UsageAccessStatus.unsupported)
        SettingItem(
          title: l10n.settingsUsageAccess,
          subtitle: _usageAccessStatus == UsageAccessStatus.allowed
              ? l10n.settingsUsageAccessEnabled
              : l10n.settingsUsageAccessRequired,
          keywords: [
            'usage',
            'access',
            'apps',
            'detection',
            'game',
            'video',
            'permission',
          ],
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
            title: Text(l10n.settingsUsageAccess),
            subtitle: Text(
              _usageAccessStatus == UsageAccessStatus.allowed
                  ? l10n.settingsUsageAccessEnabled
                  : l10n.settingsUsageAccessRequired,
            ),
            trailing: _usageAccessStatus != UsageAccessStatus.allowed
                ? TextButton(
                    onPressed: () async {
                      await widget.openUsageAccessSettings();
                      if (!mounted) return;
                      final status = await widget.refreshUsageAccessStatus();
                      setState(() => _usageAccessStatus = status);
                    },
                    child: Text(l10n.settingsAllow),
                  )
                : null,
          ),
        ),

      // 3. Theme & Appearance
      SettingItem(
        title: l10n.settingsDarkMode,
        subtitle: l10n.settingsDarkModeSubtitle,
        keywords: ['dark', 'light', 'mode', 'theme', 'appearance'],
        category: 'Theme & Appearance',
        widget: SwitchListTile(
          contentPadding: EdgeInsets.zero,
          secondary: Icon(widget.isDark ? Icons.dark_mode : Icons.light_mode),
          title: Text(l10n.settingsDarkMode),
          value: widget.isDark,
          onChanged: (_) => widget.toggleTheme(),
        ),
      ),
      if (widget.isDark)
        SettingItem(
          title: l10n.settingsAmoledDarkMode,
          subtitle: l10n.settingsAmoledDarkModeSubtitle,
          keywords: ['amoled', 'pure', 'black', 'battery', 'contrast', 'dark'],
          category: 'Theme & Appearance',
          widget: SwitchListTile(
            contentPadding: EdgeInsets.zero,
            secondary: const Icon(Icons.power_settings_new_outlined),
            title: Text(l10n.settingsAmoledDarkMode),
            subtitle: Text(l10n.settingsAmoledDarkModeSubtitle),
            value: widget.amoledDarkEnabled,
            onChanged: widget.setAmoledDarkEnabled,
          ),
        ),
      SettingItem(
        title: l10n.settingsUseSystemAccent,
        subtitle: l10n.settingsUseSystemAccentSubtitle,
        keywords: [
          'system',
          'accent',
          'color',
          'material you',
          'dynamic',
          'os',
        ],
        category: 'Theme & Appearance',
        widget: SwitchListTile(
          contentPadding: EdgeInsets.zero,
          secondary: const Icon(Icons.color_lens_outlined),
          title: Text(l10n.settingsUseSystemAccent),
          subtitle: Text(l10n.settingsUseSystemAccentSubtitle),
          value: widget.useSystemAccent,
          onChanged: widget.setUseSystemAccent,
        ),
      ),
      if (!widget.useSystemAccent) ...[
        SettingItem(
          title: l10n.settingsColorPreset,
          subtitle: l10n.settingsColorPresetSubtitle,
          keywords: [
            'color',
            'preset',
            'theme',
            'pastel',
            'blue',
            'green',
            'rose',
            'graphite',
            'sunrise',
            'custom',
          ],
          category: 'Theme & Appearance',
          widget: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Text(
                l10n.settingsColorPreset,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              ...ColorPresets.names.map(
                (preset) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    radius: 10,
                    backgroundColor: ColorPresets.swatchColor(
                      preset,
                      widget.isDark,
                      customHex: widget.customAccentColorHex,
                    ),
                  ),
                  title: Text(preset),
                  trailing: preset == widget.colorPreset
                      ? const Icon(Icons.check)
                      : null,
                  onTap: () => widget.setPreset(preset),
                ),
              ),
              if (widget.colorPreset == 'Custom') ...[
                const Divider(),
                const SizedBox(height: 8),
                Text(
                  l10n.settingsCustomAccentPalette,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
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
                          final hex =
                              '#${color.toARGB32().toRadixString(16).substring(2, 8)}';
                          widget.setCustomAccentColorHex(hex);
                        },
                        child: CircleAvatar(
                          radius: 18,
                          backgroundColor: color,
                          child:
                              widget.customAccentColorHex.toLowerCase() ==
                                  '#${color.toARGB32().toRadixString(16).substring(2, 8)}'
                                      .toLowerCase()
                              ? const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 18,
                                )
                              : null,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                                TextFormField(
                  initialValue: widget.customAccentColorHex,
                  key: ValueKey(widget.customAccentColorHex),
                  decoration: InputDecoration(
                    labelText: l10n.settingsAccentColorHex,
                    hintText: '#009688',
                    border: const OutlineInputBorder(),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  style: theme.textTheme.bodyMedium,
                  onChanged: (val) {
                    final cleanVal = val.trim();
                    if (cleanVal.startsWith('#') &&
                        (cleanVal.length == 7 || cleanVal.length == 9)) {
                      widget.setCustomAccentColorHex(cleanVal);
                    } else if (!cleanVal.startsWith('#') &&
                        (cleanVal.length == 6 || cleanVal.length == 8)) {
                      widget.setCustomAccentColorHex('#$cleanVal');
                    }
                  },
                  onFieldSubmitted: (val) {
                    if (val.startsWith('#') &&
                        (val.length == 7 || val.length == 9)) {
                      widget.setCustomAccentColorHex(val);
                    } else if (!val.startsWith('#') &&
                        (val.length == 6 || val.length == 8)) {
                      widget.setCustomAccentColorHex('#$val');
                    }
                  },
                ),
                const SizedBox(height: 16),
                const Text(
                  "Accent Color Live Preview",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Mini Timer Ring Preview
                      Column(
                        children: [
                          SizedBox(
                            width: 60,
                            height: 60,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                SizedBox(
                                  width: 54,
                                  height: 54,
                                  child: CircularProgressIndicator(
                                    value: 1.0,
                                    strokeWidth: 4,
                                    color: widget.isDark
                                        ? Colors.white12
                                        : Colors.black12,
                                  ),
                                ),
                                SizedBox(
                                  width: 54,
                                  height: 54,
                                  child: CircularProgressIndicator(
                                    value: 0.70,
                                    strokeWidth: 4,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      ColorPresets.swatchColor(
                                        'Custom',
                                        widget.isDark,
                                        customHex: widget.customAccentColorHex,
                                      ),
                                    ),
                                    backgroundColor: Colors.transparent,
                                  ),
                                ),
                                Text(
                                  "14:00",
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: widget.isDark
                                        ? Colors.white
                                        : Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            "Timer Ring",
                            style: TextStyle(fontSize: 10, color: Colors.grey),
                          ),
                        ],
                      ),
                      // Mini Break Button Preview
                      Column(
                        children: [
                          ElevatedButton.icon(
                            onPressed: () {},
                            icon: const Icon(Icons.play_arrow, size: 14),
                            label: const Text(
                              "Start",
                              style: TextStyle(fontSize: 11),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: ColorPresets.swatchColor(
                                'Custom',
                                widget.isDark,
                                customHex: widget.customAccentColorHex,
                              ),
                              foregroundColor: ThemeData.estimateBrightnessForColor(
                                ColorPresets.swatchColor(
                                  'Custom',
                                  widget.isDark,
                                  customHex: widget.customAccentColorHex,
                                ),
                              ) == Brightness.dark
                                  ? Colors.white
                                  : Colors.black,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            "Break Button",
                            style: TextStyle(fontSize: 10, color: Colors.grey),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],

      // 4. Notifications & Sounds
      SettingItem(
        title: l10n.settingsNotifications,
        subtitle: l10n.settingsNotificationsSubtitle,
        keywords: ['notification', 'reminders', 'alert', 'popups'],
        category: 'Notifications & Sounds',
        widget: SwitchListTile(
          contentPadding: EdgeInsets.zero,
          secondary: const Icon(Icons.notifications_active_outlined),
          title: Text(l10n.settingsNotifications),
          subtitle: Text(l10n.settingsNotificationsSubtitle),
          value: widget.notificationsEnabled,
          onChanged: widget.setNotificationsEnabled,
        ),
      ),
      SettingItem(
        title: l10n.settingsNotificationSound,
        subtitle: l10n.settingsNotificationSoundSubtitle,
        keywords: ['sound', 'tune', 'chime', 'notification', 'volume'],
        category: 'Notifications & Sounds',
        widget: ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.volume_up_outlined),
          title: Text(l10n.settingsNotificationSound),
          subtitle: Text(l10n.settingsNotificationSoundSubtitle),
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
        title: l10n.settingsTestReminderAlert,
        subtitle: l10n.settingsPlayReminderSound,
        keywords: ['test', 'reminder', 'alert', 'play', 'sound', 'vibration'],
        category: 'Notifications & Sounds',
        widget: ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.play_circle_outline),
          title: Text(l10n.settingsTestReminder),
          subtitle: Text(l10n.settingsPlayReminderSound),
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
      ),
      SettingItem(
        title: l10n.settingsPermissionStatus,
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
              title: Text(l10n.settingsPermissionStatus),
              subtitle: Text(_notificationPermissionLabel()),
            ),
            if (_permissionStatus == NotificationPermissionStatus.disabled)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _openSystemNotificationSettings,
                  icon: const Icon(Icons.settings_outlined),
                  label: Text(l10n.settingsOpenSystemSettings),
                ),
              ),
            if (!widget.notificationsEnabled)
              Padding(
                padding: const EdgeInsets.only(bottom: 8, top: 4),
                child: Text(l10n.settingsTimerAlertsOff),
              ),
          ],
        ),
      ),
      if (_exactAlarmStatus != ExactAlarmStatus.unsupported)
        SettingItem(
          title: l10n.settingsPreciseReminders,
          subtitle: _exactAlarmStatus == ExactAlarmStatus.allowed
              ? l10n.settingsPreciseAllowed
              : l10n.settingsPreciseLate,
          keywords: [
            'precise',
            'reminders',
            'exact',
            'timing',
            'alarm',
            'permission',
          ],
          category: 'Notifications & Sounds',
          widget: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              _exactAlarmStatus == ExactAlarmStatus.allowed
                  ? Icons.alarm_on_outlined
                  : Icons.alarm_off_outlined,
            ),
            title: Text(l10n.settingsPreciseReminders),
            subtitle: Text(
              _exactAlarmStatus == ExactAlarmStatus.allowed
                  ? l10n.settingsPreciseAllowed
                  : l10n.settingsPreciseLate,
            ),
            trailing: _exactAlarmStatus == ExactAlarmStatus.disabled
                ? TextButton(
                    onPressed: _requestExactAlarmPermission,
                    child: Text(l10n.settingsAllow),
                  )
                : null,
          ),
        ),
      if (_batteryOptimizationStatus != BatteryOptimizationStatus.unsupported)
        SettingItem(
          title: l10n.settingsBackgroundReliability,
          subtitle:
              _batteryOptimizationStatus ==
                  BatteryOptimizationStatus.unrestricted
              ? l10n.settingsBatteryUnrestricted
              : l10n.settingsBatteryOptimized,
          keywords: [
            'battery',
            'reliability',
            'optimization',
            'background',
            'delay',
          ],
          category: 'Notifications & Sounds',
          widget: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              _batteryOptimizationStatus ==
                      BatteryOptimizationStatus.unrestricted
                  ? Icons.battery_saver_outlined
                  : Icons.battery_alert_outlined,
            ),
            title: Text(l10n.settingsBackgroundReliability),
            subtitle: Text(
              _batteryOptimizationStatus ==
                      BatteryOptimizationStatus.unrestricted
                  ? l10n.settingsBatteryUnrestricted
                  : l10n.settingsBatteryOptimized,
            ),
            trailing:
                _batteryOptimizationStatus ==
                    BatteryOptimizationStatus.restricted
                ? TextButton(
                    onPressed: _openBatteryOptimizationSettings,
                    child: Text(l10n.settingsReview),
                  )
                : null,
          ),
        ),
      SettingItem(
        title: l10n.settingsHaptics,
        subtitle: l10n.settingsVibratePhaseEnd,
        keywords: ['haptics', 'vibration', 'vibrate', 'feedback'],
        category: 'Notifications & Sounds',
        widget: SwitchListTile(
          contentPadding: EdgeInsets.zero,
          secondary: const Icon(Icons.vibration),
          title: Text(l10n.settingsHaptics),
          subtitle: Text(l10n.settingsVibratePhaseEnd),
          value: widget.hapticsEnabled,
          onChanged: widget.setHapticsEnabled,
        ),
      ),
      SettingItem(
        title: l10n.settingsInAppSound,
        subtitle: l10n.settingsPlayExtraAlert,
        keywords: ['sound', 'alert', 'chime', 'bell', 'zen', 'chimes', 'bowl'],
        category: 'Notifications & Sounds',
        widget: Column(
          children: [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              secondary: const Icon(Icons.volume_up_outlined),
              title: Text(l10n.settingsInAppSound),
              subtitle: Text(l10n.settingsPlayExtraAlert),
              value: widget.soundEnabled,
              onChanged: widget.setSoundEnabled,
            ),
            if (widget.soundEnabled) ...[
              const Divider(height: 1),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.music_note_outlined),
                title: Text(l10n.settingsChimeStyle),
                subtitle: Text(l10n.settingsChimeStyleSubtitle),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 84,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  children: [
                    _buildChimeCard(
                      style: 'tibetan_bowl',
                      name: l10n.settingsChimeTibetanBowl,
                      icon: Icons.brightness_low_outlined,
                      l10n: l10n,
                    ),
                    _buildChimeCard(
                      style: 'wind_chimes',
                      name: l10n.settingsChimeWindChimes,
                      icon: Icons.air_outlined,
                      l10n: l10n,
                    ),
                    _buildChimeCard(
                      style: 'zen_bell',
                      name: l10n.settingsChimeZenBell,
                      icon: Icons.notifications_active_outlined,
                      l10n: l10n,
                    ),
                    _buildChimeCard(
                      style: 'system_alert',
                      name: l10n.settingsChimeSystemAlert,
                      icon: Icons.volume_up_outlined,
                      l10n: l10n,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
          ],
        ),
      ),
      SettingItem(
        title: l10n.settingsConsciousBlinkingReminders,
        subtitle: l10n.settingsConsciousBlinkingDesc,
        keywords: [
          'blink',
          'nudges',
          'micro-reminders',
          'notification',
          'banner',
          'popup',
          'eye',
          'conscious',
          'moisture',
        ],
        category: 'Notifications & Sounds',
        widget: Column(
          children: [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              secondary: const Icon(Icons.remove_red_eye_outlined),
              title: Text(l10n.settingsConsciousBlinkingReminders),
              subtitle: Text(l10n.settingsConsciousBlinkingSubtitle),
              value: widget.blinkRemindersEnabled,
              onChanged: widget.setBlinkRemindersEnabled,
            ),
            if (widget.blinkRemindersEnabled) ...[
              const Divider(height: 1),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.timer_outlined),
                title: Text(l10n.settingsBannerInterval),
                subtitle: Text(l10n.settingsShowBlinkBanner),
                trailing: DropdownButton<int>(
                  value: _nearestBlinkCadence(
                    widget.blinkRemindersCadenceSeconds,
                  ),
                  items: [2, 3, 5, 10, 15, 20, 30, 60, 120, 300, 600, 900]
                      .map(
                        (value) => DropdownMenuItem(
                          value: value,
                          child: Text(
                            value < 60
                                ? l10n.settingsDurationEverySeconds(value)
                                : l10n.settingsDurationEveryMinutes(
                                    value ~/ 60,
                                  ),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      widget.setBlinkRemindersCadenceSeconds(value);
                    }
                  },
                ),
              ),
              const Divider(height: 1),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                secondary: const Icon(Icons.touch_app_outlined),
                title: Text(l10n.settingsInteractiveBlinkReminders),
                subtitle: Text(l10n.settingsInteractiveBlinkRemindersSubtitle),
                value: widget.blinkReminderInteractiveEnabled,
                onChanged: widget.setBlinkReminderInteractiveEnabled,
              ),
            ],
            const Divider(height: 1),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              secondary: const Icon(Icons.notifications_active_outlined),
              title: Text(l10n.settingsTrayBlinkNudges),
              subtitle: Text(l10n.settingsTrayBlinkNudgesSubtitle),
              value: widget.trayBlinkNudgesEnabled,
              onChanged: widget.setTrayBlinkNudgesEnabled,
            ),
            if (widget.trayBlinkNudgesEnabled) ...[
              const Divider(height: 1),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.timelapse_outlined),
                title: Text(l10n.settingsTrayNudgeInterval),
                subtitle: Text(l10n.settingsTrayIconPulse),
                trailing: DropdownButton<int>(
                  value: _nearestBlinkCadence(
                    widget.trayBlinkNudgeCadenceSeconds,
                  ),
                  items: [2, 3, 5, 10, 15, 20, 30, 60, 120, 300, 600, 900]
                      .map(
                        (value) => DropdownMenuItem(
                          value: value,
                          child: Text(
                            value < 60
                                ? l10n.settingsDurationEverySeconds(value)
                                : l10n.settingsDurationEveryMinutes(
                                    value ~/ 60,
                                  ),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      widget.setTrayBlinkNudgeCadenceSeconds(value);
                    }
                  },
                ),
              ),
            ],
          ],
        ),
      ),
      SettingItem(
        title: l10n.settingsWellnessReminders,
        subtitle: l10n.settingsWellnessRemindersSubtitle,
        keywords: [
          'wellness',
          'reminders',
          'hydration',
          'posture',
          'stretch',
          'water',
          'stand',
          'sit',
        ],
        category: 'Notifications & Sounds',
        widget: Column(
          children: [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              secondary: const Icon(Icons.accessibility_new_outlined),
              title: Text(l10n.settingsWellnessReminders),
              subtitle: Text(l10n.settingsWellnessRemindersSubtitle),
              value: widget.wellnessRemindersEnabled,
              onChanged: widget.setWellnessRemindersEnabled,
            ),
            if (widget.wellnessRemindersEnabled) ...[
              const Divider(height: 1),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.timer_outlined),
                title: Text(l10n.settingsReminderInterval),
                subtitle: Text(l10n.settingsReminderIntervalDesc),
                trailing: DropdownButton<int>(
                  value: widget.wellnessReminderCadenceSeconds,
                  items: [1800, 2700, 3600, 5400, 7200].map((value) {
                    String label;
                    if (value == 1800) {
                      label = l10n.settingsWellnessEvery30Min;
                    } else if (value == 2700) {
                      label = l10n.settingsWellnessEvery45Min;
                    } else if (value == 3600) {
                      label = l10n.settingsWellnessEvery1Hour;
                    } else if (value == 5400) {
                      label = l10n.settingsWellnessEvery15Hours;
                    } else {
                      label = l10n.settingsWellnessEvery2Hours;
                    }
                    return DropdownMenuItem<int>(
                      value: value,
                      child: Text(label),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      widget.setWellnessReminderCadenceSeconds(val);
                    }
                  },
                ),
              ),
            ],
          ],
        ),
      ),

      // 5. Auto Run & Long Breaks
      SettingItem(
        title: l10n.settingsRunScheduleAutomatically,
        subtitle: l10n.settingsRunScheduleAutomaticallySubtitle,
        keywords: ['auto', 'run', 'autorenew', 'schedule', 'cycles', 'loop'],
        category: 'Auto Run & Long Breaks',
        widget: Column(
          children: [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              secondary: const Icon(Icons.autorenew),
              title: Text(l10n.settingsRunScheduleAutomatically),
              subtitle: Text(
                widget.canChangeDurations
                    ? l10n.settingsRunScheduleAutomaticallySubtitle
                    : l10n.settingsPauseCancelToChangeDesc,
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
              title: Text(l10n.settingsCycleLimit),
              subtitle: Text(l10n.settingsCycleLimitSubtitle),
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
                        if (value != null) _saveAutoRun(cycleLimit: value);
                      }
                    : null,
              ),
            ),
          ],
        ),
      ),
      SettingItem(
        title: l10n.settingsLongBreakMode,
        subtitle: l10n.settingsLongBreakModeDesc,
        keywords: ['long', 'break', 'interval', 'rest', 'cycles', 'coffee'],
        category: 'Auto Run & Long Breaks',
        widget: Column(
          children: [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              secondary: const Icon(Icons.coffee_outlined),
              title: Text(l10n.settingsLongBreakMode),
              subtitle: Text(
                l10n.settingsLongBreakModeSubtitle(
                  widget.longBreakEveryCycles,
                  _durationLabel(widget.longBreakDurationSeconds),
                ),
              ),
              value: widget.longBreakEnabled,
              onChanged: (enabled) => _saveLongBreak(enabled: enabled),
            ),
            if (widget.longBreakEnabled) ...[
              const Divider(height: 1),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.repeat),
                title: Text(l10n.settingsCycleInterval),
                trailing: DropdownButton<int>(
                  value: widget.longBreakEveryCycles,
                  items: _longBreakCycles
                      .map(
                        (cycles) => DropdownMenuItem<int>(
                          value: cycles,
                          child: Text(l10n.settingsCycleLimitCount(cycles)),
                        ),
                      )
                      .toList(),
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
                title: Text(l10n.settingsLongBreakDuration),
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
          ],
        ),
      ),

      // 6. Desktop Options
      if (isDesktop)
        SettingItem(
          title: l10n.settingsDesktopStartupBehavior,
          subtitle: l10n.settingsDesktopStartupBehaviorSubtitle,
          keywords: [
            'launch',
            'startup',
            'login',
            'autostart',
            'boot',
            'desktop',
            'minimized',
            'tray',
          ],
          category: 'Desktop Options',
          widget: Column(
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                secondary: const Icon(Icons.rocket_launch_outlined),
                title: Text(l10n.settingsLaunchAtStartup),
                subtitle: Text(l10n.settingsStartBlinkKindAutomatically),
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
              const Divider(height: 1),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                secondary: const Icon(Icons.move_to_inbox_outlined),
                title: Text(l10n.settingsStartMinimized),
                subtitle: Text(l10n.settingsOpenIntoTray),
                value: widget.startMinimized,
                onChanged: widget.setStartMinimized,
              ),
            ],
          ),
        ),

      // 7. AI Motivation & Prompts
      SettingItem(
        title: l10n.settingsAiMotivationTitle,
        subtitle: l10n.settingsAiMotivationSubtitle,
        keywords: [
          'ai',
          'motivation',
          'llm',
          'openai',
          'groq',
          'gemini',
          'api',
          'key',
          'model',
          'quote',
          'prompt',
        ],
        category: 'AI Motivation & Prompts',
        widget: _buildAiMotivationSettings(theme),
      ),
      SettingItem(
        title: l10n.settingsResetSettings,
        subtitle: l10n.settingsRestoreFactoryDefaults,
        keywords: [
          'reset',
          'restore',
          'default',
          'factory',
          'settings',
          'clear',
        ],
        category: 'System Options',
        widget: ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.settings_backup_restore, color: Colors.red),
          title: Text(
            l10n.settingsResetSettings,
            style: const TextStyle(color: Colors.red),
          ),
          subtitle: Text(l10n.settingsRestoreFactoryDefaults),
          trailing: ElevatedButton(
            onPressed: () => _showResetConfirmationDialog(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.withAlpha(26),
              foregroundColor: Colors.red,
              elevation: 0,
            ),
            child: Text(l10n.settingsReset),
          ),
        ),
      ),
      SettingItem(
        title: l10n.settingsBackupSettings,
        subtitle: l10n.settingsExportDownloadsFolder,
        keywords: ['backup', 'export', 'save', 'settings', 'json'],
        category: 'System Options',
        widget: ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.backup_outlined),
          title: Text(l10n.settingsBackupSettings),
          subtitle: Text(l10n.settingsExportDownloadsFolder),
          trailing: ElevatedButton(
            onPressed: () => _exportSettingsToFile(context),
            child: Text(l10n.settingsBackup),
          ),
        ),
      ),
      SettingItem(
        title: l10n.settingsRestoreSettings,
        subtitle: l10n.settingsLoadBackupJson,
        keywords: ['restore', 'import', 'load', 'settings', 'json', 'backup'],
        category: 'System Options',
        widget: ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.settings_input_component_outlined),
          title: Text(l10n.settingsRestoreSettings),
          subtitle: Text(l10n.settingsLoadBackupJson),
          trailing: ElevatedButton(
            onPressed: () => _importSettingsFromFile(context),
            child: Text(l10n.settingsRestore),
          ),
        ),
      ),
    ];
  }

  Widget _buildChimeCard({
    required String style,
    required String name,
    required IconData icon,
    required AppLocalizations l10n,
  }) {
    final isSelected = widget.chimeStyle == style;
    final isPlaying = _playingChimeStyle == style;
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: GestureDetector(
        onTap: () {
          widget.setChimeStyle(style);
          unawaited(_playChimePreview(style));
        },
        child: Container(
          width: 154,
          decoration: BoxDecoration(
            color: isSelected
                ? primaryColor.withValues(alpha: 0.08)
                : theme.cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? primaryColor
                  : theme.dividerColor.withValues(alpha: 0.15),
              width: isSelected ? 1.8 : 1.0,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: primaryColor.withValues(alpha: 0.15),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected
                            ? primaryColor.withValues(alpha: 0.15)
                            : theme.dividerColor.withValues(alpha: 0.05),
                      ),
                      child: Icon(
                        icon,
                        size: 18,
                        color: isSelected
                            ? primaryColor
                            : theme.iconTheme.color?.withValues(alpha: 0.7),
                      ),
                    ),
                    if (isPlaying)
                      SizedBox(
                        width: 36,
                        height: 36,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: primaryColor,
                          valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? primaryColor : theme.textTheme.bodyMedium?.color,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isPlaying
                            ? "Playing..."
                            : (isSelected ? "Selected" : "Tap to preview"),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: isPlaying
                              ? primaryColor
                              : theme.textTheme.labelSmall?.color?.withValues(alpha: 0.5),
                          fontSize: 9,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAiMotivationSettings(ThemeData theme) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          secondary: const Icon(Icons.auto_awesome_outlined),
          title: Text(l10n.settingsEnableAiMotivation),
          subtitle: Text(l10n.settingsAiMotivationEnabledSubtitle),
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
            title: Text(l10n.settingsAiProvider),
            trailing: DropdownButton<String>(
              value: widget.aiProvider,
              underline: const SizedBox(),
              items: [
                DropdownMenuItem(
                  value: 'Gemini',
                  child: Text(l10n.settingsAiProviderGemini),
                ),
                DropdownMenuItem(
                  value: 'OpenAI',
                  child: Text(l10n.settingsAiProviderOpenAi),
                ),
                DropdownMenuItem(
                  value: 'Groq',
                  child: Text(l10n.settingsAiProviderGroq),
                ),
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
                      labelText: l10n.settingsAiApiKey,
                      hintText: l10n.settingsAiApiKeyHint,
                      border: const OutlineInputBorder(),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _aiApiKeyObscured
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                        onPressed: () => setState(
                          () => _aiApiKeyObscured = !_aiApiKeyObscured,
                        ),
                      ),
                    ),
                    onChanged: (val) {
                      _aiApiKeyDebounce?.cancel();
                      _aiApiKeyDebounce = Timer(
                        const Duration(milliseconds: 800),
                        () {
                          widget.setAiApiKey(val.trim());
                          if (val.trim().isNotEmpty) {
                            unawaited(
                              _fetchAiModels(val.trim(), widget.aiProvider),
                            );
                          }
                        },
                      );
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
            title: Text(l10n.settingsAiModel),
            subtitle: _aiModelsError != null
                ? Text(
                    _aiModelsError!,
                    style: TextStyle(
                      color: theme.colorScheme.error,
                      fontSize: 12,
                    ),
                  )
                : null,
            trailing: DropdownButton<String>(
              value: _aiAvailableModels.contains(widget.aiModel)
                  ? widget.aiModel
                  : (_aiAvailableModels.isNotEmpty
                        ? _aiAvailableModels.first
                        : null),
              underline: const SizedBox(),
              items: [
                ..._aiAvailableModels.map(
                  (m) => DropdownMenuItem(
                    value: m,
                    child: Text(m, overflow: TextOverflow.ellipsis),
                  ),
                ),
                DropdownMenuItem(
                  value: '__custom__',
                  child: Text(l10n.settingsAiModelCustom),
                ),
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
              decoration: InputDecoration(
                labelText: l10n.settingsAiSystemPrompt,
                hintText: l10n.settingsAiSystemPromptHint,
                border: const OutlineInputBorder(),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
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
      final models = await AiService.instance.fetchModels(
        provider: provider,
        apiKey: apiKey,
      );
      if (!mounted) return;
      setState(() {
        _aiAvailableModels = models.isNotEmpty
            ? models
            : AiService.instance.getDefaultModels(provider);
        _aiLoadingModels = false;
      });
    } catch (e) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      setState(() {
        _aiAvailableModels = AiService.instance.getDefaultModels(provider);
        _aiLoadingModels = false;
        _aiModelsError = l10n.settingsAiLoadModelsError;
      });
    }
  }

  void _showCustomModelDialog() {
    final l10n = AppLocalizations.of(context)!;
    _aiModelCustomController.text = widget.aiModel;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.settingsCustomModelDialogTitle),
        content: TextField(
          controller: _aiModelCustomController,
          decoration: InputDecoration(
            labelText: l10n.settingsModelName,
            hintText: l10n.settingsModelNameHint,
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () {
              final val = _aiModelCustomController.text.trim();
              if (val.isNotEmpty) widget.setAiModel(val);
              Navigator.of(ctx).pop();
            },
            child: Text(l10n.settingsSet),
          ),
        ],
      ),
    );
  }

  void _showResetConfirmationDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.settingsRestoreDefaultsTitle),
        content: Text(l10n.settingsRestoreDefaultsDesc),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              widget.restoreDefaultSettings();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  duration: const Duration(seconds: 4),
                  content: Text(l10n.settingsRestoredSnackbar),
                  action: SnackBarAction(
                    label: 'OK',
                    onPressed: () {
                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    },
                  ),
                ),
              );
            },
            child: Text(l10n.settingsReset),
          ),
        ],
      ),
    );
  }

  TimerSettings _getCurrentSettings() {
    return TimerSettings(
      workDurationSeconds: widget.workDurationSeconds,
      breakDurationSeconds: widget.breakDurationSeconds,
      themeMode: widget.isDark ? ThemeMode.dark : ThemeMode.light,
      colorPreset: widget.colorPreset,
      streakCount: widget.streakCount,
      dailyGoal: widget.dailyGoal,
      notificationsEnabled: widget.notificationsEnabled,
      hapticsEnabled: widget.hapticsEnabled,
      soundEnabled: widget.soundEnabled,
      longBreakEnabled: widget.longBreakEnabled,
      longBreakDurationSeconds: widget.longBreakDurationSeconds,
      longBreakEveryCycles: widget.longBreakEveryCycles,
      autoRunEnabled: widget.autoRunEnabled,
      autoRunCycleLimit: widget.autoRunCycleLimit,
      breakMode: widget.breakMode,
      allowSkip: widget.allowSkip,
      allowPostpone: widget.allowPostpone,
      postponeDurationSeconds: widget.postponeDurationSeconds,
      smartIdleEnabled: widget.smartIdleEnabled,
      breakVisualizerStyle: widget.breakVisualizerStyle,
      breakShowClock: widget.breakShowClock,
      breakShowTips: widget.breakShowTips,
      breakShowProgress: widget.breakShowProgress,
      breakCustomMessage: widget.breakCustomMessage,
      chimeStyle: widget.chimeStyle,
      blinkRemindersEnabled: widget.blinkRemindersEnabled,
      blinkRemindersCadenceSeconds: widget.blinkRemindersCadenceSeconds,
      trayBlinkNudgesEnabled: widget.trayBlinkNudgesEnabled,
      trayBlinkNudgeCadenceSeconds: widget.trayBlinkNudgeCadenceSeconds,
      workHoursEnabled: widget.workHoursEnabled,
      workHoursStartHour: widget.workHoursStartHour,
      workHoursStartMinute: widget.workHoursStartMinute,
      workHoursEndHour: widget.workHoursEndHour,
      workHoursEndMinute: widget.workHoursEndMinute,
      workDays: widget.workDays,
      naturalBreakCreditEnabled: widget.naturalBreakCreditEnabled,
      amoledDarkEnabled: widget.amoledDarkEnabled,
      customAccentColorHex: widget.customAccentColorHex,
      useSystemAccent: widget.useSystemAccent,
      startMinimized: widget.startMinimized,
      autoStartSchedule: widget.autoStartSchedule,
      aiMotivationEnabled: widget.aiMotivationEnabled,
      osFocusDndEnabled: widget.osFocusDndEnabled,
      aiProvider: widget.aiProvider,
      aiApiKey: widget.aiApiKey,
      aiModel: widget.aiModel,
      aiCustomSystemPrompt: widget.aiCustomSystemPrompt,
      blinkReminderAiEnabled: widget.blinkReminderAiEnabled,
      blinkReminderCustomMessage: widget.blinkReminderCustomMessage,
      cameraMicAutoPostponeEnabled: widget.cameraMicAutoPostponeEnabled,
      autoPauseOnMediaEnabled: widget.autoPauseOnMediaEnabled,
      wellnessRemindersEnabled: widget.wellnessRemindersEnabled,
      wellnessReminderCadenceSeconds: widget.wellnessReminderCadenceSeconds,
      blinkReminderInteractiveEnabled: widget.blinkReminderInteractiveEnabled,
      maxConsecutiveSkips: widget.maxConsecutiveSkips,
    );
  }

  Future<void> _exportSettingsToFile(BuildContext context) async {
    try {
      final settings = _getCurrentSettings();
      final jsonMap = {
        'version': 1,
        'exportedAt': DateTime.now().toIso8601String(),
        'settings': settings.toJson(),
      };
      final content = const JsonEncoder.withIndent('  ').convert(jsonMap);

      final timestamp = DateTime.now()
          .toIso8601String()
          .replaceAll(':', '-')
          .split('.')
          .first;
      final fileName = 'blinkkind_settings_backup_$timestamp.json';

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
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 4),
          content: Row(
            children: [
              Expanded(
                child: Text(l10n.settingsExportedSnackbar(fileName)),
              ),
              const SizedBox(width: 8),
              _SnackBarButton(
                label: l10n.openFolder,
                onPressed: () {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  if (Platform.isLinux) {
                    Process.run('xdg-open', [dir.path]);
                  } else if (Platform.isMacOS) {
                    Process.run('open', [dir.path]);
                  } else if (Platform.isWindows) {
                    Process.run('explorer.exe', [dir.path]);
                  }
                },
              ),
              const SizedBox(width: 4),
              _SnackBarButton(
                label: 'OK',
                onPressed: () =>
                    ScaffoldMessenger.of(context).hideCurrentSnackBar(),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 4),
          content: Text(l10n.settingsExportFailedSnackbar(e.toString())),
          action: SnackBarAction(
            label: 'OK',
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            },
          ),
        ),
      );
    }
  }

  Future<void> _importSettingsFromFile(BuildContext context) async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null || result.files.single.path == null) {
        return;
      }

      final file = File(result.files.single.path!);
      final content = await file.readAsString();
      final decoded = json.decode(content) as Map<String, dynamic>;

      if (!decoded.containsKey('settings')) {
        throw Exception("Invalid backup file: settings data not found.");
      }

      final settingsMap = decoded['settings'] as Map<String, dynamic>;
      final newSettings = TimerSettings.fromJson(
        settingsMap,
        currentStreak: widget.streakCount,
      );

      await widget.importSettings(newSettings);

      if (!context.mounted) return;
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 4),
          content: Text(l10n.settingsRestoredSuccessSnackbar),
          action: SnackBarAction(
            label: 'OK',
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            },
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 4),
          content: Text(l10n.settingsRestoredFailedSnackbar(e.toString())),
          action: SnackBarAction(
            label: 'OK',
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            },
          ),
        ),
      );
    }
  }

  void _showCustomDailyGoalDialog() {
    final l10n = AppLocalizations.of(context)!;
    _dailyGoalCustomController.text = widget.dailyGoal.toString();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.settingsCustomDailyGoalTitle),
        content: TextField(
          controller: _dailyGoalCustomController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: l10n.settingsNumberOfBreaks,
            hintText: l10n.settingsNumberOfBreaksHint,
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () {
              final val = int.tryParse(_dailyGoalCustomController.text.trim());
              if (val != null && val > 0) {
                widget.setDailyGoal(val);
              }
              Navigator.of(ctx).pop();
            },
            child: Text(l10n.settingsSet),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    final items = _allSettingItems(context);
    final filtered = items.where((item) {
      final text =
          '${item.title} ${item.subtitle ?? ''} ${item.category} ${item.keywords.join(' ')}'
              .toLowerCase();
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
              AppLocalizations.of(context)!.settingsNoResults(_searchQuery),
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = Theme.of(context).colorScheme.primary;

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final item = filtered[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          color: isDark 
              ? Colors.white.withValues(alpha: 0.04) 
              : Colors.black.withValues(alpha: 0.02),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: isDark 
                  ? Colors.white.withValues(alpha: 0.08) 
                  : Colors.black.withValues(alpha: 0.05),
              width: 1.0,
            ),
          ),
          elevation: 0,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: accentColor.withValues(alpha: 0.25),
                      width: 1.0,
                    ),
                  ),
                  child: Text(
                    _getCategoryLabel(context, item.category),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: accentColor,
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
      if (groups.containsKey('System Options')) 'System Options',
    ];

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = Theme.of(context).colorScheme.primary;

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
          color: isDark 
              ? Colors.white.withValues(alpha: 0.04) 
              : Colors.black.withValues(alpha: 0.015),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: isDark 
                  ? Colors.white.withValues(alpha: 0.08) 
                  : Colors.black.withValues(alpha: 0.04),
              width: 1.0,
            ),
          ),
          elevation: 0,
          child: Theme(
            data: Theme.of(context).copyWith(
              dividerColor: Colors.transparent,
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
            ),
            child: ExpansionTile(
              title: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: accentColor.withValues(alpha: 0.25),
                    width: 1.0,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _categoryIcon(category),
                      size: 16,
                      color: accentColor,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _getCategoryLabel(context, category),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: accentColor,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              childrenPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              children: children,
            ),
          ),
        );
      },
    );
  }

  String _getCategoryLabel(BuildContext context, String category) {
    final l10n = AppLocalizations.of(context)!;
    switch (category) {
      case 'General Schedule':
        return l10n.settingsCategoryGeneralSchedule;
      case 'Break Screen & Behavior':
        return l10n.settingsCategoryBreakBehavior;
      case 'Theme & Appearance':
        return l10n.settingsCategoryThemeAppearance;
      case 'Notifications & Sounds':
        return l10n.settingsCategoryNotificationsSounds;
      case 'Auto Run & Long Breaks':
        return l10n.settingsCategoryAutoRunLongBreaks;
      case 'Desktop Options':
        return l10n.settingsCategoryDesktopOptions;
      case 'AI Motivation & Prompts':
        return l10n.settingsCategoryAiMotivation;
      case 'System Options':
        return l10n.settingsCategorySystemOptions;
      default:
        return category;
    }
  }

  IconData _categoryIcon(String category) {
    switch (category) {
      case 'General Schedule':
        return Icons.calendar_today;
      case 'Break Screen & Behavior':
        return Icons.visibility;
      case 'Theme & Appearance':
        return Icons.color_lens;
      case 'Notifications & Sounds':
        return Icons.notifications_active;
      case 'Auto Run & Long Breaks':
        return Icons.repeat;
      case 'Desktop Options':
        return Icons.desktop_windows;
      case 'AI Motivation & Prompts':
        return Icons.auto_awesome;
      case 'System Options':
        return Icons.settings;
      default:
        return Icons.settings;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.settingsTitle)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: AppLocalizations.of(
                  context,
                )!.settingsSearchPlaceholder,
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

/// A compact action button styled for use inside [SnackBar] content Rows.
/// Uses the SnackBar's inverse-primary color, has a rounded pill background,
/// and shows a proper Material hover/ripple so it clearly looks clickable.
class _SnackBarButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const _SnackBarButton({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return TextButton(
      style: TextButton.styleFrom(
        foregroundColor: cs.inversePrimary,
        backgroundColor: cs.inversePrimary.withValues(alpha: 0.15),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        minimumSize: const Size(40, 32),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: const StadiumBorder(),
      ).copyWith(
        overlayColor: WidgetStatePropertyAll(cs.inversePrimary.withValues(alpha: 0.22)),
      ),
      onPressed: onPressed,
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
    );
  }
}
