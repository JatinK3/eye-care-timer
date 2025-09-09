import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // for vibration haptic feedback

void main() {
  runApp(const EyeCareTimerApp());
}

/// Top-level app that owns ThemeMode and color preset state
class EyeCareTimerApp extends StatefulWidget {
  const EyeCareTimerApp({super.key});

  @override
  State<EyeCareTimerApp> createState() => _EyeCareTimerAppState();
}

class _EyeCareTimerAppState extends State<EyeCareTimerApp> {
  ThemeMode _themeMode = ThemeMode.light;
  String _colorPreset = 'Pastel'; // "Pastel", "Calm Blue"

  void _toggleTheme() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.light
          ? ThemeMode.dark
          : ThemeMode.light;
    });
  }

  void _setPreset(String preset) {
    setState(() {
      _colorPreset = preset;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Eye Care Timer',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          brightness: Brightness.dark,
        ),
      ),
      themeMode: _themeMode,
      home: TimerHomePage(
        isDark: _themeMode == ThemeMode.dark,
        colorPreset: _colorPreset,
        setPreset: _setPreset,
        toggleTheme: _toggleTheme,
      ),
    );
  }
}

/// Home page with all timer logic and UI.
class TimerHomePage extends StatefulWidget {
  final bool isDark;
  final String colorPreset;
  final void Function(String) setPreset;
  final VoidCallback toggleTheme;

  const TimerHomePage({
    super.key,
    required this.isDark,
    required this.colorPreset,
    required this.setPreset,
    required this.toggleTheme,
  });

  @override
  State<TimerHomePage> createState() => _TimerHomePageState();
}

class _TimerHomePageState extends State<TimerHomePage>
    with TickerProviderStateMixin {
  // -------------------- Styling --------------------
  final double _ringStrokeWidth = 12.0;
  final Color _textColorLight = Colors.black87;
  final Color _textColorDark = Colors.white;
  final Color _ringBackgroundColorLight = Colors.grey;
  final Color _ringBackgroundColorDark = Colors.black45;

  // -------------------- Durations --------------------
  int _workDurationSeconds = 20 * 60;
  int _breakDurationSeconds = 20;

  late int _initialDuration;
  late int _remainingSeconds;

  bool _isRunning = false;
  bool _isPaused = false;
  bool _isBreak = false;
  bool _isCancelled = false;

  int _streakCount = 0;

  // -------------------- Animation --------------------
  late AnimationController _animationController;
  late Animation<double> _progressAnimation;

  // Pulse animation for timer circle
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // Phase text fade
  double _phaseOpacity = 1.0;

  @override
  void initState() {
    super.initState();
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
    _animationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  // -------------------- Timer Logic --------------------
  void _startTimer(int duration, {bool isBreak = false}) {
    _stopTimerCleanup();
    setState(() {
      _isBreak = isBreak;
      _isRunning = true;
      _isPaused = false;
      _isCancelled = false;
      _initialDuration = duration;
      _remainingSeconds = duration;
      _animationController.duration = Duration(seconds: duration);
    });

    _animationController.forward(from: 0.0);
  }

  void _startWorkTimer() => _startTimer(_workDurationSeconds);
  void _startBreakTimer() => _startTimer(_breakDurationSeconds, isBreak: true);

  void _pauseOrResume() {
    if (!_isRunning) return;
    setState(() {
      _isPaused = !_isPaused;
      if (_isPaused) {
        _animationController.stop();
        _pulseController.stop();
      } else {
        _animationController.forward();
        if (_remainingSeconds <= 5) _pulseController.forward();
      }
    });
  }

  void _cancelTimer() {
    _isCancelled = true;
    _stopTimerCleanup();
    setState(() {
      _isRunning = false;
      _isPaused = false;
      _isBreak = false;
      _initialDuration = _workDurationSeconds;
      _remainingSeconds = _initialDuration;
      _animationController.reset();
      _pulseController.reset();
    });
  }

  void _stopTimerCleanup() {
    _animationController.stop();
    _pulseController.stop();
  }

  void _onPhaseComplete() {
    if (_isCancelled) return;
    _playChime();

    setState(() => _phaseOpacity = 0.0);

    Future.delayed(const Duration(milliseconds: 300), () {
      if (!_isBreak) {
        _streakCount++;
        _startTimer(_breakDurationSeconds, isBreak: true);
      } else {
        setState(() {
          _isRunning = false;
          _isPaused = false;
          _isBreak = false;
          _initialDuration = _workDurationSeconds;
          _remainingSeconds = _initialDuration;
          _animationController.reset();
          _pulseController.reset();
        });
      }

      setState(() => _phaseOpacity = 1.0);
    });
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
    if (isBreak)
      return isDark ? Colors.lightGreenAccent.shade100 : Colors.green;
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
                              ? 'Break Time — look 20 ft away 🌿'
                              : 'Work Time — focus on your task',
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
                                      color: textColor.withOpacity(0.75),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (!_isRunning)
                            ElevatedButton(
                              onPressed: _startWorkTimer,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: progressColor,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: const Text('Start'),
                            )
                          else
                            ElevatedButton(
                              onPressed: _pauseOrResume,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.black87,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: Text(_isPaused ? 'Resume' : 'Pause'),
                            ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            onPressed: _cancelTimer,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red.shade600,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text('Cancel'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
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
                          'Follow 20-20-20: every ${(_workDurationSeconds / 60).round()} min look 20 ft away for $_breakDurationSeconds s.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Streak today: $_streakCount cycles 🎉',
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
