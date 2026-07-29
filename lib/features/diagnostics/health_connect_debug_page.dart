import 'package:flutter/material.dart';

import '../../services/health_connect_sync_service.dart';
import '../../services/health_sync_coordinator.dart';
import '../../services/health_sync_service.dart';
import '../../services/preferences_service.dart';

/// Non-production probe for the Health Connect Phase 0 device checklist.
/// This page is only reachable from a debug Android build.
class HealthConnectDebugPage extends StatefulWidget {
  final VoidCallback onContinue;

  const HealthConnectDebugPage({super.key, required this.onContinue});

  @override
  State<HealthConnectDebugPage> createState() => _HealthConnectDebugPageState();
}

class _HealthConnectDebugPageState extends State<HealthConnectDebugPage> {
  final HealthConnectSyncService _service = HealthConnectSyncService();
  final PreferencesService _preferences = PreferencesService();
  HealthSyncStatus? _status;
  String? _error;
  String? _testResult;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final status = await _service.status();
      if (mounted) setState(() => _status = status);
    } on Object catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _requestPermission() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      await _service.requestWriteHydrationPermission();
      await _refresh();
    } on Object catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Exercises the production hydration path: local event, durable outbox, then
  /// a foreground Health Connect flush. It is intentionally debug-only.
  Future<void> _writeTestGlass() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _testResult = null;
    });
    try {
      final current = await _preferences.incrementWaterGlassesToday(1);
      await HealthSyncCoordinator(
        preferences: _preferences,
        service: _service,
      ).flushPending();
      final pending = await _preferences.loadHealthSyncOutbox();
      if (!mounted) return;
      setState(() {
        _testResult = pending.isEmpty
            ? 'Test glass logged and synced. Today: $current glass${current == 1 ? '' : 'es'}.'
            : 'Test glass logged locally. ${pending.length} sync operation${pending.length == 1 ? '' : 's'} still pending.';
      });
      await _refresh();
    } on Object catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Verifies the correction path deletes the matching client record instead
  /// of writing an offsetting hydration entry.
  Future<void> _undoTestGlass() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _testResult = null;
    });
    try {
      final current = await _preferences.incrementWaterGlassesToday(-1);
      await HealthSyncCoordinator(
        preferences: _preferences,
        service: _service,
      ).flushPending();
      final pending = await _preferences.loadHealthSyncOutbox();
      if (!mounted) return;
      setState(() {
        _testResult = pending.isEmpty
            ? 'Latest test glass was corrected and its Health Connect record was deleted. Today: $current.'
            : 'Correction saved locally. ${pending.length} sync operation${pending.length == 1 ? '' : 's'} still pending.';
      });
      await _refresh();
    } on Object catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = _status;
    return Scaffold(
      appBar: AppBar(title: const Text('Health Connect validation')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Debug-only Phase 0 probe',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text('Provider: ${status?.availability.name ?? 'Checking…'}'),
            Text(
              'WRITE_HYDRATION: ${status?.writeHydrationGranted == true ? 'Granted' : 'Not granted'}',
            ),
            if (status?.detail case final detail?) ...[
              const SizedBox(height: 8),
              Text(detail),
            ],
            if (_error case final error?) ...[
              const SizedBox(height: 12),
              Text(
                error,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            if (_testResult case final testResult?) ...[
              const SizedBox(height: 12),
              Text(testResult),
            ],
            const Spacer(),
            FilledButton(
              onPressed: _isLoading ? null : _requestPermission,
              child: const Text('Grant WRITE_HYDRATION'),
            ),
            const SizedBox(height: 12),
            FilledButton.tonal(
              onPressed: _isLoading || status?.canWrite != true
                  ? null
                  : _writeTestGlass,
              child: const Text('Write test glass and sync'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: _isLoading || status?.canWrite != true
                  ? null
                  : _undoTestGlass,
              child: const Text('Undo latest test glass and sync'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: _isLoading ? null : _refresh,
              child: const Text('Refresh status'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _isLoading ? null : widget.onContinue,
              child: const Text('Continue to BlinkKind'),
            ),
          ],
        ),
      ),
    );
  }
}
