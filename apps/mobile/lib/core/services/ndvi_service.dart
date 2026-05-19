import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../constants/app_constants.dart';

class GeospatialAlert {
  final String id;
  final String severity;
  final String alertType;
  final String message;
  final DateTime createdAt;

  const GeospatialAlert({
    required this.id,
    required this.severity,
    required this.alertType,
    required this.message,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'severity': severity,
        'alertType': alertType,
        'message': message,
        'createdAt': createdAt.toIso8601String(),
      };

  static GeospatialAlert? fromMap(Map raw) {
    try {
      return GeospatialAlert(
        id: raw['id'] as String,
        severity: raw['severity'] as String,
        alertType: raw['alertType'] as String,
        message: raw['message'] as String,
        createdAt: DateTime.parse(raw['createdAt'] as String),
      );
    } catch (_) {
      return null;
    }
  }
}

/// NDVI (Normalized Difference Vegetation Index) snapshot for a parcel.
class NdviSnapshot {
  final double value; // 0.0 to 1.0
  final DateTime fetchedAt;
  final String parcelId;
  final String? tileUrl;
  final String? thumbnailUrl;
  final List<GeospatialAlert> alerts;

  const NdviSnapshot({
    required this.value,
    required this.fetchedAt,
    required this.parcelId,
    this.tileUrl,
    this.thumbnailUrl,
    required this.alerts,
  });

  Map<String, dynamic> toMap() => {
        'value': value,
        'fetchedAt': fetchedAt.toIso8601String(),
        'parcelId': parcelId,
        'tileUrl': tileUrl,
        'thumbnailUrl': thumbnailUrl,
        'alerts': alerts.map((a) => a.toMap()).toList(),
      };

  static NdviSnapshot? fromMap(Map raw) {
    try {
      final alertsRaw = raw['alerts'] as List?;
      final List<GeospatialAlert> alertsList = [];
      if (alertsRaw != null) {
        for (final item in alertsRaw) {
          if (item is Map) {
            final alert = GeospatialAlert.fromMap(item);
            if (alert != null) alertsList.add(alert);
          }
        }
      }

      return NdviSnapshot(
        value: (raw['value'] as num).toDouble(),
        fetchedAt: DateTime.parse(raw['fetchedAt'] as String),
        parcelId: raw['parcelId'] as String,
        tileUrl: raw['tileUrl'] as String?,
        thumbnailUrl: raw['thumbnailUrl'] as String?,
        alerts: alertsList,
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

      final path = force 
          ? '$baseUrl/parcels/$parcelId/analyze' 
          : '$baseUrl/parcels/$parcelId/latest';

      final resp = await _dio.get(path);
      final data = resp.data;
      if (data == null) throw StateError('Empty NDVI response');

      final veg = data['vegetation'] as Map?;
      final double ndviValue = veg != null 
          ? (veg['meanNdvi'] as num).toDouble() 
          : 0.0;

      final vis = data['visualization'] as Map?;
      final String? tileUrl = vis?['tileUrl'] as String?;
      final String? thumbnailUrl = vis?['thumbnailUrl'] as String?;

      final List<GeospatialAlert> alertsList = [];
      if (data['alerts'] is List) {
        for (final item in data['alerts'] as List) {
          if (item is Map) {
            final alert = GeospatialAlert.fromMap(item);
            if (alert != null) alertsList.add(alert);
          }
        }
      }

      final snapshot = NdviSnapshot(
        value: ndviValue,
        fetchedAt: DateTime.now(),
        parcelId: parcelId,
        tileUrl: tileUrl,
        thumbnailUrl: thumbnailUrl,
        alerts: alertsList,
      );

      await _box.put(parcelId, snapshot.toMap());
      return snapshot;
    } catch (e) {
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
