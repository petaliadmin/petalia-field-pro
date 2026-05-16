import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/formatters.dart';
import '../../../routes/route_names.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../theme/app_colors.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final box = Hive.box(AppConstants.boxReports);
    final reports = box.values
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList()
      ..sort((a, b) =>
          (b['createdAt'] as String).compareTo(a['createdAt'] as String));

    return Scaffold(
      appBar: AppBar(title: const Text('Rapports')),
      body: reports.isEmpty
          ? const EmptyState(
              icon: Icons.description_rounded,
              title: 'Aucun rapport pour l\'instant',
              message:
                  'Les rapports apparaîtront ici après leur génération depuis une visite.',
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: reports.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final r = reports[i];
                final createdAt =
                    DateTime.tryParse(r['createdAt'] as String? ?? '');
                return GlassCard(
                  onTap: () => context.push(Routes.reportPreview,
                      extra: {
                        'parcelId': r['parcelId'],
                        'filePath': r['filePath'],
                      }),
                  child: Row(
                    children: [
                      Container(
                        height: 44,
                        width: 44,
                        decoration: BoxDecoration(
                          color: AppColors.info.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.description_rounded,
                            color: AppColors.info),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              r['parcelName'] as String? ?? 'Rapport',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            Text(
                              '${r['crop'] ?? ''}'
                              '${createdAt != null ? ' · ${Fmt.dateTime(createdAt)}' : ''}',
                              style: TextStyle(
                                  color: AppColors.textSecondaryOf(context), fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right_rounded,
                          color: AppColors.textMutedOf(context)),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
