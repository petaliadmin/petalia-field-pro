import 'package:flutter/material.dart';

/// Brand palette for Petalia Field Pro.
class AppColors {
  AppColors._();

  // Brand
  static const Color primary = Color(0xFF0F6B3E);
  static const Color primaryDark = Color(0xFF0A4F2D);
  static const Color primaryLight = Color(0xFF3E9467);

  static const Color secondary = Color(0xFFF4F1EA);
  static const Color secondaryDark = Color(0xFFE4DFD3);

  static const Color accent = Color(0xFFD6A84F);
  static const Color accentDark = Color(0xFFB98A35);

  // Surfaces
  static const Color background = Color(0xFFFAFAF7);
  static const Color surface = Colors.white;
  static const Color surfaceAlt = Color(0xFFF6F5F1);

  // Dark surfaces
  static const Color darkBackground = Color(0xFF0F1411);
  static const Color darkSurface = Color(0xFF17201B);
  static const Color darkSurfaceAlt = Color(0xFF1F2A24);

  // Text
  static const Color textPrimary = Color(0xFF1A1D1A);
  static const Color textSecondary = Color(0xFF3D4A43);
  // Darkened from #5F6B64 → #4A544D to reach WCAG AA (≥4.5:1) on secondary backgrounds.
  static const Color textMuted = Color(0xFF4A544D);

  // Feedback
  static const Color success = Color(0xFF2E8B57);
  static const Color warning = Color(0xFFE5A83B);
  static const Color danger = Color(0xFFD9534F);
  static const Color info = Color(0xFF3B82F6);

  // Health gradient
  static const Color healthExcellent = Color(0xFF2E8B57);
  static const Color healthGood = Color(0xFF9CBF3F);
  static const Color healthFair = Color(0xFFE5A83B);
  static const Color healthPoor = Color(0xFFD9534F);

  // Utility
  static const Color divider = Color(0xFFE8E6DF);
  static const Color shadow = Color(0x14000000);

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
