import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app.dart';
import 'services/desktop_integration_service.dart';
import 'services/preferences_service.dart';
import 'models/timer_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Disable network font fetching — fonts are bundled via google_fonts assets.
  // This makes startup faster and works fully offline.
  GoogleFonts.config.allowRuntimeFetching = true;
  if (!kIsWeb && (Platform.isLinux || Platform.isMacOS || Platform.isWindows)) {
    final prefs = await SharedPreferences.getInstance();
    final startMinimized =
        prefs.getBool(PreferencesService.startMinimizedKey) ??
        TimerSettings.defaultStartMinimized;
    final autoStartSchedule =
        prefs.getBool(PreferencesService.autoStartScheduleKey) ??
        TimerSettings.defaultAutoStartSchedule;
    await DesktopIntegrationService.instance.initialize(
      startMinimized: startMinimized,
      autoStartSchedule: autoStartSchedule,
    );
  }
  runApp(const BlinkKindApp());
}
