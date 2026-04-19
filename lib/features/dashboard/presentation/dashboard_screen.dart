import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/services/alert_engine.dart';
import '../../../core/services/weather_service.dart';
import '../../../core/utils/formatters.dart';
import '../../../routes/route_names.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../shared/widgets/sync_indicator.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../theme/app_colors.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../parcels/presentation/parcels_providers.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).value?.user;
    final parcels = ref.watch(parcelsProvider);
    final alerts = ref.watch(alertEngineProvider);
    final unreadAlerts = alerts.where((a) => !a.isRead).length;
    final weatherAsync = ref.watch(weatherProvider);

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.read(parcelsProvider.notifier).refresh();
            ref.invalidate(weatherProvider);
            await Future.delayed(const Duration(milliseconds: 300));
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                    child: Text(
                      (user?.name.isNotEmpty ?? false) ? user!.name[0].toUpperCase() : 'T',
                      style: const TextStyle(
                          color: AppColors.primary, fontWeight: FontWeight.w800),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _greeting(),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                        ),
                        Text(
                          user?.name ?? 'Technicien',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ],
                    ),
                  ),
                  const SyncIndicator(),
                ],
              ),
              const SizedBox(height: 22),
              _WeatherCard(weather: weatherAsync),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      label: 'Mes parcelles',
                      value: '${parcels.length}',
                      icon: Icons.grass_rounded,
                      color: AppColors.primary,
                      onTap: () => context.go(Routes.parcels),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      label: 'Alertes',
                      value: '$unreadAlerts',
                      icon: Icons.notifications_active_rounded,
                      color: unreadAlerts > 0 ? AppColors.warning : AppColors.success,
                      onTap: () => context.push(Routes.alerts),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              const SectionHeader(title: 'Actions rapides'),
              PrimaryButton(
                label: 'Nouvelle visite de terrain',
                icon: Icons.camera_alt_rounded,
                onPressed: () {
                  if (parcels.isEmpty) return;
                  _showParcelPicker(context, parcels);
                },
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => context.go(Routes.parcels),
                  icon: const Icon(Icons.grass_rounded),
                  label: const Text('Voir mes parcelles'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
              // --- Actions du jour ---
              if (alerts.isNotEmpty) ...[
                const SizedBox(height: 22),
                SectionHeader(
                  title: 'Actions du jour',
                  action: TextButton(
                    onPressed: () => context.push(Routes.alerts),
                    child: const Text('Tout voir'),
                  ),
                ),
                ...alerts
                    .where((a) => !a.isRead)
                    .take(3)
                    .map((a) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _AlertActionCard(
                            alert: a,
                            onTap: () {
                              ref
                                  .read(alertEngineProvider.notifier)
                                  .markAsRead(a.id);
                              if (a.parcelId.isNotEmpty) {
                                context.push(
                                    '${Routes.parcelDetails}/${a.parcelId}');
                              }
                            },
                          ),
                        )),
              ],
              const SizedBox(height: 22),
              GlassCard(
                child: Row(
                  children: [
                    Container(
                      height: 48,
                      width: 48,
                      decoration: BoxDecoration(
                        color: _avgHealthColor(parcels).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        _avgHealthIcon(parcels),
                        color: _avgHealthColor(parcels),
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _avgHealthLabel(parcels),
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _avgHealthDetail(parcels),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (parcels.isNotEmpty) ...[
                const SizedBox(height: 16),
                _HealthChart(parcels: parcels),
              ],
              const SizedBox(height: 22),
              SectionHeader(
                title: 'Parcelles récentes',
                action: TextButton(
                  onPressed: () => context.go(Routes.parcels),
                  child: const Text('Tout voir'),
                ),
              ),
              ...parcels.take(3).map(
                    (p) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: GlassCard(
                        onTap: () => context.push('${Routes.parcelDetails}/${p.id}'),
                        child: Row(
                          children: [
                            Container(
                              height: 46,
                              width: 46,
                              decoration: BoxDecoration(
                                color: AppColors.healthFor(p.healthScore)
                                    .withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(AppColors.healthIconFor(p.healthScore),
                                  color: AppColors.healthFor(p.healthScore)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(p.name,
                                      style: Theme.of(context).textTheme.titleMedium),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${p.crop} · ${p.owner}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('${(p.healthScore * 100).round()}%',
                                    style: TextStyle(
                                      color: AppColors.healthFor(p.healthScore),
                                      fontWeight: FontWeight.w800,
                                    )),
                                const SizedBox(height: 2),
                                Text(
                                  Fmt.relative(p.lastVisit),
                                  style: const TextStyle(
                                      fontSize: 13, color: AppColors.textMuted),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Bonjour,';
    if (h < 18) return 'Bon après-midi,';
    return 'Bonsoir,';
  }

  void _showParcelPicker(BuildContext context, List parcels) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Choisir une parcelle',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            const Text('Quelle parcelle souhaitez-vous visiter ?',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            const SizedBox(height: 12),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.4,
              ),
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: parcels.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (_, i) {
                  final p = parcels[i];
                  return ListTile(
                    leading: Container(
                      height: 40,
                      width: 40,
                      decoration: BoxDecoration(
                        color: AppColors.healthFor(p.healthScore)
                            .withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        AppColors.healthIconFor(p.healthScore),
                        color: AppColors.healthFor(p.healthScore),
                        size: 22,
                      ),
                    ),
                    title: Text(p.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 15)),
                    subtitle: Text('${p.crop} · ${p.owner}',
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 13)),
                    trailing: const Icon(Icons.chevron_right_rounded,
                        color: AppColors.textMuted),
                    onTap: () {
                      Navigator.pop(context);
                      context.push('${Routes.observation}/${p.id}');
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  static Color _avgHealthColor(List parcels) {
    if (parcels.isEmpty) return AppColors.textMuted;
    final avg = parcels.fold<double>(0, (s, p) => s + p.healthScore) / parcels.length;
    return AppColors.healthFor(avg);
  }

  static IconData _avgHealthIcon(List parcels) {
    if (parcels.isEmpty) return Icons.info_outline_rounded;
    final avg = parcels.fold<double>(0, (s, p) => s + p.healthScore) / parcels.length;
    return AppColors.healthIconFor(avg);
  }

  static String _avgHealthLabel(List parcels) {
    if (parcels.isEmpty) return 'Aucune parcelle';
    final avg = parcels.fold<double>(0, (s, p) => s + p.healthScore) / parcels.length;
    if (avg >= 0.8) return 'Vos cultures vont bien';
    if (avg >= 0.6) return 'Cultures en bonne santé';
    if (avg >= 0.4) return 'Attention requise';
    return 'Situation critique';
  }

  static String _avgHealthDetail(List parcels) {
    if (parcels.isEmpty) return 'Ajoutez des parcelles pour commencer';
    final needAttention = parcels.where((p) => p.healthScore < 0.6).length;
    if (needAttention == 0) return 'Toutes vos parcelles sont en forme';
    return '$needAttention parcelle${needAttention > 1 ? 's' : ''} nécessite${needAttention > 1 ? 'nt' : ''} votre attention';
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.onTap,
  });
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 42,
            width: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 22, color: color),
          ),
          const SizedBox(height: 12),
          Text(value,
              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                    fontSize: 26,
                  )),
          Text(label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  )),
        ],
      ),
    );
  }
}

class _WeatherCard extends StatelessWidget {
  const _WeatherCard({required this.weather});
  final AsyncValue<WeatherSnapshot> weather;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      gradient: const LinearGradient(
        colors: [AppColors.primary, AppColors.primaryLight],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      child: weather.when(
        data: (w) => _content(
          title: '${w.tempC.round()}°C · ${w.condition}',
          subtitle:
              'Humidité ${w.humidity}% · Vent ${w.windKmh.round()} km/h${_stale(w) ? ' · ${_age(w)}' : ''}',
          icon: _iconFor(w.icon),
        ),
        loading: () => _content(
          title: 'Chargement météo…',
          subtitle: 'Récupération des conditions locales',
          icon: Icons.cloud_queue_rounded,
          showSpinner: true,
        ),
        error: (_, __) => _content(
          title: 'Météo indisponible',
          subtitle: 'Réessai à la prochaine synchronisation',
          icon: Icons.cloud_off_rounded,
        ),
      ),
    );
  }

  bool _stale(WeatherSnapshot w) =>
      DateTime.now().difference(w.fetchedAt) > const Duration(hours: 1);

  String _age(WeatherSnapshot w) {
    final diff = DateTime.now().difference(w.fetchedAt);
    if (diff.inHours >= 1) return 'il y a ${diff.inHours} h';
    return 'il y a ${diff.inMinutes} min';
  }

  IconData _iconFor(String key) => switch (key) {
        'sun' => Icons.wb_sunny_rounded,
        'rain' => Icons.umbrella_rounded,
        'storm' => Icons.thunderstorm_rounded,
        'fog' => Icons.foggy,
        'snow' => Icons.ac_unit_rounded,
        _ => Icons.wb_cloudy_rounded,
      };

  Widget _content({
    required String title,
    required String subtitle,
    required IconData icon,
    bool showSpinner = false,
  }) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Aujourd\'hui',
                  style: TextStyle(color: Colors.white70, fontSize: 13)),
              const SizedBox(height: 4),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
        ),
        Container(
          height: 60,
          width: 60,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(16),
          ),
          child: showSpinner
              ? const Padding(
                  padding: EdgeInsets.all(18),
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : Icon(icon, color: Colors.white, size: 30),
        ),
      ],
    );
  }
}

class _AlertActionCard extends StatelessWidget {
  const _AlertActionCard({required this.alert, this.onTap});
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
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 12),
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

/// Bar chart showing average parcel health over the last 7 days,
/// derived from observation timestamps in Hive.
class _HealthChart extends StatelessWidget {
  const _HealthChart({required this.parcels});
  final List parcels;

  @override
  Widget build(BuildContext context) {
    final data = _buildDayData();
    if (data.isEmpty) return const SizedBox.shrink();

    final dayLabels = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Sante des cultures — 7 jours',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
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
                            style: const TextStyle(
                                fontSize: 10, color: AppColors.textMuted));
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

  List<_DayHealth> _buildDayData() {
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
          _DayHealth(
            date: now.subtract(Duration(days: i)),
            avgHealth: avg,
          ),
      ];
    }

    return [
      for (var i = 6; i >= 0; i--)
        _DayHealth(
          date: now.subtract(Duration(days: i)),
          avgHealth: dayMap.containsKey(i)
              ? dayMap[i]!.reduce((a, b) => a + b) / dayMap[i]!.length
              : 0,
        ),
    ];
  }
}

class _DayHealth {
  final DateTime date;
  final double avgHealth;
  const _DayHealth({required this.date, required this.avgHealth});
}

