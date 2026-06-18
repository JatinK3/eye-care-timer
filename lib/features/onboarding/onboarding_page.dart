import 'package:flutter/material.dart';

import '../../services/notification_service.dart';

class OnboardingPage extends StatelessWidget {
  final NotificationPermissionStatus notificationPermissionStatus;
  final VoidCallback continueToApp;
  final VoidCallback skipNotifications;

  const OnboardingPage({
    super.key,
    required this.notificationPermissionStatus,
    required this.continueToApp,
    required this.skipNotifications,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final permissionBlocked =
        notificationPermissionStatus == NotificationPermissionStatus.disabled;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 24),
            Icon(
              Icons.visibility_outlined,
              size: 56,
              color: colorScheme.primary,
            ),
            const SizedBox(height: 20),
            Text(
              'BlinkKind: Eye Break Timer',
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            Text(
              'Follow the 20-20-20 habit with gentle reminders while you work.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            _OnboardingItem(
              icon: Icons.timer_outlined,
              title: 'Focus first',
              body:
                  'Start a focus session and keep the timer running in the app.',
            ),
            _OnboardingItem(
              icon: Icons.remove_red_eye_outlined,
              title: 'Rest your eyes',
              body:
                  'When work time ends, look away and relax your focus during the break.',
            ),
            _OnboardingItem(
              icon: Icons.notifications_active_outlined,
              title: 'Allow reminders',
              body: permissionBlocked
                  ? 'Notifications are blocked in system settings. You can recover them from Settings later.'
                  : 'Notifications help the timer still remind you when the app is not on screen.',
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: continueToApp,
              icon: const Icon(Icons.notifications_active_outlined),
              label: const Text('Allow reminders and start'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: skipNotifications,
              child: const Text('Continue without reminders'),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;

  const _OnboardingItem({
    required this.icon,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(body),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
