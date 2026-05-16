import 'package:flutter/material.dart';

/// 4-tier shadow scale. Pure tokens — no Material elevation magic.
/// Outdoor-tuned: subtle at low tier (avoid washout), pronounced for floating.
class AppElevation {
  AppElevation._();

  /// Flat surface, no shadow. Use for inline cards in dense lists.
  static const List<BoxShadow> none = [];

  /// Resting surface (settled cards, sheets at rest).
  static const List<BoxShadow> low = [
    BoxShadow(
      color: Color(0x0F000000), // 6%
      blurRadius: 12,
      offset: Offset(0, 4),
    ),
  ];

  /// Default card elevation (hero KPIs, GlassCard default).
  static const List<BoxShadow> medium = [
    BoxShadow(
      color: Color(0x14000000), // ~8%
      blurRadius: 24,
      offset: Offset(0, 8),
    ),
  ];

  /// Floating elements: bottom sheets opening, dialogs.
  static const List<BoxShadow> high = [
    BoxShadow(
      color: Color(0x1F000000), // 12%
      blurRadius: 32,
      offset: Offset(0, 12),
    ),
  ];

  /// Modal / overlay shadow.
  static const List<BoxShadow> overlay = [
    BoxShadow(
      color: Color(0x29000000), // 16%
      blurRadius: 40,
      offset: Offset(0, 16),
    ),
  ];
}
