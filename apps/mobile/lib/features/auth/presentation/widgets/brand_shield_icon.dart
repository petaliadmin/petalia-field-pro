import 'package:flutter/material.dart';
import '../../../../theme/app_colors.dart';

class BrandShieldIcon extends StatelessWidget {
  final double size;
  const BrandShieldIcon({super.key, this.size = 80});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Icon(
        Icons.eco_rounded,
        color: Colors.white,
        size: size * 0.55,
      ),
    );
  }
}
