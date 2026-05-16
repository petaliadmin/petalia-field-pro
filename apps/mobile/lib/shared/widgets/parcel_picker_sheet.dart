import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/parcels/domain/parcel.dart';
import '../../routes/route_names.dart';
import '../../theme/app_colors.dart';

/// Bottom sheet that lets the user pick a parcel to start a field observation.
///
/// Pops itself before navigating to `${Routes.observation}/<parcelId>` to keep
/// the back stack clean. Designed for the central FAB of [AppShell] and reused
/// by the dashboard "Capturer" CTA — single source of truth for the gesture.
Future<void> showParcelPickerSheet(
  BuildContext context,
  List<Parcel> parcels,
) {
  if (parcels.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Ajoutez d\'abord une parcelle pour démarrer une visite.',
        ),
      ),
    );
    return Future.value();
  }
  return showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (_) => _ParcelPickerSheet(parcels: parcels),
  );
}

class _ParcelPickerSheet extends StatelessWidget {
  const _ParcelPickerSheet({required this.parcels});
  final List<Parcel> parcels;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.dividerOf(context),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Choisir une parcelle',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            'Quelle parcelle souhaitez-vous visiter ?',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondaryOf(context)),
          ),
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
                      color: AppColors.healthFor(
                        p.healthScore,
                      ).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      AppColors.healthIconFor(p.healthScore),
                      color: AppColors.healthFor(p.healthScore),
                      size: 22,
                    ),
                  ),
                  title: Text(
                    p.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  subtitle: Text(
                    '${p.crop} · ${p.owner}',
                    style: TextStyle(
                      color: AppColors.textSecondaryOf(context),
                      fontSize: 13,
                    ),
                  ),
                  trailing: Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.textMutedOf(context),
                  ),
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
    );
  }
}
