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
  String get breakComplianceLabel => 'Break compliance';

  @override
  String get complianceRate => 'Compliance Rate';

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
}
