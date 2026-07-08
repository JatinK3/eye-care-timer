import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/notification_service.dart';

class DeviceValidationPage extends StatefulWidget {
  const DeviceValidationPage({super.key});

  @override
  State<DeviceValidationPage> createState() => _DeviceValidationPageState();
}

class _DeviceValidationPageState extends State<DeviceValidationPage> {
  final NotificationService _notificationService = NotificationService();
  String _permissionStatus = 'Checking...';
  String _exactAlarmStatus = 'Checking...';
  String _batteryStatus = 'Checking...';

  @override
  void initState() {
    super.initState();
    _checkStatuses();
  }

  Future<void> _checkStatuses() async {
    if (!mounted) return;
    
    final permStatus = await _notificationService.permissionStatus();
    final alarmStatus = await _notificationService.exactAlarmStatus();
    final battStatus = await _notificationService.batteryOptimizationStatus();

    if (mounted) {
      setState(() {
        _permissionStatus = permStatus.name;
        _exactAlarmStatus = alarmStatus.name;
        _batteryStatus = battStatus.name;
      });
    }
  }

  Future<void> _testWellnessReminder() async {
    final success = await _notificationService.showTestWellnessReminder();
    _showResultSnackBar(success, 'Wellness reminder');
  }

  Future<void> _testWaterReminder() async {
    final success = await _notificationService.showTestWaterReminder();
    _showResultSnackBar(success, 'Water reminder (Check Action Log)');
  }

  Future<void> _testExactAlarmReminder() async {
    final success = await _notificationService.showTestReminder();
    _showResultSnackBar(success, 'Exact alarm (Expect 5s delay)');
  }

  void _showResultSnackBar(bool success, String testName) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? '$testName passed!' : '$testName failed!'),
        backgroundColor: success ? Colors.green : Colors.red,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Device Validation Mode'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildSectionHeader(theme, 'System Permissions & Capabilities'),
          ListTile(
            leading: const Icon(Icons.notifications),
            title: const Text('Notification Permission'),
            trailing: Text(_permissionStatus),
          ),
          ListTile(
            leading: const Icon(Icons.alarm),
            title: const Text('Exact Alarm Status'),
            trailing: Text(_exactAlarmStatus),
          ),
          ListTile(
            leading: const Icon(Icons.battery_alert),
            title: const Text('Battery Optimization'),
            trailing: Text(_batteryStatus),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _checkStatuses,
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh Statuses'),
          ),
          const Divider(height: 48),
          
          _buildSectionHeader(theme, 'Action & Background Tests'),
          ListTile(
            title: const Text('Test Wellness Reminder'),
            subtitle: const Text('Sends an immediate wellness blink reminder.'),
            trailing: const Icon(Icons.play_arrow),
            onTap: _testWellnessReminder,
          ),
          ListTile(
            title: const Text('Test Water Reminder'),
            subtitle: const Text('Sends an immediate water reminder with "Log a glass" action.'),
            trailing: const Icon(Icons.play_arrow),
            onTap: _testWaterReminder,
          ),
          ListTile(
            title: const Text('Test Exact Alarm (Background)'),
            subtitle: const Text('Schedules a reminder for 5 seconds in the future. Try minimizing the app after tapping to test background alarm precision.'),
            trailing: const Icon(Icons.play_arrow),
            onTap: _testExactAlarmReminder,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(ThemeData theme, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Text(
        title.toUpperCase(),
        style: theme.textTheme.labelMedium?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}
