import 'dart:async';

import 'package:flutter/material.dart';

import '../../services/health_connect_sync_service.dart';
import '../../services/health_sync_coordinator.dart';
import '../../services/health_sync_service.dart';
import '../../services/preferences_service.dart';

/// Android-only controls for BlinkKind's write-only hydration integration.
/// The app never requests read access or imports historical daily totals.
class HealthConnectSettingsPage extends StatefulWidget {
  const HealthConnectSettingsPage({super.key});

  @override
  State<HealthConnectSettingsPage> createState() =>
      _HealthConnectSettingsPageState();
}

class _HealthConnectSettingsPageState extends State<HealthConnectSettingsPage>
    with WidgetsBindingObserver {
  final PreferencesService _preferences = PreferencesService();
  final HealthConnectSyncService _service = HealthConnectSyncService();
  late final HealthSyncCoordinator _coordinator = HealthSyncCoordinator(
    preferences: _preferences,
    service: _service,
    isSyncEnabled: _preferences.loadHealthConnectSyncEnabled,
  );

  HealthSyncStatus? _status;
  bool _enabled = false;
  bool _loading = true;
  String? _message;
  int _pending = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_refresh());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(_refresh());
  }

  Future<void> _refresh() async {
    if (mounted) setState(() => _loading = true);
    try {
      final results = await Future.wait<Object>([
        _service.status(),
        _preferences.loadHealthConnectSyncEnabled(),
        _preferences.loadHealthSyncOutbox(),
      ]);
      if (!mounted) return;
      setState(() {
        _status = results[0] as HealthSyncStatus;
        _enabled = results[1] as bool;
        _pending = (results[2] as List).length;
      });
    } on Object catch (error) {
      if (mounted) setState(() => _message = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _setEnabled(bool enabled) async {
    if (!enabled) {
      await _preferences.saveHealthConnectSyncEnabled(false);
      if (mounted) {
        setState(() {
          _enabled = false;
          _message =
              'Sync paused. BlinkKind keeps your local hydration history.';
        });
      }
      return;
    }

    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sync water intake with Health Connect?'),
        content: const Text(
          'BlinkKind will write only new water glasses you log after enabling this setting. '
          'It will not read Health Connect data or backfill older daily totals. '
          'You can stop syncing here or manage access in Health Connect at any time.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Not now'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
    if (accepted != true) return;

    if (mounted) setState(() => _loading = true);
    try {
      final granted = await _service.requestWriteHydrationPermission();
      if (!granted) {
        if (mounted) {
          setState(() => _message = 'Health Connect access was not granted.');
        }
        return;
      }
      await _preferences.saveHealthConnectSyncEnabled(true);
      await _coordinator.flushPending();
      if (mounted) {
        setState(() => _message = 'Hydration sync is on.');
      }
    } on Object catch (error) {
      if (mounted) setState(() => _message = error.toString());
    } finally {
      await _refresh();
    }
  }

  Future<void> _retryPending() async {
    if (mounted) setState(() => _loading = true);
    try {
      await _coordinator.flushPending();
      if (mounted) setState(() => _message = 'Sync retry finished.');
    } on Object catch (error) {
      if (mounted) setState(() => _message = error.toString());
    } finally {
      await _refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = _status;
    final supported = status?.availability == HealthSyncAvailability.available;
    final accessGranted = status?.writeHydrationGranted == true;
    final statusText = switch (status?.availability) {
      HealthSyncAvailability.available =>
        accessGranted ? 'Ready to write hydration' : 'Permission needed',
      HealthSyncAvailability.updateRequired =>
        'Update Health Connect to continue',
      HealthSyncAvailability.unavailable => 'Health Connect is unavailable',
      HealthSyncAvailability.unsupported => 'Available on Android only',
      null => 'Checking Health Connect…',
    };

    return Scaffold(
      appBar: AppBar(title: const Text('Health Connect')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Water intake sync',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Writes only new glasses logged in BlinkKind. No reading, no historical backfill, and no timer or break data is shared.',
                  ),
                  const SizedBox(height: 12),
                  Text(statusText),
                  if (status?.detail case final detail?) ...[
                    const SizedBox(height: 4),
                    Text(detail),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            secondary: const Icon(Icons.water_drop_outlined),
            title: const Text('Sync with Health Connect'),
            subtitle: Text(
              _enabled
                  ? 'New water entries sync while BlinkKind is open.'
                  : 'Off',
            ),
            value: _enabled,
            onChanged: _loading || !supported ? null : _setEnabled,
          ),
          if (_enabled) ...[
            const Divider(),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.sync_outlined),
              title: const Text('Pending hydration changes'),
              subtitle: Text(
                _pending == 0
                    ? 'Everything is synced.'
                    : '$_pending waiting to sync.',
              ),
              trailing: TextButton(
                onPressed: _loading ? null : _retryPending,
                child: const Text('Retry now'),
              ),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.manage_accounts_outlined),
              title: const Text('Manage Health Connect access'),
              subtitle: const Text('Change or revoke BlinkKind permissions.'),
              onTap: _loading ? null : () => _service.openManageAccess(),
            ),
          ],
          if (_message case final message?) ...[
            const SizedBox(height: 12),
            Text(
              message,
              style: TextStyle(color: Theme.of(context).colorScheme.primary),
            ),
          ],
        ],
      ),
    );
  }
}
