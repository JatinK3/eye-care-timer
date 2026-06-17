import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/timer_settings.dart';

class PreferencesService {
  static const String workDurationSecondsKey = 'workDurationSeconds';
  static const String breakDurationSecondsKey = 'breakDurationSeconds';
  static const String themeModeKey = 'themeMode';
  static const String colorPresetKey = 'colorPreset';
  static const String streakCountKey = 'streakCount';
  static const String streakDateKey = 'streakDate';

  Future<TimerSettings> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final today = _dateKey(DateTime.now());
    final savedStreakDate = prefs.getString(streakDateKey);
    var streakCount = prefs.getInt(streakCountKey) ?? 0;

    if (savedStreakDate != today) {
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
    );
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

  Future<void> saveStreakCount(int streakCount) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(streakDateKey, _dateKey(DateTime.now()));
    await prefs.setInt(streakCountKey, streakCount);
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

  String _dateKey(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }
}
