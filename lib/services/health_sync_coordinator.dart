import '../models/health_sync_outbox_operation.dart';
import 'health_sync_service.dart';
import 'preferences_service.dart';

/// Flushes local health changes only while the foreground app asks it to.
/// Notification/background isolates only write the local event and outbox.
class HealthSyncCoordinator {
  final PreferencesService _preferences;
  final HealthSyncService _service;
  final Future<bool> Function()? _isSyncEnabled;
  bool _isFlushing = false;

  HealthSyncCoordinator({
    required PreferencesService preferences,
    required HealthSyncService service,
    Future<bool> Function()? isSyncEnabled,
  }) : _preferences = preferences,
       _service = service,
       _isSyncEnabled = isSyncEnabled;

  Future<void> flushPending() async {
    if (_isFlushing) return;
    _isFlushing = true;
    try {
      if (_isSyncEnabled != null && !await _isSyncEnabled()) return;
      final status = await _service.status();
      if (!status.canWrite) return;

      final events = await _preferences.loadHydrationIntakeEvents();
      final eventsById = {for (final event in events) event.id: event};
      final operations = await _preferences.loadHealthSyncOutbox();
      for (final operation in operations) {
        try {
          switch (operation.type) {
            case HealthSyncOperationType.upsertHydration:
              final event = eventsById[operation.hydrationEventId];
              if (event == null || event.isDeleted) {
                await _preferences.completeHealthSyncOperation(operation.id);
              } else {
                await _service.upsertHydration(event);
                await _preferences.completeHealthSyncOperation(operation.id);
              }
            case HealthSyncOperationType.deleteHydration:
              await _service.deleteHydration(operation.hydrationEventId);
              await _preferences.completeHealthSyncOperation(operation.id);
          }
        } on Object catch (error) {
          await _preferences.recordHealthSyncFailure(operation.id, error);
          // A provider failure usually affects subsequent operations too; keep
          // their order for the next foreground retry.
          break;
        }
      }
    } finally {
      _isFlushing = false;
    }
  }
}
