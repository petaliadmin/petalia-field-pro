import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

import '../../parcels/domain/parcel.dart';

/// Fits the map camera to the bounding box of all parcels' boundaries.
///
/// Schedules the fit on the next frame so it runs after the [FlutterMap] widget
/// has been mounted and laid out. Safe to call from `initState`.
///
/// Returns immediately (no-op) if the list is empty or no parcel has a boundary.
void centerMapOnParcels(
  MapController controller,
  List<Parcel> parcels, {
  EdgeInsets padding = const EdgeInsets.all(50),
}) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (parcels.isEmpty) return;
    final points = parcels.expand((p) => p.boundary).toList();
    if (points.isEmpty) return;
    final bounds = LatLngBounds.fromPoints(points);
    controller.fitCamera(CameraFit.bounds(bounds: bounds, padding: padding));
  });
}
