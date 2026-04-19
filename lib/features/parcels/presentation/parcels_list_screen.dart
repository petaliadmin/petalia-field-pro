import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/fake_api/fake_data.dart';
import '../../../core/services/location_service.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/geo_utils.dart';
import '../../../routes/route_names.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/health_badge.dart';
import '../../../theme/app_colors.dart';
import '../../map/presentation/map_providers.dart';
import '../../map/presentation/parcel_bottom_sheet.dart';
import 'parcels_providers.dart';

/// Unified parcels screen with map (default) / list toggle.
class ParcelsListScreen extends ConsumerStatefulWidget {
  const ParcelsListScreen({super.key});

  @override
  ConsumerState<ParcelsListScreen> createState() => _ParcelsListScreenState();
}

class _ParcelsListScreenState extends ConsumerState<ParcelsListScreen> {
  final _searchCtrl = TextEditingController();
  final _mapController = MapController();
  LatLng? _userPos;

  /// true = map view (default), false = list view
  bool _showMap = true;

  @override
  void initState() {
    super.initState();
    _loadPos();
    if (_showMap) _centerOnParcels();
  }

  Future<void> _loadPos() async {
    final pos = await ref.read(locationServiceProvider).current();
    if (pos != null && mounted) setState(() => _userPos = pos);
  }

  void _centerOnParcels() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final parcels = ref.read(filteredParcelsProvider);
      if (parcels.isEmpty) return;
      final points = parcels.expand((p) => p.boundary).toList();
      if (points.isEmpty) return;
      final bounds = LatLngBounds.fromPoints(points);
      _mapController.fitCamera(
        CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(50)),
      );
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final parcels = ref.watch(filteredParcelsProvider);
    final layer = ref.watch(mapLayerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes Parcelles'),
        actions: [
          // Toggle map / list
          IconButton(
            tooltip: _showMap ? 'Vue liste' : 'Vue carte',
            onPressed: () {
              setState(() => _showMap = !_showMap);
              if (_showMap) _centerOnParcels();
            },
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: Icon(
                _showMap ? Icons.view_list_rounded : Icons.map_rounded,
                key: ValueKey(_showMap),
              ),
            ),
          ),
          IconButton(
            tooltip: 'Ajouter une parcelle',
            onPressed: () => context.push(Routes.addParcel),
            icon: const Icon(Icons.add_location_alt_rounded),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar — shared between both views
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) =>
                  ref.read(parcelSearchProvider.notifier).state = v,
              decoration: const InputDecoration(
                hintText: 'Rechercher une parcelle',
                prefixIcon: Icon(Icons.search_rounded),
              ),
            ),
          ),
          // Content
          Expanded(
            child: parcels.isEmpty
                ? EmptyState(
                    icon: Icons.grass_rounded,
                    title: 'Aucune parcelle pour l\'instant',
                    message:
                        'Ajoutez votre première parcelle pour commencer le suivi.',
                    action: FilledButton.icon(
                      onPressed: () => context.push(Routes.addParcel),
                      icon: const Icon(Icons.add),
                      label: const Text('Ajouter une parcelle'),
                    ),
                  )
                : _showMap
                ? _buildMapView(parcels, layer)
                : _buildListView(parcels),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Map view
  // ---------------------------------------------------------------------------

  Widget _buildMapView(List parcels, MapLayer layer) {
    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: FakeData.defaultCenter,
            initialZoom: 14,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: layer.url,
              userAgentPackageName: 'com.petalia.fieldpro',
            ),
            PolygonLayer(
              polygons: [
                for (final p in parcels)
                  Polygon(
                    points: p.boundary,
                    color: AppColors.healthFor(
                      p.healthScore,
                    ).withValues(alpha: 0.30),
                    borderColor: AppColors.healthFor(p.healthScore),
                    borderStrokeWidth: 2.5,
                  ),
              ],
            ),
            MarkerLayer(
              markers: [
                for (final p in parcels)
                  Marker(
                    point: GeoUtils.centroid(p.boundary),
                    width: 120,
                    height: 64,
                    child: GestureDetector(
                      onTap: () => ParcelBottomSheet.show(context, p),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _ParcelPin(
                            color: AppColors.healthFor(p.healthScore),
                            healthScore: p.healthScore,
                          ),
                          const SizedBox(height: 2),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: const [
                                BoxShadow(color: Colors.black12, blurRadius: 4),
                              ],
                            ),
                            child: Text(
                              p.name,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (_userPos != null)
                  Marker(
                    point: _userPos!,
                    width: 32,
                    height: 32,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.info,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.info.withValues(alpha: 0.6),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
        // My location FAB
        Positioned(
          right: 14,
          top: 14,
          child: Column(
            children: [
              _FabMini(
                icon: Icons.my_location_rounded,
                onTap: () {
                  if (_userPos != null) _mapController.move(_userPos!, 16);
                },
              ),
            ],
          ),
        ),
        // Layer switcher
        Positioned(
          left: 14,
          bottom: 24,
          child: _LayerSwitcher(
            current: layer,
            onChanged: (l) => ref.read(mapLayerProvider.notifier).state = l,
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // List view
  // ---------------------------------------------------------------------------

  Widget _buildListView(List parcels) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      itemCount: parcels.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        final p = parcels[i];
        final area = GeoUtils.polygonAreaHa(p.boundary);
        return GlassCard(
          onTap: () => context.push('${Routes.parcelDetails}/${p.id}'),
          child: Row(
            children: [
              Container(
                height: 52,
                width: 52,
                decoration: BoxDecoration(
                  color: AppColors.healthFor(
                    p.healthScore,
                  ).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  AppColors.healthIconFor(p.healthScore),
                  color: AppColors.healthFor(p.healthScore),
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${p.owner} · ${p.village}',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _Pill(text: p.crop, icon: Icons.grass_rounded),
                        const SizedBox(width: 6),
                        _Pill(
                          text: Fmt.hectares(area),
                          icon: Icons.straighten_rounded,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              HealthBadge(score: p.healthScore, compact: true),
            ],
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Shared sub-widgets
// ---------------------------------------------------------------------------

class _Pill extends StatelessWidget {
  const _Pill({required this.text, required this.icon});
  final String text;
  final IconData icon;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.secondary,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ParcelPin extends StatelessWidget {
  const _ParcelPin({required this.color, required this.healthScore});
  final Color color;
  final double healthScore;
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      width: 36,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2.5),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Icon(
        AppColors.healthIconFor(healthScore),
        color: Colors.white,
        size: 20,
      ),
    );
  }
}

class _FabMini extends StatelessWidget {
  const _FabMini({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 4,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Icon(icon, color: AppColors.primary, size: 24),
        ),
      ),
    );
  }
}

class _LayerSwitcher extends StatelessWidget {
  const _LayerSwitcher({required this.current, required this.onChanged});
  final MapLayer current;
  final ValueChanged<MapLayer> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final l in MapLayer.values)
            InkWell(
              onTap: () => onChanged(l),
              borderRadius: BorderRadius.circular(10),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: current == l
                      ? AppColors.primary.withValues(alpha: 0.12)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _iconFor(l),
                      size: 20,
                      color: current == l
                          ? AppColors.primary
                          : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      l.label,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: current == l
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: current == l
                            ? AppColors.primary
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  IconData _iconFor(MapLayer l) => switch (l) {
    MapLayer.standard => Icons.map_rounded,
    MapLayer.satellite => Icons.satellite_alt_rounded,
    MapLayer.ndvi => Icons.eco_rounded,
  };
}
