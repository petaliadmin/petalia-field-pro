import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../theme/app_colors.dart';
import '../../parcels/presentation/parcels_providers.dart';
import '../domain/expert_request.dart';

final expertRequestsListProvider = StreamProvider<List<ExpertRequest>>((ref) async* {
  final box = Hive.box(AppConstants.boxExpertRequests);
  
  List<ExpertRequest> getList() {
    return box.values
        .map((e) => ExpertRequest.fromJson(Map<String, dynamic>.from(e)))
        .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  yield getList();

  while (true) {
    await Future.delayed(const Duration(seconds: 10));
    yield getList();
  }
});

class ExpertRequestsScreen extends ConsumerWidget {
  const ExpertRequestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestsAsync = ref.watch(expertRequestsListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Demandes d\'Avis Expert')),
      body: requestsAsync.when(
        data: (requests) => requests.isEmpty
            ? EmptyState(
                icon: Icons.support_agent_rounded,
                title: 'Aucune demande d\'avis expert',
                message: 'Les consultations d\'agronomes seniors payées avec vos crédits s\'afficheront ici.',
                action: FilledButton.icon(
                  onPressed: () => context.pop(),
                  icon: const Icon(Icons.arrow_back_rounded),
                  label: const Text('Retour'),
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.all(20),
                itemCount: requests.length,
                separatorBuilder: (_, __) => const SizedBox(height: 16),
                itemBuilder: (context, i) {
                  final r = requests[i];
                  return _ExpertRequestCard(request: r);
                },
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur: $e')),
      ),
    );
  }
}

class _ExpertRequestCard extends ConsumerWidget {
  const _ExpertRequestCard({required this.request});
  final ExpertRequest request;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final parcel = ref.watch(parcelByIdProvider(request.parcelId));
    final parcelName = parcel?.name ?? 'Parcelle ${request.parcelId.substring(0, 6)}...';

    Color statusColor = Colors.grey;
    String statusLabel = 'Brouillon';
    switch (request.status) {
      case ExpertRequestStatus.draft:
        statusColor = Colors.grey;
        statusLabel = 'Brouillon';
        break;
      case ExpertRequestStatus.queued:
        statusColor = AppColors.warning;
        statusLabel = 'En attente de synchronisation';
        break;
      case ExpertRequestStatus.sent:
        statusColor = AppColors.info;
        statusLabel = 'Envoyé à l\'expert';
        break;
      case ExpertRequestStatus.received:
        statusColor = AppColors.info;
        statusLabel = 'En cours d\'analyse';
        break;
      case ExpertRequestStatus.answered:
        statusColor = AppColors.success;
        statusLabel = 'Répondu par l\'expert';
        break;
      case ExpertRequestStatus.closed:
        statusColor = AppColors.success;
        statusLabel = 'Dossier clos';
        break;
    }

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 42,
                width: 42,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.support_agent_rounded, color: statusColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(parcelName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text(
                      'Demandé le ${request.createdAt.day}/${request.createdAt.month}/${request.createdAt.year}',
                      style: TextStyle(fontSize: 12, color: AppColors.textMutedOf(context)),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  statusLabel.toUpperCase(),
                  style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Contexte & Symptômes :',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textSecondaryOf(context)),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.all(10),
            width: double.infinity,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              request.context,
              style: const TextStyle(fontSize: 13, fontFamily: 'monospace'),
            ),
          ),
          if (request.answer != null && request.answer!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.verified_rounded, size: 18, color: AppColors.success),
                      SizedBox(width: 8),
                      Text(
                        'Réponse de l\'Agronome Senior',
                        style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.success, fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    request.answer!,
                    style: const TextStyle(fontSize: 13, height: 1.4),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
