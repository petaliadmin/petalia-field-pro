import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../../theme/app_colors.dart';

/// Bar chart showing average parcel health over the last 7 days,
/// derived from observation timestamps in Hive.
class HealthChart extends StatelessWidget {
  const HealthChart({super.key, required this.parcels});
  final List parcels;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final data = _buildDayData();
    if (data.isEmpty) return const SizedBox.shrink();

    final dayLabels = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.dashboardCropHealth7d,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
          const SizedBox(height: 16),
          SizedBox(
            height: 140,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 100,
                minY: 0,
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, _) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= data.length) {
                          return const SizedBox.shrink();
                        }
                        final wd = data[idx].date.weekday; // 1=Mon
                        return Text(dayLabels[wd - 1],
                            style: TextStyle(
                                fontSize: 10, color: AppColors.textMutedOf(context)));
                      },
                    ),
                  ),
                ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: [
                  for (var i = 0; i < data.length; i++)
                    BarChartGroupData(x: i, barRods: [
                      BarChartRodData(
                        toY: data[i].avgHealth,
                        width: 18,
                        color: AppColors.healthFor(data[i].avgHealth / 100),
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(6)),
                      ),
                    ]),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<DayHealth> _buildDayData() {
    final now = DateTime.now();
    final obsBox = Hive.box(AppConstants.boxObservations);

    // Collect observations per day for the last 7 days.
    final dayMap = <int, List<double>>{}; // dayOffset -> healthScores
    for (final raw in obsBox.values) {
      if (raw is! Map) continue;
      final at = DateTime.tryParse(raw['at']?.toString() ?? '');
      if (at == null) continue;
      final diff = now.difference(at).inDays;
      if (diff < 0 || diff > 6) continue;
      // Severity is 0..1 where 1 = worst. Convert to health = 1 - severity.
      final severity = (raw['severity'] as num?)?.toDouble() ?? 0.5;
      dayMap.putIfAbsent(diff, () => []).add((1 - severity) * 100);
    }

    // If no observations, fall back to current parcel health scores.
    if (dayMap.isEmpty) {
      final avg = parcels.isEmpty
          ? 0.0
          : parcels.fold<double>(0, (s, p) => s + p.healthScore) /
              parcels.length *
              100;
      return [
        for (var i = 6; i >= 0; i--)
          DayHealth(
            date: now.subtract(Duration(days: i)),
            avgHealth: avg,
          ),
      ];
    }

    return [
      for (var i = 6; i >= 0; i--)
        DayHealth(
          date: now.subtract(Duration(days: i)),
          avgHealth: dayMap.containsKey(i)
              ? dayMap[i]!.reduce((a, b) => a + b) / dayMap[i]!.length
              : 0,
        ),
    ];
  }
}

class DayHealth {
  final DateTime date;
  final double avgHealth;
  const DayHealth({required this.date, required this.avgHealth});
}
