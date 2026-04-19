import 'dart:math' as math;

import 'package:latlong2/latlong.dart';

class GeoUtils {
  GeoUtils._();

  /// Shoelace formula on equirectangular projection. Good enough for small parcels.
  /// Returns area in hectares.
  static double polygonAreaHa(List<LatLng> pts) {
    if (pts.length < 3) return 0;
    const earthR = 6378137.0; // meters
    double total = 0;
    for (int i = 0; i < pts.length; i++) {
      final p1 = pts[i];
      final p2 = pts[(i + 1) % pts.length];
      total += _rad(p2.longitude - p1.longitude) *
          (2 + math.sin(_rad(p1.latitude)) + math.sin(_rad(p2.latitude)));
    }
    final areaM2 = (total * earthR * earthR / 2).abs();
    return areaM2 / 10000.0;
  }

  static double _rad(double deg) => deg * math.pi / 180.0;

  /// Haversine distance in km between two points.
  static double distanceKm(LatLng a, LatLng b) {
    const r = 6371.0;
    final dLat = _rad(b.latitude - a.latitude);
    final dLon = _rad(b.longitude - a.longitude);
    final h = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_rad(a.latitude)) *
            math.cos(_rad(b.latitude)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    return r * 2 * math.atan2(math.sqrt(h), math.sqrt(1 - h));
  }

  static LatLng centroid(List<LatLng> pts) {
    if (pts.isEmpty) return const LatLng(0, 0);
    double lat = 0, lon = 0;
    for (final p in pts) {
      lat += p.latitude;
      lon += p.longitude;
    }
    return LatLng(lat / pts.length, lon / pts.length);
  }

  /// Nearest-neighbor ordering for route planning.
  static List<int> nearestNeighborRoute(LatLng origin, List<LatLng> points) {
    final remaining = List<int>.generate(points.length, (i) => i);
    final route = <int>[];
    LatLng cursor = origin;
    while (remaining.isNotEmpty) {
      int bestIdx = remaining.first;
      double bestD = distanceKm(cursor, points[bestIdx]);
      for (final i in remaining) {
        final d = distanceKm(cursor, points[i]);
        if (d < bestD) {
          bestD = d;
          bestIdx = i;
        }
      }
      route.add(bestIdx);
      cursor = points[bestIdx];
      remaining.remove(bestIdx);
    }
    return route;
  }
}
