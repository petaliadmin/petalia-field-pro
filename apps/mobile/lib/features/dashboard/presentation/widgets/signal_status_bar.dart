import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/connectivity_service.dart';
import '../../../../core/services/location_service.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../theme/app_colors.dart';

class SignalStatusBar extends ConsumerWidget {
  const SignalStatusBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final netAsync = ref.watch(networkStatusProvider);
    final net = netAsync.value ?? NetworkStatus.online;
    final gps = ref.watch(locationServiceProvider).watchWithAccuracy();

    return StreamBuilder<GpsFix>(
      stream: gps,
      builder: (context, snapshot) {
        final accuracy = snapshot.data?.accuracyM;
        final gpsOk = accuracy != null && accuracy <= 10;
        
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.surfaceAltOf(context),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                net == NetworkStatus.online ? Icons.wifi_rounded : Icons.wifi_off_rounded,
                size: 14,
                color: net == NetworkStatus.online ? AppColors.success : AppColors.danger,
              ),
              const SizedBox(width: 6),
              Text(
                net == NetworkStatus.online ? l10n.statusConnected : l10n.statusOffline,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: net == NetworkStatus.online ? AppColors.success : AppColors.danger,
                ),
              ),
              const Spacer(),
              Icon(
                gpsOk ? Icons.gps_fixed_rounded : Icons.gps_not_fixed_rounded,
                size: 14,
                color: gpsOk ? AppColors.primary : AppColors.warning,
              ),
              const SizedBox(width: 6),
              Text(
                accuracy != null
                    ? l10n.statusGpsAccuracy(accuracy.round())
                    : l10n.statusGpsWaiting,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: gpsOk ? AppColors.primary : AppColors.warning,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
