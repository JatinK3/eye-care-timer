import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/timer_session.dart';
import '../../services/notification_service.dart';
import '../../theme/color_presets.dart';

/// Home page with all timer logic and UI.
class TimerHomePage extends StatefulWidget {
  final bool isDark;
  final String colorPreset;
  final int initialWorkDurationSeconds;
  final int initialBreakDurationSeconds;
  final int initialStreakCount;
  final int dailyGoal;
  final bool longBreakEnabled;
  final int longBreakDurationSeconds;
  final int longBreakEveryCycles;
  final bool autoRunEnabled;
  final int autoRunCycleLimit;
  final TimerSession initialSession;
  final bool notificationsEnabled;
  final bool hapticsEnabled;
  final bool soundEnabled;
  final void Function(BuildContext context, bool canChangeDurations)
  openSettings;
  final void Function(String) setPreset;
  final VoidCallback toggleTheme;
  final void Function(int workDurationSeconds, int breakDurationSeconds)
  saveDurations;
  final void Function(int streakCount) saveStreakCount;
  final void Function(bool enabled) setNotificationsEnabled;
  final void Function(TimerSession session) saveSession;
  final VoidCallback clearSession;
  final NotificationService notificationService;

  const TimerHomePage({
    super.key,
    required this.isDark,
    required this.colorPreset,
    required this.initialWorkDurationSeconds,
    required this.initialBreakDurationSeconds,
    required this.initialStreakCount,
    required this.dailyGoal,
    required this.longBreakEnabled,
    required this.longBreakDurationSeconds,
    required this.longBreakEveryCycles,
    required this.autoRunEnabled,
    required this.autoRunCycleLimit,
    required this.initialSession,
    required this.notificationsEnabled,
    required this.hapticsEnabled,
    required this.soundEnabled,
    required this.openSettings,
    required this.setPreset,
    required this.toggleTheme,
    required this.saveDurations,
    required this.saveStreakCount,
    required this.setNotificationsEnabled,
    required this.saveSession,
    required this.clearSession,
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
  late bool _longBreakEnabled;
  late int _longBreakDurationSeconds;
  late int _longBreakEveryCycles;
  late bool _autoRunEnabled;
  late int _autoRunCycleLimit;
  int _autoRunCompletedCycles = 0;

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
  DateTime? _phaseStartedAt;
  DateTime? _phaseEndsAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _workDurationSeconds = widget.initialWorkDurationSeconds;
    _breakDurationSeconds = widget.initialBreakDurationSeconds;
    _longBreakEnabled = widget.longBreakEnabled;
    _longBreakDurationSeconds = widget.longBreakDurationSeconds;
    _longBreakEveryCycles = widget.longBreakEveryCycles;
    _autoRunEnabled = widget.autoRunEnabled;
    _autoRunCycleLimit = widget.autoRunCycleLimit;
    _autoRunCompletedCycles = widget.initialSession.completedAutoRunCycles;
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

    _restoreInitialSession();
  }

  @override
  void didUpdateWidget(covariant TimerHomePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_isRunning) {
      return;
    }
    if (oldWidget.initialWorkDurationSeconds !=
            widget.initialWorkDurationSeconds ||
        oldWidget.initialBreakDurationSeconds !=
            widget.initialBreakDurationSeconds ||
        oldWidget.initialStreakCount != widget.initialStreakCount ||
        oldWidget.longBreakEnabled != widget.longBreakEnabled ||
        oldWidget.longBreakDurationSeconds != widget.longBreakDurationSeconds ||
        oldWidget.longBreakEveryCycles != widget.longBreakEveryCycles ||
        oldWidget.autoRunEnabled != widget.autoRunEnabled ||
        oldWidget.autoRunCycleLimit != widget.autoRunCycleLimit) {
      setState(() {
        _workDurationSeconds = widget.initialWorkDurationSeconds;
        _breakDurationSeconds = widget.initialBreakDurationSeconds;
        _longBreakEnabled = widget.longBreakEnabled;
        _longBreakDurationSeconds = widget.longBreakDurationSeconds;
        _longBreakEveryCycles = widget.longBreakEveryCycles;
        _autoRunEnabled = widget.autoRunEnabled;
        _autoRunCycleLimit = widget.autoRunCycleLimit;
        _streakCount = widget.initialStreakCount;
        _initialDuration = _workDurationSeconds;
        _remainingSeconds = _initialDuration;
        _animationController.duration = Duration(seconds: _initialDuration);
        _animationController.reset();
      });
    }
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

  void _restoreInitialSession() {
    final session = widget.initialSession;
    if (!session.isActive) {
      return;
    }

    if (session.isPaused) {
      _restorePausedSession(session);
      return;
    }

    final phaseEndsAt = session.phaseEndsAt;
    if (phaseEndsAt == null) {
      widget.clearSession();
      return;
    }

    final remainingSeconds = phaseEndsAt.difference(DateTime.now()).inSeconds;
    if (remainingSeconds <= 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _completeExpiredRestoredSession(session);
        }
      });
      return;
    }

    _restoreRunningSession(session, remainingSeconds);
  }

  void _restorePausedSession(TimerSession session) {
    final remainingSeconds = session.remainingSeconds <= 0
        ? session.initialDurationSeconds
        : session.remainingSeconds;
    final progress = _progressFromRemaining(
      initialDurationSeconds: session.initialDurationSeconds,
      remainingSeconds: remainingSeconds,
    );

    setState(() {
      _isBreak = session.isBreak;
      _isRunning = true;
      _isPaused = true;
      _isCancelled = false;
      _initialDuration = session.initialDurationSeconds;
      _remainingSeconds = remainingSeconds;
      _animationController.duration = Duration(
        seconds: session.initialDurationSeconds,
      );
      _animationController.value = progress;
      _autoRunCompletedCycles = session.completedAutoRunCycles;
    });
  }

  void _restoreRunningSession(TimerSession session, int remainingSeconds) {
    final progress = _progressFromRemaining(
      initialDurationSeconds: session.initialDurationSeconds,
      remainingSeconds: remainingSeconds,
    );

    setState(() {
      _isBreak = session.isBreak;
      _isRunning = true;
      _isPaused = false;
      _isCancelled = false;
      _phaseStartedAt = session.phaseStartedAt;
      _phaseEndsAt = session.phaseEndsAt;
      _initialDuration = session.initialDurationSeconds;
      _remainingSeconds = remainingSeconds;
      _animationController.duration = Duration(
        seconds: session.initialDurationSeconds,
      );
      _autoRunCompletedCycles = session.completedAutoRunCycles;
    });
    _animationController.forward(from: progress);
    unawaited(
      _schedulePhaseReminder(remainingSeconds, isBreak: session.isBreak),
    );
  }

  bool _shouldContinueAutoRun() {
    return _autoRunEnabled &&
        (_autoRunCycleLimit <= 0 ||
            _autoRunCompletedCycles < _autoRunCycleLimit);
  }

  int _breakDurationForCompletedCycle(int completedCycles) {
    if (!_longBreakEnabled || _longBreakEveryCycles <= 0) {
      return _breakDurationSeconds;
    }
    return completedCycles % _longBreakEveryCycles == 0
        ? _longBreakDurationSeconds
        : _breakDurationSeconds;
  }

  void _completeExpiredRestoredSession(TimerSession session) {
    final phaseEndsAt = session.phaseEndsAt;
    if (phaseEndsAt == null) {
      widget.clearSession();
      return;
    }

    _autoRunCompletedCycles = session.completedAutoRunCycles;
    if (session.isBreak) {
      if (_shouldContinueAutoRun()) {
        _startTimer(_workDurationSeconds);
      } else {
        _autoRunCompletedCycles = 0;
        widget.clearSession();
      }
      return;
    }

    final completedCycles = _streakCount + 1;
    setState(() {
      _streakCount = completedCycles;
      _autoRunCompletedCycles = session.completedAutoRunCycles + 1;
    });
    widget.saveStreakCount(_streakCount);

    final overdueSeconds = DateTime.now().difference(phaseEndsAt).inSeconds;
    final remainingBreakSeconds =
        _breakDurationForCompletedCycle(completedCycles) - overdueSeconds;
    if (remainingBreakSeconds <= 0) {
      widget.clearSession();
      return;
    }

    _startTimer(remainingBreakSeconds, isBreak: true);
  }

  double _progressFromRemaining({
    required int initialDurationSeconds,
    required int remainingSeconds,
  }) {
    if (initialDurationSeconds <= 0) {
      return 0.0;
    }
    final elapsedSeconds = initialDurationSeconds - remainingSeconds;
    return (elapsedSeconds / initialDurationSeconds).clamp(0.0, 1.0);
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
      _phaseStartedAt = DateTime.now();
      _phaseEndsAt = _phaseStartedAt!.add(Duration(seconds: duration));
      _initialDuration = duration;
      _remainingSeconds = duration;
      _animationController.duration = Duration(seconds: duration);
    });

    _animationController.forward(from: 0.0);
    _saveActiveSession(remainingSeconds: duration);
    unawaited(_schedulePhaseReminder(duration, isBreak: isBreak));
  }

  void _startWorkTimer() {
    _autoRunCompletedCycles = 0;
    _startTimer(_workDurationSeconds);
  }

  void _pauseOrResume() {
    if (!_isRunning) return;
    setState(() {
      _isPaused = !_isPaused;
      if (_isPaused) {
        _animationController.stop();
        _pulseController.stop();
        _phaseStartedAt = null;
        _phaseEndsAt = null;
        _saveActiveSession(isPaused: true);
        unawaited(widget.notificationService.cancelPhaseReminder());
      } else {
        _phaseStartedAt = DateTime.now();
        _phaseEndsAt = _phaseStartedAt!.add(
          Duration(seconds: _remainingSeconds),
        );
        _animationController.forward();
        _saveActiveSession();
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
      _phaseStartedAt = null;
      _phaseEndsAt = null;
      _autoRunCompletedCycles = 0;
      _initialDuration = _workDurationSeconds;
      _remainingSeconds = _initialDuration;
      _animationController.reset();
    });
    widget.clearSession();
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
    _saveActiveSession(remainingSeconds: remainingSeconds);
    _animationController.forward(from: progress);
  }

  void _onPhaseComplete() {
    if (_isCancelled || !mounted) {
      return;
    }

    final completedBreakPhase = _isBreak;
    _phaseStartedAt = null;
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
        if (_shouldContinueAutoRun()) {
          _startTimer(_workDurationSeconds);
          return;
        }

        setState(() {
          _isRunning = false;
          _isPaused = false;
          _isBreak = false;
          _phaseOpacity = 1.0;
          _phaseStartedAt = null;
          _phaseEndsAt = null;
          _autoRunCompletedCycles = 0;
          _initialDuration = _workDurationSeconds;
          _remainingSeconds = _initialDuration;
          _animationController.reset();
          _pulseController.reset();
        });
        widget.clearSession();
        return;
      }

      final completedCycles = _streakCount + 1;
      setState(() {
        _streakCount = completedCycles;
        _autoRunCompletedCycles++;
      });
      widget.saveStreakCount(_streakCount);
      _startTimer(
        _breakDurationForCompletedCycle(completedCycles),
        isBreak: true,
      );
    });
  }

  void _saveActiveSession({bool? isPaused, int? remainingSeconds}) {
    widget.saveSession(
      TimerSession(
        isActive: true,
        isBreak: _isBreak,
        isPaused: isPaused ?? _isPaused,
        initialDurationSeconds: _initialDuration,
        remainingSeconds: remainingSeconds ?? _remainingSeconds,
        phaseStartedAt: _phaseStartedAt,
        phaseEndsAt: _phaseEndsAt,
        completedAutoRunCycles: _autoRunCompletedCycles,
      ),
    );
  }

  Future<void> _schedulePhaseReminder(
    int durationSeconds, {
    required bool isBreak,
  }) {
    if (!widget.notificationsEnabled) {
      return Future<void>.value();
    }

    final delay = Duration(seconds: durationSeconds);
    return isBreak
        ? widget.notificationService.scheduleBreakCompleteReminder(delay)
        : widget.notificationService.scheduleWorkCompleteReminder(delay);
  }

  void _playChime() {
    if (widget.hapticsEnabled) {
      unawaited(HapticFeedback.lightImpact());
    }
    if (widget.soundEnabled) {
      unawaited(SystemSound.play(SystemSoundType.alert));
    }
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
    return ColorPresets.backgroundGradient(preset, isDark);
  }

  String get _statusLabel {
    if (!_isRunning) {
      return 'Idle';
    }
    if (_isPaused) {
      return 'Paused';
    }
    return _isBreak ? 'Break' : 'Work';
  }

  String get _phaseTitle {
    if (!_isRunning) {
      return 'Ready for your next focus session';
    }
    if (_isPaused) {
      return _isBreak ? 'Break paused' : 'Work paused';
    }
    return _isBreak
        ? 'Break Time - look 20 ft away'
        : 'Work Time - focus on your task';
  }

  String get _phaseSubtitle {
    if (!_isRunning) {
      return 'Start when your eyes and task are ready.';
    }
    if (_isPaused) {
      return 'Resume when you are ready to continue.';
    }
    return _isBreak
        ? 'Relax your focus and blink naturally.'
        : 'A reminder will help you take the next eye break.';
  }

  IconData get _statusIcon {
    if (!_isRunning) {
      return Icons.check_circle_outline;
    }
    if (_isPaused) {
      return Icons.pause_circle_outline;
    }
    return _isBreak ? Icons.visibility_outlined : Icons.timer_outlined;
  }

  Color _progressColorForMode(bool isBreak, String preset, bool isDark) {
    return ColorPresets.progressColor(
      isBreak: isBreak,
      preset: preset,
      isDark: isDark,
    );
  }

  Color _foregroundForButtonBackground(Color backgroundColor) {
    return backgroundColor.computeLuminance() > 0.45
        ? Colors.black87
        : Colors.white;
  }

  String get _timerModeSummary {
    final workMinutes = (_workDurationSeconds / 60).round();
    final breakLabel = _durationLabel(_breakDurationSeconds);
    final autoRunLabel = _autoRunEnabled
        ? _autoRunCycleLimit <= 0
              ? ' Auto run: unlimited.'
              : ' Auto run: $_autoRunCycleLimit cycles.'
        : '';
    if (!_longBreakEnabled) {
      return 'Every $workMinutes min, look 20 ft away for $breakLabel.$autoRunLabel';
    }
    return 'Every $workMinutes min, rest for $breakLabel. Long break after $_longBreakEveryCycles cycles.$autoRunLabel';
  }

  String _durationLabel(int seconds) {
    if (seconds < 60) {
      return '$seconds s';
    }
    final minutes = seconds ~/ 60;
    return '$minutes min';
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
    final primaryButtonForeground = _foregroundForButtonBackground(
      progressColor,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Eye Care Timer'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => widget.openSettings(context, _canChangeSettings),
            tooltip: 'Settings',
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
                  220.0,
                  320.0,
                );
                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 20,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedOpacity(
                        opacity: _phaseOpacity,
                        duration: const Duration(milliseconds: 400),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: progressColor.withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: progressColor.withValues(alpha: 0.35),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _statusIcon,
                                    size: 16,
                                    color: progressColor,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    _statusLabel,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: progressColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              _phaseTitle,
                              style: Theme.of(context).textTheme.titleLarge,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _phaseSubtitle,
                              style: Theme.of(context).textTheme.bodyMedium,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
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
                                    _statusLabel,
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
                      const SizedBox(height: 16),
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
                                foregroundColor: primaryButtonForeground,
                                elevation: isDark ? 3 : 1,
                                shadowColor: Colors.black54,
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
                            onPressed: _isRunning ? _cancelTimer : null,
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
                      const SizedBox(height: 12),
                      Opacity(
                        opacity: 0.95,
                        child: Text(
                          _timerModeSummary,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Daily goal: $_streakCount / ${widget.dailyGoal} breaks',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _streakCount >= widget.dailyGoal
                            ? 'Goal reached for today'
                            : 'Streak today: $_streakCount cycles',
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
