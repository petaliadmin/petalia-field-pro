import 'package:flutter/material.dart';

import '../../../../core/services/alert_engine.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../../theme/app_colors.dart';

class AlertActionCard extends StatelessWidget {
  const AlertActionCard({super.key, required this.alert, this.onTap});
  final Alert alert;
  final VoidCallback? onTap;

  Color get _color => switch (alert.severity) {
        AlertSeverity.urgent => AppColors.danger,
        AlertSeverity.high => AppColors.danger,
        AlertSeverity.medium => AppColors.warning,
        AlertSeverity.low => AppColors.info,
      };

  IconData get _icon => switch (alert.category) {
        AlertCategory.weather => Icons.cloud_rounded,
        AlertCategory.irrigation => Icons.water_drop_rounded,
        AlertCategory.pest => Icons.bug_report_rounded,
        AlertCategory.disease => Icons.healing_rounded,
        AlertCategory.visit => Icons.event_busy_rounded,
        AlertCategory.growthStage => Icons.eco_rounded,
        AlertCategory.other => Icons.info_outline_rounded,
      };

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            height: 40,
            width: 40,
            decoration: BoxDecoration(
              color: _color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(_icon, size: 20, color: _color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(alert.title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 14)),
                const SizedBox(height: 2),
                Text(
                  alert.message,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      color: AppColors.textSecondaryOf(context), fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(Icons.chevron_right_rounded, color: _color, size: 20),
        ],
      ),
    );
  }
}
