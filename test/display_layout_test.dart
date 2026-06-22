import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:eyeapptimer/features/timer/display_layout.dart';

void main() {
  group('computeDisplaySpan', () {
    test('returns null when there are no displays', () {
      expect(computeDisplaySpan(const []), isNull);
    });

    test('returns null when every display is zero-area', () {
      final span = computeDisplaySpan(const [
        DisplayBounds(left: 0, top: 0, width: 0, height: 1080),
        DisplayBounds(left: 0, top: 0, width: 1920, height: 0),
      ]);
      expect(span, isNull);
    });

    test('single monitor spans itself and is not multi-monitor', () {
      final span = computeDisplaySpan(const [
        DisplayBounds(left: 0, top: 0, width: 1920, height: 1080),
      ]);

      expect(span, isNotNull);
      expect(span!.isMultiMonitor, isFalse);
      expect(span.windowBounds, const Rect.fromLTWH(0, 0, 1920, 1080));
      expect(span.monitorRects, [const Rect.fromLTWH(0, 0, 1920, 1080)]);
    });

    test('two side-by-side monitors form a horizontal union', () {
      final span = computeDisplaySpan(const [
        DisplayBounds(left: 0, top: 0, width: 1920, height: 1080),
        DisplayBounds(left: 1920, top: 0, width: 2560, height: 1440),
      ]);

      expect(span, isNotNull);
      expect(span!.isMultiMonitor, isTrue);
      // Union covers both: width 1920 + 2560, height max(1080, 1440).
      expect(span.windowBounds, const Rect.fromLTWH(0, 0, 4480, 1440));
      expect(span.monitorRects, [
        const Rect.fromLTWH(0, 0, 1920, 1080),
        const Rect.fromLTWH(1920, 0, 2560, 1440),
      ]);
    });

    test(
      'a monitor to the left shifts the origin so rects stay non-negative',
      () {
        final span = computeDisplaySpan(const [
          DisplayBounds(left: 0, top: 0, width: 1920, height: 1080),
          DisplayBounds(left: -1920, top: 0, width: 1920, height: 1080),
        ]);

        expect(span, isNotNull);
        expect(span!.windowBounds, const Rect.fromLTWH(-1920, 0, 3840, 1080));
        // Window-local rects are translated so the leftmost monitor is at x=0.
        expect(span.monitorRects, [
          const Rect.fromLTWH(1920, 0, 1920, 1080),
          const Rect.fromLTWH(0, 0, 1920, 1080),
        ]);
        // Every rect lives inside the window bounds (origin-relative).
        for (final rect in span.monitorRects) {
          expect(rect.left, greaterThanOrEqualTo(0));
          expect(rect.top, greaterThanOrEqualTo(0));
          expect(rect.right, lessThanOrEqualTo(span.windowBounds.width));
          expect(rect.bottom, lessThanOrEqualTo(span.windowBounds.height));
        }
      },
    );

    test('vertically stacked monitors form a vertical union', () {
      final span = computeDisplaySpan(const [
        DisplayBounds(left: 0, top: 0, width: 1920, height: 1080),
        DisplayBounds(left: 0, top: 1080, width: 1920, height: 1080),
      ]);

      expect(span!.windowBounds, const Rect.fromLTWH(0, 0, 1920, 2160));
      expect(span.monitorRects, [
        const Rect.fromLTWH(0, 0, 1920, 1080),
        const Rect.fromLTWH(0, 1080, 1920, 1080),
      ]);
    });

    test('zero-area displays are filtered before computing the span', () {
      final span = computeDisplaySpan(const [
        DisplayBounds(left: 0, top: 0, width: 0, height: 1080),
        DisplayBounds(left: 0, top: 0, width: 1920, height: 1080),
      ]);

      expect(span, isNotNull);
      expect(span!.isMultiMonitor, isFalse);
      expect(span.monitorRects, [const Rect.fromLTWH(0, 0, 1920, 1080)]);
    });
  });
}
