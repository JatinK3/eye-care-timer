import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'health_connect_settings_page.dart';

/// In-app privacy disclosure. A public policy URL is still required for a
/// Play release, but this page keeps the product's actual data behavior clear
/// and accessible before a user enables Health Connect.
class PrivacyHealthDataPage extends StatelessWidget {
  const PrivacyHealthDataPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isAndroid = !kIsWeb && Platform.isAndroid;
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy & Health Data')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _SectionCard(
            icon: Icons.phone_android_outlined,
            title: 'Stored on your device',
            body:
                'BlinkKind keeps your timer sessions, settings, focus history, and water-glass history on this device. You can clear local app data through Android system settings.',
          ),
          const SizedBox(height: 12),
          _SectionCard(
            icon: Icons.water_drop_outlined,
            title: 'Health Connect water sync',
            body:
                'Health Connect is optional and off by default. After you choose to enable it, BlinkKind writes only new water glasses that you log: the volume and timestamp. It does not request read access, backfill old daily totals, or write timer and break data.',
          ),
          if (isAndroid) ...[
            const SizedBox(height: 4),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.manage_accounts_outlined),
              title: const Text('Manage Health Connect water sync'),
              subtitle: const Text(
                'Review sync status, pause it, or manage access.',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const HealthConnectSettingsPage(),
                  ),
                );
              },
            ),
          ],
          const SizedBox(height: 12),
          _SectionCard(
            icon: Icons.cloud_outlined,
            title: 'Optional online services',
            body:
                'Analytics and crash reporting are disabled unless you enable them in Settings. If you configure an AI provider, the prompts you submit are sent to that provider to generate the requested response. Review the provider’s own privacy terms before enabling it.',
          ),
          const SizedBox(height: 12),
          _SectionCard(
            icon: Icons.policy_outlined,
            title: 'Public privacy policy',
            body:
                'A public privacy-policy link will be added here before the Google Play release. It will describe the same Health Connect, optional analytics, and optional AI-provider practices shown on this page.',
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;

  const _SectionCard({
    required this.icon,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 6),
                  Text(body),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
