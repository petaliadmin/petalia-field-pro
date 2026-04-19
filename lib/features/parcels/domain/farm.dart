library;

import 'package:flutter/material.dart';

class Farm {
  final String id;
  final String name;
  final String owner;
  final String? village;
  final String? cooperative;
  final String? phone;
  final double? totalAreaHa;
  final int parcelCount;
  final DateTime createdAt;

  const Farm({
    required this.id,
    required this.name,
    required this.owner,
    this.village,
    this.cooperative,
    this.phone,
    this.totalAreaHa,
    this.parcelCount = 0,
    required this.createdAt,
  });

  Farm copyWith({
    String? name,
    String? owner,
    String? village,
    String? cooperative,
    String? phone,
    double? totalAreaHa,
    int? parcelCount,
  }) {
    return Farm(
      id: id,
      name: name ?? this.name,
      owner: owner ?? this.owner,
      village: village ?? this.village,
      cooperative: cooperative ?? this.cooperative,
      phone: phone ?? this.phone,
      totalAreaHa: totalAreaHa ?? this.totalAreaHa,
      parcelCount: parcelCount ?? this.parcelCount,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'owner': owner,
    'village': village,
    'cooperative': cooperative,
    'phone': phone,
    'totalAreaHa': totalAreaHa,
    'parcelCount': parcelCount,
    'createdAt': createdAt.toIso8601String(),
  };

  factory Farm.fromJson(Map json) => Farm(
    id: json['id'] as String,
    name: json['name'] as String,
    owner: json['owner'] as String,
    village: json['village'] as String?,
    cooperative: json['cooperative'] as String?,
    phone: json['phone'] as String?,
    totalAreaHa: (json['totalAreaHa'] as num?)?.toDouble(),
    parcelCount: json['parcelCount'] as int? ?? 0,
    createdAt: DateTime.parse(json['createdAt'] as String),
  );
}

enum POIType {
  well('Puit', Icons.water_drop_rounded),
  borehole('Forage', Icons.plumbing_rounded),
  store('Magasin intrants', Icons.store_rounded),
  house('Case/Ferme', Icons.home_rounded),
  pump('Pompe', Icons.rotate_right_rounded),
  fence('Clôture', Icons.fence_rounded),
  other('Autre', Icons.place_rounded);

  final String label;
  final IconData icon;
  const POIType(this.label, this.icon);
}

class FieldPOI {
  final String id;
  final String name;
  final POIType type;
  final double lat;
  final double lng;
  final String? note;
  final String? photoPath;
  final DateTime createdAt;
  final String? createdBy;

  const FieldPOI({
    required this.id,
    required this.name,
    required this.type,
    required this.lat,
    required this.lng,
    this.note,
    this.photoPath,
    required this.createdAt,
    this.createdBy,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'type': type.name,
    'lat': lat,
    'lng': lng,
    'note': note,
    'photoPath': photoPath,
    'createdAt': createdAt.toIso8601String(),
    'createdBy': createdBy,
  };

  factory FieldPOI.fromJson(Map json) => FieldPOI(
    id: json['id'] as String,
    name: json['name'] as String,
    type: POIType.values.firstWhere(
      (t) => t.name == json['type'],
      orElse: () => POIType.other,
    ),
    lat: (json['lat'] as num).toDouble(),
    lng: (json['lng'] as num).toDouble(),
    note: json['note'] as String?,
    photoPath: json['photoPath'] as String?,
    createdAt: DateTime.parse(json['createdAt'] as String),
    createdBy: json['createdBy'] as String?,
  );
}

class Tour {
  final String id;
  final DateTime date;
  final DateTime? startTime;
  final DateTime? endTime;
  final List<TourStop> stops;
  final double totalDistanceKm;
  final String? gpxPath;

  const Tour({
    required this.id,
    required this.date,
    this.startTime,
    this.endTime,
    this.stops = const [],
    this.totalDistanceKm = 0,
    this.gpxPath,
  });

  Duration get duration {
    if (startTime == null || endTime == null) return Duration.zero;
    return endTime!.difference(startTime!);
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'date': date.toIso8601String(),
    'startTime': startTime?.toIso8601String(),
    'endTime': endTime?.toIso8601String(),
    'stops': stops.map((s) => s.toJson()).toList(),
    'totalDistanceKm': totalDistanceKm,
    'gpxPath': gpxPath,
  };

  factory Tour.fromJson(Map json) => Tour(
    id: json['id'] as String,
    date: DateTime.parse(json['date'] as String),
    startTime: json['startTime'] == null
        ? null
        : DateTime.parse(json['startTime'] as String),
    endTime: json['endTime'] == null
        ? null
        : DateTime.parse(json['endTime'] as String),
    stops:
        (json['stops'] as List?)?.map((s) => TourStop.fromJson(s)).toList() ??
        [],
    totalDistanceKm: (json['totalDistanceKm'] as num?)?.toDouble() ?? 0,
    gpxPath: json['gpxPath'] as String?,
  );
}

class TourStop {
  final String parcelId;
  final String parcelName;
  final double lat;
  final double lng;
  final DateTime? arrivalTime;
  final DateTime? departureTime;
  final bool visited;

  const TourStop({
    required this.parcelId,
    required this.parcelName,
    required this.lat,
    required this.lng,
    this.arrivalTime,
    this.departureTime,
    this.visited = false,
  });

  Duration get timeSpent {
    if (arrivalTime == null || departureTime == null) return Duration.zero;
    return departureTime!.difference(arrivalTime!);
  }

  Map<String, dynamic> toJson() => {
    'parcelId': parcelId,
    'parcelName': parcelName,
    'lat': lat,
    'lng': lng,
    'arrivalTime': arrivalTime?.toIso8601String(),
    'departureTime': departureTime?.toIso8601String(),
    'visited': visited,
  };

  factory TourStop.fromJson(Map json) => TourStop(
    parcelId: json['parcelId'] as String,
    parcelName: json['parcelName'] as String,
    lat: (json['lat'] as num).toDouble(),
    lng: (json['lng'] as num).toDouble(),
    arrivalTime: json['arrivalTime'] == null
        ? null
        : DateTime.parse(json['arrivalTime'] as String),
    departureTime: json['departureTime'] == null
        ? null
        : DateTime.parse(json['departureTime'] as String),
    visited: json['visited'] as bool? ?? false,
  );
}
