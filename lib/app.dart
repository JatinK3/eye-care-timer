import 'dart:async';

import 'package:flutter/material.dart';

import 'features/timer/timer_home_page.dart';
import 'models/timer_session.dart';
import 'models/timer_settings.dart';
import 'services/notification_service.dart';
import 'services/preferences_service.dart';

/// Top-level app that owns ThemeMode and color preset state.
class EyeCareTimerApp extends StatefulWidget {
  final NotificationService? notificationService;

  const EyeCareTimerApp({super.key, this.notificationService});

  @override
  State<EyeCareTimerApp> createState() => _EyeCareTimerAppState();
}

class _EyeCareTimerAppState extends State<EyeCareTimerApp> {
  final PreferencesService _preferencesService = PreferencesService();
  late final NotificationService _notificationService;

  TimerSettings _settings = const TimerSettings.defaults();
  TimerSession _session = const TimerSession.idle();
  bool _isLoadingSettings = true;

  @override
  void initState() {
    super.initState();
    _notificationService = widget.notificationService ?? NotificationService();
    unawaited(_notificationService.initialize());
    unawaited(_loadSettings());
  }

  Future<void> _loadSettings() async {
    final settings = await _preferencesService.loadSettings();
    final session = await _preferencesService.loadSession();
    if (!mounted) {
      return;
    }

    setState(() {
      _settings = settings;
      _session = session;
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

  void _saveStreakCount(int streakCount) {
    setState(() {
      _settings = _settings.copyWith(streakCount: streakCount);
    });
    unawaited(_preferencesService.saveStreakCount(streakCount));
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Eye Care Timer',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          brightness: Brightness.dark,
        ),
      ),
      themeMode: _settings.themeMode,
      home: _isLoadingSettings
          ? const Scaffold(body: Center(child: CircularProgressIndicator()))
          : TimerHomePage(
              isDark: _settings.themeMode == ThemeMode.dark,
              colorPreset: _settings.colorPreset,
              initialWorkDurationSeconds: _settings.workDurationSeconds,
              initialBreakDurationSeconds: _settings.breakDurationSeconds,
              initialStreakCount: _settings.streakCount,
              initialSession: _session,
              setPreset: _setPreset,
              toggleTheme: _toggleTheme,
              saveDurations: _saveDurations,
              saveStreakCount: _saveStreakCount,
              saveSession: _saveSession,
              clearSession: _clearSession,
              notificationService: _notificationService,
            ),
    );
  }
}
