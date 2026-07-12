import 'dart:async';
import 'dart:io';
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

  Future<bool> showPreview({
    String breakVisualizerStyle = 'Breathing',
    bool showClock = true,
    bool showTips = true,
    bool showProgress = true,
    String customMessage = '',
  }) async {
    final bool isAppInForeground =
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;

    if (_isSupportedOnDesktop) {
      return showBreakOverlay(
        durationSeconds: 10,
        breakMode: BreakMode.gentle,
        breakVisualizerStyle: breakVisualizerStyle,
        showClock: showClock,
        showTips: showTips,
        showProgress: showProgress,
        customMessage: customMessage,
        isPreview: true,
      );
    }

    if (isAppInForeground) {
      _pushBreakOverlayRoute(
        10,
        BreakMode.gentle,
        breakVisualizerStyle,
        showClock: showClock,
        showTips: showTips,
        showProgress: showProgress,
        customMessage: customMessage,
        isPreview: true,
      );
      return true;
    }
    return _invokeBoolean("showOverlayPreview");
  }

  Future<bool> stopPreview() async {
    final bool isAppInForeground =
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;

    if (_isSupportedOnDesktop || isAppInForeground) {
      return stopBreakOverlay();
    }
    return _invokeBoolean("stopOverlayPreview");
  }

  Future<bool> showBreakOverlay({
    required int durationSeconds,
    required BreakMode breakMode,
    String breakVisualizerStyle = 'Breathing',
    String? aiQuote,
    bool showClock = true,
    bool showTips = true,
    bool showProgress = true,
    String customMessage = '',
    bool isPreview = false,
    bool allowSkip = true,
    bool allowPostpone = true,
    int postponeDurationSeconds = 120,
  }) async {
    final bool isAppInForeground =
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;

    if (_isSupportedOnDesktop) {
      await DesktopIntegrationService.instance.showBreakOverlay(true);
      _pushBreakOverlayRoute(
        durationSeconds,
        breakMode,
        breakVisualizerStyle,
        aiQuote: aiQuote,
        showClock: showClock,
        showTips: showTips,
        showProgress: showProgress,
        customMessage: customMessage,
        isPreview: isPreview,
        allowSkip: allowSkip,
        allowPostpone: allowPostpone,
      );
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
            "showClock": showClock,
            "showTips": showTips,
            "showProgress": showProgress,
            "customMessage": customMessage,
            "allowSkip": allowSkip,
            "allowPostpone": allowPostpone,
            "postponeDurationSeconds": postponeDurationSeconds,
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
    String breakVisualizerStyle, {
    String? aiQuote,
    bool showClock = true,
    bool showTips = true,
    bool showProgress = true,
    String customMessage = '',
    bool isPreview = false,
    bool allowSkip = true,
    bool allowPostpone = true,
  }) {
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
          aiQuote: aiQuote,
          showClock: showClock,
          showTips: showTips,
          showProgress: showProgress,
          customMessage: customMessage,
          isPreview: isPreview,
          allowSkip: allowSkip,
          allowPostpone: allowPostpone,
          onDismiss: () {
            unawaited(stopBreakOverlay());
          },
        );
      },
      transitionsBuilder: (context, animation, secondaryAnimation, child) =>
          child,
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

  /// Returns whether relevant media is currently playing.
  ///
  /// [filter] controls which stream types trigger an auto-pause:
  ///   - `'all'`        → any audio stream (default)
  ///   - `'music_only'` → only streams whose media.role is 'music' or whose
  ///                       app is a known music player (Spotify, Rhythmbox, …)
  ///   - `'video_only'` → only streams whose media.role is 'video' or whose
  ///                       app is a known video player / browser playing video
  Future<bool> isMediaPlaying({String filter = 'all'}) async {
    if (kIsWeb) return false;
    if (defaultTargetPlatform == TargetPlatform.android) {
      // Android AudioManager.isMusicActive() covers all audio; we can't
      // reliably distinguish video-only streams there, so treat music_only
      // and all the same, and return false for video_only.
      if (filter == 'video_only') return false;
      try {
        final playing = await _channel.invokeMethod<bool>("isMusicActive");
        return playing ?? false;
      } catch (e) {
        return false;
      }
    } else if (defaultTargetPlatform == TargetPlatform.linux) {
      try {
        final result = await Process.run('pactl', ['list', 'sink-inputs']);
        if (result.exitCode == 0) {
          final output = result.stdout as String;
          // Split by "Sink Input #" to analyse each stream independently
          final inputs = output.split(RegExp(r'Sink Input #\d+'));
          for (final input in inputs) {
            if (input.trim().isEmpty) continue;

            // Only consider active (uncorked) streams
            final isUncorked = input.toLowerCase().contains('corked: no');
            if (!isUncorked) continue;

            final lowerInput = input.toLowerCase();

            // Ignore our own app and persistent comms tools
            final shouldIgnore =
                lowerInput.contains('eye_care_timer') ||
                lowerInput.contains('blinkkind') ||
                lowerInput.contains('com.jatin.eyecaretimer') ||
                lowerInput.contains('telegram') ||
                lowerInput.contains('discord') ||
                lowerInput.contains('skype') ||
                lowerInput.contains('teams');
            if (shouldIgnore) continue;

            // If 'all', any non-ignored active stream counts.
            if (filter == 'all') return true;

            // --- Classify the stream ----------------------------------------
            // Extract media.role if present  (e.g.  media.role = "music")
            final roleMatch = RegExp(
              r'media\.role\s*=\s*"([^"]+)"',
              caseSensitive: false,
            ).firstMatch(input);
            final role = roleMatch?.group(1)?.toLowerCase() ?? '';

            // Known video-player app-name keywords
            const videoApps = [
              'vlc', 'mpv', 'totem', 'kodi', 'mplayer', 'gnome-video',
              'celluloid', 'dragon', 'smplayer',
            ];
            // Known music-player app-name keywords
            const musicApps = [
              'spotify', 'rhythmbox', 'clementine', 'amarok', 'quodlibet',
              'audacious', 'lollypop', 'cantata', 'elisa', 'strawberry',
            ];

            final isVideoRole = role == 'video' || role == 'movie';
            final isMusicRole = role == 'music' || role == 'a11y';
            final isVideoApp = videoApps.any((a) => lowerInput.contains(a));
            final isMusicApp = musicApps.any((a) => lowerInput.contains(a));

            // Browser streams (chrome, firefox, …) carrying video will often
            // report media.role = "video"; music streams report "music" or nothing.
            if (filter == 'video_only') {
              if (isVideoRole || isVideoApp) return true;
              // Browsers without a role tag are treated as video by default
              // because they most commonly play video content.
              final isBrowser = lowerInput.contains('chrome') ||
                  lowerInput.contains('chromium') ||
                  lowerInput.contains('firefox') ||
                  lowerInput.contains('brave') ||
                  lowerInput.contains('opera') ||
                  lowerInput.contains('vivaldi') ||
                  lowerInput.contains('edge');
              if (isBrowser && !isMusicRole) return true;
            } else if (filter == 'music_only') {
              if (isMusicRole || isMusicApp) return true;
            }
            // ----------------------------------------------------------------
          }
        }
      } catch (e) {
        // pactl not available on this system
      }
    }
    return false;
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
