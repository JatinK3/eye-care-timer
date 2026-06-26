import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('en')];

  /// The title of the application
  ///
  /// In en, this message translates to:
  /// **'BlinkKind'**
  String get appTitle;

  /// Label for the start button
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get start;

  /// Label for the pause button
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get pause;

  /// Label for the resume button
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get resume;

  /// Label for the cancel button
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Label for the stop timer button shown when schedule is paused
  ///
  /// In en, this message translates to:
  /// **'Stop Timer'**
  String get stopTimer;

  /// Label for the skip break button
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// Label for the postpone break button
  ///
  /// In en, this message translates to:
  /// **'Postpone'**
  String get postpone;

  /// Label for the snooze button
  ///
  /// In en, this message translates to:
  /// **'Snooze'**
  String get snooze;

  /// Label showing the count of breaks taken today
  ///
  /// In en, this message translates to:
  /// **'Breaks taken today'**
  String get breaksTakenToday;

  /// Status text shown when the timer is ready to start
  ///
  /// In en, this message translates to:
  /// **'Ready for your next focus session'**
  String get readyForNextFocusSession;

  /// Timer status showing that it is currently snoozed
  ///
  /// In en, this message translates to:
  /// **'Snoozed'**
  String get snoozed;

  /// Timer status showing that the timer is paused due to work schedule
  ///
  /// In en, this message translates to:
  /// **'Schedule Paused'**
  String get schedulePaused;

  /// Timer status showing that the timer is idle
  ///
  /// In en, this message translates to:
  /// **'Idle'**
  String get idle;

  /// Timer status showing that the timer is manually paused
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get paused;

  /// Timer status showing that the timer is paused due to system idle detection
  ///
  /// In en, this message translates to:
  /// **'Idle Paused'**
  String get idlePaused;

  /// Short label for Break phase
  ///
  /// In en, this message translates to:
  /// **'Break'**
  String get breakLabel;

  /// Short label for Work phase
  ///
  /// In en, this message translates to:
  /// **'Work'**
  String get workLabel;

  /// Message shown when breaks are currently snoozed
  ///
  /// In en, this message translates to:
  /// **'Breaks snoozed ({minutes} min left)'**
  String breaksSnoozed(int minutes);

  /// Message shown when work hours have ended
  ///
  /// In en, this message translates to:
  /// **'Timer paused by schedule'**
  String get timerPausedBySchedule;

  /// Message shown when the break timer is paused
  ///
  /// In en, this message translates to:
  /// **'Break paused'**
  String get breakPaused;

  /// Message shown when the work timer is manually paused
  ///
  /// In en, this message translates to:
  /// **'Work paused'**
  String get workPaused;

  /// Message shown when the work timer is paused because user is idle
  ///
  /// In en, this message translates to:
  /// **'Work paused (Idle)'**
  String get workPausedIdle;

  /// Message encouraging user to look away during a break
  ///
  /// In en, this message translates to:
  /// **'Break Time - look 20 ft away'**
  String get breakTimeMessage;

  /// Message encouraging user to focus during work session
  ///
  /// In en, this message translates to:
  /// **'Work Time - focus on your task'**
  String get workTimeMessage;

  /// Subtitle description of the 20-20-20 rule on onboarding screen
  ///
  /// In en, this message translates to:
  /// **'Follow the 20-20-20 habit with gentle reminders while you work.'**
  String get onboardingSubtitle;

  /// Title of the first onboarding item
  ///
  /// In en, this message translates to:
  /// **'Focus first'**
  String get onboardingFocusFirstTitle;

  /// Body description of the focus first step on onboarding screen
  ///
  /// In en, this message translates to:
  /// **'Start a focus session and keep the timer running in the app.'**
  String get onboardingFocusFirstBody;

  /// Title of the second onboarding item
  ///
  /// In en, this message translates to:
  /// **'Rest your eyes'**
  String get onboardingRestEyesTitle;

  /// Body description of the rest your eyes step on onboarding screen
  ///
  /// In en, this message translates to:
  /// **'When work time ends, look away and relax your focus during the break.'**
  String get onboardingRestEyesBody;

  /// Title of the third onboarding item
  ///
  /// In en, this message translates to:
  /// **'Allow reminders'**
  String get onboardingAllowRemindersTitle;

  /// Warning message when notification permissions are blocked in system settings
  ///
  /// In en, this message translates to:
  /// **'Notifications are blocked in system settings. You can recover them from Settings later.'**
  String get onboardingNotificationsBlocked;

  /// Informational message about why notification permission is useful
  ///
  /// In en, this message translates to:
  /// **'Notifications help the timer still remind you when the app is not on screen.'**
  String get onboardingNotificationsHelp;

  /// Label for the onboarding main action button
  ///
  /// In en, this message translates to:
  /// **'Allow reminders and start'**
  String get onboardingAllowAndStart;

  /// Label for the onboarding secondary text button to skip notifications
  ///
  /// In en, this message translates to:
  /// **'Continue without reminders'**
  String get onboardingContinueWithoutReminders;

  /// Title of the history page
  ///
  /// In en, this message translates to:
  /// **'History & Insights'**
  String get historyTitle;

  /// Segment label for 7 days history range
  ///
  /// In en, this message translates to:
  /// **'7 days'**
  String get sevenDays;

  /// Segment label for 30 days history range
  ///
  /// In en, this message translates to:
  /// **'30 days'**
  String get thirtyDays;

  /// Segment label for all time history range
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get allTime;

  /// Title of the activity pattern section
  ///
  /// In en, this message translates to:
  /// **'Daily Activity Pattern'**
  String get dailyActivityPattern;

  /// Message shown when there is no activity data
  ///
  /// In en, this message translates to:
  /// **'No activity recorded in this range'**
  String get noActivityRange;

  /// Metric label for total focus time
  ///
  /// In en, this message translates to:
  /// **'Focus duration'**
  String get focusDuration;

  /// Metric label for percentage of days goal was met
  ///
  /// In en, this message translates to:
  /// **'Goal rate'**
  String get goalRate;

  /// Metric label for longest daily goal streak
  ///
  /// In en, this message translates to:
  /// **'Longest streak'**
  String get longestStreakLabel;

  /// Metric label for the hour user is most focused
  ///
  /// In en, this message translates to:
  /// **'Peak focus hour'**
  String get peakFocusHourLabel;

  /// Metric label for compliance rate
  ///
  /// In en, this message translates to:
  /// **'Break compliance'**
  String get breakComplianceLabel;

  /// Insight label for compliance rate
  ///
  /// In en, this message translates to:
  /// **'Compliance Rate'**
  String get complianceRate;

  /// Metric label for milestones count
  ///
  /// In en, this message translates to:
  /// **'Milestones earned'**
  String get milestonesEarnedLabel;

  /// Title of the achievements section
  ///
  /// In en, this message translates to:
  /// **'Achievements'**
  String get achievementsTitle;

  /// Title of the productivity insights section
  ///
  /// In en, this message translates to:
  /// **'Productivity Insights'**
  String get productivityInsights;

  /// Insight item for completed sessions
  ///
  /// In en, this message translates to:
  /// **'Completed Focus Sessions'**
  String get completedFocusSessions;

  /// Insight item for cancelled sessions
  ///
  /// In en, this message translates to:
  /// **'Cancelled Sessions'**
  String get cancelledSessions;

  /// Insight item for skipped breaks
  ///
  /// In en, this message translates to:
  /// **'Skipped Breaks'**
  String get skippedBreaks;

  /// Insight item for postponed breaks
  ///
  /// In en, this message translates to:
  /// **'Postponed Breaks'**
  String get postponedBreaks;

  /// Insight item for conscious blinks logged by user response
  ///
  /// In en, this message translates to:
  /// **'Conscious blinks logged'**
  String get consciousBlinksLogged;

  /// Title for the recent sessions list
  ///
  /// In en, this message translates to:
  /// **'Recent completed sessions'**
  String get recentCompletedSessions;

  /// Placeholder when recent sessions list is empty
  ///
  /// In en, this message translates to:
  /// **'New completed sessions will appear here'**
  String get newSessionsAppearHere;

  /// Title of the export section
  ///
  /// In en, this message translates to:
  /// **'Export Activity Data'**
  String get exportActivityData;

  /// Description of export functionality
  ///
  /// In en, this message translates to:
  /// **'Export your focus sessions and break activity events. You can save them directly to your Downloads folder or copy them to your clipboard.'**
  String get exportActivityDescription;

  /// Button to save activity as CSV file
  ///
  /// In en, this message translates to:
  /// **'Save CSV'**
  String get saveCsv;

  /// Button to save activity as JSON file
  ///
  /// In en, this message translates to:
  /// **'Save JSON'**
  String get saveJson;

  /// Button to copy activity to clipboard as CSV
  ///
  /// In en, this message translates to:
  /// **'Copy CSV'**
  String get copyCsv;

  /// Button to copy activity to clipboard as JSON
  ///
  /// In en, this message translates to:
  /// **'Copy JSON'**
  String get copyJson;

  /// Button to clear all activity history
  ///
  /// In en, this message translates to:
  /// **'Clear activity history'**
  String get clearActivityHistory;

  /// Title of clear history dialog
  ///
  /// In en, this message translates to:
  /// **'Clear activity history?'**
  String get clearHistoryConfirmTitle;

  /// Message inside clear history dialog
  ///
  /// In en, this message translates to:
  /// **'This removes daily totals and completed session details. This cannot be undone.'**
  String get clearHistoryConfirmBody;

  /// Confirm button label in clear history dialog
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// Snackbar message when copying data succeeds
  ///
  /// In en, this message translates to:
  /// **'{formatName} copied to clipboard!'**
  String copiedToClipboard(String formatName);

  /// Snackbar message when file export succeeds
  ///
  /// In en, this message translates to:
  /// **'Exported to file: {fileName}'**
  String exportedToFile(String fileName);

  /// Action button in export success snackbar
  ///
  /// In en, this message translates to:
  /// **'Open Folder'**
  String get openFolder;

  /// Snackbar message when file export fails
  ///
  /// In en, this message translates to:
  /// **'Failed to export to file: {error}'**
  String failedToExport(String error);

  /// Title of the settings page
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// Placeholder for settings search input
  ///
  /// In en, this message translates to:
  /// **'Search settings...'**
  String get settingsSearchPlaceholder;

  /// Message shown when search returns no results
  ///
  /// In en, this message translates to:
  /// **'No settings matching \"{query}\"'**
  String settingsNoResults(String query);

  /// Category for schedule settings
  ///
  /// In en, this message translates to:
  /// **'General Schedule'**
  String get settingsCategoryGeneralSchedule;

  /// Category for break behavior settings
  ///
  /// In en, this message translates to:
  /// **'Break Screen & Behavior'**
  String get settingsCategoryBreakBehavior;

  /// Category for theme settings
  ///
  /// In en, this message translates to:
  /// **'Theme & Appearance'**
  String get settingsCategoryThemeAppearance;

  /// Category for notifications settings
  ///
  /// In en, this message translates to:
  /// **'Notifications & Sounds'**
  String get settingsCategoryNotificationsSounds;

  /// Category for auto run settings
  ///
  /// In en, this message translates to:
  /// **'Auto Run & Long Breaks'**
  String get settingsCategoryAutoRunLongBreaks;

  /// Category for desktop options
  ///
  /// In en, this message translates to:
  /// **'Desktop Options'**
  String get settingsCategoryDesktopOptions;

  /// Category for AI motivation settings
  ///
  /// In en, this message translates to:
  /// **'AI Motivation & Prompts'**
  String get settingsCategoryAiMotivation;

  /// Category for system options
  ///
  /// In en, this message translates to:
  /// **'System Options'**
  String get settingsCategorySystemOptions;

  /// Title for quick presets setting
  ///
  /// In en, this message translates to:
  /// **'Quick presets'**
  String get settingsQuickPresets;

  /// Subtitle for quick presets setting
  ///
  /// In en, this message translates to:
  /// **'20-20-20, 25/5, 45/5, 10s/10s (Test)'**
  String get settingsQuickPresetsSubtitle;

  /// Title for work duration setting
  ///
  /// In en, this message translates to:
  /// **'Work duration'**
  String get settingsWorkDuration;

  /// Subtitle when work duration can be changed
  ///
  /// In en, this message translates to:
  /// **'Choose work interval'**
  String get settingsWorkDurationChoose;

  /// Subtitle when durations are locked
  ///
  /// In en, this message translates to:
  /// **'Pause/cancel timer to change'**
  String get settingsPauseCancelToChange;

  /// Detailed text when duration changes are locked
  ///
  /// In en, this message translates to:
  /// **'Pause or cancel the timer to change this'**
  String get settingsPauseCancelToChangeDesc;

  /// Title for break duration setting
  ///
  /// In en, this message translates to:
  /// **'Break duration'**
  String get settingsBreakDuration;

  /// Subtitle when break duration can be changed
  ///
  /// In en, this message translates to:
  /// **'Choose break length'**
  String get settingsBreakDurationChoose;

  /// Title for daily goal setting
  ///
  /// In en, this message translates to:
  /// **'Daily goal'**
  String get settingsDailyGoal;

  /// Subtitle showing daily goal progress
  ///
  /// In en, this message translates to:
  /// **'{streak} / {goal} breaks today'**
  String settingsDailyGoalProgress(int streak, int goal);

  /// Label for custom option
  ///
  /// In en, this message translates to:
  /// **'Custom...'**
  String get settingsCustom;

  /// Title for history setting
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get settingsHistory;

  /// Subtitle for history setting
  ///
  /// In en, this message translates to:
  /// **'Review your recent eye breaks'**
  String get settingsHistorySubtitle;

  /// Label showing daily cycles count
  ///
  /// In en, this message translates to:
  /// **'Today: {count} cycles'**
  String settingsTodayProgress(int count);

  /// Title for today's progress setting
  ///
  /// In en, this message translates to:
  /// **'Today\'\'s progress'**
  String get settingsTodayProgressTitle;

  /// Subtitle for today's progress setting
  ///
  /// In en, this message translates to:
  /// **'Reset today\'\'s streak'**
  String get settingsResetStreak;

  /// Button label to reset
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get settingsReset;

  /// Title for active work hours setting
  ///
  /// In en, this message translates to:
  /// **'Active work hours & days'**
  String get settingsActiveWorkHours;

  /// Subtitle for active work hours setting
  ///
  /// In en, this message translates to:
  /// **'Only run the timer cycles during specific hours and days'**
  String get settingsActiveWorkHoursSubtitle;

  /// Label for active days section
  ///
  /// In en, this message translates to:
  /// **'Active Days'**
  String get settingsActiveDays;

  /// Label for start time selector
  ///
  /// In en, this message translates to:
  /// **'Start Time'**
  String get settingsStartTime;

  /// Label for end time selector
  ///
  /// In en, this message translates to:
  /// **'End Time'**
  String get settingsEndTime;

  /// Title for auto-start schedule setting
  ///
  /// In en, this message translates to:
  /// **'Auto-start schedule'**
  String get settingsAutoStartSchedule;

  /// Subtitle for auto-start schedule setting
  ///
  /// In en, this message translates to:
  /// **'Automatically start the timer on launch'**
  String get settingsAutoStartScheduleSubtitle;

  /// Title for OS Focus Mode setting
  ///
  /// In en, this message translates to:
  /// **'OS Focus Mode (DND)'**
  String get settingsOsFocusMode;

  /// Subtitle for OS Focus Mode setting
  ///
  /// In en, this message translates to:
  /// **'Toggle system Do Not Disturb (DND) automatically during work phases (Linux GNOME)'**
  String get settingsOsFocusModeSubtitle;

  /// Switch label for OS Focus Mode setting
  ///
  /// In en, this message translates to:
  /// **'Toggle system DND during work phases'**
  String get settingsOsFocusModeToggle;

  /// Helpful note about GNOME DND behavior
  ///
  /// In en, this message translates to:
  /// **'Note: Ubuntu/GNOME does not natively support DND exceptions/whitelist. If you want specific apps to bypass DND, turn this toggle off and instead manually silence noisy apps under Ubuntu System Settings -> Notifications.'**
  String get settingsOsFocusModeGnomeNote;

  /// Title for break screen mode setting
  ///
  /// In en, this message translates to:
  /// **'Break screen mode'**
  String get settingsBreakScreenMode;

  /// Subtitle for break screen mode setting
  ///
  /// In en, this message translates to:
  /// **'Off, Gentle, or Strict break enforcement mode'**
  String get settingsBreakScreenModeSubtitle;

  /// Dropdown explanation for break screen mode
  ///
  /// In en, this message translates to:
  /// **'Strict mode blocks easy exit'**
  String get settingsStrictBlocksExit;

  /// Title for pre-break notification setting
  ///
  /// In en, this message translates to:
  /// **'Pre-break notification alert'**
  String get settingsPreBreakAlert;

  /// Subtitle for pre-break notification setting
  ///
  /// In en, this message translates to:
  /// **'Get a warning notification 10 seconds before the break start'**
  String get settingsPreBreakAlertSubtitle;

  /// Title for allow skip setting
  ///
  /// In en, this message translates to:
  /// **'Allow skip'**
  String get settingsAllowSkip;

  /// Subtitle for allow skip setting
  ///
  /// In en, this message translates to:
  /// **'Allow skipping the break early'**
  String get settingsAllowSkipSubtitle;

  /// Title for allow postpone setting
  ///
  /// In en, this message translates to:
  /// **'Allow postpone'**
  String get settingsAllowPostpone;

  /// Subtitle for allow postpone setting
  ///
  /// In en, this message translates to:
  /// **'Allow postponing the break'**
  String get settingsAllowPostponeSubtitle;

  /// Title for smart pause setting
  ///
  /// In en, this message translates to:
  /// **'Smart Pause & Postpone'**
  String get settingsSmartPausePostpone;

  /// Subtitle for smart pause setting
  ///
  /// In en, this message translates to:
  /// **'Pause work timer automatically when you are idle'**
  String get settingsSmartPausePostponeSubtitle;

  /// Title for natural break credit setting
  ///
  /// In en, this message translates to:
  /// **'Natural break credit'**
  String get settingsNaturalBreakCredit;

  /// Subtitle for natural break credit setting
  ///
  /// In en, this message translates to:
  /// **'Credit away time as a break if away for more than 5 minutes'**
  String get settingsNaturalBreakCreditSubtitle;

  /// Title for break visualizer style setting
  ///
  /// In en, this message translates to:
  /// **'Break visualizer style'**
  String get settingsBreakVisualizerStyle;

  /// Subtitle for break visualizer style setting
  ///
  /// In en, this message translates to:
  /// **'Choose ambient effect during breaks'**
  String get settingsBreakVisualizerStyleSubtitle;

  /// Title for break screen content settings
  ///
  /// In en, this message translates to:
  /// **'Break screen content'**
  String get settingsBreakScreenContent;

  /// Subtitle for break screen content settings
  ///
  /// In en, this message translates to:
  /// **'Choose widgets shown on the break overlay'**
  String get settingsBreakScreenContentSubtitle;

  /// Switch label for showing countdown clock
  ///
  /// In en, this message translates to:
  /// **'Show countdown clock'**
  String get settingsShowCountdown;

  /// Switch label for showing eye-care tips
  ///
  /// In en, this message translates to:
  /// **'Show eye-care tips'**
  String get settingsShowTips;

  /// Switch label for showing progress ring
  ///
  /// In en, this message translates to:
  /// **'Show progress ring'**
  String get settingsShowProgress;

  /// Title for custom reminder text setting
  ///
  /// In en, this message translates to:
  /// **'Custom reminder text'**
  String get settingsCustomReminderText;

  /// Label when custom reminder is empty
  ///
  /// In en, this message translates to:
  /// **'Using built-in rotating messages'**
  String get settingsBuiltInRotatingMessages;

  /// Title for postpone duration setting
  ///
  /// In en, this message translates to:
  /// **'Postpone duration'**
  String get settingsPostponeDuration;

  /// Subtitle for postpone duration setting
  ///
  /// In en, this message translates to:
  /// **'How long to delay the break'**
  String get settingsPostponeDurationSubtitle;

  /// Title for display over other apps setting
  ///
  /// In en, this message translates to:
  /// **'Display over other apps'**
  String get settingsDisplayOverApps;

  /// Button label to allow permission
  ///
  /// In en, this message translates to:
  /// **'Allow'**
  String get settingsAllow;

  /// Title for preview break screen setting
  ///
  /// In en, this message translates to:
  /// **'Preview break screen'**
  String get settingsPreviewBreakScreen;

  /// Subtitle for preview break screen setting
  ///
  /// In en, this message translates to:
  /// **'Show a 10-second black overlay'**
  String get settingsPreviewBreakScreenSubtitle;

  /// Title for test 20s break setting
  ///
  /// In en, this message translates to:
  /// **'Test 20s break screen'**
  String get settingsTest20sBreak;

  /// Subtitle for test 20s break setting
  ///
  /// In en, this message translates to:
  /// **'Launch a real 20-second eye break'**
  String get settingsTest20sBreakSubtitle;

  /// Title for usage access setting
  ///
  /// In en, this message translates to:
  /// **'Usage access'**
  String get settingsUsageAccess;

  /// Label when usage access is allowed
  ///
  /// In en, this message translates to:
  /// **'App detection enabled'**
  String get settingsUsageAccessEnabled;

  /// Label when usage access is required
  ///
  /// In en, this message translates to:
  /// **'Required to detect games & videos'**
  String get settingsUsageAccessRequired;

  /// Title for dark mode setting
  ///
  /// In en, this message translates to:
  /// **'Dark mode'**
  String get settingsDarkMode;

  /// Subtitle for dark mode setting
  ///
  /// In en, this message translates to:
  /// **'Toggle dark or light theme interface'**
  String get settingsDarkModeSubtitle;

  /// Title for AMOLED dark mode setting
  ///
  /// In en, this message translates to:
  /// **'AMOLED dark mode'**
  String get settingsAmoledDarkMode;

  /// Subtitle for AMOLED dark mode setting
  ///
  /// In en, this message translates to:
  /// **'Use pure black backgrounds for battery saving'**
  String get settingsAmoledDarkModeSubtitle;

  /// Title for system accent setting
  ///
  /// In en, this message translates to:
  /// **'Use system accent color'**
  String get settingsUseSystemAccent;

  /// Subtitle for system accent setting
  ///
  /// In en, this message translates to:
  /// **'Follow OS system-accent dynamic colors'**
  String get settingsUseSystemAccentSubtitle;

  /// Title for color preset setting
  ///
  /// In en, this message translates to:
  /// **'Color preset'**
  String get settingsColorPreset;

  /// Subtitle for color preset setting
  ///
  /// In en, this message translates to:
  /// **'Choose your preferred accent color theme preset'**
  String get settingsColorPresetSubtitle;

  /// Header for custom accent colors
  ///
  /// In en, this message translates to:
  /// **'Custom Accent Palette'**
  String get settingsCustomAccentPalette;

  /// Label for custom hex code field
  ///
  /// In en, this message translates to:
  /// **'Accent Color Hex Code'**
  String get settingsAccentColorHex;

  /// Title for notifications setting
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get settingsNotifications;

  /// Subtitle for notifications setting
  ///
  /// In en, this message translates to:
  /// **'Remind me when work or break time ends'**
  String get settingsNotificationsSubtitle;

  /// Title for notification sound setting
  ///
  /// In en, this message translates to:
  /// **'Notification sound'**
  String get settingsNotificationSound;

  /// Subtitle for notification sound setting
  ///
  /// In en, this message translates to:
  /// **'Uses system notification sound settings'**
  String get settingsNotificationSoundSubtitle;

  /// Title for test reminder alert setting
  ///
  /// In en, this message translates to:
  /// **'Test reminder alert'**
  String get settingsTestReminderAlert;

  /// Subtitle for test reminder alert setting
  ///
  /// In en, this message translates to:
  /// **'Play the actual reminder sound now'**
  String get settingsPlayReminderSound;

  /// Label for test reminder
  ///
  /// In en, this message translates to:
  /// **'Test reminder'**
  String get settingsTestReminder;

  /// Title for notification permission status
  ///
  /// In en, this message translates to:
  /// **'Permission status'**
  String get settingsPermissionStatus;

  /// Button label to open settings
  ///
  /// In en, this message translates to:
  /// **'Open system settings'**
  String get settingsOpenSystemSettings;

  /// Information text when notifications are disabled
  ///
  /// In en, this message translates to:
  /// **'Timer alerts are off. The countdown still works in the app.'**
  String get settingsTimerAlertsOff;

  /// Title for precise reminders setting
  ///
  /// In en, this message translates to:
  /// **'Precise reminders'**
  String get settingsPreciseReminders;

  /// Label when precise timing is allowed
  ///
  /// In en, this message translates to:
  /// **'Exact timing allowed'**
  String get settingsPreciseAllowed;

  /// Label when precise timing is disabled
  ///
  /// In en, this message translates to:
  /// **'May arrive a little late'**
  String get settingsPreciseLate;

  /// Title for battery optimization setting
  ///
  /// In en, this message translates to:
  /// **'Background reliability'**
  String get settingsBackgroundReliability;

  /// Label when battery is unrestricted
  ///
  /// In en, this message translates to:
  /// **'Battery use is unrestricted'**
  String get settingsBatteryUnrestricted;

  /// Label when battery is optimized
  ///
  /// In en, this message translates to:
  /// **'Battery optimization may delay alerts'**
  String get settingsBatteryOptimized;

  /// Button label to review battery settings
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get settingsReview;

  /// Title for haptic feedback setting
  ///
  /// In en, this message translates to:
  /// **'Haptics'**
  String get settingsHaptics;

  /// Subtitle for haptic feedback setting
  ///
  /// In en, this message translates to:
  /// **'Vibrate when a timer phase ends'**
  String get settingsVibratePhaseEnd;

  /// Title for in-app sound setting
  ///
  /// In en, this message translates to:
  /// **'In-app sound'**
  String get settingsInAppSound;

  /// Subtitle for in-app sound setting
  ///
  /// In en, this message translates to:
  /// **'Play an extra system alert while BlinkKind is open'**
  String get settingsPlayExtraAlert;

  /// Label for chime style selector
  ///
  /// In en, this message translates to:
  /// **'Chime style'**
  String get settingsChimeStyle;

  /// Subtitle for chime style selector
  ///
  /// In en, this message translates to:
  /// **'Sound to play when a break starts or ends'**
  String get settingsChimeStyleSubtitle;

  /// Title for conscious blinking reminders setting
  ///
  /// In en, this message translates to:
  /// **'Conscious blinking reminders'**
  String get settingsConsciousBlinkingReminders;

  /// Subtitle for conscious blinking reminders setting
  ///
  /// In en, this message translates to:
  /// **'Shows visible OS banner reminders during work, keeping your eyes moist and reducing fatigue'**
  String get settingsConsciousBlinkingSubtitle;

  /// Label for banner interval setting
  ///
  /// In en, this message translates to:
  /// **'Banner interval'**
  String get settingsBannerInterval;

  /// Subtitle for banner interval setting
  ///
  /// In en, this message translates to:
  /// **'How often to show the OS blink banner'**
  String get settingsShowBlinkBanner;

  /// Setting title to toggle interactive buttons on blink notifications
  ///
  /// In en, this message translates to:
  /// **'Interactive blink actions'**
  String get settingsInteractiveBlinkReminders;

  /// Setting subtitle to toggle interactive buttons on blink notifications
  ///
  /// In en, this message translates to:
  /// **'Add a button to check off blink reminders directly from notifications'**
  String get settingsInteractiveBlinkRemindersSubtitle;

  /// Title for tray blink nudges setting
  ///
  /// In en, this message translates to:
  /// **'Tray blink nudges'**
  String get settingsTrayBlinkNudges;

  /// Subtitle for tray blink nudges setting
  ///
  /// In en, this message translates to:
  /// **'Pulses the system tray icon independently from OS banner reminders'**
  String get settingsTrayBlinkNudgesSubtitle;

  /// Label for tray nudge interval setting
  ///
  /// In en, this message translates to:
  /// **'Tray nudge interval'**
  String get settingsTrayNudgeInterval;

  /// Subtitle for tray nudge interval setting
  ///
  /// In en, this message translates to:
  /// **'How often the tray icon should pulse'**
  String get settingsTrayIconPulse;

  /// Title for auto run schedule setting
  ///
  /// In en, this message translates to:
  /// **'Run schedule automatically'**
  String get settingsRunScheduleAutomatically;

  /// Subtitle for auto run schedule setting
  ///
  /// In en, this message translates to:
  /// **'Continue work and break cycles until stopped or limit is reached'**
  String get settingsRunScheduleAutomaticallySubtitle;

  /// Label for cycle limit setting
  ///
  /// In en, this message translates to:
  /// **'Cycle limit'**
  String get settingsCycleLimit;

  /// Subtitle for cycle limit setting
  ///
  /// In en, this message translates to:
  /// **'Completed work cycles in one run'**
  String get settingsCycleLimitSubtitle;

  /// Title for long break mode setting
  ///
  /// In en, this message translates to:
  /// **'Long break mode'**
  String get settingsLongBreakMode;

  /// Subtitle for long break mode setting
  ///
  /// In en, this message translates to:
  /// **'After {count} work cycles, rest for {duration}'**
  String settingsLongBreakModeSubtitle(int count, String duration);

  /// Label for cycle interval setting
  ///
  /// In en, this message translates to:
  /// **'Cycle interval'**
  String get settingsCycleInterval;

  /// Label for long break duration setting
  ///
  /// In en, this message translates to:
  /// **'Long break duration'**
  String get settingsLongBreakDuration;

  /// Switch label for startup launching
  ///
  /// In en, this message translates to:
  /// **'Launch at Startup'**
  String get settingsLaunchAtStartup;

  /// Subtitle for startup launching
  ///
  /// In en, this message translates to:
  /// **'Start BlinkKind automatically when you log in'**
  String get settingsStartBlinkKindAutomatically;

  /// Switch label for starting minimized in tray
  ///
  /// In en, this message translates to:
  /// **'Start minimized'**
  String get settingsStartMinimized;

  /// Subtitle for starting minimized
  ///
  /// In en, this message translates to:
  /// **'Open into the tray on app startup'**
  String get settingsOpenIntoTray;

  /// Switch label for AI motivation
  ///
  /// In en, this message translates to:
  /// **'Enable AI motivation'**
  String get settingsEnableAiMotivation;

  /// Label for AI provider dropdown
  ///
  /// In en, this message translates to:
  /// **'AI Provider'**
  String get settingsAiProvider;

  /// Label for API key text field
  ///
  /// In en, this message translates to:
  /// **'API Key'**
  String get settingsAiApiKey;

  /// Hint text for API key input
  ///
  /// In en, this message translates to:
  /// **'Paste your API key here'**
  String get settingsAiApiKeyHint;

  /// Label for AI model selector
  ///
  /// In en, this message translates to:
  /// **'Model'**
  String get settingsAiModel;

  /// Label for AI system prompt input
  ///
  /// In en, this message translates to:
  /// **'System prompt'**
  String get settingsAiSystemPrompt;

  /// Hint text for AI system prompt input
  ///
  /// In en, this message translates to:
  /// **'Describe what kind of quote you want...'**
  String get settingsAiSystemPromptHint;

  /// Title/Button to reset settings
  ///
  /// In en, this message translates to:
  /// **'Reset settings'**
  String get settingsResetSettings;

  /// Subtitle for reset settings option
  ///
  /// In en, this message translates to:
  /// **'Restore all settings to factory defaults'**
  String get settingsRestoreFactoryDefaults;

  /// Title/Button for backing up settings
  ///
  /// In en, this message translates to:
  /// **'Backup settings'**
  String get settingsBackupSettings;

  /// Subtitle for backing up settings
  ///
  /// In en, this message translates to:
  /// **'Export settings to your Downloads folder'**
  String get settingsExportDownloadsFolder;

  /// Title/Button for restoring settings
  ///
  /// In en, this message translates to:
  /// **'Restore settings'**
  String get settingsRestoreSettings;

  /// Subtitle for restoring settings
  ///
  /// In en, this message translates to:
  /// **'Load settings from a backup JSON file'**
  String get settingsLoadBackupJson;

  /// Title for custom model dialog
  ///
  /// In en, this message translates to:
  /// **'Custom model'**
  String get settingsCustomModelDialogTitle;

  /// Label for custom model name field
  ///
  /// In en, this message translates to:
  /// **'Model name'**
  String get settingsModelName;

  /// Hint for custom model name field
  ///
  /// In en, this message translates to:
  /// **'e.g. gpt-4o, gemini-2.0-flash'**
  String get settingsModelNameHint;

  /// Button label to confirm selection
  ///
  /// In en, this message translates to:
  /// **'Set'**
  String get settingsSet;

  /// Title of restore defaults dialog
  ///
  /// In en, this message translates to:
  /// **'Restore defaults?'**
  String get settingsRestoreDefaultsTitle;

  /// Body description of restore defaults dialog
  ///
  /// In en, this message translates to:
  /// **'This will reset all preferences (durations, presets, sound settings, theme presets, AI configurations, auto-start options) back to factory defaults.\n\nYour streak, history, and recorded activity will NOT be erased.'**
  String get settingsRestoreDefaultsDesc;

  /// Snackbar message after resetting settings
  ///
  /// In en, this message translates to:
  /// **'Settings restored to factory defaults'**
  String get settingsRestoredSnackbar;

  /// Snackbar message after importing backup
  ///
  /// In en, this message translates to:
  /// **'Settings restored successfully!'**
  String get settingsRestoredSuccessSnackbar;

  /// Snackbar message when importing backup fails
  ///
  /// In en, this message translates to:
  /// **'Failed to restore settings: {error}'**
  String settingsRestoredFailedSnackbar(String error);

  /// Title of custom daily goal dialog
  ///
  /// In en, this message translates to:
  /// **'Custom daily goal'**
  String get settingsCustomDailyGoalTitle;

  /// Label for number of breaks field
  ///
  /// In en, this message translates to:
  /// **'Number of breaks'**
  String get settingsNumberOfBreaks;

  /// Hint for number of breaks field
  ///
  /// In en, this message translates to:
  /// **'e.g. 15, 20'**
  String get settingsNumberOfBreaksHint;

  /// Title of custom blink reminder dialog
  ///
  /// In en, this message translates to:
  /// **'Custom blink reminder'**
  String get settingsCustomBlinkReminderTitle;

  /// Hint for custom blink reminder field
  ///
  /// In en, this message translates to:
  /// **'e.g. Time to blink! Rest your eyes.'**
  String get settingsCustomBlinkReminderHint;

  /// Helper for custom blink reminder field
  ///
  /// In en, this message translates to:
  /// **'Leave blank to use built-in messages'**
  String get settingsCustomBlinkReminderHelper;

  /// Button label to save settings
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get settingsSave;

  /// Snackbar message when break is automatically postponed due to camera usage
  ///
  /// In en, this message translates to:
  /// **'Camera in use — break postponed automatically'**
  String get settingsCameraAutoPostponeSnackbar;

  /// Snackbar warning when overlay permission is missing
  ///
  /// In en, this message translates to:
  /// **'Allow display over other apps first.'**
  String get settingsAllowOverlaySnackbar;

  /// Label formatting duration in seconds
  ///
  /// In en, this message translates to:
  /// **'{seconds}s'**
  String settingsDurationSeconds(int seconds);

  /// Label formatting duration in minutes
  ///
  /// In en, this message translates to:
  /// **'{minutes} min'**
  String settingsDurationMinutes(int minutes);

  /// Label formatting interval in seconds
  ///
  /// In en, this message translates to:
  /// **'Every {seconds} sec'**
  String settingsDurationEverySeconds(int seconds);

  /// Label formatting interval in minutes
  ///
  /// In en, this message translates to:
  /// **'Every {minutes} min'**
  String settingsDurationEveryMinutes(int minutes);

  /// Label when cycle limit is disabled
  ///
  /// In en, this message translates to:
  /// **'No limit'**
  String get settingsCycleNoLimit;

  /// Label showing cycle count
  ///
  /// In en, this message translates to:
  /// **'{count} cycles'**
  String settingsCycleLimitCount(int count);

  /// Title for wellness reminders setting
  ///
  /// In en, this message translates to:
  /// **'Wellness reminders'**
  String get settingsWellnessReminders;

  /// Subtitle for wellness reminders setting
  ///
  /// In en, this message translates to:
  /// **'Periodic hydration, posture, and stretch reminders during work'**
  String get settingsWellnessRemindersSubtitle;

  /// Detailed description of wellness reminders
  ///
  /// In en, this message translates to:
  /// **'Alternates hydration, posture, and stretch reminders during work sessions'**
  String get settingsWellnessRemindersDesc;

  /// Label for wellness reminder interval
  ///
  /// In en, this message translates to:
  /// **'Reminder interval'**
  String get settingsReminderInterval;

  /// Description of wellness reminder interval
  ///
  /// In en, this message translates to:
  /// **'How often to send a wellness reminder'**
  String get settingsReminderIntervalDesc;

  /// Title for camera/mic auto-postpone setting
  ///
  /// In en, this message translates to:
  /// **'Camera/mic auto-postpone'**
  String get settingsCameraMicAutoPostpone;

  /// Subtitle for camera/mic auto-postpone setting
  ///
  /// In en, this message translates to:
  /// **'Postpone breaks automatically when camera is in use (video calls)'**
  String get settingsCameraMicAutoPostponeSubtitle;

  /// Detailed description of camera/mic auto-postpone
  ///
  /// In en, this message translates to:
  /// **'Automatically postpone breaks when your camera is in use (e.g. video calls). Linux only.'**
  String get settingsCameraMicAutoPostponeDesc;

  /// Option for wellness reminder cadence
  ///
  /// In en, this message translates to:
  /// **'Every 30 min'**
  String get settingsWellnessEvery30Min;

  /// Option for wellness reminder cadence
  ///
  /// In en, this message translates to:
  /// **'Every 45 min'**
  String get settingsWellnessEvery45Min;

  /// Option for wellness reminder cadence
  ///
  /// In en, this message translates to:
  /// **'Every 1 hour'**
  String get settingsWellnessEvery1Hour;

  /// Option for wellness reminder cadence
  ///
  /// In en, this message translates to:
  /// **'Every 1.5 hours'**
  String get settingsWellnessEvery15Hours;

  /// Option for wellness reminder cadence
  ///
  /// In en, this message translates to:
  /// **'Every 2 hours'**
  String get settingsWellnessEvery2Hours;

  /// Title for AI-powered blink messages setting
  ///
  /// In en, this message translates to:
  /// **'AI-powered blink messages'**
  String get settingsAiBlinkMessages;

  /// Subtitle for AI-powered blink messages setting
  ///
  /// In en, this message translates to:
  /// **'Generate a fresh, unique reminder each time using AI'**
  String get settingsAiBlinkMessagesSubtitle;

  /// Title for custom blink reminder setting
  ///
  /// In en, this message translates to:
  /// **'Custom blink reminder'**
  String get settingsCustomReminder;

  /// System notification permission allowed status
  ///
  /// In en, this message translates to:
  /// **'System permission allowed'**
  String get settingsPermissionAllowed;

  /// System notification permission blocked status
  ///
  /// In en, this message translates to:
  /// **'System permission blocked'**
  String get settingsPermissionBlocked;

  /// System notification permission unsupported status
  ///
  /// In en, this message translates to:
  /// **'Status unavailable on this platform'**
  String get settingsPermissionUnavailable;

  /// Checking notification permission status
  ///
  /// In en, this message translates to:
  /// **'Checking system permission'**
  String get settingsPermissionChecking;

  /// Overlay permission allowed status
  ///
  /// In en, this message translates to:
  /// **'Allowed on this device'**
  String get settingsOverlayAllowed;

  /// Overlay permission disabled status
  ///
  /// In en, this message translates to:
  /// **'Permission required for enforced breaks'**
  String get settingsOverlayRequired;

  /// Checking overlay permission status
  ///
  /// In en, this message translates to:
  /// **'Checking overlay permission'**
  String get settingsOverlayChecking;

  /// Overlay permission unsupported status
  ///
  /// In en, this message translates to:
  /// **'Unavailable on this platform'**
  String get settingsOverlayUnavailable;

  /// Break mode off label
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get settingsBreakModeOff;

  /// Break mode gentle label
  ///
  /// In en, this message translates to:
  /// **'Gentle'**
  String get settingsBreakModeGentle;

  /// Break mode strict label
  ///
  /// In en, this message translates to:
  /// **'Strict'**
  String get settingsBreakModeStrict;

  /// Monday short name
  ///
  /// In en, this message translates to:
  /// **'Mon'**
  String get mon;

  /// Tuesday short name
  ///
  /// In en, this message translates to:
  /// **'Tue'**
  String get tue;

  /// Wednesday short name
  ///
  /// In en, this message translates to:
  /// **'Wed'**
  String get wed;

  /// Thursday short name
  ///
  /// In en, this message translates to:
  /// **'Thu'**
  String get thu;

  /// Friday short name
  ///
  /// In en, this message translates to:
  /// **'Fri'**
  String get fri;

  /// Saturday short name
  ///
  /// In en, this message translates to:
  /// **'Sat'**
  String get sat;

  /// Sunday short name
  ///
  /// In en, this message translates to:
  /// **'Sun'**
  String get sun;

  /// Random visualizer option name
  ///
  /// In en, this message translates to:
  /// **'Random/All'**
  String get settingsVisualizerRandom;

  /// Breathing visualizer option name
  ///
  /// In en, this message translates to:
  /// **'Calm Breathing'**
  String get settingsVisualizerBreathing;

  /// Box breathing visualizer option name
  ///
  /// In en, this message translates to:
  /// **'Box Breathing (4-4-4-4)'**
  String get settingsVisualizerBoxBreathing;

  /// Eye exercises visualizer option name
  ///
  /// In en, this message translates to:
  /// **'Eye Exercises'**
  String get settingsVisualizerEyeExercise;

  /// Blink training visualizer option name
  ///
  /// In en, this message translates to:
  /// **'Blink Training (Blink Pacing)'**
  String get settingsVisualizerBlinkTraining;

  /// Ambient visualizer option name
  ///
  /// In en, this message translates to:
  /// **'Ambient Flow'**
  String get settingsVisualizerAmbient;

  /// Starry visualizer option name
  ///
  /// In en, this message translates to:
  /// **'Starry Sky'**
  String get settingsVisualizerStarry;

  /// Switch subtitle for showing countdown clock
  ///
  /// In en, this message translates to:
  /// **'Display remaining break time'**
  String get settingsShowCountdownDesc;

  /// Switch subtitle for showing eye-care tips
  ///
  /// In en, this message translates to:
  /// **'Rotate guidance during the break'**
  String get settingsShowTipsDesc;

  /// Switch subtitle for showing progress ring
  ///
  /// In en, this message translates to:
  /// **'Visualize break progress on classic layouts'**
  String get settingsShowProgressDesc;

  /// Title/Label for custom break message
  ///
  /// In en, this message translates to:
  /// **'Custom break message'**
  String get settingsCustomBreakMessage;

  /// Subtitle for custom break message setting
  ///
  /// In en, this message translates to:
  /// **'Optional text shown before rotating tips'**
  String get settingsCustomBreakMessageSubtitle;

  /// Hint for custom break message input
  ///
  /// In en, this message translates to:
  /// **'Close your eyes and breathe slowly.'**
  String get settingsCustomBreakMessageHint;

  /// Chime style option: Tibetan Bowl
  ///
  /// In en, this message translates to:
  /// **'Tibetan Bowl'**
  String get settingsChimeTibetanBowl;

  /// Chime style option: Wind Chimes
  ///
  /// In en, this message translates to:
  /// **'Wind Chimes'**
  String get settingsChimeWindChimes;

  /// Chime style option: Zen Bell
  ///
  /// In en, this message translates to:
  /// **'Zen Bell'**
  String get settingsChimeZenBell;

  /// Chime style option: System Alert
  ///
  /// In en, this message translates to:
  /// **'System Alert'**
  String get settingsChimeSystemAlert;

  /// Description of conscious blinking reminders setting
  ///
  /// In en, this message translates to:
  /// **'Sends periodic OS notifications to remind you to blink during work sessions'**
  String get settingsConsciousBlinkingDesc;

  /// Setting title for AI Motivation & Prompts
  ///
  /// In en, this message translates to:
  /// **'AI Motivation & Prompts'**
  String get settingsAiMotivationTitle;

  /// Setting subtitle for AI Motivation & Prompts
  ///
  /// In en, this message translates to:
  /// **'Generate personalised eye-care quotes during breaks'**
  String get settingsAiMotivationSubtitle;

  /// Subtitle for enabling AI motivation switch
  ///
  /// In en, this message translates to:
  /// **'Generate personalised quotes during breaks'**
  String get settingsAiMotivationEnabledSubtitle;

  /// AI provider option: Google Gemini
  ///
  /// In en, this message translates to:
  /// **'Google Gemini'**
  String get settingsAiProviderGemini;

  /// AI provider option: OpenAI ChatGPT
  ///
  /// In en, this message translates to:
  /// **'OpenAI (ChatGPT)'**
  String get settingsAiProviderOpenAi;

  /// AI provider option: Groq Fast
  ///
  /// In en, this message translates to:
  /// **'Groq (Fast)'**
  String get settingsAiProviderGroq;

  /// Dropdown option for custom AI model
  ///
  /// In en, this message translates to:
  /// **'Custom...'**
  String get settingsAiModelCustom;

  /// Error text when loading AI models fails
  ///
  /// In en, this message translates to:
  /// **'Could not load models. Using defaults.'**
  String get settingsAiLoadModelsError;

  /// Snackbar message when settings backup succeeds
  ///
  /// In en, this message translates to:
  /// **'Exported settings to: {fileName}'**
  String settingsExportedSnackbar(String fileName);

  /// Snackbar message when settings backup fails
  ///
  /// In en, this message translates to:
  /// **'Failed to backup settings: {error}'**
  String settingsExportFailedSnackbar(String error);

  /// Subtitle/description for long break mode setting
  ///
  /// In en, this message translates to:
  /// **'Take a longer rest break after a set number of work cycles'**
  String get settingsLongBreakModeDesc;

  /// Setting Item title for desktop startup behavior
  ///
  /// In en, this message translates to:
  /// **'Desktop startup behavior'**
  String get settingsDesktopStartupBehavior;

  /// Setting Item subtitle for desktop startup behavior
  ///
  /// In en, this message translates to:
  /// **'Control login launch and tray-first startup behavior'**
  String get settingsDesktopStartupBehaviorSubtitle;

  /// Button label to export/backup settings
  ///
  /// In en, this message translates to:
  /// **'Backup'**
  String get settingsBackup;

  /// Button label to import/restore settings
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get settingsRestore;

  /// Button label to start break immediately
  ///
  /// In en, this message translates to:
  /// **'Take break now'**
  String get timerTakeBreakNow;

  /// Button label to cancel active snooze
  ///
  /// In en, this message translates to:
  /// **'Cancel snooze'**
  String get timerCancelSnooze;

  /// Button label to snooze timer for 1 hour
  ///
  /// In en, this message translates to:
  /// **'Snooze 1h'**
  String get timerSnooze1h;

  /// Button label to snooze timer until tomorrow
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get timerTomorrow;

  /// Snackbar message when a natural break is credited
  ///
  /// In en, this message translates to:
  /// **'Natural break detected and credited! Timer reset.'**
  String get timerNaturalBreakCredited;

  /// Title of notification permission prompt dialog
  ///
  /// In en, this message translates to:
  /// **'Enable notifications?'**
  String get notificationPermissionTitle;

  /// Content of notification permission prompt dialog
  ///
  /// In en, this message translates to:
  /// **'BlinkKind uses notifications to remind you when your eye break is about to start. Without this permission the reminder will only appear while the app is open.\n\nYou can change this at any time in Settings.'**
  String get notificationPermissionMessage;

  /// Label for not now button
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get notNow;

  /// Label for open settings button
  ///
  /// In en, this message translates to:
  /// **'Open Settings'**
  String get openSettings;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
