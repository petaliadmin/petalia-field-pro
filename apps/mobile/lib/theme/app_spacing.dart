import 'package:flutter/widgets.dart';

/// 8-pt spacing scale. Use these tokens instead of magic numbers.
///
/// ```
/// Padding(padding: EdgeInsets.all(AppSpacing.md), child: ...)
/// SizedBox(height: AppSpacing.lg)
/// ```
class AppSpacing {
  AppSpacing._();

  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;

  // Common composite paddings
  static const EdgeInsets pageH = EdgeInsets.symmetric(horizontal: lg);
  static const EdgeInsets pageAll = EdgeInsets.all(lg);
  static const EdgeInsets cardAll = EdgeInsets.all(xl);
  static const EdgeInsets cardCompact =
      EdgeInsets.symmetric(horizontal: lg, vertical: md);

  // Vertical gaps as widgets (less verbose than SizedBox(height: ...))
  static const Widget gapXs = SizedBox(height: xs);
  static const Widget gapSm = SizedBox(height: sm);
  static const Widget gapMd = SizedBox(height: md);
  static const Widget gapLg = SizedBox(height: lg);
  static const Widget gapXl = SizedBox(height: xl);
  static const Widget gapXxl = SizedBox(height: xxl);

  // Horizontal gaps
  static const Widget hGapXs = SizedBox(width: xs);
  static const Widget hGapSm = SizedBox(width: sm);
  static const Widget hGapMd = SizedBox(width: md);
  static const Widget hGapLg = SizedBox(width: lg);
}
