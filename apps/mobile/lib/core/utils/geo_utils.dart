import 'dart:math' as math;

import 'package:latlong2/latlong.dart';

class GeoUtils {
  GeoUtils._();

  /// Calculates the area of a polygon on a sphere using the IUGG mean radius.
  /// This is more accurate than using the equatorial radius for agricultural parcels.
  /// Returns area in hectares.
  static double polygonAreaHa(List<LatLng> pts) {
    if (pts.length < 3) return 0;
    
    // IUGG Mean Radius for high-precision calculations
    const double radius = 6371008.8;
    double total = 0;
    
    for (int i = 0; i < pts.length; i++) {
      final p1 = pts[i];
      final p2 = pts[(i + 1) % pts.length];
      
      total += _rad(p2.longitude - p1.longitude) *
          (2 + math.sin(_rad(p1.latitude)) + math.sin(_rad(p2.latitude)));
    }
    
    final areaM2 = (total * radius * radius / 2).abs();
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

  /// Ray-casting algorithm for point-in-polygon test.
  static bool isPointInPolygon(LatLng point, List<LatLng> polygon) {
    bool inside = false;
    final x = point.longitude;
    final y = point.latitude;
    for (int i = 0, j = polygon.length - 1; i < polygon.length; j = i++) {
      final xi = polygon[i].longitude;
      final yi = polygon[i].latitude;
      final xj = polygon[j].longitude;
      final yj = polygon[j].latitude;

      final intersect = ((yi > y) != (yj > y)) &&
          (x < (xj - xi) * (y - yi) / (yj - yi) + xi);
      if (intersect) inside = !inside;
    }
    return inside;
  }
}
