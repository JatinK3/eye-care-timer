import 'dart:async';
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

class NotificationService {
  static const int _phaseReminderId = 1001;
  static const int _testReminderId = 1002;
  static const int _preBreakWarningReminderId = 1003;
  static const int _blinkReminderId = 1004;

  static const String _blinkChannelId = 'blinkkind_blink_reminders_v1';
  static const String _blinkChannelName = 'Blink reminders';
  static const String _blinkChannelDescription =
      'Gentle periodic reminders to blink consciously during work sessions.';
  static const AndroidNotificationChannel _blinkChannel =
      AndroidNotificationChannel(
        _blinkChannelId,
        _blinkChannelName,
        description: _blinkChannelDescription,
        importance: Importance.low,
        playSound: false,
        enableVibration: false,
      );
  static const NotificationDetails _blinkNotificationDetails =
      NotificationDetails(
        android: AndroidNotificationDetails(
          _blinkChannelId,
          _blinkChannelName,
          channelDescription: _blinkChannelDescription,
          importance: Importance.low,
          priority: Priority.low,
          playSound: false,
          enableVibration: false,
          silent: true,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(presentAlert: true, presentSound: false),
        macOS: DarwinNotificationDetails(
          presentAlert: true,
          presentSound: false,
        ),
      );

  Future<bool> schedulePreBreakWarningReminder(Duration delay, {bool isLongBreak = false}) {
    return _schedulePhaseReminder(
      id: _preBreakWarningReminderId,
      delay: delay,
      title: isLongBreak ? 'Long break starting soon' : 'Short break starting soon',
      body: isLongBreak ? 'Prepare to take a longer rest.' : 'Prepare to rest your eyes in 10 seconds.',
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

  static const MethodChannel _settingsChannel = MethodChannel(
    'eye_care_timer/notification_settings',
  );

  final FlutterLocalNotificationsPlugin _notificationsPlugin;
  bool _isInitialized = false;

  Timer? _linuxPhaseTimer;
  Timer? _linuxWarningTimer;

  NotificationService({FlutterLocalNotificationsPlugin? notificationsPlugin})
    : _notificationsPlugin =
          notificationsPlugin ?? FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    if (_isInitialized || kIsWeb) {
      return;
    }
    if (!kIsWeb && Platform.isLinux) {
      _isInitialized = true;
      return;
    }

    tz_data.initializeTimeZones();

    const initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
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

    await _notificationsPlugin.initialize(settings: initializationSettings);
    final android = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await android?.createNotificationChannel(_phaseChannel);
    await android?.createNotificationChannel(_blinkChannel);
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
          '-a', 'BlinkKind',
          '-i', 'blinkkind',
          'BlinkKind test reminder',
          'If you heard this, phase reminder sound is ready.',
        ]);
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

  Future<bool> scheduleWorkCompleteReminder(Duration delay, {bool isLongBreak = false}) {
    return _schedulePhaseReminder(
      delay: delay,
      title: isLongBreak ? 'Time for a Long Break' : 'Time for a Short Break',
      body: isLongBreak ? 'Take a longer rest to stretch and refresh.' : 'Look 20 ft away and rest your eyes.',
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

  /// Shows an immediate silent blink-conscious reminder notification.
  Future<void> showBlinkReminder() async {
    if (kIsWeb) return;

    const messages = [
      'Remember to blink! 👁️ Give your eyes some moisture.',
      '👁️ Blink consciously — your eyes will thank you!',
      'Time to blink! Dry eyes cause fatigue. Blink fully now.',
      '👀 Blink reminder — close and open your eyes fully.',
      '💧 Moisture check! Blink a few times to refresh your eyes.',
      '👁️ Soft blink — close your eyes slowly, then open. Repeat 3×.',
    ];
    final idx = DateTime.now().second % messages.length;
    final body = messages[idx];

    if (Platform.isLinux) {
      try {
        await Process.run('notify-send', [
          '-a', 'BlinkKind',
          '-i', 'blinkkind',
          '-u', 'low',
          '-t', '4000',
          'Blink reminder',
          body,
        ]);
      } catch (e) {
        debugPrint('Failed to send Linux blink notification: \$e');
      }
      return;
    }

    await initialize();
    try {
      await _notificationsPlugin.show(
        id: _blinkReminderId,
        title: 'Blink reminder 👁️',
        body: body,
        notificationDetails: _blinkNotificationDetails,
        payload: 'blink_reminder',
      );
    } on PlatformException catch (e) {
      debugPrint('Unable to show blink reminder: $e');
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
      if (id == _preBreakWarningReminderId) {
        _linuxWarningTimer?.cancel();
        _linuxWarningTimer = Timer(delay, () {
          Process.run('notify-send', [
            '-a', 'BlinkKind',
            '-i', 'blinkkind',
            title,
            body,
          ]);
        });
      } else {
        _linuxPhaseTimer?.cancel();
        _linuxPhaseTimer = Timer(delay, () {
          Process.run('notify-send', [
            '-a', 'BlinkKind',
            '-i', 'blinkkind',
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
      await _notificationsPlugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: tz.TZDateTime.now(tz.local).add(delay),
        notificationDetails: _phaseNotificationDetails,
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
}
