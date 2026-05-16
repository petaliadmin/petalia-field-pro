import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../theme/app_colors.dart';

/// Primitive shimmering block — a single rounded rectangle. Compose into
/// richer placeholders (see [SkeletonCard], [SkeletonList]) rather than
/// using directly when you can — a list of bare blocks rarely matches the
/// loaded layout closely enough to avoid a layout jump.
class Skeleton extends StatelessWidget {
  const Skeleton({
    super.key,
    this.height = 16,
    this.width = double.infinity,
    this.radius = 8,
  });
  final double height;
  final double width;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Shimmer.fromColors(
      baseColor: isDark ? Colors.white10 : Colors.black12,
      highlightColor: isDark ? Colors.white24 : Colors.black26,
      child: Container(
        height: height,
        width: width,
        decoration: BoxDecoration(
          color: isDark ? Colors.white10 : Colors.black12,
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }
}

/// Generic card-shaped placeholder that approximates the loaded layout of
/// most list rows in the app : a 42dp leading square + two stacked text
/// lines (title 60% width, subtitle 90%) inside a card-radius container.
/// Width matches the parent.
class SkeletonCard extends StatelessWidget {
  const SkeletonCard({super.key, this.height = 92});
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceOf(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.dividerOf(context), width: 0.6),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Skeleton(height: 42, width: 42, radius: 12),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FractionallySizedBox(
                  widthFactor: 0.6,
                  child: const Skeleton(height: 14, radius: 6),
                ),
                const SizedBox(height: 10),
                FractionallySizedBox(
                  widthFactor: 0.9,
                  child: const Skeleton(height: 11, radius: 6),
                ),
                const SizedBox(height: 6),
                FractionallySizedBox(
                  widthFactor: 0.4,
                  child: const Skeleton(height: 11, radius: 6),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Stack of [SkeletonCard]s with consistent spacing — drop-in replacement
/// for a list while data is being fetched. Use the [count] parameter to
/// roughly match the expected list length so the skeleton occupies the
/// same vertical space the loaded list will (avoids jump on completion).
class SkeletonList extends StatelessWidget {
  const SkeletonList({
    super.key,
    this.count = 4,
    this.padding = const EdgeInsets.fromLTRB(16, 8, 16, 32),
    this.cardHeight = 92,
  });

  final int count;
  final EdgeInsets padding;
  final double cardHeight;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: padding,
      itemCount: count,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, __) => SkeletonCard(height: cardHeight),
    );
  }
}
