// Some private widgets (_KV, _ParcelHealthChart, _NearbyTab, _Todo) are kept
// for WIP tabs that are not yet wired in the build tree.
// ignore_for_file: unused_element, unused_element_parameter, dead_code
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/foundation.dart' show kIsWeb;

import 'package:petaliacropassist/core/services/location_service.dart';
import 'package:petaliacropassist/features/parcels/domain/parcel.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/messenger_utils.dart';
import '../../../core/data/soil_types.dart';
import '../../../core/services/nearby_places_service.dart';
import '../../../core/services/credit_service.dart';
import '../../../core/services/ndvi_service.dart';
import '../../../core/services/phenology_service.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/geo_utils.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../../routes/route_names.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/health_badge.dart';
import '../../../theme/app_colors.dart';
import 'parcels_providers.dart';

class ParcelDetailsScreen extends ConsumerStatefulWidget {
  const ParcelDetailsScreen({super.key, required this.parcelId});
  final String parcelId;

  @override
  ConsumerState<ParcelDetailsScreen> createState() =>
      _ParcelDetailsScreenState();
}

class _ParcelDetailsScreenState extends ConsumerState<ParcelDetailsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;
  final _mapController = MapController();
  bool _mapLocked = true;
  LatLng? _userPos;
  bool _showRoute = false;
  bool _isLocating = false;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final parcel = ref.watch(parcelByIdProvider(widget.parcelId));
    if (parcel == null) {
      final l10n = AppLocalizations.of(context);
      return Scaffold(
        appBar: AppBar(title: Text(l10n.parcelDetailTitle)),
        body: const EmptyState(
          icon: Icons.search_off_rounded,
          title: 'Parcelle introuvable',
          message: 'Cette parcelle a peut-être été supprimée.',
        ),
      );
    }

    final ndviSnapshot = ref.watch(ndviProvider(widget.parcelId)).valueOrNull;
    final area = GeoUtils.polygonAreaHa(parcel.boundary);

    return Scaffold(
      key: Key(widget.parcelId),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            expandedHeight: MediaQuery.of(context).size.height * 0.48,
            pinned: true,
            stretch: true,
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            leading: _AppBarBtn(
              icon: Icons.arrow_back_rounded,
              onTap: () => context.pop(),
            ),
            actions: [
              _AppBarBtn(
                icon: Icons.layers_outlined,
                onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Sélecteur de couches bientôt disponible')),
                ),
              ),
              const SizedBox(width: 8),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
                onSelected: (value) {
                  switch (value) {
                    case 'edit':
                      context.push(Routes.editParcel, extra: parcel);
                      break;
                    case 'export':
                      context.push(Routes.reportPreview, extra: {'parcelId': parcel.id});
                      break;
                    case 'passport':
                      _sharePassport(parcel.id);
                      break;
                    case 'delete':
                      _showDeleteConfirmation(context);
                      break;
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        const Icon(Icons.edit_outlined, size: 20),
                        const SizedBox(width: 12),
                        Text(AppLocalizations.of(context).parcelMenuEdit),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'export',
                    child: Row(
                      children: [
                        const Icon(Icons.picture_as_pdf_outlined, size: 20),
                        const SizedBox(width: 12),
                        Text(AppLocalizations.of(context).parcelMenuExport),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'passport',
                    child: Row(
                      children: [
                        const Icon(Icons.qr_code_2_rounded, size: 20),
                        const SizedBox(width: 12),
                        const Text('Passeport Public'),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline_rounded, size: 20, color: AppColors.danger),
                        SizedBox(width: 12),
                        Text('Supprimer', style: TextStyle(color: AppColors.danger)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 8),
            ],
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [StretchMode.zoomBackground, StretchMode.blurBackground],
              background: Stack(
                fit: StackFit.expand,
                children: [
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: GeoUtils.centroid(parcel.boundary),
                      initialZoom: 17,
                      interactionOptions: InteractionOptions(
                        flags: _mapLocked ? InteractiveFlag.none : InteractiveFlag.all & ~InteractiveFlag.rotate,
                      ),
                      onMapReady: () => _centerMapOnParcel(parcel),
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://mt1.google.com/vt/lyrs=y&x={x}&y={y}&z={z}',
                        maxZoom: 22,
                        maxNativeZoom: 20,
                        userAgentPackageName: 'com.petalia.fieldpro',
                      ),
                      if (ndviSnapshot?.tileUrl != null && ndviSnapshot!.tileUrl!.isNotEmpty)
                        TileLayer(
                          urlTemplate: ndviSnapshot.tileUrl!,
                          maxZoom: 22,
                          maxNativeZoom: 20,
                          userAgentPackageName: 'com.petalia.fieldpro',
                        ),
                      PolygonLayer(
                        polygons: [
                          Polygon(
                            points: parcel.boundary,
                            color: Colors.transparent, // Heatmap will provide the fill
                            borderColor: AppColors.primary.withOpacity(0.5),
                            borderStrokeWidth: 2,
                            isFilled: false,
                          ),
                        ],
                      ),
                      MarkerLayer(
                        markers: _buildHeatmapMarkers(parcel.boundary, parcel.healthScore),
                      ),
                      if (_showRoute && _userPos != null) ...[
                        PolylineLayer(
                          polylines: [
                            Polyline(
                              points: [_userPos!, GeoUtils.centroid(parcel.boundary)],
                              color: AppColors.primary,
                              strokeWidth: 5,
                              borderColor: Colors.white,
                              borderStrokeWidth: 1,
                            ),
                          ],
                        ),
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: _userPos!,
                              width: 40,
                              height: 40,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2),
                                ),
                                child: const Icon(Icons.person_pin_circle_rounded, color: Colors.blue, size: 30),
                              ),
                            ),
                            Marker(
                              point: GeoUtils.centroid(parcel.boundary),
                              width: 40,
                              height: 40,
                              child: const Icon(Icons.location_on_rounded, color: Colors.red, size: 35),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                  // Dégradé pour le titre en mode collapsed (Placé derrière les boutons pour ne pas bloquer le clic)
                  const IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.black26, Colors.transparent, Colors.black45],
                        ),
                      ),
                      child: SizedBox.expand(),
                    ),
                  ),
                  // Contrôles de carte (Placés après le dégradé pour être cliquables)
                  Positioned(
                    top: MediaQuery.of(context).padding.top + 55,
                    right: 12,
                    child: Column(
                      children: [
                        _MapIconBtn(
                          icon: _mapLocked ? Icons.lock_outline_rounded : Icons.lock_open_rounded,
                          color: _mapLocked ? Colors.black54 : AppColors.accent,
                          onTap: () {
                            setState(() => _mapLocked = !_mapLocked);
                          },
                        ),
                        if (!_mapLocked) ...[
                          const SizedBox(height: 12),
                          _MapIconBtn(
                            icon: Icons.add_rounded,
                            onTap: () => _mapController.move(_mapController.camera.center, _mapController.camera.zoom + 1),
                          ),
                          const SizedBox(height: 12),
                          _MapIconBtn(
                            icon: Icons.remove_rounded,
                            onTap: () => _mapController.move(_mapController.camera.center, _mapController.camera.zoom - 1),
                          ),
                          const SizedBox(height: 12),
                          _MapIconBtn(
                            icon: Icons.my_location_rounded,
                            onTap: () => _mapController.move(GeoUtils.centroid(parcel.boundary), 17),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              title: Text(parcel.name, style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.white)),
              centerTitle: false,
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(110),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.dividerOf(context), borderRadius: BorderRadius.circular(2))),
                    TabBar(
                      controller: _tab,
                      isScrollable: true,
                      tabAlignment: TabAlignment.start,
                      indicatorColor: AppColors.primary,
                      indicatorWeight: 3,
                      indicatorSize: TabBarIndicatorSize.label,
                      labelColor: AppColors.primary,
                      unselectedLabelColor: Theme.of(context).colorScheme.onSurfaceVariant,
                      labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, letterSpacing: -0.2),
                      unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      tabs: [
                        Tab(text: AppLocalizations.of(context).parcelTabSummary, icon: const Icon(Icons.dashboard_rounded, size: 20)),
                        Tab(text: AppLocalizations.of(context).parcelTabDetails, icon: const Icon(Icons.analytics_rounded, size: 20)),
                        Tab(text: AppLocalizations.of(context).parcelTabVisits, icon: const Icon(Icons.history_rounded, size: 20)),
                        Tab(text: AppLocalizations.of(context).parcelTabPhotos, icon: const Icon(Icons.camera_alt_rounded, size: 20)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
        body: Container(
          color: Theme.of(context).scaffoldBackgroundColor,
          child: Column(
            children: [
              // KPIs Header (Quick view)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${parcel.owner} · ${parcel.crop}', 
                               style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.8), fontWeight: FontWeight.w600, fontSize: 14)),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              _MiniKV(label: AppLocalizations.of(context).parcelKpiSurface, value: Fmt.hectares(area)),
                              const SizedBox(width: 16),
                              _MiniKV(label: AppLocalizations.of(context).parcelKpiYield, value: '${parcel.estimatedYield}T'),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (parcel.phone != null && parcel.phone!.trim().isNotEmpty)
                      Row(
                        children: [
                          _ContactBtn(
                            icon: Icons.call_rounded,
                            onTap: () => _launchPhone(parcel.phone!),
                            color: AppColors.primary,
                            tooltip: 'Appeler',
                          ),
                          const SizedBox(width: 8),
                          _ContactBtn(
                            icon: Icons.chat_bubble_outline_rounded,
                            onTap: () => _launchWhatsApp(parcel.phone!),
                            color: const Color(0xFF25D366),
                            tooltip: 'WhatsApp',
                          ),
                        ],
                      )
                    else
                      _ActionButton(
                        onTap: _toggleRoute,
                        icon: _isLocating ? null : (_showRoute ? Icons.close_rounded : Icons.navigation_rounded),
                        label: _isLocating 
                            ? AppLocalizations.of(context).parcelActionLocating 
                            : (_showRoute 
                                ? AppLocalizations.of(context).parcelActionStop 
                                : AppLocalizations.of(context).parcelActionNavigate),
                        active: _showRoute,
                      ),
                  ],
                ),
              ),
              Expanded(
                child: TabBarView(
                  controller: _tab,
                  children: [
                    _OverviewTab(parcelId: widget.parcelId),
                    _DetailsTab(parcel: parcel),
                    _VisitsTab(parcelId: widget.parcelId),
                    _PhotosTab(parcelId: widget.parcelId),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('${Routes.observation}/${widget.parcelId}'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_a_photo_rounded),
        label: const Text('Observation', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }

  Future<void> _toggleRoute() async {
    if (_showRoute) {
      setState(() => _showRoute = false);
      return;
    }

    setState(() => _isLocating = true);

    try {
      final pos = await ref.read(locationServiceProvider).current();
      if (!context.mounted) return;
      
      if (pos == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Impossible de récupérer votre position. Vérifiez votre GPS.')),
        );
        setState(() => _isLocating = false);
        return;
      }

      setState(() {
        _userPos = pos;
        _showRoute = true;
        _mapLocked = false;
        _isLocating = false;
      });
      
      final parcel = ref.read(parcelByIdProvider(widget.parcelId));
      if (parcel != null && parcel.boundary.isNotEmpty) {
        final target = GeoUtils.centroid(parcel.boundary);
        final bounds = LatLngBounds.fromPoints([pos, target]);
        
        // Petit délai pour laisser le temps au clavier/UI de se stabiliser
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            _mapController.fitCamera(
              CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(80)),
            );
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLocating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur GPS : $e')),
        );
      }
    }
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer cette parcelle ?'),
        content: const Text(
          'Cette action est irréversible. Toutes les visites et observations liées seront également supprimées.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () async {
              // On ferme d'abord le dialogue
              Navigator.pop(context);
              
              // On lance la suppression via le provider
              await ref.read(parcelsProvider.notifier).delete(widget.parcelId);
              
              // On retourne à la liste
              if (context.mounted) {
                context.go(Routes.parcels);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Parcelle supprimée avec succès'),
                    backgroundColor: AppColors.success,
                  ),
                );
              }
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  void _centerMapOnParcel(Parcel parcel) {
    if (parcel.boundary.isEmpty) return;

    final bounds = LatLngBounds.fromPoints(parcel.boundary);
    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.all(50),
      ),
    );
  }

  Future<void> _launchPhone(String phone) async {
    final uri = Uri.parse('tel:${phone.replaceAll(RegExp(r'[^0-9+]'), '')}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _launchWhatsApp(String phone) async {
    String clean = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (clean.length == 9 && (clean.startsWith('7') || clean.startsWith('3'))) {
      clean = '221$clean';
    }
    // Format E.164 without + for WhatsApp URL
    final uri = Uri.parse('https://api.whatsapp.com/send/?phone=$clean&text&type=phone_number&app_absent=0');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _sharePassport(String id) async {
    // Dans une app réelle, l'URL de base viendrait de la config
    final url = 'https://petalia-agro.com/parcels/passport/$id';
    
    // On utilise share_plus (supposé présent car dans pubspec)
    // Mais ici on peut aussi juste copier ou ouvrir
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  List<Marker> _buildHeatmapMarkers(List<LatLng> boundary, double healthScore) {
    if (boundary.isEmpty) return [];

    double minLat = boundary[0].latitude;
    double maxLat = boundary[0].latitude;
    double minLon = boundary[0].longitude;
    double maxLon = boundary[0].longitude;
    for (final p in boundary) {
      minLat = math.min(minLat, p.latitude);
      maxLat = math.max(maxLat, p.latitude);
      minLon = math.min(minLon, p.longitude);
      maxLon = math.max(maxLon, p.longitude);
    }

    final markers = <Marker>[];
    const gridCount = 12;
    final stepLat = (maxLat - minLat) / gridCount;
    final stepLon = (maxLon - minLon) / gridCount;

    final random = math.Random(boundary.length);

    for (double lat = minLat; lat <= maxLat; lat += stepLat) {
      for (double lon = minLon; lon <= maxLon; lon += stepLon) {
        final pt = LatLng(lat, lon);
        if (GeoUtils.isPointInPolygon(pt, boundary)) {
          final val = (healthScore - 0.15) + (random.nextDouble() * 0.3);
          final clampedVal = val.clamp(0.0, 1.0);
          final color = AppColors.healthFor(clampedVal).withOpacity(0.4);
          
          markers.add(
            Marker(
              point: pt,
              width: 30,
              height: 30,
              child: Container(
                decoration: BoxDecoration(
                  color: color.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(2),
                  border: Border.all(color: Colors.white10, width: 0.5),
                ),
              ),
            ),
          );
        }
      }
    }
    return markers;
  }
}

class _KV extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;
  const _KV({required this.label, required this.value, this.color});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final effectiveColor = color ?? theme.colorScheme.surfaceContainerHighest;
    
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          color: effectiveColor.withOpacity(isDark ? 0.15 : 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: effectiveColor.withOpacity(isDark ? 0.3 : 0.2),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: theme.colorScheme.onSurface)),
            Text(label,
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

class _OverviewTab extends ConsumerWidget {
  const _OverviewTab({required this.parcelId});
  final String parcelId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final parcel = ref.watch(parcelByIdProvider(parcelId));
    if (parcel == null) return const SizedBox.shrink();

    final ndvi = ref.watch(ndviProvider(parcelId)).valueOrNull;
    final alerts = ndvi?.alerts;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Ligne 1: Santé & Rendement (Bento Grid)
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 3,
                child: _BentoBox(
                  title: 'Vigueur (NDVI)',
                  icon: Icons.star_rounded,
                  iconColor: Colors.amber,
                  child: ref.watch(ndviProvider(parcelId)).when(
                    data: (ndvi) => Column(
                      children: [
                        const SizedBox(height: 8),
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox(
                              height: 80,
                              width: 80,
                              child: CircularProgressIndicator(
                                value: ndvi.value,
                                strokeWidth: 8,
                                backgroundColor: AppColors.healthFor(ndvi.value).withOpacity(0.1),
                                color: AppColors.healthFor(ndvi.value),
                              ),
                            ),
                            Text(
                              Fmt.percent(ndvi.value),
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.sync_rounded, color: AppColors.textMutedOf(context), size: 12),
                            const SizedBox(width: 4),
                            Text(
                              Fmt.relative(ndvi.fetchedAt, AppLocalizations.of(context)),
                              style: TextStyle(fontSize: 10, color: AppColors.textMutedOf(context)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: TextButton.icon(
                            onPressed: () => _showPremiumDialog(context, ref, parcelId),
                            icon: const Icon(Icons.satellite_alt_rounded, size: 14),
                            label: const Text('DEMANDER NDVI', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800)),
                            style: TextButton.styleFrom(
                              backgroundColor: AppColors.primary.withOpacity(0.1),
                              foregroundColor: AppColors.primary,
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, s) => Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.satellite_alt_rounded, size: 24, color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.5)),
                        const SizedBox(height: 8),
                        const Text(
                          'Données indisponibles',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: () => _showPremiumDialog(context, ref, parcelId),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            textStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                          child: const Text('DEMANDER NDVI'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: _BentoBox(
                  title: 'Potentiel',
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 12),
                      Text(
                        parcel.estimatedYield.toStringAsFixed(1),
                        style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: AppColors.primary),
                      ),
                      const Text('T/HA', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
                      const SizedBox(height: 16),
                      Text('Stable', style: TextStyle(fontSize: 11, color: AppColors.textSecondaryOf(context))),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Ligne 2: Cycle de Culture
        _LifecycleBox(parcel: parcel),

        // Indices avancés — NDMI, NDRE, tendance (visibles uniquement si données disponibles)
        if (ndvi != null) ...[
          const SizedBox(height: 12),
          _SatelliteIndicesBox(ndvi: ndvi),
        ],

        if (ndvi?.thumbnailUrl != null && ndvi!.thumbnailUrl!.isNotEmpty) ...[
          const SizedBox(height: 12),
          _BentoBox(
            title: 'Capture Satellite (GEE)',
            icon: Icons.satellite_rounded,
            iconColor: AppColors.primary,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                ndvi.thumbnailUrl!,
                height: 160,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, _, __) => Container(
                  height: 160,
                  color: Colors.grey.shade900.withOpacity(0.2),
                  alignment: Alignment.center,
                  child: const Icon(Icons.image_not_supported_rounded, color: Colors.grey),
                ),
              ),
            ),
          ),
        ],

        if (ndvi != null && alerts != null && alerts.isNotEmpty) ...[
          const SizedBox(height: 12),
          _BentoBox(
            title: 'Alertes Satellites',
            icon: Icons.warning_amber_rounded,
            iconColor: Colors.redAccent,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: alerts.map((alert) {
                final isHigh = alert.severity == 'HIGH';
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isHigh ? Colors.red.withOpacity(0.05) : Colors.orange.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isHigh ? Colors.red.withOpacity(0.2) : Colors.orange.withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        isHigh ? Icons.error_outline_rounded : Icons.warning_amber_rounded,
                        color: isHigh ? Colors.red : Colors.orange,
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              alert.message,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              Fmt.relative(alert.createdAt, AppLocalizations.of(context)),
                              style: TextStyle(
                                fontSize: 10,
                                color: AppColors.textMutedOf(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
        const SizedBox(height: 12),

        _BentoBox(
          title: 'Conseils Experts ISRA',
          icon: Icons.auto_awesome_rounded,
          iconColor: Colors.amber,
          child: const Text(
            'L\'humidité résiduelle est idéale pour un apport de fertilisant. Privilégiez un épandage en fin de journée.',
            style: TextStyle(height: 1.5, fontSize: 14),
          ),
        ),
        const SizedBox(height: 16),
        GlassCard(
          onTap: () => _sharePassport(parcel.id),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.qr_code_scanner_rounded, color: AppColors.primary),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Passeport de Traçabilité', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    Text('Partager le lien public vérifié', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ),
              const Icon(Icons.share_rounded, size: 20, color: AppColors.primary),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _AgronomicContextCard(parcel: parcel),
      ],
    );
  }

  void _showPremiumDialog(BuildContext context, WidgetRef ref, String parcelId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.satellite_alt_rounded, color: AppColors.primary),
            SizedBox(width: 12),
            Text('Analyse Satellite'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'La demande de mise à jour NDVI en temps réel est un service premium.',
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, size: 16, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Coût : 1 crédit agronomique\n(Vérification de connexion requise)',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary.withOpacity(0.9)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.push(Routes.wallet);
            },
            child: const Text('RECHARGER'),
          ),
          const Spacer(),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ANNULER'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final creditService = ref.read(creditServiceProvider.notifier);

              if (creditService.credits <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Crédits insuffisants. Veuillez recharger votre compte.')),
                );
                return;
              }

              // Tentative d'utilisation de crédit
              final success = await creditService.useCredits(1);
              if (!context.mounted) return;
              if (success) {
                try {
                  await ref.read(ndviServiceProvider).fetch(parcelId, force: true);
                  ref.invalidate(ndviProvider(parcelId));
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Mise à jour réussie (-1 crédit)'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                } catch (e) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Erreur : $e'),
                      backgroundColor: AppColors.danger,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('ACTUALISER'),
          ),
        ],
      ),
    );
  }

  void _sharePassport(String id) {
    MessengerUtils.showSuccess('Passeport numérique généré et copié !');
  }
}
class _BentoBox extends StatelessWidget {
  const _BentoBox({
    required this.title,
    required this.child,
    this.icon,
    this.iconColor,
    this.action,
  });

  final String title;
  final Widget child;
  final IconData? icon;
  final Color? iconColor;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return GlassCard(
      padding: const EdgeInsets.all(16),
      color: isDark ? AppColors.darkSurfaceAlt : null, // Surface plus visible en sombre
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 16, color: iconColor),
                const SizedBox(width: 6),
              ],
              Expanded(
                child: Text(
                  title.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                    color: isDark ? Colors.white70 : Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.7),
                  ),
                ),
              ),
              if (action != null) action!,
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

/// Carte "Cycle de Vie" : stade BBCH actuel, progression, dates clés.
/// Calcule dynamiquement à partir de [Parcel.semisDate] et du catalogue
/// [CropsCatalog] / [BbchCatalog]. Affiche un fallback quand `semisDate`
/// est manquant ou la culture inconnue.
// ---------------------------------------------------------------------------
// Satellite indices bento — NDMI, NDRE, SAVI, trend, health, cloud cover
// ---------------------------------------------------------------------------
class _SatelliteIndicesBox extends StatelessWidget {
  const _SatelliteIndicesBox({required this.ndvi});
  final NdviSnapshot ndvi;

  @override
  Widget build(BuildContext context) {
    return _BentoBox(
      title: 'Indices Satellite Sentinel-2',
      icon: Icons.analytics_rounded,
      iconColor: AppColors.primary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          // Trend + Health badge row
          Row(
            children: [
              _TrendBadge(trend: ndvi.trend),
              const SizedBox(width: 8),
              _HealthBadge(health: ndvi.health),
              if (ndvi.isCloudObstructed) ...[
                const SizedBox(width: 8),
                _CloudBadge(coverage: ndvi.cloudCoverage),
              ],
            ],
          ),
          const SizedBox(height: 12),
          // Index grid
          Row(
            children: [
              if (ndvi.ndmi != null)
                Expanded(child: _IndexTile(
                  label: 'NDMI',
                  value: ndvi.ndmi!,
                  description: 'Stress Hydrique',
                  icon: Icons.water_drop_rounded,
                  color: ndvi.hasWaterStress ? Colors.red : Colors.blue,
                  warning: ndvi.hasWaterStress ? 'Irrigation recommandée' : null,
                )),
              if (ndvi.ndmi != null && ndvi.ndre != null) const SizedBox(width: 8),
              if (ndvi.ndre != null)
                Expanded(child: _IndexTile(
                  label: 'NDRE',
                  value: ndvi.ndre!,
                  description: 'Stress Azoté',
                  icon: Icons.science_rounded,
                  color: ndvi.hasNitrogenStress ? Colors.orange : Colors.green,
                  warning: ndvi.hasNitrogenStress ? 'Analyse foliaire conseillée' : null,
                )),
            ],
          ),
          if (ndvi.savi != null || ndvi.evi2 != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                if (ndvi.savi != null)
                  Expanded(child: _IndexTile(
                    label: 'SAVI',
                    value: ndvi.savi!,
                    description: 'Sol Ajusté',
                    icon: Icons.terrain_rounded,
                    color: Colors.brown,
                  )),
                if (ndvi.savi != null && ndvi.evi2 != null) const SizedBox(width: 8),
                if (ndvi.evi2 != null)
                  Expanded(child: _IndexTile(
                    label: 'EVI2',
                    value: ndvi.evi2!,
                    description: 'Végétation Dense',
                    icon: Icons.forest_rounded,
                    color: Colors.green.shade700,
                  )),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _IndexTile extends StatelessWidget {
  const _IndexTile({
    required this.label,
    required this.value,
    required this.description,
    required this.icon,
    required this.color,
    this.warning,
  });
  final String label;
  final double value;
  final String description;
  final IconData icon;
  final Color color;
  final String? warning;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: color, letterSpacing: 0.5)),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value.toStringAsFixed(3),
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: color),
          ),
          Text(description, style: TextStyle(fontSize: 10, color: AppColors.textMutedOf(context))),
          if (warning != null) ...[
            const SizedBox(height: 4),
            Text(warning!, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.redAccent)),
          ],
        ],
      ),
    );
  }
}

class _TrendBadge extends StatelessWidget {
  const _TrendBadge({required this.trend});
  final String trend;

  @override
  Widget build(BuildContext context) {
    final (icon, color, label) = switch (trend) {
      'UP'     => (Icons.trending_up_rounded,   Colors.green,  'Hausse'),
      'DOWN'   => (Icons.trending_down_rounded, Colors.red,    'Déclin'),
      'STABLE' => (Icons.trending_flat_rounded, Colors.blue,   'Stable'),
      _        => (Icons.help_outline_rounded,  Colors.grey,   'Inconnu'),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }
}

class _HealthBadge extends StatelessWidget {
  const _HealthBadge({required this.health});
  final String health;

  @override
  Widget build(BuildContext context) {
    final (color, label) = switch (health) {
      'EXCELLENT' => (Colors.green.shade700, 'Excellent'),
      'GOOD'      => (Colors.lightGreen,     'Bonne'),
      'MODERATE'  => (Colors.orange,         'Moyenne'),
      _           => (Colors.red,            'Faible'),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color)),
    );
  }
}

class _CloudBadge extends StatelessWidget {
  const _CloudBadge({required this.coverage});
  final double coverage;

  @override
  Widget build(BuildContext context) {
    final pct = (coverage * 100).toStringAsFixed(0);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_rounded, size: 12, color: Colors.grey),
          const SizedBox(width: 4),
          Text('$pct% nuages', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.grey)),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _LifecycleBox extends StatelessWidget {
  const _LifecycleBox({required this.parcel});
  final Parcel parcel;

  @override
  Widget build(BuildContext context) {
    final snap = PhenologyService.snapshot(parcel);
    return _BentoBox(
      title: 'Cycle de Vie',
      child: snap == null ? _missing(context) : _content(context, snap),
    );
  }

  Widget _missing(BuildContext context) {
    final reason = parcel.semisDate == null
        ? 'Renseignez la date de semis pour calculer la progression.'
        : 'Culture non reconnue par le catalogue.';
    return Text(
      reason,
      style: TextStyle(
        fontSize: 13,
        color: AppColors.textSecondaryOf(context),
      ),
    );
  }

  Widget _content(BuildContext context, PhenologySnapshot s) {
    final stageLabel = s.currentStage?.label(context) ?? parcel.growthStage;
    final overdue = s.isOverdue;
    final remainingLabel = overdue
        ? 'En retard de ${-s.daysRemaining} j'
        : s.daysRemaining <= 0
            ? 'Récolte prévue'
            : 'Reste ${s.daysRemaining} j';
    final remainingColor =
        overdue ? AppColors.warning : AppColors.textSecondaryOf(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                stageLabel,
                style: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 16),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              remainingLabel,
              style: TextStyle(
                fontSize: 12,
                fontWeight: overdue ? FontWeight.w700 : FontWeight.w500,
                color: remainingColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Cycle ${s.cycleDaysMin}-${s.cycleDaysMax} j · J+${s.daysAfterSowing}',
          style: TextStyle(
              fontSize: 11, color: AppColors.textMutedOf(context)),
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: s.progress,
            minHeight: 8,
            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
            color: overdue ? AppColors.warning : AppColors.primary,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Semis ${Fmt.date(s.semisDate)}',
              style: TextStyle(
                  fontSize: 10,
                  color: AppColors.textSecondaryOf(context)),
            ),
            Text(
              '${(s.progress * 100).round()} %',
              style: const TextStyle(
                  fontSize: 10, fontWeight: FontWeight.bold),
            ),
            Text(
              'Récolte ${Fmt.date(s.estimatedHarvestDate)}',
              style: TextStyle(
                  fontSize: 10,
                  color: AppColors.textSecondaryOf(context)),
            ),
          ],
        ),
        if (overdue) ...[
          const SizedBox(height: 10),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded,
                    size: 14, color: AppColors.warning),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Parcelle hors cycle nominal — vérifier la récolte.',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.warning,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// Carte "Contexte agronomique" : variété, date de semis, type de sol,
/// culture précédente. Masquée si aucune de ces informations n'est saisie.
class _AgronomicContextCard extends StatelessWidget {
  const _AgronomicContextCard({required this.parcel});
  // Use dynamic to avoid adding another import — parcel_by_id returns Parcel.
  final dynamic parcel;

  @override
  Widget build(BuildContext context) {
    final String? variety = parcel.variety;
    final DateTime? semis = parcel.semisDate;
    final String? soilId = parcel.soilType;
    final String? previousCrop = parcel.previousCrop;

    final rows = <_ContextRow>[];
    if (variety != null && variety.isNotEmpty) {
      rows.add(_ContextRow(
          icon: Icons.spa_rounded, label: 'Variété', value: variety));
    }
    if (semis != null) {
      final das = DateTime.now().difference(semis).inDays;
      rows.add(_ContextRow(
        icon: Icons.event_rounded,
        label: 'Semis',
        value: '${Fmt.date(semis)} · J+$das',
      ));
    }
    if (soilId != null) {
      final soil = SoilTypes.byId(soilId);
      if (soil != null) {
        rows.add(_ContextRow(
          icon: Icons.terrain_rounded,
          label: 'Type de sol',
          value: soil.label(context),
          detail: soil.description(context),
        ));
      }
    }
    if (previousCrop != null && previousCrop.isNotEmpty) {
      final label = switch (previousCrop) {
        '__fallow__' => 'Jachère',
        '__none__' => 'Aucune (nouveau champ)',
        _ => previousCrop,
      };
      rows.add(_ContextRow(
          icon: Icons.history_rounded,
          label: 'Précédent cultural',
          value: label));
    }

    if (rows.isEmpty) return const SizedBox.shrink();

    return GlassCard(
      color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkSurfaceAlt : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Contexte agronomique',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) const Divider(height: 18),
            rows[i],
          ],
        ],
      ),
    );
  }
}

class _ContextRow extends StatelessWidget {
  const _ContextRow({
    required this.icon,
    required this.label,
    required this.value,
    this.detail,
  });
  final IconData icon;
  final String label;
  final String value;
  final String? detail;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.10),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.primary, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600)),
              Text(value,
                  style: const TextStyle(fontWeight: FontWeight.w700)),
              if (detail != null)
                Text(detail!,
                    style: TextStyle(
                        fontSize: 12, color: AppColors.textSecondaryOf(context))),
            ],
          ),
        ),
      ],
    );
  }
}

/// Courbe santé de la parcelle sur 30 jours, dérivée des observations en Hive.
/// Santé = 1 - sévérité (moyenne journalière). Si une journée n'a pas
/// d'observation, on interpole linéairement entre les points connus.
class _ParcelHealthChart extends StatelessWidget {
  const _ParcelHealthChart({required this.parcelId});
  final String parcelId;

  @override
  Widget build(BuildContext context) {
    final series = _buildSeries();
    final points = series.spots;
    if (points.isEmpty) {
      return GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Évolution de la santé',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(
              'Aucune visite encore — enregistrez une visite pour voir la tendance.',
              style: TextStyle(color: AppColors.textSecondaryOf(context), fontSize: 13),
            ),
          ],
        ),
      );
    }

    final last = points.last.y;
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Évolution de la santé · 30 jours',
                    style: Theme.of(context).textTheme.titleMedium),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.healthFor(last / 100).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${last.round()}%',
                  style: TextStyle(
                    color: AppColors.healthFor(last / 100),
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 160,
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: 100,
                minX: 0,
                maxX: 29,
                lineTouchData: const LineTouchData(enabled: false),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 25,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: AppColors.dividerOf(context).withOpacity(0.4),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      interval: 25,
                      getTitlesWidget: (value, _) => Text(
                        '${value.toInt()}%',
                        style: TextStyle(
                            fontSize: 10, color: AppColors.textMutedOf(context)),
                      ),
                    ),
                  ),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 7,
                      getTitlesWidget: (value, _) {
                        final days = 29 - value.toInt();
                        if (days == 0) {
                          return Text('Aujourd\'hui',
                              style: TextStyle(
                                  fontSize: 9, color: AppColors.textMutedOf(context)));
                        }
                        return Text('J-$days',
                            style: TextStyle(
                                fontSize: 10, color: AppColors.textMutedOf(context)));
                      },
                    ),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: points,
                    isCurved: true,
                    curveSmoothness: 0.3,
                    barWidth: 3,
                    color: AppColors.healthFor(last / 100),
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, _, __, ___) {
                        return FlDotCirclePainter(
                          radius: 3,
                          color: AppColors.healthFor(spot.y / 100),
                          strokeWidth: 0,
                        );
                      },
                      checkToShowDot: (spot, _) {
                        // Montre uniquement les points qui correspondent à
                        // une visite réelle (pas les interpolations).
                        return series.realDays.contains(spot.x.toInt());
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppColors.healthFor(last / 100).withOpacity(0.15),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${series.realDays.length} observation${series.realDays.length > 1 ? 's' : ''} · tendance calculée sur 30 jours',
            style: TextStyle(
              fontSize: 11,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  _HealthSeries _buildSeries() {
    final box = Hive.box(AppConstants.boxObservations);
    final now = DateTime.now();
    // dayIndex (0 = J-29, 29 = aujourd'hui) -> healthScores[]
    final byDay = <int, List<double>>{};
    for (final raw in box.values) {
      if (raw is! Map) continue;
      if (raw['parcelId'] != parcelId) continue;
      final at = DateTime.tryParse(raw['at']?.toString() ?? '');
      if (at == null) continue;
      final diff = now.difference(at).inDays;
      if (diff < 0 || diff > 29) continue;
      final severity = (raw['severity'] as num?)?.toDouble() ?? 0.5;
      final clamped = severity.clamp(0.0, 1.0);
      final health = (1 - clamped) * 100;
      byDay.putIfAbsent(29 - diff, () => <double>[]).add(health);
    }
    if (byDay.isEmpty) return const _HealthSeries(spots: [], realDays: {});

    // Points réels (moyenne par jour).
    final real = <int, double>{};
    byDay.forEach((k, v) {
      real[k] = v.reduce((a, b) => a + b) / v.length;
    });

    // Interpolation linéaire pour combler les trous.
    final sortedKeys = real.keys.toList()..sort();
    final firstX = sortedKeys.first;
    final lastX = sortedKeys.last;
    final spots = <FlSpot>[];
    for (var x = firstX; x <= lastX; x++) {
      if (real.containsKey(x)) {
        spots.add(FlSpot(x.toDouble(), real[x]!));
        continue;
      }
      final left = sortedKeys.lastWhere((k) => k < x, orElse: () => -1);
      final right = sortedKeys.firstWhere((k) => k > x, orElse: () => -1);
      if (left < 0 || right < 0) continue;
      final ratio = (x - left) / (right - left);
      final y = real[left]! + (real[right]! - real[left]!) * ratio;
      spots.add(FlSpot(x.toDouble(), y));
    }
    return _HealthSeries(spots: spots, realDays: real.keys.toSet());
  }
}

class _HealthSeries {
  final List<FlSpot> spots;
  final Set<int> realDays;
  const _HealthSeries({required this.spots, required this.realDays});
}

class _NearbyTab extends StatelessWidget {
  const _NearbyTab({required this.center});
  final LatLng center;

  @override
  Widget build(BuildContext context) {
    final service = NearbyPlacesService();
    final places = service.getNearbyPlaces(center)
      ..sort((a, b) => a.distanceKm.compareTo(b.distanceKm));

    final order = [
      PlaceCategory.village,
      PlaceCategory.hospital,
      PlaceCategory.market,
      PlaceCategory.inputSupplier,
      PlaceCategory.equipmentSupplier,
      PlaceCategory.waterSource,
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Points d\'intérêt autour de la parcelle',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 4),
        Text(
          'Distance estimée à vol d\'oiseau depuis le centre de la parcelle.',
          style: TextStyle(color: AppColors.textSecondaryOf(context), fontSize: 12),
        ),
        const SizedBox(height: 12),
        for (final cat in order)
          ...places
              .where((p) => p.category == cat)
              .map((p) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _NearbyTile(place: p),
                  )),
      ],
    );
  }
}

class _NearbyTile extends StatelessWidget {
  const _NearbyTile({required this.place});
  final NearbyPlace place;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: place.color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(place.icon, color: place.color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  place.categoryLabel,
                  style: TextStyle(
                    color: AppColors.textMutedOf(context),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  place.name,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${place.distanceKm.toStringAsFixed(1)} km',
                style: TextStyle(
                  color: place.color,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                'à vol d\'oiseau',
                style: TextStyle(color: AppColors.textMutedOf(context), fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Todo extends StatelessWidget {
  const _Todo(this.label, {required this.done});
  final String label;
  final bool done;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(
            done ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
            color: done ? AppColors.success : AppColors.textMutedOf(context),
            size: 20,
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: done
                  ? Theme.of(context).colorScheme.onSurfaceVariant
                  : Theme.of(context).colorScheme.onSurface,
              decoration: done ? TextDecoration.lineThrough : null,
            ),
          ),
        ],
      ),
    );
  }
}



class _PhotosTab extends StatelessWidget {
  const _PhotosTab({required this.parcelId});
  final String parcelId;

  @override
  Widget build(BuildContext context) {
    final photos = _loadPhotos();
    if (photos.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.photo_library_outlined,
                  color: AppColors.textMutedOf(context).withOpacity(0.6), size: 48),
              const SizedBox(height: 12),
              const Text('Aucune photo pour cette parcelle',
                  style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(
                'Les photos prises lors d\'une visite apparaîtront ici.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondaryOf(context), fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
      ),
      itemCount: photos.length,
      itemBuilder: (_, i) => _ParcelPhotoTile(entry: photos[i]),
    );
  }

  List<_ParcelPhoto> _loadPhotos() {
    final box = Hive.box(AppConstants.boxObservations);
    final result = <_ParcelPhoto>[];
    for (final raw in box.values) {
      if (raw is! Map) continue;
      if (raw['parcelId'] != parcelId) continue;
      final at = DateTime.tryParse(raw['at']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0);
      final paths = raw['photoPaths'];
      if (paths is! List) continue;
      for (final p in paths) {
        final path = p?.toString();
        if (path == null || path.isEmpty) continue;
        result.add(_ParcelPhoto(path: path, takenAt: at));
      }
    }
    result.sort((a, b) => b.takenAt.compareTo(a.takenAt));
    return result;
  }
}

class _ParcelPhoto {
  final String path;
  final DateTime takenAt;
  const _ParcelPhoto({required this.path, required this.takenAt});
}

class _ParcelPhotoTile extends StatelessWidget {
  const _ParcelPhotoTile({required this.entry});
  final _ParcelPhoto entry;

  @override
  Widget build(BuildContext context) {
    final file = File(entry.path);
    return GestureDetector(
      onTap: () => _openViewer(context),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          fit: StackFit.expand,
          children: [
            kIsWeb
                ? Image.network(
                    entry.path,
                    fit: BoxFit.cover,
                    errorBuilder: (ctx, __, ___) => _buildError(ctx),
                  )
                : Image.file(
                    file,
                    fit: BoxFit.cover,
                    errorBuilder: (ctx, __, ___) => _buildError(ctx),
                  ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 6, vertical: 4),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.55),
                    ],
                  ),
                ),
                child: Text(
                  Fmt.relative(entry.takenAt, AppLocalizations.of(context)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError(BuildContext context) {
    return Container(
      color: AppColors.surfaceAltOf(context),
      child: Icon(Icons.broken_image_outlined,
          color: AppColors.textMutedOf(context), size: 28),
    );
  }

  void _openViewer(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                child: kIsWeb 
                  ? Image.network(entry.path, fit: BoxFit.contain)
                  : Image.file(File(entry.path), fit: BoxFit.contain),
              ),
            ),
            Positioned(
              top: 12,
              right: 12,
              child: IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            Positioned(
              left: 16,
              bottom: 24,
              child: Text(
                Fmt.date(entry.takenAt),
                style: const TextStyle(
                    color: Colors.white70, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AppBarBtn extends StatelessWidget {
  const _AppBarBtn({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(10)),
      child: IconButton(icon: Icon(icon, color: Colors.white, size: 20), onPressed: onTap),
    );
  }
}

class _MapIconBtn extends StatelessWidget {
  const _MapIconBtn({required this.icon, required this.onTap, this.color});
  final IconData icon;
  final VoidCallback onTap;
  final Color? color;
  @override
  Widget build(BuildContext context) {
    return Material(
      color: (color ?? Colors.black54).withOpacity(0.6),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Padding(padding: const EdgeInsets.all(8), child: Icon(icon, color: Colors.white, size: 20)),
      ),
    );
  }
}

class _MiniKV extends StatelessWidget {
  const _MiniKV({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.5, color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.7))),
        Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
      ],
    );
  }
}

class _ContactBtn extends StatelessWidget {
  const _ContactBtn({
    required this.icon,
    required this.onTap,
    required this.color,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback onTap;
  final Color color;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withOpacity(0.12),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: IconButton(
        icon: Icon(icon, color: color, size: 22),
        onPressed: onTap,
        tooltip: tooltip,
        constraints: const BoxConstraints(minWidth: 46, minHeight: 46),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.onTap, this.icon, required this.label, this.active = false});
  final VoidCallback onTap;
  final IconData? icon;
  final String label;
  final bool active;
  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: icon != null ? Icon(icon, size: 18) : const SizedBox.shrink(),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: active ? AppColors.accent : AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
class _DetailsTab extends StatelessWidget {
  const _DetailsTab({required this.parcel});
  final dynamic parcel;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // --- SECTION TECHNIQUE ---
        _DetailSection(
          title: 'Technique de Culture',
          icon: Icons.settings_suggest_rounded,
          color: Colors.teal,
          children: [
            _DetailRow(
              icon: Icons.spa_rounded,
              label: 'Variété',
              value: parcel.variety ?? 'Non renseignée',
            ),
            if (parcel.semisDate != null)
              _DetailRow(
                icon: Icons.event_available_rounded,
                label: 'Date de semis',
                value: '${Fmt.date(parcel.semisDate!)} (J+${DateTime.now().difference(parcel.semisDate!).inDays})',
              ),
            _DetailRow(
              icon: Icons.water_drop_rounded,
              label: 'Mode d\'irrigation',
              value: parcel.irrigation,
            ),
          ],
        ),
        const SizedBox(height: 16),

        // --- SECTION SOL ---
        _DetailSection(
          title: 'Sol & Rotation',
          icon: Icons.terrain_rounded,
          color: Colors.brown,
          children: [
            if (parcel.soilType != null)
              _DetailRow(
                icon: Icons.layers_rounded,
                label: 'Type de sol',
                value: SoilTypes.byId(parcel.soilType!)?.label(context) ?? parcel.soilType!,
                subValue: SoilTypes.byId(parcel.soilType!)?.description(context),
              ),
            _DetailRow(
              icon: Icons.history_rounded,
              label: 'Précédent cultural',
              value: _formatPreviousCrop(parcel.previousCrop),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // --- SECTION LOCALISATION ---
        _DetailSection(
          title: 'Localisation & Admin',
          icon: Icons.map_rounded,
          color: Colors.blue,
          children: [
            _DetailRow(
              icon: Icons.public_rounded,
              label: 'Région',
              value: parcel.region?.toUpperCase() ?? 'Non renseignée',
            ),
            _DetailRow(
              icon: Icons.location_city_rounded,
              label: 'Village / Localité',
              value: parcel.village.isNotEmpty ? parcel.village : 'Non renseigné',
            ),
            _DetailRow(
              icon: Icons.person_outline_rounded,
              label: 'Propriétaire déclaré',
              value: parcel.owner,
            ),
          ],
        ),
        const SizedBox(height: 16),

        // --- SECTION CONTACT ---
        if (parcel.phone != null && parcel.phone!.trim().isNotEmpty)
          _DetailSection(
            title: 'Contact Agriculteur',
            icon: Icons.contact_phone_rounded,
            color: AppColors.primary,
            children: [
              _DetailRow(
                icon: Icons.phone_android_rounded,
                label: 'Numéro de téléphone',
                value: parcel.phone!,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _launchPhone(parcel.phone!),
                      icon: const Icon(Icons.call_rounded),
                      label: const Text('Appeler'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _launchWhatsApp(parcel.phone!),
                      icon: const Icon(Icons.chat_bubble_outline_rounded),
                      label: const Text('WhatsApp'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF25D366),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
      ],
    );
  }

  Future<void> _launchPhone(String phone) async {
    final uri = Uri.parse('tel:${phone.replaceAll(RegExp(r'[^0-9+]'), '')}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _launchWhatsApp(String phone) async {
    String clean = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (clean.length == 9 && (clean.startsWith('7') || clean.startsWith('3'))) {
      clean = '221$clean';
    }
    // Format E.164 without + for WhatsApp URL
    final uri = Uri.parse('https://api.whatsapp.com/send/?phone=$clean&text&type=phone_number&app_absent=0');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  String _formatPreviousCrop(String? val) {
    if (val == null || val.isEmpty) return 'Non renseigné';
    return switch (val) {
      '__fallow__' => 'Jachère',
      '__none__' => 'Nouveau champ',
      _ => val,
    };
  }
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({
    required this.title,
    required this.icon,
    required this.color,
    required this.children,
  });

  final String title;
  final IconData icon;
  final Color color;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GlassCard(
      padding: const EdgeInsets.all(16),
      color: isDark ? AppColors.darkSurfaceAlt : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(title, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 14)),
            ],
          ),
          const Divider(height: 24),
          ...children,
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.subValue,
  });

  final IconData icon;
  final String label;
  final String value;
  final String? subValue;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: colorScheme.primary.withOpacity(0.7)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, 
                     style: TextStyle(
                       fontSize: 11, 
                       color: colorScheme.onSurfaceVariant,
                       fontWeight: FontWeight.w600,
                       letterSpacing: 0.5,
                     )),
                const SizedBox(height: 1),
                Text(value, 
                     style: TextStyle(
                       fontSize: 15, 
                       fontWeight: FontWeight.w700, 
                       color: colorScheme.onSurface,
                     )),
                if (subValue != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(subValue!, 
                         style: TextStyle(
                           fontSize: 12, 
                           color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                           fontStyle: FontStyle.italic,
                         )),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _VisitsTab extends ConsumerWidget {
  const _VisitsTab({required this.parcelId});
  final String parcelId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Récupération des visites réelles depuis Hive
    final box = Hive.box(AppConstants.boxObservations);
    final allData = box.values.toList();
    
    final parcelVisits = allData
        .where((v) => v['parcelId'] == parcelId)
        .map((v) => _VisitData(
              id: v['id'] as String,
              date: DateTime.parse(v['at'] as String),
              type: v['stage'] as String? ?? 'Visite',
              summary: v['note'] as String? ?? '',
              healthScore: 1.0 - (v['severity'] as double? ?? 0.0),
              symptoms: (v['symptoms'] as List?)?.cast<String>() ?? [],
            ))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    if (parcelVisits.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history_rounded, size: 64, color: Theme.of(context).colorScheme.outlineVariant),
            const SizedBox(height: 16),
            Text('Aucune visite enregistrée', 
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
            const SizedBox(height: 8),
            Text('Réalisez votre première observation terrain.', 
              style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.6))),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: parcelVisits.length,
      itemBuilder: (context, index) {
        final visit = parcelVisits[index];
        return _VisitTimelineItem(
          visit: visit,
          isLast: index == parcelVisits.length - 1,
          onTap: () => context.push('${Routes.visitDetails}/${visit.id}'),
        );
      },
    );
  }
}

class _VisitData {
  final String id;
  final DateTime date;
  final String type;
  final String summary;
  final double healthScore;
  final List<String> symptoms;
  
  _VisitData({
    required this.id,
    required this.date, 
    required this.type, 
    required this.summary, 
    required this.healthScore,
    this.symptoms = const [],
  });
}

class _VisitTimelineItem extends StatelessWidget {
  const _VisitTimelineItem({required this.visit, required this.isLast, required this.onTap});
  final _VisitData visit;
  final bool isLast;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        children: [
          // Colonne Timeline
          Column(
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 4)],
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(width: 2, color: AppColors.dividerOf(context)),
                ),
            ],
          ),
          const SizedBox(width: 16),
          // Contenu de la visite
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: GlassCard(
                padding: const EdgeInsets.all(16),
                onTap: onTap,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(Fmt.date(visit.date), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.primary)),
                        HealthBadge(score: visit.healthScore),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(visit.type, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                    const SizedBox(height: 6),
                    Text(
                      visit.summary,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13, 
                        color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.9), 
                        height: 1.4,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Row(
                      children: [
                        Text('VOIR LE RAPPORT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.5, color: AppColors.primary)),
                        SizedBox(width: 4),
                        Icon(Icons.arrow_forward_ios_rounded, size: 10, color: AppColors.primary),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
