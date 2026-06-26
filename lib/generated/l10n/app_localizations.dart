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
