import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:eyeapptimer/app.dart';
import 'package:eyeapptimer/services/break_overlay_service.dart';
import 'package:eyeapptimer/services/notification_service.dart';
import 'package:eyeapptimer/services/preferences_service.dart';
import 'package:eyeapptimer/models/work_session_record.dart';
import 'package:eyeapptimer/models/timer_event_record.dart';
import 'package:eyeapptimer/features/timer/timer_home_page.dart';

class FakeBreakOverlayService extends BreakOverlayService {
  OverlayPermissionStatus status;
  int openSettingsCount = 0;
  int previewCount = 0;

  FakeBreakOverlayService({this.status = OverlayPermissionStatus.allowed});

  @override
  Future<OverlayPermissionStatus> permissionStatus() async => status;

  @override
  Future<bool> openPermissionSettings() async {
    openSettingsCount++;
    return true;
  }

  @override
  Future<bool> showPreview({String breakVisualizerStyle = 'Breathing'}) async {
    previewCount++;
    return status == OverlayPermissionStatus.allowed;
  }
}

class FakeNotificationService extends NotificationService {
  NotificationPermissionStatus status;
  int workReminderCount = 0;
  int breakReminderCount = 0;
  Duration? lastBreakReminderDelay;
  int cancelCount = 0;
  int permissionStatusCheckCount = 0;
  int requestPermissionCount = 0;
  int openSettingsCount = 0;
  int openChannelSettingsCount = 0;
  int testReminderCount = 0;

  FakeNotificationService({this.status = NotificationPermissionStatus.allowed});

  @override
  Future<void> initialize() async {}

  @override
  Future<void> requestPermissions() async {
    requestPermissionCount++;
  }

  @override
  Future<NotificationPermissionStatus> permissionStatus() async {
    permissionStatusCheckCount++;
    return status;
  }

  @override
  Future<NotificationReliabilityStatus> reliabilityStatus() async {
    permissionStatusCheckCount++;
    return NotificationReliabilityStatus(
      permission: status,
      exactAlarms: ExactAlarmStatus.allowed,
      batteryOptimization: BatteryOptimizationStatus.unrestricted,
    );
  }

  @override
  Future<bool> scheduleWorkCompleteReminder(Duration delay) async {
    workReminderCount++;
    return true;
  }

  @override
  Future<bool> scheduleBreakCompleteReminder(Duration delay) async {
    breakReminderCount++;
    lastBreakReminderDelay = delay;
    return true;
  }

  @override
  Future<void> cancelPhaseReminder() async {
    cancelCount++;
  }

  @override
  Future<void> cancelPreBreakWarningReminder() async {}

  @override
  Future<bool> schedulePreBreakWarningReminder(Duration delay) async {
    return true;
  }

  @override
  Future<bool> showTestReminder() async {
    testReminderCount++;
    return true;
  }

  @override
  Future<bool> openReminderChannelSettings() async {
    openChannelSettingsCount++;
    return true;
  }

  @override
  Future<bool> openNotificationSettings() async {
    openSettingsCount++;
    return true;
  }
}

Future<FakeNotificationService> pumpBlinkKindApp(
  WidgetTester tester, {
  NotificationPermissionStatus permissionStatus =
      NotificationPermissionStatus.allowed,
  FakeBreakOverlayService? breakOverlayService,
}) async {
  final notificationService = FakeNotificationService(status: permissionStatus);
  final overlayService = breakOverlayService ?? FakeBreakOverlayService();
  await tester.pumpWidget(
    BlinkKindApp(
      notificationService: notificationService,
      breakOverlayService: overlayService,
    ),
  );
  await tester.pump();
  await tester.pump();
  return notificationService;
}

String todayKey() {
  final today = DateTime.now();
  final year = today.year.toString().padLeft(4, '0');
  final month = today.month.toString().padLeft(2, '0');
  final day = today.day.toString().padLeft(2, '0');
  return '$year-$month-$day';
}

String dateKey(DateTime date) {
  final year = date.year.toString().padLeft(4, '0');
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '$year-$month-$day';
}

double contrastRatio(Color first, Color second) {
  final firstLuminance = first.computeLuminance();
  final secondLuminance = second.computeLuminance();
  final lighter = firstLuminance > secondLuminance
      ? firstLuminance
      : secondLuminance;
  final darker = firstLuminance > secondLuminance
      ? secondLuminance
      : firstLuminance;
  return (lighter + 0.05) / (darker + 0.05);
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({
      PreferencesService.onboardingCompletedKey: true,
    });
  });

  testWidgets('BlinkKind app renders initial timer state', (
    WidgetTester tester,
  ) async {
    await pumpBlinkKindApp(tester);

    expect(find.text('BlinkKind'), findsOneWidget);
    expect(
      find.textContaining('Ready for your next focus session'),
      findsOneWidget,
    );
    expect(find.text('20:00'), findsOneWidget);
    expect(find.text('Start'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
    expect(find.textContaining('Daily goal: 0 / 6 breaks'), findsOneWidget);
    expect(find.textContaining('Streak today: 0 cycles'), findsOneWidget);
  });

  testWidgets('first run onboarding can request reminders', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      PreferencesService.onboardingCompletedKey: false,
    });

    final notificationService = await pumpBlinkKindApp(tester);

    expect(
      find.text(
        'Follow the 20-20-20 habit with gentle reminders while you work.',
      ),
      findsOneWidget,
    );
    expect(find.text('Allow reminders and start'), findsOneWidget);

    await tester.tap(find.text('Allow reminders and start'));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Ready for your next focus session'),
      findsOneWidget,
    );
    expect(notificationService.requestPermissionCount, 1);
  });

  testWidgets('loads saved duration and daily streak preferences', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      PreferencesService.onboardingCompletedKey: true,
      PreferencesService.workDurationSecondsKey: 5 * 60,
      PreferencesService.breakDurationSecondsKey: 60,
      PreferencesService.streakDateKey: todayKey(),
      PreferencesService.streakCountKey: 2,
      PreferencesService.dailyGoalKey: 8,
    });

    await pumpBlinkKindApp(tester);

    expect(find.text('05:00'), findsOneWidget);
    expect(find.textContaining('Daily goal: 2 / 8 breaks'), findsOneWidget);
    expect(find.textContaining('Streak today: 2 cycles'), findsOneWidget);
  });

  testWidgets('restores a paused work session', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({
      PreferencesService.onboardingCompletedKey: true,
      PreferencesService.sessionIsActiveKey: true,
      PreferencesService.sessionIsBreakKey: false,
      PreferencesService.sessionIsPausedKey: true,
      PreferencesService.sessionInitialDurationSecondsKey: 20 * 60,
      PreferencesService.sessionRemainingSecondsKey: 5 * 60,
    });

    final notificationService = await pumpBlinkKindApp(tester);

    expect(find.text('Resume'), findsOneWidget);
    expect(find.text('05:00'), findsOneWidget);
    expect(notificationService.workReminderCount, 0);
  });

  testWidgets('restores a running break session and reschedules reminder', (
    WidgetTester tester,
  ) async {
    final now = DateTime.now();
    SharedPreferences.setMockInitialValues({
      PreferencesService.onboardingCompletedKey: true,
      PreferencesService.sessionIsActiveKey: true,
      PreferencesService.sessionIsBreakKey: true,
      PreferencesService.sessionIsPausedKey: false,
      PreferencesService.sessionInitialDurationSecondsKey: 20,
      PreferencesService.sessionRemainingSecondsKey: 12,
      PreferencesService.sessionPhaseStartedAtKey: now
          .subtract(const Duration(seconds: 8))
          .millisecondsSinceEpoch,
      PreferencesService.sessionPhaseEndsAtKey: now
          .add(const Duration(seconds: 12))
          .millisecondsSinceEpoch,
    });

    final notificationService = await pumpBlinkKindApp(tester);

    expect(find.textContaining('Break Time'), findsOneWidget);
    expect(find.text('Pause'), findsOneWidget);
    expect(notificationService.breakReminderCount, 1);
  });

  testWidgets('expired saved work session moves into remaining break', (
    WidgetTester tester,
  ) async {
    final now = DateTime.now();
    SharedPreferences.setMockInitialValues({
      PreferencesService.onboardingCompletedKey: true,
      PreferencesService.breakDurationSecondsKey: 20,
      PreferencesService.sessionIsActiveKey: true,
      PreferencesService.sessionIsBreakKey: false,
      PreferencesService.sessionIsPausedKey: false,
      PreferencesService.sessionInitialDurationSecondsKey: 20 * 60,
      PreferencesService.sessionRemainingSecondsKey: 1,
      PreferencesService.sessionPhaseStartedAtKey: now
          .subtract(const Duration(minutes: 20, seconds: 5))
          .millisecondsSinceEpoch,
      PreferencesService.sessionPhaseEndsAtKey: now
          .subtract(const Duration(seconds: 5))
          .millisecondsSinceEpoch,
    });

    final notificationService = await pumpBlinkKindApp(tester);
    await tester.pump();

    expect(find.textContaining('Break Time'), findsOneWidget);
    expect(find.text('Pause'), findsOneWidget);
    expect(find.textContaining('Streak today: 1 cycles'), findsOneWidget);
    expect(notificationService.breakReminderCount, 1);
  });

  testWidgets('expired break auto starts the next work cycle', (
    WidgetTester tester,
  ) async {
    final now = DateTime.now();
    SharedPreferences.setMockInitialValues({
      PreferencesService.onboardingCompletedKey: true,
      PreferencesService.autoRunEnabledKey: true,
      PreferencesService.autoRunCycleLimitKey: 3,
      PreferencesService.sessionIsActiveKey: true,
      PreferencesService.sessionIsBreakKey: true,
      PreferencesService.sessionIsPausedKey: false,
      PreferencesService.sessionInitialDurationSecondsKey: 20,
      PreferencesService.sessionRemainingSecondsKey: 1,
      PreferencesService.sessionPhaseStartedAtKey: now
          .subtract(const Duration(seconds: 25))
          .millisecondsSinceEpoch,
      PreferencesService.sessionPhaseEndsAtKey: now
          .subtract(const Duration(seconds: 5))
          .millisecondsSinceEpoch,
      PreferencesService.sessionCompletedAutoRunCyclesKey: 1,
    });

    final notificationService = await pumpBlinkKindApp(tester);
    await tester.pump();

    expect(find.textContaining('Work Time'), findsOneWidget);
    expect(find.text('Pause'), findsOneWidget);
    expect(notificationService.workReminderCount, 1);
  });

  testWidgets('expired break stops when the auto run limit is reached', (
    WidgetTester tester,
  ) async {
    final now = DateTime.now();
    SharedPreferences.setMockInitialValues({
      PreferencesService.onboardingCompletedKey: true,
      PreferencesService.autoRunEnabledKey: true,
      PreferencesService.autoRunCycleLimitKey: 1,
      PreferencesService.sessionIsActiveKey: true,
      PreferencesService.sessionIsBreakKey: true,
      PreferencesService.sessionIsPausedKey: false,
      PreferencesService.sessionInitialDurationSecondsKey: 20,
      PreferencesService.sessionRemainingSecondsKey: 1,
      PreferencesService.sessionPhaseStartedAtKey: now
          .subtract(const Duration(seconds: 25))
          .millisecondsSinceEpoch,
      PreferencesService.sessionPhaseEndsAtKey: now
          .subtract(const Duration(seconds: 5))
          .millisecondsSinceEpoch,
      PreferencesService.sessionCompletedAutoRunCyclesKey: 1,
    });

    final notificationService = await pumpBlinkKindApp(tester);
    await tester.pump();

    expect(find.text('Start'), findsOneWidget);
    expect(notificationService.workReminderCount, 0);
  });

  testWidgets('settings screen updates idle work duration', (
    WidgetTester tester,
  ) async {
    await pumpBlinkKindApp(tester);

    await tester.tap(find.byIcon(Icons.settings));
    await tester.pumpAndSettle();

    expect(find.text('Settings'), findsOneWidget);

    await tester.tap(find.text('General Schedule'));
    await tester.pumpAndSettle();

    expect(find.text('Work duration'), findsOneWidget);

    await tester.tap(find.text('20 min'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('5 min').last);
    await tester.pumpAndSettle();

    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(find.text('05:00'), findsOneWidget);
  });

  testWidgets('settings launches the break overlay preview', (
    WidgetTester tester,
  ) async {
    final overlayService = FakeBreakOverlayService();
    await pumpBlinkKindApp(tester, breakOverlayService: overlayService);

    await tester.tap(find.byIcon(Icons.settings));
    await tester.pumpAndSettle();

    final categoryHeader = find.text('Break Screen & Behavior');
    await tester.scrollUntilVisible(categoryHeader, 200, scrollable: find.byType(Scrollable).first);
    await tester.tap(categoryHeader);
    await tester.pumpAndSettle();

    final previewButton = find.byTooltip('Preview break overlay');
    await tester.scrollUntilVisible(previewButton, 200, scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();

    expect(find.text('Display over other apps'), findsOneWidget);
    expect(find.text('Allowed on this device'), findsOneWidget);

    await tester.tap(previewButton);
    await tester.pumpAndSettle();

    expect(overlayService.previewCount, 1);
  });

  testWidgets('settings opens the overlay permission screen', (
    WidgetTester tester,
  ) async {
    final overlayService = FakeBreakOverlayService(
      status: OverlayPermissionStatus.disabled,
    );
    await pumpBlinkKindApp(tester, breakOverlayService: overlayService);

    await tester.tap(find.byIcon(Icons.settings));
    await tester.pumpAndSettle();

    final categoryHeader = find.text('Break Screen & Behavior');
    await tester.scrollUntilVisible(categoryHeader, 200, scrollable: find.byType(Scrollable).first);
    await tester.tap(categoryHeader);
    await tester.pumpAndSettle();

    // Scroll until the unique overlay 'Allow' button is visible.
    final allowButton = find.byKey(const ValueKey('overlay_allow_button'));
    await tester.scrollUntilVisible(allowButton, 200, scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();

    expect(find.text('Permission required for enforced breaks'), findsOneWidget);
    expect(allowButton, findsOneWidget);
    await tester.tap(allowButton);
    await tester.pumpAndSettle();

    expect(overlayService.openSettingsCount, 1);
  });


  testWidgets('settings configures automatic schedule cycles', (
    WidgetTester tester,
  ) async {
    await pumpBlinkKindApp(tester);

    await tester.tap(find.byIcon(Icons.settings));
    await tester.pumpAndSettle();

    final categoryHeader = find.text('Auto Run & Long Breaks');
    await tester.scrollUntilVisible(categoryHeader, 200, scrollable: find.byType(Scrollable).first);
    await tester.tap(categoryHeader);
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text('Run schedule automatically'), 200, scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();

    await tester.tap(
      find.widgetWithText(SwitchListTile, 'Run schedule automatically'),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Unlimited'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('3 cycles').last);
    await tester.pumpAndSettle();

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool(PreferencesService.autoRunEnabledKey), isTrue);
    expect(prefs.getInt(PreferencesService.autoRunCycleLimitKey), 3);
  });

  testWidgets('settings updates break screen mode', (
    WidgetTester tester,
  ) async {
    await pumpBlinkKindApp(tester);

    await tester.tap(find.byIcon(Icons.settings));
    await tester.pumpAndSettle();

    final categoryHeader = find.text('Break Screen & Behavior');
    await tester.scrollUntilVisible(categoryHeader, 200, scrollable: find.byType(Scrollable).first);
    await tester.tap(categoryHeader);
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text('Break screen mode'), 200, scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();

    expect(find.text('Gentle'), findsOneWidget);

    await tester.tap(find.text('Gentle'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Strict').last);
    await tester.pumpAndSettle();

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(PreferencesService.breakModeKey), 'strict');
  });

  testWidgets('settings applies quick timer presets', (
    WidgetTester tester,
  ) async {
    await pumpBlinkKindApp(tester);

    await tester.tap(find.byIcon(Icons.settings));
    await tester.pumpAndSettle();

    final categoryHeader = find.text('General Schedule');
    await tester.scrollUntilVisible(categoryHeader, 200, scrollable: find.byType(Scrollable).first);
    await tester.tap(categoryHeader);
    await tester.pumpAndSettle();

    await tester.tap(find.text('25 / 5'));
    await tester.pumpAndSettle();

    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(find.text('25:00'), findsOneWidget);
    expect(find.textContaining('for 5 min'), findsOneWidget);
  });

  testWidgets('dark mode start button keeps readable contrast', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      PreferencesService.onboardingCompletedKey: true,
      PreferencesService.themeModeKey: 'dark',
      PreferencesService.colorPresetKey: 'Pastel',
    });

    await pumpBlinkKindApp(tester);

    final button = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'Start'),
    );
    final background = button.style?.backgroundColor?.resolve({});
    final foreground = button.style?.foregroundColor?.resolve({});

    expect(background, isNotNull);
    expect(foreground, isNotNull);
    expect(contrastRatio(background!, foreground!), greaterThanOrEqualTo(4.5));
  });

  testWidgets('settings screen exposes feedback toggles', (
    WidgetTester tester,
  ) async {
    await pumpBlinkKindApp(tester);

    await tester.tap(find.byIcon(Icons.settings));
    await tester.pumpAndSettle();

    final categoryHeader = find.text('Notifications & Sounds');
    await tester.scrollUntilVisible(categoryHeader, 200, scrollable: find.byType(Scrollable).first);
    await tester.tap(categoryHeader);
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text('Haptics'), 200, scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();

    expect(find.text('Haptics'), findsOneWidget);
    expect(find.text('In-app sound'), findsOneWidget);
  });

  testWidgets('settings sends a test reminder', (tester) async {
    final notificationService = await pumpBlinkKindApp(tester);

    await tester.tap(find.byIcon(Icons.settings));
    await tester.pumpAndSettle();

    final categoryHeader = find.text('Notifications & Sounds');
    await tester.scrollUntilVisible(categoryHeader, 200, scrollable: find.byType(Scrollable).first);
    await tester.tap(categoryHeader);
    await tester.pumpAndSettle();

    final channelSettings = find.byTooltip('Notification sound settings');
    await tester.scrollUntilVisible(channelSettings, 300, scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
    await tester.tap(channelSettings);
    await tester.pumpAndSettle();
    expect(notificationService.openChannelSettingsCount, 1);

    final testReminder = find.byTooltip('Send test reminder');
    await tester.scrollUntilVisible(testReminder, 100, scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
    await tester.tap(testReminder);
    await tester.pumpAndSettle();

    expect(notificationService.testReminderCount, 1);
    expect(
      find.text('Test reminder sent. Check sound and vibration.'),
      findsOneWidget,
    );
  });

  testWidgets('settings exposes expanded color presets', (
    WidgetTester tester,
  ) async {
    await pumpBlinkKindApp(tester);

    await tester.tap(find.byIcon(Icons.settings));
    await tester.pumpAndSettle();

    final categoryHeader = find.text('Theme & Appearance');
    await tester.scrollUntilVisible(categoryHeader, 200, scrollable: find.byType(Scrollable).first);
    await tester.tap(categoryHeader);
    await tester.pumpAndSettle();

    final pastelFinder = find.text('Pastel');
    await tester.scrollUntilVisible(pastelFinder, 100, scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();

    expect(pastelFinder, findsOneWidget);
    expect(find.text('Calm Blue'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Sunrise'), 200, scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();

    expect(find.text('Forest'), findsOneWidget);
    expect(find.text('Rose'), findsOneWidget);
    expect(find.text('Graphite'), findsOneWidget);
    expect(find.text('Sunrise'), findsOneWidget);
  });

  testWidgets('notification toggle disables reminder scheduling', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      PreferencesService.onboardingCompletedKey: true,
      PreferencesService.notificationsEnabledKey: false,
    });
    final notificationService = await pumpBlinkKindApp(tester);

    await tester.tap(find.text('Start'));
    await tester.pump();

    expect(find.text('Pause'), findsOneWidget);
    expect(notificationService.workReminderCount, 0);
  });

  testWidgets('settings screen toggles notification preference', (
    WidgetTester tester,
  ) async {
    final notificationService = await pumpBlinkKindApp(tester);

    await tester.tap(find.byIcon(Icons.settings));
    await tester.pumpAndSettle();

    final categoryHeader = find.text('Notifications & Sounds');
    await tester.scrollUntilVisible(categoryHeader, 200, scrollable: find.byType(Scrollable).first);
    await tester.tap(categoryHeader);
    await tester.pumpAndSettle();

    final notificationsToggle = find.widgetWithText(
      SwitchListTile,
      'Notifications',
    );
    await tester.scrollUntilVisible(notificationsToggle, 200, scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
    expect(find.text('Notifications'), findsOneWidget);
    await tester.tap(notificationsToggle);
    await tester.pumpAndSettle();

    expect(find.textContaining('Timer alerts are off'), findsOneWidget);
    expect(notificationService.cancelCount, 1);
  });

  testWidgets('settings shows notification permission status', (
    WidgetTester tester,
  ) async {
    final notificationService = await pumpBlinkKindApp(
      tester,
      permissionStatus: NotificationPermissionStatus.disabled,
    );

    await tester.tap(find.byIcon(Icons.settings));
    await tester.pumpAndSettle();

    final categoryHeader = find.text('Notifications & Sounds');
    await tester.scrollUntilVisible(categoryHeader, 200, scrollable: find.byType(Scrollable).first);
    await tester.tap(categoryHeader);
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text('Permission status'), 200, scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();

    expect(find.text('Permission status'), findsOneWidget);
    expect(find.text('System permission blocked'), findsOneWidget);
    expect(find.text('Open system settings'), findsOneWidget);

    await tester.tap(find.text('Open system settings'));
    await tester.pumpAndSettle();

    expect(notificationService.openSettingsCount, 1);
    expect(notificationService.permissionStatusCheckCount, greaterThan(0));
  });

  testWidgets('settings screen updates daily goal', (
    WidgetTester tester,
  ) async {
    await pumpBlinkKindApp(tester);

    await tester.tap(find.byIcon(Icons.settings));
    await tester.pumpAndSettle();

    final categoryHeader = find.text('General Schedule');
    await tester.scrollUntilVisible(categoryHeader, 200, scrollable: find.byType(Scrollable).first);
    await tester.tap(categoryHeader);
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text('Daily goal'), 200, scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();

    await tester.tap(find.text('6'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('10').last);
    await tester.pumpAndSettle();

    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(find.textContaining('Daily goal: 0 / 10 breaks'), findsOneWidget);
  });

  testWidgets('settings opens recent break history', (
    WidgetTester tester,
  ) async {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    SharedPreferences.setMockInitialValues({
      PreferencesService.onboardingCompletedKey: true,
      PreferencesService.dailyHistoryKey: jsonEncode({
        todayKey(): 3,
        dateKey(yesterday): 6,
      }),
      PreferencesService.streakDateKey: todayKey(),
      PreferencesService.streakCountKey: 3,
      PreferencesService.dailyGoalKey: 6,
      PreferencesService.workSessionHistoryKey: jsonEncode([
        WorkSessionRecord.completed(
          completedAt: DateTime.now(),
          durationSeconds: 1200,
        ).toJson(),
      ]),
    });

    await pumpBlinkKindApp(tester);

    await tester.tap(find.byIcon(Icons.settings));
    await tester.pumpAndSettle();

    final categoryHeader = find.text('General Schedule');
    await tester.scrollUntilVisible(categoryHeader, 200, scrollable: find.byType(Scrollable).first);
    await tester.tap(categoryHeader);
    await tester.pumpAndSettle();

    final historyTile = find.widgetWithText(ListTile, 'History');
    await tester.scrollUntilVisible(historyTile, 300, scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
    await tester.tap(historyTile);
    await tester.pumpAndSettle();

    expect(find.text('History & Insights'), findsOneWidget);
    expect(find.text('Longest streak'), findsOneWidget);
    expect(find.text('Goal rate'), findsOneWidget);
    expect(find.text('Focus duration'), findsOneWidget);
    expect(find.text('Peak focus hour'), findsOneWidget);
    expect(find.text('30 days'), findsOneWidget);
    expect(find.text('20m'), findsOneWidget);

    final logsTitle = find.text('Last 7 days logs');
    await tester.scrollUntilVisible(logsTitle, 300, scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();

    expect(logsTitle, findsOneWidget);
    expect(find.text('Today'), findsAtLeastNWidgets(1));
    expect(find.text('Yesterday'), findsOneWidget);
    expect(find.text('3 / 6'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Recent completed sessions'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('Focused for 20 min'), findsOneWidget);
  });

  testWidgets('completed work persists a session record', (tester) async {
    SharedPreferences.setMockInitialValues({
      PreferencesService.onboardingCompletedKey: true,
      PreferencesService.workDurationSecondsKey: 1,
    });

    await pumpBlinkKindApp(tester);
    await tester.tap(find.text('Start'));
    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    final records = await PreferencesService().loadWorkSessionHistory();
    expect(records, hasLength(1));
    expect(records.single.durationSeconds, 1);
  });

  testWidgets('long break mode restores into a longer break after interval', (
    WidgetTester tester,
  ) async {
    final now = DateTime.now();
    SharedPreferences.setMockInitialValues({
      PreferencesService.onboardingCompletedKey: true,
      PreferencesService.sessionIsActiveKey: true,
      PreferencesService.sessionIsBreakKey: false,
      PreferencesService.sessionIsPausedKey: false,
      PreferencesService.sessionInitialDurationSecondsKey: 1,
      PreferencesService.sessionRemainingSecondsKey: 1,
      PreferencesService.sessionPhaseStartedAtKey: now
          .subtract(const Duration(seconds: 6))
          .millisecondsSinceEpoch,
      PreferencesService.sessionPhaseEndsAtKey: now
          .subtract(const Duration(seconds: 5))
          .millisecondsSinceEpoch,
      PreferencesService.longBreakEnabledKey: true,
      PreferencesService.longBreakEveryCyclesKey: 1,
      PreferencesService.longBreakDurationSecondsKey: 3 * 60,
    });

    final notificationService = await pumpBlinkKindApp(tester);
    await tester.pump();

    expect(find.textContaining('Break Time'), findsOneWidget);
    expect(notificationService.breakReminderCount, 1);
    expect(
      notificationService.lastBreakReminderDelay?.inSeconds,
      greaterThan(150),
    );
  });

  testWidgets('start, pause, resume, and cancel keep controls consistent', (
    WidgetTester tester,
  ) async {
    final notificationService = await pumpBlinkKindApp(tester);

    await tester.tap(find.text('Start'));
    await tester.pump();

    expect(find.text('Pause'), findsOneWidget);
    expect(find.text('Start'), findsNothing);
    expect(notificationService.workReminderCount, 1);
    expect(notificationService.cancelCount, 1);

    await tester.tap(find.text('Pause'));
    await tester.pump();

    expect(find.text('Resume'), findsOneWidget);
    expect(notificationService.cancelCount, 2);

    await tester.tap(find.text('Resume'));
    await tester.pump();

    expect(find.text('Pause'), findsOneWidget);
    expect(notificationService.workReminderCount, 2);

    await tester.tap(find.text('Cancel'));
    await tester.pump();

    expect(find.text('Start'), findsOneWidget);
    expect(find.text('20:00'), findsOneWidget);
    expect(notificationService.cancelCount, 3);
  });

  testWidgets('cancel prevents pending work-to-break transition', (
    WidgetTester tester,
  ) async {
    final notificationService = await pumpBlinkKindApp(tester);

    await tester.tap(find.text('Start'));
    await tester.pump();
    await tester.pump(const Duration(minutes: 20, seconds: 1));

    await tester.tap(find.text('Cancel'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Start'), findsOneWidget);
    expect(find.text('20:00'), findsOneWidget);
    expect(notificationService.cancelCount, 3);
    expect(notificationService.breakReminderCount, 0);
    expect(find.text('Break'), findsNothing);
  });

  testWidgets(
    'BlinkKind app enters and exits focus mode when timer dial is tapped',
    (WidgetTester tester) async {
      await pumpBlinkKindApp(tester);

      expect(find.byIcon(Icons.settings), findsOneWidget);
      expect(find.textContaining('Daily goal'), findsOneWidget);

      await tester.tap(find.text('20:00'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.settings), findsNothing);
      expect(find.textContaining('Daily goal'), findsNothing);
      expect(find.text('Tap dial to exit focus mode'), findsOneWidget);

      await tester.tap(find.text('20:00'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.settings), findsOneWidget);
      expect(find.textContaining('Daily goal'), findsOneWidget);
      expect(find.text('Tap dial to exit focus mode'), findsNothing);
    },
  );

  testWidgets(
    'BlinkKind app shows pre-break warning and supports postponement',
    (WidgetTester tester) async {
      await pumpBlinkKindApp(tester);

      await tester.tap(find.text('Start'));
      await tester.pump();

      // Tick to 9 seconds remaining (triggers warning overlay)
      await tester.pump(const Duration(minutes: 19, seconds: 51));

      expect(find.textContaining('Eye break starting in'), findsOneWidget);
      expect(find.text('Postpone (2m)'), findsOneWidget);
      expect(find.text('Cancel Timer'), findsOneWidget);

      // Tap postpone
      await tester.tap(find.text('Postpone (2m)'));
      await tester.pump();

      // Timer should be back in work mode with 2 minutes (2:00) remaining
      expect(find.text('02:00'), findsOneWidget);
      expect(find.textContaining('Eye break starting in'), findsNothing);
    },
  );

  testWidgets('settings screen toggles smart idle preference', (
    WidgetTester tester,
  ) async {
    await pumpBlinkKindApp(tester);

    await tester.tap(find.byIcon(Icons.settings));
    await tester.pumpAndSettle();

    final categoryHeader = find.text('Break Screen & Behavior');
    await tester.scrollUntilVisible(categoryHeader, 200, scrollable: find.byType(Scrollable).first);
    await tester.tap(categoryHeader);
    await tester.pumpAndSettle();

    final finder = find.text('Smart Pause & Postpone');
    await tester.scrollUntilVisible(finder, 200, scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
    expect(finder, findsOneWidget);

    // Toggle off
    await tester.tap(finder);
    await tester.pumpAndSettle();

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool(PreferencesService.smartIdleEnabledKey), false);

    // Toggle on
    await tester.tap(finder);
    await tester.pumpAndSettle();
    expect(prefs.getBool(PreferencesService.smartIdleEnabledKey), true);
  });

  testWidgets('desktop idle detection triggers smart pause and resume', (
    WidgetTester tester,
  ) async {
    await pumpBlinkKindApp(tester);

    // Start timer
    await tester.tap(find.text('Start'));
    await tester.pump();

    // Verify it is running
    expect(find.text('Pause'), findsOneWidget);

    // Retrieve state and trigger system idle state manually
    final state = tester.state<TimerHomePageState>(find.byType(TimerHomePage));
    state.handleDesktopIdleChange(true);
    await tester.pump();

    // Verify it smart-paused
    expect(find.text('Idle Paused'), findsOneWidget);
    expect(
      find.textContaining('Paused automatically because you were away.'),
      findsOneWidget,
    );

    // Trigger system active state manually
    state.handleDesktopIdleChange(false);
    await tester.pump();

    // Verify it resumed
    expect(find.text('Pause'), findsOneWidget);
  });

  testWidgets('settings updates break visualizer style', (
    WidgetTester tester,
  ) async {
    await pumpBlinkKindApp(tester);

    await tester.tap(find.byIcon(Icons.settings));
    await tester.pumpAndSettle();

    final categoryHeader = find.text('Break Screen & Behavior');
    await tester.scrollUntilVisible(categoryHeader, 200, scrollable: find.byType(Scrollable).first);
    await tester.tap(categoryHeader);
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text('Break visualizer style'), 200, scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();

    expect(find.text('Calm Breathing'), findsOneWidget);

    await tester.tap(find.text('Calm Breathing'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Starry Sky').last);
    await tester.pumpAndSettle();

    final prefs = await SharedPreferences.getInstance();
    expect(
      prefs.getString(PreferencesService.breakVisualizerStyleKey),
      'Starry',
    );
  });

  testWidgets('settings updates break visualizer style to Random', (
    WidgetTester tester,
  ) async {
    await pumpBlinkKindApp(tester);

    await tester.tap(find.byIcon(Icons.settings));
    await tester.pumpAndSettle();

    final categoryHeader = find.text('Break Screen & Behavior');
    await tester.scrollUntilVisible(categoryHeader, 200, scrollable: find.byType(Scrollable).first);
    await tester.tap(categoryHeader);
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text('Break visualizer style'), 200, scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();

    expect(find.text('Calm Breathing'), findsOneWidget);

    await tester.tap(find.text('Calm Breathing'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Random/All').last);
    await tester.pumpAndSettle();

    final prefs = await SharedPreferences.getInstance();
    expect(
      prefs.getString(PreferencesService.breakVisualizerStyleKey),
      'Random',
    );
  });

  testWidgets('completed work persists a TimerEventRecord', (tester) async {
    SharedPreferences.setMockInitialValues({
      PreferencesService.onboardingCompletedKey: true,
      PreferencesService.workDurationSecondsKey: 1,
    });

    await pumpBlinkKindApp(tester);
    await tester.tap(find.text('Start'));
    await tester.pump(); // Start callback runs here
    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    final records = await PreferencesService().loadTimerEventHistory();
    expect(records, isNotEmpty);
    expect(records.any((r) => r.type == TimerEventType.workCompleted), isTrue);
  });

  testWidgets('cancelling active work persists a TimerEventRecord', (tester) async {
    SharedPreferences.setMockInitialValues({
      PreferencesService.onboardingCompletedKey: true,
      PreferencesService.workDurationSecondsKey: 20 * 60,
    });

    await pumpBlinkKindApp(tester);
    await tester.tap(find.text('Start'));
    await tester.pump(); // Start callback runs here
    await tester.pump(const Duration(seconds: 5)); // Ticks countdown so elapsed > 0
    await tester.tap(find.text('Cancel'));
    await tester.pump();

    final records = await PreferencesService().loadTimerEventHistory();
    expect(records, isNotEmpty);
    expect(records.any((r) => r.type == TimerEventType.workCancelled), isTrue);
  });

  testWidgets('skipping a break persists a TimerEventRecord', (tester) async {
    final now = DateTime.now();
    SharedPreferences.setMockInitialValues({
      PreferencesService.onboardingCompletedKey: true,
      PreferencesService.sessionIsActiveKey: true,
      PreferencesService.sessionIsBreakKey: true,
      PreferencesService.sessionIsPausedKey: false,
      PreferencesService.sessionInitialDurationSecondsKey: 20,
      PreferencesService.sessionRemainingSecondsKey: 20,
      PreferencesService.sessionPhaseStartedAtKey: now.millisecondsSinceEpoch,
      PreferencesService.sessionPhaseEndsAtKey:
          now.add(const Duration(seconds: 20)).millisecondsSinceEpoch,
    });

    await pumpBlinkKindApp(tester);
    expect(find.text('Skip'), findsOneWidget);
    await tester.tap(find.text('Skip'));
    await tester.pump();

    final records = await PreferencesService().loadTimerEventHistory();
    expect(records, isNotEmpty);
    expect(records.any((r) => r.type == TimerEventType.breakSkipped), isTrue);
  });

  testWidgets('postponing a break persists a TimerEventRecord', (tester) async {
    final now = DateTime.now();
    SharedPreferences.setMockInitialValues({
      PreferencesService.onboardingCompletedKey: true,
      PreferencesService.sessionIsActiveKey: true,
      PreferencesService.sessionIsBreakKey: true,
      PreferencesService.sessionIsPausedKey: false,
      PreferencesService.sessionInitialDurationSecondsKey: 20,
      PreferencesService.sessionRemainingSecondsKey: 20,
      PreferencesService.sessionPhaseStartedAtKey: now.millisecondsSinceEpoch,
      PreferencesService.sessionPhaseEndsAtKey:
          now.add(const Duration(seconds: 20)).millisecondsSinceEpoch,
      PreferencesService.allowPostponeKey: true,
    });

    await pumpBlinkKindApp(tester);
    expect(find.text('Postpone'), findsOneWidget);
    await tester.tap(find.text('Postpone'));
    await tester.pump();

    final records = await PreferencesService().loadTimerEventHistory();
    expect(records, isNotEmpty);
    expect(records.any((r) => r.type == TimerEventType.breakPostponed), isTrue);
  });
}

