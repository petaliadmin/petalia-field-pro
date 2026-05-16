import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../utils/geo_utils.dart';

enum PlaceCategory {
  village,
  hospital,
  market,
  inputSupplier,
  equipmentSupplier,
  waterSource,
}

class NearbyPlace {
  final String name;
  final PlaceCategory category;
  final LatLng location;
  final double distanceKm;

  const NearbyPlace({
    required this.name,
    required this.category,
    required this.location,
    required this.distanceKm,
  });

  String get categoryLabel {
    switch (category) {
      case PlaceCategory.village:
        return 'Village / Ville';
      case PlaceCategory.hospital:
        return 'Hôpital / Centre de santé';
      case PlaceCategory.market:
        return 'Marché';
      case PlaceCategory.inputSupplier:
        return 'Fournisseur d\'intrants';
      case PlaceCategory.equipmentSupplier:
        return 'Matériel agricole';
      case PlaceCategory.waterSource:
        return 'Source d\'eau';
    }
  }

  IconData get icon {
    switch (category) {
      case PlaceCategory.village:
        return Icons.location_city_rounded;
      case PlaceCategory.hospital:
        return Icons.local_hospital_rounded;
      case PlaceCategory.market:
        return Icons.storefront_rounded;
      case PlaceCategory.inputSupplier:
        return Icons.science_rounded;
      case PlaceCategory.equipmentSupplier:
        return Icons.agriculture_rounded;
      case PlaceCategory.waterSource:
        return Icons.water_drop_rounded;
    }
  }

  Color get color {
    switch (category) {
      case PlaceCategory.village:
        return const Color(0xFF5C6BC0);
      case PlaceCategory.hospital:
        return const Color(0xFFE53935);
      case PlaceCategory.market:
        return const Color(0xFFFF8F00);
      case PlaceCategory.inputSupplier:
        return const Color(0xFF43A047);
      case PlaceCategory.equipmentSupplier:
        return const Color(0xFF6D4C41);
      case PlaceCategory.waterSource:
        return const Color(0xFF039BE5);
    }
  }
}

class NearbyPlacesService {
  /// Generates simulated nearby places around a parcel centroid.
  /// In production, this would query a real API (Google Places, OSM Overpass, etc.)
  List<NearbyPlace> getNearbyPlaces(LatLng center) {
    final rng = math.Random(center.latitude.hashCode ^ center.longitude.hashCode);
    return [
      _generate(center, PlaceCategory.village, rng, [
        'Ndioum', 'Keur Momar', 'Diamniadio', 'Sangalkam', 'Thies Nones',
      ]),
      _generate(center, PlaceCategory.hospital, rng, [
        'Centre de Santé de Ndioum', 'Poste de Santé Keur Momar',
        'Hôpital Régional de Thiès', 'Case de Santé Sangalkam',
      ]),
      _generate(center, PlaceCategory.market, rng, [
        'Marché Hebdomadaire Ndioum', 'Louma de Keur Momar',
        'Marché Central de Thiès', 'Marché de Sangalkam',
      ]),
      _generate(center, PlaceCategory.inputSupplier, rng, [
        'SAED Intrants Ndioum', 'AgriPlus Fournitures',
        'SenAgri Distribution', 'Sahel Vert Intrants',
      ]),
      _generate(center, PlaceCategory.equipmentSupplier, rng, [
        'SISMAR Équipements', 'AgriMecano Thiès',
        'SenEquip Matériel', 'Diama Équipements Agricoles',
      ]),
      _generate(center, PlaceCategory.waterSource, rng, [
        'Forage de Ndioum', 'Puits communautaire Keur Momar',
        'Canal d\'irrigation SAED', 'Bassin de rétention',
      ]),
    ];
  }

  NearbyPlace _generate(
    LatLng center,
    PlaceCategory category,
    math.Random rng,
    List<String> names,
  ) {
    // Random offset: 0.5 to 8 km
    final distKm = 0.5 + rng.nextDouble() * 7.5;
    final angle = rng.nextDouble() * 2 * math.pi;
    // Approximate degree offset
    final dLat = (distKm / 111.0) * math.cos(angle);
    final dLon = (distKm / (111.0 * math.cos(center.latitude * math.pi / 180))) *
        math.sin(angle);
    final loc = LatLng(center.latitude + dLat, center.longitude + dLon);
    final actualDist = GeoUtils.distanceKm(center, loc);
    final name = names[rng.nextInt(names.length)];

    return NearbyPlace(
      name: name,
      category: category,
      location: loc,
      distanceKm: actualDist,
    );
  }
}
