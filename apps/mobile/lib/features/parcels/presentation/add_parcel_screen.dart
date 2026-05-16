import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:latlong2/latlong.dart';
import 'package:uuid/uuid.dart';

import '../../../core/data/bbch_stages.dart';
import '../../../core/data/crops_catalog.dart';
import '../../../core/data/senegal_regions.dart';
import '../../../core/data/soil_types.dart';
import '../../../core/services/contact_picker.dart';
import '../../../core/services/location_service.dart';
import '../../../core/services/tile_cache_service.dart';
import '../../../core/utils/formatters.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../../core/utils/geo_utils.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../shared/widgets/success_feedback.dart';
import '../../../theme/app_colors.dart';
import '../../auth/presentation/auth_providers.dart';
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

  /// Index du point en cours de drag (null si aucun). Sert à désactiver le pan
  /// de la carte le temps du glissement et à mettre en évidence le marker.
  int? _draggingIndex;

  /// Précision horizontale (m) du dernier fix GPS reçu pendant le walk.
  /// Permet d'afficher un feedback live ("±5 m" vert / "±20 m" rouge) et de
  /// bloquer la capture de points au-delà du seuil [_hdopThresholdM].
  double? _lastAccuracyM;
  StreamSubscription? _gpsSub;

  /// Seuil de précision GPS au-delà duquel on refuse d'enregistrer un point.
  /// Standard "Elite" : 5m max pour garantir un calcul de surface fiable.
  static const double _hdopThresholdM = 5.0;

  final _ownerCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _villageCtrl = TextEditingController();
  final _yieldCtrl = TextEditingController();
  String? _crop;
  String? _variety;
  DateTime? _semisDate;
  String? _region;
  String? _soilType;
  String? _previousCrop;
  String? _irrigation;
  String? _growthStage;

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
      _ownerCtrl.text = p.owner;
      if (p.phone != null) _phoneCtrl.text = p.phone!;
      _villageCtrl.text = p.village;
      _crop = p.crop;
      _irrigation = p.irrigation;
      _growthStage = p.growthStage;
      // Variété pré-remplie uniquement si elle fait partie du catalogue de la
      // culture courante — sinon on laisse l'utilisateur choisir.
      final cropDef = _crop != null ? CropsCatalog.byLabelFr(_crop!) : null;
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

    _ownerCtrl.addListener(_markDirty);
    _phoneCtrl.addListener(_markDirty);
    _villageCtrl.addListener(_markDirty);
    _yieldCtrl.addListener(_markDirty);
  }

  Future<void> _loadPos() async {
    final p = await ref.read(locationServiceProvider).current();
    if (mounted) setState(() => _userPos = p);
  }

  @override
  void dispose() {
    _gpsSub?.cancel();
    _ownerCtrl.dispose();
    _phoneCtrl.dispose();
    _villageCtrl.dispose();
    _yieldCtrl.dispose();
    super.dispose();
  }

  void _markDirty() {
    if (!_isDirty) setState(() => _isDirty = true);
  }

  /// Ouvre le carnet de contacts du téléphone et pré-remplit le nom de
  /// l'agriculteur + son numéro à partir de la fiche choisie. Utilise
  /// `openExternalPick` pour éviter de demander la permission READ_CONTACTS
  /// — le picker système gère l'accès. Si plusieurs numéros sont disponibles,
  /// le premier (généralement "mobile") est retenu.
  ///
  /// Le plugin n'a pas d'implémentation web : on affiche un message clair au
  /// lieu de laisser remonter une `MissingPluginException`.
  Future<void> _pickContact() async {
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'L’import depuis les contacts n’est disponible que sur mobile.'),
        ),
      );
      return;
    }
    try {
      final contact = await pickContact();
      if (contact == null) return; // utilisateur a annulé
      setState(() {
        if (contact.name != null) _ownerCtrl.text = contact.name!;
        if (contact.phone != null) _phoneCtrl.text = contact.phone!;
      });
      _markDirty();
      HapticFeedback.selectionClick();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Impossible d’ouvrir les contacts : $e'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  String _growthStageLabel(AppLocalizations l10n, String stage) {
    switch (stage) {
      case 'germination':
        return l10n.stageGermination;
      case 'vegetative':
        return l10n.stageVegetative;
      case 'flowering':
        return l10n.stageFlowering;
      case 'fruiting':
        return l10n.stageFruiting;
      case 'maturation':
        return l10n.stageMaturation;
      default:
        return stage;
    }
  }
  Future<void> _showDiscardDialog() async {
    final l10n = AppLocalizations.of(context);
    final discard = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.addParcelDiscardTitle),
        content: Text(l10n.addParcelConfirmDiscard),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.genericCancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.genericQuit),
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
      setState(() {
        _gpsRecording = true;
        _lastAccuracyM = null;
      });
      _gpsSub?.cancel();
      _gpsSub =
          ref.read(locationServiceProvider).watchWithAccuracy().listen((fix) {
        if (!_gpsRecording) return;

        final acc = fix.accuracyM;
        // Met toujours à jour l'indicateur de précision en temps réel, même si
        // le point ne sera pas retenu (permet à l'utilisateur de voir quand
        // le signal se stabilise).
        if (acc != _lastAccuracyM) {
          setState(() => _lastAccuracyM = acc);
        }

        // Blocage précision : on n'ajoute pas un point si HDOP > seuil.
        if (acc != null && acc > _hdopThresholdM) return;

        final tooClose = _points.isNotEmpty &&
            GeoUtils.distanceKm(_points.last, fix.position) * 1000 <= 3;
        if (tooClose) return;

        setState(() => _points.add(fix.position));
        // Signal sonore/haptique à chaque point capturé — indispensable quand
        // l'écran est dans la poche ou sous soleil fort (cf. §9.6).
        HapticFeedback.mediumImpact();
        SystemSound.play(SystemSoundType.click);
        _markDirty();
      });
    } else {
      setState(() => _gpsRecording = false);
      _gpsSub?.cancel();
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
    return _userPos ?? const LatLng(14.7889, -16.9260);
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

  /// Generates a short auto-code like `MAI-001` based on the crop and the
  /// next available sequence among existing parcels for that crop.
  String _generateParcelCode() {
    final existing = ref.read(parcelsProvider);
    final prefix = (_crop ?? 'XXX')
        .replaceAll(RegExp(r'[^A-Za-zÀ-ÿ]'), '')
        .toUpperCase()
        .padRight(3, 'X')
        .substring(0, 3);
    final pattern = RegExp('^$prefix-(\\d{3,})\$');
    int maxSeq = 0;
    for (final p in existing) {
      final m = pattern.firstMatch(p.name);
      if (m != null) {
        final n = int.tryParse(m.group(1)!) ?? 0;
        if (n > maxSeq) maxSeq = n;
      }
    }
    final next = (maxSeq + 1).toString().padLeft(3, '0');
    return '$prefix-$next';
  }

  void _updateSuggestedStage() {
    if (_semisDate == null || _crop == null) return;
    final cropDef = CropsCatalog.byLabelFr(_crop!);
    if (cropDef == null) return;
    final das = DateTime.now().difference(_semisDate!).inDays;
    final suggested = BbchCatalog.estimateStage(cropId: cropDef.id, das: das);
    if (suggested != null) {
      setState(() => _growthStage = suggested.id);
    }
  }

  Future<void> _save() async {
    setState(() => _autovalidateMode = AutovalidateMode.onUserInteraction);
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez remplir tous les champs requis')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final yieldVal = double.tryParse(_yieldCtrl.text.trim()) ?? 0;
      final currentUser = ref.read(authStateProvider).value?.user;
      final techName = currentUser?.name ?? 'Technicien mobile';

      final Parcel p;
      if (_isEditing) {
        final phoneTrim = _phoneCtrl.text.trim();
        p = widget.existing!.copyWith(
          owner: _ownerCtrl.text.trim(),
          phone: phoneTrim.isEmpty ? null : phoneTrim,
          technician: techName,
          village: _villageCtrl.text.trim(),
          crop: _crop!,
          growthStage: _growthStage!,
          irrigation: _irrigation!,
          estimatedYield: yieldVal,
          boundary: List.of(_points),
          variety: _variety,
          semisDate: _semisDate,
          region: _region,
          soilType: _soilType,
          previousCrop: _previousCrop,
        );
      } else {
        final phoneTrim = _phoneCtrl.text.trim();
        p = Parcel(
          id: const Uuid().v4(),
          name: _generateParcelCode(),
          owner: _ownerCtrl.text.trim(),
          phone: phoneTrim.isEmpty ? null : phoneTrim,
          technician: techName,
          village: _villageCtrl.text.trim(),
          crop: _crop!,
          growthStage: _growthStage!,
          irrigation: _irrigation!,
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
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de l\'enregistrement : $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  /// Dropdown variétés filtré par la culture courante.
  ///
  /// Affiche un champ désactivé si le catalogue n'expose pas de variétés pour
  /// la culture (cas improbable aujourd'hui — toutes ont au moins une).
  Widget _buildVarietyDropdown() {
    final cropDef = _crop != null ? CropsCatalog.byLabelFr(_crop!) : null;
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
          _updateSuggestedStage();
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
                ? Theme.of(context).colorScheme.onSurfaceVariant
                : Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ),
    );
  }

  /// Dropdown stade de croissance, filtré par la culture courante via le
  /// catalogue BBCH. Retombe sur la liste générique (5 stades) si la culture
  /// n'est pas référencée — assure la compat avec `ai_recommender`, PDF, etc.
  Widget _buildGrowthStageDropdown() {
    final l10n = AppLocalizations.of(context);
    final cropDef = _crop != null ? CropsCatalog.byLabelFr(_crop!) : null;
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
                child: Text(_growthStageLabel(l10n, s)),
              ))
          .toList();
      validValues = _growthStages.toSet();
    }

    String? current = validValues.contains(_growthStage) ? _growthStage : null;

    return DropdownButtonFormField<String>(
      value: current,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Stade de croissance',
        prefixIcon: Icon(Icons.trending_up_rounded),
      ),
      hint: const Text('Sélectionner un stade'),
      items: items,
      onChanged: (v) {
        setState(() => _growthStage = v);
        _markDirty();
      },
      validator: (v) => v == null ? 'Champ requis' : null,
    );
  }

  /// Dropdown du type de sol dominant. Optionnel mais fortement recommandé
  /// pour adapter les doses d'eau et d'engrais aux propriétés du sol.
  Widget _buildSoilTypeDropdown() {
    return DropdownButtonFormField<String>(
      value: _soilType,
      isExpanded: true,
      itemHeight: null, // Allow items to be as tall as their content
      decoration: const InputDecoration(
        labelText: 'Type de sol',
        prefixIcon: Icon(Icons.terrain_rounded),
        hintText: 'Optionnel',
      ),
      selectedItemBuilder: (context) {
        return [
          const Text('— Non renseigné —'),
          ...SoilTypes.all.map((s) => Text(s.label(context))),
        ];
      },
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
                Text(s.label(context), style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(
                  s.description(context),
                  style: TextStyle(
                      fontSize: 11, color: AppColors.textMutedOf(context)),
                  softWrap: true,
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
    final l10n = AppLocalizations.of(context);
    if (_semisDate == null) return const SizedBox.shrink();
    final cropDef = _crop != null ? CropsCatalog.byLabelFr(_crop!) : null;
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
                    ? l10n.addParcelSuggestionCoherent(das, suggested.label(context))
                    : l10n.addParcelSuggestionApplied(das, suggested.label(context), suggested.code.toString().padLeft(2, '0')),
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
                child: Text(l10n.genericApply),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
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
        title: Text(_isEditing ? l10n.editParcelTitle : l10n.addParcelTitle),
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
    final l10n = AppLocalizations.of(context);
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
                  minZoom: 0,
                  maxZoom: 24,
                  interactionOptions: InteractionOptions(
                    flags: _draggingIndex != null
                        ? InteractiveFlag.none
                        : InteractiveFlag.all,
                  ),
                  onTap: _mode == _DrawMode.tap
                      ? (_, p) {
                          setState(() => _points.add(p));
                          _markDirty();
                        }
                      : null,
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://mt1.google.com/vt/lyrs=y&x={x}&y={y}&z={z}',
                    maxZoom: 24,
                    maxNativeZoom: 20,
                    userAgentPackageName: 'com.petalia.fieldpro',
                  ),
                  // Trait plein entre points successifs
                  if (_points.length >= 2)
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: _points,
                          color: Colors.white.withValues(alpha: 0.85),
                          strokeWidth: 2.5,
                        ),
                      ],
                    ),
                  // Ligne de fermeture : preview pointillé dès 2 points, trait
                  // plein une fois le polygone valide (≥ 3 points).
                  if (_points.length >= 2)
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: [_points.last, _points.first],
                          color: _points.length >= 3
                              ? AppColors.accent.withValues(alpha: 0.8)
                              : Colors.white.withValues(alpha: 0.55),
                          strokeWidth: 2,
                          pattern: _points.length >= 3
                              ? const StrokePattern.solid()
                              : StrokePattern.dashed(
                                  segments: const [8, 6],
                                ),
                        ),
                      ],
                    ),
                  // Preview dynamique : depuis le dernier point vers la
                  // position GPS courante, avant même d'avoir placé le
                  // prochain point. Aide l'utilisateur à viser.
                  if (_points.isNotEmpty &&
                      _userPos != null &&
                      _points.last != _userPos)
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: [_points.last, _userPos!],
                          color: AppColors.accent.withValues(alpha: 0.5),
                          strokeWidth: 1.5,
                          pattern: const StrokePattern.dotted(),
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
                          width: 44,
                          height: 44,
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onLongPress: () {
                              setState(() => _points.removeAt(i));
                              _markDirty();
                              HapticFeedback.mediumImpact();
                            },
                            onPanStart: (_) {
                              setState(() => _draggingIndex = i);
                              HapticFeedback.selectionClick();
                            },
                            onPanUpdate: (details) {
                              final camera = _mapController.camera;
                              final currentPt =
                                  camera.latLngToScreenPoint(_points[i]);
                              final newOffset = Offset(
                                currentPt.x + details.delta.dx,
                                currentPt.y + details.delta.dy,
                              );
                              final newLatLng =
                                  camera.offsetToCrs(newOffset);
                              setState(() => _points[i] = newLatLng);
                            },
                            onPanEnd: (_) {
                              setState(() => _draggingIndex = null);
                              _markDirty();
                            },
                            onPanCancel: () {
                              setState(() => _draggingIndex = null);
                            },
                            child: Center(
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 120),
                                width: _draggingIndex == i ? 34 : 28,
                                height: _draggingIndex == i ? 34 : 28,
                                decoration: BoxDecoration(
                                  color: i == 0
                                      ? AppColors.accent
                                      : Colors.white,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppColors.accent,
                                    width: _draggingIndex == i ? 3.5 : 2.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                          alpha:
                                              _draggingIndex == i ? 0.4 : 0.25),
                                      blurRadius: _draggingIndex == i ? 8 : 4,
                                      offset: const Offset(0, 2),
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
              // My location button
              if (_userPos != null)
                Positioned(
                  right: 14,
                  bottom: 230,
                  child: Consumer(
                    builder: (context, ref, _) {
                      final progress = ref.watch(tileDownloadProgressProvider).valueOrNull;
                      final isDownloading = progress != null && !progress.isComplete;

                      return _FabRound(
                        icon: isDownloading ? Icons.sync_rounded : Icons.cloud_download_rounded,
                        color: isDownloading ? AppColors.accent : AppColors.primary,
                        onTap: isDownloading 
                          ? null 
                          : () {
                              TileCacheService.cacheAroundPoint(
                                point: _mapController.camera.center,
                                osmUrl: 'https://mt1.google.com/vt/lyrs=y&x={x}&y={y}&z={z}',
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Téléchargement de la zone en cours...')),
                              );
                            },
                      );
                    },
                  ),
                ),
              if (_userPos != null)
                Positioned(
                  right: 14,
                  bottom: 180,
                  child: _FabRound(
                    icon: Icons.my_location_rounded,
                    onTap: () => _mapController.move(_userPos!, 20),
                  ),
                ),

              // Crosshair for precision
              Center(
                child: IgnorePointer(
                  child: Container(
                    padding: const EdgeInsets.only(bottom: 0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 1.5,
                          height: 30,
                          color: AppColors.accent,
                        ),
                        Container(
                          width: 30,
                          height: 1.5,
                          color: AppColors.accent,
                        ),
                        Icon(
                          Icons.add_circle_outline_rounded,
                          color: AppColors.accent.withValues(alpha: 0.8),
                          size: 32,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Capture controls
              Positioned(
                right: 16,
                bottom: 110,
                child: Column(
                  children: [
                    if (_mode == _DrawMode.tap)
                      FloatingActionButton.large(
                        heroTag: 'add_point',
                        onPressed: () {
                          final center = _mapController.camera.center;
                          setState(() => _points.add(center));
                          _markDirty();
                          HapticFeedback.heavyImpact();
                        },
                        backgroundColor: AppColors.accent,
                        foregroundColor: Colors.white,
                        child: const Icon(Icons.add_location_alt_rounded, size: 36),
                      ),
                    const SizedBox(height: 16),
                    _FabRound(
                      icon: Icons.undo_rounded,
                      onTap: _undoLastPoint,
                    ),
                  ],
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
                        color: AppColors.surfaceOf(context),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(color: AppColors.shadowOf(context), blurRadius: 16),
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
                                  : AppColors.surfaceAltOf(context),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              _points.length >= 3
                                  ? Icons.check_circle_rounded
                                  : Icons.touch_app_rounded,
                              color: _points.length >= 3
                                  ? AppColors.primary
                                  : AppColors.textMutedOf(context),
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
                                      : 'Glissez un point pour l’ajuster · appui long pour supprimer',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textMutedOf(context),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (_mode == _DrawMode.gps) ...[
                            if (_gpsRecording)
                              _GpsAccuracyBadge(
                                accuracyM: _lastAccuracyM,
                                thresholdM: _hdopThresholdM,
                              ),
                            if (_gpsRecording) const SizedBox(width: 8),
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
                                  _gpsRecording ? l10n.genericStop : l10n.genericStart),
                            ),
                          ],
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
                              : AppColors.textMutedOf(context),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed:
                            _points.length >= 3 ? _goToForm : null,
                        icon: const Icon(Icons.arrow_forward_rounded),
                        label: Text(l10n.genericNext,
                            style: const TextStyle(
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
    final l10n = AppLocalizations.of(context);
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
                boxShadow: [
                  BoxShadow(color: AppColors.shadowOf(context), blurRadius: 8),
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
                        color: AppColors.surfaceOf(context),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(color: AppColors.shadowOf(context), blurRadius: 4),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.edit_rounded,
                              size: 14, color: AppColors.primary),
                          const SizedBox(width: 4),
                          Text(l10n.parcelMenuEdit,
                              style: const TextStyle(
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
                      Text(l10n.parcelKpiSurface,
                          style: TextStyle(
                              fontSize: 13, color: AppColors.textMutedOf(context))),
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
                SectionHeader(title: l10n.genericIdentification),
                GlassCard(
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _ownerCtrl,
                        decoration: InputDecoration(
                          labelText: l10n.addParcelLabelOwner,
                          prefixIcon: const Icon(Icons.person_rounded),
                          suffixIcon: IconButton(
                            tooltip: 'Importer depuis les contacts',
                            icon: const Icon(Icons.contact_phone_rounded),
                            onPressed: _pickContact,
                          ),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? l10n.genericRequiredField
                            : null,
                      ),
                      const SizedBox(height: 14),
                      IntlPhoneField(
                        controller: _phoneCtrl,
                        initialCountryCode: 'SN',
                        showCountryFlag: false,
                        decoration: const InputDecoration(
                          labelText: 'Téléphone',
                          prefixIcon: Icon(Icons.phone_rounded),
                          hintText: '77 123 45 67',
                        ),
                        onChanged: (phone) {
                          // update numeric value if needed, but controller handles it
                        },
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _villageCtrl,
                        decoration: InputDecoration(
                          labelText: l10n.addParcelLabelVillage,
                          prefixIcon: const Icon(Icons.location_city_rounded),
                          hintText: l10n.recoFallbackHint,
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
                        hint: const Text('Sélectionner une culture'),
                        items: _crops
                            .map((c) =>
                                DropdownMenuItem(value: c, child: Text(c)))
                            .toList(),
                        onChanged: (v) {
                          setState(() {
                            _crop = v;
                            // Variétés dépendantes de la culture — reset.
                            _variety = null;
                          });
                          _updateSuggestedStage();
                          _markDirty();
                        },
                        validator: (v) => v == null ? 'Champ requis' : null,
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
                        hint: const Text('Sélectionner le mode d\'irrigation'),
                        items: _irrig
                            .map((c) =>
                                DropdownMenuItem(value: c, child: Text(c)))
                            .toList(),
                        onChanged: (v) {
                          setState(() => _irrigation = v);
                          _markDirty();
                        },
                        validator: (v) => v == null ? 'Champ requis' : null,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _yieldCtrl,
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
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 20),
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
        color: AppColors.surfaceAltOf(context),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          _stepDot(context, 0, 'Tracer', Icons.map_rounded),
          Expanded(
            child: Container(
              height: 2,
              margin: const EdgeInsets.symmetric(horizontal: 8),
              color: step >= 1 ? AppColors.primary : AppColors.dividerOf(context),
            ),
          ),
          _stepDot(context, 1, 'Infos', Icons.edit_note_rounded),
        ],
      ),
    );
  }

  Widget _stepDot(BuildContext context, int index, String label, IconData icon) {
    final active = step >= index;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: 36,
          width: 36,
          decoration: BoxDecoration(
            color: active ? AppColors.primary : AppColors.surfaceAltOf(context),
            shape: BoxShape.circle,
          ),
          child: Icon(icon,
              size: 18,
              color: active ? Colors.white : AppColors.textMutedOf(context)),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            color: active ? AppColors.primary : AppColors.textMutedOf(context),
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
        color: AppColors.surfaceOf(context),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: AppColors.shadowOf(context), blurRadius: 10)],
      ),
      child: Row(
        children: [
          _tab(context, _DrawMode.tap, 'Toucher', Icons.touch_app_rounded),
          _tab(context, _DrawMode.gps, 'Marche GPS', Icons.directions_walk_rounded),
        ],
      ),
    );
  }

  Widget _tab(BuildContext context, _DrawMode m, String label, IconData icon) {
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
                  color: selected ? Colors.white : AppColors.textSecondaryOf(context)),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: selected ? Colors.white : AppColors.textSecondaryOf(context),
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

/// Badge de précision GPS affiché pendant la marche. Vert si [accuracyM] <=
/// [thresholdM], orange sinon. `null` = signal en cours d'acquisition.
class _GpsAccuracyBadge extends StatelessWidget {
  const _GpsAccuracyBadge({
    required this.accuracyM,
    required this.thresholdM,
  });

  final double? accuracyM;
  final double thresholdM;

  @override
  Widget build(BuildContext context) {
    final acc = accuracyM;
    final bool acquiring = acc == null;
    final bool ok = !acquiring && acc <= thresholdM;

    final Color bg;
    final Color fg;
    final IconData icon;
    final String label;
    if (acquiring) {
      bg = AppColors.textMutedOf(context).withValues(alpha: 0.15);
      fg = AppColors.textSecondaryOf(context);
      icon = Icons.gps_not_fixed_rounded;
      label = 'GPS…';
    } else if (ok) {
      bg = AppColors.primary.withValues(alpha: 0.15);
      fg = AppColors.primary;
      icon = Icons.gps_fixed_rounded;
      label = '±${acc.round()} m';
    } else {
      bg = AppColors.danger.withValues(alpha: 0.15);
      fg = AppColors.danger;
      icon = Icons.gps_off_rounded;
      label = '±${acc.round()} m';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: fg),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: fg,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
class _FabRound extends StatelessWidget {
  const _FabRound({required this.icon, required this.onTap, this.color});
  final IconData icon;
  final VoidCallback? onTap;
  final Color? color;
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
          child: Icon(icon, color: color ?? AppColors.primary, size: 24),
        ),
      ),
    );
  }
}
