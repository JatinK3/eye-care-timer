import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:eyeapptimer/models/pending_break.dart';
import 'package:eyeapptimer/models/timer_session.dart';
import 'package:eyeapptimer/models/health_sync_outbox_operation.dart';
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

  test(
    'records timestamped hydration events and a retryable sync outbox',
    () async {
      final now = DateTime.now();
      final today =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      SharedPreferences.setMockInitialValues(<String, Object>{
        PreferencesService.waterGlassesDateKey: today,
        PreferencesService.waterGlassesTodayKey: 0,
        PreferencesService.waterGlassSizeMlKey: 300,
      });
      final service = PreferencesService();

      expect(await service.incrementWaterGlassesToday(1), 1);
      final events = await service.loadHydrationIntakeEvents();
      final outbox = await service.loadHealthSyncOutbox();

      expect(events, hasLength(1));
      expect(events.single.volumeMl, 300);
      expect(events.single.isDeleted, isFalse);
      expect(
        events.single.recordedAt.isAfter(
          now.subtract(const Duration(seconds: 1)),
        ),
        isTrue,
      );
      expect(outbox, hasLength(1));
      expect(outbox.single.hydrationEventId, events.single.id);
      expect(outbox.single.type, HealthSyncOperationType.upsertHydration);
    },
  );

  test(
    'undo replaces a pending hydration write with a delete operation',
    () async {
      final now = DateTime.now();
      final today =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      SharedPreferences.setMockInitialValues(<String, Object>{
        PreferencesService.waterGlassesDateKey: today,
        PreferencesService.waterGlassesTodayKey: 0,
      });
      final service = PreferencesService();

      await service.incrementWaterGlassesToday(1);
      final original = (await service.loadHydrationIntakeEvents()).single;
      await service.incrementWaterGlassesToday(-1);

      final event = (await service.loadHydrationIntakeEvents()).single;
      final outbox = await service.loadHealthSyncOutbox();
      expect(event.id, original.id);
      expect(event.isDeleted, isTrue);
      expect(event.version, 1);
      expect(outbox, hasLength(1));
      expect(outbox.single.type, HealthSyncOperationType.deleteHydration);
      expect(outbox.single.hydrationEventId, original.id);
    },
  );
}
