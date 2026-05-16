import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Typography tokens — Montserrat (display/titles) + Inter (body).
///
/// Fonts are bundled in `assets/fonts/` (pinned, offline-safe).
/// No runtime fetch from Google Fonts → reliable in 2G/edge environments.
class AppTextStyles {
  AppTextStyles._();

  static const String _display = 'Montserrat';
  static const String _body = 'Inter';

  static TextTheme textTheme({Color color = AppColors.textPrimary}) {
    return TextTheme(
      displayLarge: TextStyle(
        fontFamily: _display,
        fontSize: 34,
        fontWeight: FontWeight.w900,
        letterSpacing: -1.0,
        color: color,
      ),
      displayMedium: TextStyle(
        fontFamily: _display,
        fontSize: 28,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
        color: color,
      ),
      displaySmall: TextStyle(
        fontFamily: _display,
        fontSize: 24,
        fontWeight: FontWeight.w800,
        color: color,
      ),
      headlineLarge: TextStyle(
        fontFamily: _display,
        fontSize: 26,
        fontWeight: FontWeight.w800,
        color: color,
      ),
      headlineMedium: TextStyle(
        fontFamily: _display,
        fontSize: 24,
        fontWeight: FontWeight.w800,
        color: color,
      ),
      headlineSmall: TextStyle(
        fontFamily: _display,
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: color,
      ),
      titleLarge: TextStyle(
        fontFamily: _display,
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: color,
      ),
      titleMedium: TextStyle(
        fontFamily: _display,
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: color,
      ),
      titleSmall: TextStyle(
        fontFamily: _display,
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: color,
      ),
      bodyLarge: TextStyle(
        fontFamily: _body,
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: color,
      ),
      bodyMedium: TextStyle(
        fontFamily: _body,
        fontSize: 15,
        fontWeight: FontWeight.w500,
        height: 1.4,
        color: color,
      ),
      bodySmall: TextStyle(
        fontFamily: _body,
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: color,
      ),
      labelLarge: TextStyle(
        fontFamily: _body,
        fontSize: 14,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
        color: color,
      ),
      labelMedium: TextStyle(
        fontFamily: _body,
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.4,
        color: color,
      ),
      labelSmall: TextStyle(
        fontFamily: _body,
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.3,
        color: color,
      ),
    );
  }
}
