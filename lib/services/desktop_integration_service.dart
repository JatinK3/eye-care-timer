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
import 'package:hotkey_manager/hotkey_manager.dart';
import 'desktop_controls_controller.dart';
import 'notification_service.dart';

class DesktopIntegrationService extends WindowListener {
  DesktopIntegrationService._privateConstructor();
  static final DesktopIntegrationService instance =
      DesktopIntegrationService._privateConstructor();

  final SystemTray _systemTray = SystemTray();
  final Menu _menu = Menu();
  bool _isInitialized = false;

  static const MethodChannel _lockChannel = MethodChannel(
    "blinkkind/system_lock",
  );

  final StreamController<bool> _lockStreamController =
      StreamController<bool>.broadcast();

  Stream<bool> get onSystemLockChanged => _lockStreamController.stream;
  bool _isBreakActive = false;
  bool? _lastIsBreak;
  bool? _lastIsRunning;
  bool? _lastIsPaused;
  bool? _lastAllowPostpone;
  int? _lastPostponeDurationMinutes;
  bool? _lastIsSnoozed;
  String? _lastIconPath;
  DesktopTimerState? _latestState;

  DesktopTimerState? get latestState => _latestState;

  List<Rect> _breakMonitorRects = const [];

  /// Per-monitor rectangles (in the overlay window's local coordinate space) to
  /// replicate break content onto every screen while a multi-monitor break is
  /// active. Empty when the overlay is a single-monitor fullscreen window.
  List<Rect> get breakMonitorRects => List.unmodifiable(_breakMonitorRects);

  bool get isSupported =>
      !kIsWeb &&
      (Platform.isLinux || Platform.isMacOS || Platform.isWindows) &&
      !Platform.environment.containsKey('FLUTTER_TEST');

  Future<void> initialize({
    bool startMinimized = false,
    bool autoStartSchedule = false,
  }) async {
    if (!isSupported || _isInitialized) return;

    // 1. Initialize Window Manager
    await windowManager.ensureInitialized();
    windowManager.addListener(this);
    await windowManager.setPreventClose(true);
    await windowManager.setTitle('BlinkKind');
    // Hide the OS title bar on Windows/macOS where custom window controls are standard.
    // On Linux, GNOME Shell manages window decorations and custom borderless window controls
    // are not well-integrated, so we keep the native title bar. We set the prefer-dark-theme
    // preference in native C++ to match the app theme.
    if (!Platform.isLinux) {
      await windowManager.setTitleBarStyle(
        TitleBarStyle.hidden,
        windowButtonVisibility: false,
      );
    }

    // 2. Initialize System Tray
    await _initTray();

    // 2b. Initialize Global Hotkeys
    await _initHotkeys();

    // 3. Initialize Launch at Startup
    _initLaunchAtStartup();

    // 4. Listen to state changes to update the tray menu dynamically
    DesktopControlsController.instance.states.listen((state) {
      _latestState = state;
      unawaited(_updateTrayMenu(state));
    });

    // 5. Setup MethodChannel for native system lock/unlock notifications
    _lockChannel.setMethodCallHandler((call) async {
      if (call.method == 'lock') {
        _lockStreamController.add(true);
      } else if (call.method == 'unlock') {
        _lockStreamController.add(false);
      }
    });

    if (startMinimized) {
      await windowManager.hide();
      final notificationService = NotificationService();
      if (autoStartSchedule) {
        unawaited(notificationService.showStartupNotification(
          title: 'BlinkKind is running',
          body: 'BlinkKind has started minimized in the system tray. The eye-care schedule has started.',
        ));
      } else {
        unawaited(notificationService.showStartupNotification(
          title: 'BlinkKind is running',
          body: 'BlinkKind has started minimized in the system tray. Tap the tray icon to start.',
        ));
      }
    }

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
          if (!Platform.isLinux) {
            DesktopControlsController.instance.triggerCommand(
              DesktopCommand.showDashboard,
            );
          }
        }
      });

      // Build initial menu
      await _menu.buildFrom([
        MenuItemLabel(
          label: 'Show BlinkKind',
          onClicked: (_) {
            unawaited(_showWindow());
            DesktopControlsController.instance.triggerCommand(
              DesktopCommand.showDashboard,
            );
          },
        ),
        MenuItemLabel(
          label: 'Settings',
          onClicked: (_) {
            unawaited(_showWindow());
            DesktopControlsController.instance.triggerCommand(
              DesktopCommand.openSettings,
            );
          },
        ),
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
      final timeStr =
          '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

      String tooltipText;
      if (state.isBreak) {
        tooltipText = 'BlinkKind - On a Break ($timeStr remaining)';
      } else if (state.isSnoozed) {
        tooltipText = 'BlinkKind - Breaks Snoozed';
      } else if (state.isRunning) {
        if (state.isPaused) {
          tooltipText = 'BlinkKind - Paused ($timeStr remaining)';
        } else if (state.nextBreakAt != null) {
          final localNext = state.nextBreakAt!.toLocal();
          final hour = localNext.hour.toString().padLeft(2, '0');
          final minute = localNext.minute.toString().padLeft(2, '0');
          tooltipText = 'BlinkKind - Next break at $hour:$minute';
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
      } else if (state.isSnoozed) {
        titleText = 'Snoozed';
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
          _lastPostponeDurationMinutes == state.postponeDurationMinutes &&
          _lastIsSnoozed == state.isSnoozed) {
        return;
      }

      _lastIsBreak = state.isBreak;
      _lastIsRunning = state.isRunning;
      _lastIsPaused = state.isPaused;
      _lastAllowPostpone = state.allowPostpone;
      _lastPostponeDurationMinutes = state.postponeDurationMinutes;
      _lastIsSnoozed = state.isSnoozed;

      final List<MenuItemBase> items = [
        MenuItemLabel(
          label: 'Show BlinkKind',
          onClicked: (_) {
            unawaited(_showWindow());
            DesktopControlsController.instance.triggerCommand(
              DesktopCommand.showDashboard,
            );
          },
        ),
        MenuItemLabel(
          label: 'Settings',
          onClicked: (_) {
            unawaited(_showWindow());
            DesktopControlsController.instance.triggerCommand(
              DesktopCommand.openSettings,
            );
          },
        ),
        MenuSeparator(),
      ];

      // Add dynamic, read-only Status item
      String statusText;
      if (state.isBreak) {
        statusText = 'Status: On a Break';
      } else if (state.isSnoozed) {
        statusText = 'Status: Snoozed';
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
        if (state.isRunning && !state.isPaused && !state.isSnoozed) {
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
          if (state.isPaused || state.isSnoozed) {
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

      // Add Snooze options
      items.add(MenuSeparator());
      if (state.isSnoozed) {
        items.addAll([
          MenuItemLabel(
            label: 'Cancel Snooze',
            onClicked: (_) {
              DesktopControlsController.instance.triggerCommand(
                DesktopCommand.cancelSnooze,
              );
            },
          ),
        ]);
      } else {
        items.addAll([
          MenuItemLabel(
            label: 'Snooze Breaks for 1 Hour',
            onClicked: (_) {
              DesktopControlsController.instance.triggerCommand(
                DesktopCommand.snooze1Hour,
              );
            },
          ),
          MenuItemLabel(
            label: 'Snooze Breaks until Tomorrow',
            onClicked: (_) {
              DesktopControlsController.instance.triggerCommand(
                DesktopCommand.snoozeUntilTomorrow,
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
    // The in-window countdown animation is paused while the window is hidden, so
    // tell the timer page to re-project its display from the wall clock now that
    // the window is visible again.
    DesktopControlsController.instance.triggerCommand(
      DesktopCommand.windowResumed,
    );
  }

  Future<void> _quitApp() async {
    try {
      await NotificationService().cancelBlinkReminder();
    } catch (e) {
      debugPrint('Failed to cancel notifications on exit: $e');
    }
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
    try {
      await hotKeyManager.unregisterAll();
    } catch (e) {
      debugPrint('Failed to unregister hotkeys on exit: $e');
    }
    windowManager.removeListener(this);
    try {
      await windowManager.destroy().timeout(const Duration(milliseconds: 200));
    } catch (e) {
      debugPrint('Failed to destroy window on exit: $e');
    }
    exit(0);
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

  /// Begins the desktop break. Native GTK snapshots/restores the main window
  /// state and either fullscreen-targets a single monitor or spans the main
  /// Flutter window across the virtual desktop. When spanning, it returns each
  /// monitor's local rectangle so the Flutter overlay can replicate the break
  /// content on every screen instead of showing blank black blockers. The work is
  /// delegated to the native runner so it owns the window transform
  /// end-to-end. This avoids the "dual-mapping" conflict that arose when both
  /// window_manager (Dart) and GTK (native) fought over the same window, and
  /// lets the runner restore the window synchronously on exit without
  /// GNOME/Mutter flashing the UI back onto the desktop.
  Future<void> _enterBreakWindow() async {
    _breakMonitorRects = const [];
    try {
      final result = await _overlayChannel.invokeMethod<Object?>('enterBreak');
      _breakMonitorRects = _monitorRectsFromNativeResult(result);
    } catch (e) {
      debugPrint('Failed to enter native break window: $e');
    }
  }

  List<Rect> _monitorRectsFromNativeResult(Object? result) {
    if (result is! Map) return const [];
    final rawRects = result['monitorRects'];
    if (rawRects is! List || rawRects.length <= 1) return const [];

    final rects = <Rect>[];
    for (final item in rawRects) {
      if (item is! Map) continue;
      final x = _nativeDouble(item['x']);
      final y = _nativeDouble(item['y']);
      final width = _nativeDouble(item['width']);
      final height = _nativeDouble(item['height']);
      if (width <= 0 || height <= 0) continue;
      rects.add(Rect.fromLTWH(x, y, width, height));
    }
    return rects.length > 1 ? List.unmodifiable(rects) : const [];
  }

  double _nativeDouble(Object? value) {
    if (value is num) return value.toDouble();
    return 0;
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
      final width = 64.0;
      final height = 64.0;
      final scale = width / 32.0;
      final strokeWidth = 3.5 * scale;
      final ringRadius = (width / 2) - (strokeWidth / 2) - 0.5;

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, width, height));

      // 1. Draw a dark circular background circle so it's readable on both dark/light panels.
      final bgPaint = Paint()
        ..color = const ui.Color(0xDD1E1E1E)
        ..style = ui.PaintingStyle.fill;
      canvas.drawCircle(
        Offset(width / 2, height / 2),
        (width / 2),
        bgPaint,
      );

      // 2. State specific colors and text
      ui.Color ringColor;
      String text = '';
      double progress = 0.0;

      if (state.isBreak) {
        ringColor = state.isLongBreak ? Colors.pinkAccent : Colors.greenAccent;
        text = state.remainingSeconds.toString();
        if (state.initialDurationSeconds > 0) {
          progress = (state.remainingSeconds / state.initialDurationSeconds)
              .clamp(0.0, 1.0);
        }
      } else if (state.isSnoozed) {
        ringColor = Colors.deepPurpleAccent;
        text = 'Zz';
        progress = 0.0;
      } else if (state.isRunning) {
        if (state.isPaused) {
          ringColor = Colors.orangeAccent;
          final mins = (state.remainingSeconds / 60).ceil();
          text = mins.toString();
        } else {
          final isImminent = state.remainingSeconds < 60;
          if (isImminent) {
            ringColor = Colors.amberAccent;
            text = state.remainingSeconds.toString();
          } else {
            ringColor = Colors.cyanAccent;
            final mins = (state.remainingSeconds / 60).ceil();
            text = mins.toString();
          }
        }
        if (state.initialDurationSeconds > 0) {
          progress = (state.remainingSeconds / state.initialDurationSeconds)
              .clamp(0.0, 1.0);
        }
      } else {
        ringColor = Colors.grey;
        text = '';
      }

      // 3. Draw progress ring (thicker stroke, maximized to edge)
      final ringPaint = Paint()
        ..style = ui.PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = ui.StrokeCap.round
        ..color = ringColor.withValues(alpha: 0.25);
      canvas.drawCircle(
        Offset(width / 2, height / 2),
        ringRadius,
        ringPaint,
      );

      if (progress > 0) {
        final activeRingPaint = Paint()
          ..style = ui.PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = ui.StrokeCap.round
          ..color = ringColor;

        canvas.drawArc(
          Rect.fromCircle(
            center: Offset(width / 2, height / 2),
            radius: ringRadius,
          ),
          -math.pi / 2,
          2 * math.pi * progress,
          false,
          activeRingPaint,
        );
      }

      // 4. Draw central remaining text or dot (scaled font sizes & strokes)
      if (state.isBlinkNudging) {
        final eyePaint = Paint()
          ..color = ringColor
          ..style = ui.PaintingStyle.stroke
          ..strokeWidth = 2.2 * scale
          ..strokeCap = ui.StrokeCap.round;

        canvas.drawArc(
          Rect.fromLTWH(
            width * 0.25,
            height * 0.38,
            width * 0.5,
            height * 0.25,
          ),
          0,
          math.pi,
          false,
          eyePaint,
        );
        canvas.drawLine(
          Offset(width * 0.35, height * 0.51),
          Offset(width * 0.3, height * 0.61),
          eyePaint..strokeWidth = 1.5 * scale,
        );
        canvas.drawLine(
          Offset(width * 0.5, height * 0.52),
          Offset(width * 0.5, height * 0.65),
          eyePaint..strokeWidth = 1.5 * scale,
        );
        canvas.drawLine(
          Offset(width * 0.65, height * 0.51),
          Offset(width * 0.7, height * 0.61),
          eyePaint..strokeWidth = 1.5 * scale,
        );
      } else if (text.isNotEmpty) {
        final textPainter = TextPainter(
          text: TextSpan(
            text: text,
            style: TextStyle(
              color: Colors.white,
              fontSize: text.length > 2 ? (14.5 * scale) : (19.5 * scale),
              fontWeight: ui.FontWeight.w900,
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
            (height - textPainter.height) / 2 - (1.0 * scale),
          ),
        );
      } else {
        canvas.drawCircle(
          Offset(width / 2, height / 2),
          4.0 * scale,
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
        tempDir =
            Platform.environment['TEMP'] ?? Platform.environment['TMP'] ?? '.';
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

  Future<void> _initHotkeys() async {
    try {
      await hotKeyManager.unregisterAll();

      final hotkeysConfig = [
        // Pause/Resume
        (
          PhysicalKeyboardKey.keyP,
          [HotKeyModifier.control, HotKeyModifier.alt],
          'pause_resume',
        ),
        (
          PhysicalKeyboardKey.keyP,
          [HotKeyModifier.meta, HotKeyModifier.alt],
          'pause_resume',
        ),
        // Take Break Now
        (
          PhysicalKeyboardKey.keyB,
          [HotKeyModifier.control, HotKeyModifier.alt],
          'start_break',
        ),
        (
          PhysicalKeyboardKey.keyB,
          [HotKeyModifier.meta, HotKeyModifier.alt],
          'start_break',
        ),
        // Skip Break
        (
          PhysicalKeyboardKey.keyS,
          [HotKeyModifier.control, HotKeyModifier.alt],
          'skip_break',
        ),
        (
          PhysicalKeyboardKey.keyS,
          [HotKeyModifier.meta, HotKeyModifier.alt],
          'skip_break',
        ),
        // Postpone Break
        (
          PhysicalKeyboardKey.keyO,
          [HotKeyModifier.control, HotKeyModifier.alt],
          'postpone_break',
        ),
        (
          PhysicalKeyboardKey.keyO,
          [HotKeyModifier.meta, HotKeyModifier.alt],
          'postpone_break',
        ),
      ];

      for (final config in hotkeysConfig) {
        final hotKey = HotKey(
          key: config.$1,
          modifiers: config.$2,
          scope: HotKeyScope.system,
        );
        await hotKeyManager.register(
          hotKey,
          keyDownHandler: (hk) {
            _handleHotkey(config.$3);
          },
        );
      }
    } catch (e) {
      debugPrint('Failed to initialize global hotkeys: $e');
    }
  }

  void _handleHotkey(String action) {
    switch (action) {
      case 'pause_resume':
        if (_latestState != null) {
          if (_latestState!.isPaused ||
              !_latestState!.isRunning ||
              _latestState!.isSnoozed) {
            DesktopControlsController.instance.triggerCommand(
              DesktopCommand.resume,
            );
          } else {
            DesktopControlsController.instance.triggerCommand(
              DesktopCommand.pause,
            );
          }
        } else {
          DesktopControlsController.instance.triggerCommand(
            DesktopCommand.resume,
          );
        }
        break;
      case 'start_break':
        DesktopControlsController.instance.triggerCommand(
          DesktopCommand.startBreak,
        );
        break;
      case 'skip_break':
        DesktopControlsController.instance.triggerCommand(
          DesktopCommand.skipBreak,
        );
        break;
      case 'postpone_break':
        DesktopControlsController.instance.triggerCommand(
          DesktopCommand.postponeBreak,
        );
        break;
    }
  }
}
