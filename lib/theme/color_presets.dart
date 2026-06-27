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
  /// The two colors are placed at opposite corners of the screen.
  static List<Color> glassOrbColors(String preset, bool isDark, {String? customHex}) {
    if (preset == 'Custom' && customHex != null) {
      final base = _parseHexColor(customHex);
      final a = HSLColor.fromColor(base).withLightness(isDark ? 0.18 : 0.70).withSaturation(0.60).toColor();
      final b = HSLColor.fromColor(base).withLightness(isDark ? 0.10 : 0.85).withSaturation(0.45).toColor();
      return [a, b];
    }
    return switch (preset) {
      'Calm Blue' => isDark
          ? [const Color(0xFF1A4A7A), const Color(0xFF0D2444)]
          : [const Color(0xFF90C8F8), const Color(0xFFBFDFFB)],
      'Forest' => isDark
          ? [const Color(0xFF0D3D20), const Color(0xFF1A5530)]
          : [const Color(0xFF72C98A), const Color(0xFFAAE0B8)],
      'Rose' => isDark
          ? [const Color(0xFF5A1530), const Color(0xFF3A0E20)]
          : [const Color(0xFFF4A0BA), const Color(0xFFFAC8D8)],
      'Graphite' => isDark
          ? [const Color(0xFF1E2A38), const Color(0xFF2E3E50)]
          : [const Color(0xFFAAB8C8), const Color(0xFFCFD8E0)],
      'Sunrise' => isDark
          ? [const Color(0xFF6B2E10), const Color(0xFF4A1E08)]
          : [const Color(0xFFF7A060), const Color(0xFFFACDA0)],
      // Pastel / default
      _ => isDark
          ? [const Color(0xFF0E3535), const Color(0xFF1A4040)]
          : [const Color(0xFF80C8C0), const Color(0xFFAAE0D8)],
    };
  }

  static LinearGradient backgroundGradient(String preset, bool isDark, {String? customHex}) {
    if (preset == 'Custom' && customHex != null) {
      final color = _parseHexColor(customHex);
      if (isDark) {
        final darkBase = HSLColor.fromColor(color).withLightness(0.04).withSaturation(0.20).toColor();
        final darkMid  = HSLColor.fromColor(color).withLightness(0.08).withSaturation(0.25).toColor();
        return LinearGradient(
          colors: <Color>[darkBase, darkMid, const Color(0xFF060606)],
          stops: const [0.0, 0.55, 1.0],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        );
      } else {
        final lightBase = HSLColor.fromColor(color).withLightness(0.97).withSaturation(0.18).toColor();
        final lightMid  = HSLColor.fromColor(color).withLightness(0.93).withSaturation(0.22).toColor();
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
