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
}
