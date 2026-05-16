import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:latlong2/latlong.dart';

import '../constants/app_constants.dart';
import 'location_service.dart';

/// Instantaneous weather snapshot used by the dashboard.
///
/// Data source: Open-Meteo (https://open-meteo.com) — free, no API key.
/// Cached 6 h in Hive `box_weather`. When offline or on API failure, the
/// most recent cached value is returned (with its original [fetchedAt] so
/// the UI can decide to show an "il y a X h" badge if desired).
class WeatherSnapshot {
  final double tempC;
  final int humidity; // %
  final double windKmh;
  final String condition; // FR label
  final String icon; // semantic key: sun, cloud, rain, storm, fog, snow
  final DateTime fetchedAt;
  final double latitude;
  final double longitude;

  final double maxRainNext6h;

  const WeatherSnapshot({
    required this.tempC,
    required this.humidity,
    required this.windKmh,
    required this.condition,
    required this.icon,
    required this.fetchedAt,
    required this.latitude,
    required this.longitude,
    this.maxRainNext6h = 0,
  });

  Map<String, dynamic> toMap() => {
        'temp': tempC,
        'humidity': humidity,
        'wind': windKmh,
        'condition': condition,
        'icon': icon,
        'fetchedAt': fetchedAt.toIso8601String(),
        'lat': latitude,
        'lng': longitude,
        'maxRain': maxRainNext6h,
      };

  static WeatherSnapshot? fromMap(Map raw) {
    try {
      return WeatherSnapshot(
        tempC: (raw['temp'] as num).toDouble(),
        humidity: (raw['humidity'] as num).round(),
        windKmh: (raw['wind'] as num).toDouble(),
        condition: raw['condition']?.toString() ?? '',
        icon: raw['icon']?.toString() ?? 'cloud',
        fetchedAt: DateTime.tryParse(raw['fetchedAt']?.toString() ?? '') ??
            DateTime.now(),
        latitude: (raw['lat'] as num?)?.toDouble() ?? 0,
        longitude: (raw['lng'] as num?)?.toDouble() ?? 0,
        maxRainNext6h: (raw['maxRain'] as num?)?.toDouble() ?? 0,
      );
    } catch (_) {
      return null;
    }
  }
}

class WeatherService {
  WeatherService({Dio? dio, LocationService? location})
      : _dio = dio ?? Dio(BaseOptions(connectTimeout: const Duration(seconds: 6), receiveTimeout: const Duration(seconds: 8))),
        _location = location ?? LocationService();

  final Dio _dio;
  final LocationService _location;

  static const _cacheKey = 'current';
  static const _cacheTtl = Duration(hours: 6);
  static const _endpoint = 'https://api.open-meteo.com/v1/forecast';

  Box get _box => Hive.box(AppConstants.boxWeather);

  /// Returns the cached snapshot if it exists (regardless of age).
  WeatherSnapshot? cached() {
    final raw = _box.get(_cacheKey);
    if (raw is Map) return WeatherSnapshot.fromMap(raw);
    return null;
  }

  /// Fetch fresh weather and forecast. Uses cache if fresh (< 6 h),
  /// otherwise hits the Open-Meteo API.
  Future<WeatherSnapshot> fetch({bool force = false}) async {
    final prior = cached();
    if (!force &&
        prior != null &&
        DateTime.now().difference(prior.fetchedAt) < _cacheTtl) {
      return prior;
    }

    LatLng pos = const LatLng(14.7889, -16.9260); // Default to Thiès region
    try {
      final here = await _location.current();
      if (here != null) pos = here;
    } catch (_) {}

    try {
      final resp = await _dio.get<Map<String, dynamic>>(
        _endpoint,
        queryParameters: {
          'latitude': pos.latitude.toStringAsFixed(4),
          'longitude': pos.longitude.toStringAsFixed(4),
          'current':
              'temperature_2m,relative_humidity_2m,wind_speed_10m,weather_code',
          'hourly': 'precipitation_probability,precipitation',
          'forecast_hours': 24,
          'timezone': 'auto',
        },
      );
      final current = resp.data?['current'];
      if (current is! Map) throw StateError('missing current block');

      // Analyse du risque de pluie (anti-lessivage) — §2.2
      // On regarde les 6 prochaines heures.
      final hourly = resp.data?['hourly'];
      double maxRainNext6h = 0;
      if (hourly is Map && hourly['precipitation'] is List) {
        final rains = (hourly['precipitation'] as List)
            .whereType<num>()
            .map((r) => r.toDouble())
            .take(6)
            .toList();
        if (rains.length >= 6) {
          maxRainNext6h = rains.reduce((a, b) => a > b ? a : b);
        }
      }

      final snapshot = WeatherSnapshot(
        tempC: (current['temperature_2m'] as num).toDouble(),
        humidity: (current['relative_humidity_2m'] as num).round(),
        windKmh: (current['wind_speed_10m'] as num).toDouble(),
        condition:
            _conditionLabel((current['weather_code'] as num?)?.toInt() ?? 0),
        icon: _iconKey((current['weather_code'] as num?)?.toInt() ?? 0),
        fetchedAt: DateTime.now(),
        latitude: pos.latitude,
        longitude: pos.longitude,
        maxRainNext6h: maxRainNext6h,
      );
      await _box.put(_cacheKey, snapshot.toMap());
      return snapshot;
    } catch (e, st) {
      // Surface failures in logs so we can diagnose stale data in the field.
      // Keep the user on the last cached snapshot when available.
      // ignore: avoid_print
      print('WeatherService.fetch failed: $e\n$st');
      if (prior != null) return prior;
      rethrow;
    }
  }

  /// Open-Meteo WMO weather codes → short FR labels.
  static String _conditionLabel(int code) {
    if (code == 0) return 'Ciel dégagé';
    if (code == 1) return 'Principalement clair';
    if (code == 2) return 'Partiellement nuageux';
    if (code == 3) return 'Couvert';
    if (code == 45 || code == 48) return 'Brouillard';
    if (code >= 51 && code <= 57) return 'Bruine';
    if (code >= 61 && code <= 67) return 'Pluie';
    if (code >= 71 && code <= 77) return 'Neige';
    if (code >= 80 && code <= 82) return 'Averses';
    if (code == 85 || code == 86) return 'Averses de neige';
    if (code >= 95 && code <= 99) return 'Orage';
    return 'Conditions variables';
  }

  static String _iconKey(int code) {
    if (code <= 1) return 'sun';
    if (code <= 3) return 'cloud';
    if (code == 45 || code == 48) return 'fog';
    if (code >= 51 && code <= 67) return 'rain';
    if (code >= 71 && code <= 77 || code == 85 || code == 86) return 'snow';
    if (code >= 80 && code <= 82) return 'rain';
    if (code >= 95) return 'storm';
    return 'cloud';
  }
}

final weatherServiceProvider = Provider<WeatherService>((_) => WeatherService());

/// Auto-refreshing weather snapshot. First emits the cached value (if any)
/// then triggers a network refresh.
final weatherProvider = FutureProvider<WeatherSnapshot>((ref) async {
  final service = ref.watch(weatherServiceProvider);
  return service.fetch();
});
