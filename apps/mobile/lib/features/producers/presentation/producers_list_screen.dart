import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../routes/route_names.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../theme/app_colors.dart';
import 'producers_providers.dart';

class ProducersListScreen extends ConsumerWidget {
  const ProducersListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final producers = ref.watch(filteredProducersProvider);
    final query = ref.watch(producerSearchProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Producteurs'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: TextField(
              onChanged: (v) => ref.read(producerSearchProvider.notifier).state = v,
              decoration: InputDecoration(
                hintText: 'Rechercher un producteur...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => ref.read(producerSearchProvider.notifier).state = '',
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ),
      ),
      body: producers.isEmpty
          ? EmptyState(
              icon: Icons.people_outline_rounded,
              title: query.isEmpty ? 'Aucun producteur' : 'Aucun résultat',
              message: query.isEmpty
                  ? 'Ajoutez des parcelles pour voir apparaître les producteurs.'
                  : 'Aucun producteur ne correspond à "$query".',
              action: query.isNotEmpty
                  ? TextButton(
                      onPressed: () => ref.read(producerSearchProvider.notifier).state = '',
                      child: const Text('Réinitialiser la recherche'),
                    )
                  : null,
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
              itemCount: producers.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final p = producers[i];
                return GlassCard(
                  onTap: () => context.push('${Routes.producers}/${p.id}'),
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                        child: Text(
                          p.name.isNotEmpty ? p.name[0].toUpperCase() : '?',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              p.name,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            Text(
                              '${p.village} • ${p.totalParcels} parcelle${p.totalParcels > 1 ? 's' : ''}',
                              style: TextStyle(
                                color: AppColors.textMutedOf(context),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded, color: AppColors.primary),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
