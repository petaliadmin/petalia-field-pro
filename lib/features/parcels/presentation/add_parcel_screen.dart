import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:uuid/uuid.dart';

import '../../../core/data/bbch_stages.dart';
import '../../../core/data/crops_catalog.dart';
import '../../../core/data/senegal_regions.dart';
import '../../../core/data/soil_types.dart';
import '../../../core/fake_api/fake_data.dart';
import '../../../core/services/location_service.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/geo_utils.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../shared/widgets/success_feedback.dart';
import '../../../theme/app_colors.dart';
import '../domain/parcel.dart';
import 'parcels_providers.dart';

enum _DrawMode { tap, gps }

/// Screen for creating or editing a parcel.
///
/// Pass an existing [Parcel] to [existing] for edit mode.
class AddParcelScreen extends ConsumerStatefulWidget {
  const AddParcelScreen({super.key, this.existing});

  /// If non-null, the screen opens in edit mode with pre-filled data.
  final Parcel? existing;

  @override
  ConsumerState<AddParcelScreen> createState() => _AddParcelScreenState();
}

class _AddParcelScreenState extends ConsumerState<AddParcelScreen> {
  final _formKey = GlobalKey<FormState>();
  final _mapController = MapController();
  final _points = <LatLng>[];
  _DrawMode _mode = _DrawMode.tap;
  bool _gpsRecording = false;
  LatLng? _userPos;

  final _nameCtrl = TextEditingController();
  final _ownerCtrl = TextEditingController();
  final _villageCtrl = TextEditingController();
  final _yieldCtrl = TextEditingController();
  String _crop = 'Maïs';
  String? _variety;
  DateTime? _semisDate;
  String? _region;
  String? _soilType;
  String? _previousCrop;
  String _irrigation = 'Goutte-à-goutte';
  String _growthStage = 'vegetative';

  /// Step: 0 = draw on map, 1 = fill form
  int _step = 0;
  bool _saving = false;
  bool _isDirty = false;
  AutovalidateMode _autovalidateMode = AutovalidateMode.disabled;

  /// Catalogue complet des cultures (FR + WO + variétés).
  /// Provient de [CropsCatalog.allLabelsFr] — ordre déterministe, aucune
  /// duplication avec la liste locale.
  static final List<String> _crops = CropsCatalog.allLabelsFr;
  static const _irrig = [
    'Pluvial',
    'Goutte-à-goutte',
    'Aspersion',
    'Submersion',
  ];
  static const _growthStages = [
    'germination',
    'vegetative',
    'flowering',
    'fruiting',
    'maturation',
  ];

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    _loadPos();

    if (widget.existing != null) {
      final p = widget.existing!;
      _nameCtrl.text = p.name;
      _ownerCtrl.text = p.owner;
      _villageCtrl.text = p.village;
      _crop = _crops.contains(p.crop) ? p.crop : _crops.first;
      _irrigation = _irrig.contains(p.irrigation) ? p.irrigation : _irrig.first;
      _growthStage = _growthStages.contains(p.growthStage)
          ? p.growthStage
          : _growthStages[1];
      // Variété pré-remplie uniquement si elle fait partie du catalogue de la
      // culture courante — sinon on laisse l'utilisateur choisir.
      final cropDef = CropsCatalog.byLabelFr(_crop);
      if (p.variety != null && cropDef != null &&
          cropDef.varieties.contains(p.variety)) {
        _variety = p.variety;
      }
      _semisDate = p.semisDate;
      _region = p.region;
      _soilType = p.soilType;
      _previousCrop = p.previousCrop;
      if (p.estimatedYield > 0) _yieldCtrl.text = p.estimatedYield.toString();
      _points.addAll(p.boundary);
    }

    _nameCtrl.addListener(_markDirty);
    _ownerCtrl.addListener(_markDirty);
    _villageCtrl.addListener(_markDirty);
    _yieldCtrl.addListener(_markDirty);
  }

  Future<void> _loadPos() async {
    final p = await ref.read(locationServiceProvider).current();
    if (mounted) setState(() => _userPos = p);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _ownerCtrl.dispose();
    _villageCtrl.dispose();
    _yieldCtrl.dispose();
    super.dispose();
  }

  void _markDirty() {
    if (!_isDirty) setState(() => _isDirty = true);
  }

  String _growthStageLabel(String stage) {
    switch (stage) {
      case 'germination':
        return 'Germination';
      case 'vegetative':
        return 'Végétatif';
      case 'flowering':
        return 'Floraison';
      case 'fruiting':
        return 'Fructification';
      case 'maturation':
        return 'Maturation';
      default:
        return stage;
    }
  }

  Future<void> _showDiscardDialog() async {
    final discard = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Modifications non enregistrées'),
        content: const Text('Voulez-vous quitter sans enregistrer ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Quitter'),
          ),
        ],
      ),
    );
    if (discard == true && mounted) {
      setState(() => _isDirty = false);
      context.pop();
    }
  }

  Future<void> _toggleGps() async {
    if (!_gpsRecording) {
      _points.clear();
      setState(() => _gpsRecording = true);
      ref.read(locationServiceProvider).watch().listen((pos) {
        if (!_gpsRecording) return;
        if (_points.isEmpty ||
            GeoUtils.distanceKm(_points.last, pos) * 1000 > 3) {
          setState(() => _points.add(pos));
        }
      });
    } else {
      setState(() => _gpsRecording = false);
    }
  }

  void _undoLastPoint() {
    if (_points.isNotEmpty) {
      setState(() => _points.removeLast());
      _markDirty();
    }
  }

  LatLng get _mapCenter {
    if (_isEditing && _points.isNotEmpty) {
      return GeoUtils.centroid(_points);
    }
    return _userPos ?? FakeData.defaultCenter;
  }

  void _goToForm() {
    if (_points.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Placez au moins 3 points pour définir la parcelle.'),
        ),
      );
      return;
    }
    // Auto-detect region from parcel centroid if not already set.
    if (_region == null && _points.isNotEmpty) {
      final centroid = GeoUtils.centroid(_points);
      _region = SenegalRegions.nearest(centroid).id;
    }
    setState(() => _step = 1);
  }

  void _goBackToMap() {
    setState(() => _step = 0);
  }

  Future<void> _save() async {
    setState(() => _autovalidateMode = AutovalidateMode.onUserInteraction);
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      final yieldVal = double.tryParse(_yieldCtrl.text.trim()) ?? 0;
      final Parcel p;
      if (_isEditing) {
        p = widget.existing!.copyWith(
          name: _nameCtrl.text.trim(),
          owner: _ownerCtrl.text.trim(),
          village: _villageCtrl.text.trim(),
          crop: _crop,
          growthStage: _growthStage,
          irrigation: _irrigation,
          estimatedYield: yieldVal,
          boundary: List.of(_points),
          variety: _variety,
          semisDate: _semisDate,
          region: _region,
          soilType: _soilType,
          previousCrop: _previousCrop,
        );
      } else {
        p = Parcel(
          id: const Uuid().v4(),
          name: _nameCtrl.text.trim(),
          owner: _ownerCtrl.text.trim(),
          village: _villageCtrl.text.trim(),
          crop: _crop,
          growthStage: _growthStage,
          irrigation: _irrigation,
          healthScore: 0.75,
          lastVisit: DateTime.now(),
          estimatedYield: yieldVal,
          boundary: List.of(_points),
          variety: _variety,
          semisDate: _semisDate,
          region: _region,
          soilType: _soilType,
          previousCrop: _previousCrop,
        );
      }
      await ref.read(parcelsProvider.notifier).upsert(p);
      if (!mounted) return;
      setState(() => _isDirty = false);
      SuccessFeedback.show(
        context,
        message: _isEditing ? 'Parcelle modifiée !' : 'Parcelle enregistrée !',
      );
      context.pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  /// Dropdown variétés filtré par la culture courante.
  ///
  /// Affiche un champ désactivé si le catalogue n'expose pas de variétés pour
  /// la culture (cas improbable aujourd'hui — toutes ont au moins une).
  Widget _buildVarietyDropdown() {
    final cropDef = CropsCatalog.byLabelFr(_crop);
    final varieties = cropDef?.varieties ?? const <String>[];
    if (varieties.isEmpty) {
      return const SizedBox.shrink();
    }
    // Si la valeur courante n'est plus dans la liste (changement de culture),
    // on la neutralise pour éviter l'assertion Flutter sur DropdownButton.
    final current = varieties.contains(_variety) ? _variety : null;
    return DropdownButtonFormField<String>(
      value: current,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Variété',
        prefixIcon: Icon(Icons.spa_rounded),
        hintText: 'Optionnel',
      ),
      items: [
        const DropdownMenuItem<String>(
          value: null,
          child: Text('— Non renseignée —'),
        ),
        ...varieties.map(
          (v) => DropdownMenuItem<String>(value: v, child: Text(v)),
        ),
      ],
      onChanged: (v) {
        setState(() => _variety = v);
        _markDirty();
      },
    );
  }

  /// Sélecteur de date de semis — base des calculs BBCH / jours après semis.
  Widget _buildSemisDateField() {
    final label = _semisDate == null
        ? 'Date de semis (optionnel)'
        : 'Semis : ${Fmt.date(_semisDate!)}';
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () async {
        final now = DateTime.now();
        final picked = await showDatePicker(
          context: context,
          initialDate: _semisDate ?? now,
          // Fenêtre large : 2 campagnes passées → campagne en cours.
          firstDate: DateTime(now.year - 2, 1, 1),
          lastDate: DateTime(now.year, 12, 31),
          helpText: 'Date de semis',
        );
        if (picked != null) {
          setState(() => _semisDate = picked);
          _markDirty();
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Date de semis',
          prefixIcon: const Icon(Icons.event_rounded),
          suffixIcon: _semisDate == null
              ? const Icon(Icons.calendar_today_rounded, size: 18)
              : IconButton(
                  icon: const Icon(Icons.close_rounded, size: 18),
                  tooltip: 'Effacer',
                  onPressed: () {
                    setState(() => _semisDate = null);
                    _markDirty();
                  },
                ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 15,
            color: _semisDate == null
                ? AppColors.textMuted
                : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }

  /// Dropdown stade de croissance, filtré par la culture courante via le
  /// catalogue BBCH. Retombe sur la liste générique (5 stades) si la culture
  /// n'est pas référencée — assure la compat avec `ai_recommender`, PDF, etc.
  Widget _buildGrowthStageDropdown() {
    final cropDef = CropsCatalog.byLabelFr(_crop);
    final bbch = cropDef == null ? null : BbchCatalog.stagesFor(cropDef.id);

    // Items + valeurs possibles. On mappe chaque BbchStage.id en option.
    final List<DropdownMenuItem<String>> items;
    final Set<String> validValues;
    if (bbch != null && bbch.isNotEmpty) {
      items = bbch
          .map((s) => DropdownMenuItem<String>(
                value: s.id,
                child: Text('${s.labelFr} · BBCH ${s.code.toString().padLeft(2, '0')}'),
              ))
          .toList();
      validValues = bbch.map((s) => s.id).toSet();
    } else {
      items = _growthStages
          .map((s) => DropdownMenuItem<String>(
                value: s,
                child: Text(_growthStageLabel(s)),
              ))
          .toList();
      validValues = _growthStages.toSet();
    }

    // Si la valeur actuelle n'existe plus dans la liste (changement de
    // culture), on bascule sur le premier item disponible pour ne pas planter.
    String? current = validValues.contains(_growthStage) ? _growthStage : null;
    if (current == null && items.isNotEmpty) {
      current = items.first.value;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _growthStage != current) {
          setState(() => _growthStage = current!);
        }
      });
    }

    return DropdownButtonFormField<String>(
      value: current,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Stade de croissance',
        prefixIcon: Icon(Icons.trending_up_rounded),
      ),
      items: items,
      onChanged: (v) {
        if (v == null) return;
        setState(() => _growthStage = v);
        _markDirty();
      },
    );
  }

  /// Dropdown du type de sol dominant. Optionnel mais fortement recommandé
  /// pour adapter les doses d'eau et d'engrais aux propriétés du sol.
  Widget _buildSoilTypeDropdown() {
    return DropdownButtonFormField<String>(
      value: _soilType,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Type de sol',
        prefixIcon: Icon(Icons.terrain_rounded),
        hintText: 'Optionnel',
      ),
      items: [
        const DropdownMenuItem<String>(
          value: null,
          child: Text('— Non renseigné —'),
        ),
        ...SoilTypes.all.map(
          (s) => DropdownMenuItem<String>(
            value: s.id,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(s.labelFr, overflow: TextOverflow.ellipsis),
                Text(
                  s.descriptionFr,
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textMuted),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ],
      onChanged: (v) {
        setState(() => _soilType = v);
        _markDirty();
      },
    );
  }

  /// Dropdown de la culture précédente (rotation). Liste tirée du catalogue
  /// complet + options "Jachère" et "Aucune / nouveau champ". Optionnel.
  Widget _buildPreviousCropDropdown() {
    const fallow = '__fallow__';
    const none = '__none__';

    // Valeur courante : doit appartenir à la liste des items construits pour
    // éviter l'assertion Flutter sur DropdownButton.
    final catalogLabels = CropsCatalog.allLabelsFr;
    final knownValues = <String?>{null, fallow, none, ...catalogLabels};
    final current =
        knownValues.contains(_previousCrop) ? _previousCrop : null;

    return DropdownButtonFormField<String>(
      value: current,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Culture précédente',
        prefixIcon: Icon(Icons.history_rounded),
        hintText: 'Rotation — optionnel',
      ),
      items: [
        const DropdownMenuItem<String>(
          value: null,
          child: Text('— Non renseignée —'),
        ),
        const DropdownMenuItem<String>(
          value: fallow,
          child: Text('Jachère'),
        ),
        const DropdownMenuItem<String>(
          value: none,
          child: Text('Aucune (nouveau champ)'),
        ),
        ...catalogLabels.map(
          (c) => DropdownMenuItem<String>(value: c, child: Text(c)),
        ),
      ],
      onChanged: (v) {
        setState(() => _previousCrop = v);
        _markDirty();
      },
    );
  }

  /// Dropdown de la région administrative, auto-détectée depuis le centroïde.
  Widget _buildRegionDropdown() {
    return DropdownButtonFormField<String>(
      value: _region,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Région',
        prefixIcon: Icon(Icons.map_rounded),
        hintText: 'Auto-détectée depuis la carte',
      ),
      items: [
        const DropdownMenuItem<String>(
          value: null,
          child: Text('— Non renseignée —'),
        ),
        ...SenegalRegions.all.map(
          (r) => DropdownMenuItem<String>(
            value: r.id,
            child: Text(r.labelFr),
          ),
        ),
      ],
      onChanged: (v) {
        setState(() => _region = v);
        _markDirty();
      },
    );
  }

  /// Bulle "Stade suggéré — appliquer" visible quand culture + date de semis
  /// sont renseignées et que la suggestion diffère du stade courant.
  Widget _buildBbchSuggestion() {
    if (_semisDate == null) return const SizedBox.shrink();
    final cropDef = CropsCatalog.byLabelFr(_crop);
    if (cropDef == null) return const SizedBox.shrink();
    final das = DateTime.now().difference(_semisDate!).inDays;
    final suggested = BbchCatalog.estimateStage(cropId: cropDef.id, das: das);
    if (suggested == null) return const SizedBox.shrink();
    final matches = suggested.id == _growthStage;

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: matches
              ? AppColors.success.withValues(alpha: 0.10)
              : AppColors.accent.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: matches
                ? AppColors.success.withValues(alpha: 0.35)
                : AppColors.accent.withValues(alpha: 0.35),
          ),
        ),
        child: Row(
          children: [
            Icon(
              matches ? Icons.check_circle_rounded : Icons.auto_awesome_rounded,
              size: 18,
              color: matches ? AppColors.success : AppColors.accent,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                matches
                    ? 'J+$das · stade cohérent avec ${suggested.labelFr}'
                    : 'J+$das · stade suggéré : ${suggested.labelFr} (BBCH ${suggested.code.toString().padLeft(2, '0')})',
                style: const TextStyle(fontSize: 12.5, height: 1.3),
              ),
            ),
            if (!matches)
              TextButton(
                style: TextButton.styleFrom(
                  minimumSize: const Size(0, 32),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                ),
                onPressed: () {
                  setState(() => _growthStage = suggested.id);
                  _markDirty();
                },
                child: const Text('Appliquer'),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final area = GeoUtils.polygonAreaHa(_points);
    return PopScope(
      canPop: !_isDirty,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (_step == 1) {
          _goBackToMap();
        } else {
          _showDiscardDialog();
        }
      },
      child: Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Modifier la parcelle' : 'Nouvelle parcelle'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            if (_step == 1) {
              _goBackToMap();
            } else if (_isDirty) {
              _showDiscardDialog();
            } else {
              context.pop();
            }
          },
        ),
        actions: [
          if (_step == 0 && _points.isNotEmpty)
            IconButton(
              tooltip: 'Annuler dernier point',
              onPressed: _undoLastPoint,
              icon: const Icon(Icons.undo_rounded),
            ),
          if (_step == 0 && _points.isNotEmpty)
            IconButton(
              tooltip: 'Tout effacer',
              onPressed: () { setState(_points.clear); _markDirty(); },
              icon: const Icon(Icons.delete_outline_rounded),
            ),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _step == 0
            ? _buildMapStep(area)
            : _buildFormStep(area),
      ),
    ),
    );
  }

  // ---------------------------------------------------------------------------
  // Step 0 — Draw on map
  // ---------------------------------------------------------------------------
  Widget _buildMapStep(double area) {
    return Column(
      key: const ValueKey('map'),
      children: [
        // Step indicator
        _StepBar(step: 0),
        // Map
        Expanded(
          child: Stack(
            children: [
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _mapCenter,
                  initialZoom: 18.0,
                  minZoom: 1,
                  onTap: _mode == _DrawMode.tap
                      ? (_, p) {
                          setState(() => _points.add(p));
                          _markDirty();
                        }
                      : null,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
                    userAgentPackageName: 'com.petalia.fieldpro',
                  ),
                  if (_points.length >= 2)
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: [
                            ..._points,
                            if (_points.length >= 3) _points.first,
                          ],
                          color: Colors.white.withValues(alpha: 0.7),
                          strokeWidth: 2,
                        ),
                      ],
                    ),
                  if (_points.length >= 3)
                    PolygonLayer(
                      polygons: [
                        Polygon(
                          points: _points,
                          color: AppColors.accent.withValues(alpha: 0.25),
                          borderColor: AppColors.accent,
                          borderStrokeWidth: 2.5,
                        ),
                      ],
                    ),
                  MarkerLayer(
                    markers: [
                      for (int i = 0; i < _points.length; i++)
                        Marker(
                          point: _points[i],
                          width: 30,
                          height: 30,
                          child: GestureDetector(
                            onLongPress: () {
                                setState(() => _points.removeAt(i));
                                _markDirty();
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: i == 0
                                    ? AppColors.accent
                                    : Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.accent,
                                  width: 2.5,
                                ),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: 4,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                '${i + 1}',
                                style: TextStyle(
                                  color: i == 0
                                      ? Colors.white
                                      : AppColors.accent,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              // Mode picker
              Positioned(
                top: 12,
                left: 12,
                right: 12,
                child: _ModePicker(
                  mode: _mode,
                  onChanged: (m) => setState(() => _mode = m),
                ),
              ),
              // My location button
              if (_userPos != null)
                Positioned(
                  right: 14,
                  bottom: 100,
                  child: Material(
                    color: Colors.white,
                    elevation: 4,
                    shape: const CircleBorder(),
                    child: InkWell(
                      onTap: () => _mapController.move(_userPos!, 18),
                      customBorder: const CircleBorder(),
                      child: const Padding(
                        padding: EdgeInsets.all(12),
                        child: Icon(Icons.my_location_rounded,
                            color: AppColors.primary, size: 22),
                      ),
                    ),
                  ),
                ),
              // Bottom bar
              Positioned(
                bottom: 14,
                left: 14,
                right: 14,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Area info
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: const [
                          BoxShadow(color: Colors.black26, blurRadius: 16),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            height: 40,
                            width: 40,
                            decoration: BoxDecoration(
                              color: _points.length >= 3
                                  ? AppColors.primary.withValues(alpha: 0.12)
                                  : AppColors.secondary,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              _points.length >= 3
                                  ? Icons.check_circle_rounded
                                  : Icons.touch_app_rounded,
                              color: _points.length >= 3
                                  ? AppColors.primary
                                  : AppColors.textMuted,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _points.length >= 3
                                      ? '${Fmt.hectares(area)} · ${_points.length} points'
                                      : '${_points.length} point${_points.length > 1 ? 's' : ''} place${_points.length > 1 ? 's' : ''}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15),
                                ),
                                Text(
                                  _points.length < 3
                                      ? 'Placez au moins 3 points'
                                      : 'Appuyez long sur un point pour le supprimer',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (_mode == _DrawMode.gps)
                            FilledButton.icon(
                              style: FilledButton.styleFrom(
                                backgroundColor: _gpsRecording
                                    ? AppColors.danger
                                    : AppColors.primary,
                                minimumSize: const Size(0, 40),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14),
                              ),
                              onPressed: _toggleGps,
                              icon: Icon(_gpsRecording
                                  ? Icons.stop_rounded
                                  : Icons.directions_walk_rounded),
                              label: Text(
                                  _gpsRecording ? 'Stop' : 'Démarrer'),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Next step button
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: _points.length >= 3
                              ? AppColors.primary
                              : AppColors.textMuted,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed:
                            _points.length >= 3 ? _goToForm : null,
                        icon: const Icon(Icons.arrow_forward_rounded),
                        label: const Text('Suivant',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Step 1 — Form
  // ---------------------------------------------------------------------------
  Widget _buildFormStep(double area) {
    return SingleChildScrollView(
      key: const ValueKey('form'),
      padding: EdgeInsets.fromLTRB(
          20, 0, 20, MediaQuery.of(context).padding.bottom + 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StepBar(step: 1),
          const SizedBox(height: 8),
          // Mini map preview
          GestureDetector(
            onTap: _goBackToMap,
            child: Container(
              height: 150,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 8),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                children: [
                  AbsorbPointer(
                    child: FlutterMap(
                      options: MapOptions(
                        initialCenter: GeoUtils.centroid(_points),
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
                              points: _points,
                              color:
                                  AppColors.accent.withValues(alpha: 0.3),
                              borderColor: AppColors.accent,
                              borderStrokeWidth: 2.5,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Overlay with area
                  Positioned(
                    bottom: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.straighten_rounded,
                              color: Colors.white, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            '${Fmt.hectares(area)} · ${_points.length} pts',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Edit hint
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: const [
                          BoxShadow(color: Colors.black12, blurRadius: 4),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.edit_rounded,
                              size: 14, color: AppColors.primary),
                          SizedBox(width: 4),
                          Text('Modifier',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Surface area summary card
          GlassCard(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  height: 44,
                  width: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.straighten_rounded,
                      color: AppColors.primary, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Surface de la parcelle',
                          style: TextStyle(
                              fontSize: 13, color: AppColors.textMuted)),
                      Text(
                        '${Fmt.hectares(area)} · ${_points.length} points',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Form wrapped with validation
          Form(
            key: _formKey,
            autovalidateMode: _autovalidateMode,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- Identification section ---
                const SectionHeader(title: 'Identification'),
                GlassCard(
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _nameCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Nom de la parcelle',
                          prefixIcon: Icon(Icons.label_rounded),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Le nom est obligatoire'
                            : null,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _ownerCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Propriétaire',
                          prefixIcon: Icon(Icons.person_rounded),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Le propriétaire est obligatoire'
                            : null,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _villageCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Village',
                          prefixIcon: Icon(Icons.location_city_rounded),
                          hintText: 'Optionnel',
                        ),
                      ),
                      const SizedBox(height: 14),
                      _buildRegionDropdown(),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                // --- Culture section ---
                const SectionHeader(title: 'Culture'),
                GlassCard(
                  child: Column(
                    children: [
                      DropdownButtonFormField<String>(
                        value: _crop,
                        decoration: const InputDecoration(
                          labelText: 'Culture',
                          prefixIcon: Icon(Icons.grass_rounded),
                        ),
                        items: _crops
                            .map((c) =>
                                DropdownMenuItem(value: c, child: Text(c)))
                            .toList(),
                        onChanged: (v) {
                          setState(() {
                            _crop = v!;
                            // Variétés dépendantes de la culture — reset.
                            _variety = null;
                          });
                          _markDirty();
                        },
                      ),
                      const SizedBox(height: 14),
                      _buildVarietyDropdown(),
                      const SizedBox(height: 14),
                      _buildSemisDateField(),
                      const SizedBox(height: 14),
                      _buildGrowthStageDropdown(),
                      _buildBbchSuggestion(),
                      const SizedBox(height: 14),
                      DropdownButtonFormField<String>(
                        value: _irrigation,
                        decoration: const InputDecoration(
                          labelText: 'Irrigation',
                          prefixIcon: Icon(Icons.water_drop_rounded),
                        ),
                        items: _irrig
                            .map((c) =>
                                DropdownMenuItem(value: c, child: Text(c)))
                            .toList(),
                        onChanged: (v) {
                          setState(() => _irrigation = v!);
                          _markDirty();
                        },
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _yieldCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Rendement estimé (t/ha)',
                          prefixIcon: Icon(Icons.scale_rounded),
                          hintText: 'Optionnel',
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return null;
                          final n = double.tryParse(v.trim());
                          if (n == null || n < 0) return 'Valeur invalide';
                          if (n > 100) return 'Valeur trop élevée';
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                // --- Sol & rotation section ---
                const SectionHeader(title: 'Sol & rotation'),
                GlassCard(
                  child: Column(
                    children: [
                      _buildSoilTypeDropdown(),
                      const SizedBox(height: 14),
                      _buildPreviousCropDropdown(),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                PrimaryButton(
                  icon: Icons.check_rounded,
                  label: 'Enregistrer',
                  loading: _saving,
                  onPressed: _save,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Step bar
// =============================================================================
class _StepBar extends StatelessWidget {
  const _StepBar({required this.step});
  final int step;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.secondary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          _stepDot(0, 'Tracer', Icons.map_rounded),
          Expanded(
            child: Container(
              height: 2,
              margin: const EdgeInsets.symmetric(horizontal: 8),
              color: step >= 1 ? AppColors.primary : AppColors.divider,
            ),
          ),
          _stepDot(1, 'Infos', Icons.edit_note_rounded),
        ],
      ),
    );
  }

  Widget _stepDot(int index, String label, IconData icon) {
    final active = step >= index;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: 36,
          width: 36,
          decoration: BoxDecoration(
            color: active ? AppColors.primary : AppColors.secondary,
            shape: BoxShape.circle,
          ),
          child: Icon(icon,
              size: 18,
              color: active ? Colors.white : AppColors.textMuted),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            color: active ? AppColors.primary : AppColors.textMuted,
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// Mode picker
// =============================================================================
class _ModePicker extends StatelessWidget {
  const _ModePicker({required this.mode, required this.onChanged});
  final _DrawMode mode;
  final ValueChanged<_DrawMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)],
      ),
      child: Row(
        children: [
          _tab(_DrawMode.tap, 'Toucher', Icons.touch_app_rounded),
          _tab(_DrawMode.gps, 'Marche GPS', Icons.directions_walk_rounded),
        ],
      ),
    );
  }

  Widget _tab(_DrawMode m, String label, IconData icon) {
    final selected = mode == m;
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => onChanged(m),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon,
                  size: 16,
                  color: selected ? Colors.white : AppColors.textSecondary),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: selected ? Colors.white : AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
