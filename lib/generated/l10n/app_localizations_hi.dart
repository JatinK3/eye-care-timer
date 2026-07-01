// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get appTitle => 'BlinkKind';

  @override
  String get start => 'शुरू करें';

  @override
  String get pause => 'रोकें';

  @override
  String get resume => 'जारी रखें';

  @override
  String get cancel => 'रद्द करें';

  @override
  String get stopTimer => 'टाइमर रोकें';

  @override
  String get skip => 'छोड़ें';

  @override
  String get postpone => 'स्थगित करें';

  @override
  String get snooze => 'स्नूज़ करें';

  @override
  String get breaksTakenToday => 'आज लिए गए अंतराल';

  @override
  String get readyForNextFocusSession => 'अगले फोकस सत्र के लिए तैयार';

  @override
  String get snoozed => 'स्नूज़ किया गया';

  @override
  String get schedulePaused => 'शेड्यूल रोका गया';

  @override
  String get idle => 'निष्क्रिय';

  @override
  String get paused => 'रुका हुआ';

  @override
  String get idlePaused => 'निष्क्रियता के कारण रोका गया';

  @override
  String get breakLabel => 'अंतराल';

  @override
  String get workLabel => 'कार्य';

  @override
  String breaksSnoozed(int minutes) {
    return 'अंतराल स्नूज़ किया गया ($minutes मिनट बचे हैं)';
  }

  @override
  String get timerPausedBySchedule => 'शेड्यूल द्वारा टाइमर रोका गया';

  @override
  String get breakPaused => 'अंतराल रोका गया';

  @override
  String get workPaused => 'कार्य सत्र रोका गया';

  @override
  String get workPausedIdle => 'कार्य सत्र रोका गया (निष्क्रिय)';

  @override
  String get breakTimeMessage => 'अंतराल का समय - 20 फीट दूर देखें';

  @override
  String get workTimeMessage =>
      'कार्य का समय - अपने काम पर ध्यान केंद्रित करें';

  @override
  String get onboardingSubtitle =>
      'काम करते समय हल्के अनुस्मारक के साथ 20-20-20 आदत का पालन करें।';

  @override
  String get onboardingFocusFirstTitle => 'पहले ध्यान केंद्रित करें';

  @override
  String get onboardingFocusFirstBody =>
      'एक फोकस सत्र शुरू करें और टाइमर को ऐप में चलाते रहें।';

  @override
  String get onboardingRestEyesTitle => 'आंकड़ों को आराम दें';

  @override
  String get onboardingRestEyesBody =>
      'जब काम का समय समाप्त हो, तो दूर देखें और अंतराल के दौरान अपनी आँखों को आराम दें।';

  @override
  String get onboardingAllowRemindersTitle => 'अनुस्मारक की अनुमति दें';

  @override
  String get onboardingNotificationsBlocked =>
      'सिस्टम सेटिंग्स में सूचनाएं अवरुद्ध हैं। आप उन्हें बाद में सेटिंग्स से चालू कर सकते हैं।';

  @override
  String get onboardingNotificationsHelp =>
      'जब ऐप स्क्रीन पर न हो, तब भी सूचनाएं टाइमर के माध्यम से आपको याद दिलाने में मदद करती हैं।';

  @override
  String get onboardingAllowAndStart => 'अनुमति दें और शुरू करें';

  @override
  String get onboardingContinueWithoutReminders =>
      'अनुस्मारक के बिना जारी रखें';

  @override
  String get historyTitle => 'इतिहास और विश्लेषण';

  @override
  String get sevenDays => '7 दिन';

  @override
  String get thirtyDays => '30 दिन';

  @override
  String get allTime => 'सभी समय';

  @override
  String get dailyActivityPattern => 'दैनिक गतिविधि पैटर्न';

  @override
  String get noActivityRange => 'इस अवधि में कोई गतिविधि दर्ज नहीं की गई';

  @override
  String get focusDuration => 'फोकस अवधि';

  @override
  String get goalRate => 'लक्ष्य दर';

  @override
  String get longestStreakLabel => 'सबसे लंबी लकीर';

  @override
  String get peakFocusHourLabel => 'पीक फोकस घंटा';

  @override
  String get breakComplianceLabel => 'नेत्र स्वास्थ्य स्कोर';

  @override
  String get complianceRate => 'नेत्र स्वास्थ्य स्कोर';

  @override
  String get milestonesEarnedLabel => 'अर्जित मील के पत्थर';

  @override
  String get achievementsTitle => 'उपलब्धियां';

  @override
  String get productivityInsights => 'उत्पादकता अंतर्दृष्टि';

  @override
  String get completedFocusSessions => 'पूरे किए गए फोकस सत्र';

  @override
  String get cancelledSessions => 'रद्द किए गए सत्र';

  @override
  String get skippedBreaks => 'छोड़े गए अंतराल';

  @override
  String get postponedBreaks => 'स्थगित किए गए अंतराल';

  @override
  String get consciousBlinksLogged => 'सचेत पलकें झपकना दर्ज किया गया';

  @override
  String get recentCompletedSessions => 'हाल के पूरे किए गए सत्र';

  @override
  String get newSessionsAppearHere => 'पूरे किए गए नए सत्र यहां दिखाई देंगे';

  @override
  String get exportActivityData => 'गतिविधि डेटा निर्यात करें';

  @override
  String get exportActivityDescription =>
      'अपने फोकस सत्रों और अंतराल गतिविधि को निर्यात करें। आप उन्हें सीधे डाउनलोड फ़ोल्डर में सहेज सकते हैं या क्लिपबोर्ड पर कॉपी कर सकते हैं।';

  @override
  String get saveCsv => 'CSV सहेजें';

  @override
  String get saveJson => 'JSON सहेजें';

  @override
  String get copyCsv => 'CSV कॉपी करें';

  @override
  String get copyJson => 'JSON कॉपी करें';

  @override
  String get clearActivityHistory => 'गतिविधि इतिहास साफ़ करें';

  @override
  String get clearHistoryConfirmTitle => 'गतिविधि इतिहास साफ़ करें?';

  @override
  String get clearHistoryConfirmBody =>
      'यह दैनिक कुल और पूरे किए गए सत्रों के विवरण को हटा देगा। इसे वापस नहीं लाया जा सकता।';

  @override
  String get clear => 'साफ़ करें';

  @override
  String copiedToClipboard(String formatName) {
    return '$formatName क्लिपबोर्ड पर कॉपी किया गया!';
  }

  @override
  String exportedToFile(String fileName) {
    return 'फ़ाइल में निर्यात किया गया: $fileName';
  }

  @override
  String get openFolder => 'फ़ोल्डर खोलें';

  @override
  String failedToExport(String error) {
    return 'फ़ाइल में निर्यात करने में विफल: $error';
  }

  @override
  String get settingsTitle => 'सेटिंग्स';

  @override
  String get settingsSearchPlaceholder => 'सेटिंग्स खोजें...';

  @override
  String settingsNoResults(String query) {
    return '\"$query\" से मेल खाने वाली कोई सेटिंग्स नहीं मिली';
  }

  @override
  String get settingsCategoryGeneralSchedule => 'सामान्य शेड्यूल';

  @override
  String get settingsCategoryBreakBehavior => 'अंतराल स्क्रीन और व्यवहार';

  @override
  String get settingsCategoryThemeAppearance => 'थीम और उपस्थिति';

  @override
  String get settingsCategoryNotificationsSounds => 'सूचनाएं और ध्वनियां';

  @override
  String get settingsCategoryAutoRunLongBreaks => 'ऑटो रन और लंबे अंतराल';

  @override
  String get settingsCategoryDesktopOptions => 'डेस्कटॉप विकल्प';

  @override
  String get settingsCategoryAiMotivation => 'एआई प्रेरणा और संदेश';

  @override
  String get settingsCategorySystemOptions => 'सिस्टम विकल्प';

  @override
  String get settingsQuickPresets => 'त्वरित प्रीसेट';

  @override
  String get settingsQuickPresetsSubtitle =>
      '20-20-20, 25/5, 45/5, 10s/10s (परीक्षण)';

  @override
  String get settingsWorkDuration => 'काम की अवधि';

  @override
  String get settingsWorkDurationChoose => 'काम का अंतराल चुनें';

  @override
  String get settingsPauseCancelToChange =>
      'बदलने के लिए टाइमर को रोकें/रद्द करें';

  @override
  String get settingsPauseCancelToChangeDesc =>
      'इसे बदलने के लिए टाइमर को रोकें या रद्द करें';

  @override
  String get settingsBreakDuration => 'अंतराल की अवधि';

  @override
  String get settingsBreakDurationChoose => 'अंतराल की लंबाई चुनें';

  @override
  String get settingsDailyGoal => 'दैनिक लक्ष्य';

  @override
  String settingsDailyGoalProgress(int streak, int goal) {
    return 'आज $streak / $goal अंतराल';
  }

  @override
  String get settingsCustom => 'कस्टम...';

  @override
  String get settingsHistory => 'इतिहास';

  @override
  String get settingsHistorySubtitle =>
      'अपने हाल के नेत्र अंतरालों की समीक्षा करें';

  @override
  String settingsTodayProgress(int count) {
    return 'आज: $count चक्र';
  }

  @override
  String get settingsTodayProgressTitle => 'आज की प्रगति';

  @override
  String get settingsResetStreak => 'आज की लकीर रीसेट करें';

  @override
  String get settingsReset => 'रीसेट करें';

  @override
  String get settingsActiveWorkHours => 'सक्रिय कार्य घंटे और दिन';

  @override
  String get settingsActiveWorkHoursSubtitle =>
      'केवल विशिष्ट घंटों और दिनों के दौरान ही टाइमर चक्र चलाएं';

  @override
  String get settingsActiveDays => 'सक्रिय दिन';

  @override
  String get settingsStartTime => 'शुरू होने का समय';

  @override
  String get settingsEndTime => 'समाप्त होने का समय';

  @override
  String get settingsAutoStartSchedule => 'ऑटो-स्टार्ट शेड्यूल';

  @override
  String get settingsAutoStartScheduleSubtitle =>
      'लॉन्च पर स्वचालित रूप से टाइमर शुरू करें';

  @override
  String get settingsOsFocusMode => 'ओएस फोकस मोड (DND)';

  @override
  String get settingsOsFocusModeSubtitle =>
      'काम के चरणों के दौरान स्वचालित रूप से सिस्टम डू नॉट डिस्टर्ब (DND) को टॉगल करें (Linux GNOME / Android)';

  @override
  String get settingsOsFocusModeToggle =>
      'काम के चरणों के दौरान सिस्टम DND टॉगल करें';

  @override
  String get settingsOsFocusModeGnomeNote =>
      'नोट: Ubuntu/GNOME मूल रूप से DND अपवादों/श्वेतसूची का समर्थन नहीं करता है। यदि आप चाहते हैं कि विशिष्ट ऐप DND को बायपास करें, तो इस टॉगल को बंद कर दें और इसके बजाय उबंटू सिस्टम सेटिंग्स -> सूचनाएं के तहत शोर करने वाले ऐप्स को मैन्युअल रूप से शांत करें।';

  @override
  String get settingsBreakScreenMode => 'अंतराल स्क्रीन मोड';

  @override
  String get settingsBreakScreenModeSubtitle =>
      'बंद, हल्का, या सख्त अंतराल प्रवर्तन मोड';

  @override
  String get settingsStrictBlocksExit => 'सख्त मोड आसान निकास को रोकता है';

  @override
  String get settingsPreBreakAlert => 'अंतराल से पहले सूचना अलर्ट';

  @override
  String get settingsPreBreakAlertSubtitle =>
      'अंतराल शुरू होने से 10 सेकंड पहले चेतावनी सूचना प्राप्त करें';

  @override
  String get settingsAllowSkip => 'छोड़ने की अनुमति दें';

  @override
  String get settingsAllowSkipSubtitle =>
      'अंतराल को जल्दी छोड़ने की अनुमति दें';

  @override
  String get settingsAllowPostpone => 'स्थगित करने की अनुमति दें';

  @override
  String get settingsAllowPostponeSubtitle =>
      'अंतराल स्थगित करने की अनुमति दें';

  @override
  String get settingsSmartPausePostpone => 'स्मार्ट विराम और स्थगन';

  @override
  String get settingsSmartPausePostponeSubtitle =>
      'आपके निष्क्रिय होने पर काम का टाइमर अपने आप रोकें';

  @override
  String get settingsNaturalBreakCredit => 'प्राकृतिक अंतराल क्रेडिट';

  @override
  String get settingsNaturalBreakCreditSubtitle =>
      '5 मिनट से अधिक दूर रहने पर उस समय को अंतराल के रूप में क्रेडिट करें';

  @override
  String get settingsBreakVisualizerStyle => 'अंतराल विज़ुअलाइज़र शैली';

  @override
  String get settingsBreakVisualizerStyleSubtitle =>
      'अंतराल के दौरान परिवेश प्रभाव चुनें';

  @override
  String get settingsBreakScreenContent => 'अंतराल स्क्रीन सामग्री';

  @override
  String get settingsBreakScreenContentSubtitle =>
      'अंतराल ओवरले पर दिखाए जाने वाले विजेट चुनें';

  @override
  String get settingsShowCountdown => 'उलटी गिनती घड़ी दिखाएं';

  @override
  String get settingsShowTips => 'आंखों की देखभाल के सुझाव दिखाएं';

  @override
  String get settingsShowProgress => 'प्रगति चक्र दिखाएं';

  @override
  String get settingsCustomReminderText => 'कस्टम अनुस्मारक पाठ';

  @override
  String get settingsBuiltInRotatingMessages =>
      'अंतर्निहित रोटेटिंग संदेशों का उपयोग करना';

  @override
  String get settingsPostponeDuration => 'स्थगन अवधि';

  @override
  String get settingsPostponeDurationSubtitle =>
      'अंतराल को कितनी देर तक टालना है';

  @override
  String get settingsDisplayOverApps => 'अन्य ऐप्स के ऊपर प्रदर्शित करें';

  @override
  String get settingsAllow => 'अनुमति दें';

  @override
  String get settingsPreviewBreakScreen => 'अंतराल स्क्रीन का पूर्वावलोकन';

  @override
  String get settingsPreviewBreakScreenSubtitle =>
      '10-सेकंड का ब्लैक ओवरले दिखाएं';

  @override
  String get settingsTest20sBreak => '20s अंतराल स्क्रीन का परीक्षण करें';

  @override
  String get settingsTest20sBreakSubtitle =>
      'वास्तविक 20-सेकंड का नेत्र अंतराल शुरू करें';

  @override
  String get settingsUsageAccess => 'उपयोग पहुंच';

  @override
  String get settingsUsageAccessEnabled => 'ऐप पहचान सक्षम';

  @override
  String get settingsUsageAccessRequired =>
      'गेम्स और वीडियो का पता लगाने के लिए आवश्यक';

  @override
  String get settingsDarkMode => 'डार्क मोड';

  @override
  String get settingsDarkModeSubtitle => 'डार्क या लाइट थीम इंटरफ़ेस टॉगल करें';

  @override
  String get settingsAmoledDarkMode => 'AMOLED डार्क मोड';

  @override
  String get settingsAmoledDarkModeSubtitle =>
      'बैटरी बचाने के लिए शुद्ध काले रंग के बैकग्राउंड का उपयोग करें';

  @override
  String get settingsReducedMotion => 'कम मोशन (Reduced motion)';

  @override
  String get settingsReducedMotionSubtitle =>
      'यूआई एनिमेशन और जटिल प्रभावों को कम करें';

  @override
  String get settingsUseSystemAccent => 'सिस्टम एक्सेंट रंग का उपयोग करें';

  @override
  String get settingsUseSystemAccentSubtitle =>
      'ओएस सिस्टम-एक्सेंट गतिशील रंगों का पालन करें';

  @override
  String get settingsColorPreset => 'रंग प्रीसेट';

  @override
  String get settingsColorPresetSubtitle =>
      'अपना पसंदीदा एक्सेंट रंग थीम प्रीसेट चुनें';

  @override
  String get settingsCustomAccentPalette => 'कस्टम एक्सेंट पैलेट';

  @override
  String get settingsAccentColorHex => 'एक्सेंट रंग हेक्स कोड';

  @override
  String get settingsNotifications => 'सूचनाएं';

  @override
  String get settingsNotificationsSubtitle =>
      'काम या अंतराल का समय समाप्त होने पर मुझे याद दिलाएं';

  @override
  String get settingsNotificationSound => 'सूचना ध्वनि';

  @override
  String get settingsNotificationSoundSubtitle =>
      'सिस्टम सूचना ध्वनि सेटिंग्स का उपयोग करता है';

  @override
  String get settingsTestReminderAlert => 'परीक्षण अनुस्मारक अलर्ट';

  @override
  String get settingsPlayReminderSound => 'वास्तविक अनुस्मारक ध्वनि अभी चलाएं';

  @override
  String get settingsTestReminder => 'परीक्षण अनुस्मारक';

  @override
  String get settingsPermissionStatus => 'अनुमति की स्थिति';

  @override
  String get settingsOpenSystemSettings => 'सिस्टम सेटिंग्स खोलें';

  @override
  String get settingsTimerAlertsOff =>
      'टाइमर अलर्ट बंद हैं। उलटी गिनती अभी भी ऐप में काम करती है।';

  @override
  String get settingsPreciseReminders => 'सटीक अनुस्मारक';

  @override
  String get settingsPreciseAllowed => 'सटीक समय की अनुमति';

  @override
  String get settingsPreciseLate => 'थोड़ी देर से आ सकता है';

  @override
  String get settingsBackgroundReliability => 'पृष्ठभूमि विश्वसनीयता';

  @override
  String get settingsBatteryUnrestricted => 'बैटरी उपयोग अप्रतिबंधित है';

  @override
  String get settingsBatteryOptimized =>
      'बैटरी अनुकूलन अलर्ट में देरी कर सकता है';

  @override
  String get settingsReview => 'समीक्षा';

  @override
  String get settingsHaptics => 'हैप्टिक्स (कंपन)';

  @override
  String get settingsVibratePhaseEnd => 'टाइमर चरण समाप्त होने पर कंपन करें';

  @override
  String get settingsInAppSound => 'इन-ऐप ध्वनि';

  @override
  String get settingsPlayExtraAlert =>
      'BlinkKind खुले होने के दौरान एक अतिरिक्त सिस्टम अलर्ट चलाएं';

  @override
  String get settingsChimeStyle => 'झंकार शैली';

  @override
  String get settingsChimeStyleSubtitle =>
      'अंतराल शुरू या समाप्त होने पर बजाने वाली ध्वनि';

  @override
  String get settingsConsciousBlinkingReminders =>
      'recordatorios de parpadeo सचेत';

  @override
  String get settingsConsciousBlinkingSubtitle =>
      'काम के दौरान सचेत रूप से पलक झपकने के अनुस्मारक दिखाएं';

  @override
  String get settingsBannerInterval => 'बैनर अंतराल';

  @override
  String get settingsShowBlinkBanner => 'ओएस पलक बैनर कितनी बार दिखाना है';

  @override
  String get settingsInteractiveBlinkReminders => 'इंटरैक्टिव पलक क्रियाएं';

  @override
  String get settingsInteractiveBlinkRemindersSubtitle =>
      'सूचनाओं से सीधे पलक झपकने के अनुस्मारक को चेक करने का विकल्प जोड़ें';

  @override
  String get settingsTrayBlinkNudges => 'ट्रे ब्लिंक संकेत';

  @override
  String get settingsTrayBlinkNudgesSubtitle =>
      'ओएस बैनर अनुस्मारक से स्वतंत्र रूप से सिस्टम ट्रे आइकन को पल्स करें';

  @override
  String get settingsTrayNudgeInterval => 'ट्रे संकेत अंतराल';

  @override
  String get settingsTrayIconPulse => 'ट्रे आइकन कितनी बार पल्स होना चाहिए';

  @override
  String get settingsRunScheduleAutomatically =>
      'स्वचालित रूप से शेड्यूल चलाएं';

  @override
  String get settingsRunScheduleAutomaticallySubtitle =>
      'काम और अंतराल चक्रों को तब तक जारी रखें जब तक रोका न जाए या सीमा तक न पहुंचा जाए';

  @override
  String get settingsCycleLimit => 'चक्र सीमा';

  @override
  String get settingsCycleLimitSubtitle => 'एक रन में पूरे किए गए काम के चक्र';

  @override
  String get settingsLongBreakMode => 'लंबे अंतराल का मोड';

  @override
  String settingsLongBreakModeSubtitle(int count, String duration) {
    return '$count काम के चक्रों के बाद, $duration के लिए आराम करें';
  }

  @override
  String get settingsCycleInterval => 'चक्र अंतराल';

  @override
  String get settingsLongBreakDuration => 'लंबे अंतराल की अवधि';

  @override
  String get settingsLaunchAtStartup => 'स्टार्टअप पर लॉन्च करें';

  @override
  String get settingsStartBlinkKindAutomatically =>
      'लॉग इन करने पर BlinkKind स्वचालित रूप से शुरू करें';

  @override
  String get settingsStartMinimized => 'छोटा करके शुरू करें';

  @override
  String get settingsOpenIntoTray => 'ऐप स्टार्टअप पर सिस्टम ट्रे में खोलें';

  @override
  String get settingsEnableAiMotivation => 'एआई प्रेरणा सक्षम करें';

  @override
  String get settingsAiProvider => 'एआई प्रदाता';

  @override
  String get settingsAiApiKey => 'एपीआई कुंजी';

  @override
  String get settingsAiApiKeyHint => 'अपनी एपीआई कुंजी यहां पेस्ट करें';

  @override
  String get settingsAiModel => 'मॉडल';

  @override
  String get settingsAiSystemPrompt => 'सिस्टम प्रॉम्प्ट';

  @override
  String get settingsAiSystemPromptHint =>
      'वर्णन करें कि आप किस प्रकार का उद्धरण चाहते हैं...';

  @override
  String get settingsResetSettings => 'सेटिंग्स रीसेट करें';

  @override
  String get settingsRestoreFactoryDefaults =>
      'सभी सेटिंग्स को फ़ैक्टरी डिफ़ॉल्ट पर रीसेट करें';

  @override
  String get settingsBackupSettings => 'सेटिंग्स का बैकअप लें';

  @override
  String get settingsExportDownloadsFolder =>
      'सेटिंग्स को अपने डाउनलोड फ़ोल्डर में निर्यात करें';

  @override
  String get settingsRestoreSettings => 'सेटिंग्स पुनर्स्थापित करें';

  @override
  String get settingsLoadBackupJson => 'बैकअप JSON फ़ाइल से सेटिंग्स लोड करें';

  @override
  String get settingsCustomModelDialogTitle => 'कस्टम मॉडल';

  @override
  String get settingsModelName => 'मॉडल का नाम';

  @override
  String get settingsModelNameHint => 'जैसे gpt-4o, gemini-2.0-flash';

  @override
  String get settingsSet => 'सेट करें';

  @override
  String get settingsRestoreDefaultsTitle =>
      'डिफ़ॉल्ट सेटिंग्स पुनर्स्थापित करें?';

  @override
  String get settingsRestoreDefaultsDesc =>
      'यह सभी प्राथमिकताओं (अवधि, प्रीसेट, ध्वनि सेटिंग्स, थीम प्रीसेट, एआई कॉन्फ़िगरेशन, ऑटो-स्टार्ट विकल्प) को फ़ैक्टरी डिफ़ॉल्ट पर रीसेट कर देगा।\n\nआपकी लकीर, इतिहास और गतिविधि का रिकॉर्ड नहीं हटाया जाएगा।';

  @override
  String get settingsRestoredSnackbar =>
      'सेटिंग्स को फ़ैक्टरी डिफ़ॉल्ट पर रीसेट कर दिया गया है';

  @override
  String get settingsRestoredSuccessSnackbar =>
      'सेटिंग्स सफलतापूर्वक पुनर्स्थापित की गईं!';

  @override
  String settingsRestoredFailedSnackbar(String error) {
    return 'सेटिंग्स पुनर्स्थापित करने में विफल: $error';
  }

  @override
  String get settingsCustomDailyGoalTitle => 'कस्टम दैनिक लक्ष्य';

  @override
  String get settingsNumberOfBreaks => 'अंतरालों की संख्या';

  @override
  String get settingsNumberOfBreaksHint => 'जैसे 15, 20';

  @override
  String get settingsCustomBlinkReminderTitle => 'कस्टम पलक अनुस्मारक';

  @override
  String get settingsCustomBlinkReminderHint =>
      'जैसे पलक झपकने का समय! अपनी आँखों को आराम दें।';

  @override
  String get settingsCustomBlinkReminderHelper =>
      'अंतर्निहित संदेशों का उपयोग करने के लिए खाली छोड़ दें';

  @override
  String get settingsSave => 'सहेजें';

  @override
  String get settingsCameraAutoPostponeSnackbar =>
      'कैमरा उपयोग में है — अंतराल अपने आप स्थगित कर दिया गया';

  @override
  String get settingsAllowOverlaySnackbar =>
      'पहले अन्य ऐप्स के ऊपर प्रदर्शित करने की अनुमति दें।';

  @override
  String settingsDurationSeconds(int seconds) {
    return '${seconds}s';
  }

  @override
  String settingsDurationMinutes(int minutes) {
    return '$minutes मिनट';
  }

  @override
  String settingsDurationEverySeconds(int seconds) {
    return 'प्रत्येक $seconds सेकंड';
  }

  @override
  String settingsDurationEveryMinutes(int minutes) {
    return 'प्रत्येक $minutes मिनट';
  }

  @override
  String get settingsCycleNoLimit => 'कोई सीमा नहीं';

  @override
  String settingsCycleLimitCount(int count) {
    return '$count चक्र';
  }

  @override
  String get settingsWellnessReminders => 'कल्याण अनुस्मारक';

  @override
  String get settingsWellnessRemindersSubtitle =>
      'काम के दौरान समय-समय पर पानी पीने, बैठने की स्थिति और खिंचाव के अनुस्मारक';

  @override
  String get settingsWellnessRemindersDesc =>
      'कार्य सत्रों के दौरान पानी पीने, बैठने की स्थिति और खिंचाव के अनुस्मारक को बदलता है';

  @override
  String get settingsReminderInterval => 'अनुस्मारक अंतराल';

  @override
  String get settingsReminderIntervalDesc =>
      'कल्याण अनुस्मारक कितनी बार भेजना है';

  @override
  String get settingsCameraMicAutoPostpone => 'कैमरा/माइक ऑटो-स्थगन';

  @override
  String get settingsCameraMicAutoPostponeSubtitle =>
      'कैमरा उपयोग में होने पर अंतराल को अपने आप टालें (वीडियो कॉल)';

  @override
  String get settingsCameraMicAutoPostponeDesc =>
      'जब आपका कैमरा या माइक्रोफ़ोन उपयोग में हो (जैसे वीडियो कॉल) तो स्वचालित रूप से अंतराल को स्थगित कर दें। केवल लिनक्स और एंड्रॉइड।';

  @override
  String get settingsAutoPauseOnMedia => 'मीडिया प्लेबैक ऑटो-पॉज़';

  @override
  String get settingsAutoPauseOnMediaSubtitle =>
      'वीडियो या संगीत चलने पर अंतराल को अपने आप रोकें';

  @override
  String get settingsAutoPauseOnMediaDesc =>
      'पृष्ठभूमि मीडिया (संगीत या वीडियो) सक्रिय होने पर टाइमर को स्वचालित रूप से रोकें। केवल एंड्रॉइड और लिनक्स।';

  @override
  String get settingsWellnessEvery30Min => 'प्रत्येक 30 मिनट';

  @override
  String get settingsWellnessEvery45Min => 'प्रत्येक 45 मिनट';

  @override
  String get settingsWellnessEvery1Hour => 'प्रत्येक 1 घंटा';

  @override
  String get settingsWellnessEvery15Hours => 'प्रत्येक 1.5 घंटे';

  @override
  String get settingsWellnessEvery2Hours => 'प्रत्येक 2 घंटे';

  @override
  String get settingsAiBlinkMessages => 'एआई-संचालित पलक संदेश';

  @override
  String get settingsAiBlinkMessagesSubtitle =>
      'एआई का उपयोग करके हर बार एक ताज़ा और अनोखा अनुस्मारक उत्पन्न करें';

  @override
  String get settingsCustomReminder => 'कस्टम पलक अनुस्मारक';

  @override
  String get settingsPermissionAllowed => 'सिस्टम अनुमति प्राप्त';

  @override
  String get settingsPermissionBlocked => 'सिस्टम अनुमति अवरुद्ध';

  @override
  String get settingsPermissionUnavailable =>
      'इस प्लेटफ़ॉर्म पर स्थिति अनुपलब्ध';

  @override
  String get settingsPermissionChecking => 'सिस्टम अनुमति की जांच की जा रही है';

  @override
  String get settingsOverlayAllowed => 'इस डिवाइस पर अनुमति प्राप्त';

  @override
  String get settingsOverlayRequired =>
      'अनिवार्य अंतरालों के लिए अनुमति आवश्यक';

  @override
  String get settingsOverlayChecking => 'ओवरले अनुमति की जांच की जा रही है';

  @override
  String get settingsOverlayUnavailable => 'इस प्लेटफ़ॉर्म पर अनुपलब्ध';

  @override
  String get settingsBreakModeOff => 'बंद';

  @override
  String get settingsBreakModeGentle => 'हल्का';

  @override
  String get settingsBreakModeStrict => 'सख्त';

  @override
  String get mon => 'सोम';

  @override
  String get tue => 'मंगल';

  @override
  String get wed => 'बुध';

  @override
  String get thu => 'गुरु';

  @override
  String get fri => 'शुक्र';

  @override
  String get sat => 'शनि';

  @override
  String get sun => 'रवि';

  @override
  String get settingsVisualizerRandom => 'यादृच्छिक/सभी';

  @override
  String get settingsVisualizerBreathing => 'Respiración tranquila';

  @override
  String get settingsVisualizerBoxBreathing => 'Respiración cuadrada (4-4-4-4)';

  @override
  String get settingsVisualizerEyeExercise => 'आँखों के व्यायाम';

  @override
  String get settingsVisualizerBlinkTraining =>
      'Entrenamiento de parpadeo (Paso de parpadeo)';

  @override
  String get settingsVisualizerAmbient => 'परिवेशी प्रवाह';

  @override
  String get settingsVisualizerStarry => 'तारों भरा आकाश';

  @override
  String get settingsShowCountdownDesc => 'बचे हुए अंतराल का समय दिखाएं';

  @override
  String get settingsShowTipsDesc => 'अंतराल के दौरान सुझावों को बदलें';

  @override
  String get settingsShowProgressDesc =>
      'क्लासिक लेआउट पर अंतराल की प्रगति दिखाएं';

  @override
  String get settingsCustomBreakMessage => 'कस्टम अंतराल संदेश';

  @override
  String get settingsCustomBreakMessageSubtitle =>
      'रोटेटिंग सुझावों से पहले दिखाया जाने वाला वैकल्पिक पाठ';

  @override
  String get settingsCustomBreakMessageHint =>
      'अपनी आँखें बंद करें और धीरे-धीरे साँस लें।';

  @override
  String get settingsChimeTibetanBowl => 'तिब्बती कटोरा';

  @override
  String get settingsChimeWindChimes => 'पवन झंकार';

  @override
  String get settingsChimeZenBell => 'ज़ेन घंटी';

  @override
  String get settingsChimeSystemAlert => 'सिस्टम अलर्ट';

  @override
  String get settingsConsciousBlinkingDesc =>
      'काम के दौरान आपको पलक झपकने की याद दिलाने के लिए समय-समय पर ओएस सूचनाएं भेजता है';

  @override
  String get settingsAiMotivationTitle => 'एआई प्रेरणा और संदेश';

  @override
  String get settingsAiMotivationSubtitle =>
      'अंतराल के दौरान व्यक्तिगत नेत्र-देखभाल उद्धरण उत्पन्न करें';

  @override
  String get settingsAiMotivationEnabledSubtitle =>
      'अंतराल के दौरान व्यक्तिगत उद्धरण उत्पन्न करें';

  @override
  String get settingsAiProviderGemini => 'गूगल जेमिनी';

  @override
  String get settingsAiProviderOpenAi => 'OpenAI (ChatGPT)';

  @override
  String get settingsAiProviderGroq => 'Groq (तेज़)';

  @override
  String get settingsAiModelCustom => 'कस्टम...';

  @override
  String get settingsAiLoadModelsError =>
      'मॉडल लोड नहीं किए जा सके। डिफ़ॉल्ट का उपयोग किया जा रहा है।';

  @override
  String settingsExportedSnackbar(String fileName) {
    return 'सेटिंग्स निर्यात की गईं: $fileName';
  }

  @override
  String settingsExportFailedSnackbar(String error) {
    return 'बैकअप विफल: $error';
  }

  @override
  String get settingsLongBreakModeDesc =>
      'काम के चक्रों के बाद एक लंबा अंतराल लें';

  @override
  String get settingsDesktopStartupBehavior => 'डेस्कटॉप स्टार्टअप व्यवहार';

  @override
  String get settingsDesktopStartupBehaviorSubtitle =>
      'लॉगिन लॉन्च और सिस्टम ट्रे व्यवहार को नियंत्रित करें';

  @override
  String get settingsBackup => 'बैकअप';

  @override
  String get settingsRestore => 'पुनर्स्थापित करें';

  @override
  String get timerTakeBreakNow => 'अभी अंतराल लें';

  @override
  String get timerCancelSnooze => 'स्नूज़ रद्द करें';

  @override
  String get timerSnooze1h => '1 घंटे स्नूज़';

  @override
  String get timerTomorrow => 'कल';

  @override
  String get timerNaturalBreakCredited =>
      'प्राकृतिक अंतराल दर्ज किया गया! टाइमर रीसेट।';

  @override
  String get notificationPermissionTitle => 'सूचनाएं सक्षम करें?';

  @override
  String get notificationPermissionMessage =>
      'BlinkKind अंतराल शुरू होने पर आपको याद दिलाने के लिए सूचनाओं का उपयोग करता है। अनुमति के बिना, अनुस्मारक केवल ऐप खुला होने पर दिखाई देगा।\n\nआप इसे कभी भी बदल सकते हैं।';

  @override
  String get notNow => 'अभी नहीं';

  @override
  String get openSettings => 'सेटिंग्स खोलें';

  @override
  String get settingsCategoryAbout => 'BlinkKind के बारे में';

  @override
  String get settingsAboutVersion => 'ऐप संस्करण';

  @override
  String get settingsAboutPrivacyTitle => 'गोपनीयता नीति';

  @override
  String get settingsAboutPrivacySubtitle => '100% ऑफ़लाइन और स्थानीय-प्रथम';

  @override
  String get settingsAboutPrivacyBody =>
      'BlinkKind एक स्थानीय-प्रथम और 100% ऑफ़लाइन एप्लिकेशन है। आपका इतिहास, डेटा और सेटिंग्स पूरी तरह से आपके डिवाइस पर सुरक्षित रहते हैं। हम किसी भी व्यक्तिगत जानकारी को न तो ट्रैक करते हैं और न ही एकत्र करते हैं।';

  @override
  String get settingsAboutLicensesTitle => 'ओपन सोर्स लाइसेंस';

  @override
  String get settingsAboutLicensesSubtitle =>
      'उपयोग की गई तृतीय-पक्ष सॉफ़्टवेयर लाइब्रेरी';

  @override
  String get close => 'बंद करें';

  @override
  String get batteryWarningTitle => 'बैटरी प्रतिबंध पाए गए';

  @override
  String get batteryWarningSubtitleGeneric =>
      'बैटरी अनुकूलन पृष्ठभूमि अंतराल अनुस्मारक को रोक रहा है। BlinkKind को अनुमति देने के लिए सुधारें पर टैप करें।';

  @override
  String get batteryWarningFix => 'सुधारें';

  @override
  String get batteryWarningDismiss => 'हटाएं';

  @override
  String get settingsBatteryOptimizationRestricted =>
      'प्रतिबंधित — अंतराल अनुस्मारक में देरी हो सकती है';

  @override
  String get settingsBatteryOptimizationFix => 'बैटरी सेटिंग्स ठीक करें';
}
