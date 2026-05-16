import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../constants/app_constants.dart';

/// NDVI (Normalized Difference Vegetation Index) snapshot for a parcel.
///
/// In production, this data would come from satellite providers like Sentinel-2
/// or Planet, integrated via the Petalia Hub API.
class NdviSnapshot {
  final double value; // 0.0 to 1.0
  final DateTime fetchedAt;
  final String parcelId;

  const NdviSnapshot({
    required this.value,
    required this.fetchedAt,
    required this.parcelId,
  });

  Map<String, dynamic> toMap() => {
        'value': value,
        'fetchedAt': fetchedAt.toIso8601String(),
        'parcelId': parcelId,
      };

  static NdviSnapshot? fromMap(Map raw) {
    try {
      return NdviSnapshot(
        value: (raw['value'] as num).toDouble(),
        fetchedAt: DateTime.parse(raw['fetchedAt'] as String),
        parcelId: raw['parcelId'] as String,
      );
    } catch (_) {
      return null;
    }
  }
}

class NdviService {
  NdviService({Dio? dio})
      : _dio = dio ?? Dio(BaseOptions(
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 15),
        )) {
    // Purge legacy simulated data on startup to ensure clean slate
    _box.clear();
  }

  final Dio _dio;

  Box get _box => Hive.box(AppConstants.boxNdvi);

  /// Returns the cached NDVI for a specific parcel.
  NdviSnapshot? getCached(String parcelId) {
    final raw = _box.get(parcelId);
    if (raw is Map) return NdviSnapshot.fromMap(raw);
    return null;
  }

  /// Purges all NDVI data from the local database.
  Future<void> clearAll() async {
    await _box.clear();
  }

  /// Fetches the latest NDVI data from the satellite proxy API.
  Future<NdviSnapshot> fetch(String parcelId, {bool force = false}) async {
    final prior = getCached(parcelId);
    
    // Cache TTL: 24 hours (NDVI doesn't change every minute).
    if (!force && prior != null && 
        DateTime.now().difference(prior.fetchedAt) < const Duration(hours: 24)) {
      return prior;
    }

    try {
      // Check connectivity - NDVI requires live satellite data link
      final connectivity = await Connectivity().checkConnectivity();
      if (connectivity.contains(ConnectivityResult.none)) {
        throw StateError('Connexion requise pour le service satellite');
      }

      // User requested dynamic call: we attempt the Petalia Hub API.
      // If no BaseURL is set, we use a default hub endpoint.
      final baseUrl = AppConstants.remoteBaseUrl.isNotEmpty 
          ? AppConstants.remoteBaseUrl 
          : 'https://hub.petalia.pro/api';

      final resp = await _dio.get('$baseUrl/v1/ndvi/$parcelId');

      final data = resp.data;
      if (data == null) throw StateError('Empty NDVI response');

      final snapshot = NdviSnapshot(
        value: (data['value'] as num).toDouble(),
        fetchedAt: DateTime.now(),
        parcelId: parcelId,
      );

      await _box.put(parcelId, snapshot.toMap());
      return snapshot;
    } catch (e) {
      // Fallback to cache if available, but if it was a forced refresh, 
      // we might want to know it failed.
      if (prior != null) return prior;
      rethrow;
    }
  }
}

final ndviServiceProvider = Provider<NdviService>((ref) => NdviService());

final ndviProvider = FutureProvider.family<NdviSnapshot, String>((ref, parcelId) async {
  final service = ref.watch(ndviServiceProvider);
  return service.fetch(parcelId);
});
