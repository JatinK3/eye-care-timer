import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:eyeapptimer/models/pending_break.dart';
import 'package:eyeapptimer/models/timer_session.dart';
import 'package:eyeapptimer/services/preferences_service.dart';

void main() {
  test('persists pending-break and automatic-pause session state', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final service = PreferencesService();
    const session = TimerSession(
      isActive: true,
      isBreak: false,
      isPaused: false,
      initialDurationSeconds: 120,
      remainingSeconds: 90,
      phaseStartedAt: null,
      phaseEndsAt: null,
      pendingBreak: PendingBreak(
        durationSeconds: 900,
        reason: PendingBreakReason.skippedLong,
      ),
      automaticPauseOverride: true,
      breakDebtSeconds: 45,
    );

    await service.saveSession(session);
    final restored = await service.loadSession();

    expect(restored.pendingBreak?.durationSeconds, 900);
    expect(restored.pendingBreak?.reason, PendingBreakReason.skippedLong);
    expect(restored.automaticPauseOverride, isTrue);
    expect(restored.breakDebtSeconds, 45);
  });
}
