import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../models/hydration_intake_event.dart';
import 'health_sync_service.dart';

/// Android Health Connect adapter. The caller presents its own disclosure
/// before requesting the minimum WRITE_HYDRATION permission.
class HealthConnectSyncService implements HealthSyncService {
  static const MethodChannel _channel = MethodChannel(
    'blinkkind/health_connect',
  );

  @override
  Future<HealthSyncStatus> status() async {
    if (kIsWeb || !Platform.isAndroid) {
      return const HealthSyncStatus(
        availability: HealthSyncAvailability.unsupported,
        writeHydrationGranted: false,
      );
    }

    final result = await _channel.invokeMapMethod<String, dynamic>('getStatus');
    final availability = switch (result?['availability']) {
      'available' => HealthSyncAvailability.available,
      'updateRequired' => HealthSyncAvailability.updateRequired,
      'unavailable' => HealthSyncAvailability.unavailable,
      _ => HealthSyncAvailability.unsupported,
    };
    return HealthSyncStatus(
      availability: availability,
      writeHydrationGranted: result?['writeHydrationGranted'] == true,
      detail: result?['detail'] as String?,
    );
  }

  @override
  Future<void> upsertHydration(HydrationIntakeEvent event) async {
    await _channel.invokeMethod<void>('upsertHydration', <String, Object>{
      'id': event.id,
      'version': event.version,
      'recordedAt': event.recordedAt.millisecondsSinceEpoch,
      'volumeMl': event.volumeMl,
    });
  }

  @override
  Future<void> deleteHydration(String hydrationEventId) async {
    await _channel.invokeMethod<void>('deleteHydration', <String, Object>{
      'id': hydrationEventId,
    });
  }

  Future<bool> requestWriteHydrationPermission() async {
    if (kIsWeb || !Platform.isAndroid) return false;
    return await _channel.invokeMethod<bool>(
          'requestWriteHydrationPermission',
        ) ??
        false;
  }

  Future<bool> openManageAccess() async {
    if (kIsWeb || !Platform.isAndroid) return false;
    return await _channel.invokeMethod<bool>('openManageAccess') ?? false;
  }
}
