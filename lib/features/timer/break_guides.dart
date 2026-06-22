import 'dart:math' as math;
import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// Eye Exercise Dot Tracker Guide
// ---------------------------------------------------------------------------

/// Sequence of named eye-movement exercises, each defining the dot's path.
enum _EyeExercise {
  sideSweep,
  verticalSweep,
  figureSixteen,
  zoomPulse,
  cornerDiagonals,
}

const _exerciseLabels = {
  _EyeExercise.sideSweep: 'Follow the dot\nside to side',
  _EyeExercise.verticalSweep: 'Follow the dot\nup and down',
  _EyeExercise.figureSixteen: 'Trace a figure-8\nwith your eyes',
  _EyeExercise.zoomPulse: 'Focus near\nthen far',
  _EyeExercise.cornerDiagonals: 'Trace the corners\nwith your eyes',
};

Offset _dotPositionFor(_EyeExercise exercise, double t, double hw, double hh) {
  const r = 0.80; // use 80% of half-width/height as radius
  switch (exercise) {
    case _EyeExercise.sideSweep:
      final x = math.sin(t * 2 * math.pi) * hw * r;
      return Offset(x, 0);
    case _EyeExercise.verticalSweep:
      final y = math.sin(t * 2 * math.pi) * hh * r;
      return Offset(0, y);
    case _EyeExercise.figureSixteen:
      // Lemniscate of Bernoulli
      final angle = t * 2 * math.pi;
      final scale = 1.0 / (1 + math.sin(angle) * math.sin(angle));
      final x = math.cos(angle) * scale * hw * r;
      final y = math.sin(angle) * math.cos(angle) * scale * hh * r;
      return Offset(x, y);
    case _EyeExercise.zoomPulse:
      // Dot shrinks and grows in the center — user adjusts focal depth
      return Offset.zero;
    case _EyeExercise.cornerDiagonals:
      // Square path through 4 corners, smooth via index cycling
      final segment = (t * 4).floor().clamp(0, 3);
      final frac = (t * 4) - segment;
      const corners = [
        Offset(-1, -1),
        Offset(1, -1),
        Offset(1, 1),
        Offset(-1, 1),
      ];
      final from = corners[segment];
      final to = corners[(segment + 1) % 4];
      return Offset(
        (from.dx + (to.dx - from.dx) * frac) * hw * r,
        (from.dy + (to.dy - from.dy) * frac) * hh * r,
      );
  }
}

/// An animated widget showing a glowing dot moving along various paths to
/// guide the user's eye muscles during a break. Cycles through all exercises
/// automatically for the break duration.
class EyeExerciseDotGuide extends StatefulWidget {
  final int remainingSeconds;
  /// Full break duration in seconds, for the countdown arc.
  final int totalDurationSeconds;

  const EyeExerciseDotGuide({
    super.key,
    required this.remainingSeconds,
    required this.totalDurationSeconds,
  });

  @override
  State<EyeExerciseDotGuide> createState() => _EyeExerciseDotGuideState();
}

class _EyeExerciseDotGuideState extends State<EyeExerciseDotGuide>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  // Each exercise runs for 8 seconds
  static const _secondsPerExercise = 8.0;
  static const _exercises = _EyeExercise.values;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(
        milliseconds: (_secondsPerExercise * _exercises.length * 1000).round(),
      ),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _formatTime(int secs) {
    final m = secs ~/ 60;
    final s = secs % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final totalT = _controller.value * _exercises.length; // 0..N
        final exerciseIndex = totalT.floor() % _exercises.length;
        final localT = totalT - totalT.floor(); // 0..1 within exercise
        final exercise = _exercises[exerciseIndex];
        final label = _exerciseLabels[exercise] ?? '';

        // Zoom-pulse: dot size varies instead of position
        final bool isZoomPulse = exercise == _EyeExercise.zoomPulse;
        final double dotRadius =
            isZoomPulse ? (8 + math.sin(localT * 2 * math.pi) * 14) : 10.0;

        return LayoutBuilder(
          builder: (context, constraints) {
            final hw = constraints.maxWidth / 2;
            final hh = constraints.maxHeight / 2;
            final dotOffset = _dotPositionFor(exercise, localT, hw, hh);

            return Stack(
              alignment: Alignment.center,
              children: [
                // Background guide circle
                Container(
                  width: constraints.maxWidth,
                  height: constraints.maxHeight,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.07),
                      width: 1.5,
                    ),
                  ),
                ),
                // Countdown arc
                SizedBox(
                  width: constraints.maxWidth,
                  height: constraints.maxHeight,
                  child: CircularProgressIndicator(
                    value: widget.totalDurationSeconds > 0
                        ? widget.remainingSeconds / widget.totalDurationSeconds
                        : 0,
                    strokeWidth: 3,
                    color: const Color(0xFF00E5CC).withValues(alpha: 0.5),
                    backgroundColor: Colors.white.withValues(alpha: 0.05),
                  ),
                ),
                // Center countdown + label
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _formatTime(widget.remainingSeconds),
                      style: theme.textTheme.displaySmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      label,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white54,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
                // Moving dot
                Transform.translate(
                  offset: dotOffset,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 50),
                    width: dotRadius * 2,
                    height: dotRadius * 2,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF00E5CC),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF00E5CC).withValues(alpha: 0.6),
                          blurRadius: 18,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Box Breathing Guide (4-4-4-4 paced breathing)
// ---------------------------------------------------------------------------

/// A visual box-breathing (4-4-4-4) guide that animates a glowing square
/// expanding along each side to pace the user's breathing cycle.
class BoxBreathingGuide extends StatefulWidget {
  final int remainingSeconds;
  final int totalDurationSeconds;

  const BoxBreathingGuide({
    super.key,
    required this.remainingSeconds,
    required this.totalDurationSeconds,
  });

  @override
  State<BoxBreathingGuide> createState() => _BoxBreathingGuideState();
}

class _BoxBreathingGuideState extends State<BoxBreathingGuide>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  // Box breathing cycle: inhale 4s → hold 4s → exhale 4s → hold 4s = 16s total
  static const _cycleDurationSeconds = 16.0;

  static const _phaseLabels = ['Breathe In', 'Hold', 'Breathe Out', 'Hold'];
  static const _phaseColors = [
    Color(0xFF4FC3F7), // light blue — inhale
    Color(0xFF81C784), // soft green — hold full
    Color(0xFFFFB74D), // warm amber — exhale
    Color(0xFF9575CD), // muted violet — hold empty
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 16),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _formatTime(int secs) {
    final m = secs ~/ 60;
    final s = secs % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final cycle = _controller.value * _cycleDurationSeconds; // 0..16
        final phaseIndex = (cycle / 4).floor().clamp(0, 3);
        final phaseProgress = (cycle - phaseIndex * 4.0) / 4.0; // 0..1 in phase
        final phaseLabel = _phaseLabels[phaseIndex];
        final phaseColor = _phaseColors[phaseIndex];
        final phaseSecs = 4 - (cycle - phaseIndex * 4.0).floor();

        return LayoutBuilder(
          builder: (context, constraints) {
            final size = math.min(constraints.maxWidth, constraints.maxHeight);
            final boxSize = size * 0.55;

            return Stack(
              alignment: Alignment.center,
              children: [
                // Breathing countdown arc (overall break time)
                SizedBox(
                  width: size,
                  height: size,
                  child: CircularProgressIndicator(
                    value: widget.totalDurationSeconds > 0
                        ? widget.remainingSeconds / widget.totalDurationSeconds
                        : 0,
                    strokeWidth: 3,
                    color: phaseColor.withValues(alpha: 0.4),
                    backgroundColor: Colors.white.withValues(alpha: 0.06),
                  ),
                ),
                // Box breathing animator
                SizedBox(
                  width: boxSize,
                  height: boxSize,
                  child: CustomPaint(
                    painter: _BoxBreathingPainter(
                      phaseIndex: phaseIndex,
                      phaseProgress: phaseProgress,
                      color: phaseColor,
                    ),
                  ),
                ),
                // Center text
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _formatTime(widget.remainingSeconds),
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      phaseLabel,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: phaseColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$phaseSecs',
                      style: theme.textTheme.headlineLarge?.copyWith(
                        color: phaseColor.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }
}

/// Draws an animated box where each side is progressively "traced" to pace breathing.
///
/// Phase 0 (Inhale) → traces top edge left-to-right
/// Phase 1 (Hold)   → traces right edge top-to-bottom
/// Phase 2 (Exhale) → traces bottom edge right-to-left
/// Phase 3 (Hold)   → traces left edge bottom-to-top
class _BoxBreathingPainter extends CustomPainter {
  final int phaseIndex;
  final double phaseProgress;
  final Color color;

  const _BoxBreathingPainter({
    required this.phaseIndex,
    required this.phaseProgress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    const cornerRadius = 16.0;
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, w, h),
      const Radius.circular(cornerRadius),
    );

    // Draw dim base box
    final basePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..color = Colors.white.withValues(alpha: 0.08);
    canvas.drawRRect(rect, basePaint);

    // Compute perimeter segments for 4 sides (ignoring corners for simplicity)
    final perimeter = 2 * (w + h);
    final phaseStartFraction = phaseIndex / 4.0;
    final phaseEndFraction =
        phaseStartFraction + phaseProgress / 4.0;

    final startDist = phaseStartFraction * perimeter;
    final endDist = phaseEndFraction * perimeter;

    // Draw active glow line
    final activePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..color = color
      ..strokeCap = StrokeCap.round
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 6);

    final path = _buildPerimeterPath(w, h, startDist, endDist);
    canvas.drawPath(path, activePaint);

    // Solid dot at leading edge
    final dotPos = _perimeterPoint(w, h, endDist % perimeter);
    final dotPaint = Paint()
      ..color = color
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawCircle(dotPos, 7, dotPaint);
    canvas.drawCircle(
      dotPos,
      5,
      Paint()..color = Colors.white,
    );
  }

  Path _buildPerimeterPath(
    double w,
    double h,
    double startDist,
    double endDist,
  ) {
    final path = Path();
    final perimeter = 2 * (w + h);
    // Clamp
    final s = startDist.clamp(0.0, perimeter);
    final e = endDist.clamp(0.0, perimeter);
    if (s >= e) return path;

    // Walk the perimeter: top → right → bottom → left
    final segments = [
      (Offset(0, 0), Offset(w, 0), w),         // top  0..w
      (Offset(w, 0), Offset(w, h), h),          // right w..w+h
      (Offset(w, h), Offset(0, h), w),          // bottom w+h..2w+h
      (Offset(0, h), Offset(0, 0), h),          // left  2w+h..2w+2h
    ];

    double cursor = 0;
    bool started = false;
    for (final (from, to, len) in segments) {
      final segEnd = cursor + len;
      if (segEnd < s) {
        cursor = segEnd;
        continue;
      }
      final segS = (s - cursor).clamp(0.0, len) / len;
      final segE = (e - cursor).clamp(0.0, len) / len;
      final p1 = Offset(
        from.dx + (to.dx - from.dx) * segS,
        from.dy + (to.dy - from.dy) * segS,
      );
      final p2 = Offset(
        from.dx + (to.dx - from.dx) * math.min(segE, 1.0),
        from.dy + (to.dy - from.dy) * math.min(segE, 1.0),
      );
      if (!started) {
        path.moveTo(p1.dx, p1.dy);
        started = true;
      }
      path.lineTo(p2.dx, p2.dy);
      cursor = segEnd;
      if (cursor >= e) break;
    }
    return path;
  }

  Offset _perimeterPoint(double w, double h, double dist) {
    final perimeter = 2 * (w + h);
    final d = dist.clamp(0.0, perimeter);
    if (d <= w) return Offset(d, 0); // top
    if (d <= w + h) return Offset(w, d - w); // right
    if (d <= 2 * w + h) return Offset(w - (d - w - h), h); // bottom
    return Offset(0, h - (d - 2 * w - h)); // left
  }

  @override
  bool shouldRepaint(covariant _BoxBreathingPainter old) =>
      old.phaseIndex != phaseIndex ||
      old.phaseProgress != phaseProgress ||
      old.color != color;
}
