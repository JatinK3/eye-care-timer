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
