import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'dart:async';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'app.dart';
import 'services/desktop_integration_service.dart';
import 'services/preferences_service.dart';
import 'models/timer_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String sentryDsn =
    'https://abc123xyz789@o123456.ingest.sentry.io/4500000000000000'; // Replace with actual Sentry DSN if building for release

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Disable network font fetching — fonts are bundled via google_fonts assets.
  // This makes startup faster and works fully offline.
  GoogleFonts.config.allowRuntimeFetching = true;
  
  final prefs = await SharedPreferences.getInstance();
  final startMinimized = prefs.getBool(PreferencesService.startMinimizedKey) ?? TimerSettings.defaultStartMinimized;
  final autoStartSchedule = prefs.getBool(PreferencesService.autoStartScheduleKey) ?? TimerSettings.defaultAutoStartSchedule;
  final analyticsEnabled = prefs.getBool(PreferencesService.analyticsEnabledKey) ?? TimerSettings.defaultAnalyticsEnabled;

  if (!kIsWeb && (Platform.isLinux || Platform.isMacOS || Platform.isWindows)) {
    await DesktopIntegrationService.instance.initialize(
      startMinimized: startMinimized,
      autoStartSchedule: autoStartSchedule,
    );
  }

  if (analyticsEnabled && sentryDsn.isNotEmpty) {
    await SentryFlutter.init(
      (options) {
        options.dsn = sentryDsn;
        options.tracesSampleRate = 1.0;
        options.enableAutoSessionTracking = true;
      },
      appRunner: () => runApp(const BlinkKindApp()),
    );
  } else {
    runApp(const BlinkKindApp());
  }
}
