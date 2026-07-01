import 'dart:io';
import 'package:flutter/services.dart';

class OsFocusService {
  static final OsFocusService instance = OsFocusService._();
  OsFocusService._();

  static const MethodChannel _permissionsChannel = MethodChannel('blinkkind/permissions');

  Future<void> setDndEnabled(bool enabled) async {
    if (Platform.environment.containsKey('FLUTTER_TEST')) return;
    if (Platform.isLinux) {
      try {
        // Toggle GNOME notifications show-banners setting:
        // show-banners false = DND (banners hidden)
        // show-banners true = Normal (banners shown)
        final value = enabled ? 'false' : 'true';
        await Process.run('gsettings', [
          'set',
          'org.gnome.desktop.notifications',
          'show-banners',
          value,
        ]);
      } catch (e) {
        // Catch platform exceptions silently so non-GNOME systems do not crash.
      }
    } else if (Platform.isAndroid) {
      try {
        await _permissionsChannel.invokeMethod('setDndEnabled', enabled);
      } catch (_) {
        // Catch platform exceptions silently.
      }
    }
  }
}
