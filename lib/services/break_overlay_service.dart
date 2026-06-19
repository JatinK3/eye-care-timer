import "package:flutter/foundation.dart";
import "package:flutter/services.dart";

enum OverlayPermissionStatus { unknown, allowed, disabled, unsupported }

class BreakOverlayService {
  static const MethodChannel _channel = MethodChannel(
    "blinkkind/break_overlay",
  );

  bool get _isSupported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  Future<OverlayPermissionStatus> permissionStatus() async {
    if (!_isSupported) return OverlayPermissionStatus.unsupported;
    try {
      final allowed = await _channel.invokeMethod<bool>(
        "overlayPermissionStatus",
      );
      if (allowed == null) return OverlayPermissionStatus.unknown;
      return allowed
          ? OverlayPermissionStatus.allowed
          : OverlayPermissionStatus.disabled;
    } on PlatformException {
      return OverlayPermissionStatus.unknown;
    } on MissingPluginException {
      return OverlayPermissionStatus.unsupported;
    }
  }

  Future<bool> openPermissionSettings() =>
      _invokeBoolean("openOverlayPermissionSettings");

  Future<bool> showPreview() => _invokeBoolean("showOverlayPreview");

  Future<bool> stopPreview() => _invokeBoolean("stopOverlayPreview");

  Future<bool> _invokeBoolean(String method) async {
    if (!_isSupported) return false;
    try {
      return await _channel.invokeMethod<bool>(method) ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }
}
