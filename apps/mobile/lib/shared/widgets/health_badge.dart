import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

class HealthBadge extends StatelessWidget {
  const HealthBadge({super.key, required this.score, this.compact = false});
  final double score;
  final bool compact;

  String get _label {
    if (score >= 0.8) return 'Excellent';
    if (score >= 0.6) return 'Bon';
    if (score >= 0.4) return 'Moyen';
    return 'Critique';
  }

  @override
  Widget build(BuildContext context) {
    final color = AppColors.healthFor(score);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 10 : 14, vertical: compact ? 6 : 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: color.withValues(alpha: 0.35), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            AppColors.healthIconFor(score),
            size: compact ? 16 : 18,
            color: color,
          ),
          SizedBox(width: compact ? 6 : 8),
          Text(
            compact ? _label : '$_label · ${(score * 100).round()}%',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: compact ? 13 : 15,
            ),
          ),
        ],
      ),
    );
  }
}
