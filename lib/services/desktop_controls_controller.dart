import 'dart:async';

enum DesktopCommand {
  pause,
  resume,
  // Marks the active break as using the desktop wellness coach. The countdown
  // continues normally and is held only when it reaches its natural end.
  holdBreakForCoach,
  completeBreak,
  skipBreak,
  postponeBreak,
  startBreak,
  // Emitted when the main window is shown/focused again from the tray so the
  // timer page can re-sync its display with the wall clock (on desktop the
  // countdown animation pauses while the window is hidden).
  windowResumed,
  snooze1Hour,
  snoozeUntilTomorrow,
  cancelSnooze,
  openSettings,
  showDashboard,
  // Emitted when the user taps the "I blinked!" notification action so that
  // TimerHomePage can play the confirmation chime even when the notification
  // fires while the app is backgrounded.
  playChime,
  // Emitted when the user taps the "Log a glass" water-reminder notification
  // action while the app is alive, so TimerHomePage records a glass of water.
  logWaterGlass,
  toggleSoundscape,
}

class DesktopTimerState {
  final bool isRunning;
  final bool isPaused;
  final bool isBreak;
  final int remainingSeconds;
  final bool allowSkip;
  final bool allowPostpone;
  final int postponeDurationMinutes;
  final int initialDurationSeconds;
  final bool isBlinkNudging;
  final bool isSnoozed;
  final int snoozeRemainingMinutes;
  final DateTime? nextBreakAt;
  final bool isLongBreak;
  final bool soundscapeEnabled;
  final int waterGlassesToday;
  final int waterGlassSizeMl;
  final int waterDailyGoalGlasses;

  DesktopTimerState({
    required this.isRunning,
    required this.isPaused,
    required this.isBreak,
    required this.remainingSeconds,
    this.allowSkip = true,
    this.allowPostpone = true,
    this.postponeDurationMinutes = 2,
    this.initialDurationSeconds = 1200,
    this.isBlinkNudging = false,
    this.isSnoozed = false,
    this.snoozeRemainingMinutes = 0,
    this.nextBreakAt,
    this.isLongBreak = false,
    this.soundscapeEnabled = false,
    this.waterGlassesToday = 0,
    this.waterGlassSizeMl = 250,
    this.waterDailyGoalGlasses = 8,
  });
}

class DesktopControlsController {
  DesktopControlsController._privateConstructor();
  static final DesktopControlsController instance =
      DesktopControlsController._privateConstructor();

  final _commandController = StreamController<DesktopCommand>.broadcast();
  final _stateController = StreamController<DesktopTimerState>.broadcast();
  DesktopTimerState? _latestState;

  Stream<DesktopCommand> get commands => _commandController.stream;
  Stream<DesktopTimerState> get states => _stateController.stream;
  DesktopTimerState? get latestState => _latestState;

  void triggerCommand(DesktopCommand command) {
    _commandController.add(command);
  }

  void updateState(DesktopTimerState state) {
    _latestState = state;
    _stateController.add(state);
  }
}
