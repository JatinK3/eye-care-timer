import 'package:flutter/material.dart';
import '../../services/notification_service.dart';


class ReminderReliabilityPage extends StatefulWidget {
  final NotificationReliabilityStatus initialStatus;
  final Future<NotificationReliabilityStatus> Function() refreshStatus;
  final Future<void> Function() openNotificationSettings;
  final Future<void> Function() requestExactAlarmPermission;
  final Future<void> Function() openBatteryOptimizationSettings;
  final Future<void> Function() showTestReminder;
  final Future<void> Function() showTestWellnessReminder;
  final Future<void> Function() showTestWaterReminder;

  const ReminderReliabilityPage({
    super.key,
    required this.initialStatus,
    required this.refreshStatus,
    required this.openNotificationSettings,
    required this.requestExactAlarmPermission,
    required this.openBatteryOptimizationSettings,
    required this.showTestReminder,
    required this.showTestWellnessReminder,
    required this.showTestWaterReminder,
  });

  @override
  State<ReminderReliabilityPage> createState() => _ReminderReliabilityPageState();
}

class _ReminderReliabilityPageState extends State<ReminderReliabilityPage> {
  late NotificationReliabilityStatus _status;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _status = widget.initialStatus;
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() {
      _isLoading = true;
    });
    final newStatus = await widget.refreshStatus();
    if (mounted) {
      setState(() {
        _status = newStatus;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reminder Reliability'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _refresh,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildStatusTile(
            title: 'Notification Permission',
            isOk: _status.permission == NotificationPermissionStatus.allowed,
            onFix: widget.openNotificationSettings,
          ),
          _buildStatusTile(
            title: 'Exact Alarms',
            isOk: _status.exactAlarms == ExactAlarmStatus.allowed || _status.exactAlarms == ExactAlarmStatus.unsupported,
            onFix: widget.requestExactAlarmPermission,
          ),
          _buildStatusTile(
            title: 'Battery Optimization',
            isOk: _status.batteryOptimization == BatteryOptimizationStatus.unrestricted || _status.batteryOptimization == BatteryOptimizationStatus.unsupported,
            onFix: widget.openBatteryOptimizationSettings,
          ),
          const SizedBox(height: 24),
          Text('Diagnostics', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ListTile(
            title: const Text('Pending Phase Reminder'),
            subtitle: Text(_status.hasPendingPhaseReminder ? 'Scheduled' : 'None'),
            leading: Icon(
              _status.hasPendingPhaseReminder ? Icons.timer : Icons.timer_off,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: widget.showTestReminder,
            icon: const Icon(Icons.notifications_active),
            label: const Text('Test Phase Reminder'),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: widget.showTestWellnessReminder,
            icon: const Icon(Icons.self_improvement),
            label: const Text('Test Wellness Reminder'),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: widget.showTestWaterReminder,
            icon: const Icon(Icons.water_drop),
            label: const Text('Test Water Reminder'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusTile({
    required String title,
    required bool isOk,
    required VoidCallback onFix,
  }) {
    return ListTile(
      title: Text(title),
      subtitle: Text(isOk ? 'OK' : 'Requires Action'),
      leading: Icon(
        isOk ? Icons.check_circle : Icons.error,
        color: isOk ? Colors.green : Colors.red,
      ),
      trailing: isOk ? null : ElevatedButton(
        onPressed: onFix,
        child: const Text('Fix'),
      ),
    );
  }
}
