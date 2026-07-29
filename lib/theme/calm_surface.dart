import 'package:flutter/material.dart';

/// The shared visual language for BlinkKind's calm, focus-first surfaces.
///
/// Content surfaces remain mostly opaque for readable text, predictable
/// contrast, and inexpensive rendering. Accent tint is used only to establish
/// hierarchy or communicate a state; it is not a substitute for the surface.
abstract final class CalmSurface {
  static const double radius = 18;
  static const double compactRadius = 14;

  static Color color(ThemeData theme, {Color? accent, double tint = 0}) {
    final base = theme.brightness == Brightness.dark
        ? const Color(0xFF151A22)
        : const Color(0xFFFCFDFE);
    if (accent == null || tint <= 0) return base;
    return Color.alphaBlend(accent.withValues(alpha: tint), base);
  }

  static BorderSide border(ThemeData theme, {Color? accent}) {
    final color = accent ?? theme.colorScheme.outlineVariant;
    return BorderSide(
      color: color.withValues(
        alpha: accent == null
            ? (theme.brightness == Brightness.dark ? 0.48 : 0.72)
            : 0.32,
      ),
    );
  }

  static List<BoxShadow> shadows(ThemeData theme, {bool raised = false}) {
    final alpha = theme.brightness == Brightness.dark ? 0.28 : 0.10;
    return <BoxShadow>[
      BoxShadow(
        color: Colors.black.withValues(alpha: raised ? alpha : alpha * 0.65),
        blurRadius: raised ? 22 : 12,
        offset: Offset(0, raised ? 10 : 5),
      ),
    ];
  }

  static CardThemeData cardTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    return CardThemeData(
      color: isDark ? const Color(0xFF151A22) : const Color(0xFFFCFDFE),
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius),
        side: BorderSide(
          color: isDark ? const Color(0xFF303946) : const Color(0xFFDCE3EA),
        ),
      ),
      shadowColor: Colors.black.withValues(alpha: isDark ? 0.28 : 0.10),
      surfaceTintColor: Colors.transparent,
      clipBehavior: Clip.antiAlias,
    );
  }
}
