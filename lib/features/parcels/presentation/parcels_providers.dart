import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/sync_service.dart';
import '../data/parcel_repository.dart';
import '../domain/parcel.dart';

final parcelRepositoryProvider = Provider<ParcelRepository>((_) => ParcelRepository());

class ParcelsController extends StateNotifier<List<Parcel>> {
  ParcelsController(this._ref) : super([]) {
    refresh();
  }
  final Ref _ref;

  void refresh() {
    state = _ref.read(parcelRepositoryProvider).all();
  }

  Future<void> upsert(Parcel p) async {
    await _ref.read(parcelRepositoryProvider).upsert(p);
    _ref.read(syncServiceProvider.notifier).enqueue({
      'op': 'upsert_parcel',
      'id': p.id,
      'at': DateTime.now().toIso8601String(),
    });
    refresh();
  }

  Future<void> delete(String id) async {
    await _ref.read(parcelRepositoryProvider).delete(id);
    _ref.read(syncServiceProvider.notifier).enqueue({
      'op': 'delete_parcel',
      'id': id,
      'at': DateTime.now().toIso8601String(),
    });
    refresh();
  }
}

final parcelsProvider =
    StateNotifierProvider<ParcelsController, List<Parcel>>(ParcelsController.new);

final parcelByIdProvider = Provider.family<Parcel?, String>((ref, id) {
  final list = ref.watch(parcelsProvider);
  for (final p in list) {
    if (p.id == id) return p;
  }
  return null;
});

final parcelSearchProvider = StateProvider<String>((_) => '');

final filteredParcelsProvider = Provider<List<Parcel>>((ref) {
  final all = ref.watch(parcelsProvider);
  final q = ref.watch(parcelSearchProvider).trim().toLowerCase();
  if (q.isEmpty) return all;
  return all.where((p) {
    return p.name.toLowerCase().contains(q) ||
        p.owner.toLowerCase().contains(q) ||
        p.village.toLowerCase().contains(q) ||
        p.crop.toLowerCase().contains(q);
  }).toList();
});
