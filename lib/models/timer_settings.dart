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
  static const String defaultBreakVisualizerStyle = 'Random';
  static const bool defaultBreakShowClock = true;
  static const bool defaultBreakShowTips = true;
  static const bool defaultBreakShowProgress = true;
  static const String defaultBreakCustomMessage = '';
  static const String defaultChimeStyle = 'tibetan_bowl';
  static const bool defaultBlinkRemindersEnabled = true;
  static const int defaultBlinkRemindersCadenceSeconds = 120;
  static const bool defaultTrayBlinkNudgesEnabled = true;
  static const int defaultTrayBlinkNudgeCadenceSeconds = 60;
  static const bool defaultWorkHoursEnabled = false;
  static const int defaultWorkHoursStartHour = 9;
  static const int defaultWorkHoursStartMinute = 0;
  static const int defaultWorkHoursEndHour = 18;
  static const int defaultWorkHoursEndMinute = 0;
  static const String defaultWorkDays = '1,2,3,4,5';
  static const bool defaultNaturalBreakCreditEnabled = true;
  static const bool defaultAmoledDarkEnabled = false;
  static const String defaultCustomAccentColorHex = '#009688';
  static const bool defaultUseSystemAccent = false;
  static const bool defaultStartMinimized = false;
  static const bool defaultAutoStartSchedule = false;
  static const bool defaultAiMotivationEnabled = false;
  static const bool defaultOsFocusDndEnabled = false;
  static const bool defaultBlinkReminderAiEnabled = true;
  static const String defaultBlinkReminderCustomMessage = '';
  static const bool defaultCameraMicAutoPostponeEnabled = false;
  static const bool defaultWellnessRemindersEnabled = false;
  static const bool defaultAutoPauseOnMediaEnabled = false;
  static const int defaultWellnessReminderCadenceSeconds = 3600;
  static const bool defaultBlinkReminderInteractiveEnabled = true;
  static const String defaultAiProvider = 'Gemini';
  static const String defaultAiApiKey = '';
  static const String defaultAiModel = 'gemini-1.5-flash';
  static const String defaultAiCustomSystemPrompt =
      'You are a friendly health and wellness assistant for a developer. Generate a very short, warm, and highly engaging health tip or motivational quote (strict limit of 25 words) encouraging them to blink, rest their eyes, stretch their body/legs/shoulders, stand up, drink water regularly, or take a deep breath. Keep it fresh, productive, encouraging, and extremely punchy.';
  static const int defaultMaxConsecutiveSkips = 0; // 0 means no limit
  static const String defaultActiveProfile = 'standard';
  static const String defaultAutoPostponeApps = '';

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
  final bool breakShowClock;
  final bool breakShowTips;
  final bool breakShowProgress;
  final String breakCustomMessage;
  final String chimeStyle;
  final bool blinkRemindersEnabled;
  final int blinkRemindersCadenceSeconds;
  final bool trayBlinkNudgesEnabled;
  final int trayBlinkNudgeCadenceSeconds;
  final bool workHoursEnabled;
  final int workHoursStartHour;
  final int workHoursStartMinute;
  final int workHoursEndHour;
  final int workHoursEndMinute;
  final String workDays;
  final bool naturalBreakCreditEnabled;
  final bool amoledDarkEnabled;
  final String customAccentColorHex;
  final bool useSystemAccent;
  final bool startMinimized;
  final bool autoStartSchedule;
  final bool aiMotivationEnabled;
  final bool osFocusDndEnabled;
  final String aiProvider;
  final String aiApiKey;
  final String aiModel;
  final String aiCustomSystemPrompt;
  final bool blinkReminderAiEnabled;
  final String blinkReminderCustomMessage;
  final bool cameraMicAutoPostponeEnabled;
  final bool wellnessRemindersEnabled;
  final int wellnessReminderCadenceSeconds;
  final bool blinkReminderInteractiveEnabled;
  final int maxConsecutiveSkips;
  final bool autoPauseOnMediaEnabled;
  final String activeProfile;
  final String autoPostponeApps;

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
    required this.breakShowClock,
    required this.breakShowTips,
    required this.breakShowProgress,
    required this.breakCustomMessage,
    required this.chimeStyle,
    required this.blinkRemindersEnabled,
    required this.blinkRemindersCadenceSeconds,
    required this.trayBlinkNudgesEnabled,
    required this.trayBlinkNudgeCadenceSeconds,
    required this.workHoursEnabled,
    required this.workHoursStartHour,
    required this.maxConsecutiveSkips,
    required this.workHoursStartMinute,
    required this.workHoursEndHour,
    required this.workHoursEndMinute,
    required this.workDays,
    required this.naturalBreakCreditEnabled,
    required this.amoledDarkEnabled,
    required this.customAccentColorHex,
    required this.useSystemAccent,
    required this.startMinimized,
    required this.autoStartSchedule,
    required this.aiMotivationEnabled,
    required this.osFocusDndEnabled,
    required this.aiProvider,
    required this.aiApiKey,
    required this.aiModel,
    required this.aiCustomSystemPrompt,
    required this.blinkReminderAiEnabled,
    required this.blinkReminderCustomMessage,
    required this.cameraMicAutoPostponeEnabled,
    required this.wellnessRemindersEnabled,
    required this.wellnessReminderCadenceSeconds,
    required this.blinkReminderInteractiveEnabled,
    required this.autoPauseOnMediaEnabled,
    required this.activeProfile,
    required this.autoPostponeApps,
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
      soundEnabled = true,
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
      breakShowClock = defaultBreakShowClock,
      breakShowTips = defaultBreakShowTips,
      breakShowProgress = defaultBreakShowProgress,
      breakCustomMessage = defaultBreakCustomMessage,
      chimeStyle = defaultChimeStyle,
      blinkRemindersEnabled = defaultBlinkRemindersEnabled,
      blinkRemindersCadenceSeconds = defaultBlinkRemindersCadenceSeconds,
      trayBlinkNudgesEnabled = defaultTrayBlinkNudgesEnabled,
      trayBlinkNudgeCadenceSeconds = defaultTrayBlinkNudgeCadenceSeconds,
      workHoursEnabled = defaultWorkHoursEnabled,
      workHoursStartHour = defaultWorkHoursStartHour,
      workHoursStartMinute = defaultWorkHoursStartMinute,
      workHoursEndHour = defaultWorkHoursEndHour,
      workHoursEndMinute = defaultWorkHoursEndMinute,
      workDays = defaultWorkDays,
      naturalBreakCreditEnabled = defaultNaturalBreakCreditEnabled,
      amoledDarkEnabled = defaultAmoledDarkEnabled,
      customAccentColorHex = defaultCustomAccentColorHex,
      useSystemAccent = defaultUseSystemAccent,
      startMinimized = defaultStartMinimized,
      autoStartSchedule = defaultAutoStartSchedule,
      aiMotivationEnabled = defaultAiMotivationEnabled,
      osFocusDndEnabled = defaultOsFocusDndEnabled,
      aiProvider = defaultAiProvider,
      aiApiKey = defaultAiApiKey,
      aiModel = defaultAiModel,
      aiCustomSystemPrompt = defaultAiCustomSystemPrompt,
      blinkReminderAiEnabled = defaultBlinkReminderAiEnabled,
      blinkReminderCustomMessage = defaultBlinkReminderCustomMessage,
      cameraMicAutoPostponeEnabled = defaultCameraMicAutoPostponeEnabled,
      wellnessRemindersEnabled = defaultWellnessRemindersEnabled,
      wellnessReminderCadenceSeconds = defaultWellnessReminderCadenceSeconds,
      blinkReminderInteractiveEnabled = defaultBlinkReminderInteractiveEnabled,
      maxConsecutiveSkips = defaultMaxConsecutiveSkips,
      autoPauseOnMediaEnabled = defaultAutoPauseOnMediaEnabled,
      activeProfile = defaultActiveProfile,
      autoPostponeApps = defaultAutoPostponeApps;

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
    bool? breakShowClock,
    bool? breakShowTips,
    bool? breakShowProgress,
    String? breakCustomMessage,
    String? chimeStyle,
    bool? blinkRemindersEnabled,
    int? blinkRemindersCadenceSeconds,
    bool? trayBlinkNudgesEnabled,
    int? trayBlinkNudgeCadenceSeconds,
    bool? workHoursEnabled,
    int? workHoursStartHour,
    int? workHoursStartMinute,
    int? workHoursEndHour,
    int? workHoursEndMinute,
    String? workDays,
    bool? naturalBreakCreditEnabled,
    bool? amoledDarkEnabled,
    String? customAccentColorHex,
    bool? useSystemAccent,
    bool? startMinimized,
    bool? autoStartSchedule,
    bool? aiMotivationEnabled,
    bool? osFocusDndEnabled,
    String? aiProvider,
    String? aiApiKey,
    String? aiModel,
    String? aiCustomSystemPrompt,
    bool? blinkReminderAiEnabled,
    String? blinkReminderCustomMessage,
    bool? cameraMicAutoPostponeEnabled,
    bool? wellnessRemindersEnabled,
    int? wellnessReminderCadenceSeconds,
    bool? blinkReminderInteractiveEnabled,
    int? maxConsecutiveSkips,
    bool? autoPauseOnMediaEnabled,
    String? activeProfile,
    String? autoPostponeApps,
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
      breakShowClock: breakShowClock ?? this.breakShowClock,
      breakShowTips: breakShowTips ?? this.breakShowTips,
      breakShowProgress: breakShowProgress ?? this.breakShowProgress,
      breakCustomMessage: breakCustomMessage ?? this.breakCustomMessage,
      chimeStyle: chimeStyle ?? this.chimeStyle,
      blinkRemindersEnabled:
          blinkRemindersEnabled ?? this.blinkRemindersEnabled,
      blinkRemindersCadenceSeconds:
          blinkRemindersCadenceSeconds ?? this.blinkRemindersCadenceSeconds,
      trayBlinkNudgesEnabled:
          trayBlinkNudgesEnabled ?? this.trayBlinkNudgesEnabled,
      trayBlinkNudgeCadenceSeconds:
          trayBlinkNudgeCadenceSeconds ?? this.trayBlinkNudgeCadenceSeconds,
      workHoursEnabled: workHoursEnabled ?? this.workHoursEnabled,
      workHoursStartHour: workHoursStartHour ?? this.workHoursStartHour,
      workHoursStartMinute: workHoursStartMinute ?? this.workHoursStartMinute,
      workHoursEndHour: workHoursEndHour ?? this.workHoursEndHour,
      workHoursEndMinute: workHoursEndMinute ?? this.workHoursEndMinute,
      workDays: workDays ?? this.workDays,
      naturalBreakCreditEnabled:
          naturalBreakCreditEnabled ?? this.naturalBreakCreditEnabled,
      amoledDarkEnabled: amoledDarkEnabled ?? this.amoledDarkEnabled,
      customAccentColorHex: customAccentColorHex ?? this.customAccentColorHex,
      useSystemAccent: useSystemAccent ?? this.useSystemAccent,
      startMinimized: startMinimized ?? this.startMinimized,
      autoStartSchedule: autoStartSchedule ?? this.autoStartSchedule,
      aiMotivationEnabled: aiMotivationEnabled ?? this.aiMotivationEnabled,
      osFocusDndEnabled: osFocusDndEnabled ?? this.osFocusDndEnabled,
      aiProvider: aiProvider ?? this.aiProvider,
      aiApiKey: aiApiKey ?? this.aiApiKey,
      aiModel: aiModel ?? this.aiModel,
      aiCustomSystemPrompt: aiCustomSystemPrompt ?? this.aiCustomSystemPrompt,
      blinkReminderAiEnabled:
          blinkReminderAiEnabled ?? this.blinkReminderAiEnabled,
      blinkReminderCustomMessage:
          blinkReminderCustomMessage ?? this.blinkReminderCustomMessage,
      cameraMicAutoPostponeEnabled:
          cameraMicAutoPostponeEnabled ?? this.cameraMicAutoPostponeEnabled,
      wellnessRemindersEnabled:
          wellnessRemindersEnabled ?? this.wellnessRemindersEnabled,
      wellnessReminderCadenceSeconds:
          wellnessReminderCadenceSeconds ?? this.wellnessReminderCadenceSeconds,
      blinkReminderInteractiveEnabled:
          blinkReminderInteractiveEnabled ??
          this.blinkReminderInteractiveEnabled,
      maxConsecutiveSkips: maxConsecutiveSkips ?? this.maxConsecutiveSkips,
      autoPauseOnMediaEnabled:
          autoPauseOnMediaEnabled ?? this.autoPauseOnMediaEnabled,
      activeProfile: activeProfile ?? this.activeProfile,
      autoPostponeApps: autoPostponeApps ?? this.autoPostponeApps,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'workDurationSeconds': workDurationSeconds,
      'breakDurationSeconds': breakDurationSeconds,
      'themeMode': themeMode.name,
      'colorPreset': colorPreset,
      'dailyGoal': dailyGoal,
      'notificationsEnabled': notificationsEnabled,
      'hapticsEnabled': hapticsEnabled,
      'soundEnabled': soundEnabled,
      'longBreakEnabled': longBreakEnabled,
      'longBreakDurationSeconds': longBreakDurationSeconds,
      'longBreakEveryCycles': longBreakEveryCycles,
      'autoRunEnabled': autoRunEnabled,
      'autoRunCycleLimit': autoRunCycleLimit,
      'breakMode': breakMode.name,
      'allowSkip': allowSkip,
      'allowPostpone': allowPostpone,
      'postponeDurationSeconds': postponeDurationSeconds,
      'smartIdleEnabled': smartIdleEnabled,
      'breakVisualizerStyle': breakVisualizerStyle,
      'breakShowClock': breakShowClock,
      'breakShowTips': breakShowTips,
      'breakShowProgress': breakShowProgress,
      'breakCustomMessage': breakCustomMessage,
      'chimeStyle': chimeStyle,
      'blinkRemindersEnabled': blinkRemindersEnabled,
      'blinkRemindersCadenceSeconds': blinkRemindersCadenceSeconds,
      'trayBlinkNudgesEnabled': trayBlinkNudgesEnabled,
      'trayBlinkNudgeCadenceSeconds': trayBlinkNudgeCadenceSeconds,
      'workHoursEnabled': workHoursEnabled,
      'workHoursStartHour': workHoursStartHour,
      'workHoursStartMinute': workHoursStartMinute,
      'workHoursEndHour': workHoursEndHour,
      'workHoursEndMinute': workHoursEndMinute,
      'workDays': workDays,
      'naturalBreakCreditEnabled': naturalBreakCreditEnabled,
      'amoledDarkEnabled': amoledDarkEnabled,
      'customAccentColorHex': customAccentColorHex,
      'useSystemAccent': useSystemAccent,
      'startMinimized': startMinimized,
      'autoStartSchedule': autoStartSchedule,
      'aiMotivationEnabled': aiMotivationEnabled,
      'osFocusDndEnabled': osFocusDndEnabled,
      'aiProvider': aiProvider,
      'aiApiKey': aiApiKey,
      'aiModel': aiModel,
      'aiCustomSystemPrompt': aiCustomSystemPrompt,
      'blinkReminderAiEnabled': blinkReminderAiEnabled,
      'blinkReminderCustomMessage': blinkReminderCustomMessage,
      'cameraMicAutoPostponeEnabled': cameraMicAutoPostponeEnabled,
      'wellnessRemindersEnabled': wellnessRemindersEnabled,
      'wellnessReminderCadenceSeconds': wellnessReminderCadenceSeconds,
      'blinkReminderInteractiveEnabled': blinkReminderInteractiveEnabled,
      'maxConsecutiveSkips': maxConsecutiveSkips,
      'autoPauseOnMediaEnabled': autoPauseOnMediaEnabled,
      'activeProfile': activeProfile,
      'autoPostponeApps': autoPostponeApps,
    };
  }

  static TimerSettings fromJson(
    Map<String, dynamic> json, {
    int currentStreak = 0,
  }) {
    return TimerSettings(
      workDurationSeconds:
          json['workDurationSeconds'] as int? ?? defaultWorkDurationSeconds,
      breakDurationSeconds:
          json['breakDurationSeconds'] as int? ?? defaultBreakDurationSeconds,
      themeMode: _parseThemeMode(json['themeMode']),
      colorPreset: json['colorPreset'] as String? ?? defaultColorPreset,
      streakCount: currentStreak,
      dailyGoal: json['dailyGoal'] as int? ?? 6,
      notificationsEnabled: json['notificationsEnabled'] as bool? ?? true,
      hapticsEnabled: json['hapticsEnabled'] as bool? ?? true,
      soundEnabled: json['soundEnabled'] as bool? ?? false,
      longBreakEnabled: json['longBreakEnabled'] as bool? ?? false,
      longBreakDurationSeconds:
          json['longBreakDurationSeconds'] as int? ??
          defaultLongBreakDurationSeconds,
      longBreakEveryCycles:
          json['longBreakEveryCycles'] as int? ?? defaultLongBreakEveryCycles,
      autoRunEnabled: json['autoRunEnabled'] as bool? ?? false,
      autoRunCycleLimit: json['autoRunCycleLimit'] as int? ?? 0,
      breakMode: _parseBreakMode(json['breakMode']),
      allowSkip: json['allowSkip'] as bool? ?? defaultAllowSkip,
      allowPostpone: json['allowPostpone'] as bool? ?? defaultAllowPostpone,
      postponeDurationSeconds:
          json['postponeDurationSeconds'] as int? ??
          defaultPostponeDurationSeconds,
      smartIdleEnabled:
          json['smartIdleEnabled'] as bool? ?? defaultSmartIdleEnabled,
      breakVisualizerStyle:
          json['breakVisualizerStyle'] as String? ??
          defaultBreakVisualizerStyle,
      breakShowClock: json['breakShowClock'] as bool? ?? defaultBreakShowClock,
      breakShowTips: json['breakShowTips'] as bool? ?? defaultBreakShowTips,
      breakShowProgress:
          json['breakShowProgress'] as bool? ?? defaultBreakShowProgress,
      breakCustomMessage:
          json['breakCustomMessage'] as String? ?? defaultBreakCustomMessage,
      chimeStyle: json['chimeStyle'] as String? ?? defaultChimeStyle,
      blinkRemindersEnabled:
          json['blinkRemindersEnabled'] as bool? ??
          defaultBlinkRemindersEnabled,
      blinkRemindersCadenceSeconds:
          json['blinkRemindersCadenceSeconds'] as int? ??
          defaultBlinkRemindersCadenceSeconds,
      blinkReminderInteractiveEnabled:
          json['blinkReminderInteractiveEnabled'] as bool? ??
          defaultBlinkReminderInteractiveEnabled,
      maxConsecutiveSkips:
          json['maxConsecutiveSkips'] as int? ?? defaultMaxConsecutiveSkips,
      trayBlinkNudgesEnabled:
          json['trayBlinkNudgesEnabled'] as bool? ??
          defaultTrayBlinkNudgesEnabled,
      trayBlinkNudgeCadenceSeconds:
          json['trayBlinkNudgeCadenceSeconds'] as int? ??
          defaultTrayBlinkNudgeCadenceSeconds,
      workHoursEnabled:
          json['workHoursEnabled'] as bool? ?? defaultWorkHoursEnabled,
      workHoursStartHour:
          json['workHoursStartHour'] as int? ?? defaultWorkHoursStartHour,
      workHoursStartMinute:
          json['workHoursStartMinute'] as int? ?? defaultWorkHoursStartMinute,
      workHoursEndHour:
          json['workHoursEndHour'] as int? ?? defaultWorkHoursEndHour,
      workHoursEndMinute:
          json['workHoursEndMinute'] as int? ?? defaultWorkHoursEndMinute,
      workDays: json['workDays'] as String? ?? defaultWorkDays,
      naturalBreakCreditEnabled:
          json['naturalBreakCreditEnabled'] as bool? ??
          defaultNaturalBreakCreditEnabled,
      amoledDarkEnabled:
          json['amoledDarkEnabled'] as bool? ?? defaultAmoledDarkEnabled,
      customAccentColorHex:
          json['customAccentColorHex'] as String? ??
          defaultCustomAccentColorHex,
      useSystemAccent:
          json['useSystemAccent'] as bool? ?? defaultUseSystemAccent,
      startMinimized: json['startMinimized'] as bool? ?? defaultStartMinimized,
      autoStartSchedule:
          json['autoStartSchedule'] as bool? ?? defaultAutoStartSchedule,
      aiMotivationEnabled:
          json['aiMotivationEnabled'] as bool? ?? defaultAiMotivationEnabled,
      osFocusDndEnabled:
          json['osFocusDndEnabled'] as bool? ?? defaultOsFocusDndEnabled,
      aiProvider: json['aiProvider'] as String? ?? defaultAiProvider,
      aiApiKey: json['aiApiKey'] as String? ?? defaultAiApiKey,
      aiModel: json['aiModel'] as String? ?? defaultAiModel,
      aiCustomSystemPrompt:
          json['aiCustomSystemPrompt'] as String? ??
          defaultAiCustomSystemPrompt,
      blinkReminderAiEnabled:
          json['blinkReminderAiEnabled'] as bool? ??
          defaultBlinkReminderAiEnabled,
      blinkReminderCustomMessage:
          json['blinkReminderCustomMessage'] as String? ??
          defaultBlinkReminderCustomMessage,
      cameraMicAutoPostponeEnabled:
          json['cameraMicAutoPostponeEnabled'] as bool? ??
          defaultCameraMicAutoPostponeEnabled,
      wellnessRemindersEnabled:
          json['wellnessRemindersEnabled'] as bool? ??
          defaultWellnessRemindersEnabled,
      wellnessReminderCadenceSeconds:
          json['wellnessReminderCadenceSeconds'] as int? ??
          defaultWellnessReminderCadenceSeconds,
      autoPauseOnMediaEnabled:
          json['autoPauseOnMediaEnabled'] as bool? ??
          defaultAutoPauseOnMediaEnabled,
      activeProfile: json['activeProfile'] as String? ?? defaultActiveProfile,
      autoPostponeApps: json['autoPostponeApps'] as String? ?? defaultAutoPostponeApps,
    );
  }

  static ThemeMode _parseThemeMode(dynamic value) {
    if (value is String) {
      for (final mode in ThemeMode.values) {
        if (mode.name == value) return mode;
      }
    }
    return ThemeMode.light;
  }

  static BreakMode _parseBreakMode(dynamic value) {
    if (value is String) {
      for (final mode in BreakMode.values) {
        if (mode.name == value) return mode;
      }
    }
    return BreakMode.gentle;
  }
}
