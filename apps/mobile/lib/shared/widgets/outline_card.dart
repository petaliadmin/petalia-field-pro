import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';

/// Lightweight card with a stroke and no fill — useful for pickers,
/// selectable options, and form sections that should not dominate.
class OutlineCard extends StatelessWidget {
  const OutlineCard({
    super.key,
    required this.child,
    this.padding = AppSpacing.cardCompact,
    this.onTap,
    this.borderColor,
    this.borderWidth = 1.4,
    this.borderRadius = AppRadius.md,
    this.selected = false,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? borderColor;
  final double borderWidth;
  final double borderRadius;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final defaultBorder = AppColors.dividerOf(context);
    final selectedBorder = AppColors.primary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(borderRadius),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius),
            color: selected
                ? AppColors.primary.withValues(alpha: 0.06)
                : Colors.transparent,
            border: Border.all(
              color: borderColor ??
                  (selected ? selectedBorder : defaultBorder),
              width: selected ? borderWidth + 0.4 : borderWidth,
            ),
          ),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}
