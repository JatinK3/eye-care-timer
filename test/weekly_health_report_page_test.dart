import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:eyeapptimer/features/history/weekly_health_report_page.dart';

void main() {
  testWidgets('weekly report renders trends, goals, and a takeaway', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final today = DateTime.now();
    String dateKey(DateTime date) =>
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final history = <String, int>{};
    final waterHistory = <String, int>{};
    for (var daysAgo = 0; daysAgo < 6; daysAgo++) {
      final dayKey = dateKey(today.subtract(Duration(days: daysAgo)));
      history[dayKey] = 6;
      waterHistory[dayKey] = 8;
    }
    int? appliedBreakGoal;

    await tester.pumpWidget(
      MaterialApp(
        home: WeeklyHealthReportPage(
          history: history,
          waterHistory: waterHistory,
          workSessions: const [],
          timerEvents: const [],
          dailyGoal: 6,
          waterDailyGoalGlasses: 8,
          waterGlassSizeMl: 250,
          setDailyGoal: (goal) => appliedBreakGoal = goal,
        ),
      ),
    );

    expect(find.text('Your last 7 days'), findsOneWidget);
    expect(find.text('Goal progress trend'), findsOneWidget);
    expect(find.text('Break goals'), findsOneWidget);
    expect(find.text('Water goals'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Weekly takeaway'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Weekly takeaway'), findsOneWidget);
    expect(find.text('6/7'), findsNWidgets(2));
    expect(find.text('Goal calibration'), findsOneWidget);
    final apply = find.text('Apply').first;
    await tester.ensureVisible(apply);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Apply').first);
    await tester.pump();
    expect(appliedBreakGoal, 7);
  });
}
