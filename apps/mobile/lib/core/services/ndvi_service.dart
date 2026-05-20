import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../constants/app_constants.dart';

// ---------------------------------------------------------------------------
// Domain models
// ---------------------------------------------------------------------------

class GeospatialAlert {
  final String id;
  final String severity; // LOW | MEDIUM | HIGH | CRITICAL
  final String alertType; // NDVI_LOW | NDVI_DROP | WATER_STRESS | NITROGEN_STRESS | HIGH_CLOUD_COVER | HIGH_VARIABILITY
  final String message;
  final DateTime createdAt;

  const GeospatialAlert({
    required this.id,
    required this.severity,
    required this.alertType,
    required this.message,
    required this.createdAt,
  });

  bool get isCritical => severity == 'CRITICAL';
  bool get isHigh => severity == 'HIGH';

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
        id: raw['id'] as String? ?? '',
        severity: raw['severity'] as String? ?? 'LOW',
        alertType: raw['type'] as String? ?? raw['alertType'] as String? ?? '',
        message: raw['message'] as String? ?? '',
        createdAt: DateTime.tryParse(raw['createdAt'] as String? ?? '') ?? DateTime.now(),
      );
    } catch (_) {
      return null;
    }
  }
}

/// Full satellite snapshot for a parcel — all indices from Sentinel-2.
class NdviSnapshot {
  /// NDVI mean (primary vegetation vigour indicator, 0–1)
  final double value;
  final DateTime fetchedAt;
  final String parcelId;

  // Imagery access via backend proxy
  final String? tileUrl;
  final String? thumbnailUrl;

  // Water / moisture stress (NDMI = (B8-B11)/(B8+B11))
  final double? ndmi;

  // Nitrogen / chlorophyll stress — detects 2–3 weeks earlier than NDVI
  // (NDRE = (B8A-B5)/(B8A+B5))
  final double? ndre;

  // Soil-adjusted index — useful for young crops / bare soil
  // (SAVI = 1.5*(B8-B4)/(B8+B4+0.5))
  final double? savi;

  // Enhanced vegetation — no saturation in dense canopy
  // (EVI2 = 2.5*(B8-B4)/(B8+2.4*B4+1))
  final double? evi2;

  /// UP | DOWN | STABLE | UNKNOWN (delta vs previous analysis)
  final String trend;

  /// EXCELLENT | GOOD | MODERATE | POOR (based on NDVI thresholds)
  final String health;

  final double cloudCoverage;
  final List<GeospatialAlert> alerts;

  const NdviSnapshot({
    required this.value,
    required this.fetchedAt,
    required this.parcelId,
    this.tileUrl,
    this.thumbnailUrl,
    this.ndmi,
    this.ndre,
    this.savi,
    this.evi2,
    this.trend = 'UNKNOWN',
    this.health = 'POOR',
    this.cloudCoverage = 0.0,
    required this.alerts,
  });

  bool get hasWaterStress => ndmi != null && ndmi! < -0.10;
  bool get hasNitrogenStress => ndre != null && ndre! < 0.20;
  bool get isCloudObstructed => cloudCoverage > 0.30;

  Map<String, dynamic> toMap() => {
        'value': value,
        'fetchedAt': fetchedAt.toIso8601String(),
        'parcelId': parcelId,
        'tileUrl': tileUrl,
        'thumbnailUrl': thumbnailUrl,
        'ndmi': ndmi,
        'ndre': ndre,
        'savi': savi,
        'evi2': evi2,
        'trend': trend,
        'health': health,
        'cloudCoverage': cloudCoverage,
        'alerts': alerts.map((a) => a.toMap()).toList(),
      };

  static NdviSnapshot? fromMap(Map raw) {
    try {
      final alertsRaw = raw['alerts'] as List?;
      final alerts = <GeospatialAlert>[];
      if (alertsRaw != null) {
        for (final item in alertsRaw) {
          if (item is Map) {
            final a = GeospatialAlert.fromMap(item);
            if (a != null) alerts.add(a);
          }
        }
      }
      return NdviSnapshot(
        value: (raw['value'] as num).toDouble(),
        fetchedAt: DateTime.parse(raw['fetchedAt'] as String),
        parcelId: raw['parcelId'] as String,
        tileUrl: raw['tileUrl'] as String?,
        thumbnailUrl: raw['thumbnailUrl'] as String?,
        ndmi: (raw['ndmi'] as num?)?.toDouble(),
        ndre: (raw['ndre'] as num?)?.toDouble(),
        savi: (raw['savi'] as num?)?.toDouble(),
        evi2: (raw['evi2'] as num?)?.toDouble(),
        trend: raw['trend'] as String? ?? 'UNKNOWN',
        health: raw['health'] as String? ?? 'POOR',
        cloudCoverage: (raw['cloudCoverage'] as num?)?.toDouble() ?? 0.0,
        alerts: alerts,
      );
    } catch (_) {
      return null;
    }
  }
}

// ---------------------------------------------------------------------------
// Service
// ---------------------------------------------------------------------------

class NdviService {
  NdviService({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              connectTimeout: const Duration(seconds: 12),
              receiveTimeout: const Duration(seconds: 15),
            )) {
    // Purge legacy cached data that lacks the new fields (ndre, savi, etc.)
    _box.clear();
  }

  final Dio _dio;

  Box get _box => Hive.box(AppConstants.boxNdvi);

  NdviSnapshot? getCached(String parcelId) {
    final raw = _box.get(parcelId);
    if (raw is Map) return NdviSnapshot.fromMap(raw);
    return null;
  }

  Future<void> clearAll() async => _box.clear();

  /// Fetches the latest satellite analysis from the backend proxy.
  /// Results are cached locally for 24 hours (Hive).
  /// Pass [force] = true to bypass cache and request a fresh GEE analysis.
  Future<NdviSnapshot> fetch(String parcelId, {bool force = false}) async {
    final prior = getCached(parcelId);

    if (!force &&
        prior != null &&
        DateTime.now().difference(prior.fetchedAt) < const Duration(hours: 24)) {
      return prior;
    }

    try {
      final connectivity = await Connectivity().checkConnectivity();
      if (connectivity.contains(ConnectivityResult.none)) {
        throw StateError('Connexion requise pour le service satellite');
      }

      final baseUrl = AppConstants.remoteBaseUrl.isNotEmpty
          ? AppConstants.remoteBaseUrl
          : 'https://hub.petalia.pro/api';

      // On force: trigger a fresh analysis (POST), then read /latest which
      // the engine populates after completion. The backend handles polling.
      if (force) {
        await _dio.post('$baseUrl/parcels/$parcelId/analyze');
      }

      final resp = await _dio.get('$baseUrl/parcels/$parcelId/latest');
      final data = resp.data as Map?;
      if (data == null) throw StateError('Empty NDVI response');

      final snapshot = _parseSnapshot(parcelId, baseUrl, data);
      await _box.put(parcelId, snapshot.toMap());
      return snapshot;
    } catch (e) {
      if (prior != null) return prior;
      rethrow;
    }
  }

  NdviSnapshot _parseSnapshot(String parcelId, String baseUrl, Map data) {
    final veg = data['vegetation'] as Map?;
    final water = data['water'] as Map?;

    final ndviValue = (veg?['meanNdvi'] as num?)?.toDouble() ?? 0.0;
    final ndmi = (water?['meanNdmi'] as num?)?.toDouble();
    final ndre = (veg?['ndreeMean'] as num?)?.toDouble();
    final savi = (veg?['saviMean'] as num?)?.toDouble();
    final evi2 = (veg?['evi2Mean'] as num?)?.toDouble();
    final trend = veg?['trend'] as String? ?? 'UNKNOWN';
    final health = veg?['health'] as String? ?? 'POOR';
    final cloudCoverage = (data['cloudCoverage'] as num?)?.toDouble() ?? 0.0;

    final alerts = <GeospatialAlert>[];
    if (data['alerts'] is List) {
      for (final item in data['alerts'] as List) {
        if (item is Map) {
          final a = GeospatialAlert.fromMap(item);
          if (a != null) alerts.add(a);
        }
      }
    }

    // Always use backend proxy URLs — raw GEE URLs require server-side auth.
    return NdviSnapshot(
      value: ndviValue,
      fetchedAt: DateTime.now(),
      parcelId: parcelId,
      tileUrl: '$baseUrl/parcels/$parcelId/tile?z={z}&x={x}&y={y}',
      thumbnailUrl: '$baseUrl/parcels/$parcelId/thumbnail',
      ndmi: ndmi,
      ndre: ndre,
      savi: savi,
      evi2: evi2,
      trend: trend,
      health: health,
      cloudCoverage: cloudCoverage,
      alerts: alerts,
    );
  }
}

// ---------------------------------------------------------------------------
// Riverpod providers
// ---------------------------------------------------------------------------

final ndviServiceProvider = Provider<NdviService>((ref) => NdviService());

final ndviProvider = FutureProvider.family<NdviSnapshot, String>((ref, parcelId) async {
  final service = ref.watch(ndviServiceProvider);
  return service.fetch(parcelId);
});
