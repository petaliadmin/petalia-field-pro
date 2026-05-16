import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../theme/app_colors.dart';
import '../../../l10n/gen/app_localizations.dart';

// ---------------------------------------------------------------------------
// Alert model
// ---------------------------------------------------------------------------

class Alert {
  final String id;
  final String type; // weather, irrigation, pest, visit
  final String severity; // high, medium, low
  final String title;
  final String message;
  final String parcelId;
  final DateTime at;
  final bool read;

  const Alert({
    required this.id,
    required this.type,
    required this.severity,
    required this.title,
    required this.message,
    required this.parcelId,
    required this.at,
    required this.read,
  });

  factory Alert.fromMap(Map m) => Alert(
        id: m['id'] as String,
        type: m['type'] as String,
        severity: m['severity'] as String,
        title: m['title'] as String,
        message: m['message'] as String,
        parcelId: m['parcelId'] as String? ?? '',
        at: DateTime.parse(m['at'] as String),
        read: m['read'] as bool? ?? false,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'type': type,
        'severity': severity,
        'title': title,
        'message': message,
        'parcelId': parcelId,
        'at': at.toIso8601String(),
        'read': read,
      };
}

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

final _alertsFilterProvider = StateProvider<String>((_) => 'all');

final alertsProvider =
    StateNotifierProvider<AlertsController, List<Alert>>((ref) {
  return AlertsController();
});

class AlertsController extends StateNotifier<List<Alert>> {
  AlertsController() : super([]) {
    refresh();
  }

  Box get _box => Hive.box(AppConstants.boxAlerts);

  void refresh() {
    final raw = _box.values.toList();
    final alerts = raw.map((e) => Alert.fromMap(Map<String, dynamic>.from(e as Map))).toList()
      ..sort((a, b) => b.at.compareTo(a.at));
    state = alerts;
  }

  void markRead(String id) {
    final key = _box.keys.firstWhere(
      (k) => (_box.get(k) as Map)['id'] == id,
      orElse: () => null,
    );
    if (key == null) return;
    final data = Map<String, dynamic>.from(_box.get(key) as Map);
    data['read'] = true;
    _box.put(key, data);
    refresh();
  }

  void markAllRead() {
    for (final k in _box.keys) {
      final data = Map<String, dynamic>.from(_box.get(k) as Map);
      data['read'] = true;
      _box.put(k, data);
    }
    refresh();
  }
}

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class AlertsScreen extends ConsumerWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allAlerts = ref.watch(alertsProvider);
    final filter = ref.watch(_alertsFilterProvider);
    final alerts = filter == 'all'
        ? allAlerts
        : allAlerts.where((a) => a.severity == filter).toList();
    final unreadCount = allAlerts.where((a) => !a.read).length;

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 20, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Scaffold.of(context).openDrawer(),
                    icon: const Icon(Icons.menu_rounded, size: 28),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Alertes',
                            style: Theme.of(context).textTheme.headlineSmall),
                        if (unreadCount > 0)
                          Text(
                            '$unreadCount non lue${unreadCount > 1 ? 's' : ''}',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: AppColors.warning),
                          ),
                      ],
                    ),
                  ),
                  if (unreadCount > 0)
                    TextButton.icon(
                      onPressed: () =>
                          ref.read(alertsProvider.notifier).markAllRead(),
                      icon: const Icon(Icons.done_all_rounded, size: 18),
                      label: const Text('Tout marquer lu'),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Filter chips
            SizedBox(
              height: 48,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  _FilterChip(
                    label: 'Toutes',
                    selected: filter == 'all',
                    onTap: () =>
                        ref.read(_alertsFilterProvider.notifier).state = 'all',
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Urgent',
                    selected: filter == 'high',
                    color: AppColors.danger,
                    onTap: () =>
                        ref.read(_alertsFilterProvider.notifier).state = 'high',
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Moyen',
                    selected: filter == 'medium',
                    color: AppColors.warning,
                    onTap: () =>
                        ref.read(_alertsFilterProvider.notifier).state =
                            'medium',
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Faible',
                    selected: filter == 'low',
                    color: AppColors.info,
                    onTap: () =>
                        ref.read(_alertsFilterProvider.notifier).state = 'low',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // List
            Expanded(
              child: alerts.isEmpty
                  ? const EmptyState(
                      icon: Icons.notifications_off_rounded,
                      title: 'Aucune alerte',
                      message: 'Rien à signaler pour le moment.',
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                      itemCount: alerts.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, i) => _AlertTile(alert: alerts[i]),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Widgets
// ---------------------------------------------------------------------------

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.color,
  });
  final String label;
  final bool selected;
  final Color? color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.primary;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? c : c.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : c,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

class _AlertTile extends ConsumerWidget {
  const _AlertTile({required this.alert});
  final Alert alert;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GlassCard(
      onTap: () {
        if (!alert.read) {
          ref.read(alertsProvider.notifier).markRead(alert.id);
        }
        _showDetail(context);
      },
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 42,
            width: 42,
            decoration: BoxDecoration(
              color: _severityColor(alert.severity).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(_typeIcon(alert.type),
                color: _severityColor(alert.severity), size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(alert.title,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight:
                                    alert.read ? FontWeight.w500 : FontWeight.w700,
                              )),
                    ),
                    if (!alert.read)
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(alert.message,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: AppColors.textSecondaryOf(context))),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _SeverityBadge(severity: alert.severity),
                    const Spacer(),
                    Text(Fmt.relative(alert.at, AppLocalizations.of(context)),
                        style: TextStyle(
                            fontSize: 11, color: AppColors.textMutedOf(context))),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.dividerOf(context),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  height: 48,
                  width: 48,
                  decoration: BoxDecoration(
                    color:
                        _severityColor(alert.severity).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(_typeIcon(alert.type),
                      color: _severityColor(alert.severity)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(alert.title,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w700)),
                      _SeverityBadge(severity: alert.severity),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(alert.message,
                style: TextStyle(
                    fontSize: 15, color: AppColors.textSecondaryOf(context), height: 1.5)),
            const SizedBox(height: 12),
            Text(
              Fmt.dateTime(alert.at),
              style:
                  TextStyle(fontSize: 12, color: AppColors.textMutedOf(context)),
            ),
          ],
        ),
      ),
    );
  }

  static IconData _typeIcon(String type) => switch (type) {
        'weather' => Icons.thunderstorm_rounded,
        'irrigation' => Icons.water_drop_rounded,
        'pest' => Icons.bug_report_rounded,
        'visit' => Icons.schedule_rounded,
        _ => Icons.warning_amber_rounded,
      };

  static Color _severityColor(String severity) => switch (severity) {
        'high' => AppColors.danger,
        'medium' => AppColors.warning,
        _ => AppColors.info,
      };
}

class _SeverityBadge extends StatelessWidget {
  const _SeverityBadge({required this.severity});
  final String severity;

  @override
  Widget build(BuildContext context) {
    final color = switch (severity) {
      'high' => AppColors.danger,
      'medium' => AppColors.warning,
      _ => AppColors.info,
    };
    return Container(
      margin: const EdgeInsets.only(top: 2),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        switch (severity) {
          'high' => 'URGENT',
          'medium' => 'MOYEN',
          _ => 'FAIBLE',
        },
        style: TextStyle(
            color: color, fontSize: 12, fontWeight: FontWeight.w700),
      ),
    );
  }
}
