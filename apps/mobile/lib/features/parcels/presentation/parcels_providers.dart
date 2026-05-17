import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/network/dio_provider.dart';
import '../../../core/services/location_service.dart';
import '../../../core/services/sync_service.dart';
import '../../auth/presentation/auth_providers.dart';
import '../data/parcel_repository.dart';
import '../domain/parcel.dart';

final parcelRepositoryProvider = Provider<ParcelRepository>((_) => ParcelRepository());

class ParcelsController extends StateNotifier<List<Parcel>> {
  ParcelsController(this._ref) : super([]) {
    refresh();
    fetchRemoteParcels();
  }
  final Ref _ref;

  void refresh() {
    state = _ref.read(parcelRepositoryProvider).all();
  }

  Future<void> fetchRemoteParcels({bool forceFull = false}) async {
    if (!AppConstants.remoteApiEnabled) return;
    try {
      final dio = _ref.read(dioProvider);
      final settings = Hive.box(AppConstants.boxSettings);
      final lastSync = forceFull ? '1970-01-01' : (settings.get(AppConstants.kLastParcelSyncTime) as String? ?? '1970-01-01');

      final res = await dio.get('/parcels/sync', queryParameters: {'last_sync': lastSync});
      final data = res.data;
      if (data != null && data['parcels'] is List) {
        final list = data['parcels'] as List;
        final repo = _ref.read(parcelRepositoryProvider);
        for (final item in list) {
          try {
            final p = Parcel.fromJson(item as Map);
            await repo.upsert(p);
          } catch (e) {
            debugPrint('Erreur parsing parcelle distante: $e');
          }
        }
        await settings.put(AppConstants.kLastParcelSyncTime, DateTime.now().toIso8601String());
        refresh();
      }
    } catch (e) {
      debugPrint('Erreur fetchRemoteParcels: $e');
    }
  }

  Future<void> upsert(Parcel p) async {
    await _ref.read(parcelRepositoryProvider).upsert(p);
    refresh();
    // Enqueue *after* local refresh so the UI reflects the new state even if
    // the network flush fails; the queue will retry on reconnect.
    await _ref.read(syncServiceProvider.notifier).enqueue({
      'op': 'upsert_parcel',
      'id': p.id,
      'parcel': p.toJson(),
      'at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> delete(String id) async {
    await _ref.read(parcelRepositoryProvider).delete(id);
    refresh();
    await _ref.read(syncServiceProvider.notifier).enqueue({
      'op': 'delete_parcel',
      'id': id,
      'at': DateTime.now().toIso8601String(),
    });
  }

}

final parcelsProvider =
    StateNotifierProvider<ParcelsController, List<Parcel>>(ParcelsController.new);

/// Internal id-indexed map, rebuilt only when the parcel list itself changes.
/// Lets `parcelByIdProvider` resolve in O(1) instead of scanning the list.
final _parcelsByIdProvider = Provider<Map<String, Parcel>>((ref) {
  final list = ref.watch(parcelsProvider);
  return {for (final p in list) p.id: p};
});

final parcelByIdProvider = Provider.family<Parcel?, String>((ref, id) {
  return ref.watch(_parcelsByIdProvider)[id];
});

final parcelSearchProvider = StateProvider<String>((_) => '');

/// Selected crop chip filter on the parcels list. `null` = all crops.
final parcelCropFilterProvider = StateProvider<String?>((_) => null);

/// View mode for the parcels screen (false = list, true = map).
final parcelsViewModeProvider = StateProvider<bool>((_) => false);

/// Distinct crop labels among existing parcels, sorted alphabetically.
/// Used to render the chip bar — hidden when there are fewer than 2 crops.
final parcelCropsAvailableProvider = Provider<List<String>>((ref) {
  final all = ref.watch(parcelsProvider);
  final set = <String>{for (final p in all) p.crop};
  final list = set.toList()..sort();
  return list;
});

/// Mode de tri des parcelles (Nom ou Proximité)
enum ParcelSortMode { name, distance }

final parcelSortModeProvider = StateProvider<ParcelSortMode>((_) => ParcelSortMode.name);

/// Provider exposant le flux de position actuelle
final userLocationProvider = StreamProvider<LatLng>((ref) {
  return ref.watch(locationServiceProvider).watch();
});

final filteredParcelsProvider = Provider<List<Parcel>>((ref) {
  final all = ref.watch(parcelsProvider);
  final q = ref.watch(parcelSearchProvider).trim().toLowerCase();
  final crop = ref.watch(parcelCropFilterProvider);
  final sortMode = ref.watch(parcelSortModeProvider);
  final userLoc = ref.watch(userLocationProvider).valueOrNull;
  final currentUser = ref.watch(authStateProvider).value?.user;
  final techName = currentUser?.name;

  var filtered = all.where((p) {
    if (techName != null && p.technician != null && p.technician != 'Non affecté' && p.technician != techName) {
      return false;
    }
    if (crop != null && p.crop != crop) return false;
    if (q.isEmpty) return true;
    return p.name.toLowerCase().contains(q) ||
        p.owner.toLowerCase().contains(q) ||
        p.village.toLowerCase().contains(q) ||
        p.crop.toLowerCase().contains(q);
  }).toList();

  if (sortMode == ParcelSortMode.distance && userLoc != null) {
    final distance = const Distance();
    filtered.sort((a, b) {
      if (a.boundary.isEmpty) return 1;
      if (b.boundary.isEmpty) return -1;
      
      final d1 = distance.as(LengthUnit.Meter, userLoc, a.boundary.first);
      final d2 = distance.as(LengthUnit.Meter, userLoc, b.boundary.first);
      return d1.compareTo(d2);
    });
  } else {
    // Par défaut, tri par nom
    filtered.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  }

  return filtered;
});
