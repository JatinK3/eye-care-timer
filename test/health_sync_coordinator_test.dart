import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:eyeapptimer/models/hydration_intake_event.dart';
import 'package:eyeapptimer/services/health_sync_coordinator.dart';
import 'package:eyeapptimer/services/health_sync_service.dart';
import 'package:eyeapptimer/services/preferences_service.dart';

void main() {
  test(
    'foreground flush upserts an event once and completes its outbox item',
    () async {
      final now = DateTime.now();
      SharedPreferences.setMockInitialValues(<String, Object>{
        PreferencesService.waterGlassesDateKey: _dateKey(now),
        PreferencesService.waterGlassesTodayKey: 0,
      });
      final preferences = PreferencesService();
      await preferences.incrementWaterGlassesToday(1);
      final health = _FakeHealthSyncService();
      final coordinator = HealthSyncCoordinator(
        preferences: preferences,
        service: health,
      );

      await coordinator.flushPending();

      expect(health.upserted, hasLength(1));
      expect(await preferences.loadHealthSyncOutbox(), isEmpty);
    },
  );

  test(
    'foreground flush retains and marks an operation when the provider fails',
    () async {
      final now = DateTime.now();
      SharedPreferences.setMockInitialValues(<String, Object>{
        PreferencesService.waterGlassesDateKey: _dateKey(now),
        PreferencesService.waterGlassesTodayKey: 0,
      });
      final preferences = PreferencesService();
      await preferences.incrementWaterGlassesToday(1);
      final coordinator = HealthSyncCoordinator(
        preferences: preferences,
        service: _FakeHealthSyncService(throwOnUpsert: true),
      );

      await coordinator.flushPending();

      final operation = (await preferences.loadHealthSyncOutbox()).single;
      expect(operation.attempts, 1);
      expect(operation.lastError, contains('provider unavailable'));
    },
  );

  test('does not contact Health Connect until the user opts in', () async {
    final now = DateTime.now();
    SharedPreferences.setMockInitialValues(<String, Object>{
      PreferencesService.waterGlassesDateKey: _dateKey(now),
      PreferencesService.waterGlassesTodayKey: 0,
    });
    final preferences = PreferencesService();
    await preferences.incrementWaterGlassesToday(1);
    final health = _FakeHealthSyncService();
    final coordinator = HealthSyncCoordinator(
      preferences: preferences,
      service: health,
      isSyncEnabled: () async => false,
    );

    await coordinator.flushPending();

    expect(health.upserted, isEmpty);
    expect(await preferences.loadHealthSyncOutbox(), hasLength(1));
  });

  test(
    'flushes a water correction as a delete for the original record',
    () async {
      final now = DateTime.now();
      SharedPreferences.setMockInitialValues(<String, Object>{
        PreferencesService.waterGlassesDateKey: _dateKey(now),
        PreferencesService.waterGlassesTodayKey: 0,
      });
      final preferences = PreferencesService();
      await preferences.incrementWaterGlassesToday(1);
      final eventId = (await preferences.loadHydrationIntakeEvents()).single.id;
      await preferences.incrementWaterGlassesToday(-1);
      final health = _FakeHealthSyncService();
      final coordinator = HealthSyncCoordinator(
        preferences: preferences,
        service: health,
      );

      await coordinator.flushPending();

      expect(health.deleted, [eventId]);
      expect(await preferences.loadHealthSyncOutbox(), isEmpty);
    },
  );

  test(
    'retries the same durable operation after a temporary provider failure',
    () async {
      final now = DateTime.now();
      SharedPreferences.setMockInitialValues(<String, Object>{
        PreferencesService.waterGlassesDateKey: _dateKey(now),
        PreferencesService.waterGlassesTodayKey: 0,
      });
      final preferences = PreferencesService();
      await preferences.incrementWaterGlassesToday(1);
      final health = _FakeHealthSyncService(throwOnUpsert: true);
      final coordinator = HealthSyncCoordinator(
        preferences: preferences,
        service: health,
      );

      await coordinator.flushPending();
      health.throwOnUpsert = false;
      await coordinator.flushPending();

      expect(health.upserted, hasLength(1));
      expect(await preferences.loadHealthSyncOutbox(), isEmpty);
    },
  );
}

String _dateKey(DateTime value) =>
    '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';

class _FakeHealthSyncService implements HealthSyncService {
  bool throwOnUpsert;
  final List<HydrationIntakeEvent> upserted = <HydrationIntakeEvent>[];
  final List<String> deleted = <String>[];

  _FakeHealthSyncService({this.throwOnUpsert = false});

  @override
  Future<void> deleteHydration(String hydrationEventId) async {
    deleted.add(hydrationEventId);
  }

  @override
  Future<HealthSyncStatus> status() async => const HealthSyncStatus(
    availability: HealthSyncAvailability.available,
    writeHydrationGranted: true,
  );

  @override
  Future<void> upsertHydration(HydrationIntakeEvent event) async {
    if (throwOnUpsert) throw StateError('provider unavailable');
    upserted.add(event);
  }
}
