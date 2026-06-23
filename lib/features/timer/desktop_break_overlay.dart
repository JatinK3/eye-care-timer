import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../models/timer_settings.dart';
import '../../services/desktop_controls_controller.dart';
import 'break_guides.dart';

class DesktopBreakOverlay extends StatefulWidget {
  final int initialDurationSeconds;
  final BreakMode breakMode;
  final VoidCallback onDismiss;
  final List<Rect> monitorRects;
  final String breakVisualizerStyle;

  const DesktopBreakOverlay({
    super.key,
    required this.initialDurationSeconds,
    required this.breakMode,
    required this.onDismiss,
    this.monitorRects = const [],
    this.breakVisualizerStyle = 'Breathing',
  });

  @override
  State<DesktopBreakOverlay> createState() => _DesktopBreakOverlayState();
}

class _DesktopBreakOverlayState extends State<DesktopBreakOverlay> {
  late int _remainingSeconds;
  late String _currentExercise;
  StreamSubscription<DesktopTimerState>? _stateSubscription;
  Timer? _localTimer;
  double _holdProgress = 0.0;
  Timer? _holdTimer;
  bool _hasDismissed = false;

  final List<String> _exercises = [
    "Look 20 feet away at something green.",
    "Blink rapidly for 10 seconds to moisten your eyes.",
    "Roll your eyes slowly in a circle, then reverse.",
    "Close your eyes tightly and rest them.",
    "Focus on a distant object, then a near object.",
  ];

  @override
  void initState() {
    super.initState();
    _remainingSeconds = widget.initialDurationSeconds;

    final random = math.Random();
    _currentExercise = _exercises[random.nextInt(_exercises.length)];

    // Listen to timer state changes to keep countdown synced
    _stateSubscription = DesktopControlsController.instance.states.listen((
      state,
    ) {
      if (!mounted) return;
      if (state.isBreak && state.remainingSeconds > 0) {
        setState(() {
          _remainingSeconds = state.remainingSeconds;
        });
      } else {
        _dismiss();
      }
    });

    // Fallback local timer (e.g. for previews)
    if (_remainingSeconds > 0) {
      _localTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) return;
        final nextRemaining = _remainingSeconds - 1;
        if (nextRemaining <= 0) {
          _dismiss();
          return;
        }
        setState(() {
          _remainingSeconds = nextRemaining;
        });
      });
    }
  }

  @override
  void dispose() {
    _stateSubscription?.cancel();
    _localTimer?.cancel();
    _holdTimer?.cancel();
    super.dispose();
  }

  void _dismiss() {
    if (_hasDismissed) return;
    _hasDismissed = true;
    _localTimer?.cancel();
    widget.onDismiss();
  }

  void _startHoldingExit() {
    _holdTimer?.cancel();
    setState(() {
      _holdProgress = 0.0;
    });

    const steps = 30; // 3 seconds at 100ms interval
    int currentStep = 0;
    _holdTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!mounted) return;
      currentStep++;
      setState(() {
        _holdProgress = currentStep / steps;
      });
      if (currentStep >= steps) {
        _holdTimer?.cancel();
        DesktopControlsController.instance.triggerCommand(
          DesktopCommand.skipBreak,
        );
        _dismiss();
      }
    });
  }

  void _stopHoldingExit() {
    _holdTimer?.cancel();
    setState(() {
      _holdProgress = 0.0;
    });
  }

  String _formatDuration(int totalSeconds) {
    final m = totalSeconds ~/ 60;
    final s = totalSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final rects = widget.monitorRects;
    
    Widget content;
    // Spanning multiple monitors: paint backdrop across the whole window
    // and center an identical break card within each physical screen.
    if (rects.length > 1) {
      content = Stack(
        fit: StackFit.expand,
        children: [
          for (final rect in rects)
            Positioned.fromRect(
              rect: rect,
              child: Center(child: _buildBreakCard(context)),
            ),
        ],
      );
    } else {
      content = SafeArea(child: Center(child: _buildBreakCard(context)));
    }

    if (widget.breakVisualizerStyle == 'Ambient' ||
        widget.breakVisualizerStyle == 'Breathing') {
      return Scaffold(
        backgroundColor: Colors.black,
        body: _AmbientBackground(child: content),
      );
    } else if (widget.breakVisualizerStyle == 'Starry') {
      return Scaffold(
        backgroundColor: const Color(0xFF020205),
        body: _StarrySkyBackground(child: content),
      );
    } else if (widget.breakVisualizerStyle == 'EyeExercise') {
      return Scaffold(
        backgroundColor: const Color(0xFF020D10),
        body: content,
      );
    } else if (widget.breakVisualizerStyle == 'BoxBreathing') {
      return Scaffold(
        backgroundColor: const Color(0xFF07070F),
        body: content,
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: content,
    );
  }

  Widget _buildBreakCard(BuildContext context) {
    final style = widget.breakVisualizerStyle;

    // Full-screen guided modes — no card, just the guide + controls
    if (style == 'EyeExercise' || style == 'BoxBreathing') {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 340,
                    maxHeight: 340,
                  ),
                  child: style == 'EyeExercise'
                      ? EyeExerciseDotGuide(
                          remainingSeconds: _remainingSeconds,
                          totalDurationSeconds: widget.initialDurationSeconds,
                        )
                      : BoxBreathingGuide(
                          remainingSeconds: _remainingSeconds,
                          totalDurationSeconds: widget.initialDurationSeconds,
                        ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              style == 'EyeExercise'
                  ? 'Eye Exercise Break'
                  : 'Box Breathing Break',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Colors.white38,
                  ),
            ),
            const SizedBox(height: 24),
            _buildBreakActions(context),
            const SizedBox(height: 32),
          ],
        ),
      );
    }

    final theme = Theme.of(context);
    final textStyle = theme.textTheme;
    final showBreathingGuide = widget.breakVisualizerStyle == 'Breathing';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (showBreathingGuide)
            _BreathingGuideCircle(remainingSeconds: _remainingSeconds)
          else ...[
            const Icon(Icons.visibility_outlined, color: Colors.cyan, size: 64),
            const SizedBox(height: 32),
          ],
          const SizedBox(height: 16),
          Text(
            'Time to rest your eyes',
            style: textStyle.headlineMedium?.copyWith(
              color: Colors.white70,
              fontWeight: FontWeight.w400,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              _currentExercise,
              style: textStyle.headlineSmall?.copyWith(
                color: Colors.cyanAccent,
                fontWeight: FontWeight.w300,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 48),
          if (!showBreathingGuide) ...[
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 150,
                  height: 150,
                  child: CircularProgressIndicator(
                    value: widget.initialDurationSeconds > 0
                        ? _remainingSeconds / widget.initialDurationSeconds
                        : 0.0,
                    strokeWidth: 8,
                    color: Colors.cyan,
                    backgroundColor: Colors.white12,
                  ),
                ),
                Text(
                  _formatDuration(_remainingSeconds),
                  style: textStyle.displaySmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 64),
          ] else ...[
            const SizedBox(height: 32),
          ],
          _buildBreakActions(context),
        ],
      ),
    );
  }

  /// Shared action buttons used by both the classic card and guided-mode layouts.
  Widget _buildBreakActions(BuildContext context) {
    if (widget.breakMode == BreakMode.gentle) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white70,
              side: const BorderSide(color: Colors.white24),
              shape: const StadiumBorder(),
              padding: const EdgeInsets.symmetric(
                horizontal: 28,
                vertical: 14,
              ),
            ),
            onPressed: () {
              DesktopControlsController.instance.triggerCommand(
                DesktopCommand.postponeBreak,
              );
              _dismiss();
            },
            icon: const Icon(Icons.snooze),
            label: const Text('Postpone'),
          ),
          const SizedBox(width: 24),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.cyanAccent,
              foregroundColor: Colors.black87,
              shape: const StadiumBorder(),
              padding: const EdgeInsets.symmetric(
                horizontal: 28,
                vertical: 14,
              ),
            ),
            onPressed: () {
              DesktopControlsController.instance.triggerCommand(
                DesktopCommand.skipBreak,
              );
              _dismiss();
            },
            icon: const Icon(Icons.skip_next),
            label: const Text('Skip'),
          ),
        ],
      );
    } else if (widget.breakMode == BreakMode.strict) {
      return GestureDetector(
        onTapDown: (_) => _startHoldingExit(),
        onTapUp: (_) => _stopHoldingExit(),
        onTapCancel: () => _stopHoldingExit(),
        child: Column(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 80,
                  height: 80,
                  child: CircularProgressIndicator(
                    value: _holdProgress,
                    strokeWidth: 6,
                    color: Colors.redAccent,
                    backgroundColor: Colors.white10,
                  ),
                ),
                Container(
                  width: 64,
                  height: 64,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.power_settings_new,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Builder(
              builder: (context) => Text(
                'Press and hold to exit',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }
}

class _AmbientBackground extends StatefulWidget {
  final Widget child;
  const _AmbientBackground({required this.child});

  @override
  State<_AmbientBackground> createState() => _AmbientBackgroundState();
}

class _AmbientBackgroundState extends State<_AmbientBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value;
        final color1 = Color.lerp(
          const Color(0xFF05050F),
          const Color(0xFF0C1030),
          t,
        )!;
        final color2 = Color.lerp(
          const Color(0xFF081820),
          const Color(0xFF150825),
          t,
        )!;

        final alignment1 = Alignment(
          math.sin(t * 2 * math.pi) * 0.5,
          math.cos(t * 2 * math.pi) * 0.5,
        );
        final alignment2 = Alignment(
          math.cos(t * 2 * math.pi + math.pi) * 0.6,
          math.sin(t * 2 * math.pi + math.pi) * 0.6,
        );

        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF020205),
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: alignment1,
                      radius: 1.5,
                      colors: [
                        color1.withValues(alpha: 0.4),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: alignment2,
                      radius: 1.5,
                      colors: [
                        color2.withValues(alpha: 0.35),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              ?child,
            ],
          ),
        );
      },
      child: widget.child,
    );
  }
}

class _StarrySkyBackground extends StatefulWidget {
  final Widget child;
  const _StarrySkyBackground({required this.child});

  @override
  State<_StarrySkyBackground> createState() => _StarrySkyBackgroundState();
}

class _StarrySkyBackgroundState extends State<_StarrySkyBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_Star> _stars = [];

  @override
  void initState() {
    super.initState();
    final random = math.Random();
    for (int i = 0; i < 35; i++) {
      _stars.add(
        _Star(
          x: random.nextDouble(),
          y: random.nextDouble(),
          size: random.nextDouble() * 2.2 + 0.6,
          speed: random.nextDouble() * 0.015 + 0.005,
          opacity: random.nextDouble() * 0.5 + 0.2,
        ),
      );
    }

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        for (final star in _stars) {
          star.y -= star.speed * 0.005;
          if (star.y < 0) {
            star.y = 1.0;
            star.x = math.Random().nextDouble();
          }
        }

        return CustomPaint(
          painter: _StarPainter(_stars),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

class _Star {
  double x;
  double y;
  final double size;
  final double speed;
  final double opacity;

  _Star({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.opacity,
  });
}

class _StarPainter extends CustomPainter {
  final List<_Star> stars;
  _StarPainter(this.stars);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    for (final star in stars) {
      paint.color = Colors.white.withValues(alpha: star.opacity);
      canvas.drawCircle(
        Offset(star.x * size.width, star.y * size.height),
        star.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _BreathingGuideCircle extends StatefulWidget {
  final int remainingSeconds;
  const _BreathingGuideCircle({required this.remainingSeconds});

  @override
  State<_BreathingGuideCircle> createState() => _BreathingGuideCircleState();
}

class _BreathingGuideCircleState extends State<_BreathingGuideCircle>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

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

  String _formatDuration(int totalSeconds) {
    final m = totalSeconds ~/ 60;
    final s = totalSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final value = _controller.value * 16.0;
        double scale = 1.0;
        String instruction = "Hold";
        Color ringColor = Colors.cyan.withValues(alpha: 0.3);

        if (value < 4.0) {
          final t = value / 4.0;
          scale = 1.0 + (t * 0.3);
          instruction = "Breathe In";
          ringColor = Color.lerp(
            Colors.cyan.withValues(alpha: 0.3),
            Colors.cyanAccent.withValues(alpha: 0.8),
            t,
          )!;
        } else if (value < 8.0) {
          scale = 1.3;
          instruction = "Hold";
          ringColor = Colors.cyanAccent.withValues(alpha: 0.8);
        } else if (value < 12.0) {
          final t = (value - 8.0) / 4.0;
          scale = 1.3 - (t * 0.3);
          instruction = "Breathe Out";
          ringColor = Color.lerp(
            Colors.cyanAccent.withValues(alpha: 0.8),
            Colors.teal.withValues(alpha: 0.4),
            t,
          )!;
        } else {
          scale = 1.0;
          instruction = "Hold";
          ringColor = Colors.teal.withValues(alpha: 0.4);
        }

        return SizedBox(
          width: 220,
          height: 220,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer wave ring (creates a clean expanding glow without shadows)
              Transform.scale(
                scale: scale * 1.15,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: ringColor.withValues(alpha: 0.15),
                      width: 1.5,
                    ),
                  ),
                ),
              ),
              // Main breathing ring
              Transform.scale(
                scale: scale,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: ringColor.withValues(alpha: 0.03),
                    border: Border.all(
                      color: ringColor,
                      width: 3.5,
                    ),
                  ),
                ),
              ),
              // Inner text
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _formatDuration(widget.remainingSeconds),
                    style: theme.textTheme.displaySmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    instruction,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: Colors.white60,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
