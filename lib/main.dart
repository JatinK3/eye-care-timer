import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app.dart';
import 'services/desktop_integration_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Disable network font fetching — fonts are bundled via google_fonts assets.
  // This makes startup faster and works fully offline.
  GoogleFonts.config.allowRuntimeFetching = true;
  if (!kIsWeb && (Platform.isLinux || Platform.isMacOS || Platform.isWindows)) {
    await DesktopIntegrationService.instance.initialize();
  }
  runApp(const BlinkKindApp());
}
