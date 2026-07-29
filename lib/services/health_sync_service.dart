import '../models/hydration_intake_event.dart';

enum HealthSyncAvailability {
  unsupported,
  unavailable,
  updateRequired,
  available,
}

class HealthSyncStatus {
  final HealthSyncAvailability availability;
  final bool writeHydrationGranted;
  final String? detail;

  const HealthSyncStatus({
    required this.availability,
    required this.writeHydrationGranted,
    this.detail,
  });

  bool get canWrite =>
      availability == HealthSyncAvailability.available && writeHydrationGranted;
}

/// Platform-neutral boundary for health-store adapters.
///
/// Implementations must use [HydrationIntakeEvent.id] as the provider client
/// record ID so a retry can never create a duplicate drink.
abstract interface class HealthSyncService {
  Future<HealthSyncStatus> status();

  Future<void> upsertHydration(HydrationIntakeEvent event);

  Future<void> deleteHydration(String hydrationEventId);
}
