import 'dart:io';

class OsFocusService {
  static final OsFocusService instance = OsFocusService._();
  OsFocusService._();

  Future<void> setDndEnabled(bool enabled) async {
    if (!Platform.isLinux) return;
    if (Platform.environment.containsKey('FLUTTER_TEST')) return;
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
  }
}
