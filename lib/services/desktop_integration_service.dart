import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  bool? _lastIsBreak;
  bool? _lastIsRunning;
  bool? _lastIsPaused;
  bool? _lastAllowPostpone;
  int? _lastPostponeDurationMinutes;
  String? _lastIconPath;

  List<Rect> _breakMonitorRects = const [];

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

      String titleText = '';
      if (state.isBreak) {
        titleText = 'Break $timeStr';
      } else if (state.isRunning) {
        if (state.isPaused) {
          titleText = 'Paused $timeStr';
        } else {
          titleText = timeStr;
        }
      }
      unawaited(_systemTray.setTitle(titleText));
      unawaited(_updateDynamicTrayIcon(state));

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
    // The in-window countdown animation is paused while the window is hidden, so
    // tell the timer page to re-project its display from the wall clock now that
    // the window is visible again.
    DesktopControlsController.instance.triggerCommand(
      DesktopCommand.windowResumed,
    );
  }

  Future<void> _quitApp() async {
    final oldPath = _lastIconPath;
    if (oldPath != null) {
      try {
        final oldFile = File(oldPath);
        if (await oldFile.exists()) {
          await oldFile.delete();
        }
      } catch (e) {
        debugPrint('Failed to delete tray icon on exit: $e');
      }
    }
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
      await _exitBreakWindow();
    }
  }

  static const MethodChannel _overlayChannel = MethodChannel(
    "blinkkind/break_overlay",
  );

  /// Begins the desktop break. All main-window manipulation — forcing the
  /// window up onto the active (cursor) monitor, fullscreening it to host the
  /// Flutter break UI, and covering the other monitors with black blockers — is
  /// delegated to the native GTK runner so it owns the window transform
  /// end-to-end. This avoids the "dual-mapping" conflict that arose when both
  /// window_manager (Dart) and GTK (native) fought over the same window, and
  /// lets the runner restore the window synchronously on exit without
  /// GNOME/Mutter flashing the UI back onto the desktop.
  Future<void> _enterBreakWindow() async {
    _breakMonitorRects = const [];
    try {
      await _overlayChannel.invokeMethod('enterBreak');
    } catch (e) {
      debugPrint('Failed to enter native break window: $e');
    }
  }

  /// Ends the desktop break. The native runner tears down the blockers and
  /// returns the main window to exactly the state it was in before the break:
  /// hidden back to the tray / its floating bounds, or restored on screen if it
  /// was visible. A tray-bound window is unmapped *before* its fullscreen styles
  /// are cleared, all in one synchronous native call, so the compositor never
  /// re-maps and flashes the UI.
  Future<void> _exitBreakWindow() async {
    try {
      await _overlayChannel.invokeMethod('exitBreak');
    } catch (e) {
      debugPrint('Failed to exit native break window: $e');
    }
    _isBreakActive = false;
    _breakMonitorRects = const [];
  }

  Future<void> _updateDynamicTrayIcon(DesktopTimerState state) async {
    if (!isSupported) return;

    try {
      final width = 24.0;
      final height = 24.0;
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, width, height));

      // 1. Draw a dark circular background circle so it's readable on both dark/light panels.
      final bgPaint = Paint()
        ..color = const ui.Color(0xDD1E1E1E)
        ..style = ui.PaintingStyle.fill;
      canvas.drawCircle(Offset(width / 2, height / 2), (width / 2) - 1.0, bgPaint);

      // 2. State specific colors and text
      ui.Color ringColor;
      String text = '';
      double progress = 0.0;

      if (state.isBreak) {
        ringColor = Colors.greenAccent;
        text = state.remainingSeconds.toString();
        if (state.initialDurationSeconds > 0) {
          progress = (state.remainingSeconds / state.initialDurationSeconds).clamp(0.0, 1.0);
        }
      } else if (state.isRunning) {
        if (state.isPaused) {
          ringColor = Colors.orangeAccent;
          final mins = (state.remainingSeconds / 60).ceil();
          text = mins.toString();
        } else {
          ringColor = Colors.cyanAccent;
          final mins = (state.remainingSeconds / 60).ceil();
          text = mins.toString();
        }
        if (state.initialDurationSeconds > 0) {
          progress = (state.remainingSeconds / state.initialDurationSeconds).clamp(0.0, 1.0);
        }
      } else {
        ringColor = Colors.grey;
        text = '';
      }

      // 3. Draw progress ring
      final ringPaint = Paint()
        ..style = ui.PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..strokeCap = ui.StrokeCap.round
        ..color = ringColor.withValues(alpha: 0.25);
      canvas.drawCircle(Offset(width / 2, height / 2), (width / 2) - 2.5, ringPaint);

      if (progress > 0) {
        final activeRingPaint = Paint()
          ..style = ui.PaintingStyle.stroke
          ..strokeWidth = 2.0
          ..strokeCap = ui.StrokeCap.round
          ..color = ringColor;
        
        canvas.drawArc(
          Rect.fromCircle(center: Offset(width / 2, height / 2), radius: (width / 2) - 2.5),
          -math.pi / 2,
          2 * math.pi * progress,
          false,
          activeRingPaint,
        );
      }

      // 4. Draw central remaining text or dot
      if (state.isBlinkNudging) {
        final eyePaint = Paint()
          ..color = ringColor
          ..style = ui.PaintingStyle.stroke
          ..strokeWidth = 1.8
          ..strokeCap = ui.StrokeCap.round;

        canvas.drawArc(
          Rect.fromLTWH(width * 0.25, height * 0.38, width * 0.5, height * 0.25),
          0,
          math.pi,
          false,
          eyePaint,
        );
        canvas.drawLine(
          Offset(width * 0.35, height * 0.51),
          Offset(width * 0.3, height * 0.61),
          eyePaint..strokeWidth = 1.2,
        );
        canvas.drawLine(
          Offset(width * 0.5, height * 0.52),
          Offset(width * 0.5, height * 0.65),
          eyePaint..strokeWidth = 1.2,
        );
        canvas.drawLine(
          Offset(width * 0.65, height * 0.51),
          Offset(width * 0.7, height * 0.61),
          eyePaint..strokeWidth = 1.2,
        );
      } else if (text.isNotEmpty) {
        final textPainter = TextPainter(
          text: TextSpan(
            text: text,
            style: TextStyle(
              color: Colors.white,
              fontSize: text.length > 2 ? 8.0 : 10.0,
              fontWeight: ui.FontWeight.bold,
              height: 1.0,
            ),
          ),
          textDirection: ui.TextDirection.ltr,
        );
        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(
            (width - textPainter.width) / 2,
            (height - textPainter.height) / 2,
          ),
        );
      } else {
        canvas.drawCircle(
          Offset(width / 2, height / 2),
          3.0,
          Paint()
            ..color = ringColor
            ..style = ui.PaintingStyle.fill,
        );
      }

      final picture = recorder.endRecording();
      final image = await picture.toImage(width.toInt(), height.toInt());
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      final pngBytes = byteData.buffer.asUint8List();

      final String tempDir;
      if (Platform.isWindows) {
        tempDir = Platform.environment['TEMP'] ?? Platform.environment['TMP'] ?? '.';
      } else {
        tempDir = Platform.environment['TMPDIR'] ?? '/tmp';
      }

      // Generate dynamic file path to bypass AppIndicator/composing caches
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final file = File('$tempDir/blinkkind_tray_icon_$timestamp.png');
      await file.writeAsBytes(pngBytes, flush: true);

      await _systemTray.setImage(file.path);

      // Clean up the previously written tray icon file
      final oldPath = _lastIconPath;
      if (oldPath != null && oldPath != file.path) {
        try {
          final oldFile = File(oldPath);
          if (await oldFile.exists()) {
            await oldFile.delete();
          }
        } catch (e) {
          debugPrint('Failed to delete old tray icon: $e');
        }
      }
      _lastIconPath = file.path;
    } catch (e) {
      debugPrint('Failed to update dynamic tray icon: $e');
    }
  }
}
