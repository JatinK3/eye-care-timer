import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:system_idle/system_idle.dart';
import 'package:window_manager/window_manager.dart';

import '../../models/timer_session.dart';
import '../../models/timer_settings.dart';
import '../../models/timer_event_record.dart';
import '../../services/ai_service.dart';
import '../../services/break_overlay_service.dart';
import '../../services/desktop_controls_controller.dart';
import '../../services/desktop_integration_service.dart';
import '../../services/notification_service.dart';
import '../../services/os_focus_service.dart';
import '../../services/system_ui_service.dart';
import '../../services/timer_background_service.dart';
import '../../theme/color_presets.dart';
import 'break_guides.dart';
import 'eye_health_tips.dart';
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
  final void Function(TimerEventRecord record) saveTimerEventRecord;
  final void Function(bool enabled) setNotificationsEnabled;
  final void Function(TimerSession session) saveSession;
  final VoidCallback clearSession;
  final NotificationService notificationService;
  final TimerBackgroundService? backgroundService;
  final bool allowSkip;
  final bool allowPostpone;
  final int postponeDurationSeconds;
  final bool smartIdleEnabled;
  final String breakVisualizerStyle;
  final bool breakShowClock;
  final bool breakShowTips;
  final bool breakShowProgress;
  final String breakCustomMessage;
  final String chimeStyle;
  final bool blinkRemindersEnabled;
  final int blinkRemindersCadenceSeconds;
  final bool workHoursEnabled;
  final int workHoursStartHour;
  final int workHoursStartMinute;
  final int workHoursEndHour;
  final int workHoursEndMinute;
  final String workDays;
  final bool naturalBreakCreditEnabled;
  final String customAccentColorHex;
  final bool useSystemAccent;
  final bool autoStartSchedule;
  final bool aiMotivationEnabled;
  final bool osFocusDndEnabled;
  final String aiProvider;
  final String aiApiKey;
  final String aiModel;
  final String aiCustomSystemPrompt;
  final bool twoStageWarningEnabled;
  final bool blinkReminderAiEnabled;
  final String blinkReminderCustomMessage;
  final bool cameraMicAutoPostponeEnabled;
  final bool wellnessRemindersEnabled;
  final int wellnessReminderCadenceSeconds;

  const TimerHomePage({
    super.key,
    required this.isDark,
    required this.colorPreset,
    required this.customAccentColorHex,
    required this.useSystemAccent,
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
    required this.breakVisualizerStyle,
    required this.breakShowClock,
    required this.breakShowTips,
    required this.breakShowProgress,
    required this.breakCustomMessage,
    required this.chimeStyle,
    required this.blinkRemindersEnabled,
    required this.blinkRemindersCadenceSeconds,
    required this.workHoursEnabled,
    required this.workHoursStartHour,
    required this.workHoursStartMinute,
    required this.workHoursEndHour,
    required this.workHoursEndMinute,
    required this.workDays,
    required this.naturalBreakCreditEnabled,
    required this.autoStartSchedule,
    required this.aiMotivationEnabled,
    required this.osFocusDndEnabled,
    required this.aiProvider,
    required this.aiApiKey,
    required this.aiModel,
    required this.aiCustomSystemPrompt,
    required this.twoStageWarningEnabled,
    required this.blinkReminderAiEnabled,
    required this.blinkReminderCustomMessage,
    required this.cameraMicAutoPostponeEnabled,
    required this.wellnessRemindersEnabled,
    required this.wellnessReminderCadenceSeconds,
    this.breakOverlayService,
    required this.openSettings,
    required this.setPreset,
    required this.toggleTheme,
    required this.saveDurations,
    required this.saveStreakCount,
    required this.saveCompletedWorkSession,
    required this.saveTimerEventRecord,
    required this.setNotificationsEnabled,
    required this.saveSession,
    required this.clearSession,
    required this.notificationService,
    this.backgroundService,
  });

  @override
  State<TimerHomePage> createState() => TimerHomePageState();
}

class TimerHomePageState extends State<TimerHomePage>
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
  Timer? _scheduleCheckTimer;
  bool _isSchedulePaused = false;
  DateTime? _idleStartedAt;
  DateTime? _snoozeEndsAt;
  int? _lastSnoozeRemaining;

  late int _initialDuration;
  late int _remainingSeconds;

  bool _isRunning = false;
  bool _isPaused = false;
  bool _isBreak = false;
  late String _activeBreakVisualizerStyle;
  bool _isCancelled = false;
  bool _isFocusMode = false;
  bool _isSystemIdlePaused = false;
  final SystemUiService _systemUiService = const SystemUiService();

  // AI-generated break quote, pre-fetched during work phase.
  String? _cachedAiQuote;

  // AI Health Insight fields
  String? _aiHealthInsight;
  bool _isAiInsightLoading = false;
  String? _aiInsightError;

  bool _lastDndState = false;

  int? _postponedBreakDuration;

  String _resolveVisualizerStyle() {
    if (widget.breakVisualizerStyle == 'Random') {
      const styles = [
        'Breathing',
        'BoxBreathing',
        'EyeExercise',
        'Ambient',
        'Starry',
      ];
      return styles[math.Random().nextInt(styles.length)];
    }
    return widget.breakVisualizerStyle;
  }

  Future<void> _preFetchAiQuote() async {
    if (!widget.aiMotivationEnabled || widget.aiApiKey.isEmpty) return;
    try {
      final quote = await AiService.instance.generateMotivation(
        provider: widget.aiProvider,
        apiKey: widget.aiApiKey,
        model: widget.aiModel,
        prompt: widget.aiCustomSystemPrompt,
      );
      _cachedAiQuote = quote;
    } catch (_) {
      // Silently ignore failures; fallback to static exercise tip.
      _cachedAiQuote = null;
    }
  }

  Future<void> _fetchAiHealthInsight() async {
    if (!widget.aiMotivationEnabled) return;
    if (widget.aiApiKey.isEmpty) {
      setState(() {
        _aiInsightError = 'API key is missing. Please configure it in Settings.';
        _isAiInsightLoading = false;
      });
      return;
    }

    setState(() {
      _isAiInsightLoading = true;
      _aiInsightError = null;
    });

    try {
      final focusAreas = [
        'posture and ergonomics',
        'stretching and flexibility',
        'hydration and water intake',
        'eye relaxation and vision rest',
        'deep breathing and stress relief',
        'quick physical movement and circulation',
      ];
      final randomFocus = focusAreas[math.Random().nextInt(focusAreas.length)];
      final seed = math.Random().nextInt(1000000);
      final prompt = 'Generate a single, unique, practical, and highly engaging desk wellness tip (strict limit of 30 words) for a developer working at a computer. Focus specifically on $randomFocus. Make it highly specific, actionable, and encouraging. [Seed: $seed]';

      final insight = await AiService.instance.generateMotivation(
        provider: widget.aiProvider,
        apiKey: widget.aiApiKey,
        model: widget.aiModel,
        prompt: prompt,
        temperature: 0.7,
      );
      setState(() {
        _aiHealthInsight = insight;
        _isAiInsightLoading = false;
      });
    } catch (e) {
      setState(() {
        _aiInsightError = 'Failed to fetch AI tip. Make sure your API key and connection are valid.';
        _isAiInsightLoading = false;
      });
    }
  }

  late int _streakCount;

  // -------------------- Animation --------------------
  late AnimationController _animationController;
  late Animation<double> _progressAnimation;

  // Pulse animation for timer circle.
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // Phase text fade.
  double _phaseOpacity = 1.0;
  bool _isBlinkNudging = false;
  Future<String?>? _blinkMessageFuture;
  int? _lastBlinkReminderBucket;
  DateTime? _lastBlinkReminderAt;
  int _wellnessTypeIndex = 0;
  Timer? _phaseTransitionTimer;
  Timer? _phaseDeadlineTimer;
  // Wall-clock 1Hz ticker (desktop only) that keeps the tray/app-indicator
  // countdown live even while the main window is hidden — the in-window
  // animation that normally drives the tray is frozen while the window isn't
  // rendering.
  Timer? _desktopTrayTicker;
  Timer? _educationTipTimer;
  int _educationTipIndex = 0;
  DateTime? _phaseStartedAt;
  DateTime? _phaseEndsAt;

  late final TimerBackgroundService _backgroundService;
  StreamSubscription<DesktopCommand>? _desktopCommandSubscription;
  StreamSubscription<bool>? _desktopIdleSubscription;
  StreamSubscription<bool>? _desktopLockSubscription;

  AudioPlayer? _audioPlayer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _audioPlayer = AudioPlayer();
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
    _activeBreakVisualizerStyle = widget.breakVisualizerStyle;
    _educationTipIndex = DateTime.now().minute % EyeHealthTips.all.length;
    _educationTipTimer = Timer.periodic(const Duration(seconds: 45), (_) {
      if (!mounted || _isFocusMode) return;
      setState(() {
        _educationTipIndex = (_educationTipIndex + 1) % EyeHealthTips.all.length;
      });
    });

    // Main progress controller
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(seconds: _initialDuration),
    );

    _progressAnimation =
        Tween<double>(begin: 1.0, end: 0.0).animate(_animationController)
          ..addListener(() {
            // Update remaining seconds and pulse trigger without setState —
            // only fields that non-animation widgets need to read.
            final nextRemaining = (_initialDuration * _progressAnimation.value)
                .ceil();
            if (nextRemaining != _remainingSeconds) {
              _remainingSeconds = nextRemaining;
              if (_remainingSeconds <= 5 &&
                  !_pulseController.isAnimating &&
                  _isRunning) {
                _pulseController.forward();
              }
              if (widget.blinkRemindersEnabled && !_isBreak && _isRunning && !_isPaused && !_isSchedulePaused && !_isSystemIdlePaused && !_isSnoozed) {
                final elapsed = _initialDuration - _remainingSeconds;
                // Pre-fetch AI blink message 2 seconds before cadence fires
                if (widget.blinkReminderAiEnabled && widget.aiMotivationEnabled && widget.aiApiKey.isNotEmpty) {
                  final preWarm = widget.blinkRemindersCadenceSeconds - 2;
                  if (preWarm > 0 && elapsed > 0 && elapsed % widget.blinkRemindersCadenceSeconds == preWarm) {
                    _blinkMessageFuture = AiService.instance.generateBlinkReminder(
                      provider: widget.aiProvider,
                      apiKey: widget.aiApiKey,
                      model: widget.aiModel,
                    ).timeout(const Duration(seconds: 3), onTimeout: () => '').catchError((_) => '');
                  }
                }
                if (elapsed > 0 && elapsed % widget.blinkRemindersCadenceSeconds == 0) {
                  _triggerBlinkNudge();
                }
              }
              // Wellness reminders (fires independently, including during breaks)
              if (widget.wellnessRemindersEnabled && _isRunning && !_isPaused && !_isSchedulePaused && !_isSystemIdlePaused && !_isSnoozed) {
                final elapsed = _initialDuration - _remainingSeconds;
                if (elapsed > 0 && elapsed % widget.wellnessReminderCadenceSeconds == 0) {
                  final type = WellnessType.values[_wellnessTypeIndex % WellnessType.values.length];
                  _wellnessTypeIndex++;
                  unawaited(widget.notificationService.showWellnessReminder(type));
                }
              }
              _updateDesktopState();
            }
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
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      unawaited(_syncTimerWithClock());
    }
    if (!kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.linux ||
            defaultTargetPlatform == TargetPlatform.macOS ||
            defaultTargetPlatform == TargetPlatform.windows)) {
      _initDesktopIdleDetection();
      _desktopCommandSubscription = DesktopControlsController.instance.commands
          .listen((command) {
            if (!mounted) return;
            switch (command) {
              case DesktopCommand.pause:
                if (_isRunning && !_isPaused) {
                  _pauseOrResume();
                }
                break;
              case DesktopCommand.resume:
                if (_isSnoozed) {
                  _cancelSnooze();
                } else if (_isPaused || !_isRunning) {
                  if (!_isRunning) {
                    _startWorkTimer();
                  } else {
                    _pauseOrResume();
                  }
                }
                break;
              case DesktopCommand.skipBreak:
                if (_isRunning && _isBreak) {
                  _skipBreak();
                }
                break;
              case DesktopCommand.postponeBreak:
                if (_isRunning && _isBreak) {
                  _postponeBreak();
                }
                break;
              case DesktopCommand.startBreak:
                if (_isRunning && !_isBreak) {
                  _startTimer(_breakDurationSeconds, isBreak: true);
                }
                break;
              case DesktopCommand.windowResumed:
                // Window was just shown from the tray; the countdown animation
                // was frozen while hidden, so snap it back to the wall clock.
                _realignAnimationToClock();
                break;
              case DesktopCommand.snooze1Hour:
                _snoozeBreaks(const Duration(hours: 1));
                break;
              case DesktopCommand.snoozeUntilTomorrow:
                _snoozeUntilTomorrow();
                break;
              case DesktopCommand.cancelSnooze:
                _cancelSnooze();
                break;
              case DesktopCommand.openSettings:
                unawaited(windowManager.show());
                unawaited(windowManager.focus());
                widget.openSettings(context, _canChangeSettings);
                break;
              case DesktopCommand.showDashboard:
                Navigator.of(context).popUntil((route) => route.isFirst);
                break;
            }
          });
      _desktopTrayTicker = Timer.periodic(
        const Duration(seconds: 1),
        (_) => _onDesktopTrayTick(),
      );
      _updateDesktopState();
    }
    _scheduleCheckTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _checkSchedule();
    });
    _checkSchedule();

    if (widget.aiMotivationEnabled) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _fetchAiHealthInsight();
      });
    }
  }

  /// Keeps the tray/app-indicator countdown in step with the wall clock.
  ///
  /// While the main window is visible the progress animation advances
  /// [_remainingSeconds] and pushes the tray state ~once a second. The moment
  /// the window is hidden/closed that animation freezes, so this Dart timer —
  /// which keeps firing regardless of window visibility — recomputes the
  /// remaining time from [_phaseEndsAt] and pushes it. It only pushes when the
  /// value actually changed, so it's a no-op while the window is visible and the
  /// animation is already current (no duplicate tray redraws).
  void _onDesktopTrayTick() {
    if (!mounted || !_isRunning) {
      return;
    }

    final isSnoozed = _isSnoozed;
    if (_isPaused && !isSnoozed) {
      return;
    }

    if (isSnoozed) {
      final now = DateTime.now();
      final snoozeRemaining = (_snoozeEndsAt!.difference(now).inSeconds / 60).ceil();
      if (snoozeRemaining != _lastSnoozeRemaining) {
        _lastSnoozeRemaining = snoozeRemaining;
        _updateDesktopState();
      }
      return;
    }

    if (_phaseEndsAt == null) return;

    final remainingMs = _phaseEndsAt!.difference(DateTime.now()).inMilliseconds;
    final clamped = (remainingMs / 1000).ceil().clamp(0, _initialDuration);
    if (clamped != _remainingSeconds) {
      _remainingSeconds = clamped;
      if (widget.blinkRemindersEnabled && !_isBreak && _isRunning && !_isPaused && !_isSchedulePaused && !_isSystemIdlePaused && !_isSnoozed) {
        final elapsed = _initialDuration - _remainingSeconds;
        // Pre-fetch AI blink message 2 seconds before cadence fires
        if (widget.blinkReminderAiEnabled && widget.aiMotivationEnabled && widget.aiApiKey.isNotEmpty) {
          final preWarm = widget.blinkRemindersCadenceSeconds - 2;
          if (preWarm > 0 && elapsed > 0 && elapsed % widget.blinkRemindersCadenceSeconds == preWarm) {
            _blinkMessageFuture = AiService.instance.generateBlinkReminder(
              provider: widget.aiProvider,
              apiKey: widget.aiApiKey,
              model: widget.aiModel,
            ).timeout(const Duration(seconds: 3), onTimeout: () => '').catchError((_) => '');
          }
        }
        if (elapsed > 0 && elapsed % widget.blinkRemindersCadenceSeconds == 0) {
          _triggerBlinkNudge();
        }
      }
      // Wellness reminders (fires independently, including during breaks)
      if (widget.wellnessRemindersEnabled && _isRunning && !_isPaused && !_isSchedulePaused && !_isSystemIdlePaused && !_isSnoozed) {
        final elapsed = _initialDuration - _remainingSeconds;
        if (elapsed > 0 && elapsed % widget.wellnessReminderCadenceSeconds == 0) {
          final type = WellnessType.values[_wellnessTypeIndex % WellnessType.values.length];
          _wellnessTypeIndex++;
          unawaited(widget.notificationService.showWellnessReminder(type));
        }
      }
      _updateDesktopState();
    }
  }

  @override
  void didUpdateWidget(covariant TimerHomePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.aiMotivationEnabled &&
        (!oldWidget.aiMotivationEnabled ||
         oldWidget.aiApiKey != widget.aiApiKey ||
         oldWidget.aiProvider != widget.aiProvider ||
         oldWidget.aiModel != widget.aiModel)) {
      _fetchAiHealthInsight();
    }
    if (oldWidget.breakVisualizerStyle != widget.breakVisualizerStyle) {
      setState(() {
        _activeBreakVisualizerStyle = _resolveVisualizerStyle();
      });
    }
    if (oldWidget.osFocusDndEnabled != widget.osFocusDndEnabled) {
      _updateOsFocusDnd();
    }
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
    _audioPlayer?.dispose();
    if (_isFocusMode) {
      unawaited(_systemUiService.setFocusModeEnabled(false));
    }
    unawaited(OsFocusService.instance.setDndEnabled(false));
    _desktopIdleSubscription?.cancel();
    _desktopLockSubscription?.cancel();
    _desktopCommandSubscription?.cancel();
    _desktopTrayTicker?.cancel();
    _educationTipTimer?.cancel();
    _scheduleCheckTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _phaseTransitionTimer?.cancel();
    _cancelPhaseDeadlineTimer();
    _animationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _toggleFocusMode() {
    setState(() {
      _isFocusMode = !_isFocusMode;
    });
    unawaited(_systemUiService.setFocusModeEnabled(_isFocusMode));
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        // Android can fully suspend the Dart VM, so reconcile across every
        // elapsed work/break boundary on resume.
        _syncTimerWithClock();
      } else if (!kIsWeb &&
          (defaultTargetPlatform == TargetPlatform.linux ||
              defaultTargetPlatform == TargetPlatform.macOS ||
              defaultTargetPlatform == TargetPlatform.windows)) {
        // Desktop keeps the Dart VM and the phase deadline timer running while
        // hidden, so only the frozen countdown *animation* needs re-aligning.
        // Deliberately NOT _syncTimerWithClock(): full phase reconciliation on
        // desktop focus transitions previously spawned duplicate break overlays
        // and corrupted streak state (see WORKLOG).
        _realignAnimationToClock();
      }
      if (_isFocusMode) {
        unawaited(_systemUiService.setFocusModeEnabled(true));
      }
      _checkSchedule();
    } else {
      if (_isFocusMode &&
          (state == AppLifecycleState.inactive ||
              state == AppLifecycleState.paused ||
              state == AppLifecycleState.hidden ||
              state == AppLifecycleState.detached)) {
        unawaited(_systemUiService.setFocusModeEnabled(false));
      }

      // If we are backgrounding the app during an active running break, trigger the native overlay (Android only)
      if (!kIsWeb &&
          defaultTargetPlatform == TargetPlatform.android &&
          _isRunning &&
          _isBreak &&
          !_isPaused &&
          (state == AppLifecycleState.paused ||
              state == AppLifecycleState.inactive)) {
        unawaited(
          widget.breakOverlayService?.showBreakOverlay(
            durationSeconds: _remainingSeconds,
            breakMode: widget.breakMode,
            breakVisualizerStyle: _activeBreakVisualizerStyle,
            aiQuote: _cachedAiQuote,
            showClock: widget.breakShowClock,
            showTips: widget.breakShowTips,
            showProgress: widget.breakShowProgress,
            customMessage: widget.breakCustomMessage,
          ),
        );
      }
    }
  }

  void _initDesktopIdleDetection() {
    if (kIsWeb) return;
    if (defaultTargetPlatform != TargetPlatform.linux &&
        defaultTargetPlatform != TargetPlatform.macOS &&
        defaultTargetPlatform != TargetPlatform.windows) {
      return;
    }

    try {
      _desktopLockSubscription = DesktopIntegrationService.instance.onSystemLockChanged.listen((isLocked) {
        if (!mounted) return;
        handleDesktopIdleChange(isLocked);
      });

      final systemIdle = SystemIdle.forPlatform();
      unawaited(() async {
        await systemIdle.initialize();
        if (!mounted) return;
        if (systemIdle.isSupported) {
          _desktopIdleSubscription = systemIdle
              .onIdleChanged(idleDuration: const Duration(seconds: 60))
              .listen((isIdle) {
            if (!mounted) return;
            handleDesktopIdleChange(isIdle);
          });
        }
      }());
    } catch (e) {
      debugPrint('Failed to initialize desktop idle detection: $e');
    }
  }

  void handleDesktopIdleChange(bool isIdle) {
    if (!widget.smartIdleEnabled) return;
    if (!_isRunning || _isBreak) return;

    if (isIdle) {
      if (!_isPaused && !_isSystemIdlePaused) {
        setState(() {
          _idleStartedAt = DateTime.now();
          _isSystemIdlePaused = true;
          _animationController.stop();
          _pulseController.stop();
          _cancelPhaseDeadlineTimer();
          _phaseStartedAt = null;
          _phaseEndsAt = null;
          _saveActiveSession(isPaused: true);
          _cancelReminders();
          unawaited(_backgroundService.stopPhase());
        });
        _updateDesktopState();
      }
    } else {
      if (_isSystemIdlePaused) {
        final idleStart = _idleStartedAt;
        _idleStartedAt = null;
        if (widget.naturalBreakCreditEnabled && idleStart != null) {
          final idleDuration = DateTime.now().difference(idleStart);
          if (idleDuration.inSeconds >= _breakDurationSeconds) {
            _creditNaturalBreak();
            return;
          }
        }

        setState(() {
          _isSystemIdlePaused = false;
          _phaseStartedAt = DateTime.now();
          _phaseEndsAt = _phaseStartedAt!.add(
            Duration(seconds: _remainingSeconds),
          );
          _animationController.forward();
          _saveActiveSession();
          _schedulePhaseDeadlineTimer(_phaseEndsAt!);
          unawaited(_schedulePhaseReminder(_remainingSeconds, isBreak: _isBreak));
          _startBackgroundPhase(phaseEndsAt: _phaseEndsAt!, isBreak: _isBreak);
          if (_remainingSeconds <= 5) _pulseController.forward();
        });
        _updateDesktopState();
      }
    }
  }

  void _restoreInitialSession() {
    final session = widget.initialSession;
    if (!session.isActive) {
      if (widget.autoStartSchedule) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && !_isRunning) {
            _startTimer(_workDurationSeconds);
            _checkSchedule();
          }
        });
      }
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

    _postponedBreakDuration = session.postponedBreakDuration;

    final projection = projectPhase(
      now: DateTime.now(),
      isBreak: session.isBreak,
      phaseEndsAt: phaseEndsAt,
      currentPhaseDurationSeconds: session.initialDurationSeconds,
      streakCount: _streakCount,
      autoRunCompletedCycles: session.completedAutoRunCycles,
      plan: _currentPlan(),
      postponedBreakDuration: session.postponedBreakDuration,
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
      if (_isBreak) {
        _activeBreakVisualizerStyle = _resolveVisualizerStyle();
      }
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
      _postponedBreakDuration = session.postponedBreakDuration;
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
    if (projection.boundariesCrossed > 0) {
      _postponedBreakDuration = null;
    }
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
      _cancelPhaseDeadlineTimer();
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
      if (_isBreak) {
        _activeBreakVisualizerStyle = _resolveVisualizerStyle();
      }
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
    _schedulePhaseDeadlineTimer(projection.phaseEndsAt!);
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
          breakVisualizerStyle: _activeBreakVisualizerStyle,
          aiQuote: _cachedAiQuote,
          showClock: widget.breakShowClock,
          showTips: widget.breakShowTips,
          showProgress: widget.breakShowProgress,
          customMessage: widget.breakCustomMessage,
        ),
      );
    } else {
      unawaited(widget.breakOverlayService?.stopBreakOverlay());
    }
    _updateDesktopState();
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
        naturalBreakCreditEnabled: widget.naturalBreakCreditEnabled,
        postponedBreakDuration: _postponedBreakDuration,
        currentPhaseDurationSeconds: _initialDuration,
      ),
    );
  }

  bool get _usesDesktopDeadlineTimer =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.linux ||
          defaultTargetPlatform == TargetPlatform.macOS ||
          defaultTargetPlatform == TargetPlatform.windows);

  void _cancelPhaseDeadlineTimer() {
    _phaseDeadlineTimer?.cancel();
    _phaseDeadlineTimer = null;
  }

  void _schedulePhaseDeadlineTimer(DateTime phaseEndsAt) {
    _cancelPhaseDeadlineTimer();
    if (!_usesDesktopDeadlineTimer) return;
    final scheduledPhaseEndsAt = phaseEndsAt;
    final delay = scheduledPhaseEndsAt.difference(DateTime.now());
    _phaseDeadlineTimer = Timer(delay.isNegative ? Duration.zero : delay, () {
      if (!mounted || !_isRunning || _isPaused) return;
      if (_phaseEndsAt != scheduledPhaseEndsAt) return;
      _remainingSeconds = 0;
      _animationController.stop();
      _onPhaseComplete();
    });
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

  /// Snaps the in-window countdown dial back into step with the wall clock after
  /// the window was hidden (its vsync animation freezes while not rendering).
  ///
  /// Intentionally lightweight: it re-aligns the *current* phase's animation to
  /// [_phaseEndsAt] and nothing more. It does NOT run [projectPhase]/phase
  /// reconciliation, cross boundaries, start breaks, or touch streak counters —
  /// the phase deadline is owned by [_phaseDeadlineTimer]. This is the desktop
  /// counterpart to [_syncTimerWithClock], which is kept Android-only because
  /// full reconciliation on desktop focus transitions previously spawned
  /// duplicate break overlays and corrupted state.
  void _realignAnimationToClock() {
    if (!_isRunning || _isPaused || _phaseEndsAt == null) {
      return;
    }
    final remainingMs = _phaseEndsAt!.difference(DateTime.now()).inMilliseconds;
    if (remainingMs <= 0) {
      // Phase already elapsed; let _phaseDeadlineTimer/_onPhaseComplete run it.
      return;
    }
    final remaining = (remainingMs / 1000).ceil().clamp(1, _initialDuration);
    final progress = _progressFromRemaining(
      initialDurationSeconds: _initialDuration,
      remainingSeconds: remaining,
    );
    setState(() {
      _remainingSeconds = remaining;
      _animationController.value = progress;
    });
    _animationController.forward();
    _updateDesktopState();
  }

  bool _isWithinWorkHours() {
    if (!widget.workHoursEnabled) return true;
    final now = DateTime.now();
    final activeDays = widget.workDays
        .split(',')
        .where((e) => e.isNotEmpty)
        .map(int.parse)
        .toList();
    if (!activeDays.contains(now.weekday)) {
      return false;
    }

    final currentMinutes = now.hour * 60 + now.minute;
    final startMinutes = widget.workHoursStartHour * 60 + widget.workHoursStartMinute;
    final endMinutes = widget.workHoursEndHour * 60 + widget.workHoursEndMinute;

    if (startMinutes == endMinutes) {
      return true;
    }

    if (startMinutes < endMinutes) {
      return currentMinutes >= startMinutes && currentMinutes <= endMinutes;
    } else {
      return currentMinutes >= startMinutes || currentMinutes <= endMinutes;
    }
  }

  void _checkSchedule() {
    if (!mounted) return;

    // Check snooze expiry
    if (_snoozeEndsAt != null && DateTime.now().isAfter(_snoozeEndsAt!)) {
      _cancelSnooze();
      return;
    }

    if (!widget.workHoursEnabled) {
      if (_isSchedulePaused) {
        setState(() {
          _isSchedulePaused = false;
          if (_isRunning && !_isPaused && !_isSystemIdlePaused) {
            _phaseStartedAt = DateTime.now();
            _phaseEndsAt = _phaseStartedAt!.add(Duration(seconds: _remainingSeconds));
            _animationController.forward();
            _schedulePhaseDeadlineTimer(_phaseEndsAt!);
            unawaited(_schedulePhaseReminder(_remainingSeconds, isBreak: _isBreak));
            _startBackgroundPhase(phaseEndsAt: _phaseEndsAt!, isBreak: _isBreak);
            if (_remainingSeconds <= 5) _pulseController.forward();
          }
        });
        _updateDesktopState();
      }
      return;
    }

    final within = _isWithinWorkHours();
    if (!within) {
      if (_isRunning && !_isSchedulePaused) {
        setState(() {
          _isSchedulePaused = true;
          _animationController.stop();
          _pulseController.stop();
          _cancelPhaseDeadlineTimer();
          _phaseStartedAt = null;
          _phaseEndsAt = null;
          _saveActiveSession(isPaused: true);
          _cancelReminders();
          unawaited(_backgroundService.stopPhase());
        });
        _updateDesktopState();
      }
    } else {
      if (_isRunning && _isSchedulePaused) {
        setState(() {
          _isSchedulePaused = false;
          if (!_isPaused && !_isSystemIdlePaused) {
            _phaseStartedAt = DateTime.now();
            _phaseEndsAt = _phaseStartedAt!.add(Duration(seconds: _remainingSeconds));
            _animationController.forward();
            _schedulePhaseDeadlineTimer(_phaseEndsAt!);
            unawaited(_schedulePhaseReminder(_remainingSeconds, isBreak: _isBreak));
            _startBackgroundPhase(phaseEndsAt: _phaseEndsAt!, isBreak: _isBreak);
            if (_remainingSeconds <= 5) _pulseController.forward();
          }
        });
        _updateDesktopState();
      }
    }
  }

  void _creditNaturalBreak() {
    if (!mounted) return;
    setState(() {
      _isBreak = false;
      _isSystemIdlePaused = false;
      _isPaused = false;
      _isRunning = true;
      _phaseOpacity = 1.0;
      _initialDuration = _workDurationSeconds;
      _remainingSeconds = _workDurationSeconds;
      _animationController.duration = Duration(seconds: _workDurationSeconds);
      _animationController.reset();
      _phaseStartedAt = DateTime.now();
      _phaseEndsAt = _phaseStartedAt!.add(Duration(seconds: _workDurationSeconds));
    });

    _animationController.forward(from: 0.0);
    _saveActiveSession(remainingSeconds: _workDurationSeconds);
    _schedulePhaseDeadlineTimer(_phaseEndsAt!);
    unawaited(_schedulePhaseReminder(_workDurationSeconds, isBreak: false));
    _startBackgroundPhase(phaseEndsAt: _phaseEndsAt!, isBreak: false);
    _updateDesktopState();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Natural break detected and credited! Timer reset.'),
        duration: Duration(seconds: 4),
      ),
    );
  }

  // -------------------- Timer Logic --------------------
  void _startTimer(int duration, {bool isBreak = false}) {
    _phaseTransitionTimer?.cancel();
    _phaseTransitionTimer = null;
    _lastBlinkReminderBucket = null;
    _lastBlinkReminderAt = null;
    _cancelPhaseDeadlineTimer();
    _stopTimerCleanup(resetPulse: true);
    _cancelReminders();
    setState(() {
      _isBreak = isBreak;
      if (isBreak) {
        _activeBreakVisualizerStyle = _resolveVisualizerStyle();
      }
      _isRunning = true;
      _isPaused = false;
      _isSystemIdlePaused = false;
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
    _schedulePhaseDeadlineTimer(_phaseEndsAt!);
    unawaited(_schedulePhaseReminder(duration, isBreak: isBreak));
    _startBackgroundPhase(phaseEndsAt: _phaseEndsAt!, isBreak: isBreak);
    if (isBreak && widget.breakMode != BreakMode.off) {
      unawaited(
        widget.breakOverlayService?.showBreakOverlay(
          durationSeconds: duration,
          breakMode: widget.breakMode,
          breakVisualizerStyle: _activeBreakVisualizerStyle,
          aiQuote: _cachedAiQuote,
        ),
      );
    } else {
      unawaited(widget.breakOverlayService?.stopBreakOverlay());
      if (!isBreak) {
        unawaited(_preFetchAiQuote());
      }
    }
    _updateDesktopState();
  }

  void _startWorkTimer() {
    _autoRunCompletedCycles = 0;
    _startTimer(_workDurationSeconds);
    _updateDesktopState();
  }

  void _takeBreakNow() {
    if (_isBreak) return;
    if (_isSnoozed) {
      _snoozeEndsAt = null;
      _lastSnoozeRemaining = null;
    }
    _activeBreakVisualizerStyle = _resolveVisualizerStyle();
    _startTimer(_breakDurationSeconds, isBreak: true);
  }

  void _pauseTimerForSnooze(Duration duration) {
    _snoozeBreaks(duration);
  }

  void _pauseOrResume() {
    if (!_isRunning) return;
    setState(() {
      _isPaused = !_isPaused;
      _isSystemIdlePaused = false;
      if (_isPaused) {
        _animationController.stop();
        _pulseController.stop();
        _cancelPhaseDeadlineTimer();
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
        _schedulePhaseDeadlineTimer(_phaseEndsAt!);
        unawaited(_schedulePhaseReminder(_remainingSeconds, isBreak: _isBreak));
        _startBackgroundPhase(phaseEndsAt: _phaseEndsAt!, isBreak: _isBreak);
        if (_remainingSeconds <= 5) _pulseController.forward();
      }
    });
    _updateDesktopState();
  }

  void _snoozeBreaks(Duration duration) {
    setState(() {
      _snoozeEndsAt = DateTime.now().add(duration);
      _isRunning = true;
      _isBreak = false;
      _remainingSeconds = _workDurationSeconds;
      _initialDuration = _workDurationSeconds;
      
      _isPaused = true;
      _isSystemIdlePaused = false;
      _animationController.stop();
      _pulseController.stop();
      _cancelPhaseDeadlineTimer();
      _phaseStartedAt = null;
      _phaseEndsAt = null;
      _saveActiveSession(isPaused: true);
      _cancelReminders();
      unawaited(_backgroundService.stopPhase());
      unawaited(widget.breakOverlayService?.stopBreakOverlay());
    });
    _updateDesktopState();
  }

  void _snoozeUntilTomorrow() {
    final now = DateTime.now();
    final tomorrow = now.add(const Duration(days: 1));
    final snoozeTarget = DateTime(
      tomorrow.year,
      tomorrow.month,
      tomorrow.day,
      widget.workHoursEnabled ? widget.workHoursStartHour : 9,
      widget.workHoursEnabled ? widget.workHoursStartMinute : 0,
    );
    final duration = snoozeTarget.difference(now);
    _snoozeBreaks(duration.isNegative ? const Duration(hours: 12) : duration);
  }

  void _cancelSnooze() {
    setState(() {
      _snoozeEndsAt = null;
      _lastSnoozeRemaining = null;
      _isPaused = false;
      _isSystemIdlePaused = false;
      _phaseStartedAt = DateTime.now();
      _phaseEndsAt = _phaseStartedAt!.add(
        Duration(seconds: _remainingSeconds),
      );
      _animationController.forward();
      _saveActiveSession();
      _schedulePhaseDeadlineTimer(_phaseEndsAt!);
      unawaited(_schedulePhaseReminder(_remainingSeconds, isBreak: _isBreak));
      _startBackgroundPhase(phaseEndsAt: _phaseEndsAt!, isBreak: _isBreak);
      if (_remainingSeconds <= 5) _pulseController.forward();
    });
    _updateDesktopState();
  }

  void _cancelReminders() {
    unawaited(widget.notificationService.cancelPhaseReminder());
    unawaited(widget.notificationService.cancelPreBreakWarningReminder());
  }

  void _skipBreak() {
    if (!_isBreak || !_isRunning) return;
    _animationController.stop();
    widget.saveTimerEventRecord(TimerEventRecord(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      timestamp: DateTime.now(),
      type: TimerEventType.breakSkipped,
      durationSeconds: 0,
    ));
    _onPhaseComplete();
    _updateDesktopState();
  }

  void _postponeBreak() {
    if (!_isRunning) return;
    _animationController.stop();
    _playChime();
    _pulseController.stop();
    // Cancel the pending "Break complete" reminder that was scheduled when the
    // break started. Without this it would still fire at the original break-end
    // time and tell the user the break completed even though they postponed it.
    _cancelReminders();
    // Tear down the break overlay too, so postponing from the tray menu (which
    // doesn't go through the overlay's own dismiss path) doesn't leave the
    // fullscreen break screen up over the resumed work phase.
    unawaited(widget.breakOverlayService?.stopBreakOverlay());
    final postponeSeconds = widget.postponeDurationSeconds;
    widget.saveTimerEventRecord(TimerEventRecord(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      timestamp: DateTime.now(),
      type: TimerEventType.breakPostponed,
      durationSeconds: postponeSeconds,
    ));
    setState(() {
      _isBreak = false;
      _postponedBreakDuration = _initialDuration;
      _phaseOpacity = 1.0;
      _initialDuration = postponeSeconds;
      _remainingSeconds = _initialDuration;
      _phaseStartedAt = DateTime.now();
      _phaseEndsAt = _phaseStartedAt!.add(Duration(seconds: _initialDuration));
      _animationController.duration = Duration(seconds: _initialDuration);
      _animationController.reset();
      _animationController.forward(from: 0.0);
    });
    _startBackgroundPhase(phaseEndsAt: _phaseEndsAt!, isBreak: false);
    _saveActiveSession(remainingSeconds: _remainingSeconds);
    _schedulePhaseDeadlineTimer(_phaseEndsAt!);
    // Schedule the reminder for the new (postponed) work window so it behaves
    // like any other work phase instead of ending silently.
    unawaited(_schedulePhaseReminder(postponeSeconds, isBreak: false));
    unawaited(_preFetchAiQuote());
    _updateDesktopState();
  }

  void _cancelTimer() {
    _isCancelled = true;
    _phaseTransitionTimer?.cancel();
    _phaseTransitionTimer = null;
    _stopTimerCleanup(resetPulse: true);
    _cancelReminders();
    unawaited(_backgroundService.stopPhase());
    unawaited(widget.breakOverlayService?.stopBreakOverlay());
    if (!_isBreak) {
      final elapsed = _initialDuration - _remainingSeconds;
      if (elapsed > 0) {
        widget.saveTimerEventRecord(TimerEventRecord(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          timestamp: DateTime.now(),
          type: TimerEventType.workCancelled,
          durationSeconds: elapsed,
        ));
      }
    }
    setState(() {
      _isRunning = false;
      _isPaused = false;
      _isBreak = false;
      _isSystemIdlePaused = false;
      _snoozeEndsAt = null;
      _lastSnoozeRemaining = null;
      _phaseOpacity = 1.0;
      _phaseStartedAt = null;
      _phaseEndsAt = null;
      _autoRunCompletedCycles = 0;
      _initialDuration = _workDurationSeconds;
      _remainingSeconds = _initialDuration;
      _animationController.reset();
    });
    widget.clearSession();
    _updateDesktopState();
  }

  void _stopTimerCleanup({bool resetPulse = false}) {
    _animationController.stop();
    _pulseController.stop();
    _cancelPhaseDeadlineTimer();
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
      final pendingEvents = bgSession['pendingEvents'] as List<dynamic>?;
      final bgPostponedBreakDuration = bgSession['postponedBreakDuration'] as int?;
      if (pendingEvents != null) {
        bool hasNaturalBreak = false;
        for (final event in pendingEvents) {
          if (event is Map<dynamic, dynamic>) {
            final typeStr = event['type'] as String;
            final timestamp = event['timestamp'] as int;
            final durationSeconds = event['durationSeconds'] as int;
            if (typeStr == 'naturalBreakCredited') {
              hasNaturalBreak = true;
              continue;
            }
            final type = TimerEventType.values.firstWhere(
              (e) => e.name == typeStr,
              orElse: () => TimerEventType.workCompleted,
            );
            widget.saveTimerEventRecord(TimerEventRecord(
              id: timestamp.toString(),
              timestamp: DateTime.fromMillisecondsSinceEpoch(timestamp),
              type: type,
              durationSeconds: durationSeconds,
            ));
          }
        }
        if (hasNaturalBreak) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Natural break detected while away! Timer reset.'),
                duration: Duration(seconds: 4),
              ),
            );
          });
        }
      }

      setState(() {
        _isBreak = bgIsBreak;
        _streakCount = bgStreakCount;
        _autoRunCompletedCycles = bgCompletedAutoRunCycles;
        _phaseEndsAt = DateTime.fromMillisecondsSinceEpoch(bgEndsAtMillis);
        _postponedBreakDuration = bgPostponedBreakDuration;

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
      postponedBreakDuration: _postponedBreakDuration,
    );
    _applyProjection(
      projection,
      persist: true,
      scheduleReminder: projection.boundariesCrossed > 0,
      playChime: true,
    );
  }

  void _onPhaseComplete() {
    if (!_isRunning || _phaseEndsAt == null || _isCancelled || !mounted) {
      return;
    }

    _cancelPhaseDeadlineTimer();

    final completedBreakPhase = _isBreak;
    final completedPhaseAt = _phaseEndsAt!;
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
        unawaited(widget.breakOverlayService?.stopBreakOverlay());
        widget.clearSession();
        _updateDesktopState();
        return;
      }

      final upcomingBreakDuration = _postponedBreakDuration ?? _breakDurationForCompletedCycle(_streakCount + 1);
      final isPostponed = _postponedBreakDuration != null;

      setState(() {
        _postponedBreakDuration = null;
        if (!isPostponed) {
          _streakCount = _streakCount + 1;
          _autoRunCompletedCycles++;
        }
      });

      if (!isPostponed) {
        widget.saveStreakCount(_streakCount);
        widget.saveCompletedWorkSession(completedPhaseAt, _initialDuration);
        widget.saveTimerEventRecord(TimerEventRecord(
          id: completedPhaseAt.millisecondsSinceEpoch.toString(),
          timestamp: completedPhaseAt,
          type: TimerEventType.workCompleted,
          durationSeconds: _initialDuration,
        ));
      }

      _startTimer(
        upcomingBreakDuration,
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
        postponedBreakDuration: _postponedBreakDuration,
      ),
    );
  }

  bool _isNextBreakLong() {
    if (_postponedBreakDuration != null) {
      return _postponedBreakDuration == _longBreakDurationSeconds;
    }
    if (!_longBreakEnabled || _longBreakEveryCycles <= 0) return false;
    return (_streakCount + 1) % _longBreakEveryCycles == 0;
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
      final nextIsLong = _isNextBreakLong();
      if (durationSeconds > 10) {
        unawaited(
          widget.notificationService.schedulePreBreakWarningReminder(
            Duration(seconds: durationSeconds - 10),
            isLongBreak: nextIsLong,
          ),
        );
      }
      return widget.notificationService.scheduleWorkCompleteReminder(
        delay,
        isLongBreak: nextIsLong,
      );
    }
  }

  Future<void> _playChime() async {
    if (widget.hapticsEnabled) {
      unawaited(HapticFeedback.lightImpact());
    }
    if (widget.soundEnabled) {
      if (widget.chimeStyle == 'system_alert') {
        unawaited(SystemSound.play(SystemSoundType.alert));
      } else {
        try {
          await _audioPlayer?.stop();
          unawaited(_audioPlayer!.play(AssetSource('sounds/${widget.chimeStyle}.wav')));
        } catch (e) {
          unawaited(SystemSound.play(SystemSoundType.alert));
        }
      }
    }
  }

  void _triggerBlinkNudge() {
    // Guard: never nudge during breaks, snoozed state, or when not running.
    if (!_isRunning ||
        _isBreak ||
        _isPaused ||
        _isSnoozed ||
        _isSchedulePaused ||
        _isSystemIdlePaused) {
      return;
    }

    final cadence = widget.blinkRemindersCadenceSeconds;
    if (cadence <= 0) return;

    final elapsed = _initialDuration - _remainingSeconds;
    if (elapsed <= 0) return;

    final bucket = elapsed ~/ cadence;
    final now = DateTime.now();
    final lastAt = _lastBlinkReminderAt;
    if (_lastBlinkReminderBucket == bucket ||
        (lastAt != null && now.difference(lastAt).inSeconds < cadence - 1)) {
      return;
    }
    _lastBlinkReminderBucket = bucket;
    _lastBlinkReminderAt = now;

    if (widget.hapticsEnabled) {
      unawaited(HapticFeedback.selectionClick());
    }

    // Determine the notification message:
    // 1. Custom message (user-typed) takes highest priority
    // 2. AI pre-fetched message (if AI enabled and configured)
    // 3. Built-in rotating fallback
    final String? customMsg = widget.blinkReminderCustomMessage.isNotEmpty
        ? widget.blinkReminderCustomMessage
        : null;

    if (customMsg != null) {
      unawaited(widget.notificationService.showBlinkReminder(customMessage: customMsg));
    } else if (_blinkMessageFuture != null) {
      final future = _blinkMessageFuture!;
      _blinkMessageFuture = null;
      future.then((msg) {
        if (mounted) {
          unawaited(
            widget.notificationService.showBlinkReminder(
              customMessage: (msg != null && msg.isNotEmpty) ? msg : null,
            ),
          );
        }
      }).catchError((_) {
        if (mounted) unawaited(widget.notificationService.showBlinkReminder());
      });
    } else {
      // No AI message ready, send with built-in rotating message
      unawaited(widget.notificationService.showBlinkReminder());
    }

    setState(() {
      _isBlinkNudging = true;
    });
    _updateDesktopState();

    Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _isBlinkNudging = false;
        });
        _updateDesktopState();
      }
    });
  }

  bool get _canChangeSettings => !_isRunning;

  LinearGradient _backgroundGradientFromPreset(String preset, bool isDark) {
    return ColorPresets.backgroundGradient(preset, isDark, customHex: widget.customAccentColorHex);
  }

  bool get _isSnoozed => _snoozeEndsAt != null && DateTime.now().isBefore(_snoozeEndsAt!);

  /// Returns true if a camera device is currently in active use (Linux only).
  // ignore: unused_element
  Future<bool> _isCameraOrMicInUse() async {
    if (kIsWeb || !Platform.isLinux) return false;
    try {
      final result = await Process.run(
        'bash',
        ['-c', 'fuser /dev/video* 2>/dev/null | grep -q . && echo yes || echo no'],
      ).timeout(const Duration(seconds: 2));
      return (result.stdout as String).trim() == 'yes';
    } catch (_) {
      return false;
    }
  }

  String get _statusLabel {
    if (_isSnoozed) {
      return 'Snoozed';
    }
    if (_isSchedulePaused) {
      return 'Schedule Paused';
    }
    if (!_isRunning) {
      return 'Idle';
    }
    if (_isPaused) {
      return 'Paused';
    }
    if (_isSystemIdlePaused) {
      return 'Idle Paused';
    }
    return _isBreak ? 'Break' : 'Work';
  }

  String get _phaseTitle {
    if (_isSnoozed) {
      final diff = _snoozeEndsAt!.difference(DateTime.now());
      final mins = (diff.inSeconds / 60).ceil();
      return 'Breaks snoozed ($mins min left)';
    }
    if (_isSchedulePaused) {
      return 'Timer paused by schedule';
    }
    if (!_isRunning) {
      return 'Ready for your next focus session';
    }
    if (_isPaused) {
      return _isBreak ? 'Break paused' : 'Work paused';
    }
    if (_isSystemIdlePaused) {
      return _isBreak ? 'Break paused' : 'Work paused (Idle)';
    }
    return _isBreak
        ? 'Break Time - look 20 ft away'
        : 'Work Time - focus on your task';
  }

  String get _phaseSubtitle {
    if (_isSchedulePaused) {
      return 'Outside active work hours or days.';
    }
    if (!_isRunning) {
      return 'Start when your eyes and task are ready.';
    }
    if (_isPaused) {
      return 'Resume when you are ready to continue.';
    }
    if (_isSystemIdlePaused) {
      return 'Paused automatically because you were away.';
    }
    return _isBreak
        ? 'Relax your focus and blink naturally.'
        : 'A reminder will help you take the next eye break.';
  }

  IconData get _statusIcon {
    if (_isSchedulePaused) {
      return Icons.calendar_today_outlined;
    }
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
      customHex: widget.customAccentColorHex,
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

  EyeHealthTip get _currentEducationTip =>
      EyeHealthTips.at(_educationTipIndex);

  EyeHealthTip get _currentBreakTip => EyeHealthTips.breakTipForRemaining(
        remainingSeconds: _remainingSeconds,
        totalDurationSeconds: _initialDuration,
        offset: _educationTipIndex,
      );

  String _durationLabel(int seconds) {
    if (seconds < 60) {
      return '$seconds s';
    }
    final minutes = seconds ~/ 60;
    return '$minutes min';
  }

  Widget _buildTodayBreakSummary(ThemeData theme, Color accentColor) {
    final goalReached = widget.dailyGoal > 0 && _streakCount >= widget.dailyGoal;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: accentColor.withValues(alpha: 0.24)),
      ),
      child: Row(
        children: [
          Icon(
            goalReached ? Icons.emoji_events_outlined : Icons.visibility_outlined,
            color: accentColor,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Breaks taken today',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$_streakCount / ${widget.dailyGoal} breaks',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          Text(
            goalReached ? 'Goal met' : 'Keep going',
            style: theme.textTheme.labelLarge?.copyWith(
              color: accentColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHomeQuickActions(ThemeData theme, bool isDark, Color accentColor) {
    final canTakeBreak = !_isBreak && !_isSchedulePaused;
    final foreground = accentColor.computeLuminance() > 0.45
        ? Colors.black87
        : Colors.white;
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 10,
      runSpacing: 8,
      children: [
        FilledButton.icon(
          onPressed: canTakeBreak ? _takeBreakNow : null,
          icon: const Icon(Icons.visibility_outlined),
          label: const Text('Take break now'),
          style: FilledButton.styleFrom(
            backgroundColor: accentColor,
            foregroundColor: foreground,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        if (_isSnoozed)
          OutlinedButton.icon(
            onPressed: _cancelSnooze,
            icon: const Icon(Icons.notifications_active_outlined),
            label: const Text('Cancel snooze'),
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          )
        else ...[
          OutlinedButton.icon(
            onPressed: _isBreak ? null : () => _pauseTimerForSnooze(const Duration(hours: 1)),
            icon: const Icon(Icons.snooze_outlined),
            label: const Text('Snooze 1h'),
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          OutlinedButton.icon(
            onPressed: _isBreak ? null : _snoozeUntilTomorrow,
            icon: const Icon(Icons.nights_stay_outlined),
            label: const Text('Tomorrow'),
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildLearnCard(ThemeData theme, bool isDark, Color accentColor) {
    final tip = _currentEducationTip;
    final surfaceColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.white.withValues(alpha: 0.72);
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.10)
        : Colors.black.withValues(alpha: 0.08);

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      child: Container(
        key: ValueKey(tip.title),
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.school_outlined, color: accentColor, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tip.title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(tip.detail, style: theme.textTheme.bodySmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAiInsightCard(ThemeData theme, bool isDark, Color accentColor) {
    if (!widget.aiMotivationEnabled) return const SizedBox.shrink();

    final surfaceColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.white.withValues(alpha: 0.72);
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.10)
        : Colors.black.withValues(alpha: 0.08);

    Widget content;
    if (_isAiInsightLoading) {
      content = Row(
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(accentColor),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Analyzing habits & preparing custom tip...',
            style: theme.textTheme.bodySmall?.copyWith(
              color: isDark ? Colors.white60 : Colors.black54,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      );
    } else if (_aiInsightError != null) {
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _aiInsightError!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: _fetchAiHealthInsight,
            borderRadius: BorderRadius.circular(4),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.refresh, size: 14, color: accentColor),
                  const SizedBox(width: 4),
                  Text(
                    'Retry',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: accentColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    } else if (_aiHealthInsight != null) {
      content = Text(
        _aiHealthInsight!,
        style: theme.textTheme.bodySmall,
      );
    } else {
      // Not loaded yet and not loading (e.g. if key was empty or request not made)
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'No insight loaded yet.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: isDark ? Colors.white60 : Colors.black54,
            ),
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: _fetchAiHealthInsight,
            borderRadius: BorderRadius.circular(4),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.refresh, size: 14, color: accentColor),
                  const SizedBox(width: 4),
                  Text(
                    'Generate tip',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: accentColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      child: Container(
        key: ValueKey('ai_insight_${_isAiInsightLoading}_${_aiInsightError != null}_${_aiHealthInsight?.hashCode}'),
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.auto_awesome, color: accentColor, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'AI Health Insight',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (!_isAiInsightLoading && _aiHealthInsight != null)
                        IconButton(
                          icon: const Icon(Icons.refresh, size: 16),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: _fetchAiHealthInsight,
                          tooltip: 'Regenerate Insight',
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  content,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBreakTipPanel(ThemeData theme, bool isDark, Color accentColor) {
    return AnimatedBuilder(
      animation: _progressAnimation,
      builder: (context, _) {
        final tip = _currentBreakTip;
        final message = widget.breakCustomMessage.trim().isNotEmpty
            ? widget.breakCustomMessage.trim()
            : tip.action;
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: Column(
            key: ValueKey(tip.title),
            children: [
              Text(
                message,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: accentColor,
                  fontWeight: FontWeight.w700,
                  height: 1.35,
                ),
              ),
              if (widget.breakShowTips) ...[
                const SizedBox(height: 4),
                Text(
                tip.detail,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isDark ? Colors.white70 : Colors.black54,
                  height: 1.4,
                ),
              ),
              ],
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark || _isFocusMode;
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

    final systemOverlayStyle = SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
    );

    final theme = Theme.of(context);
    final effectiveTheme = _isFocusMode
        ? ThemeData.dark().copyWith(
            colorScheme: ColorScheme.dark(
              primary: ColorPresets.swatchColor(widget.colorPreset, true, customHex: widget.customAccentColorHex),
            ),
          )
        : theme;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: systemOverlayStyle,
      child: Theme(
        data: effectiveTheme,
        child: Scaffold(
          extendBodyBehindAppBar: true,
          appBar: _isFocusMode
              ? null
              : AppBar(
                  title: const Text('BlinkKind'),
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  systemOverlayStyle: systemOverlayStyle,
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
          RepaintBoundary(
            child: Container(
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

                      final timerDial = _AnimatedTimerDial(
                        size: size,
                        progressAnimation: _progressAnimation,
                        pulseAnimation: _pulseAnimation,
                        initialDuration: _initialDuration,
                        statusLabel: _statusLabel,
                        textColor: textColor,
                        ringBackgroundColor: ringBgColor,
                        progressColor: progressColor,
                        strokeWidth: _ringStrokeWidth,
                        isLandscape: isLandscape,
                        onTap: _toggleFocusMode,
                        blinkRemindersEnabled: widget.blinkRemindersEnabled,
                        isBlinkNudging: _isBlinkNudging,
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
                                              if (_isBreak &&
                                                  _isRunning &&
                                                  !_isPaused &&
                                                  (widget.breakShowTips ||
                                                      widget.breakCustomMessage.trim().isNotEmpty)) ...[
                                                const SizedBox(height: 10),
                                                _buildBreakTipPanel(
                                                  Theme.of(context),
                                                  isDark,
                                                  progressColor,
                                                ),
                                              ],
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
                                        const SizedBox(height: 12),
                                        _buildTodayBreakSummary(
                                          Theme.of(context),
                                          progressColor,
                                        ),
                                        const SizedBox(height: 12),
                                        _buildHomeQuickActions(
                                          Theme.of(context),
                                          isDark,
                                          progressColor,
                                        ),
                                        const SizedBox(height: 12),
                                        _buildLearnCard(
                                          Theme.of(context),
                                          isDark,
                                          progressColor,
                                        ),
                                        if (widget.aiMotivationEnabled) ...[
                                          const SizedBox(height: 12),
                                          _buildAiInsightCard(
                                            Theme.of(context),
                                            isDark,
                                            progressColor,
                                          ),
                                        ],
                                      ] else ...[
                                        Opacity(
                                          opacity: 0.35,
                                          child: Text(
                                            'Tap dial to exit focus mode',
                                            style: Theme.of(
                                              context,
                                            ).textTheme.bodySmall?.copyWith(
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
                                        borderRadius: BorderRadius.circular(
                                          999,
                                        ),
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
                                            style: Theme.of(
                                              context,
                                            ).textTheme.labelLarge?.copyWith(
                                              fontWeight: FontWeight.w600,
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
                                    if (_isBreak &&
                                        _isRunning &&
                                        !_isPaused &&
                                        (widget.breakShowTips ||
                                            widget.breakCustomMessage.trim().isNotEmpty)) ...[
                                      const SizedBox(height: 10),
                                      _buildBreakTipPanel(
                                        Theme.of(context),
                                        isDark,
                                        progressColor,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],
                            timerDial,
                            // Guided break modes: show the interactive guide
                            // below the dial when on break.
                            if (_isBreak &&
                                _isRunning &&
                                !_isPaused) ...[
                              if (_activeBreakVisualizerStyle ==
                                      'EyeExercise' ||
                                  _activeBreakVisualizerStyle ==
                                      'BoxBreathing' ||
                                  _activeBreakVisualizerStyle ==
                                      'BlinkTraining') ...[
                                const SizedBox(height: 16),
                                ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    maxWidth: 280,
                                    maxHeight: 280,
                                  ),
                                  child: _activeBreakVisualizerStyle ==
                                          'EyeExercise'
                                      ? EyeExerciseDotGuide(
                                          remainingSeconds: _remainingSeconds,
                                          totalDurationSeconds:
                                              _initialDuration,
                                        )
                                      : _activeBreakVisualizerStyle ==
                                              'BoxBreathing'
                                          ? BoxBreathingGuide(
                                              remainingSeconds: _remainingSeconds,
                                              totalDurationSeconds:
                                                  _initialDuration,
                                            )
                                          : BlinkTrainingGuide(
                                              remainingSeconds: _remainingSeconds,
                                              totalDurationSeconds:
                                                  _initialDuration,
                                            ),
                                ),
                              ],
                            ],
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
                              const SizedBox(height: 12),
                              _buildTodayBreakSummary(
                                Theme.of(context),
                                progressColor,
                              ),
                              const SizedBox(height: 12),
                              _buildHomeQuickActions(
                                Theme.of(context),
                                isDark,
                                progressColor,
                              ),
                              const SizedBox(height: 12),
                              _buildLearnCard(
                                Theme.of(context),
                                isDark,
                                progressColor,
                              ),
                              if (widget.aiMotivationEnabled) ...[
                                const SizedBox(height: 12),
                                _buildAiInsightCard(
                                  Theme.of(context),
                                  isDark,
                                  progressColor,
                                ),
                              ],
                            ] else ...[
                              Opacity(
                                opacity: 0.35,
                                child: Text(
                                  'Tap dial to exit focus mode',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.bodySmall?.copyWith(
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
          ),

        ],
      ),
    ),
  ),
);
  }

  void _updateOsFocusDnd() {
    final shouldBeEnabled = widget.osFocusDndEnabled &&
        _isRunning &&
        !_isPaused &&
        !_isBreak &&
        !_isSchedulePaused &&
        !_isSystemIdlePaused;
    if (shouldBeEnabled != _lastDndState) {
      _lastDndState = shouldBeEnabled;
      unawaited(OsFocusService.instance.setDndEnabled(shouldBeEnabled));
    }
  }

  void _updateDesktopState() {
    _updateOsFocusDnd();
    if (kIsWeb) return;
    if (defaultTargetPlatform == TargetPlatform.linux ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.windows) {
      final now = DateTime.now();
      final snoozeEnds = _snoozeEndsAt;
      final isSnoozed = snoozeEnds != null && now.isBefore(snoozeEnds);
      final snoozeRemaining = isSnoozed ? (snoozeEnds.difference(now).inSeconds / 60).ceil() : 0;
      
      DateTime? nextBreakVal;
      if (_isRunning && !_isBreak && !_isPaused && !_isSystemIdlePaused && !isSnoozed) {
        nextBreakVal = _phaseEndsAt;
      }

      DesktopControlsController.instance.updateState(
        DesktopTimerState(
          isRunning: _isRunning,
          isPaused: _isPaused || _isSystemIdlePaused,
          isBreak: _isBreak,
          remainingSeconds: _remainingSeconds,
          allowPostpone: widget.allowPostpone,
          postponeDurationMinutes: widget.postponeDurationSeconds ~/ 60,
          initialDurationSeconds: _initialDuration,
          isBlinkNudging: _isBlinkNudging,
          isSnoozed: isSnoozed,
          snoozeRemainingMinutes: snoozeRemaining,
          nextBreakAt: nextBreakVal,
          isLongBreak: _isBreak && _longBreakEnabled && _initialDuration == _longBreakDurationSeconds,
        ),
      );
    }
  }
}

class _AnimatedTimerDial extends StatelessWidget {
  final double size;
  final Animation<double> progressAnimation;
  final Animation<double> pulseAnimation;
  final int initialDuration;
  final String statusLabel;
  final Color textColor;
  final Color ringBackgroundColor;
  final Color progressColor;
  final double strokeWidth;
  final bool isLandscape;
  final VoidCallback onTap;
  final bool blinkRemindersEnabled;
  final bool isBlinkNudging;

  const _AnimatedTimerDial({
    required this.size,
    required this.progressAnimation,
    required this.pulseAnimation,
    required this.initialDuration,
    required this.statusLabel,
    required this.textColor,
    required this.ringBackgroundColor,
    required this.progressColor,
    required this.strokeWidth,
    required this.isLandscape,
    required this.onTap,
    required this.blinkRemindersEnabled,
    required this.isBlinkNudging,
  });

  String _formattedTime(int seconds) {
    if (seconds < 60) return seconds.toString();
    final minutes = seconds ~/ 60;
    final remainder = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainder.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final dialSize = size * 0.92;
    return RepaintBoundary(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: ScaleTransition(
          scale: pulseAnimation,
          child: SizedBox(
            width: size,
            height: size,
            child: AnimatedBuilder(
              animation: progressAnimation,
              child: SizedBox(
                width: dialSize,
                height: dialSize,
                child: CircularProgressIndicator(
                  value: 1.0,
                  strokeWidth: strokeWidth,
                  color: ringBackgroundColor,
                ),
              ),
              builder: (context, backgroundRing) {
                final remainingSeconds =
                    (initialDuration * progressAnimation.value).ceil();
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    backgroundRing!,
                    SizedBox(
                      width: dialSize,
                      height: dialSize,
                      child: CircularProgressIndicator(
                        value: progressAnimation.value,
                        strokeWidth: strokeWidth,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          progressColor,
                        ),
                        backgroundColor: Colors.transparent,
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (blinkRemindersEnabled) ...[
                          AnimatedCrossFade(
                            firstChild: Icon(
                              Icons.remove_red_eye_outlined,
                              size: 18,
                              color: textColor.withValues(alpha: 0.5),
                            ),
                            secondChild: Icon(
                              Icons.remove_red_eye,
                              size: 18,
                              color: progressColor,
                            ),
                            crossFadeState: isBlinkNudging
                                ? CrossFadeState.showSecond
                                : CrossFadeState.showFirst,
                            duration: const Duration(milliseconds: 100),
                          ),
                          const SizedBox(height: 6),
                        ],
                        Text(
                          _formattedTime(remainingSeconds),
                          style: Theme.of(context).textTheme.displaySmall?.copyWith(
                            fontSize: isLandscape ? 28 : null,
                            fontWeight: FontWeight.w300,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          statusLabel,
                          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: textColor.withValues(alpha: 0.65),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
