import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/services/alert_engine.dart';
import '../../../core/utils/formatters.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../../routes/route_names.dart';
import '../../../shared/widgets/bento_grid.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/parcel_picker_sheet.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../shared/widgets/solid_card.dart';
import '../../../shared/widgets/sync_indicator.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../parcels/presentation/parcels_providers.dart';
import '../../../core/services/weather_service.dart';
import '../../../core/services/credit_service.dart';
import 'dashboard_providers.dart';
import 'widgets/alert_action_card.dart';
import 'widgets/health_chart.dart';
import 'widgets/hero_bento_card.dart';
import 'widgets/signal_status_bar.dart';
import 'widgets/stat_card.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final user = ref.watch(authStateProvider).value?.user;
    final parcels = ref.watch(parcelsProvider);
    final alerts = ref.watch(alertEngineProvider);
    final unreadAlerts = alerts.where((a) => !a.isRead).length;
    final weatherAsync = ref.watch(weatherProvider);
    final reportCount = ref.watch(reportCountProvider);
    final tourProgress = ref.watch(tourProgressProvider);

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.read(parcelsProvider.notifier).refresh();
            ref.invalidate(weatherProvider);
            await Future.delayed(const Duration(milliseconds: 300));
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Scaffold.of(context).openDrawer(),
                    icon: const Icon(Icons.menu_rounded, size: 28),
                    tooltip: 'Menu principal',
                  ),
                  const SizedBox(width: 4),
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.1), width: 2),
                    ),
                    child: CircleAvatar(
                      radius: 24,
                      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                      child: Text(
                        (user?.name.isNotEmpty ?? false) ? user!.name[0].toUpperCase() : 'T',
                        style: const TextStyle(
                            color: AppColors.primary, 
                            fontWeight: FontWeight.w900,
                            fontSize: 18),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _greeting(l10n).toUpperCase(),
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                color: AppColors.textMutedOf(context),
                                letterSpacing: 1.2,
                                fontSize: 11,
                              ),
                        ),
                        Text(
                          user?.name ?? 'Technicien',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Flexible(
                    child: SyncIndicator(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const SignalStatusBar(),
              const SizedBox(height: 12),
              BentoGrid(
                columns: 4,
                rowHeight: 92,
                gap: AppSpacing.md,
                children: [
                  BentoTile(
                    colSpan: 4,
                    rowSpan: 1,
                    child: HeroBentoCard(
                      weather: weatherAsync,
                      credits: ref.watch(creditServiceProvider),
                    ),
                  ),
                  BentoTile(
                    colSpan: 2,
                    child: StatCard(
                      label: l10n.parcelsTitle,
                      value: '${parcels.length}',
                      icon: Icons.grass_rounded,
                      color: AppColors.primary,
                      onTap: () => context.go(Routes.parcels),
                    ),
                  ),
                  BentoTile(
                    colSpan: 2,
                    child: StatCard(
                      label: l10n.tabAlerts,
                      value: '$unreadAlerts',
                      icon: Icons.notifications_active_rounded,
                      color: unreadAlerts > 0 ? AppColors.danger : AppColors.success,
                      onTap: () => context.push(Routes.alerts),
                    ),
                  ),
                  BentoTile(
                    colSpan: 2,
                    child: StatCard(
                      label: 'Tournée',
                      value: tourProgress,
                      icon: Icons.alt_route_rounded,
                      color: AppColors.primary,
                      onTap: () => context.push(Routes.routePlanner),
                    ),
                  ),
                  BentoTile(
                    colSpan: 2,
                    child: StatCard(
                      label: 'Rapports',
                      value: reportCount.toString(),
                      icon: Icons.description_rounded,
                      color: AppColors.primary,
                      onTap: () => context.push(Routes.reports),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              () {
                final tasks = ref.watch(dashboardTasksProvider);
                if (tasks.isEmpty) return const SizedBox.shrink();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SectionHeader(
                      title: 'À faire aujourd\'hui',
                      action: TextButton(
                        onPressed: () => context.go(Routes.parcels),
                        child: Text('${tasks.length} tâches'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 100,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: tasks.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 12),
                        itemBuilder: (context, i) {
                          final t = tasks[i];
                          final isHigh = t.priority == TaskPriority.high;
                          return GlassCard(
                            width: 260,
                            onTap: t.parcelId != null 
                              ? () => context.push('${Routes.parcelDetails}/${t.parcelId}')
                              : null,
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: (isHigh ? AppColors.danger : AppColors.primary).withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    isHigh ? Icons.priority_high_rounded : Icons.event_available_rounded,
                                    color: isHigh ? AppColors.danger : AppColors.primary,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        t.title,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        t.subtitle,
                                        style: TextStyle(fontSize: 11, color: AppColors.textSecondaryOf(context)),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                );
              }(),
              SectionHeader(
                title: l10n.dashboardQuickActions, 
              ),
              const SizedBox(height: 12),
              PrimaryButton(
                label: l10n.dashboardNewVisit,
                icon: Icons.add_a_photo_rounded,
                onPressed: () {
                  if (parcels.isEmpty) return;
                  showParcelPickerSheet(context, parcels);
                },
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => context.go(Routes.parcels),
                  icon: const Icon(Icons.grass_rounded),
                  label: Text(l10n.dashboardViewMyParcels),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
              if (alerts.isNotEmpty) ...[
                const SizedBox(height: 22),
                SectionHeader(
                  title: l10n.dashboardDailyActions,
                  action: TextButton(
                    onPressed: () => context.push(Routes.alerts),
                    child: Text(l10n.dashboardSeeAll),
                  ),
                ),
                ...alerts
                    .where((a) => !a.isRead)
                    .take(3)
                    .map((a) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: AlertActionCard(
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
                        color: _avgHealthColor(context, parcels).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        _avgHealthIcon(parcels),
                        color: _avgHealthColor(context, parcels),
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _avgHealthLabel(l10n, parcels),
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _avgHealthDetail(l10n, parcels),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.textSecondaryOf(context),
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
                HealthChart(parcels: parcels),
              ],
              const SizedBox(height: 22),
              SectionHeader(
                title: l10n.recentParcels,
                action: TextButton(
                  onPressed: () => context.go(Routes.parcels),
                  child: Text(l10n.seeAll),
                ),
              ),
              ...parcels.take(3).map(
                    (p) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: SolidCard(
                        onTap: () => context.push('${Routes.parcelDetails}/${p.id}'),
                        padding: AppSpacing.cardCompact,
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
                                        ?.copyWith(color: AppColors.textSecondaryOf(context)),
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
                                  Fmt.relative(p.lastVisit, l10n),
                                  style: TextStyle(
                                      fontSize: 13, color: AppColors.textMutedOf(context)),
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

  String _greeting(AppLocalizations l10n) {
    final h = DateTime.now().hour;
    if (h < 12) return l10n.greetingMorning;
    if (h < 18) return l10n.greetingAfternoon;
    return l10n.greetingEvening;
  }

  static Color _avgHealthColor(BuildContext context, List parcels) {
    if (parcels.isEmpty) return AppColors.textMutedOf(context);
    final avg = parcels.fold<double>(0, (s, p) => s + p.healthScore) / parcels.length;
    return AppColors.healthFor(avg);
  }

  static IconData _avgHealthIcon(List parcels) {
    if (parcels.isEmpty) return Icons.info_outline_rounded;
    final avg = parcels.fold<double>(0, (s, p) => s + p.healthScore) / parcels.length;
    return AppColors.healthIconFor(avg);
  }

  String _avgHealthLabel(AppLocalizations l10n, List parcels) {
    if (parcels.isEmpty) return l10n.healthNone;
    final avg =
        parcels.fold<double>(0, (s, p) => s + p.healthScore) / parcels.length;
    if (avg >= 0.8) return l10n.healthAllFine;
    if (avg >= 0.6) return l10n.healthGood;
    if (avg >= 0.4) return l10n.healthWarning;
    return l10n.healthCritical;
  }

  String _avgHealthDetail(AppLocalizations l10n, List parcels) {
    if (parcels.isEmpty) return l10n.parcelsEmptyMessage;
    final needAttention = parcels.where((p) => p.healthScore < 0.6).length;
    if (needAttention == 0) return l10n.healthAllFine;
    return l10n.healthNeedAttention(needAttention);
  }
}


