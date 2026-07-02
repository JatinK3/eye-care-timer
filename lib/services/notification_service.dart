import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

enum NotificationPermissionStatus { unknown, allowed, disabled, unsupported }

enum ExactAlarmStatus { unknown, allowed, disabled, unsupported }

enum BatteryOptimizationStatus {
  unknown,
  unrestricted,
  restricted,
  unsupported,
}

class NotificationReliabilityStatus {
  final NotificationPermissionStatus permission;
  final ExactAlarmStatus exactAlarms;
  final BatteryOptimizationStatus batteryOptimization;
  final bool hasPendingPhaseReminder;

  const NotificationReliabilityStatus({
    this.permission = NotificationPermissionStatus.unknown,
    this.exactAlarms = ExactAlarmStatus.unknown,
    this.batteryOptimization = BatteryOptimizationStatus.unknown,
    this.hasPendingPhaseReminder = false,
  });
}

enum WellnessType { hydration, posture, stretch }

class NotificationService {
  static const int _phaseReminderId = 1001;
  static const int _testReminderId = 1002;
  static const int _preBreakWarningReminderId = 1003;
  static const int _blinkReminderId = 1004;
  static const int _wellnessReminderId = 1005;
  static const int _autoPostponeReminderId = 1006;
  static const int _waterReminderId = 1007;
  static int? _linuxBlinkNotificationReplaceId;
  static DateTime? _lastBlinkReminderSentAt;
  static const String _wellnessChannelId = 'blinkkind_wellness_v1';
  static const String _wellnessChannelName = 'Wellness reminders';
  static const String _wellnessChannelDescription =
      'Periodic hydration, posture, and stretch reminders.';
  static const AndroidNotificationChannel _wellnessChannel =
      AndroidNotificationChannel(
        _wellnessChannelId,
        _wellnessChannelName,
        description: _wellnessChannelDescription,
        importance: Importance.high,
        playSound: false,
        enableVibration: false,
      );
  static const NotificationDetails _wellnessNotificationDetails =
      NotificationDetails(
        android: AndroidNotificationDetails(
          _wellnessChannelId,
          _wellnessChannelName,
          channelDescription: _wellnessChannelDescription,
          importance: Importance.high,
          priority: Priority.high,
          playSound: false,
          enableVibration: false,
          silent: true,
        ),
        iOS: DarwinNotificationDetails(presentAlert: true, presentSound: false),
        macOS: DarwinNotificationDetails(
          presentAlert: true,
          presentSound: false,
        ),
      );

  // Blink channel: dynamically built per chimeStyle so Android uses the
  // correct sound. Channel ID encodes the style name — Android creates a
  // fresh channel (and therefore fresh sound) when the user changes the chime.
  static String _blinkChannelId(String chimeStyle) =>
      'blinkkind_blink_reminders_v5_$chimeStyle';
  static const String _blinkChannelName = 'Blink reminders';
  static const String _blinkChannelDescription =
      'Visible periodic banner reminders to blink consciously during work sessions.';

  static AndroidNotificationChannel _buildBlinkChannel(String chimeStyle) {
    final RawResourceAndroidNotificationSound? sound =
        (chimeStyle != 'system_alert')
            ? RawResourceAndroidNotificationSound(chimeStyle)
            : null;
    return AndroidNotificationChannel(
      _blinkChannelId(chimeStyle),
      _blinkChannelName,
      description: _blinkChannelDescription,
      importance: Importance.high,
      playSound: sound != null,
      sound: sound,
      enableVibration: false,
    );
  }

  static NotificationDetails _buildBlinkDetails(
    String chimeStyle, {
    bool interactive = false,
  }) {
    final channelId = _blinkChannelId(chimeStyle);
    final RawResourceAndroidNotificationSound? sound =
        (chimeStyle != 'system_alert')
            ? RawResourceAndroidNotificationSound(chimeStyle)
            : null;
    return NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        _blinkChannelName,
        channelDescription: _blinkChannelDescription,
        importance: Importance.high,
        priority: Priority.high,
        playSound: sound != null,
        sound: sound,
        enableVibration: false,
        silent: false,
        icon: 'ic_stat_eye',
        actions: interactive
            ? <AndroidNotificationAction>[
                AndroidNotificationAction(
                  'blink_done',
                  'I blinked! \u{1F441}\uFE0F',
                  cancelNotification: true,
                  showsUserInterface: true,
                ),
              ]
            : null,
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentSound: false,
      ),
      macOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentSound: false,
      ),
    );
  }

  Future<bool> schedulePreBreakWarningReminder(
    Duration delay, {
    bool isLongBreak = false,
  }) {
    return _schedulePhaseReminder(
      id: _preBreakWarningReminderId,
      delay: delay,
      title: isLongBreak
          ? 'Long break starting soon'
          : 'Short break starting soon',
      body: isLongBreak
          ? 'Prepare to take a longer rest.'
          : 'Prepare to rest your eyes in 10 seconds.',
      payload: 'pre_break_warning',
    );
  }

  Future<void> cancelPreBreakWarningReminder() async {
    if (kIsWeb) {
      return;
    }
    if (Platform.isLinux) {
      _linuxWarningTimer?.cancel();
      _linuxWarningTimer = null;
      return;
    }

    await initialize();
    try {
      await _notificationsPlugin.cancel(id: _preBreakWarningReminderId);
    } on PlatformException catch (error) {
      debugPrint('Unable to cancel warning reminder: $error');
    }
  }

  static const String _channelId = 'blinkkind_phase_reminders_v2';
  static const String _channelName = 'BlinkKind reminders';
  static const String _channelDescription =
      'Reminders for work and eye break timer phases.';
  static const AndroidNotificationChannel _phaseChannel =
      AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: _channelDescription,
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
        audioAttributesUsage: AudioAttributesUsage.alarm,
      );
  static const NotificationDetails _phaseNotificationDetails =
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.high,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
          category: AndroidNotificationCategory.alarm,
          audioAttributesUsage: AudioAttributesUsage.alarm,
        ),
        iOS: DarwinNotificationDetails(presentAlert: true, presentSound: true),
        macOS: DarwinNotificationDetails(
          presentAlert: true,
          presentSound: true,
        ),
      );

  static const NotificationDetails _workCompleteNotificationDetails =
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.high,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
          category: AndroidNotificationCategory.alarm,
          audioAttributesUsage: AudioAttributesUsage.alarm,
          actions: <AndroidNotificationAction>[
            AndroidNotificationAction(
              'postpone_break',
              'Postpone',
              showsUserInterface: false,
            ),
            AndroidNotificationAction(
              'skip_break',
              'Skip',
              showsUserInterface: false,
            ),
          ],
        ),
        iOS: DarwinNotificationDetails(presentAlert: true, presentSound: true),
        macOS: DarwinNotificationDetails(
          presentAlert: true,
          presentSound: true,
        ),
      );

  static const MethodChannel _settingsChannel = MethodChannel(
    'eye_care_timer/notification_settings',
  );

  final FlutterLocalNotificationsPlugin _notificationsPlugin;
  bool _isInitialized = false;

  final StreamController<NotificationResponse> _notificationResponseController =
      StreamController<NotificationResponse>.broadcast();
  final StreamController<void> _blinkReminderAcknowledgedController =
      StreamController<void>.broadcast();

  Stream<NotificationResponse> get onNotificationResponse =>
      _notificationResponseController.stream;
  Stream<void> get onBlinkReminderAcknowledged =>
      _blinkReminderAcknowledgedController.stream;

  Timer? _linuxPhaseTimer;
  Timer? _linuxWarningTimer;
  Process? _linuxBlinkActionMonitor;
  String _linuxBlinkActionMonitorBuffer = '';

  NotificationService({FlutterLocalNotificationsPlugin? notificationsPlugin})
    : _notificationsPlugin =
          notificationsPlugin ?? FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    if (_isInitialized || kIsWeb) {
      return;
    }
    if (!kIsWeb && Platform.isLinux) {
      await _ensureLinuxBlinkActionMonitor();
      _isInitialized = true;
      return;
    }

    tz_data.initializeTimeZones();

    const initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings('ic_stat_eye'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
      macOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );

    await _notificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        _notificationResponseController.add(response);
      },
    );
    final android = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await android?.createNotificationChannel(_phaseChannel);
    await android?.createNotificationChannel(_wellnessChannel);
    _isInitialized = true;
  }

  Future<void> requestPermissions() async {
    if (kIsWeb) {
      return;
    }

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, sound: true);

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          MacOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, sound: true);
  }

  Future<NotificationPermissionStatus> permissionStatus() async {
    if (kIsWeb) {
      return NotificationPermissionStatus.unsupported;
    }
    if (Platform.isLinux) {
      return NotificationPermissionStatus.allowed;
    }

    await initialize();

    final androidStatus = await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.areNotificationsEnabled();
    if (androidStatus != null) {
      return androidStatus
          ? NotificationPermissionStatus.allowed
          : NotificationPermissionStatus.disabled;
    }

    final iosStatus = await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.checkPermissions();
    if (iosStatus != null) {
      return iosStatus.isEnabled
          ? NotificationPermissionStatus.allowed
          : NotificationPermissionStatus.disabled;
    }

    final macosStatus = await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          MacOSFlutterLocalNotificationsPlugin
        >()
        ?.checkPermissions();
    if (macosStatus != null) {
      return macosStatus.isEnabled
          ? NotificationPermissionStatus.allowed
          : NotificationPermissionStatus.disabled;
    }

    return NotificationPermissionStatus.unsupported;
  }

  Future<NotificationReliabilityStatus> reliabilityStatus() async {
    return NotificationReliabilityStatus(
      permission: await permissionStatus(),
      exactAlarms: await exactAlarmStatus(),
      batteryOptimization: await batteryOptimizationStatus(),
      hasPendingPhaseReminder: await hasPendingPhaseReminder(),
    );
  }

  Future<ExactAlarmStatus> exactAlarmStatus() async {
    if (kIsWeb) return ExactAlarmStatus.unsupported;
    if (Platform.isLinux) return ExactAlarmStatus.allowed;
    await initialize();
    final android = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android == null) return ExactAlarmStatus.unsupported;
    final allowed = await android.canScheduleExactNotifications();
    return allowed == true
        ? ExactAlarmStatus.allowed
        : ExactAlarmStatus.disabled;
  }

  Future<bool> requestExactAlarmPermission() async {
    if (kIsWeb) return false;
    await initialize();
    return await _notificationsPlugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >()
            ?.requestExactAlarmsPermission() ??
        false;
  }

  Future<BatteryOptimizationStatus> batteryOptimizationStatus() async {
    if (kIsWeb) return BatteryOptimizationStatus.unsupported;
    if (Platform.isLinux) return BatteryOptimizationStatus.unrestricted;
    try {
      final ignored = await _settingsChannel.invokeMethod<bool>(
        'isBatteryOptimizationIgnored',
      );
      if (ignored == null) return BatteryOptimizationStatus.unsupported;
      return ignored
          ? BatteryOptimizationStatus.unrestricted
          : BatteryOptimizationStatus.restricted;
    } on PlatformException {
      return BatteryOptimizationStatus.unsupported;
    } on MissingPluginException {
      return BatteryOptimizationStatus.unsupported;
    }
  }

  Future<bool> openBatteryOptimizationSettings() =>
      _openSystemSettings('openBatteryOptimizationSettings');

  Future<bool> openNotificationSettings() =>
      _openSystemSettings('openNotificationSettings');

  Future<bool> openReminderChannelSettings() =>
      _openSystemSettings('openReminderChannelSettings');

  Future<bool> requestIgnoreBatteryOptimizations() =>
      _openSystemSettings('requestIgnoreBatteryOptimizations');

  Future<bool> openOemBatterySettings() =>
      _openSystemSettings('openOemBatterySettings');

  Future<String> detectOemManufacturer() async {
    if (kIsWeb || !Platform.isAndroid) return '';
    try {
      return await _settingsChannel.invokeMethod<String>(
            'detectOemManufacturer') ??
          '';
    } on PlatformException {
      return '';
    } on MissingPluginException {
      return '';
    }
  }

  Future<bool> _openSystemSettings(String method) async {
    if (kIsWeb) return false;
    try {
      return await _settingsChannel.invokeMethod<bool>(method) ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  Future<bool> hasPendingPhaseReminder() async {
    if (kIsWeb) return false;
    if (Platform.isLinux) {
      return _linuxPhaseTimer != null && _linuxPhaseTimer!.isActive;
    }
    await initialize();
    try {
      final pending = await _notificationsPlugin.pendingNotificationRequests();
      return pending.any((request) => request.id == _phaseReminderId);
    } on PlatformException {
      return false;
    }
  }

  Future<bool> showTestReminder() async {
    if (kIsWeb) return false;
    if (Platform.isLinux) {
      try {
        await Process.run('notify-send', [
          '-a',
          'BlinkKind',
          '-i',
          'blinkkind',
          'BlinkKind test reminder',
          'If you heard this, phase reminder sound is ready.',
        ]);
        unawaited(_playLinuxChimeFallback());
        return true;
      } catch (e) {
        debugPrint('Failed to send Linux notification: $e');
        return false;
      }
    }
    await initialize();
    if (await permissionStatus() != NotificationPermissionStatus.allowed) {
      return false;
    }
    try {
      await _notificationsPlugin.show(
        id: _testReminderId,
        title: 'BlinkKind test reminder',
        body: 'If you heard this, phase reminder sound is ready.',
        notificationDetails: _phaseNotificationDetails,
        payload: 'test_reminder',
      );
      return true;
    } on PlatformException catch (error) {
      debugPrint('Unable to show test reminder: $error');
      return false;
    }
  }

  Future<bool> scheduleWorkCompleteReminder(
    Duration delay, {
    bool isLongBreak = false,
  }) {
    return _schedulePhaseReminder(
      delay: delay,
      title: isLongBreak ? 'Time for a Long Break' : 'Time for a Short Break',
      body: isLongBreak
          ? 'Take a longer rest to stretch and refresh.'
          : 'Look 20 ft away and rest your eyes.',
      payload: 'work_complete',
    );
  }

  Future<bool> scheduleBreakCompleteReminder(Duration delay) {
    return _schedulePhaseReminder(
      delay: delay,
      title: 'Break complete',
      body: 'You can return to your task.',
      payload: 'break_complete',
    );
  }

  Future<void> showStartupNotification({
    required String title,
    required String body,
  }) async {
    if (kIsWeb) return;
    if (Platform.isLinux) {
      try {
        await Process.run('notify-send', [
          '-a',
          'BlinkKind',
          '-i',
          'blinkkind',
          title,
          body,
        ]);
      } catch (e) {
        debugPrint('Failed to send Linux startup notification: $e');
      }
      return;
    }
    await initialize();
    try {
      await _notificationsPlugin.show(
        id: 1007,
        title: title,
        body: body,
        notificationDetails: _wellnessNotificationDetails,
        payload: 'startup',
      );
    } on PlatformException catch (error) {
      debugPrint('Unable to show startup notification: $error');
    }
  }

  /// Shows an immediate blink-conscious reminder notification.
  /// On Android the notification channel carries the chime as its sound, so
  /// it plays even when the app is closed.  On Linux/desktop the caller is
  /// expected to play the chime in-app (see timer_home_page._triggerBlinkReminder).
  Future<void> showBlinkReminder({
    String? customMessage,
    bool interactive = true,
    String chimeStyle = 'tibetan_bowl',
  }) async {
    if (kIsWeb) return;

    final now = DateTime.now();
    if (_lastBlinkReminderSentAt != null &&
        now.difference(_lastBlinkReminderSentAt!).inSeconds < 5) {
      debugPrint('Skipping duplicate blink reminder notification due to rate limit.');
      return;
    }
    _lastBlinkReminderSentAt = now;

    const messages = [
      'Remember to blink! \u{1F441}\uFE0F Give your eyes some moisture.',
      '\u{1F441}\uFE0F Blink consciously — your eyes will thank you!',
      'Time to blink! Dry eyes cause fatigue. Blink fully now.',
      '\u{1F440} Blink reminder — close and open your eyes fully.',
      '\u{1F4A7} Moisture check! Blink a few times to refresh your eyes.',
      '\u{1F441}\uFE0F Soft blink — close your eyes slowly, then open. Repeat 3\u00D7.',
    ];
    final idx = DateTime.now().second % messages.length;
    final body = (customMessage != null && customMessage.isNotEmpty)
        ? customMessage
        : messages[idx];

    if (Platform.isLinux) {
      await _showLinuxBlinkReminder(body: body, interactive: interactive);
      return;
    }

    await initialize();
    // Ensure the per-chime channel exists on Android.
    if (!kIsWeb && Platform.isAndroid) {
      try {
        await _notificationsPlugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >()
            ?.createNotificationChannel(_buildBlinkChannel(chimeStyle));
      } catch (_) {}
    }
    try {
      await _notificationsPlugin.show(
        id: _blinkReminderId,
        title: 'Blink reminder \u{1F441}\uFE0F',
        body: body,
        notificationDetails: _buildBlinkDetails(
          chimeStyle,
          interactive: interactive,
        ),
        payload: 'blink_reminder',
      );
    } on PlatformException catch (e) {
      debugPrint('Unable to show blink reminder: $e');
    }
  }

  Future<void> _showLinuxBlinkReminder({
    required String body,
    required bool interactive,
  }) async {
    try {
      if (interactive) {
        await _ensureLinuxBlinkActionMonitor();
      }
      await cancelBlinkReminder();
      final id = await _showLinuxNotificationViaDbus(
        body: body,
        interactive: interactive,
      );
      if (id != null) {
        if (id > 0) {
          _linuxBlinkNotificationReplaceId = id;
        } else {
          _linuxBlinkNotificationReplaceId = null;
        }
        return;
      }
    } catch (e) {
      debugPrint('Failed to send Linux blink notification via DBus: $e');
    }

    await _showLinuxBlinkReminderViaNotifySend(
      body: body,
      interactive: interactive,
    );
  }

  Future<int?> _showLinuxNotificationViaDbus({
    required String body,
    required bool interactive,
  }) async {
    final replaceId = _linuxBlinkNotificationReplaceId ?? 0;
    final actions = interactive ? "['blink_done', 'I blinked']" : '[]';
    final result = await Process.run('gdbus', [
      'call',
      '--session',
      '--dest',
      'org.freedesktop.Notifications',
      '--object-path',
      '/org/freedesktop/Notifications',
      '--method',
      'org.freedesktop.Notifications.Notify',
      'BlinkKind',
      replaceId.toString(),
      'blinkkind',
      'Blink reminder',
      body,
      actions,
      "{'urgency': <byte 1>}",
      '7000',
    ]);
    if (result.exitCode != 0) {
      debugPrint('Failed to send Linux blink notification: ${result.stderr}');
      return null;
    }

    final stdout = result.stdout as String;
    final match = RegExp(r'uint32\s+(\d+)').firstMatch(stdout);
    if (match == null) return 0; // Success but unable to parse ID
    return int.tryParse(match.group(1)!);
  }

  Future<void> _ensureLinuxBlinkActionMonitor() async {
    if (_linuxBlinkActionMonitor != null || kIsWeb || !Platform.isLinux) {
      return;
    }

    try {
      Process process;
      const watchExpr =
          "type='signal',interface='org.freedesktop.Notifications',member='ActionInvoked'";
      try {
        process = await Process.start('stdbuf', [
          '-o0',
          'dbus-monitor',
          watchExpr,
        ]);
      } catch (e) {
        debugPrint('stdbuf not available, starting dbus-monitor directly: $e');
        process = await Process.start('dbus-monitor', [watchExpr]);
      }
      _linuxBlinkActionMonitor = process;
      _linuxBlinkActionMonitorBuffer = '';

      process.stdout.transform(utf8.decoder).listen((chunk) {
        _linuxBlinkActionMonitorBuffer += chunk;
        if (_linuxBlinkActionMonitorBuffer.length > 4096) {
          _linuxBlinkActionMonitorBuffer = _linuxBlinkActionMonitorBuffer
              .substring(_linuxBlinkActionMonitorBuffer.length - 4096);
        }

        final regExp = RegExp(r'member=ActionInvoked[\s\S]*?string\s+"([^"]+)"');
        final matches = regExp.allMatches(_linuxBlinkActionMonitorBuffer);
        for (final match in matches) {
          final actionId = match.group(1);
          if (actionId != null) {
            if (actionId == 'blink_done') {
              _blinkReminderAcknowledgedController.add(null);
            }
            _notificationResponseController.add(
              NotificationResponse(
                notificationResponseType: NotificationResponseType.selectedNotificationAction,
                actionId: actionId,
              ),
            );
          }
        }
        if (matches.isNotEmpty) {
          _linuxBlinkActionMonitorBuffer = '';
        }
      });
      process.stderr.drain<void>();
      unawaited(
        process.exitCode.then((_) {
          if (_linuxBlinkActionMonitor == process) {
            _linuxBlinkActionMonitor = null;
            _linuxBlinkActionMonitorBuffer = '';
          }
        }),
      );
    } catch (e) {
      debugPrint('Failed to watch Linux blink notification actions: $e');
      _linuxBlinkActionMonitor = null;
      _linuxBlinkActionMonitorBuffer = '';
    }
  }

  Future<void> _showLinuxBlinkReminderViaNotifySend({
    required String body,
    required bool interactive,
  }) async {
    try {
      final replaceId = _linuxBlinkNotificationReplaceId;
      final args = [
        '-a',
        'BlinkKind',
        '-i',
        'blinkkind',
        '-u',
        'normal',
        '-t',
        '7000',
        if (interactive) ...['-A', 'blink_done=I blinked'],
        '-p',
        if (replaceId != null) ...['-r', replaceId.toString()],
        'Blink reminder',
        body,
      ];

      // Use Process.start so we don't block on interactive notifications
      // but still capture the notification ID from stdout.
      final process = await Process.start('notify-send', args);
      
      // Read the first line of stdout to get the notification ID (printed immediately by -p)
      final stdoutLine = await process.stdout
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .first
          .timeout(const Duration(seconds: 1), onTimeout: () => '');
          
      final notificationId = int.tryParse(stdoutLine.trim());
      if (notificationId != null) {
        _linuxBlinkNotificationReplaceId = notificationId;
      }
      
      // Drain stdout/stderr so the process doesn't get blocked
      unawaited(process.stdout.drain<void>());
      unawaited(process.stderr.drain<void>());
    } catch (e) {
      debugPrint('Failed to send Linux blink notification via notify-send: $e');
    }
  }

  Future<void> cancelBlinkReminder() async {
    if (kIsWeb) return;

    if (Platform.isLinux) {
      final id = _linuxBlinkNotificationReplaceId;
      if (id != null) {
        try {
          await Process.run('gdbus', [
            'call',
            '--session',
            '--dest',
            'org.freedesktop.Notifications',
            '--object-path',
            '/org/freedesktop/Notifications',
            '--method',
            'org.freedesktop.Notifications.CloseNotification',
            id.toString(),
          ]);
          _linuxBlinkNotificationReplaceId = null;
        } catch (e) {
          debugPrint('Failed to close Linux blink notification: $e');
        }
      }
      return;
    }

    await initialize();
    try {
      await _notificationsPlugin.cancel(id: _blinkReminderId);
    } on PlatformException catch (e) {
      debugPrint('Unable to cancel blink reminder: $e');
    }
  }

  Future<void> showWellnessReminder(
    WellnessType type, {
    String? aiMessage,
  }) async {
    if (kIsWeb) return;

    String title;
    String body;
    switch (type) {
      case WellnessType.hydration:
        title = 'Hydration check';
        body = aiMessage ?? 'Take a sip of water and stay hydrated!';
        break;
      case WellnessType.posture:
        title = 'Posture check';
        body =
            aiMessage ??
            'Sit up straight, shoulders relaxed, screen at eye level.';
        break;
      case WellnessType.stretch:
        title = 'Stretch reminder';
        body =
            aiMessage ??
            'Stand up and stretch for 30 seconds. Your body will thank you!';
        break;
    }

    if (Platform.isLinux) {
      try {
        await Process.run('notify-send', [
          '-a',
          'BlinkKind',
          '-i',
          'blinkkind',
          '-u',
          'low',
          '-t',
          '5000',
          title,
          body,
        ]);
      } catch (e) {
        debugPrint('Failed to send Linux wellness notification: $e');
      }
      return;
    }

    await initialize();
    try {
      await _notificationsPlugin.show(
        id: _wellnessReminderId,
        title: title,
        body: body,
        notificationDetails: _wellnessNotificationDetails,
        payload: 'wellness_reminder',
      );
    } on PlatformException catch (e) {
      debugPrint('Unable to show wellness reminder: $e');
    }
  }

  Future<void> _cancelIntervalRange(int idBase) async {
    for (int i = 0; i < 50; i++) {
      try {
        await _notificationsPlugin.cancel(id: idBase + i);
      } catch (_) {}
    }
  }

  /// Pre-schedules up to 50 repeating interval reminders (Android/iOS) via
  /// zonedSchedule. The first lands [firstDelaySeconds] from now, then every
  /// [cadenceSeconds] up to [horizonSeconds] from now. [messages] holds the
  /// rotating `[title, body]` pairs. No-op on Linux (which drives reminders from
  /// the foreground accumulator instead) and on web.
  Future<void> _scheduleIntervalRemindersBackground({
    required int idBase,
    required int cadenceSeconds,
    required int firstDelaySeconds,
    required int horizonSeconds,
    required int startIndex,
    required List<List<String>> messages,
  }) async {
    if (kIsWeb || Platform.isLinux) return;
    await _cancelIntervalRange(idBase);
    if (cadenceSeconds <= 0 || horizonSeconds <= 0 || messages.isEmpty) return;

    int delay = firstDelaySeconds;
    if (delay <= 0) delay = cadenceSeconds;

    final exactAlarmsAllowed =
        await exactAlarmStatus() == ExactAlarmStatus.allowed;

    int index = startIndex;
    int scheduledCount = 0;
    while (delay <= horizonSeconds && scheduledCount < 50) {
      final message = messages[index % messages.length];
      try {
        await _notificationsPlugin.zonedSchedule(
          id: idBase + scheduledCount,
          title: message[0],
          body: message[1],
          scheduledDate:
              tz.TZDateTime.now(tz.local).add(Duration(seconds: delay)),
          notificationDetails: _wellnessNotificationDetails,
          androidScheduleMode: exactAlarmsAllowed
              ? AndroidScheduleMode.exactAllowWhileIdle
              : AndroidScheduleMode.inexactAllowWhileIdle,
          payload: 'interval_reminder_background',
        );
      } catch (e) {
        debugPrint('Unable to schedule background interval reminder: $e');
        break; // If one fails, stop scheduling more
      }
      delay += cadenceSeconds;
      index++;
      scheduledCount++;
    }
  }

  Future<void> cancelWellnessRemindersBackground() async {
    if (kIsWeb || Platform.isLinux) return;
    await _cancelIntervalRange(3000);
  }

  /// Anchor-based wellness scheduling: the caller derives [firstDelaySeconds]
  /// from a session anchor so the cadence survives work/break phase reschedules
  /// (a 30-min cadence no longer resets every 20-min work phase), and schedules
  /// across [horizonSeconds] (e.g. until the active-hours end) rather than only
  /// the current work phase.
  Future<void> scheduleWellnessRemindersBackground({
    required int cadenceSeconds,
    required int firstDelaySeconds,
    required int horizonSeconds,
    required int startIndex,
  }) async {
    await _scheduleIntervalRemindersBackground(
      idBase: 3000,
      cadenceSeconds: cadenceSeconds,
      firstDelaySeconds: firstDelaySeconds,
      horizonSeconds: horizonSeconds,
      startIndex: startIndex,
      messages: const [
        ['Hydration check', 'Take a sip of water and stay hydrated!'],
        [
          'Posture check',
          'Sit up straight, shoulders relaxed, screen at eye level.'
        ],
        [
          'Stretch reminder',
          'Stand up and stretch for 30 seconds. Your body will thank you!'
        ],
      ],
    );
  }

  Future<void> cancelWaterRemindersBackground() async {
    if (kIsWeb || Platform.isLinux) return;
    await _cancelIntervalRange(3100);
  }

  /// Anchor-based water scheduling (Android/iOS). Cadence is derived by the
  /// caller from the daily goal spread across the active-hours window.
  Future<void> scheduleWaterRemindersBackground({
    required int cadenceSeconds,
    required int firstDelaySeconds,
    required int horizonSeconds,
  }) async {
    await _scheduleIntervalRemindersBackground(
      idBase: 3100,
      cadenceSeconds: cadenceSeconds,
      firstDelaySeconds: firstDelaySeconds,
      horizonSeconds: horizonSeconds,
      startIndex: 0,
      messages: const [
        ['Hydration break 💧', 'Time to drink a glass of water.'],
      ],
    );
  }

  /// Shows an immediate water reminder (used by the desktop foreground path).
  Future<void> showWaterReminder({int? consumedGlasses, int? goalGlasses}) async {
    if (kIsWeb) return;
    const title = 'Hydration break 💧';
    final body = (consumedGlasses != null && goalGlasses != null)
        ? 'Time for some water — $consumedGlasses of $goalGlasses glasses so far today.'
        : 'Time to drink a glass of water.';

    if (Platform.isLinux) {
      try {
        await Process.run('notify-send', [
          '-a',
          'BlinkKind',
          '-i',
          'blinkkind',
          '-u',
          'low',
          '-t',
          '5000',
          title,
          body,
        ]);
      } catch (e) {
        debugPrint('Failed to send Linux water notification: $e');
      }
      return;
    }

    await initialize();
    try {
      await _notificationsPlugin.show(
        id: _waterReminderId,
        title: title,
        body: body,
        notificationDetails: _wellnessNotificationDetails,
        payload: 'water_reminder',
      );
    } on PlatformException catch (e) {
      debugPrint('Unable to show water reminder: $e');
    }
  }

  Future<void> showAutoPostponeNotification() async {
    if (kIsWeb) return;

    const title = 'Break Auto-Postponed 🎥';
    const body = 'Your eye break was postponed because your camera or microphone is in use.';

    if (Platform.isLinux) {
      try {
        await Process.run('notify-send', [
          '-a',
          'BlinkKind',
          '-i',
          'blinkkind',
          '-u',
          'normal',
          '-t',
          '5000',
          title,
          body,
        ]);
      } catch (e) {
        debugPrint('Failed to send Linux auto-postpone notification: $e');
      }
      return;
    }

    await initialize();
    try {
      await _notificationsPlugin.show(
        id: _autoPostponeReminderId,
        title: title,
        body: body,
        notificationDetails: _wellnessNotificationDetails,
        payload: 'auto_postpone',
      );
    } on PlatformException catch (e) {
      debugPrint('Unable to show auto-postpone notification: $e');
    }
  }

  Future<void> cancelPhaseReminder() async {
    if (kIsWeb) {
      return;
    }
    if (Platform.isLinux) {
      _linuxPhaseTimer?.cancel();
      _linuxPhaseTimer = null;
      return;
    }

    await initialize();
    try {
      await _notificationsPlugin.cancel(id: _phaseReminderId);
      await cancelWellnessRemindersBackground();
    } on PlatformException catch (error) {
      debugPrint('Unable to cancel phase reminder: $error');
    }
  }

  Future<bool> _schedulePhaseReminder({
    int id = _phaseReminderId,
    required Duration delay,
    required String title,
    required String body,
    required String payload,
  }) async {
    if (kIsWeb || delay <= Duration.zero) {
      return false;
    }
    if (Platform.isLinux) {
      final isWorkComplete = payload == 'work_complete';
      if (id == _preBreakWarningReminderId) {
        _linuxWarningTimer?.cancel();
        _linuxWarningTimer = Timer(delay, () {
          Process.run('notify-send', [
            '-a',
            'BlinkKind',
            '-i',
            'blinkkind',
            title,
            body,
          ]);
        });
      } else {
        _linuxPhaseTimer?.cancel();
        _linuxPhaseTimer = Timer(delay, () {
          Process.run('notify-send', [
            '-a',
            'BlinkKind',
            '-i',
            'blinkkind',
            if (isWorkComplete) ...[
              '-A',
              'postpone_break=Postpone',
              '-A',
              'skip_break=Skip',
            ],
            title,
            body,
          ]);
        });
      }
      return true;
    }

    await initialize();
    try {
      await _notificationsPlugin.cancel(id: id);
      final exactAlarmsAllowed =
          await exactAlarmStatus() == ExactAlarmStatus.allowed;
      final isWorkComplete = payload == 'work_complete';
      await _notificationsPlugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: tz.TZDateTime.now(tz.local).add(delay),
        notificationDetails: isWorkComplete
            ? _workCompleteNotificationDetails
            : _phaseNotificationDetails,
        androidScheduleMode: exactAlarmsAllowed
            ? AndroidScheduleMode.exactAllowWhileIdle
            : AndroidScheduleMode.inexactAllowWhileIdle,
        payload: payload,
      );
      final pending = await _notificationsPlugin.pendingNotificationRequests();
      return pending.any((request) => request.id == id);
    } on PlatformException catch (error) {
      debugPrint('Unable to schedule phase reminder: $error');
      return false;
    } on ArgumentError catch (error) {
      debugPrint('Unable to schedule phase reminder: $error');
      return false;
    }
  }

  Future<void> _playLinuxChimeFallback() async {
    try {
      final byteData = await rootBundle.load('assets/sounds/tibetan_bowl.wav');
      final tempDir = Directory.systemTemp;
      final file = File('${tempDir.path}/blinkkind_sounds/tibetan_bowl.wav');
      if (!await file.exists()) {
        await file.create(recursive: true);
        await file.writeAsBytes(byteData.buffer.asUint8List(), flush: true);
      }
      final audioUtils = ['pw-play', 'paplay', 'aplay'];
      for (final util in audioUtils) {
        try {
          final result = await Process.run(util, [file.path]);
          if (result.exitCode == 0) {
            break;
          }
        } catch (_) {}
      }
    } catch (e) {
      debugPrint('Error playing Linux test chime fallback: $e');
    }
  }

  void dispose() {
    _linuxPhaseTimer?.cancel();
    _linuxWarningTimer?.cancel();
    _linuxBlinkActionMonitor?.kill();
    _linuxBlinkActionMonitor = null;
  }
}
