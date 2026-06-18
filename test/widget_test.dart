import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:eyeapptimer/app.dart';
import 'package:eyeapptimer/services/notification_service.dart';
import 'package:eyeapptimer/services/preferences_service.dart';

class FakeNotificationService extends NotificationService {
  NotificationPermissionStatus status;
  int workReminderCount = 0;
  int breakReminderCount = 0;
  Duration? lastBreakReminderDelay;
  int cancelCount = 0;
  int permissionStatusCheckCount = 0;
  int requestPermissionCount = 0;
  int openSettingsCount = 0;

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
  Future<void> scheduleWorkCompleteReminder(Duration delay) async {
    workReminderCount++;
  }

  @override
  Future<void> scheduleBreakCompleteReminder(Duration delay) async {
    breakReminderCount++;
    lastBreakReminderDelay = delay;
  }

  @override
  Future<void> cancelPhaseReminder() async {
    cancelCount++;
  }

  @override
  Future<bool> openNotificationSettings() async {
    openSettingsCount++;
    return true;
  }
}

Future<FakeNotificationService> pumpEyeCareTimerApp(
  WidgetTester tester, {
  NotificationPermissionStatus permissionStatus =
      NotificationPermissionStatus.allowed,
}) async {
  final notificationService = FakeNotificationService(status: permissionStatus);
  await tester.pumpWidget(
    EyeCareTimerApp(notificationService: notificationService),
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

  testWidgets('Eye Care Timer app renders initial timer state', (
    WidgetTester tester,
  ) async {
    await pumpEyeCareTimerApp(tester);

    expect(find.text('Eye Care Timer'), findsOneWidget);
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

    final notificationService = await pumpEyeCareTimerApp(tester);

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

    await pumpEyeCareTimerApp(tester);

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

    final notificationService = await pumpEyeCareTimerApp(tester);

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

    final notificationService = await pumpEyeCareTimerApp(tester);

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

    final notificationService = await pumpEyeCareTimerApp(tester);
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

    final notificationService = await pumpEyeCareTimerApp(tester);
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

    final notificationService = await pumpEyeCareTimerApp(tester);
    await tester.pump();

    expect(find.text('Start'), findsOneWidget);
    expect(notificationService.workReminderCount, 0);
  });

  testWidgets('settings screen updates idle work duration', (
    WidgetTester tester,
  ) async {
    await pumpEyeCareTimerApp(tester);

    await tester.tap(find.byIcon(Icons.settings));
    await tester.pumpAndSettle();

    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Work duration'), findsOneWidget);

    await tester.tap(find.text('20 min'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('5 min').last);
    await tester.pumpAndSettle();

    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(find.text('05:00'), findsOneWidget);
  });

  testWidgets('settings configures automatic schedule cycles', (
    WidgetTester tester,
  ) async {
    await pumpEyeCareTimerApp(tester);

    await tester.tap(find.byIcon(Icons.settings));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Auto run'), 200);
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

  testWidgets('settings applies quick timer presets', (
    WidgetTester tester,
  ) async {
    await pumpEyeCareTimerApp(tester);

    await tester.tap(find.byIcon(Icons.settings));
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

    await pumpEyeCareTimerApp(tester);

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
    await pumpEyeCareTimerApp(tester);

    await tester.tap(find.byIcon(Icons.settings));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text('Feedback'), 200);
    await tester.pumpAndSettle();

    expect(find.text('Feedback'), findsOneWidget);
    expect(find.text('Haptics'), findsOneWidget);
    expect(find.text('Sound'), findsOneWidget);
  });

  testWidgets('settings exposes expanded color presets', (
    WidgetTester tester,
  ) async {
    await pumpEyeCareTimerApp(tester);

    await tester.tap(find.byIcon(Icons.settings));
    await tester.pumpAndSettle();

    expect(find.text('Pastel'), findsOneWidget);
    expect(find.text('Calm Blue'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Sunrise'), 200);
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
    final notificationService = await pumpEyeCareTimerApp(tester);

    await tester.tap(find.text('Start'));
    await tester.pump();

    expect(find.text('Pause'), findsOneWidget);
    expect(notificationService.workReminderCount, 0);
  });

  testWidgets('settings screen toggles notification preference', (
    WidgetTester tester,
  ) async {
    final notificationService = await pumpEyeCareTimerApp(tester);

    await tester.tap(find.byIcon(Icons.settings));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text('Notifications'), 200);
    await tester.drag(find.byType(ListView), const Offset(0, -140));
    await tester.pumpAndSettle();
    expect(find.text('Notifications'), findsOneWidget);
    await tester.tap(find.widgetWithText(SwitchListTile, 'Notifications'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Timer alerts are off'), findsOneWidget);
    expect(notificationService.cancelCount, 1);
  });

  testWidgets('settings shows notification permission status', (
    WidgetTester tester,
  ) async {
    final notificationService = await pumpEyeCareTimerApp(
      tester,
      permissionStatus: NotificationPermissionStatus.disabled,
    );

    await tester.tap(find.byIcon(Icons.settings));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Permission status'), 200);
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
    await pumpEyeCareTimerApp(tester);

    await tester.tap(find.byIcon(Icons.settings));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Daily goal'), 200);
    await tester.drag(find.byType(ListView), const Offset(0, -140));
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
    });

    await pumpEyeCareTimerApp(tester);

    await tester.tap(find.byIcon(Icons.settings));
    await tester.pumpAndSettle();
    final historyTile = find.widgetWithText(ListTile, 'History');
    await tester.scrollUntilVisible(historyTile, 300);
    await tester.pumpAndSettle();
    await tester.tap(historyTile);
    await tester.pumpAndSettle();

    expect(find.text('History'), findsOneWidget);
    expect(find.text('Best day'), findsOneWidget);
    expect(find.text('Goal streak'), findsOneWidget);
    expect(find.text('Last 7 days'), findsOneWidget);
    expect(find.text('Today'), findsOneWidget);
    expect(find.text('Yesterday'), findsOneWidget);
    expect(find.text('3 / 6'), findsOneWidget);
    expect(find.text('6 breaks'), findsOneWidget);
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

    final notificationService = await pumpEyeCareTimerApp(tester);
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
    final notificationService = await pumpEyeCareTimerApp(tester);

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
    final notificationService = await pumpEyeCareTimerApp(tester);

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
}
