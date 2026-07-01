import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:system_idle/system_idle.dart';
import 'package:window_manager/window_manager.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

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
import '../../generated/l10n/app_localizations.dart';
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
  final void Function(BuildContext context) openHistory;
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
  final int maxConsecutiveSkips;
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
  final bool trayBlinkNudgesEnabled;
  final int trayBlinkNudgeCadenceSeconds;
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
  final bool blinkReminderAiEnabled;
  final String blinkReminderCustomMessage;
  final bool cameraMicAutoPostponeEnabled;
  final bool wellnessRemindersEnabled;
  final int wellnessReminderCadenceSeconds;
  final bool blinkReminderInteractiveEnabled;
  final bool autoPauseOnMediaEnabled;
  final String autoPostponeApps;
  final bool reducedMotionEnabled;
  final Future<bool> Function()? isCameraInUseOverride;
  final Future<bool> Function()? isMicInUseOverride;
  final bool showBatteryWarning;
  final String oemManufacturer;
  final VoidCallback onDismissBatteryWarning;
  final VoidCallback onFixBatteryRestriction;
  final bool showNotificationWarning;
  final VoidCallback onFixNotificationPermission;

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
    required this.reducedMotionEnabled,
    required this.smartIdleEnabled,
    required this.breakVisualizerStyle,
    required this.breakShowClock,
    required this.breakShowTips,
    required this.breakShowProgress,
    required this.breakCustomMessage,
    required this.chimeStyle,
    required this.blinkRemindersEnabled,
    required this.blinkRemindersCadenceSeconds,
    required this.trayBlinkNudgesEnabled,
    required this.trayBlinkNudgeCadenceSeconds,
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
    required this.blinkReminderAiEnabled,
    required this.blinkReminderCustomMessage,
    required this.cameraMicAutoPostponeEnabled,
    required this.wellnessRemindersEnabled,
    required this.wellnessReminderCadenceSeconds,
    required this.blinkReminderInteractiveEnabled,
    required this.autoPauseOnMediaEnabled,
    required this.autoPostponeApps,
    this.isCameraInUseOverride,
    this.isMicInUseOverride,
    this.breakOverlayService,
    required this.openSettings,
    required this.openHistory,
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
    required this.maxConsecutiveSkips,
    required this.showBatteryWarning,
    required this.oemManufacturer,
    required this.onDismissBatteryWarning,
    required this.onFixBatteryRestriction,
    required this.showNotificationWarning,
    required this.onFixNotificationPermission,
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
  bool _isMediaPaused = false;
  Timer? _mediaPollTimer;
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
        _aiInsightError =
            'API key is missing. Please configure it in Settings.';
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
      final prompt =
          'Generate a single, unique, practical, and highly engaging desk wellness tip (strict limit of 30 words) for a developer working at a computer. Focus specifically on $randomFocus. Make it highly specific, actionable, and encouraging. [Seed: $seed]';

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
    } catch (e, stackTrace) {
      unawaited(Sentry.captureException(e, stackTrace: stackTrace));
      setState(() {
        _aiInsightError =
            'Failed to fetch AI tip. Make sure your API key and connection are valid.';
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

  // Transition flash animation
  late AnimationController _flashController;
  late Animation<double> _flashAnimation;
  Color _flashColor = Colors.white;

  // Streak milestone celebration
  bool _showConfetti = false;

  // Phase text fade.
  double _phaseOpacity = 1.0;
  bool _isBlinkNudging = false;
  Future<String?>? _blinkMessageFuture;
  int? _lastBlinkReminderBucket;
  DateTime? _lastBlinkReminderAt;
  int? _lastTrayBlinkNudgeBucket;
  DateTime? _lastTrayBlinkNudgeAt;
  DateTime? _lastAnimationTickAt;
  int _wellnessTypeIndex = 0;
  int _wellnessAccumulator = 0;
  Timer? _phaseTransitionTimer;
  Timer? _phaseDeadlineTimer;
  // Wall-clock 1Hz ticker (desktop only) that keeps the tray/app-indicator
  // countdown live even while the main window is hidden — the in-window
  // animation that normally drives the tray is frozen while the window isn't
  // rendering.
  Timer? _desktopTrayTicker;
  Timer? _educationTipTimer;
  int _educationTipIndex = 0;
  int _consecutiveSkips = 0;
  // Tip frozen at break start — stays the same for the whole break so the
  // message never changes mid-break and no extra LLM calls are triggered.
  EyeHealthTip? _frozenBreakTip;
  DateTime? _phaseStartedAt;
  DateTime? _phaseEndsAt;
  late String _currentDateKey;

  late final TimerBackgroundService _backgroundService;
  StreamSubscription<DesktopCommand>? _desktopCommandSubscription;
  StreamSubscription<bool>? _desktopIdleSubscription;
  StreamSubscription<bool>? _desktopLockSubscription;

  AudioPlayer? _audioPlayer;
  Process? _activeChimeProcess;

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
    _currentDateKey = _todayKey();
    _initialDuration = _workDurationSeconds;
    _remainingSeconds = _initialDuration;
    _activeBreakVisualizerStyle = widget.breakVisualizerStyle;
    _educationTipIndex = DateTime.now().minute % EyeHealthTips.all.length;
    _educationTipTimer = Timer.periodic(const Duration(seconds: 45), (_) {
      if (!mounted || _isFocusMode) return;
      setState(() {
        _educationTipIndex =
            (_educationTipIndex + 1) % EyeHealthTips.all.length;
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
            _lastAnimationTickAt = DateTime.now();
            // Update remaining seconds and pulse trigger.
            final elapsedSeconds =
                (_animationController.value * _initialDuration).round();
            final nextRemaining = _initialDuration - elapsedSeconds;
            if (nextRemaining != _remainingSeconds) {
              final delta = _remainingSeconds - nextRemaining;
              _remainingSeconds = nextRemaining;
              setState(() {});
              
              if (_remainingSeconds <= 5 &&
                  !_pulseController.isAnimating &&
                  _isRunning) {
                _pulseController.forward();
              }
              _processBlinkReminderCadences();
              _processWellnessReminders(delta);
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
    if (widget.reducedMotionEnabled) {
      _pulseAnimation = const AlwaysStoppedAnimation(1.0);
    } else {
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

    // Transition flash animation setup
    _flashController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    if (widget.reducedMotionEnabled) {
      _flashAnimation = const AlwaysStoppedAnimation(0.0);
    } else {
      _flashAnimation = TweenSequence<double>([
        TweenSequenceItem(
          tween: Tween<double>(begin: 0.0, end: 0.55)
              .chain(CurveTween(curve: Curves.easeIn)),
          weight: 35,
        ),
        TweenSequenceItem(
          tween: Tween<double>(begin: 0.55, end: 0.0)
              .chain(CurveTween(curve: Curves.easeOut)),
          weight: 65,
        ),
      ]).animate(_flashController);
    }

    _restoreInitialSession();
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      unawaited(_syncTimerWithClock());
    }
    if (!kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.linux ||
            defaultTargetPlatform == TargetPlatform.macOS ||
            defaultTargetPlatform == TargetPlatform.windows)) {
      _initDesktopIdleDetection();
      _desktopTrayTicker = Timer.periodic(
        const Duration(seconds: 1),
        (_) => _onDesktopTrayTick(),
      );
      _updateDesktopState();
    }

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
            case DesktopCommand.playChime:
              // Play the confirmation chime when the user taps the
              // "I blinked!" notification action button.
              unawaited(_playChime(hapticEvent: 'blink_reminder'));
              break;
          }
        });
    _scheduleCheckTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _checkSchedule();
    });
    _checkSchedule();

    // Media playback auto-pause poll (every 5 seconds, Android & Linux only)
    if (widget.autoPauseOnMediaEnabled) {
      _mediaPollTimer = Timer.periodic(const Duration(seconds: 5), (_) {
        _checkMediaPlayback();
      });
    }

    if (widget.aiMotivationEnabled) {
      scheduleMicrotask(() {
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
      final snoozeRemaining = (_snoozeEndsAt!.difference(now).inSeconds / 60)
          .ceil();
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
      final lastTick = _lastAnimationTickAt;
      final isAnimationTicking = lastTick != null &&
          DateTime.now().difference(lastTick).inMilliseconds < 200;
      if (!isAnimationTicking || (clamped - _remainingSeconds).abs() > 1) {
        final delta = _remainingSeconds - clamped;
        _remainingSeconds = clamped;
        setState(() {});
        
        _processBlinkReminderCadences();
        _processWellnessReminders(delta);
        _updateDesktopState();
      }
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
    // Dynamically start or stop the media poll timer when the setting changes.
    if (oldWidget.autoPauseOnMediaEnabled != widget.autoPauseOnMediaEnabled) {
      if (widget.autoPauseOnMediaEnabled) {
        _mediaPollTimer ??= Timer.periodic(const Duration(seconds: 5), (_) {
          _checkMediaPlayback();
        });
      } else {
        _mediaPollTimer?.cancel();
        _mediaPollTimer = null;
        // Clear any active media pause so the timer resumes.
        if (_isMediaPaused) {
          setState(() {
            _isMediaPaused = false;
            if (_isRunning && !_isPaused) {
              _phaseStartedAt = DateTime.now();
              _phaseEndsAt = _phaseStartedAt!.add(
                Duration(seconds: _remainingSeconds),
              );
              _animationController.forward();
              _schedulePhaseDeadlineTimer(_phaseEndsAt!);
              _startBackgroundPhase(phaseEndsAt: _phaseEndsAt!, isBreak: _isBreak);
            }
          });
          _updateDesktopState();
        }
      }
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
    _activeChimeProcess?.kill();
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
    _mediaPollTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _phaseTransitionTimer?.cancel();
    _cancelPhaseDeadlineTimer();
    _animationController.dispose();
    _pulseController.dispose();
    _flashController.dispose();
    super.dispose();
  }

  void _toggleFocusMode() {
    setState(() {
      _isFocusMode = !_isFocusMode;
    });
    unawaited(_systemUiService.setFocusModeEnabled(_isFocusMode));
  }

  /// Polls whether background media (music / video) is playing.
  /// On Android uses [AudioManager.isMusicActive] via MethodChannel.
  /// On Linux uses `pactl list sink-inputs` to check for un-corked streams.
  Future<void> _checkMediaPlayback() async {
    if (!mounted || !_isRunning) return;
    if (!widget.autoPauseOnMediaEnabled) return;

    final overlayService = widget.breakOverlayService;
    if (overlayService == null) return;

    final isPlaying = await overlayService.isMediaPlaying();

    if (!mounted) return;

    if (isPlaying && !_isPaused && !_isMediaPaused && !_isSystemIdlePaused) {
      // Media just started → auto-pause
      setState(() {
        _isMediaPaused = true;
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
    } else if (!isPlaying && _isMediaPaused) {
      // Media stopped → auto-resume
      setState(() {
        _isMediaPaused = false;
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
      _desktopLockSubscription = DesktopIntegrationService
          .instance
          .onSystemLockChanged
          .listen((isLocked) {
            if (!mounted) return;
            handleDesktopIdleChange(isLocked, isLockEvent: true);
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
                handleDesktopIdleChange(isIdle, isLockEvent: false);
              });
        }
      }());
    } catch (e, stackTrace) {
      unawaited(Sentry.captureException(e, stackTrace: stackTrace));
      debugPrint('Failed to initialize desktop idle detection: $e');
    }
  }

  void handleDesktopIdleChange(bool isIdle, {bool isLockEvent = false}) {
    if (!widget.smartIdleEnabled) return;
    if (!_isRunning || _isBreak) return;

    if (isIdle) {
      if (!_isPaused && !_isSystemIdlePaused) {
        setState(() {
          // If this is a regular idle event (not screen lock), the user has already
          // been idle for 60 seconds (the system idle detection threshold). We subtract
          // those 60 seconds to accurately measure the total duration of the user's away time.
          _idleStartedAt = isLockEvent
              ? DateTime.now()
              : DateTime.now().subtract(const Duration(seconds: 60));
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
          unawaited(
            _schedulePhaseReminder(_remainingSeconds, isBreak: _isBreak),
          );
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
        scheduleMicrotask(() {
          if (mounted && !_isRunning) {
            _startTimer(_workDurationSeconds);
            _checkSchedule();
          }
        });
      }
      return;
    }

    final phaseStartedAt = session.phaseStartedAt;
    final phaseEndsAt = session.phaseEndsAt;
    final sessionTime = phaseStartedAt ?? phaseEndsAt;
    if (sessionTime != null) {
      final now = DateTime.now();
      final isSameDay = sessionTime.year == now.year &&
          sessionTime.month == now.month &&
          sessionTime.day == now.day;
      if (!isSameDay) {
        scheduleMicrotask(() {
          if (mounted) {
            widget.clearSession();
          }
        });
        if (widget.autoStartSchedule) {
          scheduleMicrotask(() {
            if (mounted && !_isRunning) {
              _startTimer(_workDurationSeconds);
              _checkSchedule();
            }
          });
        }
        return;
      }
    }

    if (session.isPaused) {
      _restorePausedSession(session);
      return;
    }

    if (phaseEndsAt == null) {
      scheduleMicrotask(() {
        if (mounted) {
          widget.clearSession();
        }
      });
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
    scheduleMicrotask(() {
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

  String _todayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  void _checkDayChange() {
    final today = _todayKey();
    if (_currentDateKey != today) {
      _currentDateKey = today;
      setState(() {
        _streakCount = 0;
      });
      widget.saveStreakCount(0);
    }
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
      _playChime(hapticEvent: projection.isBreak ? 'work_complete' : 'break_complete');
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
        maxConsecutiveSkips: widget.maxConsecutiveSkips,
        autoPostponeApps: widget.autoPostponeApps,
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
    final startMinutes =
        widget.workHoursStartHour * 60 + widget.workHoursStartMinute;
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
            _phaseEndsAt = _phaseStartedAt!.add(
              Duration(seconds: _remainingSeconds),
            );
            _animationController.forward();
            _schedulePhaseDeadlineTimer(_phaseEndsAt!);
            unawaited(
              _schedulePhaseReminder(_remainingSeconds, isBreak: _isBreak),
            );
            _startBackgroundPhase(
              phaseEndsAt: _phaseEndsAt!,
              isBreak: _isBreak,
            );
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
            _phaseEndsAt = _phaseStartedAt!.add(
              Duration(seconds: _remainingSeconds),
            );
            _animationController.forward();
            _schedulePhaseDeadlineTimer(_phaseEndsAt!);
            unawaited(
              _schedulePhaseReminder(_remainingSeconds, isBreak: _isBreak),
            );
            _startBackgroundPhase(
              phaseEndsAt: _phaseEndsAt!,
              isBreak: _isBreak,
            );
            if (_remainingSeconds <= 5) _pulseController.forward();
          }
        });
        _updateDesktopState();
      }
    }
  }

  void _creditNaturalBreak() {
    if (!mounted) return;

    // Log the work done up to this point so user doesn't lose credit for it
    final workDone = _initialDuration - _remainingSeconds;
    if (workDone > 0) {
      final now = DateTime.now();
      widget.saveCompletedWorkSession(now, workDone);
      widget.saveTimerEventRecord(
        TimerEventRecord(
          id: now.millisecondsSinceEpoch.toString(),
          timestamp: now,
          type: TimerEventType.workCompleted,
          durationSeconds: workDone,
        ),
      );
    }

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
      _phaseEndsAt = _phaseStartedAt!.add(
        Duration(seconds: _workDurationSeconds),
      );
    });

    _animationController.forward(from: 0.0);
    _saveActiveSession(remainingSeconds: _workDurationSeconds);
    _schedulePhaseDeadlineTimer(_phaseEndsAt!);
    unawaited(_schedulePhaseReminder(_workDurationSeconds, isBreak: false));
    _startBackgroundPhase(phaseEndsAt: _phaseEndsAt!, isBreak: false);
    _updateDesktopState();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context)!.timerNaturalBreakCredited),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'OK',
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  // -------------------- Timer Logic --------------------
  void _startTimer(int duration, {bool isBreak = false}) {
    _phaseTransitionTimer?.cancel();
    _phaseTransitionTimer = null;
    _lastBlinkReminderBucket = null;
    _lastBlinkReminderAt = null;
    _lastTrayBlinkNudgeBucket = null;
    _lastTrayBlinkNudgeAt = null;
    _cancelPhaseDeadlineTimer();
    _stopTimerCleanup(resetPulse: true);
    _cancelReminders();
    
    // Trigger transition flash
    final isDarkTheme = Theme.of(context).brightness == Brightness.dark;
    final accentColor = widget.useSystemAccent
        ? Theme.of(context).colorScheme.primary
        : ColorPresets.swatchColor(
            widget.colorPreset,
            isDarkTheme,
            customHex: widget.customAccentColorHex,
          );
    _flashColor = isBreak ? accentColor : Colors.white;
    _flashController.forward(from: 0.0);

    setState(() {
      _isBreak = isBreak;
      if (isBreak) {
        _activeBreakVisualizerStyle = _resolveVisualizerStyle();
        // Freeze a tip at break start \u2014 stays fixed for the entire break.
        // Pick the next tip from the rotating index so each break shows a
        // different one, then advance the index for the following break.
        _frozenBreakTip = EyeHealthTips.at(_educationTipIndex);
        _educationTipIndex =
            (_educationTipIndex + 1) % EyeHealthTips.all.length;
      } else {
        _frozenBreakTip = null; // clear for next break
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
      _phaseEndsAt = _phaseStartedAt!.add(Duration(seconds: _remainingSeconds));
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
    unawaited(widget.notificationService.cancelBlinkReminder());
  }

  void _skipBreak() {
    if (!_isBreak || !_isRunning) return;
    // Enforce skip limit
    final limit = widget.maxConsecutiveSkips;
    if (limit > 0 && _consecutiveSkips >= limit) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'You\'ve skipped $limit break${limit == 1 ? '' : 's'} in a row — take a moment to rest your eyes! 👁️',
          ),
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'OK',
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            },
          ),
        ),
      );
      return;
    }
    _consecutiveSkips++;
    _animationController.stop();
    widget.saveTimerEventRecord(
      TimerEventRecord(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        timestamp: DateTime.now(),
        type: TimerEventType.breakSkipped,
        durationSeconds: 0,
      ),
    );
    _onPhaseComplete();
    _updateDesktopState();
  }

  void _postponeBreak() {
    if (!_isRunning) return;
    _animationController.stop();
    _playChime(hapticEvent: 'postpone');
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
    widget.saveTimerEventRecord(
      TimerEventRecord(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        timestamp: DateTime.now(),
        type: TimerEventType.breakPostponed,
        durationSeconds: postponeSeconds,
      ),
    );
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
        widget.saveTimerEventRecord(
          TimerEventRecord(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            timestamp: DateTime.now(),
            type: TimerEventType.workCancelled,
            durationSeconds: elapsed,
          ),
        );
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

    final now = DateTime.now();
    final isSameDay = _phaseEndsAt!.year == now.year &&
        _phaseEndsAt!.month == now.month &&
        _phaseEndsAt!.day == now.day;
    if (!isSameDay) {
      await _backgroundService.stopPhase();
      setState(() {
        _isRunning = false;
        _isPaused = false;
        _phaseEndsAt = null;
        _streakCount = 0;
      });
      _checkSchedule();
      return;
    }

    _animationController.stop();
    final bgSession = await _backgroundService.getBackgroundSession();
    if (!mounted) return;
    if (bgSession != null && bgSession['isActive'] == true) {
      final bgEndsAtMillis = bgSession['phaseEndsAtMillis'] as int;
      final bgEndsAt = DateTime.fromMillisecondsSinceEpoch(bgEndsAtMillis);
      final now = DateTime.now();
      final isSameDay = bgEndsAt.year == now.year &&
          bgEndsAt.month == now.month &&
          bgEndsAt.day == now.day;
      if (!isSameDay) {
        await _backgroundService.stopPhase();
        setState(() {
          _isRunning = false;
          _isPaused = false;
          _phaseEndsAt = null;
          _streakCount = 0;
        });
        _checkSchedule();
        return;
      }
      final bgIsBreak = bgSession['isBreak'] as bool;
      final bgStreakCount = bgSession['streakCount'] as int;
      final bgCompletedAutoRunCycles =
          bgSession['completedAutoRunCycles'] as int;
      final pendingEvents = bgSession['pendingEvents'] as List<dynamic>?;
      final bgPostponedBreakDuration =
          bgSession['postponedBreakDuration'] as int?;
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
            widget.saveTimerEventRecord(
              TimerEventRecord(
                id: timestamp.toString(),
                timestamp: DateTime.fromMillisecondsSinceEpoch(timestamp),
                type: type,
                durationSeconds: durationSeconds,
              ),
            );
          }
        }
        if (hasNaturalBreak) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text(
                  'Natural break detected while away! Timer reset.',
                ),
                duration: const Duration(seconds: 4),
                action: SnackBarAction(
                  label: 'OK',
                  onPressed: () {
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  },
                ),
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

  Future<bool> _isRestrictedAppFocused() async {
    final rawApps = widget.autoPostponeApps;
    if (rawApps.trim().isEmpty) return false;
    final apps = rawApps
        .split(',')
        .map((e) => e.trim().toLowerCase())
        .where((e) => e.isNotEmpty)
        .toList();
    if (apps.isEmpty) return false;

    if (!kIsWeb && Platform.isLinux) {
      try {
        final activeWindowResult = await Process.run('xprop', ['-root', '_NET_ACTIVE_WINDOW']);
        if (activeWindowResult.exitCode != 0) return false;
        final out = activeWindowResult.stdout.toString();
        final match = RegExp(r'window id # (0x[0-9a-fA-F]+)').firstMatch(out);
        if (match == null) return false;
        final windowId = match.group(1);
        if (windowId == null) return false;

        final wmClassResult = await Process.run('xprop', ['-id', windowId, 'WM_CLASS']);
        if (wmClassResult.exitCode != 0) return false;
        final classOut = wmClassResult.stdout.toString().toLowerCase();

        for (final app in apps) {
          if (classOut.contains(app)) {
            return true;
          }
        }
      } catch (_) {}
    }
    return false;
  }

  Future<void> _onPhaseComplete() async {
    if (!_isRunning || _phaseEndsAt == null || _isCancelled || !mounted) {
      return;
    }

    _cancelPhaseDeadlineTimer();

    final completedBreakPhase = _isBreak;
    final completedPhaseAt = _phaseEndsAt!;
    _phaseStartedAt = null;
    _phaseEndsAt = null;
    _cancelReminders();
    _playChime(hapticEvent: completedBreakPhase ? 'break_complete' : 'work_complete');
    _pulseController.stop();

    setState(() => _phaseOpacity = 0.0);

    // Camera/mic & Focused app auto postpone check
    bool shouldAutoPostpone = false;
    int upcomingBreakDuration = 0;
    bool wasPostponedWork = false;
    if (!completedBreakPhase) {
      if (widget.cameraMicAutoPostponeEnabled) {
        final camInUse = await _isCameraInUse();
        final micInUse = await _isMicInUse();
        if (camInUse || micInUse) {
          shouldAutoPostpone = true;
        }
      }
      if (!shouldAutoPostpone && widget.autoPostponeApps.trim().isNotEmpty) {
        final appFocused = await _isRestrictedAppFocused();
        if (appFocused) {
          shouldAutoPostpone = true;
        }
      }
      if (shouldAutoPostpone) {
        upcomingBreakDuration = _postponedBreakDuration ??
            _breakDurationForCompletedCycle(_streakCount + 1);
        wasPostponedWork = _postponedBreakDuration != null;
      }
    }

    if (!mounted || _isCancelled || !_isRunning) {
      return;
    }

    if (shouldAutoPostpone) {
      _autoPostponeBreak(completedPhaseAt, upcomingBreakDuration, wasPostponedWork);
      return;
    }

    _phaseTransitionTimer?.cancel();
    _phaseTransitionTimer = Timer(const Duration(milliseconds: 300), () {
      _phaseTransitionTimer = null;
      if (!mounted || _isCancelled) {
        return;
      }

      if (completedBreakPhase) {
        // Reset skip counter — the user actually took the break
        _consecutiveSkips = 0;
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

      final upcomingBreakDuration =
          _postponedBreakDuration ??
          _breakDurationForCompletedCycle(_streakCount + 1);
      final isPostponed = _postponedBreakDuration != null;

      setState(() {
        _postponedBreakDuration = null;
        if (!isPostponed) {
          _streakCount = _streakCount + 1;
          _autoRunCompletedCycles++;
        }
      });

      if (!isPostponed) {
        _onStreakIncremented(_streakCount);
        widget.saveStreakCount(_streakCount);
        widget.saveCompletedWorkSession(completedPhaseAt, _initialDuration);
        widget.saveTimerEventRecord(
          TimerEventRecord(
            id: completedPhaseAt.millisecondsSinceEpoch.toString(),
            timestamp: completedPhaseAt,
            type: TimerEventType.workCompleted,
            durationSeconds: _initialDuration,
          ),
        );
      }

      _startTimer(upcomingBreakDuration, isBreak: true);
    });
  }

  void _onStreakIncremented(int newStreak) {
    final isMilestone = newStreak == widget.dailyGoal || 
                        newStreak == 5 || 
                        newStreak == 10 || 
                        newStreak == 25 || 
                        newStreak == 50;
    if (isMilestone && newStreak > 0) {
      _triggerMilestoneCelebration();
    }
  }

  void _triggerMilestoneCelebration() {
    if (!mounted) return;
    if (Platform.environment.containsKey('FLUTTER_TEST')) return;
    setState(() {
      _showConfetti = true;
    });
    // Run the particle confetti for 4 seconds, then stop it to conserve CPU
    Timer(const Duration(seconds: 4), () {
      if (!mounted) return;
      setState(() {
        _showConfetti = false;
      });
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
      unawaited(widget.notificationService.cancelWellnessRemindersBackground());
      return Future<bool>.value(false);
    }

    final delay = Duration(seconds: durationSeconds);
    if (isBreak) {
      unawaited(widget.notificationService.cancelWellnessRemindersBackground());
      return widget.notificationService.scheduleBreakCompleteReminder(delay);
    } else {
      if (widget.wellnessRemindersEnabled && widget.wellnessReminderCadenceSeconds > 0) {
        unawaited(
          widget.notificationService.scheduleWellnessRemindersBackground(
            remainingSeconds: durationSeconds,
            cadenceSeconds: widget.wellnessReminderCadenceSeconds,
            currentAccumulator: _wellnessAccumulator,
            startIndex: _wellnessTypeIndex,
          ),
        );
      } else {
        unawaited(widget.notificationService.cancelWellnessRemindersBackground());
      }

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

  Future<void> _triggerHapticPattern(String event) async {
    if (!widget.hapticsEnabled) return;
    switch (event) {
      case 'work_complete':
        await HapticFeedback.heavyImpact();
        await Future.delayed(const Duration(milliseconds: 150));
        await HapticFeedback.heavyImpact();
        break;
      case 'break_complete':
        await HapticFeedback.mediumImpact();
        await Future.delayed(const Duration(milliseconds: 150));
        await HapticFeedback.lightImpact();
        break;
      case 'blink_reminder':
        await HapticFeedback.selectionClick();
        break;
      case 'postpone':
        await HapticFeedback.mediumImpact();
        break;
      case 'button_tap':
      default:
        await HapticFeedback.lightImpact();
        break;
    }
  }

  Future<void> _playChime({String? hapticEvent}) async {
    if (widget.hapticsEnabled) {
      unawaited(_triggerHapticPattern(hapticEvent ?? 'button_tap'));
    }
    if (widget.soundEnabled) {
      if (widget.chimeStyle == 'system_alert') {
        unawaited(SystemSound.play(SystemSoundType.alert));
      } else {
        if (!kIsWeb && Platform.isLinux) {
          try {
            _activeChimeProcess?.kill();
            _activeChimeProcess = null;

            final byteData = await rootBundle.load('assets/sounds/${widget.chimeStyle}.wav');
            final tempDir = Directory.systemTemp;
            final file = File('${tempDir.path}/blinkkind_sounds/${widget.chimeStyle}.wav');
            if (!await file.exists()) {
              await file.create(recursive: true);
              await file.writeAsBytes(byteData.buffer.asUint8List(), flush: true);
            }

            bool played = false;
            final audioUtils = ['pw-play', 'paplay', 'aplay'];
            for (final util in audioUtils) {
              try {
                final process = await Process.start(util, [file.path]);
                _activeChimeProcess = process;
                played = true;
                unawaited(process.exitCode.then((code) {
                  if (_activeChimeProcess == process) {
                    _activeChimeProcess = null;
                  }
                }));
                break;
              } catch (_) {}
            }
            if (played) return;
          } catch (e) {
            debugPrint('Error playing Linux chime: $e');
          }
        }
        try {
          await _audioPlayer?.stop();
          unawaited(
            _audioPlayer!.play(AssetSource('sounds/${widget.chimeStyle}.wav')),
          );
        } catch (e) {
          unawaited(SystemSound.play(SystemSoundType.alert));
        }
      }
    }
  }

  bool get _canRunBlinkReminderCadences =>
      _isRunning &&
      !_isBreak &&
      !_isPaused &&
      !_isSnoozed &&
      !_isSchedulePaused &&
      !_isSystemIdlePaused;

  void _processBlinkReminderCadences() {
    if (!_canRunBlinkReminderCadences) return;

    final elapsed = _initialDuration - _remainingSeconds;
    if (elapsed <= 0) return;

    if (widget.blinkRemindersEnabled) {
      _preWarmBlinkReminderMessage(elapsed);
      if (widget.blinkRemindersCadenceSeconds > 0 &&
          elapsed % widget.blinkRemindersCadenceSeconds == 0) {
        _triggerBlinkReminderBanner(elapsed);
      }
    }

    if (widget.trayBlinkNudgesEnabled &&
        widget.trayBlinkNudgeCadenceSeconds > 0 &&
        elapsed % widget.trayBlinkNudgeCadenceSeconds == 0) {
      _triggerTrayBlinkNudge(elapsed);
    }
  }

  void _preWarmBlinkReminderMessage(int elapsed) {
    if (!widget.blinkReminderAiEnabled ||
        !widget.aiMotivationEnabled ||
        widget.aiApiKey.isEmpty) {
      return;
    }

    final preWarm = widget.blinkRemindersCadenceSeconds - 2;
    if (preWarm <= 0) return;
    if (elapsed % widget.blinkRemindersCadenceSeconds != preWarm) return;

    _blinkMessageFuture = AiService.instance
        .generateBlinkReminder(
          provider: widget.aiProvider,
          apiKey: widget.aiApiKey,
          model: widget.aiModel,
        )
        .timeout(const Duration(seconds: 3), onTimeout: () => '')
        .catchError((_) => '');
  }

  void _triggerBlinkReminderBanner(int elapsed) {
    final cadence = widget.blinkRemindersCadenceSeconds;
    if (cadence <= 0) return;

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
      unawaited(_triggerHapticPattern('blink_reminder'));
    }

    // On Linux/desktop the notification carries no sound channel, so play
    // the chime in-app immediately.  On Android the channel handles it.
    if (!kIsWeb && (Platform.isLinux || Platform.isMacOS || Platform.isWindows)) {
      unawaited(_playChime(hapticEvent: 'blink_reminder'));
    }

    final customMsg = widget.blinkReminderCustomMessage.isNotEmpty
        ? widget.blinkReminderCustomMessage
        : null;

    // Helper that re-checks the dedup guard before actually posting.
    // This is critical for async paths (AI future callbacks) where
    // the resolution may arrive one or more cadence periods late.
    void postNotification(String? message) {
      if (!mounted || !_canRunBlinkReminderCadences) return;
      // Re-check: if another notification has already fired since this
      // async call was scheduled, bail out.
      final nowPost = DateTime.now();
      final sinceLast = _lastBlinkReminderAt == null
          ? null
          : nowPost.difference(_lastBlinkReminderAt!).inSeconds;
      if (_lastBlinkReminderBucket != bucket &&
          sinceLast != null &&
          sinceLast < cadence - 1) {
        // A newer bucket already fired; skip this stale callback.
        return;
      }
      unawaited(
        widget.notificationService.showBlinkReminder(
          customMessage: (message != null && message.isNotEmpty) ? message : null,
          interactive: widget.blinkReminderInteractiveEnabled,
          chimeStyle: widget.chimeStyle,
        ),
      );
    }

    if (customMsg != null) {
      postNotification(customMsg);
    } else if (_blinkMessageFuture != null) {
      final future = _blinkMessageFuture!;
      _blinkMessageFuture = null;
      future
          .then((msg) => postNotification(msg))
          .catchError((_) => postNotification(null));
    } else {
      postNotification(null);
    }
  }

  void _triggerTrayBlinkNudge(int elapsed) {
    final cadence = widget.trayBlinkNudgeCadenceSeconds;
    if (cadence <= 0) return;

    final bucket = elapsed ~/ cadence;
    final now = DateTime.now();
    final lastAt = _lastTrayBlinkNudgeAt;
    if (_lastTrayBlinkNudgeBucket == bucket ||
        (lastAt != null && now.difference(lastAt).inSeconds < cadence - 1)) {
      return;
    }
    _lastTrayBlinkNudgeBucket = bucket;
    _lastTrayBlinkNudgeAt = now;

    setState(() {
      _isBlinkNudging = true;
    });
    _updateDesktopState();

    Timer(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      setState(() {
        _isBlinkNudging = false;
      });
      _updateDesktopState();
    });
  }

  bool get _canChangeSettings => !_isRunning;

  LinearGradient _backgroundGradientFromPreset(String preset, bool isDark) {
    if (widget.useSystemAccent) {
      final primaryColor = Theme.of(context).colorScheme.primary;
      final hex = '#${primaryColor.toARGB32().toRadixString(16).padLeft(8, '0').substring(2)}';
      return ColorPresets.backgroundGradient(
        'Custom',
        isDark,
        customHex: hex,
      );
    }
    return ColorPresets.backgroundGradient(
      preset,
      isDark,
      customHex: widget.customAccentColorHex,
    );
  }

  bool get _isSnoozed =>
      _snoozeEndsAt != null && DateTime.now().isBefore(_snoozeEndsAt!);

  Future<bool> _isCameraInUse() async {
    if (widget.isCameraInUseOverride != null) {
      return widget.isCameraInUseOverride!();
    }
    if (kIsWeb) return false;
    if (Platform.isLinux) {
      try {
        final result = await Process.run('bash', [
          '-c',
          'fuser /dev/video* 2>/dev/null | grep -q . && echo yes || echo no',
        ]).timeout(const Duration(seconds: 2));
        return (result.stdout as String).trim() == 'yes';
      } catch (_) {
        return false;
      }
    } else if (Platform.isAndroid) {
      try {
        final bool inUse = await const MethodChannel('blinkkind/break_overlay')
            .invokeMethod('isCameraInUse');
        return inUse;
      } catch (_) {
        return false;
      }
    }
    return false;
  }

  Future<bool> _isMicInUse() async {
    if (widget.isMicInUseOverride != null) {
      return widget.isMicInUseOverride!();
    }
    if (kIsWeb) return false;
    if (Platform.isLinux) {
      try {
        final result = await Process.run('bash', [
          '-c',
          'pactl list source-outputs 2>/dev/null | grep -q "Source Output #" && echo yes || echo no',
        ]).timeout(const Duration(seconds: 2));
        return (result.stdout as String).trim() == 'yes';
      } catch (_) {
        return false;
      }
    } else if (Platform.isAndroid) {
      try {
        final bool inUse = await const MethodChannel('blinkkind/break_overlay')
            .invokeMethod('isMicInUse');
        return inUse;
      } catch (_) {
        return false;
      }
    }
    return false;
  }

  void _autoPostponeBreak(
    DateTime completedPhaseAt,
    int upcomingBreakDuration,
    bool wasPostponedWork,
  ) {
    final postponeSeconds = widget.postponeDurationSeconds;

    // 1. Save completed work session & streak count (if it wasn't already a postponed work)
    if (!wasPostponedWork) {
      setState(() {
        _streakCount = _streakCount + 1;
        _autoRunCompletedCycles++;
      });
      _onStreakIncremented(_streakCount);
      widget.saveStreakCount(_streakCount);
      widget.saveCompletedWorkSession(completedPhaseAt, _initialDuration);
      widget.saveTimerEventRecord(
        TimerEventRecord(
          id: completedPhaseAt.millisecondsSinceEpoch.toString(),
          timestamp: completedPhaseAt,
          type: TimerEventType.workCompleted,
          durationSeconds: _initialDuration,
        ),
      );
    }

    // 2. Save break postponed event
    widget.saveTimerEventRecord(
      TimerEventRecord(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        timestamp: DateTime.now(),
        type: TimerEventType.breakPostponed,
        durationSeconds: postponeSeconds,
      ),
    );

    // 3. Set the state for the new postponed work phase
    setState(() {
      _isBreak = false;
      _postponedBreakDuration = upcomingBreakDuration;
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

    // 4. Schedule phase reminder for work
    unawaited(_schedulePhaseReminder(postponeSeconds, isBreak: false));
    unawaited(_preFetchAiQuote());
    _updateDesktopState();

    // 5. Show notification
    unawaited(widget.notificationService.showAutoPostponeNotification());
  }

  void _processWellnessReminders(int delta) {
    if (!widget.wellnessRemindersEnabled) return;

    // Only accumulate if running, not paused, not snoozed, not schedule-paused, not idle-paused
    final isTimerActive = _isRunning &&
        !_isPaused &&
        !_isSchedulePaused &&
        !_isSystemIdlePaused &&
        !_isSnoozed;

    if (isTimerActive && delta > 0 && delta < 10) {
      _wellnessAccumulator += delta;
      if (_wellnessAccumulator >= widget.wellnessReminderCadenceSeconds) {
        _wellnessAccumulator = 0;
        final type =
            WellnessType.values[_wellnessTypeIndex % WellnessType.values.length];
        _wellnessTypeIndex++;
        unawaited(_triggerWellnessReminder(type));
      }
    }
  }

  Future<void> _triggerWellnessReminder(WellnessType type) async {
    String? aiMessage;
    if (widget.aiMotivationEnabled && widget.aiApiKey.isNotEmpty) {
      try {
        final prompt = _getWellnessPrompt(type);
        aiMessage = await AiService.instance.generateMotivation(
          provider: widget.aiProvider,
          apiKey: widget.aiApiKey,
          model: widget.aiModel,
          prompt: prompt,
        );
      } catch (e, stackTrace) {
        unawaited(Sentry.captureException(e, stackTrace: stackTrace));
        debugPrint('Failed to generate AI wellness reminder: $e');
      }
    }
    unawaited(widget.notificationService.showWellnessReminder(type, aiMessage: aiMessage));
  }

  String _getWellnessPrompt(WellnessType type) {
    switch (type) {
      case WellnessType.hydration:
        return 'Generate a short, friendly, and motivational reminder (max 15 words) for a developer to take a sip of water and stay hydrated right now. Speak directly to a developer.';
      case WellnessType.posture:
        return 'Generate a short, friendly, and motivational reminder (max 15 words) for a developer to check their sitting posture right now (e.g. relax shoulders, sit up straight). Speak directly to a developer.';
      case WellnessType.stretch:
        return 'Generate a short, friendly, and motivational reminder (max 15 words) for a developer to stand up and stretch right now. Speak directly to a developer.';
    }
  }

  String _statusLabel(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (_isSnoozed) {
      return l10n.snoozed;
    }
    if (_isSchedulePaused) {
      return l10n.schedulePaused;
    }
    if (!_isRunning) {
      return l10n.idle;
    }
    if (_isMediaPaused) {
      return 'Media';
    }
    if (_isPaused) {
      return l10n.paused;
    }
    if (_isSystemIdlePaused) {
      return l10n.idlePaused;
    }
    return _isBreak ? l10n.breakLabel : l10n.workLabel;
  }

  String _phaseTitle(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (_isSnoozed) {
      final diff = _snoozeEndsAt!.difference(DateTime.now());
      final mins = (diff.inSeconds / 60).ceil();
      return l10n.breaksSnoozed(mins);
    }
    if (_isSchedulePaused) {
      return l10n.timerPausedBySchedule;
    }
    if (!_isRunning) {
      return l10n.readyForNextFocusSession;
    }
    if (_isMediaPaused) {
      return 'Paused — media is playing';
    }
    if (_isPaused) {
      return _isBreak ? l10n.breakPaused : l10n.workPaused;
    }
    if (_isSystemIdlePaused) {
      return _isBreak ? l10n.breakPaused : l10n.workPausedIdle;
    }
    return _isBreak ? l10n.breakTimeMessage : l10n.workTimeMessage;
  }

  String get _phaseSubtitle {
    if (_isSchedulePaused) {
      return 'Outside active work hours or days.';
    }
    if (!_isRunning) {
      return 'Start when your eyes and task are ready.';
    }
    if (_isMediaPaused) {
      return 'Will resume automatically when media stops.';
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
    if (_isMediaPaused) {
      return Icons.music_note_rounded;
    }
    if (_isPaused) {
      return Icons.pause_circle_outline;
    }
    return _isBreak ? Icons.visibility_outlined : Icons.timer_outlined;
  }

  Color _progressColorForMode(bool isBreak, String preset, bool isDark) {
    if (widget.useSystemAccent) {
      if (isBreak) {
        return isDark ? Colors.lightGreenAccent.shade100 : Colors.green;
      }
      return Theme.of(context).colorScheme.primary;
    }
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

  EyeHealthTip get _currentEducationTip => EyeHealthTips.at(_educationTipIndex);

  // Returns the tip frozen when the current break started.
  // Falls back to a random tip in case it wasn't set (shouldn't happen).
  EyeHealthTip get _currentBreakTip =>
      _frozenBreakTip ?? EyeHealthTips.at(_educationTipIndex);

  String _durationLabel(int seconds) {
    if (seconds < 60) {
      return '$seconds s';
    }
    final minutes = seconds ~/ 60;
    return '$minutes min';
  }

  Widget _buildTodayBreakSummary(ThemeData theme, Color accentColor) {
    final goalReached =
        widget.dailyGoal > 0 && _streakCount >= widget.dailyGoal;
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
            goalReached
                ? Icons.emoji_events_outlined
                : Icons.visibility_outlined,
            color: accentColor,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!.breaksTakenToday,
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

  Widget _buildHomeQuickActions(
    ThemeData theme,
    bool isDark,
    Color accentColor,
  ) {
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
          label: Text(AppLocalizations.of(context)!.timerTakeBreakNow),
          style: FilledButton.styleFrom(
            backgroundColor: accentColor,
            foregroundColor: foreground,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        if (_isSnoozed)
          OutlinedButton.icon(
            onPressed: _cancelSnooze,
            icon: const Icon(Icons.notifications_active_outlined),
            label: Text(AppLocalizations.of(context)!.timerCancelSnooze),
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          )
        else ...[
          OutlinedButton.icon(
            onPressed: _isBreak
                ? null
                : () => _pauseTimerForSnooze(const Duration(hours: 1)),
            icon: const Icon(Icons.snooze_outlined),
            label: Text(AppLocalizations.of(context)!.timerSnooze1h),
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          OutlinedButton.icon(
            onPressed: _isBreak ? null : _snoozeUntilTomorrow,
            icon: const Icon(Icons.nights_stay_outlined),
            label: Text(AppLocalizations.of(context)!.timerTomorrow),
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
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
      content = Text(_aiHealthInsight!, style: theme.textTheme.bodySmall);
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
        key: ValueKey(
          'ai_insight_${_isAiInsightLoading}_${_aiInsightError != null}_${_aiHealthInsight?.hashCode}',
        ),
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
    _checkDayChange();
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
      systemNavigationBarIconBrightness: isDark
          ? Brightness.light
          : Brightness.dark,
    );

    final theme = Theme.of(context);
    final effectiveTheme = _isFocusMode
        ? ThemeData.dark().copyWith(
            colorScheme: ColorScheme.dark(
              primary: widget.useSystemAccent
                  ? Theme.of(context).colorScheme.primary
                  : ColorPresets.swatchColor(
                      widget.colorPreset,
                      true,
                      customHex: widget.customAccentColorHex,
                    ),
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
                  title: const DragToMoveArea(
                    child: Text('BlinkKind'),
                  ),
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  systemOverlayStyle: systemOverlayStyle,
                  actions: [
                    if (_isRunning)
                      Tooltip(
                        message: _isPaused ? 'Resume timer' : 'Pause timer',
                        child: InkWell(
                          onTap: _pauseOrResume,
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: (_isPaused || _isMediaPaused)
                                    ? Colors.orangeAccent.withValues(alpha: 0.8)
                                    : Colors.white.withValues(alpha: 0.3),
                              ),
                              color: (_isPaused || _isMediaPaused)
                                  ? Colors.orange.withValues(alpha: 0.15)
                                  : Colors.transparent,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                                  size: 18,
                                  color: (_isPaused || _isMediaPaused)
                                      ? Colors.orangeAccent
                                      : null,
                                ),
                                if (_isMediaPaused) ...[
                                  const SizedBox(width: 4),
                                  Icon(
                                    Icons.music_note_rounded,
                                    size: 14,
                                    color: Colors.orangeAccent.withValues(alpha: 0.9),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    IconButton(
                      icon: const Icon(Icons.bar_chart),
                      onPressed: () => widget.openHistory(context),
                      tooltip: 'Productivity Insights',
                    ),
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
                    gradient: _backgroundGradientFromPreset(
                      widget.colorPreset,
                      _isFocusMode ? true : isDark,
                    ),
                  ),
                  child: Stack(
                    children: [
                      if (!_isFocusMode)
                        Positioned.fill(
                          child: _GlassmorphicBackground(
                            colorPreset: widget.colorPreset,
                            isDark: isDark,
                            customAccentColorHex: widget.customAccentColorHex,
                            useSystemAccent: widget.useSystemAccent,
                          ),
                        ),
                      if (_isFocusMode)
                        Positioned.fill(
                          child: _FocusModeBackground(
                            color: progressColor,
                            progressAnimation: _progressAnimation,
                            isBreak: _isBreak,
                          ),
                        ),
                      SafeArea(
                    child: Center(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final isLandscape =
                              MediaQuery.of(context).orientation ==
                              Orientation.landscape;
                          final double multiplier = _isFocusMode ? 1.25 : 1.0;
                          final double size = isLandscape
                              ? ((constraints.maxHeight - 48) * multiplier).clamp(160.0, 340.0)
                              : ((constraints.maxWidth - 48) * multiplier).clamp(220.0, 420.0);

                          final timerDial = _AnimatedTimerDial(
                            size: size,
                            progressAnimation: _progressAnimation,
                            pulseAnimation: _pulseAnimation,
                            initialDuration: _initialDuration,
                            statusLabel: _statusLabel(context),
                            textColor: textColor,
                            ringBackgroundColor: ringBgColor,
                            progressColor: progressColor,
                            strokeWidth: _ringStrokeWidth,
                            isLandscape: isLandscape,
                            onTap: _toggleFocusMode,
                            blinkRemindersEnabled:
                                widget.blinkRemindersEnabled ||
                                widget.trayBlinkNudgesEnabled,
                            isBlinkNudging: _isBlinkNudging,
                            isFocusMode: _isFocusMode,
                            isBreak: _isBreak,
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
                                  label: Text(
                                    AppLocalizations.of(context)!.start,
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: progressColor,
                                    foregroundColor: primaryButtonForeground,
                                    elevation: isDark ? 3 : 1,
                                    shadowColor: Colors.black54,
                                    padding: EdgeInsets.symmetric(
                                      horizontal: isLandscape ? 16 : 22,
                                      vertical: isLandscape ? 8 : 12,
                                    ),
                                    shape: const StadiumBorder(),
                                  ),
                                )
                              else if (_isSchedulePaused) ...[
                                // Schedule-paused: no Pause/Resume (already effectively
                                // paused). Only allow cancelling the session entirely.
                                OutlinedButton.icon(
                                  onPressed: _cancelTimer,
                                  icon: const Icon(Icons.stop),
                                  label: Text(
                                    AppLocalizations.of(context)!.stopTimer,
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: isDark
                                        ? Colors.red.shade200
                                        : Colors.red.shade700,
                                    side: BorderSide(
                                      color: Colors.red.shade300,
                                    ),
                                    padding: EdgeInsets.symmetric(
                                      horizontal: isLandscape ? 14 : 18,
                                      vertical: isLandscape ? 8 : 12,
                                    ),
                                    shape: const StadiumBorder(),
                                  ),
                                ),
                              ] else ...[
                                ElevatedButton.icon(
                                  onPressed: _pauseOrResume,
                                  icon: Icon(
                                    _isPaused ? Icons.play_arrow : Icons.pause,
                                  ),
                                  label: Text(
                                    _isPaused
                                        ? AppLocalizations.of(context)!.resume
                                        : AppLocalizations.of(context)!.pause,
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isDark
                                        ? Colors.white24
                                        : Colors.black87,
                                    foregroundColor: Colors.white,
                                    padding: EdgeInsets.symmetric(
                                      horizontal: isLandscape ? 16 : 20,
                                      vertical: isLandscape ? 8 : 12,
                                    ),
                                    shape: const StadiumBorder(),
                                  ),
                                ),
                                if (_isBreak && !_isPaused) ...[
                                  if (widget.allowSkip && (widget.maxConsecutiveSkips == 0 || _consecutiveSkips < widget.maxConsecutiveSkips))
                                    ElevatedButton.icon(
                                      onPressed: _skipBreak,
                                      icon: const Icon(Icons.skip_next),
                                      label: Text(
                                        AppLocalizations.of(context)!.skip,
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green.shade600,
                                        foregroundColor: Colors.white,
                                        padding: EdgeInsets.symmetric(
                                          horizontal: isLandscape ? 16 : 20,
                                          vertical: isLandscape ? 8 : 12,
                                        ),
                                        shape: const StadiumBorder(),
                                      ),
                                    ),
                                  if (widget.allowPostpone)
                                    ElevatedButton.icon(
                                      onPressed: _postponeBreak,
                                      icon: const Icon(Icons.snooze),
                                      label: Text(
                                        AppLocalizations.of(context)!.postpone,
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.orange.shade700,
                                        foregroundColor: Colors.white,
                                        padding: EdgeInsets.symmetric(
                                          horizontal: isLandscape ? 16 : 20,
                                          vertical: isLandscape ? 8 : 12,
                                        ),
                                        shape: const StadiumBorder(),
                                      ),
                                    ),
                                ],
                                OutlinedButton.icon(
                                  onPressed: _cancelTimer,
                                  icon: const Icon(Icons.stop),
                                  label: Text(
                                    AppLocalizations.of(context)!.cancel,
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: isDark
                                        ? Colors.red.shade200
                                        : Colors.red.shade700,
                                    side: BorderSide(
                                      color: Colors.red.shade300,
                                    ),
                                    padding: EdgeInsets.symmetric(
                                      horizontal: isLandscape ? 14 : 18,
                                      vertical: isLandscape ? 8 : 12,
                                    ),
                                    shape: const StadiumBorder(),
                                  ),
                                ),
                              ],
                            ],
                          );

                          if (isLandscape) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16.0,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  timerDial,
                                  const SizedBox(width: 32),
                                  Expanded(
                                    child: SingleChildScrollView(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
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
                                                    _phaseTitle(context),
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
                                                          widget
                                                              .breakCustomMessage
                                                              .trim()
                                                              .isNotEmpty)) ...[
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
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodySmall
                                                    ?.copyWith(
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
                                                _statusLabel(context),
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .labelLarge
                                                    ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: progressColor,
                                                    ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        Text(
                                          _phaseTitle(context),
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
                                                widget.breakCustomMessage
                                                    .trim()
                                                    .isNotEmpty)) ...[
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
                                if (_isBreak && _isRunning && !_isPaused) ...[
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
                                      child:
                                          _activeBreakVisualizerStyle ==
                                              'EyeExercise'
                                          ? EyeExerciseDotGuide(
                                              remainingSeconds:
                                                  _remainingSeconds,
                                              totalDurationSeconds:
                                                  _initialDuration,
                                            )
                                          : _activeBreakVisualizerStyle ==
                                                'BoxBreathing'
                                          ? BoxBreathingGuide(
                                              remainingSeconds:
                                                  _remainingSeconds,
                                              totalDurationSeconds:
                                                  _initialDuration,
                                            )
                                          : BlinkTrainingGuide(
                                              remainingSeconds:
                                                  _remainingSeconds,
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
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodyMedium,
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
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(color: textColor),
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
                  ],
                ),
              ),
            ),
            if (widget.showNotificationWarning && !_isFocusMode)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: _NotificationWarningBanner(
                  onFix: widget.onFixNotificationPermission,
                ),
              )
            else if (widget.showBatteryWarning && !_isFocusMode)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: _BatteryWarningBanner(
                  oemManufacturer: widget.oemManufacturer,
                  onFix: widget.onFixBatteryRestriction,
                  onDismiss: widget.onDismissBatteryWarning,
                ),
              ),
            if (_showConfetti)
              const Positioned.fill(
                child: IgnorePointer(
                  child: _ConfettiWidget(),
                ),
              ),
            IgnorePointer(
              child: AnimatedBuilder(
                animation: _flashAnimation,
                builder: (context, child) {
                  if (_flashAnimation.value <= 0.0) return const SizedBox.shrink();
                  return Container(
                    color: _flashColor.withValues(alpha: _flashAnimation.value),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    ),
  );
  }

  void _updateOsFocusDnd() {
    final shouldBeEnabled =
        widget.osFocusDndEnabled &&
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
      final snoozeRemaining = isSnoozed
          ? (snoozeEnds.difference(now).inSeconds / 60).ceil()
          : 0;

      DateTime? nextBreakVal;
      if (_isRunning &&
          !_isBreak &&
          !_isPaused &&
          !_isSystemIdlePaused &&
          !isSnoozed) {
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
          isLongBreak:
              _isBreak &&
              _longBreakEnabled &&
              _initialDuration == _longBreakDurationSeconds,
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
  final bool isFocusMode;
  final bool isBreak;

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
    required this.isFocusMode,
    required this.isBreak,
  });

  String _formattedTime(int seconds) {
    if (seconds < 60) return seconds.toString();
    final minutes = seconds ~/ 60;
    final remainder = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainder.toString().padLeft(2, '0')}';
  }

  Color _getCurrentProgressColor(double progress) {
    if (isBreak) {
      return progressColor;
    }
    if (progress > 0.25) {
      return const Color(0xFF10B981); // Emerald green
    } else if (progress > 0.10) {
      return const Color(0xFFF59E0B); // Amber
    } else {
      return const Color(0xFFF97316); // Orange
    }
  }

  List<Color> _getRingColors(double progress, Color baseColor) {
    if (isBreak) {
      final hsl = HSLColor.fromColor(baseColor);
      final lighterColor = hsl
          .withLightness((hsl.lightness + 0.15).clamp(0.0, 1.0))
          .toColor();
      return [baseColor, lighterColor];
    }
    if (progress > 0.25) {
      final hsl = HSLColor.fromColor(baseColor);
      final lighterColor = hsl
          .withLightness((hsl.lightness + 0.15).clamp(0.0, 1.0))
          .toColor();
      return [baseColor, lighterColor];
    } else if (progress > 0.10) {
      return const [
        Color(0xFFD97706), // Amber
        Color(0xFFFBBF24), // Light Amber
      ];
    } else {
      return const [
        Color(0xFFEA580C), // Orange
        Color(0xFFF87171), // Coral / Light Red
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final dialSize = size * 0.92;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: ScaleTransition(
        scale: pulseAnimation,
        child: SizedBox(
          width: size,
          height: size,
          child: AnimatedBuilder(
            animation: progressAnimation,
            child: null,
            builder: (context, _) {
              final remainingSeconds =
                  (initialDuration * progressAnimation.value).ceil();
              final currentProgressColor = _getCurrentProgressColor(progressAnimation.value);
              final ringColors = _getRingColors(progressAnimation.value, progressColor);

              return Stack(
                alignment: Alignment.center,
                children: [
                  // Frosted glass inner circle
                  Container(
                    width: dialSize - strokeWidth * 2,
                    height: dialSize - strokeWidth * 2,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.04),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.07),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: currentProgressColor.withValues(alpha: 0.08),
                          blurRadius: 24,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                  // Neon ring painter (ghost track + glowing arc + tip dot)
                  SizedBox(
                    width: dialSize,
                    height: dialSize,
                    child: CustomPaint(
                      painter: _GradientTimerPainter(
                        progress: progressAnimation.value,
                        strokeWidth: strokeWidth,
                        colors: ringColors,
                        trackColor: ringBackgroundColor,
                      ),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _BlinkKindAnimatedEye(
                        size: isFocusMode ? 36 : 26,
                        color: textColor.withValues(alpha: 0.8),
                        irisColor: currentProgressColor,
                        isBlinkNudging: isBlinkNudging,
                        isBreak: isBreak,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _formattedTime(remainingSeconds),
                        style: Theme.of(context).textTheme.displaySmall
                            ?.copyWith(
                              fontSize: isLandscape ? 28 : (isFocusMode ? 54 : null),
                              fontWeight: FontWeight.w200,
                              color: textColor,
                              shadows: isFocusMode
                                  ? [
                                      Shadow(
                                        color: currentProgressColor.withValues(alpha: 0.25),
                                        blurRadius: 16,
                                      ),
                                    ]
                                  : null,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        statusLabel,
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(
                              fontSize: isFocusMode ? 14 : null,
                              fontWeight: isFocusMode ? FontWeight.w300 : null,
                              color: textColor.withValues(
                                alpha: isFocusMode ? 0.45 : 0.65,
                              ),
                              letterSpacing: isFocusMode ? 1.5 : null,
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
    );
  }
}

class _FocusModeBackground extends StatefulWidget {
  final Color color;
  final Animation<double>? progressAnimation;
  final bool isBreak;

  const _FocusModeBackground({
    required this.color,
    this.progressAnimation,
    this.isBreak = false,
  });

  @override
  State<_FocusModeBackground> createState() => _FocusModeBackgroundState();
}

class _FocusModeBackgroundState extends State<_FocusModeBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final effectiveProgressAnimation = widget.progressAnimation;

    Widget buildBackground(double progressFraction) {
      Color baseColor = widget.color;
      if (!widget.isBreak) {
        if (progressFraction > 0.25) {
          baseColor = widget.color;
        } else if (progressFraction > 0.10) {
          baseColor = const Color(0xFFF59E0B);
        } else {
          baseColor = const Color(0xFFF97316);
        }
      }

      return AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final scale = 0.85 + _controller.value * 0.3; // pulsing scale 0.85 to 1.15
          final opacity = 0.04 + _controller.value * 0.08; // soft opacity
          return Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: scale,
                colors: [
                  baseColor.withValues(alpha: opacity),
                  Colors.transparent,
                ],
                stops: const [0.0, 1.0],
              ),
            ),
          );
        },
      );
    }

    if (effectiveProgressAnimation != null) {
      return AnimatedBuilder(
        animation: effectiveProgressAnimation,
        builder: (context, child) {
          return buildBackground(effectiveProgressAnimation.value);
        },
      );
    }

    return buildBackground(1.0);
  }
}

class _GradientTimerPainter extends CustomPainter {
  final double progress;
  final double strokeWidth;
  final List<Color> colors;
  final Color trackColor;

  _GradientTimerPainter({
    required this.progress,
    required this.strokeWidth,
    required this.colors,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final startAngle = -math.pi / 2;

    // ── 1. Ghost track (full circle, very faint) ────────────────────────
    final trackPaint = Paint()
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.butt
      ..color = trackColor.withValues(alpha: 0.18);
    canvas.drawCircle(center, radius, trackPaint);

    if (progress <= 0) return;

    final sweepAngle = 2 * math.pi * progress;
    final tipAngle = startAngle + sweepAngle;
    final tipX = center.dx + radius * math.cos(tipAngle);
    final tipY = center.dy + radius * math.sin(tipAngle);
    final tipOffset = Offset(tipX, tipY);

    // Origin point at 12 o'clock (arc start) — needed after switching to
    // StrokeCap.butt so the start looks clean, not a hard cut.
    final originOffset = Offset(
      center.dx + radius * math.cos(startAngle),
      center.dy + radius * math.sin(startAngle),
    );

    // Resolve primary arc colour for the glow layers
    final arcColor = colors.isNotEmpty ? colors.last : const Color(0xFF34D399);
    final startColor = colors.isNotEmpty ? colors.first : arcColor;

    // ── 2. Outer bloom glow (wide, very soft) — butt caps, no start bleed
    final bloomPaint = Paint()
      ..strokeWidth = strokeWidth * 3.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.butt
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14)
      ..color = arcColor.withValues(alpha: 0.18);
    canvas.drawArc(rect, startAngle, sweepAngle, false, bloomPaint);

    // ── 3. Inner glow (tighter, moderate opacity) ── butt caps
    final innerGlowPaint = Paint()
      ..strokeWidth = strokeWidth * 1.8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.butt
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6)
      ..color = arcColor.withValues(alpha: 0.45);
    canvas.drawArc(rect, startAngle, sweepAngle, false, innerGlowPaint);

    // ── 4. Main neon arc — butt caps (no round cap bleed at origin) ─────
    final arcPaint = Paint()
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.butt;

    if (colors.length == 1) {
      arcPaint.color = colors.first;
    } else {
      arcPaint.shader = SweepGradient(
        colors: colors,
        stops: List.generate(colors.length, (i) => i / (colors.length - 1)),
        transform: const GradientRotation(-math.pi / 2),
      ).createShader(rect);
    }
    canvas.drawArc(rect, startAngle, sweepAngle, false, arcPaint);

    // ── 5. Origin dot at arc start (12 o'clock) ─────────────────────────
    // Gives the arc start a smooth finish to replace the round cap we removed.
    canvas.drawCircle(
      originOffset,
      strokeWidth * 0.5,
      Paint()..color = startColor.withValues(alpha: 0.7),
    );

    // ── 6. Glowing dot at arc tip ───────────────────────────────────────
    // Outer halo using a RadialGradient shader to avoid Skia/Impeller blur box artifacts
    final glowRadius = strokeWidth * 2.5;
    canvas.drawCircle(
      tipOffset,
      glowRadius,
      Paint()
        ..shader = RadialGradient(
          colors: [
            arcColor.withValues(alpha: 0.4),
            arcColor.withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromCircle(center: tipOffset, radius: glowRadius)),
    );
    // Bright core dot
    canvas.drawCircle(
      tipOffset,
      strokeWidth * 0.65,
      Paint()..color = Colors.white.withValues(alpha: 0.95),
    );
  }

  @override
  bool shouldRepaint(covariant _GradientTimerPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.trackColor != trackColor ||
        !listEquals(oldDelegate.colors, colors);
  }
}

class _GlassmorphicBackground extends StatefulWidget {
  final String colorPreset;
  final bool isDark;
  final String? customAccentColorHex;
  final bool useSystemAccent;

  const _GlassmorphicBackground({
    required this.colorPreset,
    required this.isDark,
    this.customAccentColorHex,
    required this.useSystemAccent,
  });

  @override
  State<_GlassmorphicBackground> createState() => _GlassmorphicBackgroundState();
}

class _GlassmorphicBackgroundState extends State<_GlassmorphicBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 25),
    );
    if (kIsWeb || !Platform.environment.containsKey('FLUTTER_TEST')) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String effectivePreset;
    final String? effectiveHex;
    if (widget.useSystemAccent) {
      effectivePreset = 'Custom';
      final primaryColor = Theme.of(context).colorScheme.primary;
      effectiveHex = '#${primaryColor.toARGB32().toRadixString(16).padLeft(8, '0').substring(2)}';
    } else {
      effectivePreset = widget.colorPreset;
      effectiveHex = widget.customAccentColorHex;
    }

    final colors = ColorPresets.glassOrbColors(
      effectivePreset,
      widget.isDark,
      customHex: effectiveHex,
    );
    final primaryOrbColor = colors[0];
    final secondaryOrbColor = colors[1];

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final value = _controller.value * 2 * math.pi;

        // Slow fluid drift — primary orb near top-left, drifts toward center
        final dx1 = math.sin(value) * 0.12;
        final dy1 = math.cos(value) * 0.10;

        // Secondary orb near bottom-right
        final dx2 = math.cos(value + math.pi / 3) * 0.14;
        final dy2 = math.sin(value + math.pi / 3) * 0.10;

        // Accent orb — small, sits near center-right, opposite phase
        final dx3 = math.sin(value + math.pi) * 0.20;
        final dy3 = math.cos(value + math.pi) * 0.15;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            // Primary orb — top-left quadrant, drifts toward ring edge
            Align(
              alignment: Alignment(-0.55 + dx1, -0.50 + dy1),
              child: Container(
                width: 420,
                height: 420,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      primaryOrbColor.withValues(alpha: widget.isDark ? 0.80 : 0.50),
                      primaryOrbColor.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
            // Secondary orb — bottom-right quadrant
            Align(
              alignment: Alignment(0.60 + dx2, 0.55 + dy2),
              child: Container(
                width: 400,
                height: 400,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      secondaryOrbColor.withValues(alpha: widget.isDark ? 0.65 : 0.40),
                      secondaryOrbColor.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
            // Accent orb — small, near center-right, adds depth behind the ring
            Align(
              alignment: Alignment(0.30 + dx3, 0.10 + dy3),
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      primaryOrbColor.withValues(alpha: widget.isDark ? 0.45 : 0.25),
                      primaryOrbColor.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
            // Light blur to smooth edges — kept low so orbs stay vivid
            Positioned.fill(
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 22, sigmaY: 22),
                child: const SizedBox.shrink(),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _BlinkKindAnimatedEye extends StatefulWidget {
  final double size;
  final Color color;
  final Color irisColor;
  final bool isBlinkNudging;
  final bool isBreak;

  const _BlinkKindAnimatedEye({
    required this.size,
    required this.color,
    required this.irisColor,
    required this.isBlinkNudging,
    required this.isBreak,
  });

  @override
  State<_BlinkKindAnimatedEye> createState() => _BlinkKindAnimatedEyeState();
}

class _BlinkKindAnimatedEyeState extends State<_BlinkKindAnimatedEye>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _openAnimation;
  late AnimationController _nudgeScaleController;
  late Animation<double> _scaleAnimation;
  Timer? _naturalBlinkTimer;
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _openAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _nudgeScaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.25).chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.25, end: 0.95).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.95, end: 1.0).chain(CurveTween(curve: Curves.easeInCubic)),
        weight: 30,
      ),
    ]).animate(_nudgeScaleController);

    _scheduleNextNaturalBlink();
  }

  @override
  void didUpdateWidget(covariant _BlinkKindAnimatedEye oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isBlinkNudging && !oldWidget.isBlinkNudging) {
      _triggerNudgeBlink();
      _nudgeScaleController.forward(from: 0.0);
    }
    if (widget.isBreak != oldWidget.isBreak) {
      _triggerTransitionFlutter();
    }
  }

  void _scheduleNextNaturalBlink() {
    if (Platform.environment.containsKey('FLUTTER_TEST')) return;
    _naturalBlinkTimer?.cancel();
    final nextDelay = Duration(milliseconds: 3000 + _random.nextInt(3500));
    _naturalBlinkTimer = Timer(nextDelay, () {
      if (!mounted) return;
      _triggerNaturalBlink();
    });
  }

  Future<void> _triggerNaturalBlink() async {
    if (!mounted || _controller.isAnimating || widget.isBlinkNudging) {
      _scheduleNextNaturalBlink();
      return;
    }
    await _controller.forward();
    if (!mounted) return;
    await _controller.reverse();
    _scheduleNextNaturalBlink();
  }

  Future<void> _triggerNudgeBlink() async {
    if (Platform.environment.containsKey('FLUTTER_TEST')) return;
    _naturalBlinkTimer?.cancel();
    if (!mounted) return;
    _controller.stop();
    await _controller.forward();
    if (!mounted) return;
    await _controller.reverse();
    if (!mounted) return;
    await Future<void>.delayed(const Duration(milliseconds: 80));
    if (!mounted) return;
    await _controller.forward();
    if (!mounted) return;
    await _controller.reverse();
    _scheduleNextNaturalBlink();
  }

  Future<void> _triggerTransitionFlutter() async {
    if (Platform.environment.containsKey('FLUTTER_TEST')) return;
    _naturalBlinkTimer?.cancel();
    if (!mounted) return;
    _controller.stop();
    for (int i = 0; i < 3; i++) {
      await _controller.forward();
      if (!mounted) return;
      await _controller.reverse();
      if (!mounted) return;
      await Future<void>.delayed(const Duration(milliseconds: 60));
    }
    _scheduleNextNaturalBlink();
  }

  @override
  void dispose() {
    _naturalBlinkTimer?.cancel();
    _controller.dispose();
    _nudgeScaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_openAnimation, _scaleAnimation]),
      builder: (context, child) {
        final scale = _scaleAnimation.value;
        final glowOpacity = ((scale - 1.0) / 0.25).clamp(0.0, 1.0);
        return SizedBox(
          width: widget.size * 1.5,
          height: widget.size,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              if (scale > 1.0)
                Positioned(
                  child: Container(
                    width: widget.size * 2.2,
                    height: widget.size * 2.2,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          widget.irisColor.withValues(alpha: glowOpacity * 0.4),
                          widget.irisColor.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ),
              Transform.scale(
                scale: scale,
                child: CustomPaint(
                  size: Size(widget.size * 1.5, widget.size),
                  painter: _EyeVectorPainter(
                    openAmount: _openAnimation.value,
                    eyelidColor: widget.color,
                    irisColor: widget.irisColor,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _EyeVectorPainter extends CustomPainter {
  final double openAmount;
  final Color eyelidColor;
  final Color irisColor;

  const _EyeVectorPainter({
    required this.openAmount,
    required this.eyelidColor,
    required this.irisColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w / 2, h / 2);

    final startX = w * 0.16;
    final endX = w * 0.84;
    final double verticalScale = 0.05 + (0.42 * openAmount);
    final double topOffset = (h / 2) - (h * verticalScale);
    final double bottomOffset = (h / 2) + (h * verticalScale);

    final outerPath = Path();
    outerPath.moveTo(startX, h / 2);
    outerPath.quadraticBezierTo(w / 2, topOffset, endX, h / 2);
    outerPath.quadraticBezierTo(w / 2, bottomOffset, startX, h / 2);
    outerPath.close();

    canvas.save();

    if (openAmount > 0.05) {
      final eyeballPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.85)
        ..style = PaintingStyle.fill;
      canvas.drawPath(outerPath, eyeballPaint);

      canvas.clipPath(outerPath);

      final irisRadius = math.min(w, h) * 0.42;
      final irisPaint = Paint()
        ..color = irisColor
        ..style = PaintingStyle.fill;
      canvas.drawCircle(center, irisRadius, irisPaint);

      final pupilPaint = Paint()
        ..color = Colors.black.withValues(alpha: 0.9)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(center, irisRadius * 0.45, pupilPaint);

      final reflectionPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;
      canvas.drawCircle(
        center + Offset(-irisRadius * 0.25, -irisRadius * 0.25),
        irisRadius * 0.18,
        reflectionPaint,
      );
    }

    canvas.restore();

    final lidPaint = Paint()
      ..color = eyelidColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;
    
    final upperPath = Path()
      ..moveTo(startX, h / 2)
      ..quadraticBezierTo(w / 2, topOffset, endX, h / 2);
    
    final lowerPath = Path()
      ..moveTo(startX, h / 2)
      ..quadraticBezierTo(w / 2, bottomOffset, endX, h / 2);

    canvas.drawPath(upperPath, lidPaint);
    canvas.drawPath(lowerPath, lidPaint);
  }

  @override
  bool shouldRepaint(covariant _EyeVectorPainter old) =>
      old.openAmount != openAmount ||
      old.eyelidColor != eyelidColor ||
      old.irisColor != irisColor;
}

class _ConfettiWidget extends StatefulWidget {
  const _ConfettiWidget();

  @override
  State<_ConfettiWidget> createState() => _ConfettiWidgetState();
}

class _ConfettiWidgetState extends State<_ConfettiWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_ConfettiParticle> _particles = [];
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final size = MediaQuery.of(context).size;
      final center = Offset(size.width / 2, size.height / 3);
      for (int i = 0; i < 75; i++) {
        final angle = _random.nextDouble() * 2 * math.pi;
        final speed = 4.0 + _random.nextDouble() * 8.0;
        final velocity = Offset(math.cos(angle) * speed, math.sin(angle) * speed - 3.0);
        final color = HSVColor.fromAHSV(
          1.0,
          _random.nextDouble() * 360.0,
          0.85,
          0.95,
        ).toColor();
        
        _particles.add(
          _ConfettiParticle(
            position: center,
            velocity: velocity,
            color: color,
            radius: 3.0 + _random.nextDouble() * 4.0,
            rotation: _random.nextDouble() * 2 * math.pi,
            rotationSpeed: -0.1 + _random.nextDouble() * 0.2,
          ),
        );
      }
      _controller.repeat();
    });
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
        for (final p in _particles) {
          p.position += p.velocity;
          p.velocity = Offset(p.velocity.dx * 0.98, (p.velocity.dy + 0.22) * 0.98);
          p.rotation += p.rotationSpeed;
        }
        return CustomPaint(
          size: Size.infinite,
          painter: _ConfettiPainter(particles: _particles),
        );
      },
    );
  }
}

class _ConfettiParticle {
  Offset position;
  Offset velocity;
  final Color color;
  final double radius;
  double rotation;
  final double rotationSpeed;

  _ConfettiParticle({
    required this.position,
    required this.velocity,
    required this.color,
    required this.radius,
    required this.rotation,
    required this.rotationSpeed,
  });
}

class _ConfettiPainter extends CustomPainter {
  final List<_ConfettiParticle> particles;

  const _ConfettiPainter({required this.particles});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (final p in particles) {
      if (p.position.dx < 0 || p.position.dx > size.width || p.position.dy > size.height) {
        continue;
      }
      canvas.save();
      canvas.translate(p.position.dx, p.position.dy);
      canvas.rotate(p.rotation);
      paint.color = p.color;
      canvas.drawRect(
        Rect.fromCenter(center: Offset.zero, width: p.radius * 2, height: p.radius * 1.2),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) => true;
}

class _BatteryWarningBanner extends StatefulWidget {
  final String oemManufacturer;
  final VoidCallback onFix;
  final VoidCallback onDismiss;

  const _BatteryWarningBanner({
    required this.oemManufacturer,
    required this.onFix,
    required this.onDismiss,
  });

  @override
  State<_BatteryWarningBanner> createState() => _BatteryWarningBannerState();
}

class _BatteryWarningBannerState extends State<_BatteryWarningBanner> {
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _visible = true);
    });
  }

  String _subtitle() {
    final m = widget.oemManufacturer.toLowerCase();
    if (m.contains('samsung')) {
      return 'Samsung One UI may stop break reminders in the background. Tap Fix to open Power Saving settings.';
    } else if (m.contains('xiaomi') || m.contains('redmi') || m.contains('miui')) {
      return 'MIUI battery manager may block break reminders. Tap Fix to allow BlinkKind in background.';
    } else if (m.contains('huawei') || m.contains('honor')) {
      return 'Huawei Protected Apps list may stop break reminders. Tap Fix to add BlinkKind.';
    } else if (m.contains('oppo') || m.contains('realme') || m.contains('coloros')) {
      return 'ColorOS may restrict BlinkKind in background. Tap Fix to enable unrestricted access.';
    } else if (m.contains('oneplus') || m.contains('oxygen')) {
      return 'OnePlus battery optimization may stop break reminders. Tap Fix to set BlinkKind to unrestricted.';
    } else if (m.contains('vivo')) {
      return 'Vivo background manager may block break reminders. Tap Fix to allow BlinkKind.';
    }
    return 'Battery optimization is blocking background break reminders. Tap Fix to whitelist BlinkKind.';
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSlide(
      offset: _visible ? Offset.zero : const Offset(0, -1),
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
      child: AnimatedOpacity(
        opacity: _visible ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 300),
        child: SafeArea(
          bottom: false,
          child: Container(
            margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFF8C00), Color(0xFFFFB347)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF8C00).withValues(alpha: 0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.battery_alert_rounded,
                  color: Colors.white,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Battery Restrictions Detected',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 13.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _subtitle(),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.92),
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: widget.onFix,
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFFB35900),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 6),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Fix',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    TextButton(
                      onPressed: widget.onDismiss,
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white70,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        'Dismiss',
                        style: TextStyle(fontSize: 11),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NotificationWarningBanner extends StatefulWidget {
  final VoidCallback onFix;

  const _NotificationWarningBanner({
    required this.onFix,
  });

  @override
  State<_NotificationWarningBanner> createState() => _NotificationWarningBannerState();
}

class _NotificationWarningBannerState extends State<_NotificationWarningBanner> {
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _visible = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSlide(
      offset: _visible ? Offset.zero : const Offset(0, -1),
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
      child: AnimatedOpacity(
        opacity: _visible ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 300),
        child: SafeArea(
          bottom: false,
          child: Container(
            margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFE53935), Color(0xFFEF5350)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFE53935).withValues(alpha: 0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Icon(
                  Icons.notifications_off_rounded,
                  color: Colors.white,
                  size: 28,
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Notifications Blocked',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 13.5,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Break reminders cannot be shown without permission. Tap Fix to enable them.',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: widget.onFix,
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFFC62828),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 6),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Fix',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
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
    );
  }
}
