import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:eyeapptimer/app.dart';
import 'package:eyeapptimer/services/notification_service.dart';
import 'package:eyeapptimer/services/preferences_service.dart';

class FakeNotificationService extends NotificationService {
  int workReminderCount = 0;
  int breakReminderCount = 0;
  int cancelCount = 0;

  @override
  Future<void> initialize() async {}

  @override
  Future<void> requestPermissions() async {}

  @override
  Future<void> scheduleWorkCompleteReminder(Duration delay) async {
    workReminderCount++;
  }

  @override
  Future<void> scheduleBreakCompleteReminder(Duration delay) async {
    breakReminderCount++;
  }

  @override
  Future<void> cancelPhaseReminder() async {
    cancelCount++;
  }
}

Future<FakeNotificationService> pumpEyeCareTimerApp(WidgetTester tester) async {
  final notificationService = FakeNotificationService();
  await tester.pumpWidget(
    EyeCareTimerApp(notificationService: notificationService),
  );
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

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Eye Care Timer app renders initial timer state', (
    WidgetTester tester,
  ) async {
    await pumpEyeCareTimerApp(tester);

    expect(find.text('Eye Care Timer'), findsOneWidget);
    expect(find.textContaining('Work Time'), findsOneWidget);
    expect(find.text('20:00'), findsOneWidget);
    expect(find.text('Start'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
    expect(find.textContaining('Streak today: 0 cycles'), findsOneWidget);
  });

  testWidgets('loads saved duration and daily streak preferences', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      PreferencesService.workDurationSecondsKey: 5 * 60,
      PreferencesService.breakDurationSecondsKey: 60,
      PreferencesService.streakDateKey: todayKey(),
      PreferencesService.streakCountKey: 2,
    });

    await pumpEyeCareTimerApp(tester);

    expect(find.text('05:00'), findsOneWidget);
    expect(find.textContaining('Streak today: 2 cycles'), findsOneWidget);
  });

  testWidgets('restores a paused work session', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({
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

  testWidgets('notification toggle disables reminder scheduling', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({
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

    expect(find.text('Notifications'), findsOneWidget);
    await tester.tap(find.byType(SwitchListTile).last);
    await tester.pumpAndSettle();

    expect(find.textContaining('Timer alerts are off'), findsOneWidget);
    expect(notificationService.cancelCount, 1);
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
