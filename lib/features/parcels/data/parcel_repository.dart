import 'package:hive/hive.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/services/tile_cache_service.dart';
import '../../map/presentation/map_providers.dart';
import '../domain/parcel.dart';

class ParcelRepository {
  Box get _box => Hive.box(AppConstants.boxParcels);

  List<Parcel> all() {
    return _box.values
        .map((e) => Parcel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList()
      ..sort((a, b) => b.lastVisit.compareTo(a.lastVisit));
  }

  Parcel? byId(String id) {
    final raw = _box.get(id);
    if (raw == null) return null;
    return Parcel.fromJson(Map<String, dynamic>.from(raw as Map));
  }

  Future<void> upsert(Parcel p) async {
    await _box.put(p.id, p.toJson());
    // Pre-cache map tiles around the parcel boundary (fire-and-forget).
    if (p.boundary.length >= 3) {
      TileCacheService.cacheAroundParcel(
        boundary: p.boundary,
        osmUrl: MapLayer.standard.url,
      );
    }
  }

  Future<void> delete(String id) async => _box.delete(id);
}
