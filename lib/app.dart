import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dynamic_color/dynamic_color.dart';

import 'features/history/history_page.dart';
import 'features/onboarding/onboarding_page.dart';
import 'features/settings/settings_page.dart';
import 'features/timer/timer_home_page.dart';
import 'features/splash/splash_quote_page.dart';
import 'models/timer_session.dart';
import 'models/timer_settings.dart';
import 'models/timer_event_record.dart';
import 'models/work_session_record.dart';
import 'services/break_overlay_service.dart';
import 'services/notification_service.dart';
import 'services/permissions_service.dart';
import 'services/preferences_service.dart';
import 'theme/color_presets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'generated/l10n/app_localizations.dart';

const PageTransitionsTheme _smoothPageTransitionsTheme = PageTransitionsTheme(
  builders: <TargetPlatform, PageTransitionsBuilder>{
    TargetPlatform.android: CupertinoPageTransitionsBuilder(),
    TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
    TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
    TargetPlatform.fuchsia: ZoomPageTransitionsBuilder(),
    TargetPlatform.linux: ZoomPageTransitionsBuilder(),
    TargetPlatform.windows: ZoomPageTransitionsBuilder(),
  },
);

/// Builds a clean, minimalist Inter-based text theme on top of [base].
/// Inter is geometric, highly legible, and gives the crisp iOS-like feel
/// on Android without any decorative serifs or display flourishes.
TextTheme _buildTextTheme(TextTheme base) {
  return GoogleFonts.interTextTheme(base).copyWith(
    // Display — very large hero numbers (timer countdown)
    displayLarge: GoogleFonts.inter(
      fontSize: 57,
      fontWeight: FontWeight.w200,
      letterSpacing: -1.5,
      height: 1.1,
    ),
    displayMedium: GoogleFonts.inter(
      fontSize: 45,
      fontWeight: FontWeight.w200,
      letterSpacing: -0.5,
      height: 1.15,
    ),
    displaySmall: GoogleFonts.inter(
      fontSize: 36,
      fontWeight: FontWeight.w300,
      letterSpacing: -0.5,
      height: 1.2,
    ),
    // Headline — section titles, card headers
    headlineLarge: GoogleFonts.inter(
      fontSize: 32,
      fontWeight: FontWeight.w300,
      letterSpacing: -0.3,
      height: 1.25,
    ),
    headlineMedium: GoogleFonts.inter(
      fontSize: 28,
      fontWeight: FontWeight.w400,
      letterSpacing: -0.2,
      height: 1.3,
    ),
    headlineSmall: GoogleFonts.inter(
      fontSize: 24,
      fontWeight: FontWeight.w400,
      letterSpacing: -0.2,
      height: 1.3,
    ),
    // Title — dialog titles, list section headers
    titleLarge: GoogleFonts.inter(
      fontSize: 22,
      fontWeight: FontWeight.w500,
      letterSpacing: -0.1,
      height: 1.35,
    ),
    titleMedium: GoogleFonts.inter(
      fontSize: 16,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.1,
      height: 1.4,
    ),
    titleSmall: GoogleFonts.inter(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.1,
      height: 1.4,
    ),
    // Body — general readable text
    bodyLarge: GoogleFonts.inter(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.0,
      height: 1.5,
    ),
    bodyMedium: GoogleFonts.inter(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.0,
      height: 1.5,
    ),
    bodySmall: GoogleFonts.inter(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.1,
      height: 1.5,
    ),
    // Label — button labels, tags, captions
    labelLarge: GoogleFonts.inter(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.1,
      height: 1.4,
    ),
    labelMedium: GoogleFonts.inter(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.4,
      height: 1.4,
    ),
    labelSmall: GoogleFonts.inter(
      fontSize: 11,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.4,
      height: 1.4,
    ),
  );
}

class _BlinkKindScrollBehavior extends MaterialScrollBehavior {
  const _BlinkKindScrollBehavior();

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    final platform = getPlatform(context);
    if (platform == TargetPlatform.android || platform == TargetPlatform.iOS) {
      return const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      );
    }
    return super.getScrollPhysics(context);
  }
}

/// Top-level app that owns ThemeMode and color preset state.
class BlinkKindApp extends StatefulWidget {
  final NotificationService? notificationService;
  final BreakOverlayService? breakOverlayService;

  const BlinkKindApp({
    super.key,
    this.notificationService,
    this.breakOverlayService,
  });

  @override
  State<BlinkKindApp> createState() => _BlinkKindAppState();
}

class _BlinkKindAppState extends State<BlinkKindApp> {
  final PreferencesService _preferencesService = PreferencesService();
  late final NotificationService _notificationService;
  late final BreakOverlayService _breakOverlayService;

  TimerSettings _settings = const TimerSettings.defaults();
  TimerSession _session = const TimerSession.idle();
  Map<String, int> _history = <String, int>{};
  List<WorkSessionRecord> _workSessionHistory = <WorkSessionRecord>[];
  List<TimerEventRecord> _timerEventHistory = <TimerEventRecord>[];
  final ValueNotifier<List<TimerEventRecord>> _timerEventHistoryListenable =
      ValueNotifier<List<TimerEventRecord>>(<TimerEventRecord>[]);
  NotificationPermissionStatus _notificationPermissionStatus =
      NotificationPermissionStatus.unknown;
  ExactAlarmStatus _exactAlarmStatus = ExactAlarmStatus.unknown;
  BatteryOptimizationStatus _batteryOptimizationStatus =
      BatteryOptimizationStatus.unknown;
  OverlayPermissionStatus _overlayPermissionStatus =
      OverlayPermissionStatus.unknown;
  UsageAccessStatus _usageAccessStatus = UsageAccessStatus.unknown;
  bool _hasCompletedOnboarding = false;
  bool _isLoadingSettings = true;
  bool _showSplash = true;

  final PermissionsService _permissionsService = PermissionsService();
  StreamSubscription<NotificationResponse>? _notificationSubscription;
  StreamSubscription<void>? _blinkReminderAcknowledgedSubscription;

  @override
  void initState() {
    super.initState();
    _notificationService = widget.notificationService ?? NotificationService();
    _breakOverlayService = widget.breakOverlayService ?? BreakOverlayService();
    unawaited(_initializeNotifications());
    unawaited(_refreshOverlayPermissionStatus());
    unawaited(_refreshUsageAccessStatus());
    unawaited(_loadSettings());
  }

  Future<void> _initializeNotifications() async {
    await _notificationService.initialize();
    await _refreshNotificationReliabilityStatus();
    _notificationSubscription = _notificationService.onNotificationResponse
        .listen(_handleNotificationResponse);
    _blinkReminderAcknowledgedSubscription = _notificationService
        .onBlinkReminderAcknowledged
        .listen((_) => _recordBlinkReminderAcknowledged());
  }

  @override
  void dispose() {
    _notificationSubscription?.cancel();
    _blinkReminderAcknowledgedSubscription?.cancel();
    _timerEventHistoryListenable.dispose();
    super.dispose();
  }

  void _handleNotificationResponse(NotificationResponse response) {
    if (response.actionId == 'blink_done') {
      _recordBlinkReminderAcknowledged();
    }
  }

  void _recordBlinkReminderAcknowledged() {
    final now = DateTime.now();
    final record = TimerEventRecord(
      id: now.microsecondsSinceEpoch.toString(),
      timestamp: now,
      type: TimerEventType.blinkReminderAcknowledged,
      durationSeconds: 0,
    );
    _saveTimerEventRecord(record);
  }

  Future<NotificationReliabilityStatus>
  _refreshNotificationReliabilityStatus() async {
    final status = await _notificationService.reliabilityStatus();
    if (!mounted) return status;
    setState(() {
      _notificationPermissionStatus = status.permission;
      _exactAlarmStatus = status.exactAlarms;
      _batteryOptimizationStatus = status.batteryOptimization;
    });
    return status;
  }

  Future<NotificationPermissionStatus>
  _refreshNotificationPermissionStatus() async {
    return (await _refreshNotificationReliabilityStatus()).permission;
  }

  Future<void> _requestNotificationPermissions() async {
    await _notificationService.requestPermissions();
    await _refreshNotificationPermissionStatus();
  }

  Future<void> _completeOnboarding({required bool requestReminders}) async {
    setState(() {
      _hasCompletedOnboarding = true;
      _settings = _settings.copyWith(notificationsEnabled: requestReminders);
    });
    await _preferencesService.saveOnboardingCompleted(true);
    await _preferencesService.saveNotificationsEnabled(requestReminders);
    if (requestReminders) {
      await _requestNotificationPermissions();
    } else {
      await _notificationService.cancelPhaseReminder();
      await _refreshNotificationPermissionStatus();
    }
    // On Android 13+, show a rationale dialog if notifications are not yet
    // granted (system dialog may not auto-prompt in all OEM configurations).
    await _maybeShowNotificationRationale();
  }

  Future<void> _maybeShowNotificationRationale() async {
    if (!mounted) return;
    // Only relevant on Android 13+ (API 33)
    if (kIsWeb || !Platform.isAndroid) return;
    final status = await _notificationService.permissionStatus();
    if (status == NotificationPermissionStatus.disabled) {
      final navigator = BreakOverlayService.navigatorKey.currentContext;
      if (navigator == null || !navigator.mounted) return;
      await showDialog<void>(
        context: navigator,
        builder: (ctx) {
          final l10n = AppLocalizations.of(ctx)!;
          return AlertDialog(
            title: Text(l10n.notificationPermissionTitle),
            content: Text(l10n.notificationPermissionMessage),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text(l10n.notNow),
              ),
              FilledButton(
                onPressed: () async {
                  Navigator.of(ctx).pop();
                  await _notificationService.openNotificationSettings();
                },
                child: Text(l10n.openSettings),
              ),
            ],
          );
        },
      );
    }
  }

  Future<OverlayPermissionStatus> _refreshOverlayPermissionStatus() async {
    final status = await _breakOverlayService.permissionStatus();
    if (mounted) {
      setState(() => _overlayPermissionStatus = status);
    }
    return status;
  }

  Future<UsageAccessStatus> _refreshUsageAccessStatus() async {
    final status = await _permissionsService.usageAccessStatus();
    if (mounted) {
      setState(() => _usageAccessStatus = status);
    }
    return status;
  }

  Future<void> _openUsageAccessSettings() async {
    await _permissionsService.openUsageAccessSettings();
  }

  Future<void> _openOverlayPermissionSettings() async {
    await _breakOverlayService.openPermissionSettings();
  }

  Future<bool> _showOverlayPreview() {
    String resolvedStyle = _settings.breakVisualizerStyle;
    if (resolvedStyle == 'Random') {
      const styles = [
        'Breathing',
        'BoxBreathing',
        'EyeExercise',
        'Ambient',
        'Starry',
      ];
      resolvedStyle = styles[math.Random().nextInt(styles.length)];
    }
    return _breakOverlayService.showPreview(
      breakVisualizerStyle: resolvedStyle,
      showClock: _settings.breakShowClock,
      showTips: _settings.breakShowTips,
      showProgress: _settings.breakShowProgress,
      customMessage: _settings.breakCustomMessage,
    );
  }

  Future<bool> _showRealBreakTest() {
    String resolvedStyle = _settings.breakVisualizerStyle;
    if (resolvedStyle == 'Random') {
      const styles = [
        'Breathing',
        'BoxBreathing',
        'EyeExercise',
        'Ambient',
        'Starry',
      ];
      resolvedStyle = styles[math.Random().nextInt(styles.length)];
    }
    return _breakOverlayService.showBreakOverlay(
      durationSeconds: 20,
      breakMode: _settings.breakMode,
      breakVisualizerStyle: resolvedStyle,
      showClock: _settings.breakShowClock,
      showTips: _settings.breakShowTips,
      showProgress: _settings.breakShowProgress,
      customMessage: _settings.breakCustomMessage,
      isPreview: true,
    );
  }

  Future<void> _openNotificationSettings() async {
    await _notificationService.openNotificationSettings();
  }

  Future<void> _openReminderChannelSettings() async {
    await _notificationService.openReminderChannelSettings();
  }

  Future<bool> _showTestReminder() {
    return _notificationService.showTestReminder();
  }

  Future<void> _requestExactAlarmPermission() async {
    await _notificationService.requestExactAlarmPermission();
  }

  Future<void> _openBatteryOptimizationSettings() async {
    await _notificationService.openBatteryOptimizationSettings();
  }

  Future<void> _loadSettings() async {
    final settings = await _preferencesService.loadSettings();
    final session = await _preferencesService.loadSession();
    final history = await _preferencesService.loadHistory();
    final workSessionHistory = await _preferencesService
        .loadWorkSessionHistory();
    final timerEventHistory = await _preferencesService.loadTimerEventHistory();
    final hasCompletedOnboarding = await _preferencesService
        .loadOnboardingCompleted();
    if (!mounted) {
      return;
    }

    setState(() {
      _settings = settings;
      _session = session;
      _history = history;
      _workSessionHistory = workSessionHistory;
      _timerEventHistory = timerEventHistory;
      _timerEventHistoryListenable.value = List<TimerEventRecord>.unmodifiable(
        timerEventHistory,
      );
      _hasCompletedOnboarding = hasCompletedOnboarding;
      _isLoadingSettings = false;
    });
  }

  void _toggleTheme() {
    final nextThemeMode = _settings.themeMode == ThemeMode.light
        ? ThemeMode.dark
        : ThemeMode.light;
    setState(() {
      _settings = _settings.copyWith(themeMode: nextThemeMode);
    });
    unawaited(_preferencesService.saveThemeMode(nextThemeMode));
  }

  void _setPreset(String preset) {
    setState(() {
      _settings = _settings.copyWith(colorPreset: preset);
    });
    unawaited(_preferencesService.saveColorPreset(preset));
  }

  void _setDailyGoal(int dailyGoal) {
    setState(() {
      _settings = _settings.copyWith(dailyGoal: dailyGoal);
    });
    unawaited(_preferencesService.saveDailyGoal(dailyGoal));
  }

  void _setHapticsEnabled(bool enabled) {
    setState(() {
      _settings = _settings.copyWith(hapticsEnabled: enabled);
    });
    unawaited(_preferencesService.saveHapticsEnabled(enabled));
  }

  void _setSoundEnabled(bool enabled) {
    setState(() {
      _settings = _settings.copyWith(soundEnabled: enabled);
    });
    unawaited(_preferencesService.saveSoundEnabled(enabled));
  }

  void _setChimeStyle(String style) {
    setState(() {
      _settings = _settings.copyWith(chimeStyle: style);
    });
    unawaited(_preferencesService.saveChimeStyle(style));
  }

  void _setAmoledDarkEnabled(bool enabled) {
    setState(() {
      _settings = _settings.copyWith(amoledDarkEnabled: enabled);
    });
    unawaited(_preferencesService.saveAmoledDarkEnabled(enabled));
  }

  void _setCustomAccentColorHex(String hex) {
    setState(() {
      _settings = _settings.copyWith(customAccentColorHex: hex);
    });
    unawaited(_preferencesService.saveCustomAccentColorHex(hex));
  }

  void _setUseSystemAccent(bool enabled) {
    setState(() {
      _settings = _settings.copyWith(useSystemAccent: enabled);
    });
    unawaited(_preferencesService.saveUseSystemAccent(enabled));
  }

  void _setStartMinimized(bool enabled) {
    setState(() {
      _settings = _settings.copyWith(startMinimized: enabled);
    });
    unawaited(_preferencesService.saveStartMinimized(enabled));
  }

  void _setBlinkRemindersEnabled(bool enabled) {
    setState(() {
      _settings = _settings.copyWith(blinkRemindersEnabled: enabled);
    });
    unawaited(_preferencesService.saveBlinkRemindersEnabled(enabled));
  }

  void _setBlinkRemindersCadenceSeconds(int seconds) {
    setState(() {
      _settings = _settings.copyWith(blinkRemindersCadenceSeconds: seconds);
    });
    unawaited(_preferencesService.saveBlinkRemindersCadenceSeconds(seconds));
  }

  void _setTrayBlinkNudgesEnabled(bool enabled) {
    setState(() {
      _settings = _settings.copyWith(trayBlinkNudgesEnabled: enabled);
    });
    unawaited(_preferencesService.saveTrayBlinkNudgesEnabled(enabled));
  }

  void _setTrayBlinkNudgeCadenceSeconds(int seconds) {
    setState(() {
      _settings = _settings.copyWith(trayBlinkNudgeCadenceSeconds: seconds);
    });
    unawaited(_preferencesService.saveTrayBlinkNudgeCadenceSeconds(seconds));
  }

  void _setWorkHoursEnabled(bool enabled) {
    setState(() {
      _settings = _settings.copyWith(workHoursEnabled: enabled);
    });
    unawaited(_preferencesService.saveWorkHoursEnabled(enabled));
  }

  void _setWorkHoursStartHour(int hour) {
    setState(() {
      _settings = _settings.copyWith(workHoursStartHour: hour);
    });
    unawaited(_preferencesService.saveWorkHoursStartHour(hour));
  }

  void _setWorkHoursStartMinute(int minute) {
    setState(() {
      _settings = _settings.copyWith(workHoursStartMinute: minute);
    });
    unawaited(_preferencesService.saveWorkHoursStartMinute(minute));
  }

  void _setWorkHoursEndHour(int hour) {
    setState(() {
      _settings = _settings.copyWith(workHoursEndHour: hour);
    });
    unawaited(_preferencesService.saveWorkHoursEndHour(hour));
  }

  void _setWorkHoursEndMinute(int minute) {
    setState(() {
      _settings = _settings.copyWith(workHoursEndMinute: minute);
    });
    unawaited(_preferencesService.saveWorkHoursEndMinute(minute));
  }

  void _setWorkDays(String days) {
    setState(() {
      _settings = _settings.copyWith(workDays: days);
    });
    unawaited(_preferencesService.saveWorkDays(days));
  }

  void _setNaturalBreakCreditEnabled(bool enabled) {
    setState(() {
      _settings = _settings.copyWith(naturalBreakCreditEnabled: enabled);
    });
    unawaited(_preferencesService.saveNaturalBreakCreditEnabled(enabled));
  }

  void _setAutoStartSchedule(bool enabled) {
    setState(() {
      _settings = _settings.copyWith(autoStartSchedule: enabled);
    });
    unawaited(_preferencesService.saveAutoStartSchedule(enabled));
  }

  void _setTwoStageWarningEnabled(bool enabled) {
    setState(() {
      _settings = _settings.copyWith(twoStageWarningEnabled: enabled);
    });
    unawaited(_preferencesService.saveTwoStageWarningEnabled(enabled));
  }

  void _setBlinkReminderInteractiveEnabled(bool enabled) {
    setState(() {
      _settings = _settings.copyWith(blinkReminderInteractiveEnabled: enabled);
    });
    unawaited(_preferencesService.saveBlinkReminderInteractiveEnabled(enabled));
  }

  void _setOsFocusDndEnabled(bool enabled) {
    setState(() {
      _settings = _settings.copyWith(osFocusDndEnabled: enabled);
    });
    unawaited(_preferencesService.saveOsFocusDndEnabled(enabled));
  }

  Future<void> _restoreDefaultSettings() async {
    final defaults = await _preferencesService.resetToDefaultSettings(
      _settings.streakCount,
    );
    setState(() {
      _settings = defaults;
    });
  }

  Future<void> _importSettings(TimerSettings settings) async {
    await _preferencesService.saveAllSettings(settings);
    setState(() {
      _settings = settings;
    });
  }

  void _setAiMotivationEnabled(bool enabled) {
    setState(() {
      _settings = _settings.copyWith(aiMotivationEnabled: enabled);
    });
    unawaited(_preferencesService.saveAiMotivationEnabled(enabled));
  }

  void _setAiProvider(String provider) {
    setState(() {
      _settings = _settings.copyWith(aiProvider: provider);
    });
    unawaited(_preferencesService.saveAiProvider(provider));
  }

  void _setAiApiKey(String apiKey) {
    setState(() {
      _settings = _settings.copyWith(aiApiKey: apiKey);
    });
    unawaited(_preferencesService.saveAiApiKey(apiKey));
  }

  void _setAiModel(String model) {
    setState(() {
      _settings = _settings.copyWith(aiModel: model);
    });
    unawaited(_preferencesService.saveAiModel(model));
  }

  void _setAiCustomSystemPrompt(String prompt) {
    setState(() {
      _settings = _settings.copyWith(aiCustomSystemPrompt: prompt);
    });
    unawaited(_preferencesService.saveAiCustomSystemPrompt(prompt));
  }

  void _setNotificationsEnabled(bool enabled) {
    setState(() {
      _settings = _settings.copyWith(notificationsEnabled: enabled);
    });
    if (!enabled) {
      unawaited(_notificationService.cancelPhaseReminder());
      unawaited(_refreshNotificationPermissionStatus());
    } else {
      unawaited(_requestNotificationPermissions());
    }
    unawaited(_preferencesService.saveNotificationsEnabled(enabled));
  }

  void _saveDurations(int workDurationSeconds, int breakDurationSeconds) {
    setState(() {
      _settings = _settings.copyWith(
        workDurationSeconds: workDurationSeconds,
        breakDurationSeconds: breakDurationSeconds,
      );
    });
    unawaited(
      _preferencesService.saveDurations(
        workDurationSeconds: workDurationSeconds,
        breakDurationSeconds: breakDurationSeconds,
      ),
    );
  }

  void _saveLongBreakSettings({
    required bool enabled,
    required int durationSeconds,
    required int everyCycles,
  }) {
    setState(() {
      _settings = _settings.copyWith(
        longBreakEnabled: enabled,
        longBreakDurationSeconds: durationSeconds,
        longBreakEveryCycles: everyCycles,
      );
    });
    unawaited(
      _preferencesService.saveLongBreakSettings(
        enabled: enabled,
        durationSeconds: durationSeconds,
        everyCycles: everyCycles,
      ),
    );
  }

  void _saveAutoRunSettings({required bool enabled, required int cycleLimit}) {
    setState(() {
      _settings = _settings.copyWith(
        autoRunEnabled: enabled,
        autoRunCycleLimit: cycleLimit,
      );
    });
    unawaited(
      _preferencesService.saveAutoRunSettings(
        enabled: enabled,
        cycleLimit: cycleLimit,
      ),
    );
  }

  void _setBreakMode(BreakMode breakMode) {
    setState(() {
      _settings = _settings.copyWith(breakMode: breakMode);
    });
    unawaited(_preferencesService.saveBreakMode(breakMode));
  }

  void _setAllowSkip(bool enabled) {
    setState(() {
      _settings = _settings.copyWith(allowSkip: enabled);
    });
    unawaited(_preferencesService.saveAllowSkip(enabled));
  }

  void _setAllowPostpone(bool enabled) {
    setState(() {
      _settings = _settings.copyWith(allowPostpone: enabled);
    });
    unawaited(_preferencesService.saveAllowPostpone(enabled));
  }

  void _setPostponeDurationSeconds(int seconds) {
    setState(() {
      _settings = _settings.copyWith(postponeDurationSeconds: seconds);
    });
    unawaited(_preferencesService.savePostponeDurationSeconds(seconds));
  }

  void _setSmartIdleEnabled(bool enabled) {
    setState(() {
      _settings = _settings.copyWith(smartIdleEnabled: enabled);
    });
    unawaited(_preferencesService.saveSmartIdleEnabled(enabled));
  }

  void _setBreakVisualizerStyle(String style) {
    setState(() {
      _settings = _settings.copyWith(breakVisualizerStyle: style);
    });
    unawaited(_preferencesService.saveBreakVisualizerStyle(style));
  }

  void _setBreakShowClock(bool enabled) {
    setState(() {
      _settings = _settings.copyWith(breakShowClock: enabled);
    });
    unawaited(_preferencesService.saveBreakShowClock(enabled));
  }

  void _setBreakShowTips(bool enabled) {
    setState(() {
      _settings = _settings.copyWith(breakShowTips: enabled);
    });
    unawaited(_preferencesService.saveBreakShowTips(enabled));
  }

  void _setBreakShowProgress(bool enabled) {
    setState(() {
      _settings = _settings.copyWith(breakShowProgress: enabled);
    });
    unawaited(_preferencesService.saveBreakShowProgress(enabled));
  }

  void _setBreakCustomMessage(String message) {
    setState(() {
      _settings = _settings.copyWith(breakCustomMessage: message);
    });
    unawaited(_preferencesService.saveBreakCustomMessage(message));
  }

  void _saveSession(TimerSession session) {
    setState(() {
      _session = session;
    });
    unawaited(_preferencesService.saveSession(session));
  }

  void _clearSession() {
    setState(() {
      _session = const TimerSession.idle();
    });
    unawaited(_preferencesService.clearSession());
  }

  String _todayKey() {
    final today = DateTime.now();
    final year = today.year.toString().padLeft(4, '0');
    final month = today.month.toString().padLeft(2, '0');
    final day = today.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  void _saveCompletedWorkSession(DateTime completedAt, int durationSeconds) {
    final record = WorkSessionRecord.completed(
      completedAt: completedAt,
      durationSeconds: durationSeconds,
    );
    setState(() {
      final updated = List<WorkSessionRecord>.from(_workSessionHistory)
        ..removeWhere((existing) => existing.id == record.id)
        ..insert(0, record);
      _workSessionHistory = updated.length > 500
          ? updated.sublist(0, 500)
          : updated;
    });
    unawaited(_preferencesService.saveCompletedWorkSession(record));
  }

  void _saveTimerEventRecord(TimerEventRecord record) {
    setState(() {
      final updated = List<TimerEventRecord>.from(_timerEventHistory)
        ..removeWhere((existing) => existing.id == record.id)
        ..insert(0, record);
      _timerEventHistory = updated.length > 1000
          ? updated.sublist(0, 1000)
          : updated;
      _timerEventHistoryListenable.value = List<TimerEventRecord>.unmodifiable(
        _timerEventHistory,
      );
    });
    unawaited(_preferencesService.saveTimerEventRecord(record));
  }

  void _resetHistory() {
    setState(() {
      _history = <String, int>{};
      _workSessionHistory = <WorkSessionRecord>[];
      _timerEventHistory = <TimerEventRecord>[];
      _timerEventHistoryListenable.value = const <TimerEventRecord>[];
      _settings = _settings.copyWith(streakCount: 0);
    });
    unawaited(_preferencesService.clearHistory());
    unawaited(_preferencesService.saveStreakCount(0));
  }

  void _resetStreakCount() {
    setState(() {
      _settings = _settings.copyWith(streakCount: 0);
      final updatedHistory = Map<String, int>.from(_history);
      updatedHistory.remove(_todayKey());
      _history = updatedHistory;
    });
    unawaited(_preferencesService.saveStreakCount(0));
  }

  void _saveStreakCount(int streakCount) {
    setState(() {
      _settings = _settings.copyWith(streakCount: streakCount);
      final updatedHistory = Map<String, int>.from(_history);
      if (streakCount <= 0) {
        updatedHistory.remove(_todayKey());
      } else {
        updatedHistory[_todayKey()] = streakCount;
      }
      _history = updatedHistory;
    });
    unawaited(_preferencesService.saveStreakCount(streakCount));
  }

  Future<HistoryDataSnapshot> _refreshHistoryData() async {
    final history = await _preferencesService.loadHistory();
    final workSessions = await _preferencesService.loadWorkSessionHistory();
    final timerEvents = await _preferencesService.loadTimerEventHistory();

    if (mounted) {
      setState(() {
        _history = history;
        _workSessionHistory = workSessions;
        _timerEventHistory = timerEvents;
        _timerEventHistoryListenable.value =
            List<TimerEventRecord>.unmodifiable(timerEvents);
      });
    }

    return HistoryDataSnapshot(
      history: history,
      workSessions: workSessions,
      timerEvents: timerEvents,
    );
  }

  void _openHistory(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => HistoryPage(
          history: _history,
          workSessions: _workSessionHistory,
          timerEvents: _timerEventHistory,
          timerEventsListenable: _timerEventHistoryListenable,
          refreshHistoryData: _refreshHistoryData,
          dailyGoal: _settings.dailyGoal,
          resetHistory: _resetHistory,
          aiProvider: _settings.aiProvider,
          aiApiKey: _settings.aiApiKey,
          aiModel: _settings.aiModel,
          aiMotivationEnabled: _settings.aiMotivationEnabled,
        ),
      ),
    );
  }

  void _openSettings(BuildContext context, bool canChangeDurations) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SettingsPage(
          isDark: _settings.themeMode == ThemeMode.dark,
          colorPreset: _settings.colorPreset,
          workDurationSeconds: _settings.workDurationSeconds,
          breakDurationSeconds: _settings.breakDurationSeconds,
          streakCount: _settings.streakCount,
          dailyGoal: _settings.dailyGoal,
          longBreakEnabled: _settings.longBreakEnabled,
          longBreakDurationSeconds: _settings.longBreakDurationSeconds,
          longBreakEveryCycles: _settings.longBreakEveryCycles,
          autoRunEnabled: _settings.autoRunEnabled,
          autoRunCycleLimit: _settings.autoRunCycleLimit,
          breakMode: _settings.breakMode,
          setBreakMode: _setBreakMode,
          allowSkip: _settings.allowSkip,
          allowPostpone: _settings.allowPostpone,
          postponeDurationSeconds: _settings.postponeDurationSeconds,
          smartIdleEnabled: _settings.smartIdleEnabled,
          breakVisualizerStyle: _settings.breakVisualizerStyle,
          breakShowClock: _settings.breakShowClock,
          breakShowTips: _settings.breakShowTips,
          breakShowProgress: _settings.breakShowProgress,
          breakCustomMessage: _settings.breakCustomMessage,
          setAllowSkip: _setAllowSkip,
          setAllowPostpone: _setAllowPostpone,
          setPostponeDurationSeconds: _setPostponeDurationSeconds,
          setSmartIdleEnabled: _setSmartIdleEnabled,
          setBreakVisualizerStyle: _setBreakVisualizerStyle,
          setBreakShowClock: _setBreakShowClock,
          setBreakShowTips: _setBreakShowTips,
          setBreakShowProgress: _setBreakShowProgress,
          setBreakCustomMessage: _setBreakCustomMessage,
          notificationsEnabled: _settings.notificationsEnabled,
          notificationPermissionStatus: _notificationPermissionStatus,
          exactAlarmStatus: _exactAlarmStatus,
          batteryOptimizationStatus: _batteryOptimizationStatus,
          overlayPermissionStatus: _overlayPermissionStatus,
          usageAccessStatus: _usageAccessStatus,
          refreshUsageAccessStatus: _refreshUsageAccessStatus,
          openUsageAccessSettings: _openUsageAccessSettings,
          hapticsEnabled: _settings.hapticsEnabled,
          soundEnabled: _settings.soundEnabled,
          chimeStyle: _settings.chimeStyle,
          setChimeStyle: _setChimeStyle,
          blinkRemindersEnabled: _settings.blinkRemindersEnabled,
          blinkRemindersCadenceSeconds: _settings.blinkRemindersCadenceSeconds,
          setBlinkRemindersEnabled: _setBlinkRemindersEnabled,
          setBlinkRemindersCadenceSeconds: _setBlinkRemindersCadenceSeconds,
          trayBlinkNudgesEnabled: _settings.trayBlinkNudgesEnabled,
          trayBlinkNudgeCadenceSeconds: _settings.trayBlinkNudgeCadenceSeconds,
          setTrayBlinkNudgesEnabled: _setTrayBlinkNudgesEnabled,
          setTrayBlinkNudgeCadenceSeconds: _setTrayBlinkNudgeCadenceSeconds,
          blinkReminderAiEnabled: _settings.blinkReminderAiEnabled,
          blinkReminderCustomMessage: _settings.blinkReminderCustomMessage,
          cameraMicAutoPostponeEnabled: _settings.cameraMicAutoPostponeEnabled,
          wellnessRemindersEnabled: _settings.wellnessRemindersEnabled,
          wellnessReminderCadenceSeconds:
              _settings.wellnessReminderCadenceSeconds,
          blinkReminderInteractiveEnabled:
              _settings.blinkReminderInteractiveEnabled,
          setBlinkReminderInteractiveEnabled:
              _setBlinkReminderInteractiveEnabled,
          workHoursEnabled: _settings.workHoursEnabled,
          workHoursStartHour: _settings.workHoursStartHour,
          workHoursStartMinute: _settings.workHoursStartMinute,
          workHoursEndHour: _settings.workHoursEndHour,
          workHoursEndMinute: _settings.workHoursEndMinute,
          workDays: _settings.workDays,
          naturalBreakCreditEnabled: _settings.naturalBreakCreditEnabled,
          setWorkHoursEnabled: _setWorkHoursEnabled,
          setWorkHoursStartHour: _setWorkHoursStartHour,
          setWorkHoursStartMinute: _setWorkHoursStartMinute,
          setWorkHoursEndHour: _setWorkHoursEndHour,
          setWorkHoursEndMinute: _setWorkHoursEndMinute,
          setWorkDays: _setWorkDays,
          setNaturalBreakCreditEnabled: _setNaturalBreakCreditEnabled,
          autoStartSchedule: _settings.autoStartSchedule,
          setAutoStartSchedule: _setAutoStartSchedule,
          twoStageWarningEnabled: _settings.twoStageWarningEnabled,
          setTwoStageWarningEnabled: _setTwoStageWarningEnabled,
          canChangeDurations: canChangeDurations,
          toggleTheme: _toggleTheme,
          setPreset: _setPreset,
          saveDurations: _saveDurations,
          saveLongBreakSettings: _saveLongBreakSettings,
          saveAutoRunSettings: _saveAutoRunSettings,
          setDailyGoal: _setDailyGoal,
          amoledDarkEnabled: _settings.amoledDarkEnabled,
          customAccentColorHex: _settings.customAccentColorHex,
          useSystemAccent: _settings.useSystemAccent,
          setAmoledDarkEnabled: _setAmoledDarkEnabled,
          setCustomAccentColorHex: _setCustomAccentColorHex,
          setUseSystemAccent: _setUseSystemAccent,
          startMinimized: _settings.startMinimized,
          setStartMinimized: _setStartMinimized,
          setNotificationsEnabled: _setNotificationsEnabled,
          setHapticsEnabled: _setHapticsEnabled,
          setSoundEnabled: _setSoundEnabled,
          openOverlayPermissionSettings: _openOverlayPermissionSettings,
          showOverlayPreview: _showOverlayPreview,
          showRealBreakTest: _showRealBreakTest,
          refreshOverlayPermissionStatus: _refreshOverlayPermissionStatus,
          openNotificationSettings: _openNotificationSettings,
          openReminderChannelSettings: _openReminderChannelSettings,
          showTestReminder: _showTestReminder,
          refreshNotificationReliabilityStatus:
              _refreshNotificationReliabilityStatus,
          requestExactAlarmPermission: _requestExactAlarmPermission,
          openBatteryOptimizationSettings: _openBatteryOptimizationSettings,
          openHistory: _openHistory,
          resetStreak: _resetStreakCount,
          aiMotivationEnabled: _settings.aiMotivationEnabled,
          aiProvider: _settings.aiProvider,
          aiApiKey: _settings.aiApiKey,
          aiModel: _settings.aiModel,
          aiCustomSystemPrompt: _settings.aiCustomSystemPrompt,
          setAiMotivationEnabled: _setAiMotivationEnabled,
          setAiProvider: _setAiProvider,
          setAiApiKey: _setAiApiKey,
          setAiModel: _setAiModel,
          setAiCustomSystemPrompt: _setAiCustomSystemPrompt,
          osFocusDndEnabled: _settings.osFocusDndEnabled,
          setOsFocusDndEnabled: _setOsFocusDndEnabled,
          restoreDefaultSettings: _restoreDefaultSettings,
          importSettings: _importSettings,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        final seedColor = _settings.useSystemAccent
            ? (lightDynamic?.primary ??
                  ColorPresets.seedColor(
                    _settings.colorPreset,
                    customHex: _settings.customAccentColorHex,
                  ))
            : ColorPresets.seedColor(
                _settings.colorPreset,
                customHex: _settings.customAccentColorHex,
              );

        ColorScheme lightColorScheme;
        ColorScheme darkColorScheme;

        if (_settings.useSystemAccent &&
            lightDynamic != null &&
            darkDynamic != null) {
          lightColorScheme = lightDynamic;
          darkColorScheme = darkDynamic;
        } else {
          lightColorScheme = ColorScheme.fromSeed(seedColor: seedColor);
          darkColorScheme = ColorScheme.fromSeed(
            seedColor: seedColor,
            brightness: Brightness.dark,
          );
        }

        // AMOLED modifications
        if (_settings.amoledDarkEnabled) {
          darkColorScheme = darkColorScheme.copyWith(surface: Colors.black);
        }

        final isPlatformDark =
            MediaQuery.platformBrightnessOf(context) == Brightness.dark;
        final isDarkTheme =
            _settings.themeMode == ThemeMode.dark ||
            (_settings.themeMode == ThemeMode.system && isPlatformDark);

        return MaterialApp(
          navigatorKey: BreakOverlayService.navigatorKey,
          onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          debugShowCheckedModeBanner: false,
          scrollBehavior: const _BlinkKindScrollBehavior(),
          theme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.light,
            colorScheme: lightColorScheme,
            textTheme: _buildTextTheme(ThemeData.light().textTheme),
            pageTransitionsTheme: _smoothPageTransitionsTheme,
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,
            colorScheme: darkColorScheme,
            scaffoldBackgroundColor: _settings.amoledDarkEnabled
                ? Colors.black
                : null,
            textTheme: _buildTextTheme(ThemeData.dark().textTheme),
            pageTransitionsTheme: _smoothPageTransitionsTheme,
          ),
          themeMode: _settings.themeMode,
          home: _isLoadingSettings
              ? const Scaffold(body: Center(child: CircularProgressIndicator()))
              : !_hasCompletedOnboarding
              ? OnboardingPage(
                  notificationPermissionStatus: _notificationPermissionStatus,
                  continueToApp: () =>
                      unawaited(_completeOnboarding(requestReminders: true)),
                  skipNotifications: () =>
                      unawaited(_completeOnboarding(requestReminders: false)),
                )
              : _showSplash
              ? SplashQuotePage(
                  onComplete: () {
                    setState(() => _showSplash = false);
                  },
                )
              : TimerHomePage(
                  isDark: isDarkTheme,
                  colorPreset: _settings.colorPreset,
                  customAccentColorHex: _settings.customAccentColorHex,
                  useSystemAccent: _settings.useSystemAccent,
                  initialWorkDurationSeconds: _settings.workDurationSeconds,
                  initialBreakDurationSeconds: _settings.breakDurationSeconds,
                  initialStreakCount: _settings.streakCount,
                  dailyGoal: _settings.dailyGoal,
                  longBreakEnabled: _settings.longBreakEnabled,
                  longBreakDurationSeconds: _settings.longBreakDurationSeconds,
                  longBreakEveryCycles: _settings.longBreakEveryCycles,
                  autoRunEnabled: _settings.autoRunEnabled,
                  autoRunCycleLimit: _settings.autoRunCycleLimit,
                  notificationsEnabled: _settings.notificationsEnabled,
                  hapticsEnabled: _settings.hapticsEnabled,
                  soundEnabled: _settings.soundEnabled,
                  chimeStyle: _settings.chimeStyle,
                  blinkRemindersEnabled: _settings.blinkRemindersEnabled,
                  blinkRemindersCadenceSeconds:
                      _settings.blinkRemindersCadenceSeconds,
                  trayBlinkNudgesEnabled: _settings.trayBlinkNudgesEnabled,
                  trayBlinkNudgeCadenceSeconds:
                      _settings.trayBlinkNudgeCadenceSeconds,
                  workHoursEnabled: _settings.workHoursEnabled,
                  workHoursStartHour: _settings.workHoursStartHour,
                  workHoursStartMinute: _settings.workHoursStartMinute,
                  workHoursEndHour: _settings.workHoursEndHour,
                  workHoursEndMinute: _settings.workHoursEndMinute,
                  workDays: _settings.workDays,
                  naturalBreakCreditEnabled:
                      _settings.naturalBreakCreditEnabled,
                  autoStartSchedule: _settings.autoStartSchedule,
                  twoStageWarningEnabled: _settings.twoStageWarningEnabled,
                  breakMode: _settings.breakMode,
                  allowSkip: _settings.allowSkip,
                  allowPostpone: _settings.allowPostpone,
                  postponeDurationSeconds: _settings.postponeDurationSeconds,
                  smartIdleEnabled: _settings.smartIdleEnabled,
                  breakVisualizerStyle: _settings.breakVisualizerStyle,
                  breakShowClock: _settings.breakShowClock,
                  breakShowTips: _settings.breakShowTips,
                  breakShowProgress: _settings.breakShowProgress,
                  breakCustomMessage: _settings.breakCustomMessage,
                  initialSession: _session,
                  openSettings: _openSettings,
                  setPreset: _setPreset,
                  toggleTheme: _toggleTheme,
                  saveDurations: _saveDurations,
                  saveStreakCount: _saveStreakCount,
                  saveCompletedWorkSession: _saveCompletedWorkSession,
                  saveTimerEventRecord: _saveTimerEventRecord,
                  setNotificationsEnabled: _setNotificationsEnabled,
                  saveSession: _saveSession,
                  clearSession: _clearSession,
                  notificationService: _notificationService,
                  breakOverlayService: _breakOverlayService,
                  aiMotivationEnabled: _settings.aiMotivationEnabled,
                  osFocusDndEnabled: _settings.osFocusDndEnabled,
                  aiProvider: _settings.aiProvider,
                  aiApiKey: _settings.aiApiKey,
                  aiModel: _settings.aiModel,
                  aiCustomSystemPrompt: _settings.aiCustomSystemPrompt,
                  blinkReminderAiEnabled: _settings.blinkReminderAiEnabled,
                  blinkReminderCustomMessage:
                      _settings.blinkReminderCustomMessage,
                  cameraMicAutoPostponeEnabled:
                      _settings.cameraMicAutoPostponeEnabled,
                  wellnessRemindersEnabled: _settings.wellnessRemindersEnabled,
                  wellnessReminderCadenceSeconds:
                      _settings.wellnessReminderCadenceSeconds,
                  blinkReminderInteractiveEnabled:
                      _settings.blinkReminderInteractiveEnabled,
                  openHistory: _openHistory,
                ),
        );
      },
    );
  }
}
