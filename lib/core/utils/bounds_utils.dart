import 'dart:math' as math;

import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class BoundsUtils {
  BoundsUtils._();

  /// Expand a [LatLngBounds] by [bufferKm] in every direction.
  static LatLngBounds expandBounds(LatLngBounds bounds, double bufferKm) {
    final dLat = bufferKm / 111.32;
    final midLat = (bounds.north + bounds.south) / 2;
    final dLng = bufferKm / (111.32 * math.cos(midLat * math.pi / 180));

    return LatLngBounds(
      LatLng(bounds.south - dLat, bounds.west - dLng),
      LatLng(bounds.north + dLat, bounds.east + dLng),
    );
  }

  /// Build a bounding box around a list of points with [bufferKm] margin.
  static LatLngBounds boundsFromPoints(List<LatLng> points,
      {double bufferKm = 0}) {
    assert(points.isNotEmpty, 'points must not be empty');
    final bounds = LatLngBounds.fromPoints(points);
    return bufferKm > 0 ? expandBounds(bounds, bufferKm) : bounds;
  }

  /// Estimate the number of tiles in a bounding box for zoom range [minZoom]..[maxZoom].
  static int estimateTileCount(LatLngBounds bounds, int minZoom, int maxZoom) {
    int total = 0;
    for (int z = minZoom; z <= maxZoom; z++) {
      final n = 1 << z; // 2^z
      final xMin = _lngToTileX(bounds.west, n);
      final xMax = _lngToTileX(bounds.east, n);
      final yMin = _latToTileY(bounds.north, n);
      final yMax = _latToTileY(bounds.south, n);
      total += (xMax - xMin + 1) * (yMax - yMin + 1);
    }
    return total;
  }

  /// Rough size estimate in MB.
  /// Average tile: ~15 KB for OSM, ~25 KB for satellite.
  static double estimateSizeMb(int tileCount, {bool satellite = false}) {
    final avgKb = satellite ? 25.0 : 15.0;
    return tileCount * avgKb / 1024.0;
  }

  // Convert longitude to tile X at given total tile count.
  static int _lngToTileX(double lng, int n) {
    return ((lng + 180) / 360 * n).floor().clamp(0, n - 1);
  }

  // Convert latitude to tile Y at given total tile count.
  static int _latToTileY(double lat, int n) {
    final latRad = lat * math.pi / 180;
    return ((1 - math.log(math.tan(latRad) + 1 / math.cos(latRad)) / math.pi) /
            2 *
            n)
        .floor()
        .clamp(0, n - 1);
  }
}
