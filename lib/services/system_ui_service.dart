import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class SystemUiService {
  static const MethodChannel _channel = MethodChannel('blinkkind/system_ui');

  const SystemUiService();

  Future<void> setFocusModeEnabled(bool enabled) async {
    if (enabled) {
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        await SystemChrome.setEnabledSystemUIMode(
          SystemUiMode.manual,
          overlays: const [],
        );
      } else {
        await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      }
    } else {
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }

    if (defaultTargetPlatform != TargetPlatform.iOS) {
      return;
    }

    try {
      await _channel.invokeMethod<void>('setImmersive', enabled);
    } on MissingPluginException {
      // Allows widget tests and unsupported runners to use the Flutter fallback.
    } on PlatformException catch (error) {
      debugPrint('Could not update iOS immersive system UI: $error');
    }
  }
}
