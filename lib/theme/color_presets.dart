import 'package:flutter/material.dart';

class ColorPresets {
  static const List<String> names = <String>[
    'Pastel',
    'Calm Blue',
    'Forest',
    'Rose',
    'Graphite',
    'Sunrise',
    'Custom',
  ];

  static Color _parseHexColor(String hex) {
    try {
      final buffer = StringBuffer();
      if (hex.length == 6 || hex.length == 7) buffer.write('ff');
      buffer.write(hex.replaceFirst('#', ''));
      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (e) {
      return Colors.teal;
    }
  }

  static Color seedColor(String preset, {String? customHex}) {
    if (preset == 'Custom' && customHex != null) {
      return _parseHexColor(customHex);
    }
    return switch (preset) {
      'Calm Blue' => Colors.blue,
      'Forest' => Colors.green,
      'Rose' => Colors.pink,
      'Graphite' => Colors.blueGrey,
      'Sunrise' => Colors.deepOrange,
      _ => Colors.teal,
    };
  }

  static Color swatchColor(String preset, bool isDark, {String? customHex}) {
    if (preset == 'Custom' && customHex != null) {
      return _parseHexColor(customHex);
    }
    return switch (preset) {
      'Calm Blue' => isDark ? Colors.lightBlueAccent.shade100 : Colors.blue,
      'Forest' => isDark ? Colors.lightGreenAccent.shade100 : Colors.green,
      'Rose' => isDark ? Colors.pinkAccent.shade100 : Colors.pink,
      'Graphite' => isDark ? Colors.blueGrey.shade100 : Colors.blueGrey,
      'Sunrise' => isDark ? Colors.orangeAccent.shade100 : Colors.deepOrange,
      _ => isDark ? Colors.tealAccent.shade100 : Colors.teal,
    };
  }

  /// Returns the orb/blob colors used for the glassmorphic background effect.
  /// Two orbs per preset — both from the same hue family for a cohesive look.
  static List<Color> glassOrbColors(String preset, bool isDark, {String? customHex}) {
    if (preset == 'Custom' && customHex != null) {
      final base = _parseHexColor(customHex);
      final a = HSLColor.fromColor(base).withLightness(isDark ? 0.38 : 0.70).withSaturation(0.80).toColor();
      final b = HSLColor.fromColor(base).withLightness(isDark ? 0.25 : 0.85).withSaturation(0.65).toColor();
      return [a, b];
    }
    return switch (preset) {
      // Vivid cyan-blue family
      'Calm Blue' => isDark
          ? [const Color(0xFF1565C0), const Color(0xFF0D47A1)]
          : [const Color(0xFF42A5F5), const Color(0xFF90CAF9)],
      // Vivid emerald-green family
      'Forest' => isDark
          ? [const Color(0xFF1B5E20), const Color(0xFF2E7D32)]
          : [const Color(0xFF43A047), const Color(0xFF81C784)],
      // Vivid pink-rose family
      'Rose' => isDark
          ? [const Color(0xFF880E4F), const Color(0xFFAD1457)]
          : [const Color(0xFFEC407A), const Color(0xFFF48FB1)],
      // Blue-grey family
      'Graphite' => isDark
          ? [const Color(0xFF37474F), const Color(0xFF455A64)]
          : [const Color(0xFF78909C), const Color(0xFFB0BEC5)],
      // Vivid amber-orange family
      'Sunrise' => isDark
          ? [const Color(0xFFE65100), const Color(0xFFBF360C)]
          : [const Color(0xFFFF7043), const Color(0xFFFFAB91)],
      // Teal family
      _ => isDark
          ? [const Color(0xFF006064), const Color(0xFF00838F)]
          : [const Color(0xFF26C6DA), const Color(0xFF80DEEA)],
    };
  }

  static LinearGradient backgroundGradient(String preset, bool isDark, {String? customHex}) {
    if (preset == 'Custom' && customHex != null) {
      final color = _parseHexColor(customHex);
      if (isDark) {
        final darkBase = HSLColor.fromColor(color).withLightness(0.08).withSaturation(0.60).toColor();
        final darkMid  = HSLColor.fromColor(color).withLightness(0.14).withSaturation(0.65).toColor();
        return LinearGradient(
          colors: <Color>[darkBase, darkMid, const Color(0xFF050505)],
          stops: const [0.0, 0.55, 1.0],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        );
      } else {
        final lightBase = HSLColor.fromColor(color).withLightness(0.92).withSaturation(0.40).toColor();
        final lightMid  = HSLColor.fromColor(color).withLightness(0.85).withSaturation(0.50).toColor();
        return LinearGradient(
          colors: <Color>[lightBase, lightMid, Colors.white],
          stops: const [0.0, 0.5, 1.0],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      }
    }
    return switch (preset) {
      'Calm Blue' =>
        isDark
            ? const LinearGradient(
                colors: <Color>[Color(0xFF060C18), Color(0xFF0B1A30), Color(0xFF050E1F)],
                stops: [0.0, 0.5, 1.0],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              )
            : const LinearGradient(
                colors: <Color>[Color(0xFFD2EEFF), Color(0xFFADD0F8), Color(0xFFEEF7FF)],
                stops: [0.0, 0.5, 1.0],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
      'Forest' =>
        isDark
            ? const LinearGradient(
                colors: <Color>[Color(0xFF040E08), Color(0xFF0A1C10), Color(0xFF060F09)],
                stops: [0.0, 0.5, 1.0],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              )
            : const LinearGradient(
                colors: <Color>[Color(0xFFE2F4E7), Color(0xFFB8E5C4), Color(0xFFF0FAF2)],
                stops: [0.0, 0.5, 1.0],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
      'Rose' =>
        isDark
            ? const LinearGradient(
                colors: <Color>[Color(0xFF10080D), Color(0xFF200F18), Color(0xFF0C060A)],
                stops: [0.0, 0.5, 1.0],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              )
            : const LinearGradient(
                colors: <Color>[Color(0xFFFFF0F4), Color(0xFFFAC4D5), Color(0xFFFFF8FA)],
                stops: [0.0, 0.5, 1.0],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
      'Graphite' =>
        isDark
            ? const LinearGradient(
                colors: <Color>[Color(0xFF080A0D), Color(0xFF141A22), Color(0xFF0A0D12)],
                stops: [0.0, 0.5, 1.0],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              )
            : const LinearGradient(
                colors: <Color>[Color(0xFFEDF0F3), Color(0xFFCBD4DE), Color(0xFFF5F7F9)],
                stops: [0.0, 0.5, 1.0],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
      'Sunrise' =>
        isDark
            ? const LinearGradient(
                colors: <Color>[Color(0xFF100907), Color(0xFF20140C), Color(0xFF0D0A07)],
                stops: [0.0, 0.5, 1.0],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              )
            : const LinearGradient(
                colors: <Color>[Color(0xFFFFF4E0), Color(0xFFF8BF88), Color(0xFFFFFAF0)],
                stops: [0.0, 0.5, 1.0],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
      // Pastel / default
      _ =>
        isDark
            ? const LinearGradient(
                colors: <Color>[Color(0xFF06090C), Color(0xFF101620), Color(0xFF07090D)],
                stops: [0.0, 0.5, 1.0],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              )
            : const LinearGradient(
                colors: <Color>[Color(0xFFECF6F6), Color(0xFFD0EDEC), Color(0xFFF5FAFA)],
                stops: [0.0, 0.5, 1.0],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
    };
  }

  static Color progressColor({
    required bool isBreak,
    required String preset,
    required bool isDark,
    String? customHex,
  }) {
    if (isBreak) {
      return isDark ? Colors.lightGreenAccent.shade100 : Colors.green;
    }
    return swatchColor(preset, isDark, customHex: customHex);
  }
}
