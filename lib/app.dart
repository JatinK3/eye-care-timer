import 'dart:async';

import 'package:flutter/material.dart';

import 'features/history/history_page.dart';
import 'features/onboarding/onboarding_page.dart';
import 'features/settings/settings_page.dart';
import 'features/timer/timer_home_page.dart';
import 'models/timer_session.dart';
import 'models/timer_settings.dart';
import 'models/work_session_record.dart';
import 'services/break_overlay_service.dart';
import 'services/notification_service.dart';
import 'services/preferences_service.dart';
import 'theme/color_presets.dart';

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
  NotificationPermissionStatus _notificationPermissionStatus =
      NotificationPermissionStatus.unknown;
  ExactAlarmStatus _exactAlarmStatus = ExactAlarmStatus.unknown;
  BatteryOptimizationStatus _batteryOptimizationStatus =
      BatteryOptimizationStatus.unknown;
  OverlayPermissionStatus _overlayPermissionStatus =
      OverlayPermissionStatus.unknown;
  bool _hasCompletedOnboarding = false;
  bool _isLoadingSettings = true;

  @override
  void initState() {
    super.initState();
    _notificationService = widget.notificationService ?? NotificationService();
    _breakOverlayService = widget.breakOverlayService ?? BreakOverlayService();
    unawaited(_initializeNotifications());
    unawaited(_refreshOverlayPermissionStatus());
    unawaited(_loadSettings());
  }

  Future<void> _initializeNotifications() async {
    await _notificationService.initialize();
    await _refreshNotificationReliabilityStatus();
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
  }

  Future<OverlayPermissionStatus> _refreshOverlayPermissionStatus() async {
    final status = await _breakOverlayService.permissionStatus();
    if (mounted) {
      setState(() => _overlayPermissionStatus = status);
    }
    return status;
  }

  Future<void> _openOverlayPermissionSettings() async {
    await _breakOverlayService.openPermissionSettings();
  }

  Future<bool> _showOverlayPreview() {
    return _breakOverlayService.showPreview();
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

  void _resetHistory() {
    setState(() {
      _history = <String, int>{};
      _workSessionHistory = <WorkSessionRecord>[];
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

  void _openHistory(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => HistoryPage(
          history: _history,
          workSessions: _workSessionHistory,
          dailyGoal: _settings.dailyGoal,
          resetHistory: _resetHistory,
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
          setAllowSkip: _setAllowSkip,
          setAllowPostpone: _setAllowPostpone,
          setPostponeDurationSeconds: _setPostponeDurationSeconds,
          notificationsEnabled: _settings.notificationsEnabled,
          notificationPermissionStatus: _notificationPermissionStatus,
          exactAlarmStatus: _exactAlarmStatus,
          batteryOptimizationStatus: _batteryOptimizationStatus,
          overlayPermissionStatus: _overlayPermissionStatus,
          hapticsEnabled: _settings.hapticsEnabled,
          soundEnabled: _settings.soundEnabled,
          canChangeDurations: canChangeDurations,
          toggleTheme: _toggleTheme,
          setPreset: _setPreset,
          saveDurations: _saveDurations,
          saveLongBreakSettings: _saveLongBreakSettings,
          saveAutoRunSettings: _saveAutoRunSettings,
          setDailyGoal: _setDailyGoal,
          setNotificationsEnabled: _setNotificationsEnabled,
          setHapticsEnabled: _setHapticsEnabled,
          setSoundEnabled: _setSoundEnabled,
          openOverlayPermissionSettings: _openOverlayPermissionSettings,
          showOverlayPreview: _showOverlayPreview,
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
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final seedColor = ColorPresets.seedColor(_settings.colorPreset);

    return MaterialApp(
      title: 'BlinkKind: Eye Break Timer',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(seedColor: seedColor),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: seedColor,
          brightness: Brightness.dark,
        ),
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
          : TimerHomePage(
              isDark: _settings.themeMode == ThemeMode.dark,
              colorPreset: _settings.colorPreset,
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
              breakMode: _settings.breakMode,
              allowSkip: _settings.allowSkip,
              allowPostpone: _settings.allowPostpone,
              postponeDurationSeconds: _settings.postponeDurationSeconds,
              initialSession: _session,
              openSettings: _openSettings,
              setPreset: _setPreset,
              toggleTheme: _toggleTheme,
              saveDurations: _saveDurations,
              saveStreakCount: _saveStreakCount,
              saveCompletedWorkSession: _saveCompletedWorkSession,
              setNotificationsEnabled: _setNotificationsEnabled,
              saveSession: _saveSession,
              clearSession: _clearSession,
              notificationService: _notificationService,
              breakOverlayService: _breakOverlayService,
            ),
    );
  }
}
