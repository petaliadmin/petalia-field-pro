import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/formatters.dart';
import '../../../core/utils/geo_utils.dart';
import '../../../routes/route_names.dart';
import '../../../shared/widgets/health_badge.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../theme/app_colors.dart';
import '../../parcels/domain/parcel.dart';

class ParcelBottomSheet extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final area = GeoUtils.polygonAreaHa(parcel.boundary);
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(22, 14, 22, 22),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Text(parcel.name, style: Theme.of(context).textTheme.titleLarge),
              ),
              HealthBadge(score: parcel.healthScore, compact: true),
            ],
          ),
          const SizedBox(height: 4),
          Text('${parcel.owner} · ${parcel.village}',
              style: TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 18),
          Row(
            children: [
              _Stat(icon: Icons.straighten_rounded, label: 'Surface', value: Fmt.hectares(area)),
              _Stat(icon: Icons.grass_rounded, label: 'Culture', value: parcel.crop),
              _Stat(icon: Icons.water_drop_rounded, label: 'Irrigation', value: parcel.irrigation),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => context.push('${Routes.parcelDetails}/${parcel.id}'),
                  icon: const Icon(Icons.open_in_new_rounded),
                  label: const Text('Détails'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: PrimaryButton(
                  icon: Icons.camera_alt_rounded,
                  label: 'Observer',
                  onPressed: () {
                    Navigator.of(context).pop();
                    context.push('${Routes.observation}/${parcel.id}');
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color: AppColors.secondary,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: AppColors.primary),
            const SizedBox(height: 6),
            Text(value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w700)),
            Text(label,
                style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}
