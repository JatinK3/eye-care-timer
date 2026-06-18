import 'package:flutter/material.dart';

class ColorPresets {
  static const List<String> names = <String>[
    'Pastel',
    'Calm Blue',
    'Forest',
    'Rose',
    'Graphite',
    'Sunrise',
  ];

  static Color seedColor(String preset) {
    return switch (preset) {
      'Calm Blue' => Colors.blue,
      'Forest' => Colors.green,
      'Rose' => Colors.pink,
      'Graphite' => Colors.blueGrey,
      'Sunrise' => Colors.deepOrange,
      _ => Colors.teal,
    };
  }

  static Color swatchColor(String preset, bool isDark) {
    return switch (preset) {
      'Calm Blue' => isDark ? Colors.lightBlueAccent.shade100 : Colors.blue,
      'Forest' => isDark ? Colors.lightGreenAccent.shade100 : Colors.green,
      'Rose' => isDark ? Colors.pinkAccent.shade100 : Colors.pink,
      'Graphite' => isDark ? Colors.blueGrey.shade100 : Colors.blueGrey,
      'Sunrise' => isDark ? Colors.orangeAccent.shade100 : Colors.deepOrange,
      _ => isDark ? Colors.tealAccent.shade100 : Colors.teal,
    };
  }

  static LinearGradient backgroundGradient(String preset, bool isDark) {
    return switch (preset) {
      'Calm Blue' =>
        isDark
            ? const LinearGradient(
                colors: <Color>[Color(0xFF0F1724), Color(0xFF102A43)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : const LinearGradient(
                colors: <Color>[Color(0xFFDFF6FF), Color(0xFF9BBDF9)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
      'Forest' =>
        isDark
            ? const LinearGradient(
                colors: <Color>[Color(0xFF101914), Color(0xFF1E3327)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : const LinearGradient(
                colors: <Color>[Color(0xFFEEF8EF), Color(0xFFBFE6CA)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
      'Rose' =>
        isDark
            ? const LinearGradient(
                colors: <Color>[Color(0xFF1D1116), Color(0xFF3B1E2A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : const LinearGradient(
                colors: <Color>[Color(0xFFFFF1F5), Color(0xFFF8C9D8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
      'Graphite' =>
        isDark
            ? const LinearGradient(
                colors: <Color>[Color(0xFF111318), Color(0xFF242A31)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : const LinearGradient(
                colors: <Color>[Color(0xFFF4F6F8), Color(0xFFCED6DF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
      'Sunrise' =>
        isDark
            ? const LinearGradient(
                colors: <Color>[Color(0xFF1E1511), Color(0xFF3B251B)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : const LinearGradient(
                colors: <Color>[Color(0xFFFFF6E6), Color(0xFFF7C6A4)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
      _ =>
        isDark
            ? const LinearGradient(
                colors: <Color>[Color(0xFF101216), Color(0xFF1A1C1F)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : const LinearGradient(
                colors: <Color>[Color(0xFFF2F7F7), Color(0xFFEAF6F5)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
    };
  }

  static Color progressColor({
    required bool isBreak,
    required String preset,
    required bool isDark,
  }) {
    if (isBreak) {
      return isDark ? Colors.lightGreenAccent.shade100 : Colors.green;
    }
    return swatchColor(preset, isDark);
  }
}
