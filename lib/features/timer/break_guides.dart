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
      // Lemniscate of Bernoulli — 2 full cycles in 8 s so the ∞ shape is
      // always clearly visible regardless of when the user starts watching.
      final angle = t * 4 * math.pi;
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
    const themeColor = Color(0xFF00E5CC);

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

            // Compute particle trail offsets
            final trailCount = 6;
            final trailWidgets = <Widget>[];
            if (!isZoomPulse) {
              for (int i = 1; i <= trailCount; i++) {
                // Look back in time (localT - delay)
                final double delay = i * 0.015;
                final double tailT = (localT - delay + 1.0) % 1.0;
                final Offset trailOffset = _dotPositionFor(exercise, tailT, hw, hh);
                final double trailRadius = dotRadius * (1.0 - (i / (trailCount + 2)));
                final double trailOpacity = 0.25 * (1.0 - (i / trailCount));

                trailWidgets.add(
                  Transform.translate(
                    offset: trailOffset,
                    child: Container(
                      width: trailRadius * 2,
                      height: trailRadius * 2,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: themeColor.withValues(alpha: trailOpacity),
                      ),
                    ),
                  ),
                );
              }
            }

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
                    color: themeColor.withValues(alpha: 0.5),
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
                // Render particle trail widgets
                ...trailWidgets,
                // Moving dot with high-end glowing halo
                Transform.translate(
                  offset: dotOffset,
                  child: SizedBox(
                    width: dotRadius * 3.5,
                    height: dotRadius * 3.5,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Outer pulsing glow
                        Container(
                          width: dotRadius * 3.5,
                          height: dotRadius * 3.5,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: themeColor.withValues(alpha: 0.12),
                          ),
                        ),
                        // Inner ring glow
                        Container(
                          width: dotRadius * 2.5,
                          height: dotRadius * 2.5,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: themeColor.withValues(alpha: 0.45),
                              width: 1.8,
                            ),
                          ),
                        ),
                        // Core glowing dot
                        Container(
                          width: dotRadius * 1.4,
                          height: dotRadius * 1.4,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: themeColor,
                            boxShadow: [
                              BoxShadow(
                                color: themeColor,
                                blurRadius: 8.0,
                                spreadRadius: 1.0,
                              ),
                            ],
                          ),
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
    const r = 16.0; // corner radius — matches the visual box

    // ── Draw dim base rounded-rectangle box ──────────────────────────────
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, w, h),
      const Radius.circular(r),
    );
    final basePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..color = Colors.white.withValues(alpha: 0.08);
    canvas.drawRRect(rrect, basePaint);

    // ── Build the perimeter path that follows the rounded rectangle ───────
    // We split the perimeter into 8 segments per side:
    //   straight segment + corner arc (quarter circle, length = r * π/2)
    // Layout (starting from top-left arc, going clockwise):
    //   TL arc → top straight → TR arc → right straight →
    //   BR arc → bottom straight → BL arc → left straight
    final arcLen = r * math.pi / 2; // length of one quarter-circle arc
    final straightTop = w - 2 * r;
    final straightRight = h - 2 * r;
    final straightBottom = w - 2 * r;
    final totalPerimeter =
        4 * arcLen + 2 * straightTop + 2 * straightRight;


    // Each of the 4 breathing phases maps to exactly 1/4 of the perimeter.
    final phaseStart = phaseIndex / 4.0 * totalPerimeter;
    final phaseEnd = phaseStart + phaseProgress / 4.0 * totalPerimeter;

    // Helper: point on the rounded-rect perimeter at distance [d] from
    // top-left corner (clockwise).
    Offset perimeterPoint(double d) {
      d = d % totalPerimeter;
      // 1. TL arc: from (r,0) sweeping 270°→360° (i.e. left col going up then over)
      //    Actually we start at top-left going right: arc centre (r, r), from 180°→270°
      double cursor = 0;
      // Segment A: TL corner arc (centre r,r, from 180° to 270°)
      double segLen = arcLen;
      if (d < cursor + segLen) {
        final t = (d - cursor) / segLen; // 0..1
        final angle = math.pi + t * math.pi / 2; // 180°→270°
        return Offset(r + r * math.cos(angle), r + r * math.sin(angle));
      }
      cursor += segLen;
      // Segment B: top straight  (r,0) → (w-r, 0)
      segLen = straightTop;
      if (d < cursor + segLen) {
        return Offset(r + (d - cursor), 0);
      }
      cursor += segLen;
      // Segment C: TR corner arc (centre w-r, r, from 270°→0°)
      segLen = arcLen;
      if (d < cursor + segLen) {
        final t = (d - cursor) / segLen;
        final angle = -math.pi / 2 + t * math.pi / 2;
        return Offset((w - r) + r * math.cos(angle), r + r * math.sin(angle));
      }
      cursor += segLen;
      // Segment D: right straight  (w, r) → (w, h-r)
      segLen = straightRight;
      if (d < cursor + segLen) {
        return Offset(w, r + (d - cursor));
      }
      cursor += segLen;
      // Segment E: BR corner arc (centre w-r, h-r, from 0°→90°)
      segLen = arcLen;
      if (d < cursor + segLen) {
        final t = (d - cursor) / segLen;
        final angle = t * math.pi / 2;
        return Offset((w - r) + r * math.cos(angle), (h - r) + r * math.sin(angle));
      }
      cursor += segLen;
      // Segment F: bottom straight  (w-r, h) → (r, h)
      segLen = straightBottom;
      if (d < cursor + segLen) {
        return Offset(w - r - (d - cursor), h);
      }
      cursor += segLen;
      // Segment G: BL corner arc (centre r, h-r, from 90°→180°)
      segLen = arcLen;
      if (d < cursor + segLen) {
        final t = (d - cursor) / segLen;
        final angle = math.pi / 2 + t * math.pi / 2;
        return Offset(r + r * math.cos(angle), (h - r) + r * math.sin(angle));
      }
      cursor += segLen;
      // Segment H: left straight  (0, h-r) → (0, r)
      return Offset(0, h - r - (d - cursor));
    }

    // ── Draw active progress arc along the rounded-rect ───────────────────
    final activePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..color = color
      ..strokeCap = StrokeCap.round;

    // Sample the path between phaseStart and phaseEnd
    final path = Path();
    const steps = 60;
    for (int i = 0; i <= steps; i++) {
      final d = phaseStart + (phaseEnd - phaseStart) * i / steps;
      final pt = perimeterPoint(d.clamp(0.0, totalPerimeter));
      if (i == 0) {
        path.moveTo(pt.dx, pt.dy);
      } else {
        path.lineTo(pt.dx, pt.dy);
      }
    }
    canvas.drawPath(path, activePaint);

    // ── Leading dot at the tip of the progress line ───────────────────────
    final dotPos = perimeterPoint(phaseEnd.clamp(0.0, totalPerimeter));
    canvas.drawCircle(
      dotPos, 9,
      Paint()..color = color.withValues(alpha: 0.3)..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      dotPos, 4.5,
      Paint()..color = Colors.white..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(covariant _BoxBreathingPainter old) =>
      old.phaseIndex != phaseIndex ||
      old.phaseProgress != phaseProgress ||
      old.color != color;
}

// ---------------------------------------------------------------------------
// Blink Training Guide (Blink reflex pacing)
// ---------------------------------------------------------------------------

class BlinkTrainingGuide extends StatefulWidget {
  final int remainingSeconds;
  final int totalDurationSeconds;

  const BlinkTrainingGuide({
    super.key,
    required this.remainingSeconds,
    required this.totalDurationSeconds,
  });

  @override
  State<BlinkTrainingGuide> createState() => _BlinkTrainingGuideState();
}

class _BlinkTrainingGuideState extends State<BlinkTrainingGuide>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  // Blink cycle of 4 seconds: 3.3s open → 0.15s closing → 0.2s closed → 0.15s opening → 0.2s open
  static const _cycleDurationSeconds = 4.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
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
    const themeColor = Color(0xFF00E5CC);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value * _cycleDurationSeconds; // 0..4
        double openAmount = 1.0;
        String instruction = 'Keep eyes relaxed';

        if (t < 3.3) {
          openAmount = 1.0;
          instruction = 'Keep eyes relaxed';
        } else if (t < 3.45) {
          final frac = (t - 3.3) / 0.15;
          openAmount = 1.0 - frac; // closing
          instruction = 'Blink!';
        } else if (t < 3.65) {
          openAmount = 0.0; // closed
          instruction = 'Blink!';
        } else if (t < 3.8) {
          final frac = (t - 3.65) / 0.15;
          openAmount = frac; // opening
          instruction = 'Keep eyes relaxed';
        } else {
          openAmount = 1.0;
          instruction = 'Keep eyes relaxed';
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final size = math.min(constraints.maxWidth, constraints.maxHeight);
            final eyeSize = size * 0.45;

            return Stack(
              alignment: Alignment.center,
              children: [
                // Countdown arc (overall break time)
                SizedBox(
                  width: size,
                  height: size,
                  child: CircularProgressIndicator(
                    value: widget.totalDurationSeconds > 0
                        ? widget.remainingSeconds / widget.totalDurationSeconds
                        : 0,
                    strokeWidth: 3,
                    color: themeColor.withValues(alpha: 0.4),
                    backgroundColor: Colors.white.withValues(alpha: 0.06),
                  ),
                ),
                // Center blinking eye painter
                SizedBox(
                  width: eyeSize * 1.5,
                  height: eyeSize,
                  child: CustomPaint(
                    painter: _EyePacingPainter(
                      openAmount: openAmount,
                      color: themeColor,
                    ),
                  ),
                ),
                // Center labels positioned below/above the eye shape
                Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 24),
                      child: Text(
                        _formatTime(widget.remainingSeconds),
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.white70,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: Text(
                        instruction,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: openAmount < 0.5 ? themeColor : Colors.white60,
                          fontWeight: FontWeight.w600,
                        ),
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

class _EyePacingPainter extends CustomPainter {
  final double openAmount;
  final Color color;

  const _EyePacingPainter({
    required this.openAmount,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w / 2, h / 2);

    final outerPath = Path();
    // Build almond shape.
    final double topOffset = (h / 2) - (h * 0.35 * openAmount);
    final double bottomOffset = (h / 2) + (h * 0.35 * openAmount);

    outerPath.moveTo(w * 0.1, h / 2);
    outerPath.quadraticBezierTo(w / 2, topOffset, w * 0.9, h / 2);
    outerPath.quadraticBezierTo(w / 2, bottomOffset, w * 0.1, h / 2);
    outerPath.close();

    canvas.save();

    // Eyeball background filling (soft clean white)
    final eyeballPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.9)
      ..style = PaintingStyle.fill;
    canvas.drawPath(outerPath, eyeballPaint);

    // Clip to keep the iris/pupil strictly inside the eyelids
    canvas.clipPath(outerPath);

    // Draw Iris
    final irisRadius = math.min(w, h) * 0.28;
    final irisPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, irisRadius, irisPaint);

    // Draw Pupil
    final pupilPaint = Paint()
      ..color = Colors.black87
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, irisRadius * 0.45, pupilPaint);

    // Draw light reflection spot
    final reflectionPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
      center + Offset(-irisRadius * 0.22, -irisRadius * 0.22),
      irisRadius * 0.15,
      reflectionPaint,
    );

    canvas.restore();

    // Draw eyelids outline
    final lidPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(outerPath, lidPaint);
  }

  @override
  bool shouldRepaint(covariant _EyePacingPainter old) =>
      old.openAmount != openAmount || old.color != color;
}
