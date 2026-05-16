library;

import 'package:hive/hive.dart';

import '../../../core/constants/app_constants.dart';
import '../domain/farm.dart';

class POIRepository {
  Box get _box => Hive.box(AppConstants.boxParcels);
  static const String _poiKey = 'field_pois';
  static const String _farmsKey = 'farms';
  static const String _toursKey = 'tours';

  List<FieldPOI> getAllPOIs() {
    final data = _box.get(_poiKey, defaultValue: <Map>[]);
    return data
        .map((m) => FieldPOI.fromJson(Map<String, dynamic>.from(m)))
        .toList();
  }

  List<FieldPOI> getPOIsInBounds(
    double minLat,
    double maxLat,
    double minLng,
    double maxLng,
  ) {
    return getAllPOIs()
        .where(
          (p) =>
              p.lat >= minLat &&
              p.lat <= maxLat &&
              p.lng >= minLng &&
              p.lng <= maxLng,
        )
        .toList();
  }

  Future<void> savePOI(FieldPOI poi) async {
    final pois = getAllPOIs();
    final index = pois.indexWhere((p) => p.id == poi.id);
    if (index >= 0) {
      pois[index] = poi;
    } else {
      pois.add(poi);
    }
    await _box.put(_poiKey, pois.map((p) => p.toJson()).toList());
  }

  Future<void> deletePOI(String id) async {
    final pois = getAllPOIs();
    pois.removeWhere((p) => p.id == id);
    await _box.put(_poiKey, pois.map((p) => p.toJson()).toList());
  }

  List<Farm> getAllFarms() {
    final data = _box.get(_farmsKey, defaultValue: <Map>[]);
    return data
        .map((m) => Farm.fromJson(Map<String, dynamic>.from(m)))
        .toList();
  }

  Future<void> saveFarm(Farm farm) async {
    final farms = getAllFarms();
    final index = farms.indexWhere((f) => f.id == farm.id);
    if (index >= 0) {
      farms[index] = farm;
    } else {
      farms.add(farm);
    }
    await _box.put(_farmsKey, farms.map((f) => f.toJson()).toList());
  }

  Farm? getFarmForOwner(String owner) {
    final farms = getAllFarms();
    try {
      return farms.firstWhere((f) => f.owner == owner);
    } catch (_) {
      return null;
    }
  }

  List<Tour> getAllTours() {
    final data = _box.get(_toursKey, defaultValue: <Map>[]);
    return data
        .map((m) => Tour.fromJson(Map<String, dynamic>.from(m)))
        .toList();
  }

  Tour? getTourForDate(DateTime date) {
    final tours = getAllTours();
    try {
      return tours.firstWhere(
        (t) =>
            t.date.year == date.year &&
            t.date.month == date.month &&
            t.date.day == date.day,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> saveTour(Tour tour) async {
    final tours = getAllTours();
    final index = tours.indexWhere((t) => t.id == tour.id);
    if (index >= 0) {
      tours[index] = tour;
    } else {
      tours.add(tour);
    }
    await _box.put(_toursKey, tours.map((t) => t.toJson()).toList());
  }

  Future<void> deleteTour(String id) async {
    final tours = getAllTours();
    tours.removeWhere((t) => t.id == id);
    await _box.put(_toursKey, tours.map((t) => t.toJson()).toList());
  }
}
