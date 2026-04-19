import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class Skeleton extends StatelessWidget {
  const Skeleton({super.key, this.height = 16, this.width = double.infinity, this.radius = 8});
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
          color: Colors.black12,
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }
}
