import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:launch_at_startup/launch_at_startup.dart';
import 'package:screen_retriever/screen_retriever.dart';
import 'package:system_tray/system_tray.dart';
import 'package:flutter/services.dart';
import 'package:window_manager/window_manager.dart';
import 'desktop_controls_controller.dart';

class DesktopIntegrationService extends WindowListener {
  DesktopIntegrationService._privateConstructor();
  static final DesktopIntegrationService instance =
      DesktopIntegrationService._privateConstructor();

  final SystemTray _systemTray = SystemTray();
  final Menu _menu = Menu();
  bool _isInitialized = false;
  bool _isBreakActive = false;
  bool _isWindowHiddenToTray = false;
  bool _wasHiddenToTrayBeforeBreak = false;
  bool? _lastIsBreak;
  bool? _lastIsRunning;
  bool? _lastIsPaused;
  bool? _lastAllowPostpone;
  int? _lastPostponeDurationMinutes;

  List<Rect> _breakMonitorRects = const [];
  Rect? _savedWindowBounds;
  bool _wasMaximized = false;

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
    _isWindowHiddenToTray = false;
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
      _isWindowHiddenToTray = true;
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

  Future<Display?> _getActiveDisplay() async {
    try {
      final cursorPoint = await screenRetriever.getCursorScreenPoint();
      final displays = await screenRetriever.getAllDisplays();
      for (final display in displays) {
        final position = display.visiblePosition;
        if (position == null) continue;
        final size = display.visibleSize ?? display.size;
        final rect = Rect.fromLTWH(position.dx, position.dy, size.width, size.height);
        if (rect.contains(cursorPoint)) {
          return display;
        }
      }
    } catch (e) {
      debugPrint('Failed to get active display: $e');
    }
    return null;
  }

  static const MethodChannel _overlayChannel = MethodChannel(
    "blinkkind/break_overlay",
  );

  Future<void> _enterBreakWindow() async {
    _wasHiddenToTrayBeforeBreak = _isWindowHiddenToTray;
    _isWindowHiddenToTray = false;

    // 1. Save original bounds and maximized state to restore after the break
    try {
      _savedWindowBounds = await windowManager.getBounds();
      _wasMaximized = await windowManager.isMaximized();
    } catch (e) {
      debugPrint('Failed to get window bounds/state: $e');
    }

    // 2. Identify the active display where the user is currently working (cursor position)
    final activeDisplay = await _getActiveDisplay();
    if (activeDisplay != null) {
      final position = activeDisplay.visiblePosition;
      final size = activeDisplay.size;
      if (position != null) {
        try {
          // Set the window bounds to cover the entire active monitor
          await windowManager.setBounds(Rect.fromLTWH(position.dx, position.dy, size.width, size.height));
        } catch (e) {
          debugPrint('Failed to set window bounds: $e');
        }
      }
    }

    // 3. Show, restore, and focus the window first to map it to the desktop
    await windowManager.show();
    if (await windowManager.isMinimized()) {
      await windowManager.restore();
    }
    await windowManager.focus();

    // 4. Force fullscreen, borderless visual styles, and always-on-top
    _breakMonitorRects = const [];
    try {
      await windowManager.setAlwaysOnTop(true);
      await windowManager.setSkipTaskbar(true);
      await windowManager.setTitleBarStyle(TitleBarStyle.hidden);
      await windowManager.setFullScreen(true);
    } catch (e) {
      debugPrint('Failed to configure fullscreen overlay: $e');
    }
    await windowManager.focus();

    // 5. Invoke native screen blockers to cover secondary displays (like safeeyes does)
    try {
      await _overlayChannel.invokeMethod('showBlockers');
    } catch (e) {
      debugPrint('Failed to show native screen blockers: $e');
    }
  }

  Future<void> _exitBreakWindow() async {
    // 1. Destroy native screen blockers on secondary displays
    try {
      await _overlayChannel.invokeMethod('hideBlockers');
    } catch (e) {
      debugPrint('Failed to hide native screen blockers: $e');
    }

    // 2. Restore window decorations and exit fullscreen
    try {
      await windowManager.setFullScreen(false);
      await windowManager.setAlwaysOnTop(false);
      await windowManager.setSkipTaskbar(false);
      await windowManager.setTitleBarStyle(TitleBarStyle.normal);

      // Wait for the window manager to process the style change and frame the window
      await Future.delayed(const Duration(milliseconds: 200));

      final saved = _savedWindowBounds;
      if (saved != null) {
        await windowManager.setBounds(saved);
      }
      if (_wasMaximized) {
        await windowManager.maximize();
      }
      if (_wasHiddenToTrayBeforeBreak) {
        await windowManager.hide();
        _isWindowHiddenToTray = true;
      }
    } catch (e) {
      debugPrint('Failed to restore window bounds: $e');
    }
    _savedWindowBounds = null;
    _wasMaximized = false;
    _breakMonitorRects = const [];
  }
}
