import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

enum UsageAccessStatus { unknown, allowed, disabled, unsupported }

/// Exposes checks and deep-link actions for special Android permissions that
/// cannot be granted at runtime (e.g. PACKAGE_USAGE_STATS for Smart Idle).
class PermissionsService {
  static const MethodChannel _channel = MethodChannel('blinkkind/permissions');

  static bool get _isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// Returns whether the user has granted Usage Access to this app.
  /// On non-Android platforms always returns [UsageAccessStatus.unsupported].
  Future<UsageAccessStatus> usageAccessStatus() async {
    if (!_isAndroid) return UsageAccessStatus.unsupported;
    try {
      final granted = await _channel.invokeMethod<bool>(
        'usageAccessPermissionStatus',
      );
      if (granted == null) return UsageAccessStatus.unknown;
      return granted ? UsageAccessStatus.allowed : UsageAccessStatus.disabled;
    } on PlatformException {
      return UsageAccessStatus.unknown;
    } on MissingPluginException {
      return UsageAccessStatus.unsupported;
    }
  }

  /// Opens the system Usage Access settings screen so the user can grant access.
  Future<void> openUsageAccessSettings() async {
    if (!_isAndroid) return;
    try {
      await _channel.invokeMethod<bool>('openUsageAccessSettings');
    } on PlatformException catch (e) {
      debugPrint('Could not open usage access settings: $e');
    } on MissingPluginException {
      // no-op on platforms without the channel
    }
  }
}
