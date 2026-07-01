// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'BlinkKind';

  @override
  String get start => 'Start';

  @override
  String get pause => 'Pause';

  @override
  String get resume => 'Resume';

  @override
  String get cancel => 'Cancel';

  @override
  String get stopTimer => 'Stop Timer';

  @override
  String get skip => 'Skip';

  @override
  String get postpone => 'Postpone';

  @override
  String get snooze => 'Snooze';

  @override
  String get breaksTakenToday => 'Breaks taken today';

  @override
  String get readyForNextFocusSession => 'Ready for your next focus session';

  @override
  String get snoozed => 'Snoozed';

  @override
  String get schedulePaused => 'Schedule Paused';

  @override
  String get idle => 'Idle';

  @override
  String get paused => 'Paused';

  @override
  String get idlePaused => 'Idle Paused';

  @override
  String get breakLabel => 'Break';

  @override
  String get workLabel => 'Work';

  @override
  String breaksSnoozed(int minutes) {
    return 'Breaks snoozed ($minutes min left)';
  }

  @override
  String get timerPausedBySchedule => 'Timer paused by schedule';

  @override
  String get breakPaused => 'Break paused';

  @override
  String get workPaused => 'Work paused';

  @override
  String get workPausedIdle => 'Work paused (Idle)';

  @override
  String get breakTimeMessage => 'Break Time - look 20 ft away';

  @override
  String get workTimeMessage => 'Work Time - focus on your task';

  @override
  String get onboardingSubtitle =>
      'Follow the 20-20-20 habit with gentle reminders while you work.';

  @override
  String get onboardingFocusFirstTitle => 'Focus first';

  @override
  String get onboardingFocusFirstBody =>
      'Start a focus session and keep the timer running in the app.';

  @override
  String get onboardingRestEyesTitle => 'Rest your eyes';

  @override
  String get onboardingRestEyesBody =>
      'When work time ends, look away and relax your focus during the break.';

  @override
  String get onboardingAllowRemindersTitle => 'Allow reminders';

  @override
  String get onboardingNotificationsBlocked =>
      'Notifications are blocked in system settings. You can recover them from Settings later.';

  @override
  String get onboardingNotificationsHelp =>
      'Notifications help the timer still remind you when the app is not on screen.';

  @override
  String get onboardingAllowAndStart => 'Allow reminders and start';

  @override
  String get onboardingContinueWithoutReminders => 'Continue without reminders';

  @override
  String get historyTitle => 'History & Insights';

  @override
  String get sevenDays => '7 days';

  @override
  String get thirtyDays => '30 days';

  @override
  String get allTime => 'All';

  @override
  String get dailyActivityPattern => 'Daily Activity Pattern';

  @override
  String get noActivityRange => 'No activity recorded in this range';

  @override
  String get focusDuration => 'Focus duration';

  @override
  String get goalRate => 'Goal rate';

  @override
  String get longestStreakLabel => 'Longest streak';

  @override
  String get peakFocusHourLabel => 'Peak focus hour';

  @override
  String get breakComplianceLabel => 'Eye Health Score';

  @override
  String get complianceRate => 'Eye Health Score';

  @override
  String get milestonesEarnedLabel => 'Milestones earned';

  @override
  String get achievementsTitle => 'Achievements';

  @override
  String get productivityInsights => 'Productivity Insights';

  @override
  String get completedFocusSessions => 'Completed Focus Sessions';

  @override
  String get cancelledSessions => 'Cancelled Sessions';

  @override
  String get skippedBreaks => 'Skipped Breaks';

  @override
  String get postponedBreaks => 'Postponed Breaks';

  @override
  String get consciousBlinksLogged => 'Conscious blinks logged';

  @override
  String get recentCompletedSessions => 'Recent completed sessions';

  @override
  String get newSessionsAppearHere => 'New completed sessions will appear here';

  @override
  String get exportActivityData => 'Export Activity Data';

  @override
  String get exportActivityDescription =>
      'Export your focus sessions and break activity events. You can save them directly to your Downloads folder or copy them to your clipboard.';

  @override
  String get saveCsv => 'Save CSV';

  @override
  String get saveJson => 'Save JSON';

  @override
  String get copyCsv => 'Copy CSV';

  @override
  String get copyJson => 'Copy JSON';

  @override
  String get clearActivityHistory => 'Clear activity history';

  @override
  String get clearHistoryConfirmTitle => 'Clear activity history?';

  @override
  String get clearHistoryConfirmBody =>
      'This removes daily totals and completed session details. This cannot be undone.';

  @override
  String get clear => 'Clear';

  @override
  String copiedToClipboard(String formatName) {
    return '$formatName copied to clipboard!';
  }

  @override
  String exportedToFile(String fileName) {
    return 'Exported to file: $fileName';
  }

  @override
  String get openFolder => 'Open Folder';

  @override
  String failedToExport(String error) {
    return 'Failed to export to file: $error';
  }

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsSearchPlaceholder => 'Search settings...';

  @override
  String settingsNoResults(String query) {
    return 'No settings matching \"$query\"';
  }

  @override
  String get settingsCategoryGeneralSchedule => 'General Schedule';

  @override
  String get settingsCategoryBreakBehavior => 'Break Screen & Behavior';

  @override
  String get settingsCategoryThemeAppearance => 'Theme & Appearance';

  @override
  String get settingsCategoryNotificationsSounds => 'Notifications & Sounds';

  @override
  String get settingsCategoryAutoRunLongBreaks => 'Auto Run & Long Breaks';

  @override
  String get settingsCategoryDesktopOptions => 'Desktop Options';

  @override
  String get settingsCategoryAiMotivation => 'AI Motivation & Prompts';

  @override
  String get settingsCategorySystemOptions => 'System Options';

  @override
  String get settingsQuickPresets => 'Quick presets';

  @override
  String get settingsQuickPresetsSubtitle =>
      '20-20-20, 25/5, 45/5, 10s/10s (Test)';

  @override
  String get settingsWorkDuration => 'Work duration';

  @override
  String get settingsWorkDurationChoose => 'Choose work interval';

  @override
  String get settingsPauseCancelToChange => 'Pause/cancel timer to change';

  @override
  String get settingsPauseCancelToChangeDesc =>
      'Pause or cancel the timer to change this';

  @override
  String get settingsBreakDuration => 'Break duration';

  @override
  String get settingsBreakDurationChoose => 'Choose break length';

  @override
  String get settingsDailyGoal => 'Daily goal';

  @override
  String settingsDailyGoalProgress(int streak, int goal) {
    return '$streak / $goal breaks today';
  }

  @override
  String get settingsCustom => 'Custom...';

  @override
  String get settingsHistory => 'History';

  @override
  String get settingsHistorySubtitle => 'Review your recent eye breaks';

  @override
  String settingsTodayProgress(int count) {
    return 'Today: $count cycles';
  }

  @override
  String get settingsTodayProgressTitle => 'Today\'s progress';

  @override
  String get settingsResetStreak => 'Reset today\'s streak';

  @override
  String get settingsReset => 'Reset';

  @override
  String get settingsActiveWorkHours => 'Active work hours & days';

  @override
  String get settingsActiveWorkHoursSubtitle =>
      'Only run the timer cycles during specific hours and days';

  @override
  String get settingsActiveDays => 'Active Days';

  @override
  String get settingsStartTime => 'Start Time';

  @override
  String get settingsEndTime => 'End Time';

  @override
  String get settingsAutoStartSchedule => 'Auto-start schedule';

  @override
  String get settingsAutoStartScheduleSubtitle =>
      'Automatically start the timer on launch';

  @override
  String get settingsOsFocusMode => 'OS Focus Mode (DND)';

  @override
  String get settingsOsFocusModeSubtitle =>
      'Toggle system Do Not Disturb (DND) automatically during work phases (Linux GNOME)';

  @override
  String get settingsOsFocusModeToggle =>
      'Toggle system DND during work phases';

  @override
  String get settingsOsFocusModeGnomeNote =>
      'Note: Ubuntu/GNOME does not natively support DND exceptions/whitelist. If you want specific apps to bypass DND, turn this toggle off and instead manually silence noisy apps under Ubuntu System Settings -> Notifications.';

  @override
  String get settingsBreakScreenMode => 'Break screen mode';

  @override
  String get settingsBreakScreenModeSubtitle =>
      'Off, Gentle, or Strict break enforcement mode';

  @override
  String get settingsStrictBlocksExit => 'Strict mode blocks easy exit';

  @override
  String get settingsPreBreakAlert => 'Pre-break notification alert';

  @override
  String get settingsPreBreakAlertSubtitle =>
      'Get a warning notification 10 seconds before the break start';

  @override
  String get settingsAllowSkip => 'Allow skip';

  @override
  String get settingsAllowSkipSubtitle => 'Allow skipping the break early';

  @override
  String get settingsAllowPostpone => 'Allow postpone';

  @override
  String get settingsAllowPostponeSubtitle => 'Allow postponing the break';

  @override
  String get settingsSmartPausePostpone => 'Smart Pause & Postpone';

  @override
  String get settingsSmartPausePostponeSubtitle =>
      'Pause work timer automatically when you are idle';

  @override
  String get settingsNaturalBreakCredit => 'Natural break credit';

  @override
  String get settingsNaturalBreakCreditSubtitle =>
      'Credit away time as a break if away for more than 5 minutes';

  @override
  String get settingsBreakVisualizerStyle => 'Break visualizer style';

  @override
  String get settingsBreakVisualizerStyleSubtitle =>
      'Choose ambient effect during breaks';

  @override
  String get settingsBreakScreenContent => 'Break screen content';

  @override
  String get settingsBreakScreenContentSubtitle =>
      'Choose widgets shown on the break overlay';

  @override
  String get settingsShowCountdown => 'Show countdown clock';

  @override
  String get settingsShowTips => 'Show eye-care tips';

  @override
  String get settingsShowProgress => 'Show progress ring';

  @override
  String get settingsCustomReminderText => 'Custom reminder text';

  @override
  String get settingsBuiltInRotatingMessages =>
      'Using built-in rotating messages';

  @override
  String get settingsPostponeDuration => 'Postpone duration';

  @override
  String get settingsPostponeDurationSubtitle => 'How long to delay the break';

  @override
  String get settingsDisplayOverApps => 'Display over other apps';

  @override
  String get settingsAllow => 'Allow';

  @override
  String get settingsPreviewBreakScreen => 'Preview break screen';

  @override
  String get settingsPreviewBreakScreenSubtitle =>
      'Show a 10-second black overlay';

  @override
  String get settingsTest20sBreak => 'Test 20s break screen';

  @override
  String get settingsTest20sBreakSubtitle =>
      'Launch a real 20-second eye break';

  @override
  String get settingsUsageAccess => 'Usage access';

  @override
  String get settingsUsageAccessEnabled => 'App detection enabled';

  @override
  String get settingsUsageAccessRequired => 'Required to detect games & videos';

  @override
  String get settingsDarkMode => 'Dark mode';

  @override
  String get settingsDarkModeSubtitle => 'Toggle dark or light theme interface';

  @override
  String get settingsAmoledDarkMode => 'AMOLED dark mode';

  @override
  String get settingsAmoledDarkModeSubtitle =>
      'Use pure black backgrounds for battery saving';

  @override
  String get settingsReducedMotion => 'Reduced motion';

  @override
  String get settingsReducedMotionSubtitle =>
      'Minimize UI animations and complex effects';

  @override
  String get settingsUseSystemAccent => 'Use system accent color';

  @override
  String get settingsUseSystemAccentSubtitle =>
      'Follow OS system-accent dynamic colors';

  @override
  String get settingsColorPreset => 'Color preset';

  @override
  String get settingsColorPresetSubtitle =>
      'Choose your preferred accent color theme preset';

  @override
  String get settingsCustomAccentPalette => 'Custom Accent Palette';

  @override
  String get settingsAccentColorHex => 'Accent Color Hex Code';

  @override
  String get settingsNotifications => 'Notifications';

  @override
  String get settingsNotificationsSubtitle =>
      'Remind me when work or break time ends';

  @override
  String get settingsNotificationSound => 'Notification sound';

  @override
  String get settingsNotificationSoundSubtitle =>
      'Uses system notification sound settings';

  @override
  String get settingsTestReminderAlert => 'Test reminder alert';

  @override
  String get settingsPlayReminderSound => 'Play the actual reminder sound now';

  @override
  String get settingsTestReminder => 'Test reminder';

  @override
  String get settingsPermissionStatus => 'Permission status';

  @override
  String get settingsOpenSystemSettings => 'Open system settings';

  @override
  String get settingsTimerAlertsOff =>
      'Timer alerts are off. The countdown still works in the app.';

  @override
  String get settingsPreciseReminders => 'Precise reminders';

  @override
  String get settingsPreciseAllowed => 'Exact timing allowed';

  @override
  String get settingsPreciseLate => 'May arrive a little late';

  @override
  String get settingsBackgroundReliability => 'Background reliability';

  @override
  String get settingsBatteryUnrestricted => 'Battery use is unrestricted';

  @override
  String get settingsBatteryOptimized =>
      'Battery optimization may delay alerts';

  @override
  String get settingsReview => 'Review';

  @override
  String get settingsHaptics => 'Haptics';

  @override
  String get settingsVibratePhaseEnd => 'Vibrate when a timer phase ends';

  @override
  String get settingsInAppSound => 'In-app sound';

  @override
  String get settingsPlayExtraAlert =>
      'Play an extra system alert while BlinkKind is open';

  @override
  String get settingsChimeStyle => 'Chime style';

  @override
  String get settingsChimeStyleSubtitle =>
      'Sound to play when a break starts or ends';

  @override
  String get settingsConsciousBlinkingReminders =>
      'Conscious blinking reminders';

  @override
  String get settingsConsciousBlinkingSubtitle =>
      'Shows visible OS banner reminders during work, keeping your eyes moist and reducing fatigue';

  @override
  String get settingsBannerInterval => 'Banner interval';

  @override
  String get settingsShowBlinkBanner => 'How often to show the OS blink banner';

  @override
  String get settingsInteractiveBlinkReminders => 'Interactive blink actions';

  @override
  String get settingsInteractiveBlinkRemindersSubtitle =>
      'Add a button to check off blink reminders directly from notifications';

  @override
  String get settingsTrayBlinkNudges => 'Tray blink nudges';

  @override
  String get settingsTrayBlinkNudgesSubtitle =>
      'Pulses the system tray icon independently from OS banner reminders';

  @override
  String get settingsTrayNudgeInterval => 'Tray nudge interval';

  @override
  String get settingsTrayIconPulse => 'How often the tray icon should pulse';

  @override
  String get settingsRunScheduleAutomatically => 'Run schedule automatically';

  @override
  String get settingsRunScheduleAutomaticallySubtitle =>
      'Continue work and break cycles until stopped or limit is reached';

  @override
  String get settingsCycleLimit => 'Cycle limit';

  @override
  String get settingsCycleLimitSubtitle => 'Completed work cycles in one run';

  @override
  String get settingsLongBreakMode => 'Long break mode';

  @override
  String settingsLongBreakModeSubtitle(int count, String duration) {
    return 'After $count work cycles, rest for $duration';
  }

  @override
  String get settingsCycleInterval => 'Cycle interval';

  @override
  String get settingsLongBreakDuration => 'Long break duration';

  @override
  String get settingsLaunchAtStartup => 'Launch at Startup';

  @override
  String get settingsStartBlinkKindAutomatically =>
      'Start BlinkKind automatically when you log in';

  @override
  String get settingsStartMinimized => 'Start minimized';

  @override
  String get settingsOpenIntoTray => 'Open into the tray on app startup';

  @override
  String get settingsEnableAiMotivation => 'Enable AI motivation';

  @override
  String get settingsAiProvider => 'AI Provider';

  @override
  String get settingsAiApiKey => 'API Key';

  @override
  String get settingsAiApiKeyHint => 'Paste your API key here';

  @override
  String get settingsAiModel => 'Model';

  @override
  String get settingsAiSystemPrompt => 'System prompt';

  @override
  String get settingsAiSystemPromptHint =>
      'Describe what kind of quote you want...';

  @override
  String get settingsResetSettings => 'Reset settings';

  @override
  String get settingsRestoreFactoryDefaults =>
      'Restore all settings to factory defaults';

  @override
  String get settingsBackupSettings => 'Backup settings';

  @override
  String get settingsExportDownloadsFolder =>
      'Export settings to your Downloads folder';

  @override
  String get settingsRestoreSettings => 'Restore settings';

  @override
  String get settingsLoadBackupJson => 'Load settings from a backup JSON file';

  @override
  String get settingsCustomModelDialogTitle => 'Custom model';

  @override
  String get settingsModelName => 'Model name';

  @override
  String get settingsModelNameHint => 'e.g. gpt-4o, gemini-2.0-flash';

  @override
  String get settingsSet => 'Set';

  @override
  String get settingsRestoreDefaultsTitle => 'Restore defaults?';

  @override
  String get settingsRestoreDefaultsDesc =>
      'This will reset all preferences (durations, presets, sound settings, theme presets, AI configurations, auto-start options) back to factory defaults.\n\nYour streak, history, and recorded activity will NOT be erased.';

  @override
  String get settingsRestoredSnackbar =>
      'Settings restored to factory defaults';

  @override
  String get settingsRestoredSuccessSnackbar =>
      'Settings restored successfully!';

  @override
  String settingsRestoredFailedSnackbar(String error) {
    return 'Failed to restore settings: $error';
  }

  @override
  String get settingsCustomDailyGoalTitle => 'Custom daily goal';

  @override
  String get settingsNumberOfBreaks => 'Number of breaks';

  @override
  String get settingsNumberOfBreaksHint => 'e.g. 15, 20';

  @override
  String get settingsCustomBlinkReminderTitle => 'Custom blink reminder';

  @override
  String get settingsCustomBlinkReminderHint =>
      'e.g. Time to blink! Rest your eyes.';

  @override
  String get settingsCustomBlinkReminderHelper =>
      'Leave blank to use built-in messages';

  @override
  String get settingsSave => 'Save';

  @override
  String get settingsCameraAutoPostponeSnackbar =>
      'Camera in use — break postponed automatically';

  @override
  String get settingsAllowOverlaySnackbar =>
      'Allow display over other apps first.';

  @override
  String settingsDurationSeconds(int seconds) {
    return '${seconds}s';
  }

  @override
  String settingsDurationMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String settingsDurationEverySeconds(int seconds) {
    return 'Every $seconds sec';
  }

  @override
  String settingsDurationEveryMinutes(int minutes) {
    return 'Every $minutes min';
  }

  @override
  String get settingsCycleNoLimit => 'No limit';

  @override
  String settingsCycleLimitCount(int count) {
    return '$count cycles';
  }

  @override
  String get settingsWellnessReminders => 'Wellness reminders';

  @override
  String get settingsWellnessRemindersSubtitle =>
      'Periodic hydration, posture, and stretch reminders during work';

  @override
  String get settingsWellnessRemindersDesc =>
      'Alternates hydration, posture, and stretch reminders during work sessions';

  @override
  String get settingsReminderInterval => 'Reminder interval';

  @override
  String get settingsReminderIntervalDesc =>
      'How often to send a wellness reminder';

  @override
  String get settingsCameraMicAutoPostpone => 'Camera/mic auto-postpone';

  @override
  String get settingsCameraMicAutoPostponeSubtitle =>
      'Postpone breaks automatically when camera is in use (video calls)';

  @override
  String get settingsCameraMicAutoPostponeDesc =>
      'Automatically postpone breaks when your camera or microphone is in use (e.g. video calls). Linux & Android only.';

  @override
  String get settingsAutoPauseOnMedia => 'Media playback auto-pause';

  @override
  String get settingsAutoPauseOnMediaSubtitle =>
      'Pause breaks automatically when video or music is playing';

  @override
  String get settingsAutoPauseOnMediaDesc =>
      'Automatically pause the timer when background media (music or video) is active. Android & Linux only.';

  @override
  String get settingsWellnessEvery30Min => 'Every 30 min';

  @override
  String get settingsWellnessEvery45Min => 'Every 45 min';

  @override
  String get settingsWellnessEvery1Hour => 'Every 1 hour';

  @override
  String get settingsWellnessEvery15Hours => 'Every 1.5 hours';

  @override
  String get settingsWellnessEvery2Hours => 'Every 2 hours';

  @override
  String get settingsAiBlinkMessages => 'AI-powered blink messages';

  @override
  String get settingsAiBlinkMessagesSubtitle =>
      'Generate a fresh, unique reminder each time using AI';

  @override
  String get settingsCustomReminder => 'Custom blink reminder';

  @override
  String get settingsPermissionAllowed => 'System permission allowed';

  @override
  String get settingsPermissionBlocked => 'System permission blocked';

  @override
  String get settingsPermissionUnavailable =>
      'Status unavailable on this platform';

  @override
  String get settingsPermissionChecking => 'Checking system permission';

  @override
  String get settingsOverlayAllowed => 'Allowed on this device';

  @override
  String get settingsOverlayRequired =>
      'Permission required for enforced breaks';

  @override
  String get settingsOverlayChecking => 'Checking overlay permission';

  @override
  String get settingsOverlayUnavailable => 'Unavailable on this platform';

  @override
  String get settingsBreakModeOff => 'Off';

  @override
  String get settingsBreakModeGentle => 'Gentle';

  @override
  String get settingsBreakModeStrict => 'Strict';

  @override
  String get mon => 'Mon';

  @override
  String get tue => 'Tue';

  @override
  String get wed => 'Wed';

  @override
  String get thu => 'Thu';

  @override
  String get fri => 'Fri';

  @override
  String get sat => 'Sat';

  @override
  String get sun => 'Sun';

  @override
  String get settingsVisualizerRandom => 'Random/All';

  @override
  String get settingsVisualizerBreathing => 'Calm Breathing';

  @override
  String get settingsVisualizerBoxBreathing => 'Box Breathing (4-4-4-4)';

  @override
  String get settingsVisualizerEyeExercise => 'Eye Exercises';

  @override
  String get settingsVisualizerBlinkTraining => 'Blink Training (Blink Pacing)';

  @override
  String get settingsVisualizerAmbient => 'Ambient Flow';

  @override
  String get settingsVisualizerStarry => 'Starry Sky';

  @override
  String get settingsShowCountdownDesc => 'Display remaining break time';

  @override
  String get settingsShowTipsDesc => 'Rotate guidance during the break';

  @override
  String get settingsShowProgressDesc =>
      'Visualize break progress on classic layouts';

  @override
  String get settingsCustomBreakMessage => 'Custom break message';

  @override
  String get settingsCustomBreakMessageSubtitle =>
      'Optional text shown before rotating tips';

  @override
  String get settingsCustomBreakMessageHint =>
      'Close your eyes and breathe slowly.';

  @override
  String get settingsChimeTibetanBowl => 'Tibetan Bowl';

  @override
  String get settingsChimeWindChimes => 'Wind Chimes';

  @override
  String get settingsChimeZenBell => 'Zen Bell';

  @override
  String get settingsChimeSystemAlert => 'System Alert';

  @override
  String get settingsConsciousBlinkingDesc =>
      'Sends periodic OS notifications to remind you to blink during work sessions';

  @override
  String get settingsAiMotivationTitle => 'AI Motivation & Prompts';

  @override
  String get settingsAiMotivationSubtitle =>
      'Generate personalised eye-care quotes during breaks';

  @override
  String get settingsAiMotivationEnabledSubtitle =>
      'Generate personalised quotes during breaks';

  @override
  String get settingsAiProviderGemini => 'Google Gemini';

  @override
  String get settingsAiProviderOpenAi => 'OpenAI (ChatGPT)';

  @override
  String get settingsAiProviderGroq => 'Groq (Fast)';

  @override
  String get settingsAiModelCustom => 'Custom...';

  @override
  String get settingsAiLoadModelsError =>
      'Could not load models. Using defaults.';

  @override
  String settingsExportedSnackbar(String fileName) {
    return 'Exported settings to: $fileName';
  }

  @override
  String settingsExportFailedSnackbar(String error) {
    return 'Failed to backup settings: $error';
  }

  @override
  String get settingsLongBreakModeDesc =>
      'Take a longer rest break after a set number of work cycles';

  @override
  String get settingsDesktopStartupBehavior => 'Desktop startup behavior';

  @override
  String get settingsDesktopStartupBehaviorSubtitle =>
      'Control login launch and tray-first startup behavior';

  @override
  String get settingsBackup => 'Backup';

  @override
  String get settingsRestore => 'Restore';

  @override
  String get timerTakeBreakNow => 'Take break now';

  @override
  String get timerCancelSnooze => 'Cancel snooze';

  @override
  String get timerSnooze1h => 'Snooze 1h';

  @override
  String get timerTomorrow => 'Tomorrow';

  @override
  String get timerNaturalBreakCredited =>
      'Natural break detected and credited! Timer reset.';

  @override
  String get notificationPermissionTitle => 'Enable notifications?';

  @override
  String get notificationPermissionMessage =>
      'BlinkKind uses notifications to remind you when your eye break is about to start. Without this permission the reminder will only appear while the app is open.\n\nYou can change this at any time in Settings.';

  @override
  String get notNow => 'Not now';

  @override
  String get openSettings => 'Open Settings';

  @override
  String get settingsCategoryAbout => 'About BlinkKind';

  @override
  String get settingsAboutVersion => 'App Version';

  @override
  String get settingsAboutPrivacyTitle => 'Privacy Policy';

  @override
  String get settingsAboutPrivacySubtitle => '100% offline and local-first';

  @override
  String get settingsAboutPrivacyBody =>
      'BlinkKind is a local-first, 100% offline application. Your focus sessions, settings, and history are saved strictly on your local device. We do not collect, store, or transmit any personal data, usage metrics, or camera/microphone feeds.';

  @override
  String get settingsAboutLicensesTitle => 'Open Source Licenses';

  @override
  String get settingsAboutLicensesSubtitle =>
      'Third-party software libraries used';

  @override
  String get close => 'Close';

  @override
  String get batteryWarningTitle => 'Battery Restrictions Detected';

  @override
  String get batteryWarningSubtitleGeneric =>
      'Battery optimization is blocking background break reminders. Tap Fix to whitelist BlinkKind.';

  @override
  String get batteryWarningFix => 'Fix';

  @override
  String get batteryWarningDismiss => 'Dismiss';

  @override
  String get settingsBatteryOptimizationRestricted =>
      'Restricted — breaks may be delayed or not delivered';

  @override
  String get settingsBatteryOptimizationFix => 'Fix Battery Settings';
}
