import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../features/timer/desktop_break_overlay.dart';
import '../models/timer_settings.dart';
import 'desktop_integration_service.dart';

enum OverlayPermissionStatus { unknown, allowed, disabled, unsupported }

enum _MediaType { music, video, unknown }

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
  /// Detection uses three layered signals on Linux:
  ///   1. `media.role` in pactl — set by the browser via the MediaSession API
  ///      (YouTube Music → "music", regular YouTube → "video")
  ///   2. `media.name` in pactl — page/track title from the browser
  ///      (e.g. "YouTube Music", "Netflix", "SoundCloud")
  ///   3. `playerctl` MPRIS — reads `xesam:url` + title from all registered
  ///      MPRIS players (reliable fallback when pactl metadata is sparse)
  ///
  /// [filter] values: `'all'` | `'music_only'` | `'video_only'`
  Future<bool> isMediaPlaying({String filter = 'all'}) async {
    if (kIsWeb) return false;
    if (defaultTargetPlatform == TargetPlatform.android) {
      if (filter == 'video_only') return false;
      try {
        final playing = await _channel.invokeMethod<bool>("isMusicActive");
        return playing ?? false;
      } catch (e) {
        return false;
      }
    } else if (defaultTargetPlatform == TargetPlatform.linux) {
      // Layer 1 + 2: pactl sink-inputs
      final pactlHit = await _checkPactlStreams(filter);
      if (pactlHit == true) return true;

      // Layer 3: playerctl MPRIS (only needed for filtered modes)
      if (filter != 'all') {
        if (await _checkPlayerctl(filter)) return true;
      }
    }
    return false;
  }

  /// Layers 1 & 2 — inspect pactl sink-inputs.
  /// Returns `true`  if a matching stream is found,
  ///         `false` if streams exist but none match the filter,
  ///         `null`  if pactl failed or no streams were present.
  Future<bool?> _checkPactlStreams(String filter) async {
    try {
      final result = await Process.run('pactl', ['list', 'sink-inputs']);
      if (result.exitCode != 0) return null;

      final inputs = (result.stdout as String).split(RegExp(r'Sink Input #\d+'));
      for (final input in inputs) {
        if (input.trim().isEmpty) continue;
        if (!input.toLowerCase().contains('corked: no')) continue;

        final lower = input.toLowerCase();
        if (_shouldIgnoreStream(lower)) continue;

        if (filter == 'all') return true;

        final role = _extractProp(input, 'media.role');
        final mediaName = _extractProp(input, 'media.name');
        final appName = _extractProp(input, 'application.name');

        final type = _classifyPactl(
          role: role, mediaName: mediaName, appName: appName, lower: lower,
        );
        if (filter == 'music_only' && type == _MediaType.music) return true;
        if (filter == 'video_only' && type == _MediaType.video) return true;
      }
      return false;
    } catch (_) {
      return null;
    }
  }

  /// Layer 3 — query MPRIS via `playerctl` for accurate browser stream info.
  Future<bool> _checkPlayerctl(String filter) async {
    try {
      final listResult = await Process.run(
        'playerctl',
        ['-a', 'status', '--format', '{{playerName}}|{{status}}'],
      );
      if (listResult.exitCode != 0) return false;

      for (final line in (listResult.stdout as String).trim().split('\n')) {
        final parts = line.split('|');
        if (parts.length < 2) continue;
        final playerName = parts[0].trim().toLowerCase();
        final status = parts[1].trim().toLowerCase();
        if (status != 'playing') continue;
        if (_shouldIgnoreStream(playerName)) continue;

        // Fetch URL + title for this player
        final metaResult = await Process.run(
          'playerctl',
          [
            '--player=$playerName', 'metadata', '--format',
            '{{xesam:url}}|{{xesam:title}}|{{mpris:artUrl}}',
          ],
        );
        if (metaResult.exitCode != 0) continue;

        final meta = (metaResult.stdout as String).trim().toLowerCase();
        final type = _classifyMpris(meta, playerName);
        if (filter == 'music_only' && type == _MediaType.music) return true;
        if (filter == 'video_only' && type == _MediaType.video) return true;
      }
    } catch (_) {
      // playerctl not installed — silently skip
    }
    return false;
  }

  // ── helpers ──────────────────────────────────────────────────────────

  String _extractProp(String block, String key) {
    final m = RegExp(
      '${RegExp.escape(key)}\\s*=\\s*"([^"]*)"',
      caseSensitive: false,
    ).firstMatch(block);
    return m?.group(1)?.toLowerCase().trim() ?? '';
  }

  bool _shouldIgnoreStream(String lower) =>
      lower.contains('eye_care_timer') ||
      lower.contains('blinkkind') ||
      lower.contains('com.jatin.eyecaretimer') ||
      lower.contains('telegram') ||
      lower.contains('discord') ||
      lower.contains('skype') ||
      lower.contains('teams');

  _MediaType _classifyPactl({
    required String role,
    required String mediaName,
    required String appName,
    required String lower,
  }) {
    // ── Layer 1: media.role (set by browser MediaSession API) ────────
    // Chrome/Firefox propagate the page's MediaSession type here:
    //   YouTube Music → "music"   |   YouTube (video) → "video"
    if (role == 'music' || role == 'a11y') return _MediaType.music;
    if (role == 'video' || role == 'movie') return _MediaType.video;

    // ── Layer 2a: media.name / lowerInput keyword matching ───────────
    // Music streaming services (checked first so "youtube music" wins
    // before the plain "youtube" video check below)
    const musicKeywords = [
      'youtube music', 'soundcloud', 'spotify', 'apple music',
      'tidal', 'deezer', 'pandora', 'amazon music',
      'jiosaavn', 'gaana', 'wynk', 'hungama',
    ];
    const videoKeywords = [
      'netflix', 'amazon prime', 'prime video', 'disney+',
      'hotstar', 'hulu', 'hbo max', 'twitch',
      'youtube',   // plain YouTube — comes after "youtube music" so no clash
      'zee5', 'sonyliv', 'voot', 'mxplayer', 'jiocinema',
    ];
    for (final kw in musicKeywords) {
      if (mediaName.contains(kw) || lower.contains(kw)) return _MediaType.music;
    }
    for (final kw in videoKeywords) {
      if (mediaName.contains(kw) || lower.contains(kw)) return _MediaType.video;
    }

    // ── Layer 2b: known standalone app names ─────────────────────────
    const musicApps = [
      'rhythmbox', 'clementine', 'amarok', 'quodlibet',
      'audacious', 'lollypop', 'cantata', 'elisa', 'strawberry',
    ];
    const videoApps = [
      'vlc', 'mpv', 'totem', 'kodi', 'mplayer',
      'celluloid', 'dragon', 'smplayer', 'parole',
    ];
    if (musicApps.any((a) => lower.contains(a))) return _MediaType.music;
    if (videoApps.any((a) => lower.contains(a))) return _MediaType.video;

    return _MediaType.unknown;
  }

  _MediaType _classifyMpris(String meta, String playerName) {
    // Music signals: xesam:url domain or player name
    const musicSignals = [
      'music.youtube.com',   // YouTube Music URL domain
      'soundcloud.com',
      'open.spotify.com',
      'music.apple.com',
      'tidal.com',
      'deezer.com',
      'pandora.com',
      'music.amazon',
      'jiosaavn.com',
      'gaana.com',
      'spotify',
      'rhythmbox', 'clementine', 'amarok', 'audacious', 'elisa', 'strawberry',
    ];
    // Video signals
    const videoSignals = [
      'youtube.com/watch',   // Regular YouTube — after music.youtube.com check
      'netflix.com',
      'primevideo.com',
      'disneyplus.com',
      'hotstar.com',
      'hulu.com',
      'hbo.com',
      'twitch.tv',
      'vlc', 'mpv', 'totem', 'celluloid',
    ];
    for (final s in musicSignals) {
      if (meta.contains(s) || playerName.contains(s)) return _MediaType.music;
    }
    for (final s in videoSignals) {
      if (meta.contains(s) || playerName.contains(s)) return _MediaType.video;
    }
    return _MediaType.unknown;
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
