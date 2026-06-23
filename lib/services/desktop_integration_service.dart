import 'dart:async';
import 'dart:io';
import 'dart:ui' show Rect;
import 'package:flutter/foundation.dart';
import 'package:launch_at_startup/launch_at_startup.dart';
import 'package:screen_retriever/screen_retriever.dart';
import 'package:system_tray/system_tray.dart';
import 'package:window_manager/window_manager.dart';
import '../features/timer/display_layout.dart';
import 'desktop_controls_controller.dart';

class DesktopIntegrationService extends WindowListener {
  DesktopIntegrationService._privateConstructor();
  static final DesktopIntegrationService instance =
      DesktopIntegrationService._privateConstructor();

  final SystemTray _systemTray = SystemTray();
  final Menu _menu = Menu();
  bool _isInitialized = false;
  bool _isBreakActive = false;
  bool? _lastIsBreak;
  bool? _lastIsRunning;
  bool? _lastIsPaused;
  bool? _lastAllowPostpone;
  int? _lastPostponeDurationMinutes;

  List<Rect> _breakMonitorRects = const [];
  Rect? _savedWindowBounds;
  bool _spanningActive = false;

  /// Per-monitor rectangles (in the overlay window's local coordinate space) to
  /// replicate break content onto every screen while a multi-monitor break is
  /// active. Empty when the overlay is a single-monitor fullscreen window.
  List<Rect> get breakMonitorRects => List.unmodifiable(_breakMonitorRects);

  bool get isSupported =>
      !kIsWeb &&
      (Platform.isLinux || Platform.isMacOS || Platform.isWindows) &&
      !Platform.environment.containsKey('FLUTTER_TEST');

  Future<void> initialize() async {
    if (!isSupported || _isInitialized) return;

    // 1. Initialize Window Manager
    await windowManager.ensureInitialized();
    windowManager.addListener(this);
    await windowManager.setPreventClose(true);
    await windowManager.setTitle('BlinkKind');

    // 2. Initialize System Tray
    await _initTray();

    // 3. Initialize Launch at Startup
    _initLaunchAtStartup();

    // 4. Listen to state changes to update the tray menu dynamically
    DesktopControlsController.instance.states.listen((state) {
      unawaited(_updateTrayMenu(state));
    });

    _isInitialized = true;
  }

  Future<void> _initTray() async {
    String iconPath;
    if (Platform.isWindows) {
      iconPath = 'assets/app_icon.ico';
    } else {
      iconPath = 'assets/app_icon.png';
    }

    try {
      await _systemTray.initSystemTray(
        title: 'BlinkKind',
        iconPath: iconPath,
        toolTip: 'BlinkKind Eye Care Timer',
      );

      _systemTray.registerSystemTrayEventHandler((eventName) {
        if (eventName == 'click' || eventName == 'double-click') {
          unawaited(_showWindow());
        }
      });

      // Build initial menu
      await _menu.buildFrom([
        MenuItemLabel(label: 'Show BlinkKind', onClicked: (_) => _showWindow()),
        MenuSeparator(),
        MenuItemLabel(label: 'Exit', onClicked: (_) => _quitApp()),
      ]);

      await _systemTray.setContextMenu(_menu);
    } catch (e) {
      debugPrint('System tray initialization failed: $e');
    }
  }

  void _initLaunchAtStartup() {
    try {
      launchAtStartup.setup(
        appName: 'BlinkKind',
        appPath: Platform.resolvedExecutable,
      );
    } catch (e) {
      debugPrint('LaunchAtStartup setup failed: $e');
    }
  }

  Future<void> setLaunchAtStartup(bool enabled) async {
    if (!isSupported) return;
    try {
      if (enabled) {
        await launchAtStartup.enable();
      } else {
        await launchAtStartup.disable();
      }
    } catch (e) {
      debugPrint('Failed to set LaunchAtStartup: $e');
    }
  }

  Future<bool> isLaunchAtStartupEnabled() async {
    if (!isSupported) return false;
    try {
      return await launchAtStartup.isEnabled();
    } catch (e) {
      debugPrint('Failed to query LaunchAtStartup status: $e');
      return false;
    }
  }

  Future<void> _updateTrayMenu(DesktopTimerState state) async {
    if (!isSupported) return;
    _isBreakActive = state.isBreak;
    try {
      // 1. Update the system tray tooltip dynamically with time remaining.
      // This is updated on hover and does NOT recreate the context menu structure,
      // avoiding any hover flickering issues.
      final minutes = state.remainingSeconds ~/ 60;
      final seconds = state.remainingSeconds % 60;
      final timeStr = '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
      
      String tooltipText;
      if (state.isBreak) {
        tooltipText = 'BlinkKind - On a Break ($timeStr remaining)';
      } else if (state.isRunning) {
        if (state.isPaused) {
          tooltipText = 'BlinkKind - Paused ($timeStr remaining)';
        } else {
          tooltipText = 'BlinkKind - Next break in $timeStr';
        }
      } else {
        tooltipText = 'BlinkKind - Timer Idle';
      }
      unawaited(_systemTray.setToolTip(tooltipText));

      // 2. Only rebuild the context menu when the control states actually change.
      if (_lastIsBreak == state.isBreak &&
          _lastIsRunning == state.isRunning &&
          _lastIsPaused == state.isPaused &&
          _lastAllowPostpone == state.allowPostpone &&
          _lastPostponeDurationMinutes == state.postponeDurationMinutes) {
        return;
      }

      _lastIsBreak = state.isBreak;
      _lastIsRunning = state.isRunning;
      _lastIsPaused = state.isPaused;
      _lastAllowPostpone = state.allowPostpone;
      _lastPostponeDurationMinutes = state.postponeDurationMinutes;

      final List<MenuItemBase> items = [
        MenuItemLabel(label: 'Show BlinkKind', onClicked: (_) => _showWindow()),
        MenuSeparator(),
      ];

      // Add dynamic, read-only Status item
      String statusText;
      if (state.isBreak) {
        statusText = 'Status: On a Break';
      } else if (state.isRunning) {
        if (state.isPaused) {
          statusText = 'Status: Paused';
        } else {
          statusText = 'Status: Working';
        }
      } else {
        statusText = 'Status: Idle';
      }
      items.addAll([
        MenuItemLabel(label: statusText, enabled: false),
        MenuSeparator(),
      ]);

      if (state.isBreak) {
        items.addAll([
          MenuItemLabel(
            label: 'Skip Break',
            onClicked: (_) {
              DesktopControlsController.instance.triggerCommand(
                DesktopCommand.skipBreak,
              );
            },
          ),
        ]);
        if (state.allowPostpone) {
          items.addAll([
            MenuItemLabel(
              label: 'Postpone Break (${state.postponeDurationMinutes}m)',
              onClicked: (_) {
                DesktopControlsController.instance.triggerCommand(
                  DesktopCommand.postponeBreak,
                );
              },
            ),
          ]);
        }
      } else {
        if (state.isRunning && !state.isPaused) {
          items.addAll([
            MenuItemLabel(
              label: 'Take a Break Now',
              onClicked: (_) {
                DesktopControlsController.instance.triggerCommand(
                  DesktopCommand.startBreak,
                );
              },
            ),
          ]);
        }

        if (state.isRunning) {
          if (state.isPaused) {
            items.addAll([
              MenuItemLabel(
                label: 'Resume Timer',
                onClicked: (_) {
                  DesktopControlsController.instance.triggerCommand(
                    DesktopCommand.resume,
                  );
                },
              ),
            ]);
          } else {
            items.addAll([
              MenuItemLabel(
                label: 'Pause Timer',
                onClicked: (_) {
                  DesktopControlsController.instance.triggerCommand(
                    DesktopCommand.pause,
                  );
                },
              ),
            ]);
          }
        } else {
          items.addAll([
            MenuItemLabel(
              label: 'Start Timer',
              onClicked: (_) {
                DesktopControlsController.instance.triggerCommand(
                  DesktopCommand.resume,
                );
              },
            ),
          ]);
        }
      }

      items.addAll([
        MenuSeparator(),
        MenuItemLabel(label: 'Exit', onClicked: (_) => _quitApp()),
      ]);

      await _menu.buildFrom(items);
      await _systemTray.setContextMenu(_menu);
    } catch (e) {
      debugPrint('Failed to update tray menu: $e');
    }
  }

  Future<void> _showWindow() async {
    await windowManager.show();
    await windowManager.focus();
  }

  Future<void> _quitApp() async {
    windowManager.removeListener(this);
    await windowManager.destroy();
  }

  // --- WindowListener overrides ---

  @override
  void onWindowClose() async {
    final isPreventClose = await windowManager.isPreventClose();
    if (isPreventClose) {
      if (_isBreakActive) {
        await _showWindow();
        return;
      }
      await windowManager.hide();
    }
  }

  Future<void> showBreakOverlay(bool show) async {
    if (!isSupported) return;
    if (show) {
      _isBreakActive = true;
      await _enterBreakWindow();
    } else {
      _isBreakActive = false;
      await _exitBreakWindow();
    }
  }

  Future<void> _enterBreakWindow() async {
    final span = await _computeDisplaySpan();
    await windowManager.setAlwaysOnTop(true);

    if (span != null && span.isMultiMonitor && _canSpanDisplays()) {
      try {
        _savedWindowBounds = await windowManager.getBounds();
        await windowManager.setBounds(span.windowBounds);
        _breakMonitorRects = span.monitorRects;
        _spanningActive = true;
        // Cosmetic only: hide the window chrome over the break. Best-effort so
        // a platform without title-bar control still gets a covering overlay.
        try {
          await windowManager.setSkipTaskbar(true);
          await windowManager.setTitleBarStyle(TitleBarStyle.hidden);
        } catch (e) {
          debugPrint('Could not hide window chrome for break overlay: $e');
        }
        await windowManager.show();
        await windowManager.focus();
        return;
      } catch (e) {
        debugPrint(
          'Multi-monitor break span failed; falling back to fullscreen: $e',
        );
        _spanningActive = false;
        _breakMonitorRects = const [];
        _savedWindowBounds = null;
      }
    }

    // Single-monitor, Wayland, or fallback path: fullscreen on the current
    // monitor (original behavior).
    _breakMonitorRects = const [];
    await windowManager.setFullScreen(true);
    await windowManager.show();
    await windowManager.focus();
  }

  Future<void> _exitBreakWindow() async {
    if (_spanningActive) {
      _spanningActive = false;
      try {
        await windowManager.setTitleBarStyle(TitleBarStyle.normal);
        await windowManager.setSkipTaskbar(false);
        final saved = _savedWindowBounds;
        if (saved != null) {
          await windowManager.setBounds(saved);
        }
      } catch (e) {
        debugPrint('Failed to restore window after break overlay: $e');
      }
      _savedWindowBounds = null;
    } else {
      await windowManager.setFullScreen(false);
    }
    _breakMonitorRects = const [];
    await windowManager.setAlwaysOnTop(false);
  }

  Future<DisplaySpan?> _computeDisplaySpan() async {
    try {
      final displays = await screenRetriever.getAllDisplays();
      final bounds = <DisplayBounds>[];
      for (final d in displays) {
        final position = d.visiblePosition;
        if (position == null) continue;
        final size = d.visibleSize ?? d.size;
        bounds.add(
          DisplayBounds(
            left: position.dx,
            top: position.dy,
            width: size.width,
            height: size.height,
          ),
        );
      }
      return computeDisplaySpan(bounds);
    } catch (e) {
      debugPrint('Failed to enumerate displays for break overlay: $e');
      return null;
    }
  }

  bool _canSpanDisplays() {
    // Wayland does not let a client position itself at absolute global
    // coordinates, so a single window cannot reliably cover other monitors.
    // Fall back to single-monitor fullscreen there.
    if (Platform.isLinux) {
      final sessionType = Platform.environment['XDG_SESSION_TYPE']
          ?.toLowerCase();
      final waylandDisplay = Platform.environment['WAYLAND_DISPLAY'];
      final isWayland =
          sessionType == 'wayland' ||
          (waylandDisplay != null && waylandDisplay.isNotEmpty);
      if (isWayland) return false;
    }
    return true;
  }
}
