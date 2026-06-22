import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../models/timer_settings.dart';
import '../../services/desktop_controls_controller.dart';

class DesktopBreakOverlay extends StatefulWidget {
  final int initialDurationSeconds;
  final BreakMode breakMode;
  final VoidCallback onDismiss;

  /// Per-monitor rectangles in this window's local coordinate space. When the
  /// overlay window spans multiple monitors, the break card is replicated and
  /// centered within each one. Empty for a single-monitor fullscreen overlay.
  final List<Rect> monitorRects;

  const DesktopBreakOverlay({
    super.key,
    required this.initialDurationSeconds,
    required this.breakMode,
    required this.onDismiss,
    this.monitorRects = const [],
  });

  @override
  State<DesktopBreakOverlay> createState() => _DesktopBreakOverlayState();
}

class _DesktopBreakOverlayState extends State<DesktopBreakOverlay> {
  late int _remainingSeconds;
  late double _rotationAngle;
  late String _currentExercise;
  StreamSubscription<DesktopTimerState>? _stateSubscription;
  Timer? _localTimer;
  double _holdProgress = 0.0;
  Timer? _holdTimer;

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
    // Random rotation between -5 and +5 degrees
    _rotationAngle = (random.nextDouble() * 10 - 5) * math.pi / 180;
    _currentExercise = _exercises[random.nextInt(_exercises.length)];

    // Listen to timer state changes to keep countdown synced
    _stateSubscription = DesktopControlsController.instance.states.listen((
      state,
    ) {
      if (!mounted) return;
      if (state.isBreak) {
        setState(() {
          _remainingSeconds = state.remainingSeconds;
        });
      } else {
        widget.onDismiss();
      }
    });

    // Fallback local timer (e.g. for previews)
    if (_remainingSeconds > 0) {
      _localTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) return;
        setState(() {
          if (_remainingSeconds > 0) {
            _remainingSeconds--;
          } else {
            _localTimer?.cancel();
            widget.onDismiss();
          }
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
        widget.onDismiss();
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
    // Spanning multiple monitors: paint a black backdrop across the whole
    // window and center an identical break card within each physical screen so
    // the user cannot simply look at an uncovered display.
    if (rects.length > 1) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          fit: StackFit.expand,
          children: [
            for (final rect in rects)
              Positioned.fromRect(
                rect: rect,
                child: Center(child: _buildBreakCard(context)),
              ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(child: Center(child: _buildBreakCard(context))),
    );
  }

  Widget _buildBreakCard(BuildContext context) {
    final theme = Theme.of(context);
    final textStyle = theme.textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.visibility_outlined, color: Colors.cyan, size: 64),
          const SizedBox(height: 32),
          Text(
            'Time to rest your eyes',
            style: textStyle.headlineMedium?.copyWith(
              color: Colors.white70,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Transform.rotate(
            angle: _rotationAngle,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.cyan.withValues(alpha: 0.3)),
              ),
              child: Text(
                _currentExercise,
                style: textStyle.titleLarge?.copyWith(
                  color: Colors.cyanAccent,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          const SizedBox(height: 48),
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
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 64),
          if (widget.breakMode == BreakMode.gentle) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white70,
                    side: const BorderSide(color: Colors.white30),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                  ),
                  onPressed: () {
                    DesktopControlsController.instance.triggerCommand(
                      DesktopCommand.postponeBreak,
                    );
                    widget.onDismiss();
                  },
                  icon: const Icon(Icons.snooze),
                  label: const Text('Postpone'),
                ),
                const SizedBox(width: 24),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.cyan,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                  ),
                  onPressed: () {
                    DesktopControlsController.instance.triggerCommand(
                      DesktopCommand.skipBreak,
                    );
                    widget.onDismiss();
                  },
                  icon: const Icon(Icons.skip_next),
                  label: const Text('Skip'),
                ),
              ],
            ),
          ] else if (widget.breakMode == BreakMode.strict) ...[
            GestureDetector(
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
                  const Text(
                    'Press and hold to exit',
                    style: TextStyle(
                      color: Colors.redAccent,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
