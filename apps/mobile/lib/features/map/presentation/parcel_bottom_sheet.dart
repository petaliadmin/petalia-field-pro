import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/services/ndvi_service.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/geo_utils.dart';
import '../../../routes/route_names.dart';
import '../../../shared/widgets/health_badge.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../theme/app_colors.dart';
import '../../parcels/domain/parcel.dart';

class ParcelBottomSheet extends ConsumerWidget {
  const ParcelBottomSheet({super.key, required this.parcel});
  final Parcel parcel;

  static Future<void> show(BuildContext context, Parcel parcel) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ParcelBottomSheet(parcel: parcel),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final area = GeoUtils.polygonAreaHa(parcel.boundary);
    
    final ndviAsync = ref.watch(ndviProvider(parcel.id));
    final score = ndviAsync.maybeWhen(
      data: (n) => n.value,
      orElse: () => parcel.healthScore,
    );
    final healthColor = AppColors.healthFor(score);

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Barre de santé supérieure
          Container(
            height: 6,
            width: double.infinity,
            decoration: BoxDecoration(
              color: healthColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: colorScheme.outlineVariant.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            parcel.name,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w900,
                              color: colorScheme.onSurface,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${parcel.owner} · ${parcel.village}',
                            style: TextStyle(
                              color: colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    HealthBadge(score: score),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    _Stat(
                      icon: Icons.straighten_rounded,
                      label: 'Surface',
                      value: Fmt.hectares(area),
                      color: colorScheme.primary,
                    ),
                    _Stat(
                      icon: Icons.grass_rounded,
                      label: 'Culture',
                      value: parcel.crop,
                      color: Colors.orange,
                    ),
                    _Stat(
                      icon: Icons.water_drop_rounded,
                      label: 'Irrigation',
                      value: parcel.irrigation,
                      color: Colors.blue,
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                Row(
                  children: [
                    Expanded(
                      child: PrimaryButton(
                        icon: Icons.analytics_rounded,
                        label: 'Détails',
                        onPressed: () {
                          Navigator.pop(context);
                          context.push('${Routes.parcelDetails}/${parcel.id}');
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          context.push('${Routes.observation}/${parcel.id}');
                        },
                        icon: const Icon(Icons.add_a_photo_rounded, size: 20),
                        label: const Text('Visiter'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.5)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 14,
                color: colorScheme.onSurface,
              ),
            ),
            Text(
              label.toUpperCase(),
              style: TextStyle(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                fontSize: 9,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
