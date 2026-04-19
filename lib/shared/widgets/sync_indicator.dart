import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/connectivity_service.dart';
import '../../core/services/sync_service.dart';
import '../../theme/app_colors.dart';

class SyncIndicator extends ConsumerWidget {
  const SyncIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sync = ref.watch(syncServiceProvider);
    final net = ref.watch(networkStatusProvider).value ?? NetworkStatus.online;

    Color color;
    IconData icon;
    String label;

    if (net == NetworkStatus.offline) {
      color = AppColors.danger;
      icon = Icons.cloud_off_rounded;
      label = 'Hors ligne';
    } else if (sync.state == SyncState.syncing) {
      color = AppColors.info;
      icon = Icons.sync_rounded;
      label = 'Synchro…';
    } else if (sync.pending > 0) {
      color = AppColors.warning;
      icon = Icons.cloud_queue_rounded;
      label = '${sync.pending} en attente';
    } else {
      color = AppColors.success;
      icon = Icons.cloud_done_rounded;
      label = 'Synchronisé';
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
