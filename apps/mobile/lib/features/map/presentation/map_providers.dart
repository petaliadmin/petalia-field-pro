import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/tile_cache_service.dart';
import '../../../l10n/gen/app_localizations.dart';

enum MapLayer { standard, dark, satellite, ndvi }

extension MapLayerX on MapLayer {
  String get url => switch (this) {
    MapLayer.standard => 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
    MapLayer.dark => 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
    MapLayer.satellite =>
      'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
    MapLayer.ndvi =>
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png', // Placeholder
  };

  String label(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return switch (this) {
      MapLayer.standard => l10n.mapLayerStandard,
      MapLayer.dark => l10n.mapLayerDark,
      MapLayer.satellite => l10n.mapLayerSatellite,
      MapLayer.ndvi => l10n.mapLayerNdvi,
    };
  }

  String get storeName => switch (this) {
    MapLayer.standard => TileStores.osm,
    MapLayer.dark => TileStores.dark,
    MapLayer.satellite => TileStores.satellite,
    MapLayer.ndvi => 'ndvi',
  };

  bool get isOverlay => this == MapLayer.ndvi;
}

final mapLayerProvider = StateProvider<MapLayer>((_) => MapLayer.standard);

/// Offline-capable tile provider for the given [MapLayer].
/// Returns either FMTCTileProvider (native with cache) or URL string (web, no cache).
final offlineTileProvider = Provider.family<TileProvider?, MapLayer>((
  ref,
  layer,
) {
  final result = TileCacheService.tileProviderFor(layer.storeName);
  // If result is a string (web fallback), return null to use default network loading
  if (result is String) return null;
  return result as TileProvider;
});

/// NDVI color legend: red=stress, yellow=moderate, green=vigorous
class NdviLegend extends StatelessWidget {
  const NdviLegend({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'NDVI',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _NdviColor(color: Colors.red, label: l10n.mapLegendStress),
              const SizedBox(width: 8),
              _NdviColor(color: Colors.orange, label: l10n.mapLegendModerate),
              const SizedBox(width: 8),
              _NdviColor(color: Colors.green, label: l10n.mapLegendVigorous),
            ],
          ),
        ],
      ),
    );
  }
}

class _NdviColor extends StatelessWidget {
  final Color color;
  final String label;
  const _NdviColor({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 12, height: 12, color: color),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 10)),
      ],
    );
  }
}
