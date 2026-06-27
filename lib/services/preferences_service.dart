import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/timer_session.dart';
import '../models/timer_settings.dart';
import '../models/timer_event_record.dart';
import '../models/work_session_record.dart';

class PreferencesService {
  static const String timerEventsHistoryKey = 'timerEventsHistory';
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
  static const String autoRunEnabledKey = 'autoRunEnabled';
  static const String autoRunCycleLimitKey = 'autoRunCycleLimit';
  static const String onboardingCompletedKey = 'onboardingCompleted';
  static const String breakModeKey = 'breakMode';
  static const String allowSkipKey = 'allowSkip';
  static const String allowPostponeKey = 'allowPostpone';
  static const String postponeDurationSecondsKey = 'postponeDurationSeconds';
  static const String smartIdleEnabledKey = 'smartIdleEnabled';
  static const String breakVisualizerStyleKey = 'breakVisualizerStyle';
  static const String breakShowClockKey = 'breakShowClock';
  static const String breakShowTipsKey = 'breakShowTips';
  static const String breakShowProgressKey = 'breakShowProgress';
  static const String breakCustomMessageKey = 'breakCustomMessage';
  static const String chimeStyleKey = 'chimeStyle';
  static const String blinkRemindersEnabledKey = 'blinkRemindersEnabled';
  static const String blinkRemindersCadenceSecondsKey =
      'blinkRemindersCadenceSeconds';
  static const String trayBlinkNudgesEnabledKey = 'trayBlinkNudgesEnabled';
  static const String trayBlinkNudgeCadenceSecondsKey =
      'trayBlinkNudgeCadenceSeconds';
  static const String workHoursEnabledKey = 'workHoursEnabled';
  static const String workHoursStartHourKey = 'workHoursStartHour';
  static const String workHoursStartMinuteKey = 'workHoursStartMinute';
  static const String workHoursEndHourKey = 'workHoursEndHour';
  static const String workHoursEndMinuteKey = 'workHoursEndMinute';
  static const String workDaysKey = 'workDays';
  static const String naturalBreakCreditEnabledKey =
      'naturalBreakCreditEnabled';
  static const String dailyHistoryKey = 'dailyHistory';
  static const String workSessionHistoryKey = 'workSessionHistory';
  static const String sessionIsActiveKey = 'sessionIsActive';
  static const String sessionIsBreakKey = 'sessionIsBreak';
  static const String sessionIsPausedKey = 'sessionIsPaused';
  static const String sessionInitialDurationSecondsKey =
      'sessionInitialDurationSeconds';
  static const String sessionRemainingSecondsKey = 'sessionRemainingSeconds';
  static const String sessionPhaseStartedAtKey = 'sessionPhaseStartedAt';
  static const String sessionPhaseEndsAtKey = 'sessionPhaseEndsAt';
  static const String sessionCompletedAutoRunCyclesKey =
      'sessionCompletedAutoRunCycles';
  static const String amoledDarkEnabledKey = 'amoledDarkEnabled';
  static const String customAccentColorHexKey = 'customAccentColorHex';
  static const String useSystemAccentKey = 'useSystemAccent';
  static const String startMinimizedKey = 'startMinimized';
  static const String aiMotivationEnabledKey = 'aiMotivationEnabled';
  static const String aiProviderKey = 'aiProvider';
  static const String aiApiKeyKey = 'aiApiKey';
  static const String aiModelKey = 'aiModel';
  static const String aiCustomSystemPromptKey = 'aiCustomSystemPrompt';
  static const String autoStartScheduleKey = 'autoStartSchedule';
  static const String osFocusDndEnabledKey = 'osFocusDndEnabled';
  static const String blinkReminderAiEnabledKey = 'blinkReminderAiEnabled';
  static const String blinkReminderCustomMessageKey =
      'blinkReminderCustomMessage';
  static const String cameraMicAutoPostponeEnabledKey =
      'cameraMicAutoPostponeEnabled';
  static const String wellnessRemindersEnabledKey = 'wellnessRemindersEnabled';
  static const String wellnessReminderCadenceSecondsKey =
      'wellnessReminderCadenceSeconds';
  static const String blinkReminderInteractiveEnabledKey =
      'blinkReminderInteractiveEnabled';
  static const String maxConsecutiveSkipsKey = 'maxConsecutiveSkips';
  static const String autoPauseOnMediaEnabledKey = 'autoPauseOnMediaEnabled';

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
      soundEnabled: prefs.getBool(soundEnabledKey) ?? true,
      longBreakEnabled: prefs.getBool(longBreakEnabledKey) ?? false,
      longBreakDurationSeconds:
          prefs.getInt(longBreakDurationSecondsKey) ??
          TimerSettings.defaultLongBreakDurationSeconds,
      longBreakEveryCycles:
          prefs.getInt(longBreakEveryCyclesKey) ??
          TimerSettings.defaultLongBreakEveryCycles,
      autoRunEnabled: prefs.getBool(autoRunEnabledKey) ?? false,
      autoRunCycleLimit: prefs.getInt(autoRunCycleLimitKey) ?? 0,
      breakMode: _breakModeFromString(prefs.getString(breakModeKey)),
      allowSkip: prefs.getBool(allowSkipKey) ?? TimerSettings.defaultAllowSkip,
      allowPostpone:
          prefs.getBool(allowPostponeKey) ?? TimerSettings.defaultAllowPostpone,
      postponeDurationSeconds:
          prefs.getInt(postponeDurationSecondsKey) ??
          TimerSettings.defaultPostponeDurationSeconds,
      smartIdleEnabled:
          prefs.getBool(smartIdleEnabledKey) ??
          TimerSettings.defaultSmartIdleEnabled,
      breakVisualizerStyle:
          prefs.getString(breakVisualizerStyleKey) ??
          TimerSettings.defaultBreakVisualizerStyle,
      breakShowClock:
          prefs.getBool(breakShowClockKey) ??
          TimerSettings.defaultBreakShowClock,
      breakShowTips:
          prefs.getBool(breakShowTipsKey) ?? TimerSettings.defaultBreakShowTips,
      breakShowProgress:
          prefs.getBool(breakShowProgressKey) ??
          TimerSettings.defaultBreakShowProgress,
      breakCustomMessage:
          prefs.getString(breakCustomMessageKey) ??
          TimerSettings.defaultBreakCustomMessage,
      chimeStyle:
          prefs.getString(chimeStyleKey) ?? TimerSettings.defaultChimeStyle,
      blinkRemindersEnabled:
          prefs.getBool(blinkRemindersEnabledKey) ??
          TimerSettings.defaultBlinkRemindersEnabled,
      blinkRemindersCadenceSeconds:
          prefs.getInt(blinkRemindersCadenceSecondsKey) ??
          TimerSettings.defaultBlinkRemindersCadenceSeconds,
      trayBlinkNudgesEnabled:
          prefs.getBool(trayBlinkNudgesEnabledKey) ??
          TimerSettings.defaultTrayBlinkNudgesEnabled,
      trayBlinkNudgeCadenceSeconds:
          prefs.getInt(trayBlinkNudgeCadenceSecondsKey) ??
          TimerSettings.defaultTrayBlinkNudgeCadenceSeconds,
      workHoursEnabled:
          prefs.getBool(workHoursEnabledKey) ??
          TimerSettings.defaultWorkHoursEnabled,
      workHoursStartHour:
          prefs.getInt(workHoursStartHourKey) ??
          TimerSettings.defaultWorkHoursStartHour,
      workHoursStartMinute:
          prefs.getInt(workHoursStartMinuteKey) ??
          TimerSettings.defaultWorkHoursStartMinute,
      workHoursEndHour:
          prefs.getInt(workHoursEndHourKey) ??
          TimerSettings.defaultWorkHoursEndHour,
      workHoursEndMinute:
          prefs.getInt(workHoursEndMinuteKey) ??
          TimerSettings.defaultWorkHoursEndMinute,
      workDays: prefs.getString(workDaysKey) ?? TimerSettings.defaultWorkDays,
      naturalBreakCreditEnabled:
          prefs.getBool(naturalBreakCreditEnabledKey) ??
          TimerSettings.defaultNaturalBreakCreditEnabled,
      amoledDarkEnabled:
          prefs.getBool(amoledDarkEnabledKey) ??
          TimerSettings.defaultAmoledDarkEnabled,
      customAccentColorHex:
          prefs.getString(customAccentColorHexKey) ??
          TimerSettings.defaultCustomAccentColorHex,
      useSystemAccent:
          prefs.getBool(useSystemAccentKey) ??
          TimerSettings.defaultUseSystemAccent,
      startMinimized:
          prefs.getBool(startMinimizedKey) ??
          TimerSettings.defaultStartMinimized,
      aiMotivationEnabled:
          prefs.getBool(aiMotivationEnabledKey) ??
          TimerSettings.defaultAiMotivationEnabled,
      aiProvider:
          prefs.getString(aiProviderKey) ?? TimerSettings.defaultAiProvider,
      aiApiKey: prefs.getString(aiApiKeyKey) ?? TimerSettings.defaultAiApiKey,
      aiModel: prefs.getString(aiModelKey) ?? TimerSettings.defaultAiModel,
      aiCustomSystemPrompt: () {
        final saved = prefs.getString(aiCustomSystemPromptKey);
        if (saved == null) {
          return TimerSettings.defaultAiCustomSystemPrompt;
        }
        if (saved.contains('friendly eye-care assistant')) {
          return TimerSettings.defaultAiCustomSystemPrompt;
        }
        return saved;
      }(),
      autoStartSchedule:
          prefs.getBool(autoStartScheduleKey) ??
          TimerSettings.defaultAutoStartSchedule,
      osFocusDndEnabled:
          prefs.getBool(osFocusDndEnabledKey) ??
          TimerSettings.defaultOsFocusDndEnabled,
      blinkReminderAiEnabled:
          prefs.getBool(blinkReminderAiEnabledKey) ??
          TimerSettings.defaultBlinkReminderAiEnabled,
      blinkReminderCustomMessage:
          prefs.getString(blinkReminderCustomMessageKey) ??
          TimerSettings.defaultBlinkReminderCustomMessage,
      cameraMicAutoPostponeEnabled:
          prefs.getBool(cameraMicAutoPostponeEnabledKey) ??
          TimerSettings.defaultCameraMicAutoPostponeEnabled,
      wellnessRemindersEnabled:
          prefs.getBool(wellnessRemindersEnabledKey) ??
          TimerSettings.defaultWellnessRemindersEnabled,
      wellnessReminderCadenceSeconds:
          prefs.getInt(wellnessReminderCadenceSecondsKey) ??
          TimerSettings.defaultWellnessReminderCadenceSeconds,
      blinkReminderInteractiveEnabled:
          prefs.getBool(blinkReminderInteractiveEnabledKey) ??
          TimerSettings.defaultBlinkReminderInteractiveEnabled,
      autoPauseOnMediaEnabled:
          prefs.getBool(autoPauseOnMediaEnabledKey) ??
          TimerSettings.defaultAutoPauseOnMediaEnabled,
      maxConsecutiveSkips:
          prefs.getInt(maxConsecutiveSkipsKey) ??
          TimerSettings.defaultMaxConsecutiveSkips,
    );
  }

  Future<Map<String, int>> loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    return _historyFromPrefs(prefs);
  }

  Future<List<WorkSessionRecord>> loadWorkSessionHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final rawRecords = prefs.getString(workSessionHistoryKey);
    if (rawRecords == null || rawRecords.isEmpty) {
      return <WorkSessionRecord>[];
    }

    try {
      final decoded = jsonDecode(rawRecords);
      if (decoded is! List<dynamic>) return <WorkSessionRecord>[];
      final records = <WorkSessionRecord>[];
      for (final item in decoded) {
        if (item is! Map<String, dynamic>) continue;
        try {
          records.add(WorkSessionRecord.fromJson(item));
        } on Object {
          continue;
        }
      }
      records.sort((a, b) => b.completedAt.compareTo(a.completedAt));
      return records;
    } on FormatException {
      return <WorkSessionRecord>[];
    }
  }

  Future<List<WorkSessionRecord>> saveCompletedWorkSession(
    WorkSessionRecord record,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final records = await loadWorkSessionHistory();
    records.removeWhere((existing) => existing.id == record.id);
    records.insert(0, record);
    const maximumRecords = 500;
    final retained = records.length > maximumRecords
        ? records.sublist(0, maximumRecords)
        : records;
    await prefs.setString(
      workSessionHistoryKey,
      jsonEncode(retained.map((item) => item.toJson()).toList()),
    );
    return retained;
  }

  Future<List<TimerEventRecord>> loadTimerEventHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final rawRecords = prefs.getString(timerEventsHistoryKey);
    if (rawRecords == null || rawRecords.isEmpty) {
      return <TimerEventRecord>[];
    }

    try {
      final decoded = jsonDecode(rawRecords);
      if (decoded is! List<dynamic>) return <TimerEventRecord>[];
      final records = <TimerEventRecord>[];
      for (final item in decoded) {
        if (item is! Map<String, dynamic>) continue;
        try {
          records.add(TimerEventRecord.fromJson(item));
        } on Object {
          continue;
        }
      }
      records.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return records;
    } on FormatException {
      return <TimerEventRecord>[];
    }
  }

  Future<List<TimerEventRecord>> saveTimerEventRecord(
    TimerEventRecord record,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final records = await loadTimerEventHistory();
    records.removeWhere((existing) => existing.id == record.id);
    records.insert(0, record);
    const maximumRecords = 1000;
    final retained = records.length > maximumRecords
        ? records.sublist(0, maximumRecords)
        : records;
    await prefs.setString(
      timerEventsHistoryKey,
      jsonEncode(retained.map((item) => item.toJson()).toList()),
    );
    return retained;
  }

  Future<void> saveHistoryCount(String dateKey, int count) async {
    final prefs = await SharedPreferences.getInstance();
    await _saveHistoryCount(prefs, dateKey, count);
  }

  Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(dailyHistoryKey);
    await prefs.remove(workSessionHistoryKey);
    await prefs.remove(timerEventsHistoryKey);
  }

  Future<TimerSettings> resetToDefaultSettings(int currentStreak) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setInt(
      workDurationSecondsKey,
      TimerSettings.defaultWorkDurationSeconds,
    );
    await prefs.setInt(
      breakDurationSecondsKey,
      TimerSettings.defaultBreakDurationSeconds,
    );
    await prefs.setString(themeModeKey, _themeModeToString(ThemeMode.light));
    await prefs.setString(colorPresetKey, TimerSettings.defaultColorPreset);
    await prefs.setInt(dailyGoalKey, 6);
    await prefs.setBool(notificationsEnabledKey, true);
    await prefs.setBool(hapticsEnabledKey, true);
    await prefs.setBool(soundEnabledKey, false);
    await prefs.setBool(longBreakEnabledKey, false);
    await prefs.setInt(
      longBreakDurationSecondsKey,
      TimerSettings.defaultLongBreakDurationSeconds,
    );
    await prefs.setInt(
      longBreakEveryCyclesKey,
      TimerSettings.defaultLongBreakEveryCycles,
    );
    await prefs.setBool(autoRunEnabledKey, false);
    await prefs.setInt(autoRunCycleLimitKey, 0);
    await prefs.setString(
      breakModeKey,
      _breakModeToString(TimerSettings.defaultBreakMode),
    );
    await prefs.setBool(allowSkipKey, TimerSettings.defaultAllowSkip);
    await prefs.setBool(allowPostponeKey, TimerSettings.defaultAllowPostpone);
    await prefs.setInt(
      postponeDurationSecondsKey,
      TimerSettings.defaultPostponeDurationSeconds,
    );
    await prefs.setBool(
      smartIdleEnabledKey,
      TimerSettings.defaultSmartIdleEnabled,
    );
    await prefs.setString(
      breakVisualizerStyleKey,
      TimerSettings.defaultBreakVisualizerStyle,
    );
    await prefs.setBool(breakShowClockKey, TimerSettings.defaultBreakShowClock);
    await prefs.setBool(breakShowTipsKey, TimerSettings.defaultBreakShowTips);
    await prefs.setBool(
      breakShowProgressKey,
      TimerSettings.defaultBreakShowProgress,
    );
    await prefs.setString(
      breakCustomMessageKey,
      TimerSettings.defaultBreakCustomMessage,
    );
    await prefs.setString(chimeStyleKey, TimerSettings.defaultChimeStyle);
    await prefs.setBool(
      blinkRemindersEnabledKey,
      TimerSettings.defaultBlinkRemindersEnabled,
    );
    await prefs.setInt(
      blinkRemindersCadenceSecondsKey,
      TimerSettings.defaultBlinkRemindersCadenceSeconds,
    );
    await prefs.setBool(
      trayBlinkNudgesEnabledKey,
      TimerSettings.defaultTrayBlinkNudgesEnabled,
    );
    await prefs.setInt(
      trayBlinkNudgeCadenceSecondsKey,
      TimerSettings.defaultTrayBlinkNudgeCadenceSeconds,
    );
    await prefs.setBool(
      workHoursEnabledKey,
      TimerSettings.defaultWorkHoursEnabled,
    );
    await prefs.setInt(
      workHoursStartHourKey,
      TimerSettings.defaultWorkHoursStartHour,
    );
    await prefs.setInt(
      workHoursStartMinuteKey,
      TimerSettings.defaultWorkHoursStartMinute,
    );
    await prefs.setInt(
      workHoursEndHourKey,
      TimerSettings.defaultWorkHoursEndHour,
    );
    await prefs.setInt(
      workHoursEndMinuteKey,
      TimerSettings.defaultWorkHoursEndMinute,
    );
    await prefs.setString(workDaysKey, TimerSettings.defaultWorkDays);
    await prefs.setBool(
      naturalBreakCreditEnabledKey,
      TimerSettings.defaultNaturalBreakCreditEnabled,
    );
    await prefs.setBool(
      amoledDarkEnabledKey,
      TimerSettings.defaultAmoledDarkEnabled,
    );
    await prefs.setString(
      customAccentColorHexKey,
      TimerSettings.defaultCustomAccentColorHex,
    );
    await prefs.setBool(
      useSystemAccentKey,
      TimerSettings.defaultUseSystemAccent,
    );
    await prefs.setBool(startMinimizedKey, TimerSettings.defaultStartMinimized);
    await prefs.setBool(
      aiMotivationEnabledKey,
      TimerSettings.defaultAiMotivationEnabled,
    );
    await prefs.setString(aiProviderKey, TimerSettings.defaultAiProvider);
    await prefs.setString(aiApiKeyKey, TimerSettings.defaultAiApiKey);
    await prefs.setString(aiModelKey, TimerSettings.defaultAiModel);
    await prefs.setString(
      aiCustomSystemPromptKey,
      TimerSettings.defaultAiCustomSystemPrompt,
    );
    await prefs.setBool(
      autoStartScheduleKey,
      TimerSettings.defaultAutoStartSchedule,
    );
    await prefs.setBool(
      osFocusDndEnabledKey,
      TimerSettings.defaultOsFocusDndEnabled,
    );
    await prefs.setBool(
      blinkReminderAiEnabledKey,
      TimerSettings.defaultBlinkReminderAiEnabled,
    );
    await prefs.setString(
      blinkReminderCustomMessageKey,
      TimerSettings.defaultBlinkReminderCustomMessage,
    );
    await prefs.setBool(
      cameraMicAutoPostponeEnabledKey,
      TimerSettings.defaultCameraMicAutoPostponeEnabled,
    );
    await prefs.setBool(
      wellnessRemindersEnabledKey,
      TimerSettings.defaultWellnessRemindersEnabled,
    );
    await prefs.setInt(
      wellnessReminderCadenceSecondsKey,
      TimerSettings.defaultWellnessReminderCadenceSeconds,
    );
    await prefs.setBool(
      blinkReminderInteractiveEnabledKey,
      TimerSettings.defaultBlinkReminderInteractiveEnabled,
    );

    return const TimerSettings.defaults().copyWith(streakCount: currentStreak);
  }

  Future<void> saveAllSettings(TimerSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(workDurationSecondsKey, settings.workDurationSeconds);
    await prefs.setInt(breakDurationSecondsKey, settings.breakDurationSeconds);
    await prefs.setString(themeModeKey, _themeModeToString(settings.themeMode));
    await prefs.setString(colorPresetKey, settings.colorPreset);
    await prefs.setInt(dailyGoalKey, settings.dailyGoal);
    await prefs.setBool(notificationsEnabledKey, settings.notificationsEnabled);
    await prefs.setBool(hapticsEnabledKey, settings.hapticsEnabled);
    await prefs.setBool(soundEnabledKey, settings.soundEnabled);
    await prefs.setBool(longBreakEnabledKey, settings.longBreakEnabled);
    await prefs.setInt(
      longBreakDurationSecondsKey,
      settings.longBreakDurationSeconds,
    );
    await prefs.setInt(longBreakEveryCyclesKey, settings.longBreakEveryCycles);
    await prefs.setBool(autoRunEnabledKey, settings.autoRunEnabled);
    await prefs.setInt(autoRunCycleLimitKey, settings.autoRunCycleLimit);
    await prefs.setString(breakModeKey, _breakModeToString(settings.breakMode));
    await prefs.setBool(allowSkipKey, settings.allowSkip);
    await prefs.setBool(allowPostponeKey, settings.allowPostpone);
    await prefs.setInt(
      postponeDurationSecondsKey,
      settings.postponeDurationSeconds,
    );
    await prefs.setBool(smartIdleEnabledKey, settings.smartIdleEnabled);
    await prefs.setString(
      breakVisualizerStyleKey,
      settings.breakVisualizerStyle,
    );
    await prefs.setBool(breakShowClockKey, settings.breakShowClock);
    await prefs.setBool(breakShowTipsKey, settings.breakShowTips);
    await prefs.setBool(breakShowProgressKey, settings.breakShowProgress);
    await prefs.setString(breakCustomMessageKey, settings.breakCustomMessage);
    await prefs.setString(chimeStyleKey, settings.chimeStyle);
    await prefs.setBool(
      blinkRemindersEnabledKey,
      settings.blinkRemindersEnabled,
    );
    await prefs.setInt(
      blinkRemindersCadenceSecondsKey,
      settings.blinkRemindersCadenceSeconds,
    );
    await prefs.setBool(
      trayBlinkNudgesEnabledKey,
      settings.trayBlinkNudgesEnabled,
    );
    await prefs.setInt(
      trayBlinkNudgeCadenceSecondsKey,
      settings.trayBlinkNudgeCadenceSeconds,
    );
    await prefs.setBool(workHoursEnabledKey, settings.workHoursEnabled);
    await prefs.setInt(workHoursStartHourKey, settings.workHoursStartHour);
    await prefs.setInt(workHoursStartMinuteKey, settings.workHoursStartMinute);
    await prefs.setInt(workHoursEndHourKey, settings.workHoursEndHour);
    await prefs.setInt(workHoursEndMinuteKey, settings.workHoursEndMinute);
    await prefs.setString(workDaysKey, settings.workDays);
    await prefs.setBool(
      naturalBreakCreditEnabledKey,
      settings.naturalBreakCreditEnabled,
    );
    await prefs.setBool(amoledDarkEnabledKey, settings.amoledDarkEnabled);
    await prefs.setString(
      customAccentColorHexKey,
      settings.customAccentColorHex,
    );
    await prefs.setBool(useSystemAccentKey, settings.useSystemAccent);
    await prefs.setBool(startMinimizedKey, settings.startMinimized);
    await prefs.setBool(aiMotivationEnabledKey, settings.aiMotivationEnabled);
    await prefs.setString(aiProviderKey, settings.aiProvider);
    await prefs.setString(aiApiKeyKey, settings.aiApiKey);
    await prefs.setString(aiModelKey, settings.aiModel);
    await prefs.setString(
      aiCustomSystemPromptKey,
      settings.aiCustomSystemPrompt,
    );
    await prefs.setBool(autoStartScheduleKey, settings.autoStartSchedule);
    await prefs.setBool(osFocusDndEnabledKey, settings.osFocusDndEnabled);
    await prefs.setBool(
      blinkReminderAiEnabledKey,
      settings.blinkReminderAiEnabled,
    );
    await prefs.setString(
      blinkReminderCustomMessageKey,
      settings.blinkReminderCustomMessage,
    );
    await prefs.setBool(
      cameraMicAutoPostponeEnabledKey,
      settings.cameraMicAutoPostponeEnabled,
    );
    await prefs.setBool(
      wellnessRemindersEnabledKey,
      settings.wellnessRemindersEnabled,
    );
    await prefs.setInt(
      wellnessReminderCadenceSecondsKey,
      settings.wellnessReminderCadenceSeconds,
    );
    await prefs.setBool(
      blinkReminderInteractiveEnabledKey,
      settings.blinkReminderInteractiveEnabled,
    );
    await prefs.setInt(
      maxConsecutiveSkipsKey,
      settings.maxConsecutiveSkips,
    );
    await prefs.setBool(
      autoPauseOnMediaEnabledKey,
      settings.autoPauseOnMediaEnabled,
    );
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
      completedAutoRunCycles:
          prefs.getInt(sessionCompletedAutoRunCyclesKey) ?? 0,
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
    await prefs.setInt(
      sessionCompletedAutoRunCyclesKey,
      session.completedAutoRunCycles,
    );
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
    await prefs.remove(sessionCompletedAutoRunCyclesKey);
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

  Future<void> saveAmoledDarkEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(amoledDarkEnabledKey, enabled);
  }

  Future<void> saveCustomAccentColorHex(String hex) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(customAccentColorHexKey, hex);
  }

  Future<void> saveUseSystemAccent(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(useSystemAccentKey, enabled);
  }

  Future<void> saveStartMinimized(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(startMinimizedKey, enabled);
  }

  Future<void> saveDailyGoal(int dailyGoal) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(dailyGoalKey, dailyGoal);
  }

  Future<void> saveNotificationsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(notificationsEnabledKey, enabled);
  }


  Future<void> saveBlinkReminderAiEnabled(bool v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(blinkReminderAiEnabledKey, v);
  }

  Future<void> saveBlinkReminderCustomMessage(String v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(blinkReminderCustomMessageKey, v);
  }

  Future<void> saveCameraMicAutoPostponeEnabled(bool v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(cameraMicAutoPostponeEnabledKey, v);
  }

  Future<void> saveWellnessRemindersEnabled(bool v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(wellnessRemindersEnabledKey, v);
  }

  Future<void> saveWellnessReminderCadenceSeconds(int v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(wellnessReminderCadenceSecondsKey, v);
  }

  Future<void> saveBlinkReminderInteractiveEnabled(bool v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(blinkReminderInteractiveEnabledKey, v);
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

  Future<void> saveAutoRunSettings({
    required bool enabled,
    required int cycleLimit,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(autoRunEnabledKey, enabled);
    await prefs.setInt(autoRunCycleLimitKey, cycleLimit);
  }

  Future<void> saveBreakMode(BreakMode breakMode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(breakModeKey, _breakModeToString(breakMode));
  }

  Future<void> saveAllowSkip(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(allowSkipKey, enabled);
  }

  Future<void> saveMaxConsecutiveSkips(int count) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(maxConsecutiveSkipsKey, count);
  }

  Future<void> saveAllowPostpone(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(allowPostponeKey, enabled);
  }

  Future<void> savePostponeDurationSeconds(int seconds) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(postponeDurationSecondsKey, seconds);
  }

  Future<void> saveSmartIdleEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(smartIdleEnabledKey, enabled);
  }

  Future<void> saveBreakVisualizerStyle(String style) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(breakVisualizerStyleKey, style);
  }

  Future<void> saveBreakShowClock(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(breakShowClockKey, enabled);
  }

  Future<void> saveBreakShowTips(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(breakShowTipsKey, enabled);
  }

  Future<void> saveBreakShowProgress(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(breakShowProgressKey, enabled);
  }

  Future<void> saveBreakCustomMessage(String message) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(breakCustomMessageKey, message);
  }

  Future<void> saveChimeStyle(String style) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(chimeStyleKey, style);
  }

  Future<void> saveBlinkRemindersEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(blinkRemindersEnabledKey, enabled);
  }

  Future<void> saveBlinkRemindersCadenceSeconds(int seconds) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(blinkRemindersCadenceSecondsKey, seconds);
  }

  Future<void> saveTrayBlinkNudgesEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(trayBlinkNudgesEnabledKey, enabled);
  }

  Future<void> saveTrayBlinkNudgeCadenceSeconds(int seconds) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(trayBlinkNudgeCadenceSecondsKey, seconds);
  }

  Future<void> saveWorkHoursEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(workHoursEnabledKey, enabled);
  }

  Future<void> saveWorkHoursStartHour(int hour) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(workHoursStartHourKey, hour);
  }

  Future<void> saveWorkHoursStartMinute(int minute) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(workHoursStartMinuteKey, minute);
  }

  Future<void> saveWorkHoursEndHour(int hour) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(workHoursEndHourKey, hour);
  }

  Future<void> saveWorkHoursEndMinute(int minute) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(workHoursEndMinuteKey, minute);
  }

  Future<void> saveWorkDays(String days) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(workDaysKey, days);
  }

  Future<void> saveNaturalBreakCreditEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(naturalBreakCreditEnabledKey, enabled);
  }

  Future<void> saveAiMotivationEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(aiMotivationEnabledKey, enabled);
  }

  Future<void> saveAiProvider(String provider) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(aiProviderKey, provider);
  }

  Future<void> saveAiApiKey(String apiKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(aiApiKeyKey, apiKey);
  }

  Future<void> saveAiModel(String model) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(aiModelKey, model);
  }

  Future<void> saveAiCustomSystemPrompt(String prompt) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(aiCustomSystemPromptKey, prompt);
  }

  Future<void> saveAutoStartSchedule(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(autoStartScheduleKey, enabled);
  }

  Future<void> saveOsFocusDndEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(osFocusDndEnabledKey, enabled);
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

  BreakMode _breakModeFromString(String? value) {
    return switch (value) {
      'off' => BreakMode.off,
      'strict' => BreakMode.strict,
      _ => BreakMode.gentle,
    };
  }

  String _breakModeToString(BreakMode breakMode) {
    return switch (breakMode) {
      BreakMode.off => 'off',
      BreakMode.strict => 'strict',
      BreakMode.gentle => 'gentle',
    };
  }
}
