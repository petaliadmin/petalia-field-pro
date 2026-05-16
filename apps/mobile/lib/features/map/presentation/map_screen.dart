import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/network/connectivity_service.dart';
import '../../../core/services/location_service.dart';
import '../../../core/services/tile_cache_service.dart';
import '../../../core/services/credit_service.dart';
import '../../../core/utils/geo_utils.dart';
import '../../../routes/route_names.dart';
import '../../../theme/app_colors.dart';
import '../../parcels/presentation/parcels_providers.dart';
import 'map_helpers.dart';
import 'map_providers.dart';
import 'parcel_bottom_sheet.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  final _mapController = MapController();
  LatLng? _userPos;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadPos();
    _centerOnParcels();
  }

  void _centerOnParcels() {
    centerMapOnParcels(_mapController, ref.read(filteredParcelsProvider));
  }

  Future<void> _loadPos() async {
    final pos = await ref.read(locationServiceProvider).current();
    if (pos != null && mounted) setState(() => _userPos = pos);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  IconData _getLayerIcon(WidgetRef ref) {
    return ref.read(mapLayerProvider).isOverlay
        ? Icons.layers_clear_rounded
        : Icons.layers_rounded;
  }

  Future<void> _cycleLayer(WidgetRef ref) async {
    final current = ref.read(mapLayerProvider);
    final layers = MapLayer.values;
    final idx = layers.indexOf(current);
    final next = layers[(idx + 1) % layers.length];

    if (next == MapLayer.ndvi) {
      final creditService = ref.read(creditServiceProvider.notifier);
      if (creditService.credits < CreditService.costNdvi) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Crédits insuffisants pour la couche NDVI (1 crédit requis).')),
        );
        context.push(Routes.wallet);
        return;
      }
      await creditService.useCredits(CreditService.costNdvi);
    }

    ref.read(mapLayerProvider.notifier).state = next;
  }

  @override
  Widget build(BuildContext context) {
    final parcels = ref.watch(filteredParcelsProvider);
    final layer = ref.watch(mapLayerProvider);

    // Auto-switch to dark tiles if in dark mode and standard is selected.
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveLayer = (layer == MapLayer.standard && isDark) ? MapLayer.dark : layer;

    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: const LatLng(14.7889, -16.9260),
              initialZoom: 14,
              maxZoom: 24,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: effectiveLayer.url,
                maxZoom: 24,
                maxNativeZoom: 18,
                userAgentPackageName: 'com.petalia.fieldpro',
                tileProvider: isFmtcSupported
                    ? ref.watch(offlineTileProvider(effectiveLayer))
                    : null, // Web: use default network loading
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
              // Clustering auto au-delà de 30 parcelles : au-dessous, un
              // MarkerLayer classique garde tous les labels lisibles. Le
              // marqueur utilisateur est toujours exclu du cluster.
              if (parcels.length > 30)
                MarkerClusterLayerWidget(
                  options: MarkerClusterLayerOptions(
                    maxClusterRadius: 80,
                    size: const Size(44, 44),
                    padding: const EdgeInsets.all(40),
                    maxZoom: 24,
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
                                    color: Theme.of(context).colorScheme.surface,
                                    borderRadius: BorderRadius.circular(8),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Colors.black12,
                                        blurRadius: 4,
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    p.name,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    color: Theme.of(context).colorScheme.onSurface,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                    builder: (context, markers) {
                      return Container(
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '${markers.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      );
                    },
                  ),
                )
              else
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
                                    BoxShadow(
                                      color: Colors.black12,
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                                child: Text(
                                  p.name,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Theme.of(context).colorScheme.onSurface,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              // Marqueur utilisateur — hors cluster pour qu'il reste visible.
              if (_userPos != null)
                MarkerLayer(
                  markers: [
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
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 16, 0),
              child: Row(
                children: [
                  Material(
                    color: Colors.white,
                    elevation: 3,
                    shape: const CircleBorder(),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                      color: AppColors.primary,
                      onPressed: () {
                        if (context.canPop()) {
                          context.pop();
                        } else {
                          context.go(Routes.dashboard);
                        }
                      },
                      tooltip: 'Retour',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _SearchBar(
                      controller: _searchCtrl,
                      onChanged: (v) =>
                          ref.read(parcelSearchProvider.notifier).state = v,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            right: 14,
            top: MediaQuery.of(context).padding.top + 80,
            child: Column(
              children: [
                _FabMini(
                  icon: Icons.my_location_rounded,
                  onTap: () {
                    if (_userPos != null) {
                      _mapController.move(_userPos!, 16);
                    }
                  },
                ),
                const SizedBox(height: 10),
                _FabMini(
                  icon: _getLayerIcon(ref),
                  onTap: () => _cycleLayer(ref),
                ),
                const SizedBox(height: 10),
                _FabMini(
                  icon: Icons.add_location_alt_rounded,
                  onTap: () => context.push(Routes.addParcel),
                ),
              ],
            ),
          ),
          // Download progress banner
          Positioned(left: 0, right: 0, bottom: 0, child: _DownloadBanner()),
          // Offline chip
          Positioned(left: 14, bottom: 80, child: _OfflineChip()),
          Positioned(
            left: 14,
            bottom: 24,
            child: _LayerSwitcher(
              current: effectiveLayer,
              onChanged: (l) => ref.read(mapLayerProvider.notifier).state = l,
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: 36,
          width: 36,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2.5),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            AppColors.healthIconFor(healthScore),
            color: Colors.white,
            size: 20,
          ),
        ),
      ],
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

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.controller, required this.onChanged});
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 3,
      borderRadius: BorderRadius.circular(18),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: 'Rechercher parcelle, agriculteur, village…',
          prefixIcon: const Icon(Icons.search_rounded),
          fillColor: Theme.of(context).colorScheme.surface,
          filled: true,
          border: InputBorder.none,
          focusedBorder: InputBorder.none,
          enabledBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Filter layers to avoid redundancy with auto-switch
    final availableLayers = MapLayer.values.where((l) {
      if (isDark && l == MapLayer.standard) return false;
      if (!isDark && l == MapLayer.dark) return false;
      return true;
    }).toList();

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: 0.1),
          width: 1,
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final l in availableLayers)
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
                      ? theme.colorScheme.primary.withValues(alpha: 0.15)
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
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      l.label(context),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: current == l
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: current == l
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurface,
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
    MapLayer.dark => Icons.dark_mode_rounded,
    MapLayer.satellite => Icons.satellite_alt_rounded,
    MapLayer.ndvi => Icons.eco_rounded,
  };
}

class _OfflineChip extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(networkStatusProvider);
    final isOffline =
        status.whenOrNull(data: (s) => s == NetworkStatus.offline) ?? false;
    if (!isOffline) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.cloud_off_rounded, size: 16, color: AppColors.warning),
          const SizedBox(width: 6),
          Text(
            'Carte hors-ligne',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.warning,
            ),
          ),
        ],
      ),
    );
  }
}

class _DownloadBanner extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(tileDownloadProgressProvider);
    return progress.when(
      data: (p) {
        if (p == null || p.isComplete) return const SizedBox.shrink();
        final pct = p.maxTiles > 0 ? p.cachedTiles / p.maxTiles : 0.0;
        return Container(
          color: AppColors.primary.withValues(alpha: 0.95),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Téléchargement carte… ${(pct * 100).toInt()}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      '${p.cachedTiles}/${p.maxTiles}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: pct,
                    backgroundColor: Colors.white24,
                    color: Colors.white,
                    minHeight: 4,
                  ),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
