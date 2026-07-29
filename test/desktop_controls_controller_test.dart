import 'package:flutter_test/flutter_test.dart';

import 'package:eyeapptimer/services/desktop_controls_controller.dart';

void main() {
  test('keeps the latest timer snapshot for a late tray subscriber', () {
    final state = DesktopTimerState(
      isRunning: true,
      isPaused: false,
      isBreak: false,
      remainingSeconds: 179,
    );

    DesktopControlsController.instance.updateState(state);

    expect(DesktopControlsController.instance.latestState, same(state));
  });
}
