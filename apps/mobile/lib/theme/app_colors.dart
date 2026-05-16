import 'package:flutter/material.dart';

/// Brand palette for Petalia Field Pro.
class AppColors {
  AppColors._();

  // Brand - Nature Distilled Palette (Pro Max Standard)
  static const Color primary = Color(0xFF2E5A44); // Deep Forest Sage
  static const Color primaryDark = Color(0xFF1B3A2C);
  static const Color primaryLight = Color(0xFF4A7C5F);

  static const Color secondary = Color(0xFFF9F6F0); // Organic Parchment
  static const Color secondaryDark = Color(0xFFEEE8DA);

  static const Color accent = Color(0xFFB38D46); // Harvest Ochre (Darkened for contrast)
  static const Color accentDark = Color(0xFF8F6E32);
  static const Color accentLight = Color(0xFFD9B980);

  // Surfaces (4-tier hierarchy, light theme)
  static const Color background = Color(0xFFFDFCF8); // Eggshell Organic — page bg
  static const Color surface = Colors.white;          // Card / sheet — top tier
  static const Color surfaceElevated = Color(0xFFFFFFFF); // Floating dialogs
  static const Color surfaceSubtle = Color(0xFFF6F3E8);   // Inline subtle blocks
  static const Color surfaceAlt = Color(0xFFF0EDE2);      // Disabled / hover

  // Dark surfaces (Biomimetic Dark - Refined for visibility)
  static const Color darkBackground = Color(0xFF141916); // Moss Charcoal
  static const Color darkSurface = Color(0xFF1E2521);    // Forest Slate
  static const Color darkSurfaceAlt = Color(0xFF28322D); // Sage Shadow
  static const Color darkSurfaceElevated = Color(0xFF323D37); // Leaf Moss

  // Text (High Contrast for Outdoor — WCAG AA validated on Eggshell #FDFCF8)
  static const Color textPrimary = Color(0xFF0A0D0B);   // ~15:1
  static const Color textSecondary = Color(0xFF232B27); // ~11:1
  static const Color textMuted = Color(0xFF424D46);     // ~6.5:1
  static const Color textAccent = Color(0xFF8F6E32);    // ~5.5:1 (Ochre Text)

  // Feedback (Saturation boosted for terrain visibility)
  static const Color success = Color(0xFF247046);
  static const Color warning = Color(0xFFCC8D29);
  static const Color danger = Color(0xFFC53030);
  static const Color info = Color(0xFF1E60D5);

  // Health gradient (Accessible for colorblindness)
  static const Color healthExcellent = Color(0xFF247046);
  static const Color healthGood = Color(0xFF86A633);
  static const Color healthFair = Color(0xFFCC8D29);
  static const Color healthPoor = Color(0xFFC53030);

  // Dark text (mirrors light textPrimary/Secondary/Muted — for explicit dark usage)
  static const Color darkTextPrimary = Color(0xFFF2F5F3);   // Pure Mist
  static const Color darkTextSecondary = Color(0xFFC5CFC8); // Sage Grey
  static const Color darkTextMuted = Color(0xFF8B9B91);     // Moss Grey

  // Utility
  static const Color divider = Color(0xFFE8E6DF);
  static const Color darkDivider = Color(0x1FFFFFFF);  // white @ ~12% alpha
  static const Color shadow = Color(0x14000000);
  static const Color darkShadow = Color(0x52000000);   // black @ ~32% alpha

  /// Theme-aware surface (use when you can't reach Theme.of(context)).
  static Color surfaceOf(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? darkSurface : surface;

  /// Theme-aware alternate surface (slightly elevated).
  static Color surfaceAltOf(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? darkSurfaceAlt : surfaceSubtle;

  /// Theme-aware primary text color.
  static Color textPrimaryOf(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? darkTextPrimary : textPrimary;

  /// Theme-aware secondary text color.
  static Color textSecondaryOf(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? darkTextSecondary : textSecondary;

  /// Theme-aware muted text color.
  static Color textMutedOf(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? darkTextMuted : textMuted;

  /// Theme-aware divider color.
  static Color dividerOf(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? darkDivider : divider;

  /// Theme-aware shadow color.
  static Color shadowOf(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? darkShadow : shadow;

  static Color healthFor(double score) {
    if (score >= 0.8) return healthExcellent;
    if (score >= 0.6) return healthGood;
    if (score >= 0.4) return healthFair;
    return healthPoor;
  }

  /// Colorblind-safe icon per health level.
  static IconData healthIconFor(double score) {
    if (score >= 0.8) return Icons.check_circle_rounded;
    if (score >= 0.6) return Icons.thumb_up_rounded;
    if (score >= 0.4) return Icons.warning_rounded;
    return Icons.error_rounded;
  }
}
