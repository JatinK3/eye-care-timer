import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/notification_service.dart';

/// Home page with all timer logic and UI.
class TimerHomePage extends StatefulWidget {
  final bool isDark;
  final String colorPreset;
  final int initialWorkDurationSeconds;
  final int initialBreakDurationSeconds;
  final int initialStreakCount;
  final void Function(String) setPreset;
  final VoidCallback toggleTheme;
  final void Function(int workDurationSeconds, int breakDurationSeconds)
  saveDurations;
  final void Function(int streakCount) saveStreakCount;
  final NotificationService notificationService;

  const TimerHomePage({
    super.key,
    required this.isDark,
    required this.colorPreset,
    required this.initialWorkDurationSeconds,
    required this.initialBreakDurationSeconds,
    required this.initialStreakCount,
    required this.setPreset,
    required this.toggleTheme,
    required this.saveDurations,
    required this.saveStreakCount,
    required this.notificationService,
  });

  @override
  State<TimerHomePage> createState() => _TimerHomePageState();
}

class _TimerHomePageState extends State<TimerHomePage>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  // -------------------- Styling --------------------
  final double _ringStrokeWidth = 12.0;
  final Color _textColorLight = Colors.black87;
  final Color _textColorDark = Colors.white;
  final Color _ringBackgroundColorLight = Colors.black12;
  final Color _ringBackgroundColorDark = Colors.white24;

  // -------------------- Durations --------------------
  late int _workDurationSeconds;
  late int _breakDurationSeconds;

  late int _initialDuration;
  late int _remainingSeconds;

  bool _isRunning = false;
  bool _isPaused = false;
  bool _isBreak = false;
  bool _isCancelled = false;

  late int _streakCount;

  // -------------------- Animation --------------------
  late AnimationController _animationController;
  late Animation<double> _progressAnimation;

  // Pulse animation for timer circle.
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // Phase text fade.
  double _phaseOpacity = 1.0;
  Timer? _phaseTransitionTimer;
  DateTime? _phaseEndsAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _workDurationSeconds = widget.initialWorkDurationSeconds;
    _breakDurationSeconds = widget.initialBreakDurationSeconds;
    _streakCount = widget.initialStreakCount;
    _initialDuration = _workDurationSeconds;
    _remainingSeconds = _initialDuration;

    // Main progress controller
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(seconds: _initialDuration),
    );

    _progressAnimation =
        Tween<double>(begin: 1.0, end: 0.0).animate(_animationController)
          ..addListener(() {
            setState(() {
              _remainingSeconds = (_initialDuration * _progressAnimation.value)
                  .ceil();

              if (_remainingSeconds <= 5 &&
                  !_pulseController.isAnimating &&
                  _isRunning) {
                _pulseController.forward();
              }
            });
          })
          ..addStatusListener((status) {
            if (status == AnimationStatus.completed) {
              _onPhaseComplete();
            }
          });

    // Pulse animation setup
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    _pulseAnimation =
        Tween<double>(begin: 1.0, end: 1.08).animate(
          CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
        )..addStatusListener((status) {
          if (status == AnimationStatus.completed) {
            _pulseController.reverse();
          } else if (status == AnimationStatus.dismissed) {
            if (_remainingSeconds <= 5 && _isRunning) {
              _pulseController.forward();
            }
          }
        });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _phaseTransitionTimer?.cancel();
    _animationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _syncTimerWithClock();
    }
  }

  // -------------------- Timer Logic --------------------
  void _startTimer(int duration, {bool isBreak = false}) {
    _phaseTransitionTimer?.cancel();
    _phaseTransitionTimer = null;
    _stopTimerCleanup(resetPulse: true);
    unawaited(widget.notificationService.cancelPhaseReminder());
    setState(() {
      _isBreak = isBreak;
      _isRunning = true;
      _isPaused = false;
      _isCancelled = false;
      _phaseOpacity = 1.0;
      _phaseEndsAt = DateTime.now().add(Duration(seconds: duration));
      _initialDuration = duration;
      _remainingSeconds = duration;
      _animationController.duration = Duration(seconds: duration);
    });

    _animationController.forward(from: 0.0);
    unawaited(_schedulePhaseReminder(duration, isBreak: isBreak));
  }

  void _startWorkTimer() => _startTimer(_workDurationSeconds);

  void _pauseOrResume() {
    if (!_isRunning) return;
    setState(() {
      _isPaused = !_isPaused;
      if (_isPaused) {
        _animationController.stop();
        _pulseController.stop();
        _phaseEndsAt = null;
        unawaited(widget.notificationService.cancelPhaseReminder());
      } else {
        _animationController.forward();
        unawaited(_schedulePhaseReminder(_remainingSeconds, isBreak: _isBreak));
        if (_remainingSeconds <= 5) _pulseController.forward();
      }
    });
  }

  void _cancelTimer() {
    _isCancelled = true;
    _phaseTransitionTimer?.cancel();
    _phaseTransitionTimer = null;
    _stopTimerCleanup(resetPulse: true);
    unawaited(widget.notificationService.cancelPhaseReminder());
    setState(() {
      _isRunning = false;
      _isPaused = false;
      _isBreak = false;
      _phaseOpacity = 1.0;
      _phaseEndsAt = null;
      _initialDuration = _workDurationSeconds;
      _remainingSeconds = _initialDuration;
      _animationController.reset();
    });
  }

  void _stopTimerCleanup({bool resetPulse = false}) {
    _animationController.stop();
    _pulseController.stop();
    if (resetPulse) {
      _pulseController.reset();
    }
  }

  void _syncTimerWithClock() {
    if (!_isRunning || _isPaused || _phaseEndsAt == null) {
      return;
    }

    final remainingSeconds = _phaseEndsAt!.difference(DateTime.now()).inSeconds;
    if (remainingSeconds <= 0) {
      _remainingSeconds = 0;
      _animationController.stop();
      _onPhaseComplete();
      return;
    }

    final elapsedSeconds = _initialDuration - remainingSeconds;
    final progress = (elapsedSeconds / _initialDuration).clamp(0.0, 1.0);
    setState(() {
      _remainingSeconds = remainingSeconds;
    });
    _animationController.forward(from: progress);
  }

  void _onPhaseComplete() {
    if (_isCancelled || !mounted) {
      return;
    }

    final completedBreakPhase = _isBreak;
    _phaseEndsAt = null;
    unawaited(widget.notificationService.cancelPhaseReminder());
    _playChime();
    _pulseController.stop();

    setState(() => _phaseOpacity = 0.0);

    _phaseTransitionTimer?.cancel();
    _phaseTransitionTimer = Timer(const Duration(milliseconds: 300), () {
      _phaseTransitionTimer = null;
      if (!mounted || _isCancelled) {
        return;
      }

      if (completedBreakPhase) {
        setState(() {
          _isRunning = false;
          _isPaused = false;
          _isBreak = false;
          _phaseOpacity = 1.0;
          _phaseEndsAt = null;
          _initialDuration = _workDurationSeconds;
          _remainingSeconds = _initialDuration;
          _animationController.reset();
          _pulseController.reset();
        });
        return;
      }

      setState(() => _streakCount++);
      widget.saveStreakCount(_streakCount);
      _startTimer(_breakDurationSeconds, isBreak: true);
    });
  }

  Future<void> _schedulePhaseReminder(
    int durationSeconds, {
    required bool isBreak,
  }) {
    final delay = Duration(seconds: durationSeconds);
    return isBreak
        ? widget.notificationService.scheduleBreakCompleteReminder(delay)
        : widget.notificationService.scheduleWorkCompleteReminder(delay);
  }

  void _playChime() {
    HapticFeedback.lightImpact();
  }

  String _formattedTime(int seconds) {
    if (seconds >= 60) {
      final m = seconds ~/ 60;
      final s = seconds % 60;
      return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    } else {
      return seconds.toString();
    }
  }

  bool get _canChangeSettings => !_isRunning;

  LinearGradient _backgroundGradientFromPreset(String preset, bool isDark) {
    switch (preset) {
      case 'Calm Blue':
        return isDark
            ? const LinearGradient(
                colors: [Color(0xFF0F1724), Color(0xFF102A43)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : const LinearGradient(
                colors: [Color(0xFFDFF6FF), Color(0xFF9BBDF9)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              );
      default: // Pastel
        return isDark
            ? const LinearGradient(
                colors: [Color(0xFF101216), Color(0xFF1A1C1F)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : const LinearGradient(
                colors: [Color(0xFFF2F7F7), Color(0xFFEAF6F5)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              );
    }
  }

  Color _progressColorForMode(bool isBreak, String preset, bool isDark) {
    if (isBreak) {
      return isDark ? Colors.lightGreenAccent.shade100 : Colors.green;
    }
    switch (preset) {
      case 'Calm Blue':
        return isDark ? Colors.lightBlueAccent.shade100 : Colors.blue;
      default: // Pastel
        return isDark ? Colors.tealAccent.shade100 : Colors.teal;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final textColor = isDark ? _textColorDark : _textColorLight;
    final ringBgColor = isDark
        ? _ringBackgroundColorDark
        : _ringBackgroundColorLight;
    final progressColor = _progressColorForMode(
      _isBreak,
      widget.colorPreset,
      isDark,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Eye Care Timer'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(widget.isDark ? Icons.light_mode : Icons.dark_mode),
            onPressed: widget.toggleTheme,
            tooltip: 'Toggle theme',
          ),
          IconButton(
            icon: const Icon(Icons.color_lens),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                builder: (_) => SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: ['Pastel', 'Calm Blue']
                        .map(
                          (preset) => ListTile(
                            leading: CircleAvatar(
                              radius: 10,
                              backgroundColor: _progressColorForMode(
                                false,
                                preset,
                                isDark,
                              ),
                            ),
                            title: Text(preset),
                            trailing: preset == widget.colorPreset
                                ? const Icon(Icons.check)
                                : null,
                            onTap: () {
                              widget.setPreset(preset);
                              Navigator.pop(context);
                            },
                          ),
                        )
                        .toList(),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: _backgroundGradientFromPreset(widget.colorPreset, isDark),
        ),
        child: SafeArea(
          child: Center(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final double size = (constraints.maxWidth - 48).clamp(
                  240.0,
                  360.0,
                );
                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 28,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedOpacity(
                        opacity: _phaseOpacity,
                        duration: const Duration(milliseconds: 400),
                        child: Text(
                          _isBreak
                              ? 'Break Time - look 20 ft away'
                              : 'Work Time - focus on your task',
                          style: Theme.of(context).textTheme.titleLarge,
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 20),
                      ScaleTransition(
                        scale: _pulseAnimation,
                        child: SizedBox(
                          width: size,
                          height: size,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              SizedBox(
                                width: size * 0.92,
                                height: size * 0.92,
                                child: CircularProgressIndicator(
                                  value: 1.0,
                                  strokeWidth: _ringStrokeWidth,
                                  color: ringBgColor,
                                ),
                              ),
                              SizedBox(
                                width: size * 0.92,
                                height: size * 0.92,
                                child: CircularProgressIndicator(
                                  value: _progressAnimation.value,
                                  strokeWidth: _ringStrokeWidth,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    progressColor,
                                  ),
                                  backgroundColor: Colors.transparent,
                                ),
                              ),
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _formattedTime(_remainingSeconds),
                                    style: TextStyle(
                                      fontSize: 36,
                                      fontWeight: FontWeight.w700,
                                      color: textColor,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    _isBreak ? 'Break' : 'Work',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: textColor.withValues(alpha: 0.75),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 12,
                        runSpacing: 8,
                        children: [
                          if (!_isRunning)
                            ElevatedButton.icon(
                              onPressed: _startWorkTimer,
                              icon: const Icon(Icons.play_arrow),
                              label: const Text('Start'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: progressColor,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 22,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            )
                          else
                            ElevatedButton.icon(
                              onPressed: _pauseOrResume,
                              icon: Icon(
                                _isPaused ? Icons.play_arrow : Icons.pause,
                              ),
                              label: Text(_isPaused ? 'Resume' : 'Pause'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isDark
                                    ? Colors.white24
                                    : Colors.black87,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          OutlinedButton.icon(
                            onPressed: _cancelTimer,
                            icon: const Icon(Icons.stop),
                            label: const Text('Cancel'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: isDark
                                  ? Colors.red.shade200
                                  : Colors.red.shade700,
                              side: BorderSide(color: Colors.red.shade300),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Card(
                        elevation: 1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Work Duration',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  DropdownButton<int>(
                                    value: _workDurationSeconds ~/ 60,
                                    items: [1, 2, 5, 10, 15, 20, 25, 30, 45, 60]
                                        .map(
                                          (m) => DropdownMenuItem<int>(
                                            value: m,
                                            child: Text('$m min'),
                                          ),
                                        )
                                        .toList(),
                                    onChanged: _canChangeSettings
                                        ? (v) {
                                            if (v == null) return;
                                            setState(() {
                                              _workDurationSeconds = v * 60;
                                              if (!_isRunning && !_isBreak) {
                                                _initialDuration =
                                                    _workDurationSeconds;
                                                _remainingSeconds =
                                                    _initialDuration;
                                              }
                                            });
                                            widget.saveDurations(
                                              _workDurationSeconds,
                                              _breakDurationSeconds,
                                            );
                                          }
                                        : null,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Break Duration',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  DropdownButton<int>(
                                    value: _breakDurationSeconds,
                                    items: [20, 30, 45, 60, 90, 120]
                                        .map(
                                          (s) => DropdownMenuItem<int>(
                                            value: s,
                                            child: Text('$s sec'),
                                          ),
                                        )
                                        .toList(),
                                    onChanged: _canChangeSettings
                                        ? (v) {
                                            if (v == null) return;
                                            setState(() {
                                              _breakDurationSeconds = v;
                                              if (!_isRunning && !_isBreak) {
                                                _initialDuration =
                                                    _workDurationSeconds;
                                                _remainingSeconds =
                                                    _initialDuration;
                                              }
                                            });
                                            widget.saveDurations(
                                              _workDurationSeconds,
                                              _breakDurationSeconds,
                                            );
                                          }
                                        : null,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Opacity(
                        opacity: 0.95,
                        child: Text(
                          'Every ${(_workDurationSeconds / 60).round()} min, look 20 ft away for $_breakDurationSeconds s.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Streak today: $_streakCount cycles',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
