import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// Horizontal stepper showing the current step in the observation workflow.
///
/// Steps: 0 = Observer, 1 = Conseils, 2 = Rapport
class WorkflowStepper extends StatelessWidget {
  const WorkflowStepper({super.key, required this.currentStep});

  /// 0 = Observer, 1 = Conseils, 2 = Rapport
  final int currentStep;

  static const _labels = ['1. Observer', '2. Conseils', '3. Rapport'];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.secondary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          for (int i = 0; i < _labels.length; i++) ...[
            if (i > 0) _buildLine(completed: i <= currentStep),
            _buildStep(index: i),
          ],
        ],
      ),
    );
  }

  Widget _buildStep({required int index}) {
    final isCompleted = index < currentStep;
    final isCurrent = index == currentStep;
    final isActive = isCompleted || isCurrent;

    final bgColor = isActive ? AppColors.primary : AppColors.textMuted;
    final fgColor = isActive ? Colors.white : AppColors.textMuted;

    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isActive
                  ? bgColor
                  : bgColor.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: isCompleted
                ? Icon(Icons.check_rounded, size: 18, color: fgColor)
                : Text(
                    '${index + 1}',
                    style: TextStyle(
                      color: isActive ? fgColor : AppColors.textMuted,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
          ),
          const SizedBox(height: 6),
          Text(
            _labels[index],
            style: TextStyle(
              color: isActive ? AppColors.primary : AppColors.textMuted,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              fontSize: 11,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildLine({required bool completed}) {
    return Flexible(
      flex: 0,
      child: Container(
        width: 24,
        height: 2,
        margin: const EdgeInsets.only(bottom: 18),
        color: completed ? AppColors.primary : AppColors.textMuted.withValues(alpha: 0.3),
      ),
    );
  }
}
