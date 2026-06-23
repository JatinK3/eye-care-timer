import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:eyeapptimer/features/timer/break_guides.dart';

void main() {
  group('EyeExerciseDotGuide', () {
    testWidgets('renders initial state and advances exercises over time', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 400,
              child: EyeExerciseDotGuide(
                remainingSeconds: 20,
                totalDurationSeconds: 20,
              ),
            ),
          ),
        ),
      );

      // Verify initial formatting of time and first exercise label
      expect(find.text('00:20'), findsOneWidget);
      expect(find.text('Follow the dot\nside to side'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Advance by 8 seconds (first exercise duration is 8.0s)
      await tester.pump(const Duration(seconds: 8));

      // Should now show the next exercise label
      expect(find.text('Follow the dot\nup and down'), findsOneWidget);

      // Advance by another 8 seconds
      await tester.pump(const Duration(seconds: 8));
      expect(find.text('Trace a figure-8\nwith your eyes'), findsOneWidget);
    });
  });

  group('BoxBreathingGuide', () {
    testWidgets('renders initial state and cycles through breathing phases', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 400,
              child: BoxBreathingGuide(
                remainingSeconds: 20,
                totalDurationSeconds: 20,
              ),
            ),
          ),
        ),
      );

      // Verify time, initial phase (Breathe In) and inner counter (4)
      expect(find.text('00:20'), findsOneWidget);
      expect(find.text('Breathe In'), findsOneWidget);
      expect(find.text('4'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is CustomPaint &&
              widget.painter != null &&
              widget.painter.runtimeType.toString() == '_BoxBreathingPainter',
        ),
        findsOneWidget,
      );

      // Advance by 4 seconds to the Hold phase
      await tester.pump(const Duration(seconds: 4));
      expect(find.text('Hold'), findsOneWidget);

      // Advance by 4 seconds to the Breathe Out phase
      await tester.pump(const Duration(seconds: 4));
      expect(find.text('Breathe Out'), findsOneWidget);

      // Advance by 4 seconds to the Hold phase (empty)
      await tester.pump(const Duration(seconds: 4));
      expect(find.text('Hold'), findsOneWidget);
    });
  });
}
