import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/timer_session.dart';
import '../models/timer_settings.dart';

class PreferencesService {
  static const String workDurationSecondsKey = 'workDurationSeconds';
  static const String breakDurationSecondsKey = 'breakDurationSeconds';
  static const String themeModeKey = 'themeMode';
  static const String colorPresetKey = 'colorPreset';
  static const String streakCountKey = 'streakCount';
  static const String streakDateKey = 'streakDate';
  static const String dailyGoalKey = 'dailyGoal';
  static const String notificationsEnabledKey = 'notificationsEnabled';
  static const String hapticsEnabledKey = 'hapticsEnabled';
  static const String soundEnabledKey = 'soundEnabled';
  static const String longBreakEnabledKey = 'longBreakEnabled';
  static const String longBreakDurationSecondsKey = 'longBreakDurationSeconds';
  static const String longBreakEveryCyclesKey = 'longBreakEveryCycles';
  static const String onboardingCompletedKey = 'onboardingCompleted';
  static const String dailyHistoryKey = 'dailyHistory';
  static const String sessionIsActiveKey = 'sessionIsActive';
  static const String sessionIsBreakKey = 'sessionIsBreak';
  static const String sessionIsPausedKey = 'sessionIsPaused';
  static const String sessionInitialDurationSecondsKey =
      'sessionInitialDurationSeconds';
  static const String sessionRemainingSecondsKey = 'sessionRemainingSeconds';
  static const String sessionPhaseStartedAtKey = 'sessionPhaseStartedAt';
  static const String sessionPhaseEndsAtKey = 'sessionPhaseEndsAt';

  Future<TimerSettings> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final today = _dateKey(DateTime.now());
    final savedStreakDate = prefs.getString(streakDateKey);
    var streakCount = prefs.getInt(streakCountKey) ?? 0;

    if (savedStreakDate != today) {
      final previousStreakCount = streakCount;
      if (savedStreakDate != null && previousStreakCount > 0) {
        await _saveHistoryCount(prefs, savedStreakDate, previousStreakCount);
      }
      streakCount = 0;
      await prefs.setString(streakDateKey, today);
      await prefs.setInt(streakCountKey, streakCount);
    }

    return TimerSettings(
      workDurationSeconds:
          prefs.getInt(workDurationSecondsKey) ??
          TimerSettings.defaultWorkDurationSeconds,
      breakDurationSeconds:
          prefs.getInt(breakDurationSecondsKey) ??
          TimerSettings.defaultBreakDurationSeconds,
      themeMode: _themeModeFromString(prefs.getString(themeModeKey)),
      colorPreset:
          prefs.getString(colorPresetKey) ?? TimerSettings.defaultColorPreset,
      streakCount: streakCount,
      dailyGoal: prefs.getInt(dailyGoalKey) ?? 6,
      notificationsEnabled: prefs.getBool(notificationsEnabledKey) ?? true,
      hapticsEnabled: prefs.getBool(hapticsEnabledKey) ?? true,
      soundEnabled: prefs.getBool(soundEnabledKey) ?? false,
      longBreakEnabled: prefs.getBool(longBreakEnabledKey) ?? false,
      longBreakDurationSeconds:
          prefs.getInt(longBreakDurationSecondsKey) ??
          TimerSettings.defaultLongBreakDurationSeconds,
      longBreakEveryCycles:
          prefs.getInt(longBreakEveryCyclesKey) ??
          TimerSettings.defaultLongBreakEveryCycles,
    );
  }

  Future<Map<String, int>> loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    return _historyFromPrefs(prefs);
  }

  Future<void> saveHistoryCount(String dateKey, int count) async {
    final prefs = await SharedPreferences.getInstance();
    await _saveHistoryCount(prefs, dateKey, count);
  }

  Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(dailyHistoryKey);
  }

  Future<bool> loadOnboardingCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(onboardingCompletedKey) ?? false;
  }

  Future<void> saveOnboardingCompleted(bool completed) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(onboardingCompletedKey, completed);
  }

  Future<TimerSession> loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    final isActive = prefs.getBool(sessionIsActiveKey) ?? false;
    if (!isActive) {
      return const TimerSession.idle();
    }

    return TimerSession(
      isActive: isActive,
      isBreak: prefs.getBool(sessionIsBreakKey) ?? false,
      isPaused: prefs.getBool(sessionIsPausedKey) ?? false,
      initialDurationSeconds:
          prefs.getInt(sessionInitialDurationSecondsKey) ?? 0,
      remainingSeconds: prefs.getInt(sessionRemainingSecondsKey) ?? 0,
      phaseStartedAt: _dateTimeFromMillis(
        prefs.getInt(sessionPhaseStartedAtKey),
      ),
      phaseEndsAt: _dateTimeFromMillis(prefs.getInt(sessionPhaseEndsAtKey)),
    );
  }

  Future<void> saveSession(TimerSession session) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(sessionIsActiveKey, session.isActive);
    await prefs.setBool(sessionIsBreakKey, session.isBreak);
    await prefs.setBool(sessionIsPausedKey, session.isPaused);
    await prefs.setInt(
      sessionInitialDurationSecondsKey,
      session.initialDurationSeconds,
    );
    await prefs.setInt(sessionRemainingSecondsKey, session.remainingSeconds);
    await _setOptionalDateTime(
      prefs,
      sessionPhaseStartedAtKey,
      session.phaseStartedAt,
    );
    await _setOptionalDateTime(
      prefs,
      sessionPhaseEndsAtKey,
      session.phaseEndsAt,
    );
  }

  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(sessionIsActiveKey, false);
    await prefs.remove(sessionIsBreakKey);
    await prefs.remove(sessionIsPausedKey);
    await prefs.remove(sessionInitialDurationSecondsKey);
    await prefs.remove(sessionRemainingSecondsKey);
    await prefs.remove(sessionPhaseStartedAtKey);
    await prefs.remove(sessionPhaseEndsAtKey);
  }

  Future<void> saveDurations({
    required int workDurationSeconds,
    required int breakDurationSeconds,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(workDurationSecondsKey, workDurationSeconds);
    await prefs.setInt(breakDurationSecondsKey, breakDurationSeconds);
  }

  Future<void> saveThemeMode(ThemeMode themeMode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(themeModeKey, _themeModeToString(themeMode));
  }

  Future<void> saveColorPreset(String colorPreset) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(colorPresetKey, colorPreset);
  }

  Future<void> saveDailyGoal(int dailyGoal) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(dailyGoalKey, dailyGoal);
  }

  Future<void> saveNotificationsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(notificationsEnabledKey, enabled);
  }

  Future<void> saveHapticsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(hapticsEnabledKey, enabled);
  }

  Future<void> saveSoundEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(soundEnabledKey, enabled);
  }

  Future<void> saveLongBreakSettings({
    required bool enabled,
    required int durationSeconds,
    required int everyCycles,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(longBreakEnabledKey, enabled);
    await prefs.setInt(longBreakDurationSecondsKey, durationSeconds);
    await prefs.setInt(longBreakEveryCyclesKey, everyCycles);
  }

  Future<void> saveStreakCount(int streakCount) async {
    final prefs = await SharedPreferences.getInstance();
    final today = _dateKey(DateTime.now());
    await prefs.setString(streakDateKey, today);
    await prefs.setInt(streakCountKey, streakCount);
    await _saveHistoryCount(prefs, today, streakCount);
  }

  Map<String, int> _historyFromPrefs(SharedPreferences prefs) {
    final rawHistory = prefs.getString(dailyHistoryKey);
    if (rawHistory == null || rawHistory.isEmpty) {
      return <String, int>{};
    }

    final Object? decoded;
    try {
      decoded = jsonDecode(rawHistory);
    } on FormatException {
      return <String, int>{};
    }

    if (decoded is! Map<String, dynamic>) {
      return <String, int>{};
    }

    return decoded.map(
      (key, value) =>
          MapEntry(key, value is int ? value : int.tryParse('$value') ?? 0),
    );
  }

  Future<void> _saveHistoryCount(
    SharedPreferences prefs,
    String dateKey,
    int count,
  ) async {
    final history = _historyFromPrefs(prefs);
    if (count <= 0) {
      history.remove(dateKey);
    } else {
      history[dateKey] = count;
    }
    await prefs.setString(dailyHistoryKey, jsonEncode(history));
  }

  ThemeMode _themeModeFromString(String? value) {
    return switch (value) {
      'dark' => ThemeMode.dark,
      'system' => ThemeMode.system,
      _ => ThemeMode.light,
    };
  }

  String _themeModeToString(ThemeMode themeMode) {
    return switch (themeMode) {
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
      ThemeMode.light => 'light',
    };
  }

  DateTime? _dateTimeFromMillis(int? millisecondsSinceEpoch) {
    if (millisecondsSinceEpoch == null) {
      return null;
    }
    return DateTime.fromMillisecondsSinceEpoch(millisecondsSinceEpoch);
  }

  Future<void> _setOptionalDateTime(
    SharedPreferences prefs,
    String key,
    DateTime? value,
  ) {
    if (value == null) {
      return prefs.remove(key);
    }
    return prefs.setInt(key, value.millisecondsSinceEpoch);
  }

  String _dateKey(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }
}
