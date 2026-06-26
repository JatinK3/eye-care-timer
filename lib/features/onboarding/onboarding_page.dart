import 'package:flutter/material.dart';

import '../../services/notification_service.dart';
import '../../generated/l10n/app_localizations.dart';

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
              '${AppLocalizations.of(context)!.appTitle}: Eye Break Timer',
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            Text(
              AppLocalizations.of(context)!.onboardingSubtitle,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            _OnboardingItem(
              icon: Icons.timer_outlined,
              title: AppLocalizations.of(context)!.onboardingFocusFirstTitle,
              body: AppLocalizations.of(context)!.onboardingFocusFirstBody,
            ),
            _OnboardingItem(
              icon: Icons.remove_red_eye_outlined,
              title: AppLocalizations.of(context)!.onboardingRestEyesTitle,
              body: AppLocalizations.of(context)!.onboardingRestEyesBody,
            ),
            _OnboardingItem(
              icon: Icons.notifications_active_outlined,
              title: AppLocalizations.of(context)!.onboardingAllowRemindersTitle,
              body: permissionBlocked
                  ? AppLocalizations.of(context)!.onboardingNotificationsBlocked
                  : AppLocalizations.of(context)!.onboardingNotificationsHelp,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: continueToApp,
              icon: const Icon(Icons.notifications_active_outlined),
              label: Text(AppLocalizations.of(context)!.onboardingAllowAndStart),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: skipNotifications,
              child: Text(
                AppLocalizations.of(context)!.onboardingContinueWithoutReminders,
              ),
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
                  style: const TextStyle(fontWeight: FontWeight.w600),
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
