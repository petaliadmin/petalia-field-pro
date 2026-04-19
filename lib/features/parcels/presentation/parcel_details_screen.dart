import 'dart:io';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/data/soil_types.dart';
import '../../../core/services/nearby_places_service.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/geo_utils.dart';
import '../../../routes/route_names.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/health_badge.dart';
import '../../../shared/widgets/primary_button.dart';
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

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 5, vsync: this);
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
      return Scaffold(
        appBar: AppBar(title: const Text('Détails de la parcelle')),
        body: EmptyState(
          icon: Icons.search_off_rounded,
          title: 'Parcelle introuvable',
          message: 'Cette parcelle a peut-être été supprimée ou n\'est pas encore synchronisée.',
          action: FilledButton.icon(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back_rounded),
            label: const Text('Retour'),
          ),
        ),
      );
    }
    final area = GeoUtils.polygonAreaHa(parcel.boundary);

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, inner) => [
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            stretch: true,
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            title: Text(parcel.name, style: const TextStyle(color: Colors.white)),
            actions: [
              IconButton(
                tooltip: 'Modifier la parcelle',
                onPressed: () =>
                    context.push(Routes.editParcel, extra: parcel),
                icon: const Icon(Icons.edit_rounded),
              ),
              IconButton(
                onPressed: () =>
                    context.push(Routes.reportPreview, extra: {'parcelId': parcel.id}),
                icon: const Icon(Icons.share_rounded),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  AbsorbPointer(
                    child: FlutterMap(
                      options: MapOptions(
                        initialCenter: GeoUtils.centroid(parcel.boundary),
                        initialZoom: 17,
                        interactionOptions: const InteractionOptions(
                          flags: InteractiveFlag.none,
                        ),
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
                          userAgentPackageName: 'com.petalia.fieldpro',
                        ),
                        PolygonLayer(
                          polygons: [
                            Polygon(
                              points: parcel.boundary,
                              color: AppColors.healthFor(parcel.healthScore)
                                  .withValues(alpha: 0.35),
                              borderColor:
                                  AppColors.healthFor(parcel.healthScore),
                              borderStrokeWidth: 3,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppColors.primary.withValues(alpha: 0.7),
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.4),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(parcel.owner,
                                  style: Theme.of(context).textTheme.titleMedium),
                              Text('${parcel.crop} · ${parcel.growthStage}',
                                  style: const TextStyle(
                                      color: AppColors.textSecondary)),
                            ],
                          ),
                        ),
                        HealthBadge(score: parcel.healthScore),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        _KV(label: 'Surface', value: Fmt.hectares(area)),
                        _KV(
                          label: 'Dernière visite',
                          value: Fmt.relative(parcel.lastVisit),
                        ),
                        _KV(
                          label: 'Rendement',
                          value: '${parcel.estimatedYield.toStringAsFixed(1)} t/ha',
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () =>
                                context.push(Routes.routePlanner),
                            icon: const Icon(Icons.navigation_rounded),
                            label: const Text('Itinéraire'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: PrimaryButton(
                            icon: Icons.camera_alt_rounded,
                            label: 'Observer',
                            onPressed: () => context
                                .push('${Routes.observation}/${parcel.id}'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            TabBar(
              controller: _tab,
              isScrollable: true,
              labelColor: AppColors.primary,
              indicatorColor: AppColors.primary,
              unselectedLabelColor: AppColors.textSecondary,
              tabs: const [
                Tab(text: 'Proximité'),
                Tab(text: 'Vue d\'ensemble'),
                Tab(text: 'Visites'),
                Tab(text: 'Photos'),
                Tab(text: 'Notes'),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tab,
                children: [
                  _NearbyTab(center: GeoUtils.centroid(parcel.boundary)),
                  _OverviewTab(parcelId: parcel.id),
                  const _VisitsTab(),
                  _PhotosTab(parcelId: parcel.id),
                  const _NotesTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _KV extends StatelessWidget {
  const _KV({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.secondary,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w700)),
            Text(label,
                style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
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
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _ParcelHealthChart(parcelId: parcelId),
        const SizedBox(height: 12),
        if (parcel != null) _AgronomicContextCard(parcel: parcel),
        if (parcel != null) const SizedBox(height: 12),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Résumé de santé',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 6),
              const Text(
                'La culture évolue normalement. Maintenez le rythme d\'irrigation actuel et réévaluez dans 4 à 5 jours.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Prochaines étapes',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 10),
              _Todo('Vérifier l\'humidité du sol', done: true),
              _Todo('Surveiller les nuisibles', done: true),
              _Todo('Planifier l\'apport d\'engrais', done: false),
            ],
          ),
        ),
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
          label: 'Sol',
          value: soil.labelFr,
          detail: soil.descriptionFr,
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
            color: AppColors.primary.withValues(alpha: 0.10),
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
                  style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w600)),
              Text(value,
                  style: const TextStyle(fontWeight: FontWeight.w700)),
              if (detail != null)
                Text(detail!,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary)),
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
            const Text(
              'Aucune observation encore — enregistrez une visite pour voir la tendance.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
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
                  color: AppColors.healthFor(last / 100).withValues(alpha: 0.15),
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
                    color: AppColors.divider.withValues(alpha: 0.4),
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
                        style: const TextStyle(
                            fontSize: 10, color: AppColors.textMuted),
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
                          return const Text('Aujourd\'hui',
                              style: TextStyle(
                                  fontSize: 9, color: AppColors.textMuted));
                        }
                        return Text('J-$days',
                            style: const TextStyle(
                                fontSize: 10, color: AppColors.textMuted));
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
                        // une observation réelle (pas les interpolations).
                        return series.realDays.contains(spot.x.toInt());
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppColors.healthFor(last / 100)
                          .withValues(alpha: 0.15),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${series.realDays.length} observation${series.realDays.length > 1 ? 's' : ''} · tendance calculée sur 30 jours',
            style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
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
        const Text(
          'Distance estimée à vol d\'oiseau depuis le centre de la parcelle.',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
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
              color: place.color.withValues(alpha: 0.15),
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
                  style: const TextStyle(
                    color: AppColors.textMuted,
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
              const Text(
                'à vol d\'oiseau',
                style: TextStyle(color: AppColors.textMuted, fontSize: 11),
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
            color: done ? AppColors.success : AppColors.textMuted,
            size: 20,
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: done ? AppColors.textSecondary : AppColors.textPrimary,
              decoration: done ? TextDecoration.lineThrough : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _VisitsTab extends StatelessWidget {
  const _VisitsTab();
  @override
  Widget build(BuildContext context) {
    final items = [
      ('Tournée de routine', DateTime.now().subtract(const Duration(days: 2)), 'Bon'),
      ('Suivi d\'irrigation', DateTime.now().subtract(const Duration(days: 8)), 'Moyen'),
      ('Évaluation initiale', DateTime.now().subtract(const Duration(days: 21)), 'Excellent'),
    ];
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        final it = items[i];
        return GlassCard(
          child: Row(
            children: [
              Container(
                width: 4,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(it.$1,
                        style: Theme.of(context).textTheme.titleMedium),
                    Text(Fmt.date(it.$2),
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 12)),
                  ],
                ),
              ),
              Text(
                it.$3,
                style: const TextStyle(
                    color: AppColors.primary, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        );
      },
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
                  color: AppColors.textMuted.withValues(alpha: 0.6), size: 48),
              const SizedBox(height: 12),
              const Text('Aucune photo pour cette parcelle',
                  style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              const Text(
                'Les photos prises lors d\'une visite apparaîtront ici.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
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
            Image.file(
              file,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: AppColors.secondary,
                child: const Icon(Icons.broken_image_outlined,
                    color: AppColors.textMuted, size: 28),
              ),
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
                      Colors.black.withValues(alpha: 0.55),
                    ],
                  ),
                ),
                child: Text(
                  Fmt.relative(entry.takenAt),
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
                child: Image.file(File(entry.path), fit: BoxFit.contain),
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

class _NotesTab extends StatelessWidget {
  const _NotesTab();
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Échange avec l\'agriculteur',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 6),
              const Text(
                'L\'agriculteur signale une nette réduction du jaunissement des feuilles après le dernier apport d\'urée.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
