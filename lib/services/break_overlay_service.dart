import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../features/timer/desktop_break_overlay.dart';
import '../models/timer_settings.dart';
import 'desktop_integration_service.dart';

enum OverlayPermissionStatus { unknown, allowed, disabled, unsupported }

class BreakOverlayService {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static const MethodChannel _channel = MethodChannel(
    "blinkkind/break_overlay",
  );

  Route? _activeRoute;

  bool get _isSupported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  bool get _isSupportedOnDesktop =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.linux ||
          defaultTargetPlatform == TargetPlatform.macOS ||
          defaultTargetPlatform == TargetPlatform.windows);

  Future<OverlayPermissionStatus> permissionStatus() async {
    if (_isSupportedOnDesktop) return OverlayPermissionStatus.allowed;
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

  Future<bool> openPermissionSettings() async {
    if (_isSupportedOnDesktop) return true;
    return _invokeBoolean("openOverlayPermissionSettings");
  }

  Future<bool> showPreview({String breakVisualizerStyle = 'Breathing'}) async {
    final bool isAppInForeground = WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;

    if (_isSupportedOnDesktop) {
      return showBreakOverlay(
        durationSeconds: 10,
        breakMode: BreakMode.gentle,
        breakVisualizerStyle: breakVisualizerStyle,
      );
    }

    if (isAppInForeground) {
      _pushBreakOverlayRoute(10, BreakMode.gentle, breakVisualizerStyle);
      return true;
    }
    return _invokeBoolean("showOverlayPreview");
  }

  Future<bool> stopPreview() async {
    final bool isAppInForeground = WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;

    if (_isSupportedOnDesktop || isAppInForeground) {
      return stopBreakOverlay();
    }
    return _invokeBoolean("stopOverlayPreview");
  }

  Future<bool> showBreakOverlay({
    required int durationSeconds,
    required BreakMode breakMode,
    String breakVisualizerStyle = 'Breathing',
  }) async {
    final bool isAppInForeground = WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;

    if (_isSupportedOnDesktop) {
      await DesktopIntegrationService.instance.showBreakOverlay(true);
      _pushBreakOverlayRoute(durationSeconds, breakMode, breakVisualizerStyle);
      return true;
    }

    if (isAppInForeground) {
      unawaited(_invokeBoolean("stopBreakOverlay"));
      return true;
    }

    if (!_isSupported) return false;
    try {
      return await _channel.invokeMethod<bool>("showBreakOverlay", {
            "durationSeconds": durationSeconds,
            "breakMode": breakMode.name,
          }) ??
          false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  Future<bool> stopBreakOverlay() async {
    if (_isSupportedOnDesktop) {
      await DesktopIntegrationService.instance.showBreakOverlay(false);
      _popBreakOverlayRoute();
      return true;
    }
    _popBreakOverlayRoute();
    return _invokeBoolean("stopBreakOverlay");
  }

  void _pushBreakOverlayRoute(
    int durationSeconds,
    BreakMode breakMode,
    String breakVisualizerStyle,
  ) {
    final navigator = navigatorKey.currentState;
    if (navigator == null) return;

    if (_activeRoute != null) {
      return;
    }

    final monitorRects = DesktopIntegrationService.instance.breakMonitorRects;

    _activeRoute = PageRouteBuilder<void>(
      opaque: true,
      transitionDuration: Duration.zero,
      reverseTransitionDuration: Duration.zero,
      pageBuilder: (context, animation, secondaryAnimation) {
        return DesktopBreakOverlay(
          initialDurationSeconds: durationSeconds,
          breakMode: breakMode,
          monitorRects: monitorRects,
          breakVisualizerStyle: breakVisualizerStyle,
          onDismiss: () {
            unawaited(stopBreakOverlay());
          },
        );
      },
      transitionsBuilder: (context, animation, secondaryAnimation, child) => child,
    );

    navigator.push(_activeRoute!);
  }

  void _popBreakOverlayRoute() {
    final navigator = navigatorKey.currentState;
    if (navigator != null && _activeRoute != null) {
      navigator.removeRoute(_activeRoute!);
      _activeRoute = null;
    }
  }

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
