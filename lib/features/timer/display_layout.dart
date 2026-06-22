import 'dart:math' as math;
import 'dart:ui';

/// Raw geometry for one monitor in the global desktop coordinate space, as
/// reported by the platform (logical pixels).
class DisplayBounds {
  final double left;
  final double top;
  final double width;
  final double height;

  const DisplayBounds({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
  });
}

/// The window geometry needed to cover every monitor with a single overlay
/// window, plus where each monitor sits inside that window.
class DisplaySpan {
  /// Bounds for the overlay window in the global desktop coordinate space.
  /// This is what `WindowManager.setBounds` expects.
  final Rect windowBounds;

  /// Each monitor's rectangle translated into the overlay window's local
  /// coordinate space (the union's top-left becomes the origin). These map
  /// directly onto Flutter layout coordinates, so the break content can be
  /// centered on each physical screen.
  final List<Rect> monitorRects;

  const DisplaySpan({required this.windowBounds, required this.monitorRects});

  /// Whether more than one usable monitor was found. A single-monitor span can
  /// keep using the simpler fullscreen path.
  bool get isMultiMonitor => monitorRects.length > 1;
}

/// Computes the overlay span that covers all [displays].
///
/// Pure and deterministic so it can be unit tested without a display server.
/// Zero-area displays are ignored. Returns `null` when no usable display
/// remains, signalling the caller to fall back to single-monitor fullscreen.
DisplaySpan? computeDisplaySpan(List<DisplayBounds> displays) {
  final usable = displays
      .where((d) => d.width > 0 && d.height > 0)
      .toList(growable: false);
  if (usable.isEmpty) return null;

  var minLeft = double.infinity;
  var minTop = double.infinity;
  var maxRight = double.negativeInfinity;
  var maxBottom = double.negativeInfinity;

  for (final d in usable) {
    minLeft = math.min(minLeft, d.left);
    minTop = math.min(minTop, d.top);
    maxRight = math.max(maxRight, d.left + d.width);
    maxBottom = math.max(maxBottom, d.top + d.height);
  }

  final windowBounds = Rect.fromLTRB(minLeft, minTop, maxRight, maxBottom);
  final monitorRects = usable
      .map(
        (d) =>
            Rect.fromLTWH(d.left - minLeft, d.top - minTop, d.width, d.height),
      )
      .toList(growable: false);

  return DisplaySpan(windowBounds: windowBounds, monitorRects: monitorRects);
}
