import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:launch_at_startup/launch_at_startup.dart';
import 'package:system_tray/system_tray.dart';
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
      final List<MenuItemBase> items = [
        MenuItemLabel(label: 'Show BlinkKind', onClicked: (_) => _showWindow()),
        MenuSeparator(),
      ];

      if (state.isBreak) {
        items.addAll([
          MenuItemLabel(
            label: 'Break Active - Skip Break',
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
      } else if (state.isRunning) {
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
      await windowManager.setAlwaysOnTop(true);
      await windowManager.setFullScreen(true);
      await windowManager.show();
      await windowManager.focus();
    } else {
      _isBreakActive = false;
      await windowManager.setFullScreen(false);
      await windowManager.setAlwaysOnTop(false);
    }
  }
}
