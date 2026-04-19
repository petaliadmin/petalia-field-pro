import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/data/bbch_stages.dart';
import '../../../core/data/crops_catalog.dart';
import '../../recommendations/data/agro_rules_repository.dart';
import '../../recommendations/domain/agro_rule.dart';
import '../../../core/services/audio_service.dart';
import '../../../core/services/sync_service.dart';
import '../../../routes/route_names.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/success_feedback.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/workflow_stepper.dart';
import '../../../theme/app_colors.dart';
import '../../parcels/presentation/parcels_providers.dart';

class ObservationScreen extends ConsumerStatefulWidget {
  const ObservationScreen({super.key, required this.parcelId});
  final String parcelId;

  @override
  ConsumerState<ObservationScreen> createState() => _ObservationScreenState();
}

class _ObservationScreenState extends ConsumerState<ObservationScreen> {
  final _noteCtrl = TextEditingController();
  final _symptoms = <String>{};
  String? _stage;
  double _severity = 0.3;
  final _photos = <XFile>[];

  // Audio note state
  AudioState _audioState = AudioState.idle;
  AudioNote? _audioNote;
  Duration _recordingDuration = Duration.zero;
  Timer? _durationTimer;

  // Quick health state
  String? _quickHealth; // 'good', 'fair', 'bad'
  bool _severityManuallySet = false;

  // Field measurements state
  int? _cropHeightCm;
  int? _plantSpacingCm;
  String? _plantDensity; // 'sparse', 'normal', 'dense'
  String? _irrigationStatus; // 'working', 'attention', 'broken'
  String? _soilMoisture; // 'dry', 'moist', 'soaked'
  String? _groundCover; // 'low', 'medium', 'high', 'full'
  String? _floweringStatus; // 'none', 'partial', 'full'
  final _cropHeightCtrl = TextEditingController();
  final _plantSpacingCtrl = TextEditingController();

  static final _symptomCatalog = [
    ('yellow_leaves', 'Feuilles jaunes', Icons.eco_rounded),
    ('pests', 'Nuisibles', Icons.bug_report_rounded),
    ('drought', 'Sécheresse', Icons.wb_sunny_rounded),
    ('weeds', 'Mauvaises herbes', Icons.grass_rounded),
    ('spots', 'Taches de maladie', Icons.blur_on_rounded),
    ('taches_brunes', 'Taches brunes', Icons.circle_rounded),
    ('taches_noires', 'Taches noires', Icons.circle_outlined),
    ('defoliation', 'Feuilles mangées', Icons.grass_rounded),
    ('feuille_blanche', 'Feuille blanche anormale', Icons.colorize_rounded),
    ('mosaique', 'Mosaïque jaune', Icons.palette_rounded),
    ('nanisme', 'Plante trop petite', Icons.height_rounded),
    ('fletrissement', 'Flétrissement', Icons.water_drop_outlined),
    ('galles', 'Galles/Bosses', Icons.bubble_chart_rounded),
    ('miellat', 'Liquide collant (miellat)', Icons.water_rounded),
    ('mauvaise_levee', 'Mauvaise levée', Icons.warning_rounded),
    ('pas_grain', 'Épi/Gousse vide', Icons.sell_rounded),
    ('fruit_pourri', 'Fruit pourri', Icons.sick_rounded),
  ];

  static const _genericStages = [
    BbchStage(code: 0, id: 'semis', labelFr: 'Semis/Plantation', dasMin: 0),
    BbchStage(code: 9, id: 'germination', labelFr: 'Levée', dasMin: 5),
    BbchStage(code: 19, id: 'vegetative', labelFr: 'Croissance', dasMin: 20),
    BbchStage(code: 51, id: 'flowering', labelFr: 'Floraison', dasMin: 45),
    BbchStage(
      code: 71,
      id: 'fruiting',
      labelFr: 'Formation fruits',
      dasMin: 65,
    ),
    BbchStage(code: 89, id: 'maturation', labelFr: 'Maturité', dasMin: 90),
  ];

  @override
  void dispose() {
    _noteCtrl.dispose();
    _cropHeightCtrl.dispose();
    _plantSpacingCtrl.dispose();
    _durationTimer?.cancel();
    ref.read(audioServiceProvider).dispose();
    super.dispose();
  }

  Future<void> _pickPhoto({required bool camera}) async {
    try {
      if (camera) {
        final x = await ImagePicker().pickImage(
          source: ImageSource.camera,
          imageQuality: 80,
        );
        if (x != null) setState(() => _photos.add(x));
      } else {
        final picks = await ImagePicker().pickMultiImage(imageQuality: 80);
        if (picks.isNotEmpty) {
          setState(() => _photos.addAll(picks));
        }
      }
    } catch (_) {}
  }

  void _removePhoto(int index) {
    setState(() => _photos.removeAt(index));
  }

  void _setQuickHealth(String value, double severity) {
    setState(() {
      _quickHealth = value;
      if (!_severityManuallySet) {
        _severity = severity;
      }
    });
  }

  void _setManualSeverity(double value) {
    setState(() {
      _severity = value;
      _severityManuallySet = true;
    });
  }

  Future<void> _startRecording() async {
    final audio = ref.read(audioServiceProvider);
    final hasPermission = await audio.hasPermission();
    if (!hasPermission) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Permission microphone requise')),
      );
      return;
    }
    await audio.startRecording();
    HapticFeedback.mediumImpact();
    setState(() {
      _audioState = AudioState.recording;
      _recordingDuration = Duration.zero;
    });
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _recordingDuration = audio.elapsed);
    });
  }

  Future<void> _stopRecording() async {
    _durationTimer?.cancel();
    final audio = ref.read(audioServiceProvider);
    final note = await audio.stopRecording();
    HapticFeedback.mediumImpact();
    setState(() {
      _audioState = AudioState.idle;
      _audioNote = note;
    });
  }

  void _deleteAudioNote() {
    if (_audioNote != null && !kIsWeb) {
      final file = File(_audioNote!.path);
      if (file.existsSync()) file.deleteSync();
    }
    setState(() => _audioNote = null);
  }

  Future<void> _save() async {
    final parcel = ref.read(parcelByIdProvider(widget.parcelId));
    if (parcel == null) return;
    final id = const Uuid().v4();
    final data = {
      'id': id,
      'parcelId': parcel.id,
      'at': DateTime.now().toIso8601String(),
      'stage': _stage ?? parcel.growthStage,
      'symptoms': _symptoms.toList(),
      'severity': _severity,
      'note': _noteCtrl.text.trim(),
      'photoPaths': _photos.map((f) => f.path).toList(),
      'audioPath': _audioNote?.path,
      'cropHeightCm': _cropHeightCm,
      'plantSpacingCm': _plantSpacingCm,
      'plantDensity': _plantDensity,
      'irrigationStatus': _irrigationStatus,
      'soilMoisture': _soilMoisture,
      'groundCover': _groundCover,
      'floweringStatus': _floweringStatus,
    };
    await Hive.box(AppConstants.boxObservations).put(id, data);
    ref.read(syncServiceProvider.notifier).enqueue({
      'op': 'create_observation',
      'id': id,
      'parcelId': parcel.id,
    });
    if (!mounted) return;
    SuccessFeedback.show(context, message: 'Visite enregistrée !');
    context.pushReplacement(
      '${Routes.recommendations}/${parcel.id}',
      extra: {
        'symptoms': _symptoms.toList(),
        'severity': _severity,
        'stage': _stage ?? parcel.growthStage,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final parcel = ref.watch(parcelByIdProvider(widget.parcelId));
    if (parcel == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Visite de terrain')),
        body: EmptyState(
          icon: Icons.search_off_rounded,
          title: 'Parcelle introuvable',
          message:
              'Cette parcelle a peut-être été supprimée ou n\'est pas encore synchronisée.',
          action: FilledButton.icon(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back_rounded),
            label: const Text('Retour'),
          ),
        ),
      );
    }
    // BBCH stages filtered by crop, with fallback to generic list.
    final cropDef = CropsCatalog.byLabelFr(parcel.crop);
    final bbchStages = cropDef == null
        ? null
        : BbchCatalog.stagesFor(cropDef.id);

    // Auto-suggest stage from DAS if parcel has a semisDate.
    if (_stage == null && parcel.semisDate != null && cropDef != null) {
      final das = DateTime.now().difference(parcel.semisDate!).inDays;
      final suggested = BbchCatalog.estimateStage(cropId: cropDef.id, das: das);
      if (suggested != null) {
        _stage = suggested.id;
      }
    }

    // Rule engine inline preview — shows matched rules in real time.
    final rulesAsync = ref.watch(agroRulesProvider);
    final matchedRules = rulesAsync.whenOrNull(data: (all) => matchRules(
      allRules: all,
      crop: parcel.crop,
      stage: _stage ?? parcel.growthStage,
      symptoms: _symptoms.toList(),
      severity: _severity,
      region: parcel.region,
    )) ?? const <AgroRule>[];

    return Scaffold(
      appBar: AppBar(title: const Text('Visite de terrain')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          const WorkflowStepper(currentStep: 0),
          const SizedBox(height: 16),
          Text(parcel.name, style: Theme.of(context).textTheme.titleLarge),
          Text(
            '${parcel.crop} · ${parcel.owner}',
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),

          // ---- Photo section ----
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Photos',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    if (_photos.isNotEmpty)
                      Text(
                        '${_photos.length} photo${_photos.length > 1 ? 's' : ''}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                if (_photos.isEmpty)
                  AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.secondary,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      alignment: Alignment.center,
                      child: const Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.add_a_photo_rounded,
                            size: 36,
                            color: AppColors.textMuted,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Aucune photo',
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  SizedBox(
                    height: 120,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _photos.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemBuilder: (context, i) => _PhotoThumbnail(
                        photo: _photos[i],
                        onRemove: () => _removePhoto(i),
                      ),
                    ),
                  ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _pickPhoto(camera: true),
                        icon: const Icon(Icons.camera_alt_rounded),
                        label: const Text('Appareil photo'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _pickPhoto(camera: false),
                        icon: const Icon(Icons.photo_library_rounded),
                        label: const Text('Galerie'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ---- Quick health buttons ----
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Comment va votre culture ?',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                _QuickHealthButton(
                  icon: Icons.check_circle_rounded,
                  label: 'Tout va bien',
                  color: AppColors.success,
                  selected: _quickHealth == 'good',
                  onTap: () => _setQuickHealth('good', 0.1),
                ),
                const SizedBox(height: 10),
                _QuickHealthButton(
                  icon: Icons.warning_rounded,
                  label: 'Quelques problèmes',
                  color: AppColors.warning,
                  selected: _quickHealth == 'fair',
                  onTap: () => _setQuickHealth('fair', 0.5),
                ),
                const SizedBox(height: 10),
                _QuickHealthButton(
                  icon: Icons.error_rounded,
                  label: 'État critique',
                  color: AppColors.danger,
                  selected: _quickHealth == 'bad',
                  onTap: () => _setQuickHealth('bad', 0.9),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ---- Advanced details (expandable) ----
          GlassCard(
            padding: EdgeInsets.zero,
            child: Theme(
              data: Theme.of(
                context,
              ).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 4,
                ),
                childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                leading: const Icon(
                  Icons.tune_rounded,
                  color: AppColors.primary,
                ),
                title: const Text(
                  'Plus de détails (optionnel)',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                ),
                onExpansionChanged: (_) {},
                children: [
                  // Growth stage dropdown
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Où en est votre culture ?',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: _stage ?? parcel.growthStage,
                    items: (bbchStages ?? _genericStages)
                        .map(
                          (s) => DropdownMenuItem(
                            value: s.id,
                            child: Text(s.labelFr),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => _stage = v),
                  ),
                  const SizedBox(height: 20),

                  // Symptom cards grid
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Que voyez-vous ?',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                  const SizedBox(height: 10),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 2.0,
                    children: [
                      for (final s in _symptomCatalog)
                        _SymptomCard(
                          icon: s.$3,
                          label: s.$2,
                          selected: _symptoms.contains(s.$1),
                          onTap: () {
                            setState(() {
                              _symptoms.contains(s.$1)
                                  ? _symptoms.remove(s.$1)
                                  : _symptoms.add(s.$1);
                            });
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Severity 3-button picker
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'C\'est grave ?',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _SeverityButton(
                          label: 'Léger',
                          icon: Icons.sentiment_satisfied_rounded,
                          color: AppColors.success,
                          selected: _severityManuallySet && _severity == 0.2,
                          onTap: () => _setManualSeverity(0.2),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _SeverityButton(
                          label: 'Moyen',
                          icon: Icons.sentiment_neutral_rounded,
                          color: AppColors.warning,
                          selected: _severityManuallySet && _severity == 0.5,
                          onTap: () => _setManualSeverity(0.5),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _SeverityButton(
                          label: 'Grave',
                          icon: Icons.sentiment_very_dissatisfied_rounded,
                          color: AppColors.danger,
                          selected: _severityManuallySet && _severity == 0.8,
                          onTap: () => _setManualSeverity(0.8),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // ---- Field measurements (expandable) ----
          GlassCard(
            padding: EdgeInsets.zero,
            child: Theme(
              data: Theme.of(
                context,
              ).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 4,
                ),
                childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                leading: const Icon(
                  Icons.straighten_rounded,
                  color: AppColors.primary,
                ),
                title: const Text(
                  'Mesures de terrain (optionnel)',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                ),
                children: [
                  // --- Sous-groupe : Mesures de la culture ---
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Mesures de la culture',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _PresetRow(
                    label: 'Taille des cultures',
                    icon: Icons.height_rounded,
                    presets: const [50, 100, 150, 200],
                    value: _cropHeightCm,
                    controller: _cropHeightCtrl,
                    unit: 'cm',
                    onChanged: (v) => setState(() => _cropHeightCm = v),
                  ),
                  const SizedBox(height: 16),
                  _PresetRow(
                    label: 'Espacement des plants',
                    icon: Icons.swap_horiz_rounded,
                    presets: const [20, 30, 50, 80],
                    value: _plantSpacingCm,
                    controller: _plantSpacingCtrl,
                    unit: 'cm',
                    onChanged: (v) => setState(() => _plantSpacingCm = v),
                  ),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Row(
                      children: [
                        const Icon(
                          Icons.grid_view_rounded,
                          size: 18,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Densité des plants',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  _ToggleRow(
                    options: const [
                      _ToggleOption(
                        key: 'sparse',
                        label: 'Clairsemé',
                        icon: Icons.scatter_plot_rounded,
                        color: AppColors.warning,
                      ),
                      _ToggleOption(
                        key: 'normal',
                        label: 'Normal',
                        icon: Icons.grid_view_rounded,
                        color: AppColors.success,
                      ),
                      _ToggleOption(
                        key: 'dense',
                        label: 'Dense',
                        icon: Icons.view_comfy_rounded,
                        color: AppColors.info,
                      ),
                    ],
                    selected: _plantDensity,
                    onChanged: (v) => setState(() => _plantDensity = v),
                  ),
                  const SizedBox(height: 20),

                  // --- Sous-groupe : Phénologie ---
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Phénologie',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Row(
                      children: [
                        const Icon(
                          Icons.local_florist_rounded,
                          size: 18,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Présence de fleurs/fruits',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  _ToggleRow(
                    options: [
                      _ToggleOption(
                        key: 'none',
                        label: 'Non',
                        icon: Icons.do_not_disturb_rounded,
                        color: AppColors.textMuted,
                      ),
                      const _ToggleOption(
                        key: 'partial',
                        label: 'Partiel',
                        icon: Icons.local_florist_rounded,
                        color: AppColors.warning,
                      ),
                      const _ToggleOption(
                        key: 'full',
                        label: 'Oui',
                        icon: Icons.local_florist_rounded,
                        color: AppColors.success,
                      ),
                    ],
                    selected: _floweringStatus,
                    onChanged: (v) => setState(() => _floweringStatus = v),
                  ),
                  const SizedBox(height: 20),

                  // --- Sous-groupe : Sol et irrigation ---
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Sol et irrigation',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Row(
                      children: [
                        const Icon(
                          Icons.water_drop_rounded,
                          size: 18,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'État de l\'irrigation',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  _ToggleRow(
                    options: const [
                      _ToggleOption(
                        key: 'working',
                        label: 'Fonctionnel',
                        icon: Icons.check_circle_rounded,
                        color: AppColors.success,
                      ),
                      _ToggleOption(
                        key: 'attention',
                        label: 'À surveiller',
                        icon: Icons.warning_rounded,
                        color: AppColors.warning,
                      ),
                      _ToggleOption(
                        key: 'broken',
                        label: 'En panne',
                        icon: Icons.error_rounded,
                        color: AppColors.danger,
                      ),
                    ],
                    selected: _irrigationStatus,
                    onChanged: (v) => setState(() => _irrigationStatus = v),
                  ),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Row(
                      children: [
                        const Icon(
                          Icons.opacity_rounded,
                          size: 18,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Humidité du sol',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  _ToggleRow(
                    options: const [
                      _ToggleOption(
                        key: 'dry',
                        label: 'Sec',
                        icon: Icons.wb_sunny_rounded,
                        color: AppColors.warning,
                      ),
                      _ToggleOption(
                        key: 'moist',
                        label: 'Humide',
                        icon: Icons.water_drop_rounded,
                        color: AppColors.success,
                      ),
                      _ToggleOption(
                        key: 'soaked',
                        label: 'Trempé',
                        icon: Icons.pool_rounded,
                        color: AppColors.info,
                      ),
                    ],
                    selected: _soilMoisture,
                    onChanged: (v) => setState(() => _soilMoisture = v),
                  ),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Row(
                      children: [
                        const Icon(
                          Icons.landscape_rounded,
                          size: 18,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Couverture du sol',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 2.0,
                    children: [
                      _CoverCard(
                        label: '< 25%',
                        icon: Icons.circle_outlined,
                        selected: _groundCover == 'low',
                        onTap: () => setState(
                          () => _groundCover = _groundCover == 'low'
                              ? null
                              : 'low',
                        ),
                      ),
                      _CoverCard(
                        label: '25 – 50%',
                        icon: Icons.pie_chart_outline_rounded,
                        selected: _groundCover == 'medium',
                        onTap: () => setState(
                          () => _groundCover = _groundCover == 'medium'
                              ? null
                              : 'medium',
                        ),
                      ),
                      _CoverCard(
                        label: '50 – 75%',
                        icon: Icons.pie_chart_rounded,
                        selected: _groundCover == 'high',
                        onTap: () => setState(
                          () => _groundCover = _groundCover == 'high'
                              ? null
                              : 'high',
                        ),
                      ),
                      _CoverCard(
                        label: '> 75%',
                        icon: Icons.circle_rounded,
                        selected: _groundCover == 'full',
                        onTap: () => setState(
                          () => _groundCover = _groundCover == 'full'
                              ? null
                              : 'full',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // ---- Notes section (unchanged) ----
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Notes', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                TextField(
                  controller: _noteCtrl,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    hintText: 'Décrivez ce que vous voyez...',
                  ),
                ),
                const SizedBox(height: 10),
                // Audio note recorder
                if (_audioNote != null && _audioState == AudioState.idle)
                  _AudioNoteCard(note: _audioNote!, onDelete: _deleteAudioNote)
                else if (_audioState == AudioState.recording)
                  _RecordingIndicator(
                    duration: _recordingDuration,
                    onStop: _stopRecording,
                  )
                else
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _startRecording,
                          icon: const Icon(Icons.mic_rounded),
                          label: const Text('Note vocale'),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ---- Agro rules preview ----
          if (matchedRules.isNotEmpty)
            _RulesPreviewCard(rules: matchedRules),
          const SizedBox(height: 20),

          // ---- Save button (unchanged) ----
          PrimaryButton(
            label: 'Enregistrer la visite',
            icon: Icons.check_rounded,
            onPressed: _save,
          ),
          const SizedBox(height: 10),

          // ---- Checklist button (unchanged) ----
          OutlinedButton.icon(
            onPressed: () => context.push('${Routes.checklist}/${parcel.id}'),
            icon: const Icon(Icons.checklist_rounded),
            label: const Text('Ma liste de vérification'),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Photo thumbnail with remove button
// ---------------------------------------------------------------------------
class _PhotoThumbnail extends StatelessWidget {
  const _PhotoThumbnail({required this.photo, required this.onRemove});
  final XFile photo;
  final VoidCallback onRemove;

  Widget _buildImage() {
    const size = 120.0;
    if (kIsWeb) {
      // On web, XFile.path is a blob URL usable by Image.network.
      return Image.network(
        photo.path,
        height: size,
        width: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _placeholder(size),
      );
    }
    return Image.file(
      File(photo.path),
      height: size,
      width: size,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => _placeholder(size),
    );
  }

  Widget _placeholder(double size) => Container(
    height: size,
    width: size,
    color: AppColors.secondary,
    alignment: Alignment.center,
    child: const Icon(Icons.broken_image_rounded, color: AppColors.textMuted),
  );

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: _buildImage(),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              height: 26,
              width: 26,
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.close_rounded,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Quick health big buttons
// ---------------------------------------------------------------------------
class _QuickHealthButton extends StatelessWidget {
  const _QuickHealthButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 64,
      child: Material(
        color: selected ? color : color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Icon(icon, size: 28, color: selected ? Colors.white : color),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: selected ? Colors.white : color,
                    ),
                  ),
                ),
                if (selected)
                  const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Symptom illustrated card for the grid
// ---------------------------------------------------------------------------
class _SymptomCard extends StatelessWidget {
  const _SymptomCard({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: selected
            ? AppColors.primary.withValues(alpha: 0.08)
            : AppColors.secondary,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: selected ? AppColors.primary : Colors.transparent,
          width: 2,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 28,
                color: selected ? AppColors.primary : AppColors.textSecondary,
              ),
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? AppColors.primary : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Severity 3-button picker
// ---------------------------------------------------------------------------
class _SeverityButton extends StatelessWidget {
  const _SeverityButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: selected ? color : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color, width: 2),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              children: [
                Icon(icon, size: 24, color: selected ? Colors.white : color),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: selected ? Colors.white : color,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Recording indicator
// ---------------------------------------------------------------------------
class _RecordingIndicator extends StatelessWidget {
  const _RecordingIndicator({required this.duration, required this.onStop});

  final Duration duration;
  final VoidCallback onStop;

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            height: 12,
            width: 12,
            decoration: const BoxDecoration(
              color: AppColors.danger,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Enregistrement  ${_formatDuration(duration)}',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: AppColors.danger,
            ),
          ),
          const Spacer(),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.danger,
              minimumSize: const Size(0, 36),
              padding: const EdgeInsets.symmetric(horizontal: 14),
            ),
            onPressed: onStop,
            icon: const Icon(Icons.stop_rounded, size: 18),
            label: const Text('Arrêter'),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Audio note card — WhatsApp-style player (play/pause, seek bar, waveform)
// ---------------------------------------------------------------------------
class _AudioNoteCard extends StatefulWidget {
  const _AudioNoteCard({required this.note, required this.onDelete});

  final AudioNote note;
  final VoidCallback onDelete;

  @override
  State<_AudioNoteCard> createState() => _AudioNoteCardState();
}

class _AudioNoteCardState extends State<_AudioNoteCard> {
  late final AudioPlaybackController _ctrl;
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _ctrl = AudioPlaybackController();
    _duration = widget.note.duration;
    _ctrl.stateStream.listen((v) {
      if (mounted) setState(() => _isPlaying = v == PlayerState.playing);
    });
    _ctrl.positionStream.listen((p) {
      if (mounted) setState(() => _position = p);
    });
    _ctrl.durationStream.listen((d) {
      if (mounted && d > Duration.zero) setState(() => _duration = d);
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _toggle() async {
    if (_isPlaying) {
      _ctrl.pause();
    } else {
      if (_position > Duration.zero && _position < _duration) {
        await _ctrl.resume();
      } else {
        await _ctrl.play(
          widget.note.path,
          fallbackDuration: widget.note.duration,
        );
      }
    }
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final total = _duration.inMilliseconds == 0
        ? widget.note.duration.inMilliseconds.toDouble().clamp(
            1,
            double.infinity,
          )
        : _duration.inMilliseconds.toDouble();
    final current = _position.inMilliseconds.toDouble().clamp(0.0, total);
    final shown = _isPlaying || _position > Duration.zero
        ? _position
        : _duration;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          // Play / Pause
          Material(
            color: AppColors.primary,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: _toggle,
              child: SizedBox(
                height: 42,
                width: 42,
                child: Icon(
                  _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _WaveformProgress(
                  progress: total == 0 ? 0 : current / total,
                  isPlaying: _isPlaying,
                  onSeek: (fraction) {
                    final target = Duration(
                      milliseconds: (total * fraction).round(),
                    );
                    _ctrl.seek(target);
                  },
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.mic_rounded,
                      size: 12,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _fmt(shown),
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: widget.onDelete,
            icon: const Icon(Icons.delete_outline_rounded),
            color: AppColors.danger,
            iconSize: 20,
            tooltip: 'Supprimer',
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// WhatsApp-style waveform with progress + tap-to-seek
// ---------------------------------------------------------------------------
class _WaveformProgress extends StatelessWidget {
  const _WaveformProgress({
    required this.progress,
    required this.isPlaying,
    required this.onSeek,
  });

  final double progress; // 0..1
  final bool isPlaying;
  final ValueChanged<double> onSeek;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (d) {
            final f = (d.localPosition.dx / c.maxWidth).clamp(0.0, 1.0);
            onSeek(f);
          },
          onHorizontalDragUpdate: (d) {
            final f = (d.localPosition.dx / c.maxWidth).clamp(0.0, 1.0);
            onSeek(f);
          },
          child: SizedBox(
            height: 28,
            width: double.infinity,
            child: CustomPaint(
              painter: _WaveformPainter(
                progress: progress.clamp(0.0, 1.0),
                activeColor: AppColors.primary,
                inactiveColor: AppColors.primary.withValues(alpha: 0.25),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _WaveformPainter extends CustomPainter {
  _WaveformPainter({
    required this.progress,
    required this.activeColor,
    required this.inactiveColor,
  });

  final double progress;
  final Color activeColor;
  final Color inactiveColor;

  // Static seed so the waveform shape stays consistent between rebuilds.
  static const _bars = <double>[
    0.30,
    0.55,
    0.75,
    0.45,
    0.85,
    0.65,
    0.40,
    0.70,
    0.90,
    0.50,
    0.35,
    0.60,
    0.80,
    0.55,
    0.45,
    0.75,
    0.95,
    0.60,
    0.40,
    0.70,
    0.50,
    0.85,
    0.65,
    0.35,
    0.55,
    0.75,
    0.45,
    0.60,
    0.80,
    0.50,
    0.40,
    0.70,
    0.90,
    0.55,
    0.35,
    0.65,
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final barCount = _bars.length;
    final gap = 2.0;
    final barWidth = (size.width - gap * (barCount - 1)) / barCount;
    final centerY = size.height / 2;
    final activeBars = (progress * barCount).floor();

    for (var i = 0; i < barCount; i++) {
      final h = _bars[i] * size.height;
      final x = i * (barWidth + gap);
      final paint = Paint()
        ..color = i < activeBars ? activeColor : inactiveColor
        ..strokeCap = StrokeCap.round
        ..strokeWidth = barWidth;
      canvas.drawLine(
        Offset(x + barWidth / 2, centerY - h / 2),
        Offset(x + barWidth / 2, centerY + h / 2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WaveformPainter old) =>
      old.progress != progress ||
      old.activeColor != activeColor ||
      old.inactiveColor != inactiveColor;
}

// ---------------------------------------------------------------------------
// Rules preview card — shows matched agro rules inline during observation
// ---------------------------------------------------------------------------
class _RulesPreviewCard extends StatelessWidget {
  const _RulesPreviewCard({required this.rules});
  final List<AgroRule> rules;

  @override
  Widget build(BuildContext context) {
    // Show at most 3 rules in the preview.
    final shown = rules.take(3).toList();
    return GlassCard(
      gradient: const LinearGradient(
        colors: [AppColors.accent, AppColors.accentDark],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 34,
                width: 34,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '${rules.length} conseil${rules.length > 1 ? 's' : ''} disponible${rules.length > 1 ? 's' : ''}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (final r in shown)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    r.recommendation.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    r.diagnosis,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          if (rules.length > 3)
            Text(
              '+ ${rules.length - 3} autre${rules.length - 3 > 1 ? 's' : ''} — visible apres enregistrement',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Preset row with quick-pick buttons + compact text field
// ---------------------------------------------------------------------------
class _PresetRow extends StatelessWidget {
  const _PresetRow({
    required this.label,
    required this.icon,
    required this.presets,
    required this.value,
    required this.onChanged,
    required this.controller,
    required this.unit,
  });

  final String label;
  final IconData icon;
  final List<int> presets;
  final int? value;
  final ValueChanged<int?> onChanged;
  final TextEditingController controller;
  final String unit;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            for (int i = 0; i < presets.length; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              Expanded(
                child: _PresetChip(
                  label: '${presets[i]}',
                  unit: unit,
                  selected: value == presets[i],
                  onTap: () {
                    if (value == presets[i]) {
                      onChanged(null);
                      controller.clear();
                    } else {
                      onChanged(presets[i]);
                      controller.text = '${presets[i]}';
                    }
                  },
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 48,
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: 'Autre valeur',
              suffixText: unit,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
              isDense: true,
            ),
            onChanged: (v) {
              final n = int.tryParse(v.trim());
              onChanged(n);
            },
          ),
        ),
      ],
    );
  }
}

class _PresetChip extends StatelessWidget {
  const _PresetChip({
    required this.label,
    required this.unit,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String unit;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.secondary,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.divider,
            width: 1.5,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          '$label $unit',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Reusable toggle row (3 or 4 options)
// ---------------------------------------------------------------------------
class _ToggleOption {
  const _ToggleOption({
    required this.key,
    required this.label,
    required this.icon,
    required this.color,
  });
  final String key;
  final String label;
  final IconData icon;
  final Color color;
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  final List<_ToggleOption> options;
  final String? selected;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (int i = 0; i < options.length; i++) ...[
          if (i > 0) const SizedBox(width: 10),
          Expanded(child: _buildButton(options[i])),
        ],
      ],
    );
  }

  Widget _buildButton(_ToggleOption opt) {
    final isSelected = selected == opt.key;
    return GestureDetector(
      onTap: () => onChanged(isSelected ? null : opt.key),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected ? opt.color : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: opt.color, width: 2),
        ),
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          children: [
            Icon(
              opt.icon,
              size: 24,
              color: isSelected ? Colors.white : opt.color,
            ),
            const SizedBox(height: 4),
            Text(
              opt.label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isSelected ? Colors.white : opt.color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Ground cover card (2x2 grid item) — reuses _SymptomCard pattern
// ---------------------------------------------------------------------------
class _CoverCard extends StatelessWidget {
  const _CoverCard({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: selected
            ? AppColors.primary.withValues(alpha: 0.08)
            : AppColors.secondary,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: selected ? AppColors.primary : Colors.transparent,
          width: 2,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 24,
                color: selected ? AppColors.primary : AppColors.textSecondary,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? AppColors.primary : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
