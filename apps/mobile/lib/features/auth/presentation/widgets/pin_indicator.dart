import 'package:flutter/material.dart';
import '../../../../theme/app_colors.dart';

class PinIndicator extends StatelessWidget {
  final int length;
  final int currentLength;
  final bool isError;

  const PinIndicator({
    super.key,
    required this.length,
    required this.currentLength,
    this.isError = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < length; i++)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: i < currentLength
                    ? (isError ? AppColors.danger : AppColors.primary)
                    : Colors.transparent,
                border: Border.all(
                  color: i < currentLength
                      ? (isError ? AppColors.danger : AppColors.primary)
                      : AppColors.dividerOf(context),
                  width: 2,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
