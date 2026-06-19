import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/timer_session.dart';
import '../../models/timer_settings.dart';
import '../../services/break_overlay_service.dart';
import '../../services/notification_service.dart';
import '../../services/timer_background_service.dart';
import '../../theme/color_presets.dart';
import 'phase_schedule.dart';

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
  final BreakMode breakMode;
  final BreakOverlayService? breakOverlayService;
  final void Function(BuildContext context, bool canChangeDurations)
  openSettings;
  final void Function(String) setPreset;
  final VoidCallback toggleTheme;
  final void Function(int workDurationSeconds, int breakDurationSeconds)
  saveDurations;
  final void Function(int streakCount) saveStreakCount;
  final void Function(DateTime completedAt, int durationSeconds)
  saveCompletedWorkSession;
  final void Function(bool enabled) setNotificationsEnabled;
  final void Function(TimerSession session) saveSession;
  final VoidCallback clearSession;
  final NotificationService notificationService;
  final TimerBackgroundService? backgroundService;
  final bool allowSkip;
  final bool allowPostpone;
  final int postponeDurationSeconds;
  final bool smartIdleEnabled;

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
    required this.breakMode,
    required this.allowSkip,
    required this.allowPostpone,
    required this.postponeDurationSeconds,
    required this.smartIdleEnabled,
    this.breakOverlayService,
    required this.openSettings,
    required this.setPreset,
    required this.toggleTheme,
    required this.saveDurations,
    required this.saveStreakCount,
    required this.saveCompletedWorkSession,
    required this.setNotificationsEnabled,
    required this.saveSession,
    required this.clearSession,
    required this.notificationService,
    this.backgroundService,
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
  bool _isFocusMode = false;

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

  late final TimerBackgroundService _backgroundService;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _backgroundService = widget.backgroundService ?? TimerBackgroundService();
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
    if (_isFocusMode) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
    WidgetsBinding.instance.removeObserver(this);
    _phaseTransitionTimer?.cancel();
    _animationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _toggleFocusMode() {
    setState(() {
      _isFocusMode = !_isFocusMode;
      if (_isFocusMode) {
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      } else {
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      }
    });
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

    final projection = projectPhase(
      now: DateTime.now(),
      isBreak: session.isBreak,
      phaseEndsAt: phaseEndsAt,
      currentPhaseDurationSeconds: session.initialDurationSeconds,
      streakCount: _streakCount,
      autoRunCompletedCycles: session.completedAutoRunCycles,
      plan: _currentPlan(),
    );

    if (projection.boundariesCrossed == 0 && !projection.isIdle) {
      // Same phase is still running: restore it on the first frame without
      // touching parent state (the persisted session is already accurate).
      _applyProjection(
        projection,
        persist: false,
        scheduleReminder: true,
        playChime: false,
      );
      return;
    }

    // One or more boundaries elapsed while the app was closed. Defer applying
    // until after the first frame because it writes back to parent state.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _applyProjection(
          projection,
          persist: true,
          scheduleReminder: true,
          playChime: false,
        );
      }
    });
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

  PhasePlan _currentPlan() {
    return PhasePlan(
      workDurationSeconds: _workDurationSeconds,
      breakDurationSeconds: _breakDurationSeconds,
      longBreakEnabled: _longBreakEnabled,
      longBreakDurationSeconds: _longBreakDurationSeconds,
      longBreakEveryCycles: _longBreakEveryCycles,
      autoRunEnabled: _autoRunEnabled,
      autoRunCycleLimit: _autoRunCycleLimit,
    );
  }

  /// Applies a [projectPhase] result: records any work phases that finished
  /// while the app was away, then either lands on the running phase or resets
  /// to idle. Used by both launch-restore and resume reconciliation so the two
  /// paths behave identically.
  void _applyProjection(
    PhaseProjection projection, {
    required bool persist,
    required bool scheduleReminder,
    required bool playChime,
  }) {
    for (final work in projection.completedWorkSessions) {
      widget.saveCompletedWorkSession(work.completedAt, work.durationSeconds);
    }
    if (projection.completedWorkSessions.isNotEmpty) {
      _streakCount = projection.streakCount;
      widget.saveStreakCount(_streakCount);
    }
    _autoRunCompletedCycles = projection.autoRunCompletedCycles;

    if (playChime && projection.boundariesCrossed > 0) {
      _playChime();
    }

    if (projection.isIdle) {
      _phaseTransitionTimer?.cancel();
      _phaseTransitionTimer = null;
      _cancelReminders();
      unawaited(_backgroundService.stopPhase());
      unawaited(widget.breakOverlayService?.stopBreakOverlay());
      setState(() {
        _isRunning = false;
        _isPaused = false;
        _isBreak = false;
        _isCancelled = false;
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

    final progress = _progressFromRemaining(
      initialDurationSeconds: projection.initialDurationSeconds,
      remainingSeconds: projection.remainingSeconds,
    );
    setState(() {
      _isBreak = projection.isBreak;
      _isRunning = true;
      _isPaused = false;
      _isCancelled = false;
      _phaseOpacity = 1.0;
      _phaseStartedAt = projection.phaseStartedAt;
      _phaseEndsAt = projection.phaseEndsAt;
      _initialDuration = projection.initialDurationSeconds;
      _remainingSeconds = projection.remainingSeconds;
      _animationController.duration = Duration(
        seconds: projection.initialDurationSeconds,
      );
    });
    _animationController.forward(from: progress);
    if (persist) {
      _saveActiveSession(remainingSeconds: projection.remainingSeconds);
    }
    if (scheduleReminder) {
      unawaited(
        _schedulePhaseReminder(
          projection.remainingSeconds,
          isBreak: projection.isBreak,
        ),
      );
    }
    _startBackgroundPhase(
      phaseEndsAt: projection.phaseEndsAt!,
      isBreak: projection.isBreak,
    );
    if (projection.isBreak && widget.breakMode != BreakMode.off) {
      unawaited(
        widget.breakOverlayService?.showBreakOverlay(
          durationSeconds: projection.remainingSeconds,
          breakMode: widget.breakMode,
        ),
      );
    } else {
      unawaited(widget.breakOverlayService?.stopBreakOverlay());
    }
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

  void _startBackgroundPhase({
    required DateTime phaseEndsAt,
    required bool isBreak,
  }) {
    unawaited(
      _backgroundService.startPhase(
        phaseEndsAt: phaseEndsAt,
        isBreak: isBreak,
        breakMode: widget.breakMode,
        workDurationSeconds: _workDurationSeconds,
        breakDurationSeconds: _breakDurationSeconds,
        longBreakEnabled: _longBreakEnabled,
        longBreakDurationSeconds: _longBreakDurationSeconds,
        longBreakEveryCycles: _longBreakEveryCycles,
        autoRunEnabled: _autoRunEnabled,
        autoRunCycleLimit: _autoRunCycleLimit,
        streakCount: _streakCount,
        completedAutoRunCycles: _autoRunCompletedCycles,
        allowSkip: widget.allowSkip,
        allowPostpone: widget.allowPostpone,
        postponeDurationSeconds: widget.postponeDurationSeconds,
        smartIdleEnabled: widget.smartIdleEnabled,
      ),
    );
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
    _cancelReminders();
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
    _startBackgroundPhase(phaseEndsAt: _phaseEndsAt!, isBreak: isBreak);
    if (isBreak && widget.breakMode != BreakMode.off) {
      unawaited(
        widget.breakOverlayService?.showBreakOverlay(
          durationSeconds: duration,
          breakMode: widget.breakMode,
        ),
      );
    } else {
      unawaited(widget.breakOverlayService?.stopBreakOverlay());
    }
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
        _cancelReminders();
        unawaited(_backgroundService.stopPhase());
      } else {
        _phaseStartedAt = DateTime.now();
        _phaseEndsAt = _phaseStartedAt!.add(
          Duration(seconds: _remainingSeconds),
        );
        _animationController.forward();
        _saveActiveSession();
        unawaited(_schedulePhaseReminder(_remainingSeconds, isBreak: _isBreak));
        _startBackgroundPhase(phaseEndsAt: _phaseEndsAt!, isBreak: _isBreak);
        if (_remainingSeconds <= 5) _pulseController.forward();
      }
    });
  }

  void _cancelReminders() {
    unawaited(widget.notificationService.cancelPhaseReminder());
    unawaited(widget.notificationService.cancelPreBreakWarningReminder());
  }

  void _skipBreak() {
    if (!_isBreak || !_isRunning) return;
    _animationController.stop();
    _onPhaseComplete();
  }

  void _postponeBreak() {
    if (!_isRunning) return;
    _animationController.stop();
    _playChime();
    _pulseController.stop();
    setState(() {
      _isBreak = false;
      _phaseOpacity = 1.0;
      _initialDuration = widget.postponeDurationSeconds;
      _remainingSeconds = _initialDuration;
      _phaseStartedAt = DateTime.now();
      _phaseEndsAt = _phaseStartedAt!.add(Duration(seconds: _initialDuration));
      _animationController.duration = Duration(seconds: _initialDuration);
      _animationController.reset();
      _animationController.forward(from: 0.0);
    });
    _startBackgroundPhase(phaseEndsAt: _phaseEndsAt!, isBreak: false);
    _saveActiveSession(remainingSeconds: _remainingSeconds);
  }

  void _cancelTimer() {
    _isCancelled = true;
    _phaseTransitionTimer?.cancel();
    _phaseTransitionTimer = null;
    _stopTimerCleanup(resetPulse: true);
    _cancelReminders();
    unawaited(_backgroundService.stopPhase());
    unawaited(widget.breakOverlayService?.stopBreakOverlay());
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

  Future<void> _syncTimerWithClock() async {
    if (!_isRunning || _isPaused || _phaseEndsAt == null) {
      return;
    }

    _animationController.stop();
    final bgSession = await _backgroundService.getBackgroundSession();
    if (!mounted) return;
    if (bgSession != null && bgSession['isActive'] == true) {
      final bgEndsAtMillis = bgSession['phaseEndsAtMillis'] as int;
      final bgIsBreak = bgSession['isBreak'] as bool;
      final bgStreakCount = bgSession['streakCount'] as int;
      final bgCompletedAutoRunCycles =
          bgSession['completedAutoRunCycles'] as int;

      setState(() {
        _isBreak = bgIsBreak;
        _streakCount = bgStreakCount;
        _autoRunCompletedCycles = bgCompletedAutoRunCycles;
        _phaseEndsAt = DateTime.fromMillisecondsSinceEpoch(bgEndsAtMillis);

        _workDurationSeconds = bgSession['workDurationSeconds'] as int;
        _breakDurationSeconds = bgSession['breakDurationSeconds'] as int;
        _longBreakEnabled = bgSession['longBreakEnabled'] as bool;
        _longBreakDurationSeconds =
            bgSession['longBreakDurationSeconds'] as int;
        _longBreakEveryCycles = bgSession['longBreakEveryCycles'] as int;
        _autoRunEnabled = bgSession['autoRunEnabled'] as bool;
        _autoRunCycleLimit = bgSession['autoRunCycleLimit'] as int;

        _initialDuration = _isBreak
            ? _breakDurationForCompletedCycle(_streakCount)
            : _workDurationSeconds;
      });
    }

    final projection = projectPhase(
      now: DateTime.now(),
      isBreak: _isBreak,
      phaseEndsAt: _phaseEndsAt!,
      currentPhaseDurationSeconds: _initialDuration,
      streakCount: _streakCount,
      autoRunCompletedCycles: _autoRunCompletedCycles,
      plan: _currentPlan(),
    );
    _applyProjection(
      projection,
      persist: true,
      scheduleReminder: projection.boundariesCrossed > 0,
      playChime: true,
    );
  }

  void _onPhaseComplete() {
    if (_isCancelled || !mounted) {
      return;
    }

    final completedBreakPhase = _isBreak;
    final completedPhaseAt = _phaseEndsAt ?? DateTime.now();
    _phaseStartedAt = null;
    _phaseEndsAt = null;
    _cancelReminders();
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

        unawaited(_backgroundService.stopPhase());
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
      widget.saveCompletedWorkSession(completedPhaseAt, _initialDuration);
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

  Future<bool> _schedulePhaseReminder(
    int durationSeconds, {
    required bool isBreak,
  }) {
    if (!widget.notificationsEnabled) {
      return Future<bool>.value(false);
    }

    final delay = Duration(seconds: durationSeconds);
    if (isBreak) {
      return widget.notificationService.scheduleBreakCompleteReminder(delay);
    } else {
      if (durationSeconds > 10) {
        unawaited(
          widget.notificationService.schedulePreBreakWarningReminder(
            Duration(seconds: durationSeconds - 10),
          ),
        );
      }
      return widget.notificationService.scheduleWorkCompleteReminder(delay);
    }
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

    final showWarningOverlay =
        _isRunning &&
        !_isBreak &&
        !_isPaused &&
        _remainingSeconds <= 10 &&
        _remainingSeconds > 0;
    final warningOpacity = showWarningOverlay
        ? ((10 - _remainingSeconds) / 10.0).clamp(0.0, 1.0)
        : 0.0;

    return Scaffold(
      appBar: _isFocusMode
          ? null
          : AppBar(
              title: const Text('BlinkKind'),
              backgroundColor: Colors.transparent,
              elevation: 0,
              actions: [
                IconButton(
                  icon: const Icon(Icons.settings),
                  onPressed: () =>
                      widget.openSettings(context, _canChangeSettings),
                  tooltip: 'Settings',
                ),
              ],
            ),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              color: _isFocusMode ? Colors.black : null,
              gradient: _isFocusMode
                  ? null
                  : _backgroundGradientFromPreset(widget.colorPreset, isDark),
            ),
            child: SafeArea(
              child: Center(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isLandscape =
                        MediaQuery.of(context).orientation ==
                        Orientation.landscape;
                    final double size = isLandscape
                        ? (constraints.maxHeight - 48).clamp(160.0, 260.0)
                        : (constraints.maxWidth - 48).clamp(220.0, 320.0);

                    final timerDial = GestureDetector(
                      onTap: _toggleFocusMode,
                      behavior: HitTestBehavior.opaque,
                      child: ScaleTransition(
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
                                      fontSize: isLandscape ? 28 : 36,
                                      fontWeight: FontWeight.w700,
                                      color: textColor,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _statusLabel,
                                    style: TextStyle(
                                      fontSize: isLandscape ? 11 : 14,
                                      color: textColor.withValues(alpha: 0.75),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );

                    final actionButtons = Wrap(
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
                              padding: EdgeInsets.symmetric(
                                horizontal: isLandscape ? 16 : 22,
                                vertical: isLandscape ? 8 : 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          )
                        else ...[
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
                              padding: EdgeInsets.symmetric(
                                horizontal: isLandscape ? 16 : 20,
                                vertical: isLandscape ? 8 : 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                          if (_isBreak && !_isPaused) ...[
                            if (widget.allowSkip)
                              ElevatedButton.icon(
                                onPressed: _skipBreak,
                                icon: const Icon(Icons.skip_next),
                                label: const Text('Skip'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green.shade600,
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.symmetric(
                                    horizontal: isLandscape ? 16 : 20,
                                    vertical: isLandscape ? 8 : 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            if (widget.allowPostpone)
                              ElevatedButton.icon(
                                onPressed: _postponeBreak,
                                icon: const Icon(Icons.snooze),
                                label: const Text('Postpone'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange.shade700,
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.symmetric(
                                    horizontal: isLandscape ? 16 : 20,
                                    vertical: isLandscape ? 8 : 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                          ],
                        ],
                        OutlinedButton.icon(
                          onPressed: _isRunning ? _cancelTimer : null,
                          icon: const Icon(Icons.stop),
                          label: const Text('Cancel'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: isDark
                                ? Colors.red.shade200
                                : Colors.red.shade700,
                            side: BorderSide(color: Colors.red.shade300),
                            padding: EdgeInsets.symmetric(
                              horizontal: isLandscape ? 14 : 18,
                              vertical: isLandscape ? 8 : 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ],
                    );

                    if (isLandscape) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            timerDial,
                            const SizedBox(width: 32),
                            Expanded(
                              child: SingleChildScrollView(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    if (!_isFocusMode) ...[
                                      AnimatedOpacity(
                                        opacity: _phaseOpacity,
                                        duration: const Duration(
                                          milliseconds: 400,
                                        ),
                                        child: Column(
                                          children: [
                                            Text(
                                              _phaseTitle,
                                              style: Theme.of(
                                                context,
                                              ).textTheme.titleLarge,
                                              textAlign: TextAlign.center,
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              _phaseSubtitle,
                                              style: Theme.of(
                                                context,
                                              ).textTheme.bodyMedium,
                                              textAlign: TextAlign.center,
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                    ],
                                    actionButtons,
                                    const SizedBox(height: 12),
                                    if (!_isFocusMode) ...[
                                      Text(
                                        _timerModeSummary,
                                        textAlign: TextAlign.center,
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodyMedium,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Daily goal: $_streakCount / ${widget.dailyGoal} breaks',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w700,
                                            ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _streakCount >= widget.dailyGoal
                                            ? 'Goal reached for today'
                                            : 'Streak today: $_streakCount cycles',
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodyMedium,
                                      ),
                                    ] else ...[
                                      Opacity(
                                        opacity: 0.35,
                                        child: Text(
                                          'Tap dial to exit focus mode',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: textColor,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    // Portrait Layout
                    return SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 20,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (!_isFocusMode) ...[
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
                                      color: progressColor.withValues(
                                        alpha: 0.14,
                                      ),
                                      borderRadius: BorderRadius.circular(999),
                                      border: Border.all(
                                        color: progressColor.withValues(
                                          alpha: 0.35,
                                        ),
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
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleLarge,
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _phaseSubtitle,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodyMedium,
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                          timerDial,
                          const SizedBox(height: 20),
                          actionButtons,
                          const SizedBox(height: 16),
                          if (!_isFocusMode) ...[
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
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _streakCount >= widget.dailyGoal
                                  ? 'Goal reached for today'
                                  : 'Streak today: $_streakCount cycles',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ] else ...[
                            Opacity(
                              opacity: 0.35,
                              child: Text(
                                'Tap dial to exit focus mode',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: textColor,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          if (showWarningOverlay)
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: warningOpacity),
                child: Center(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.visibility_off_outlined,
                            size: 64,
                            color: Colors.red.shade300.withValues(
                              alpha: warningOpacity,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Eye break starting in $_remainingSeconds seconds',
                            style: Theme.of(context).textTheme.headlineMedium
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Prepare to look 20 feet away to rest your eyes',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(color: Colors.white70),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (widget.allowPostpone) ...[
                                ElevatedButton.icon(
                                  onPressed: _postponeBreak,
                                  icon: const Icon(Icons.snooze),
                                  label: Text(
                                    'Postpone (${widget.postponeDurationSeconds ~/ 60}m)',
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white24,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                              ],
                              OutlinedButton.icon(
                                onPressed: _cancelTimer,
                                icon: const Icon(Icons.close),
                                label: const Text('Cancel Timer'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.red.shade200,
                                  side: BorderSide(color: Colors.red.shade300),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
