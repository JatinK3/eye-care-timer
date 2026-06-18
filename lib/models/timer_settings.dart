import 'package:flutter/material.dart';

class TimerSettings {
  static const int defaultWorkDurationSeconds = 20 * 60;
  static const int defaultBreakDurationSeconds = 20;
  static const String defaultColorPreset = 'Pastel';
  static const int defaultLongBreakDurationSeconds = 5 * 60;
  static const int defaultLongBreakEveryCycles = 4;

  final int workDurationSeconds;
  final int breakDurationSeconds;
  final ThemeMode themeMode;
  final String colorPreset;
  final int streakCount;
  final int dailyGoal;
  final bool notificationsEnabled;
  final bool hapticsEnabled;
  final bool soundEnabled;
  final bool longBreakEnabled;
  final int longBreakDurationSeconds;
  final int longBreakEveryCycles;
  final bool autoRunEnabled;
  final int autoRunCycleLimit;

  const TimerSettings({
    required this.workDurationSeconds,
    required this.breakDurationSeconds,
    required this.themeMode,
    required this.colorPreset,
    required this.streakCount,
    required this.dailyGoal,
    required this.notificationsEnabled,
    required this.hapticsEnabled,
    required this.soundEnabled,
    required this.longBreakEnabled,
    required this.longBreakDurationSeconds,
    required this.longBreakEveryCycles,
    required this.autoRunEnabled,
    required this.autoRunCycleLimit,
  });

  const TimerSettings.defaults()
    : workDurationSeconds = defaultWorkDurationSeconds,
      breakDurationSeconds = defaultBreakDurationSeconds,
      themeMode = ThemeMode.light,
      colorPreset = defaultColorPreset,
      streakCount = 0,
      dailyGoal = 6,
      notificationsEnabled = true,
      hapticsEnabled = true,
      soundEnabled = false,
      longBreakEnabled = false,
      longBreakDurationSeconds = defaultLongBreakDurationSeconds,
      longBreakEveryCycles = defaultLongBreakEveryCycles,
      autoRunEnabled = false,
      autoRunCycleLimit = 0;

  TimerSettings copyWith({
    int? workDurationSeconds,
    int? breakDurationSeconds,
    ThemeMode? themeMode,
    String? colorPreset,
    int? streakCount,
    int? dailyGoal,
    bool? notificationsEnabled,
    bool? hapticsEnabled,
    bool? soundEnabled,
    bool? longBreakEnabled,
    int? longBreakDurationSeconds,
    int? longBreakEveryCycles,
    bool? autoRunEnabled,
    int? autoRunCycleLimit,
  }) {
    return TimerSettings(
      workDurationSeconds: workDurationSeconds ?? this.workDurationSeconds,
      breakDurationSeconds: breakDurationSeconds ?? this.breakDurationSeconds,
      themeMode: themeMode ?? this.themeMode,
      colorPreset: colorPreset ?? this.colorPreset,
      streakCount: streakCount ?? this.streakCount,
      dailyGoal: dailyGoal ?? this.dailyGoal,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      longBreakEnabled: longBreakEnabled ?? this.longBreakEnabled,
      longBreakDurationSeconds:
          longBreakDurationSeconds ?? this.longBreakDurationSeconds,
      longBreakEveryCycles: longBreakEveryCycles ?? this.longBreakEveryCycles,
      autoRunEnabled: autoRunEnabled ?? this.autoRunEnabled,
      autoRunCycleLimit: autoRunCycleLimit ?? this.autoRunCycleLimit,
    );
  }
}
