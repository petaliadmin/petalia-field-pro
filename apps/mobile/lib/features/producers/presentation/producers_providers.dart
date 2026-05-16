import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../parcels/presentation/parcels_providers.dart';
import '../domain/producer.dart';

final producersProvider = Provider<List<Producer>>((ref) {
  final parcels = ref.watch(parcelsProvider);
  
  // Group by owner name
  final groups = <String, List<dynamic>>{};
  for (final p in parcels) {
    groups.putIfAbsent(p.owner, () => []).add(p);
  }

  return groups.entries.map((e) {
    final ownerName = e.key;
    final ownerParcels = e.value;
    
    // Find first available phone and village
    String? phone;
    String village = '';
    for (final p in ownerParcels) {
      if (p.phone != null && p.phone!.isNotEmpty) phone = p.phone;
      if (p.village.isNotEmpty) village = p.village;
    }

    return Producer(
      id: ownerName, // Simplification
      name: ownerName,
      phone: phone,
      village: village,
      parcels: List.from(ownerParcels),
    );
  }).toList()..sort((a, b) => a.name.compareTo(b.name));
});

final producerSearchProvider = StateProvider<String>((ref) => '');

final filteredProducersProvider = Provider<List<Producer>>((ref) {
  final all = ref.watch(producersProvider);
  final query = ref.watch(producerSearchProvider).toLowerCase();
  
  if (query.isEmpty) return all;
  
  return all.where((p) {
    return p.name.toLowerCase().contains(query) || 
           p.village.toLowerCase().contains(query) ||
           (p.phone?.contains(query) ?? false);
  }).toList();
});
