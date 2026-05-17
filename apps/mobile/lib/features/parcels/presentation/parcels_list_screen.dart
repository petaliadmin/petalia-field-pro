import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:petaliacropassist/features/parcels/domain/parcel.dart';
import '../../../core/services/export_service.dart';

import '../../../core/services/location_service.dart';
import '../../../core/services/ndvi_service.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/geo_utils.dart';
import 'package:petaliacropassist/l10n/gen/app_localizations.dart';
import '../../../routes/route_names.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/health_badge.dart';
import '../../../theme/app_colors.dart';
import '../../map/presentation/map_helpers.dart';
import '../../map/presentation/map_providers.dart';
import '../../map/presentation/parcel_bottom_sheet.dart';
import 'parcels_providers.dart';
import 'widgets/health_sparkline.dart';
import '../../../core/services/sync_service.dart';
import '../../../core/services/transcription_service.dart';
import '../../map/presentation/map_caching_sheet.dart';

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

  // Removed local _showMap state to use global provider

  @override
  void initState() {
    super.initState();
    _loadPos();
    // Use a post-frame callback to center if map is active on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ref.read(parcelsViewModeProvider)) _centerOnParcels();
    });
  }

  Future<void> _loadPos() async {
    final pos = await ref.read(locationServiceProvider).current();
    if (pos != null && mounted) setState(() => _userPos = pos);
  }

  void _centerOnParcels() {
    centerMapOnParcels(_mapController, ref.read(filteredParcelsProvider));
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final parcels = ref.watch(filteredParcelsProvider);
    final allParcels = ref.watch(parcelsProvider);
    final layer = ref.watch(mapLayerProvider);
    final crops = ref.watch(parcelCropsAvailableProvider);
    final selectedCrop = ref.watch(parcelCropFilterProvider);
    final isSearching = ref.watch(parcelSearchProvider).isNotEmpty || selectedCrop != null;

    // Auto-switch to dark tiles if in dark mode and standard is selected.
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveLayer = (layer == MapLayer.standard && isDark) ? MapLayer.dark : layer;

    final showMap = ref.watch(parcelsViewModeProvider);

    Widget content;
    if (allParcels.isEmpty) {
      content = EmptyState(
        icon: Icons.grass_rounded,
        title: l10n.parcelsEmptyTitle,
        message: l10n.parcelsEmptyMessage,
        action: FilledButton.icon(
          onPressed: () => context.push(Routes.addParcel),
          icon: const Icon(Icons.add),
          label: Text(l10n.parcelsAddButton),
        ),
      );
    } else if (parcels.isEmpty && isSearching) {
      content = Column(
        children: [
          _buildSearchAndFilters(crops, selectedCrop, l10n),
          Expanded(
            child: EmptyState(
              icon: Icons.search_off_rounded,
              title: 'Aucun résultat',
              message: 'Essayez de modifier vos filtres ou le texte de recherche.',
              action: TextButton.icon(
                onPressed: () {
                  _searchCtrl.clear();
                  ref.read(parcelSearchProvider.notifier).state = '';
                  ref.read(parcelCropFilterProvider.notifier).state = null;
                },
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Réinitialiser'),
              ),
            ),
          ),
        ],
      );
    } else if (showMap) {
      content = _buildMapView(parcels, effectiveLayer, crops, selectedCrop, l10n);
    } else {
      content = Column(
        children: [
          _buildSearchAndFilters(crops, selectedCrop, l10n),
          Expanded(child: _buildListView(parcels)),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Scaffold.of(context).openDrawer(),
          icon: const Icon(Icons.menu_rounded),
          tooltip: 'Menu principal',
        ),
        title: Text(l10n.parcelsTitle),
        actions: [
          // Global Sync Indicator
          Consumer(
            builder: (context, ref, _) {
              final syncStatus = ref.watch(syncServiceProvider);
              if (syncStatus.pending == 0) {
                return const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(Icons.cloud_done_rounded, color: AppColors.success, size: 20),
                );
              }
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(
                      syncStatus.state == SyncState.syncing 
                          ? Icons.sync_rounded 
                          : Icons.cloud_upload_rounded,
                      color: AppColors.warning,
                      size: 22,
                    ),
                    if (syncStatus.pending > 0)
                      Positioned(
                        right: 0,
                        top: 10,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(color: AppColors.danger, shape: BoxShape.circle),
                          constraints: const BoxConstraints(minWidth: 12, minHeight: 12),
                          child: Text(
                            '${syncStatus.pending}',
                            style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.cloud_download_rounded),
            onPressed: () => ref.read(parcelsProvider.notifier).fetchRemoteParcels(),
            tooltip: 'Synchroniser avec le serveur',
          ),
          IconButton(
            icon: const Icon(Icons.share_rounded),
            onPressed: () => _showExportOptions(context, parcels, l10n),
            tooltip: l10n.exportTitle,
          ),
          IconButton(
            tooltip: showMap ? l10n.tooltipListView : l10n.tooltipMapView,
            onPressed: () {
              final newVal = !showMap;
              ref.read(parcelsViewModeProvider.notifier).state = newVal;
              if (newVal) _centerOnParcels();
            },
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: Icon(
                showMap ? Icons.view_list_rounded : Icons.map_rounded,
                key: ValueKey(showMap),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: parcels.isEmpty
          ? null
          : Padding(
              padding: const EdgeInsets.only(bottom: 32),
              child: FloatingActionButton.extended(
                onPressed: () => context.push(Routes.addParcel),
                icon: const Icon(Icons.add_location_alt_rounded),
                label: Text(l10n.parcelsAddButton),
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
      body: content,
    );
  }

  Widget _buildSearchAndFilters(List<String> crops, String? selectedCrop, AppLocalizations l10n) {
    final sortMode = ref.watch(parcelSortModeProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (v) => ref.read(parcelSearchProvider.notifier).state = v,
                  decoration: InputDecoration(
                    hintText: l10n.parcelsSearchHint,
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.mic_rounded, color: AppColors.primary),
                      onPressed: () async {
                        final stt = ref.read(transcriptionServiceProvider);
                        final available = await stt.init();
                        if (available) {
                          stt.startListening(onResult: (text) {
                            _searchCtrl.text = text;
                            ref.read(parcelSearchProvider.notifier).state = text;
                          });
                        }
                      },
                    ),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surface,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Sort toggle
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
                  ),
                ),
                child: IconButton(
                  icon: Icon(
                    sortMode == ParcelSortMode.distance 
                        ? Icons.near_me_rounded 
                        : Icons.sort_by_alpha_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  onPressed: () {
                    final next = sortMode == ParcelSortMode.name 
                        ? ParcelSortMode.distance 
                        : ParcelSortMode.name;
                    ref.read(parcelSortModeProvider.notifier).state = next;
                  },
                  tooltip: sortMode == ParcelSortMode.distance 
                      ? 'Tri par proximité' 
                      : 'Tri par nom',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (crops.isNotEmpty)
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  ChoiceChip(
                    label: Text(l10n.parcelsAllCrops),
                    selected: selectedCrop == null,
                    onSelected: (s) => ref.read(parcelCropFilterProvider.notifier).state = null,
                  ),
                  const SizedBox(width: 8),
                  ...crops.map((c) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(c),
                      selected: selectedCrop == c,
                      onSelected: (s) => ref.read(parcelCropFilterProvider.notifier).state = s ? c : null,
                    ),
                  )),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Map view
  // ---------------------------------------------------------------------------

  Widget _buildMapView(
    List parcels,
    MapLayer layer,
    List<String> crops,
    String? selectedCrop,
    AppLocalizations l10n,
  ) {
    return Stack(
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
              urlTemplate: layer.url,
              maxZoom: 24,
              maxNativeZoom: 18,
              userAgentPackageName: 'com.petalia.fieldpro',
            ),
            PolygonLayer(
              polygons: [
                for (final p in parcels)
                  Polygon(
                    points: p.boundary,
                    color: ref.watch(ndviProvider(p.id)).maybeWhen(
                      data: (ndvi) => AppColors.healthFor(ndvi.value).withValues(alpha: 0.30),
                      orElse: () => AppColors.healthFor(p.healthScore).withValues(alpha: 0.10),
                    ),
                    borderColor: ref.watch(ndviProvider(p.id)).maybeWhen(
                      data: (ndvi) => AppColors.healthFor(ndvi.value),
                      orElse: () => AppColors.healthFor(p.healthScore).withValues(alpha: 0.4),
                    ),
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
                          Consumer(
                            builder: (context, ref, _) {
                              final ndviAsync = ref.watch(ndviProvider(p.id));
                              final score = ndviAsync.maybeWhen(
                                data: (n) => n.value,
                                orElse: () => p.healthScore,
                              );
                              return _ParcelPin(
                                color: AppColors.healthFor(score),
                                healthScore: score,
                              );
                            },
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
                              border: Border.all(
                                color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
                                width: 0.5,
                              ),
                              boxShadow: const [
                                BoxShadow(color: Colors.black26, blurRadius: 4),
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
              const SizedBox(height: 12),
              _FabMini(
                icon: Icons.download_for_offline_rounded,
                onTap: () {
                  final bounds = _mapController.camera.visibleBounds;
                  MapCachingSheet.show(context, bounds, layer.storeName);
                },
              ),
            ],
          ),
        ),
        // Search and filters over map
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: _buildSearchAndFilters(crops, selectedCrop, l10n),
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

  Widget _buildListView(List<Parcel> parcels) {
    return RefreshIndicator(
      onRefresh: () => ref.read(parcelsProvider.notifier).fetchRemoteParcels(),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        itemCount: parcels.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, i) {
          final p = parcels[i];
          final area = GeoUtils.polygonAreaHa(p.boundary);
          
          return Consumer(
            builder: (context, ref, _) {
              final ndviAsync = ref.watch(ndviProvider(p.id));
              final score = ndviAsync.maybeWhen(
                data: (n) => n.value,
                orElse: () => p.healthScore,
              );
              
              final userLoc = ref.watch(userLocationProvider).valueOrNull;
              String? distanceStr;
              if (userLoc != null && p.boundary.isNotEmpty) {
                final d = const Distance().as(LengthUnit.Meter, userLoc, p.boundary.first);
                distanceStr = d > 1000 
                    ? '${(d / 1000).toStringAsFixed(1)} km' 
                    : '${d.round()} m';
              }

              return GlassCard(
                onTap: () => context.push('${Routes.parcelDetails}/${p.id}'),
                child: Row(
                  children: [
                    Container(
                      height: 52,
                      width: 52,
                      decoration: BoxDecoration(
                        color: AppColors.healthFor(score).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        AppColors.healthIconFor(score),
                        color: AppColors.healthFor(score),
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  p.name,
                                  style: Theme.of(context).textTheme.titleMedium,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (distanceStr != null) ...[
                                const SizedBox(width: 8),
                                Text(
                                  distanceStr,
                                  style: TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${p.owner} · ${p.village}',
                            style: TextStyle(
                              color: AppColors.textSecondaryOf(context),
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
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Hero(
                          tag: 'parcel-${p.id}-health-list',
                          child: Material(
                            type: MaterialType.transparency,
                            child: HealthBadge(score: score, compact: true),
                          ),
                        ),
                        const SizedBox(height: 6),
                        HealthSparkline(parcelId: p.id),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showExportOptions(BuildContext context, List<Parcel> parcels, AppLocalizations l10n) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.dividerOf(context), borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 24),
            Text(l10n.exportTitle, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            _ExportTile(
              icon: Icons.picture_as_pdf_rounded,
              title: l10n.exportPdf,
              color: AppColors.primary,
              onTap: () async {
                Navigator.pop(context);
                await ExportService.exportToPdf(parcels, l10n);
              },
            ),
            const SizedBox(height: 12),
            _ExportTile(
              icon: Icons.table_chart_rounded,
              title: l10n.exportExcel,
              color: AppColors.success,
              onTap: () async {
                Navigator.pop(context);
                await ExportService.exportToExcel(parcels, l10n);
              },
            ),
          ],
        ),
      ),
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
        color: AppColors.surfaceAltOf(context),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondaryOf(context)),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondaryOf(context),
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
      color: AppColors.surfaceOf(context),
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    // On cache 'dark' en mode clair et 'standard' en mode sombre 
    // pour éviter la redondance car le switch est automatique.
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
}

IconData _iconFor(MapLayer l) => switch (l) {
  MapLayer.standard => Icons.map_rounded,
  MapLayer.dark => Icons.dark_mode_rounded,
  MapLayer.satellite => Icons.satellite_alt_rounded,
  MapLayer.ndvi => Icons.eco_rounded,
};

class _ExportTile extends StatelessWidget {
  const _ExportTile({required this.icon, required this.title, required this.color, required this.onTap});
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 16),
          Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16))),
          const Spacer(),
          Icon(Icons.chevron_right_rounded, color: AppColors.textSecondaryOf(context)),
        ],
      ),
    );
  }
}
