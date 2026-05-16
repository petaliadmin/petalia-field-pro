import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/geo_utils.dart';
import '../../../routes/route_names.dart';
import '../../dashboard/presentation/tour_provider.dart';

import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../theme/app_colors.dart';
import '../../parcels/domain/parcel.dart';
import '../../parcels/presentation/parcels_providers.dart';
import '../../../core/services/location_service.dart';

class RoutePlannerScreen extends ConsumerStatefulWidget {
  const RoutePlannerScreen({super.key, this.targetParcelId});
  final String? targetParcelId;

  @override
  ConsumerState<RoutePlannerScreen> createState() => _RoutePlannerScreenState();
}

class _RoutePlannerScreenState extends ConsumerState<RoutePlannerScreen> {
  final _selected = <String>{};
  List<int>? _optimizedOrder;
  bool _showMap = false;
  LatLng? _userPos;

  @override
  void initState() {
    super.initState();
    if (widget.targetParcelId != null) {
      _selected.add(widget.targetParcelId!);
      // We'll trigger optimization once we have the user position
    }
    _loadUserPos();
  }

  Future<void> _loadUserPos() async {
    final pos = await ref.read(locationServiceProvider).current();
    if (mounted) {
      setState(() => _userPos = pos);
      if (widget.targetParcelId != null) {
        _optimize();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final parcels = ref.watch(parcelsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Planificateur de tournée'),
        actions: [
          if (_selected.isNotEmpty && !_showMap)
            TextButton.icon(
              onPressed: _optimize,
              icon: const Icon(Icons.alt_route_rounded, size: 18),
              label: const Text('Optimiser'),
            ),
          if (_showMap)
            TextButton.icon(
              onPressed: () => setState(() {
                _showMap = false;
                _optimizedOrder = null;
              }),
              icon: const Icon(Icons.edit_rounded, size: 18),
              label: const Text('Modifier'),
            ),
        ],
      ),
      body: parcels.isEmpty
          ? const EmptyState(
              icon: Icons.alt_route_rounded,
              title: 'Aucune parcelle',
              message: 'Ajoutez d\'abord des parcelles pour planifier une tournée.',
            )
          : _showMap
              ? _RouteMapView(
                  parcels: _orderedParcels(parcels),
                  userPos: _userPos,
                )
              : _buildSelectionList(parcels),
    );
  }

  Widget _buildSelectionList(List<Parcel> parcels) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
          child: Row(
            children: [
              Text(
                '${_selected.length} / ${parcels.length} sélectionnée${_selected.length > 1 ? 's' : ''}',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: AppColors.textSecondaryOf(context)),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => setState(() {
                  if (_selected.length == parcels.length) {
                    _selected.clear();
                  } else {
                    _selected.addAll(parcels.map((p) => p.id));
                  }
                }),
                child: Text(
                    _selected.length == parcels.length
                        ? 'Tout désélectionner'
                        : 'Tout sélectionner',
                    style: const TextStyle(fontSize: 13)),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
            itemCount: parcels.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) {
              final p = parcels[i];
              final checked = _selected.contains(p.id);
              return GlassCard(
                onTap: () => setState(() {
                  checked ? _selected.remove(p.id) : _selected.add(p.id);
                }),
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      height: 32,
                      width: 32,
                      decoration: BoxDecoration(
                        color: checked
                            ? AppColors.primary
                            : AppColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: checked
                          ? const Icon(Icons.check_rounded,
                              color: Colors.white, size: 18)
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(p.name,
                              style: Theme.of(context).textTheme.titleSmall),
                          const SizedBox(height: 2),
                          Text(
                            '${p.village} — ${p.crop}',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: AppColors.textSecondaryOf(context)),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.healthFor(p.healthScore)
                            .withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${(p.healthScore * 100).round()}%',
                        style: TextStyle(
                          color: AppColors.healthFor(p.healthScore),
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _optimize() {
    final parcels = ref.read(parcelsProvider);
    final selectedParcels =
        parcels.where((p) => _selected.contains(p.id)).toList();
    if (selectedParcels.length < 2) {
      setState(() {
        _optimizedOrder = List.generate(selectedParcels.length, (i) => i);
        _showMap = true;
      });
      return;
    }
    final centroids =
        selectedParcels.map((p) => GeoUtils.centroid(p.boundary)).toList();
    final origin = _userPos ?? const LatLng(14.7889, -16.9260);
    final order =
        GeoUtils.nearestNeighborRoute(origin, centroids);
    setState(() {
      _optimizedOrder = order;
      _showMap = true;
    });
  }

  List<Parcel> _orderedParcels(List<Parcel> all) {
    final selectedParcels =
        all.where((p) => _selected.contains(p.id)).toList();
    if (_optimizedOrder == null) return selectedParcels;
    return [
      for (final i in _optimizedOrder!)
        if (i < selectedParcels.length) selectedParcels[i],
    ];
  }
}

// ---------------------------------------------------------------------------
class _RouteMapView extends StatelessWidget {
  const _RouteMapView({required this.parcels, this.userPos});
  final List<Parcel> parcels;
  final LatLng? userPos;

  @override
  Widget build(BuildContext context) {
    if (parcels.isEmpty) {
      return const EmptyState(
        icon: Icons.alt_route_rounded,
        title: 'Aucune parcelle sélectionnée',
        message: 'Retournez en arrière et sélectionnez des parcelles pour créer votre tournée.',
      );
    }

    final origin = userPos ?? const LatLng(14.7889, -16.9260);
    final centroids =
        parcels.map((p) => GeoUtils.centroid(p.boundary)).toList();
    final allPoints = centroids.toList()..insert(0, origin);
    final bounds = LatLngBounds.fromPoints(allPoints);

    // Total distance
    double totalKm = 0;
    LatLng cursor = origin;
    for (final c in centroids) {
      totalKm += GeoUtils.distanceKm(cursor, c);
      cursor = c;
    }

    return Stack(
      children: [
        FlutterMap(
          options: MapOptions(
            initialCameraFit: CameraFit.bounds(
              bounds: bounds,
              padding: const EdgeInsets.all(60),
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.petalia.fieldpro',
            ),
            // Route polyline
            PolylineLayer(
              polylines: [
                Polyline(
                  points: [origin, ...centroids],
                  strokeWidth: 3,
                  color: AppColors.primary,
                  pattern: const StrokePattern.dotted(),
                ),
              ],
            ),
            // Origin marker
            MarkerLayer(
              markers: [
                Marker(
                  point: origin,
                  width: 48,
                  height: 48,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: const [
                        BoxShadow(
                            color: AppColors.shadow,
                            blurRadius: 6,
                            offset: Offset(0, 2)),
                      ],
                    ),
                    child: const Icon(Icons.my_location_rounded,
                        color: Colors.white, size: 18),
                  ),
                ),
                // Parcel markers (numbered)
                for (int i = 0; i < centroids.length; i++)
                  Marker(
                    point: centroids[i],
                    width: 48,
                    height: 48,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: const [
                          BoxShadow(
                              color: AppColors.shadow,
                              blurRadius: 6,
                              offset: Offset(0, 2)),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${i + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),

        // Bottom summary card
        Positioned(
          left: 16,
          right: 16,
          bottom: 24,
          child: GlassCard(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    _SummaryChip(
                      icon: Icons.place_rounded,
                      label: '${parcels.length} arrêt${parcels.length > 1 ? 's' : ''}',
                    ),
                    const SizedBox(width: 12),
                    _SummaryChip(
                      icon: Icons.straighten_rounded,
                      label: '${totalKm.toStringAsFixed(1)} km',
                    ),
                    const SizedBox(width: 12),
                    _SummaryChip(
                      icon: Icons.access_time_rounded,
                      label: _estimateTime(parcels.length, totalKm),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                // Stop list
                for (int i = 0; i < parcels.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text('${i + 1}',
                              style: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12)),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(parcels[i].name,
                              style: const TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w500)),
                        ),
                        Text(parcels[i].village,
                            style: TextStyle(
                                color: AppColors.textMutedOf(context), fontSize: 14)),
                      ],
                    ),
                  ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: Consumer(
                    builder: (context, ref, _) => ElevatedButton.icon(
                      onPressed: () {
                        ref.read(tourProvider.notifier).start(parcels.map((p) => p.id).toList());
                        context.go(Routes.dashboard);
                      },
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: const Text('DÉMARRER LA TOURNÉE'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _estimateTime(int stops, double km) {
    // ~30 min per stop + driving at ~40 km/h
    final driveMin = (km / 40 * 60).round();
    final visitMin = stops * 30;
    final total = driveMin + visitMin;
    if (total < 60) return '~$total min';
    final h = total ~/ 60;
    final m = total % 60;
    return '~${h}h ${m > 0 ? '${m}m' : ''}';
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 6),
          Text(label,
              style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13)),
        ],
      ),
    );
  }
}
