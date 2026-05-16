import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:petaliacropassist/core/utils/geo_utils.dart';

void main() {
  group('GeoUtils', () {
    test('distanceKm should be accurate', () {
      // Distance between Dakar (14.7167, -17.4677) and Thies (14.7917, -16.9250)
      // approx 59km
      final dakar = const LatLng(14.7167, -17.4677);
      final thies = const LatLng(14.7917, -16.9250);
      
      final dist = GeoUtils.distanceKm(dakar, thies);
      expect(dist, closeTo(59.0, 1.0));
    });

    test('centroid should be correct', () {
      final pts = [
        const LatLng(0, 0),
        const LatLng(0, 2),
        const LatLng(2, 2),
        const LatLng(2, 0),
      ];
      final c = GeoUtils.centroid(pts);
      expect(c.latitude, 1.0);
      expect(c.longitude, 1.0);
    });

    test('polygonAreaHa should return 0 for less than 3 points', () {
      expect(GeoUtils.polygonAreaHa([]), 0);
      expect(GeoUtils.polygonAreaHa([const LatLng(0, 0)]), 0);
    });

    test('polygonAreaHa for a 100m x 100m square should be approx 1 hectare', () {
      // 0.0009 degrees is approx 100m at equator
      const side = 0.0008983; // approx 100m
      final square = [
        const LatLng(0, 0),
        const LatLng(0, side),
        const LatLng(side, side),
        const LatLng(side, 0),
      ];
      
      final area = GeoUtils.polygonAreaHa(square);
      expect(area, closeTo(1.0, 0.05));
    });

    test('nearestNeighborRoute should return points in order of proximity', () {
      final origin = const LatLng(0, 0);
      final pts = [
        const LatLng(0, 10), // index 0 (far)
        const LatLng(0, 1),  // index 1 (near)
        const LatLng(0, 5),  // index 2 (middle)
      ];
      
      final route = GeoUtils.nearestNeighborRoute(origin, pts);
      expect(route, [1, 2, 0]);
    });
  });
}
