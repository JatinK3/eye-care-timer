import 'dart:async';

enum DesktopCommand { pause, resume, skipBreak, postponeBreak, startBreak }

class DesktopTimerState {
  final bool isRunning;
  final bool isPaused;
  final bool isBreak;
  final int remainingSeconds;
  final bool allowPostpone;
  final int postponeDurationMinutes;

  DesktopTimerState({
    required this.isRunning,
    required this.isPaused,
    required this.isBreak,
    required this.remainingSeconds,
    this.allowPostpone = true,
    this.postponeDurationMinutes = 2,
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
