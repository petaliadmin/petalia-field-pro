import 'dart:ui';
import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';

/// Premium glassmorphic card with backdrop blur and subtle borders.
///
/// In **High Visibility mode** (terrain plein soleil), automatically degrades
/// to a solid opaque surface with stronger border — blur + transparency hurt
/// outdoor legibility.
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.onTap,
    this.color,
    this.borderRadius = const BorderRadius.all(Radius.circular(24)),
    this.gradient,
    this.blur = 8.0,
    this.borderOpacity = 0.1,
    this.forceSolid = false,
    this.margin,
    this.width,
    this.height,
  });

  /// Solid variant (no blur, opaque). Use when this card sits over a
  /// scrolling list or in dense layouts to reduce GPU cost.
  const GlassCard.solid({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.onTap,
    this.color,
    this.borderRadius = const BorderRadius.all(Radius.circular(24)),
    this.gradient,
    this.borderOpacity = 0.1,
    this.margin,
    this.width,
    this.height,
  })  : blur = 0.0,
        forceSolid = true;

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? color;
  final BorderRadiusGeometry borderRadius;
  final Gradient? gradient;
  final double blur;
  final double borderOpacity;
  final bool forceSolid;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final highVis = HighVisibility.of(context);
    final solid = forceSolid || highVis;

    final bg = color ?? theme.colorScheme.surface;
    final bgAlpha = solid ? 1.0 : (isDark ? 0.75 : 0.85);
    final effectiveBlur = solid ? 0.0 : blur;
    final effectiveBorderOpacity = highVis ? 0.6 : borderOpacity;

    final localBorderRadius = borderRadius;
    final content = Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: localBorderRadius is BorderRadius ? localBorderRadius : null,
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            color: gradient == null ? bg.withValues(alpha: bgAlpha) : null,
            gradient: gradient,
            borderRadius: borderRadius,
            border: Border.all(
              color: (isDark ? Colors.white : AppColors.primary)
                  .withValues(alpha: effectiveBorderOpacity),
              width: highVis ? 1.6 : 1.2,
            ),
          ),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );

    return Container(
      margin: margin,
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: solid
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: solid
            ? content
            : BackdropFilter(
                filter: ImageFilter.blur(
                    sigmaX: effectiveBlur, sigmaY: effectiveBlur),
                child: content,
              ),
      ),
    );
  }
}
