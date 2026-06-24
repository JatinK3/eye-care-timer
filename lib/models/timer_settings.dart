import 'package:flutter/material.dart';

enum BreakMode { off, gentle, strict }

class TimerSettings {
  static const int defaultWorkDurationSeconds = 20 * 60;
  static const int defaultBreakDurationSeconds = 20;
  static const String defaultColorPreset = 'Pastel';
  static const int defaultLongBreakDurationSeconds = 5 * 60;
  static const int defaultLongBreakEveryCycles = 4;
  static const BreakMode defaultBreakMode = BreakMode.gentle;

  static const bool defaultAllowSkip = true;
  static const bool defaultAllowPostpone = true;
  static const int defaultPostponeDurationSeconds = 2 * 60;
  static const bool defaultSmartIdleEnabled = true;
  static const String defaultBreakVisualizerStyle = 'Breathing';
  static const String defaultChimeStyle = 'tibetan_bowl';
  static const bool defaultBlinkRemindersEnabled = false;
  static const int defaultBlinkRemindersCadenceSeconds = 5;
  static const bool defaultWorkHoursEnabled = false;
  static const int defaultWorkHoursStartHour = 9;
  static const int defaultWorkHoursStartMinute = 0;
  static const int defaultWorkHoursEndHour = 18;
  static const int defaultWorkHoursEndMinute = 0;
  static const String defaultWorkDays = '1,2,3,4,5';
  static const bool defaultNaturalBreakCreditEnabled = true;

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
  final BreakMode breakMode;
  final bool allowSkip;
  final bool allowPostpone;
  final int postponeDurationSeconds;
  final bool smartIdleEnabled;
  final String breakVisualizerStyle;
  final String chimeStyle;
  final bool blinkRemindersEnabled;
  final int blinkRemindersCadenceSeconds;
  final bool workHoursEnabled;
  final int workHoursStartHour;
  final int workHoursStartMinute;
  final int workHoursEndHour;
  final int workHoursEndMinute;
  final String workDays;
  final bool naturalBreakCreditEnabled;

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
    required this.breakMode,
    required this.allowSkip,
    required this.allowPostpone,
    required this.postponeDurationSeconds,
    required this.smartIdleEnabled,
    required this.breakVisualizerStyle,
    required this.chimeStyle,
    required this.blinkRemindersEnabled,
    required this.blinkRemindersCadenceSeconds,
    required this.workHoursEnabled,
    required this.workHoursStartHour,
    required this.workHoursStartMinute,
    required this.workHoursEndHour,
    required this.workHoursEndMinute,
    required this.workDays,
    required this.naturalBreakCreditEnabled,
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
      autoRunCycleLimit = 0,
      breakMode = defaultBreakMode,
      allowSkip = defaultAllowSkip,
      allowPostpone = defaultAllowPostpone,
      postponeDurationSeconds = defaultPostponeDurationSeconds,
      smartIdleEnabled = defaultSmartIdleEnabled,
      breakVisualizerStyle = defaultBreakVisualizerStyle,
      chimeStyle = defaultChimeStyle,
      blinkRemindersEnabled = defaultBlinkRemindersEnabled,
      blinkRemindersCadenceSeconds = defaultBlinkRemindersCadenceSeconds,
      workHoursEnabled = defaultWorkHoursEnabled,
      workHoursStartHour = defaultWorkHoursStartHour,
      workHoursStartMinute = defaultWorkHoursStartMinute,
      workHoursEndHour = defaultWorkHoursEndHour,
      workHoursEndMinute = defaultWorkHoursEndMinute,
      workDays = defaultWorkDays,
      naturalBreakCreditEnabled = defaultNaturalBreakCreditEnabled;

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
    BreakMode? breakMode,
    bool? allowSkip,
    bool? allowPostpone,
    int? postponeDurationSeconds,
    bool? smartIdleEnabled,
    String? breakVisualizerStyle,
    String? chimeStyle,
    bool? blinkRemindersEnabled,
    int? blinkRemindersCadenceSeconds,
    bool? workHoursEnabled,
    int? workHoursStartHour,
    int? workHoursStartMinute,
    int? workHoursEndHour,
    int? workHoursEndMinute,
    String? workDays,
    bool? naturalBreakCreditEnabled,
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
      breakMode: breakMode ?? this.breakMode,
      allowSkip: allowSkip ?? this.allowSkip,
      allowPostpone: allowPostpone ?? this.allowPostpone,
      postponeDurationSeconds:
          postponeDurationSeconds ?? this.postponeDurationSeconds,
      smartIdleEnabled: smartIdleEnabled ?? this.smartIdleEnabled,
      breakVisualizerStyle: breakVisualizerStyle ?? this.breakVisualizerStyle,
      chimeStyle: chimeStyle ?? this.chimeStyle,
      blinkRemindersEnabled:
          blinkRemindersEnabled ?? this.blinkRemindersEnabled,
      blinkRemindersCadenceSeconds:
          blinkRemindersCadenceSeconds ?? this.blinkRemindersCadenceSeconds,
      workHoursEnabled: workHoursEnabled ?? this.workHoursEnabled,
      workHoursStartHour: workHoursStartHour ?? this.workHoursStartHour,
      workHoursStartMinute: workHoursStartMinute ?? this.workHoursStartMinute,
      workHoursEndHour: workHoursEndHour ?? this.workHoursEndHour,
      workHoursEndMinute: workHoursEndMinute ?? this.workHoursEndMinute,
      workDays: workDays ?? this.workDays,
      naturalBreakCreditEnabled:
          naturalBreakCreditEnabled ?? this.naturalBreakCreditEnabled,
    );
  }
}
