import 'dart:async';

enum DesktopCommand {
  pause,
  resume,
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
}

class DesktopTimerState {
  final bool isRunning;
  final bool isPaused;
  final bool isBreak;
  final int remainingSeconds;
  final bool allowPostpone;
  final int postponeDurationMinutes;
  final int initialDurationSeconds;
  final bool isBlinkNudging;
  final bool isSnoozed;
  final int snoozeRemainingMinutes;
  final DateTime? nextBreakAt;
  final bool isLongBreak;

  DesktopTimerState({
    required this.isRunning,
    required this.isPaused,
    required this.isBreak,
    required this.remainingSeconds,
    this.allowPostpone = true,
    this.postponeDurationMinutes = 2,
    this.initialDurationSeconds = 1200,
    this.isBlinkNudging = false,
    this.isSnoozed = false,
    this.snoozeRemainingMinutes = 0,
    this.nextBreakAt,
    this.isLongBreak = false,
  });
}

class DesktopControlsController {
  DesktopControlsController._privateConstructor();
  static final DesktopControlsController instance =
      DesktopControlsController._privateConstructor();

  final _commandController = StreamController<DesktopCommand>.broadcast();
  final _stateController = StreamController<DesktopTimerState>.broadcast();

  Stream<DesktopCommand> get commands => _commandController.stream;
  Stream<DesktopTimerState> get states => _stateController.stream;

  void triggerCommand(DesktopCommand command) {
    _commandController.add(command);
  }

  void updateState(DesktopTimerState state) {
    _stateController.add(state);
  }
}
