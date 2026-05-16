import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image/image.dart' as img;
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
import '../../../core/services/credit_service.dart';
import '../../../core/utils/messenger_utils.dart';
import '../../../core/services/ai_diagnostic_service.dart';
import '../../../core/services/audio_service.dart';
import '../../../core/services/location_service.dart';
import '../../../core/services/symptoms_catalog_service.dart';
import '../../../core/services/sync_service.dart';
import '../../../core/services/transcription_service.dart';
import '../../../core/utils/exif_writer.dart';
import '../../../routes/route_names.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/workflow_stepper.dart';
import '../../../theme/app_colors.dart';
import '../../parcels/presentation/parcels_providers.dart';
import '../../dashboard/presentation/tour_provider.dart';

class ObservationScreen extends ConsumerStatefulWidget {
  const ObservationScreen({super.key, required this.parcelId});
  final String parcelId;

  @override
  ConsumerState<ObservationScreen> createState() => _ObservationScreenState();
}

class _ObservationScreenState extends ConsumerState<ObservationScreen> {
  final _noteCtrl = TextEditingController();
  bool _isListening = false;
  bool _saving = false;
  final _symptoms = <String>{};
  String? _stage;
  double _severity = 0.0;
  final _photos = <XFile>[];
  bool _isAnalyzing = false;

  // Audio notes state
  AudioState _audioState = AudioState.idle;
  final List<AudioNote> _audioNotes = [];
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
  int? _salinityIndex; // 0..4
  String? _recentInput; // 'fertilizer', 'pesticide', 'organic', 'none'
  final _inputDosageCtrl = TextEditingController();
  final _cropHeightCtrl = TextEditingController();
  final _plantSpacingCtrl = TextEditingController();

  List<SymptomEntry> _symptomCatalog = const [];

  static const _genericStages = [
    BbchStage(code: 0, id: 'semis', labelFr: 'Semis/Plantation', dasMin: 0),
    BbchStage(code: 9, id: 'germination', labelFr: 'Levée', dasMin: 5),
    BbchStage(code: 19, id: 'vegetative', labelFr: 'Croissance', dasMin: 20),
    BbchStage(code: 51, id: 'flowering', labelFr: 'Floraison', dasMin: 45),
    BbchStage(code: 71, id: 'fruiting', labelFr: 'Formation fruits', dasMin: 65),
    BbchStage(code: 89, id: 'maturation', labelFr: 'Maturité', dasMin: 90),
  ];

  Locale? _loadedLocale;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final locale = Localizations.localeOf(context);
    if (_loadedLocale != locale) {
      _loadedLocale = locale;
      SymptomsCatalogService.load(locale).then((entries) {
        if (mounted) setState(() => _symptomCatalog = entries);
      });
    }
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    _cropHeightCtrl.dispose();
    _plantSpacingCtrl.dispose();
    _inputDosageCtrl.dispose();
    _durationTimer?.cancel();
    ref.read(audioServiceProvider).dispose();
    super.dispose();
  }

  Future<void> _pickPhoto({required bool camera}) async {
    try {
      if (camera) {
        final locFuture = ref.read(locationServiceProvider).current();
        final x = await ImagePicker().pickImage(source: ImageSource.camera, imageQuality: 80);
        if (x != null) {
          final loc = await locFuture;
          if (loc != null && !kIsWeb) {
            try { await ExifWriter.writeGps(file: File(x.path), latitude: loc.latitude, longitude: loc.longitude); } catch (_) {}
          }
          if (mounted) {
            if (!kIsWeb) {
              final bytes = await x.readAsBytes();
              final decoded = img.decodeImage(bytes);
              if (decoded != null && (decoded.width > 1280 || decoded.height > 1280)) {
                final resized = img.copyResize(decoded, width: decoded.width > decoded.height ? 1280 : null, height: decoded.height >= decoded.width ? 1280 : null);
                await File(x.path).writeAsBytes(img.encodeJpg(resized, quality: 85));
              }
            }
            setState(() => _photos.add(x));
          }
        }
      } else {
        final picks = await ImagePicker().pickMultiImage(imageQuality: 80);
        if (picks.isNotEmpty) {
          setState(() => _photos.addAll(picks));
        }
      }
    } catch (_) {}
  }

  void _removePhoto(int index) => setState(() => _photos.removeAt(index));

  String? _pendingRequestId;

  Future<void> _runAiDiagnostic() async {
    if (_photos.isEmpty || _isAnalyzing || _pendingRequestId != null) return;
    
    final creditService = ref.read(creditServiceProvider.notifier);
    if (creditService.credits < CreditService.costAiDiagnostic) {
      MessengerUtils.showInfo('Crédits insuffisants.');
      context.push(Routes.wallet);
      return;
    }

    final parcel = ref.read(parcelByIdProvider(widget.parcelId));
    if (parcel == null) return;

    setState(() => _isAnalyzing = true);
    try {
      await creditService.useCredits(CreditService.costAiDiagnostic);
      final ai = ref.read(aiDiagnosticServiceProvider);
      
      Uint8List? pBytes;
      if (kIsWeb) pBytes = await _photos.last.readAsBytes();

      final requestId = await ai.submitRequest(
        parcelId: parcel.id,
        ownerName: parcel.owner,
        ownerPhone: parcel.phone ?? '',
        photoPath: _photos.last.path,
        photoBytes: pBytes,
      );

      if (mounted) {
        setState(() {
          _pendingRequestId = requestId;
          _isAnalyzing = false;
        });
        MessengerUtils.showSuccess('Demande de diagnostic envoyée à l\'expert.');
      }
    } catch (e) { 
      if (mounted) setState(() => _isAnalyzing = false); 
      MessengerUtils.showError('Erreur d\'envoi : $e');
    }
  }

  void _setQuickHealth(String value, double severity) {
    setState(() { _quickHealth = value; if (!_severityManuallySet) _severity = severity; });
  }

  void _setManualSeverity(double value) => setState(() { _severity = value; _severityManuallySet = true; });

  Future<void> _toggleListening() async {
    final stt = ref.read(transcriptionServiceProvider);
    if (_isListening) { stt.stopListening(); setState(() => _isListening = false); } 
    else {
      final available = await stt.init();
      if (available && mounted) {
        setState(() => _isListening = true);
        stt.startListening(onResult: (text) { if (mounted) setState(() { _noteCtrl.text = text; _isListening = false; }); });
      }
    }
  }

  Future<void> _startRecording() async {
    final audio = ref.read(audioServiceProvider);
    if (!(await audio.hasPermission())) return;
    await audio.startRecording();
    HapticFeedback.mediumImpact();
    setState(() { _audioState = AudioState.recording; _recordingDuration = Duration.zero; });
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) { if (mounted) setState(() => _recordingDuration = audio.elapsed); });
  }

  Future<void> _stopRecording() async {
    _durationTimer?.cancel();
    final note = await ref.read(audioServiceProvider).stopRecording();
    HapticFeedback.mediumImpact();
    setState(() { _audioState = AudioState.idle; if (note != null) _audioNotes.add(note); });
  }

  void _deleteAudioNote(int index) {
    if (index >= 0 && index < _audioNotes.length) {
      if (!kIsWeb) { final file = File(_audioNotes[index].path); if (file.existsSync()) file.deleteSync(); }
      setState(() => _audioNotes.removeAt(index));
    }
  }

  bool get _hasEvidence => _photos.isNotEmpty || _audioNotes.isNotEmpty;

  Future<void> _save() async {
    if (_saving || !_hasEvidence) return;
    final parcel = ref.read(parcelByIdProvider(widget.parcelId));
    if (parcel == null) return;
    setState(() => _saving = true);
    try {
      final id = const Uuid().v4();
      final photoBytes = <Uint8List>[];
      if (kIsWeb) { for (final f in _photos) photoBytes.add(await f.readAsBytes()); }
      final data = {
        'id': id, 'parcelId': parcel.id, 'at': DateTime.now().toIso8601String(),
        'stage': _stage ?? parcel.growthStage, 'symptoms': _symptoms.toList(), 'severity': _severity,
        'note': _noteCtrl.text.trim(), 'photoPaths': _photos.map((f) => f.path).toList(), 'photoBytes': photoBytes,
        'audioPaths': _audioNotes.map((n) => n.path).toList(), 'cropHeightCm': _cropHeightCm,
        'plantSpacingCm': _plantSpacingCm, 'plantDensity': _plantDensity, 'irrigationStatus': _irrigationStatus,
        'soilMoisture': _soilMoisture, 'groundCover': _groundCover, 'floweringStatus': _floweringStatus,
        'salinityIndex': _salinityIndex, 'recentInput': _recentInput, 'inputDosage': _inputDosageCtrl.text,
      };
      await Hive.box(AppConstants.boxObservations).put(id, data);
      await ref.read(syncServiceProvider.notifier).enqueue({'op': 'create_observation', 'id': id, 'parcelId': parcel.id});
      
      // Update tour progress if active
      ref.read(tourProvider.notifier).markVisited(parcel.id);

      HapticFeedback.mediumImpact();
      MessengerUtils.showSuccess('Visite enregistrée !');
      if (mounted) context.go('${Routes.recommendations}/${parcel.id}', extra: {'symptoms': _symptoms.toList(), 'severity': _severity, 'stage': _stage ?? parcel.growthStage});
    } catch (e) { MessengerUtils.showError('Erreur : $e'); } 
    finally { if (mounted) setState(() => _saving = false); }
  }

  @override
  Widget build(BuildContext context) {
    final parcel = ref.watch(parcelByIdProvider(widget.parcelId));
    if (parcel == null) {
      return Scaffold(appBar: AppBar(title: const Text('Visite')), body: EmptyState(icon: Icons.search_off_rounded, title: 'Parcelle introuvable', message: 'Introuvable.', action: FilledButton.icon(onPressed: () => context.pop(), icon: const Icon(Icons.arrow_back_rounded), label: const Text('Retour'))));
    }
    final rulesAsync = ref.watch(agroRulesProvider);
    final matchedRules = rulesAsync.whenOrNull(data: (all) => matchRules(allRules: all, crop: parcel.crop, stage: _stage ?? parcel.growthStage, symptoms: _symptoms.toList(), severity: _severity, region: parcel.region)) ?? const <AgroRule>[];

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Visite de terrain'),
          bottom: TabBar(
            isScrollable: false,
            indicatorColor: AppColors.primary,
            indicatorWeight: 3,
            labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, letterSpacing: 0.5),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            tabs: const [
              Tab(text: 'SANTÉ', icon: Icon(Icons.health_and_safety_rounded, size: 20)),
              Tab(text: 'RESSOURCES', icon: Icon(Icons.water_drop_rounded, size: 20)),
              Tab(text: 'PRATIQUES', icon: Icon(Icons.agriculture_rounded, size: 20)),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildHealthTab(parcel, matchedRules),
            _buildResourcesTab(parcel),
            _buildPracticesTab(parcel),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthTab(dynamic parcel, List<AgroRule> matchedRules) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        const WorkflowStepper(currentStep: 0),
        const SizedBox(height: 16),
        Text(parcel.name, style: Theme.of(context).textTheme.titleLarge),
        Text('Diagnostic de santé actuel', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.7), fontSize: 14)),
        const SizedBox(height: 16),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Photos de terrain', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              if (_photos.isEmpty) _buildPhotoPlaceholder() else _buildPhotoList(),
              const SizedBox(height: 12),
              _buildPhotoButtons(),
              if (_photos.isNotEmpty) ...[const SizedBox(height: 12), _buildAiDiagnosticButton()],
            ],
          ),
        ),
        const SizedBox(height: 12),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('État général', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              _QuickHealthButton(icon: Icons.check_circle_rounded, label: 'Tout va bien', color: AppColors.success, selected: _quickHealth == 'good', onTap: () => _setQuickHealth('good', 0.1)),
              const SizedBox(height: 10),
              _QuickHealthButton(icon: Icons.warning_rounded, label: 'Quelques problèmes', color: AppColors.warning, selected: _quickHealth == 'fair', onTap: () => _setQuickHealth('fair', 0.5)),
              const SizedBox(height: 10),
              _QuickHealthButton(icon: Icons.error_rounded, label: 'État critique', color: AppColors.danger, selected: _quickHealth == 'bad', onTap: () => _setQuickHealth('bad', 0.9)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Diagnostic détaillé', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              _buildSymptomGrid(),
              const SizedBox(height: 20),
              Text('Gravité de l\'infestation', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 10),
              _buildSeverityPicker(),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (matchedRules.isNotEmpty) _RulesPreviewCard(rules: matchedRules),
      ],
    );
  }

  Widget _buildResourcesTab(dynamic parcel) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Irrigation & Eau', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              _buildIrrigationToggle(),
              const SizedBox(height: 16),
              Text('Humidité du sol', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              _buildMoistureToggle(),
            ],
          ),
        ),
        const SizedBox(height: 12),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('État de la parcelle', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              Text('Indice de Salinité (Visuel)', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 4),
              Text('Recherche de croûtes blanches ou de brûlures.', style: TextStyle(fontSize: 12, color: AppColors.textMutedOf(context))),
              const SizedBox(height: 10),
              _SalinityPicker(value: _salinityIndex, onChanged: (v) => setState(() => _salinityIndex = v)),
              const SizedBox(height: 20),
              Text('Couverture du sol (%)', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 10),
              _buildGroundCoverGrid(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPracticesTab(dynamic parcel) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
      children: [
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Phénologie & Croissance', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              _buildStageDropdown(parcel),
              const SizedBox(height: 20),
              _PresetRow(label: 'Taille des cultures', icon: Icons.height_rounded, presets: const [50, 100, 150, 200], value: _cropHeightCm, controller: _cropHeightCtrl, unit: 'cm', onChanged: (v) => setState(() => _cropHeightCm = v)),
              const SizedBox(height: 16),
              _PresetRow(label: 'Espacement des plants', icon: Icons.swap_horiz_rounded, presets: const [20, 30, 50, 80], value: _plantSpacingCm, controller: _plantSpacingCtrl, unit: 'cm', onChanged: (v) => setState(() => _plantSpacingCm = v)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Derniers Intrants / Traitements', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              _ToggleRow(
                options: const [
                  _ToggleOption(key: 'fertilizer', label: 'Engrais', icon: Icons.science_rounded, color: AppColors.info),
                  _ToggleOption(key: 'pesticide', label: 'Pesticide', icon: Icons.bug_report_rounded, color: AppColors.danger),
                  _ToggleOption(key: 'organic', label: 'Organique', icon: Icons.eco_rounded, color: AppColors.success),
                  _ToggleOption(key: 'none', label: 'Aucun', icon: Icons.block_rounded, color: Colors.grey),
                ],
                selected: _recentInput,
                onChanged: (v) => setState(() => _recentInput = v),
              ),
              if (_recentInput != null && _recentInput != 'none') ...[
                const SizedBox(height: 16),
                TextField(controller: _inputDosageCtrl, decoration: const InputDecoration(hintText: 'Dosage ou produit utilisé...', prefixIcon: Icon(Icons.edit_note_rounded))),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Notes de terrain', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              _buildNoteField(),
              const SizedBox(height: 10),
              _buildAudioSection(),
            ],
          ),
        ),
        const SizedBox(height: 24),
        PrimaryButton(label: 'Finaliser la visite', icon: Icons.check_circle_rounded, loading: _saving, onPressed: _hasEvidence ? _save : null),
        if (!_hasEvidence) Padding(padding: const EdgeInsets.only(top: 8), child: Text('Capturez une photo ou une note vocale pour valider.', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: AppColors.danger.withValues(alpha: 0.7)))),
      ],
    );
  }

  Widget _buildPhotoPlaceholder() => AspectRatio(aspectRatio: 16 / 9, child: Container(decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainer, borderRadius: BorderRadius.circular(16)), alignment: Alignment.center, child: Icon(Icons.add_a_photo_rounded, size: 40, color: AppColors.textMutedOf(context))));
  Widget _buildPhotoList() => SizedBox(height: 120, child: ListView.separated(scrollDirection: Axis.horizontal, itemCount: _photos.length, separatorBuilder: (_, __) => const SizedBox(width: 10), itemBuilder: (context, i) => _PhotoThumbnail(photo: _photos[i], onRemove: () => _removePhoto(i))));
  Widget _buildPhotoButtons() => Row(children: [Expanded(child: OutlinedButton.icon(onPressed: () => _pickPhoto(camera: true), icon: const Icon(Icons.camera_alt_rounded), label: const Text('Caméra'))), const SizedBox(width: 10), Expanded(child: OutlinedButton.icon(onPressed: () => _pickPhoto(camera: false), icon: const Icon(Icons.photo_library_rounded), label: const Text('Galerie')))]);
  Widget _buildAiDiagnosticButton() => SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: (_isAnalyzing || _pendingRequestId != null) ? null : _runAiDiagnostic,
          icon: _isAnalyzing
              ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : Icon(_pendingRequestId != null ? Icons.hourglass_empty_rounded : Icons.auto_awesome_rounded, color: AppColors.accent),
          label: Text(_pendingRequestId != null ? 'Demande envoyée' : 'Diagnostic Expert (Claude)'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.accent,
            side: const BorderSide(color: AppColors.accent),
            disabledForegroundColor: AppColors.accent.withValues(alpha: 0.5),
          ),
        ),
      );
  Widget _buildSymptomGrid() => GridView.count(crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: 2.2, children: [for (final s in _symptomCatalog) _SymptomCard(icon: s.icon, label: s.label, selected: _symptoms.contains(s.id), onTap: () => setState(() => _symptoms.contains(s.id) ? _symptoms.remove(s.id) : _symptoms.add(s.id)))]);
  Widget _buildSeverityPicker() => Row(children: [Expanded(child: _SeverityButton(label: 'Léger', icon: Icons.sentiment_satisfied_rounded, color: AppColors.success, selected: _severityManuallySet && _severity == 0.2, onTap: () => _setManualSeverity(0.2))), const SizedBox(width: 8), Expanded(child: _SeverityButton(label: 'Moyen', icon: Icons.sentiment_neutral_rounded, color: AppColors.warning, selected: _severityManuallySet && _severity == 0.5, onTap: () => _setManualSeverity(0.5))), const SizedBox(width: 8), Expanded(child: _SeverityButton(label: 'Grave', icon: Icons.sentiment_very_dissatisfied_rounded, color: AppColors.danger, selected: _severityManuallySet && _severity == 0.8, onTap: () => _setManualSeverity(0.8)))]);
  Widget _buildIrrigationToggle() => _ToggleRow(options: const [_ToggleOption(key: 'working', label: 'OK', icon: Icons.check_circle_rounded, color: AppColors.success), _ToggleOption(key: 'attention', label: 'Alerte', icon: Icons.warning_rounded, color: AppColors.warning), _ToggleOption(key: 'broken', label: 'Panne', icon: Icons.error_rounded, color: AppColors.danger)], selected: _irrigationStatus, onChanged: (v) => setState(() => _irrigationStatus = v));
  Widget _buildMoistureToggle() => _ToggleRow(options: const [_ToggleOption(key: 'dry', label: 'Sec', icon: Icons.wb_sunny_rounded, color: AppColors.warning), _ToggleOption(key: 'moist', label: 'Humide', icon: Icons.water_drop_rounded, color: AppColors.success), _ToggleOption(key: 'soaked', label: 'Trempé', icon: Icons.pool_rounded, color: AppColors.info)], selected: _soilMoisture, onChanged: (v) => setState(() => _soilMoisture = v));
  Widget _buildGroundCoverGrid() => GridView.count(crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: 2.2, children: [_CoverCard(label: '< 25%', icon: Icons.circle_outlined, selected: _groundCover == 'low', onTap: () => setState(() => _groundCover = _groundCover == 'low' ? null : 'low')), _CoverCard(label: '25 – 50%', icon: Icons.pie_chart_outline_rounded, selected: _groundCover == 'medium', onTap: () => setState(() => _groundCover = _groundCover == 'medium' ? null : 'medium')), _CoverCard(label: '50 – 75%', icon: Icons.pie_chart_rounded, selected: _groundCover == 'high', onTap: () => setState(() => _groundCover = _groundCover == 'high' ? null : 'high')), _CoverCard(label: '> 75%', icon: Icons.circle_rounded, selected: _groundCover == 'full', onTap: () => setState(() => _groundCover = _groundCover == 'full' ? null : 'full'))]);
  Widget _buildStageDropdown(dynamic parcel) {
    final cropDef = CropsCatalog.byLabelFr(parcel.crop);
    final bbchStages = cropDef == null ? null : BbchCatalog.stagesFor(cropDef.id);
    return DropdownButtonFormField<String>(value: _stage ?? (parcel.semisDate != null ? (BbchCatalog.estimateStage(cropId: cropDef?.id ?? '', das: DateTime.now().difference(parcel.semisDate!).inDays)?.id ?? parcel.growthStage) : parcel.growthStage), decoration: const InputDecoration(labelText: 'Stade de développement', labelStyle: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)), items: (bbchStages ?? _genericStages).map((s) => DropdownMenuItem(value: s.id, child: Text(s.labelFr))).toList(), onChanged: (v) => setState(() => _stage = v));
  }
  Widget _buildNoteField() => TextField(controller: _noteCtrl, maxLines: 3, decoration: InputDecoration(hintText: 'Notes libres...', suffixIcon: IconButton(icon: Icon(_isListening ? Icons.mic_rounded : Icons.mic_none_rounded, color: _isListening ? AppColors.danger : AppColors.primary), onPressed: _toggleListening)));
  Widget _buildAudioSection() => Column(children: [if (_audioNotes.isNotEmpty) ...[for (int i = 0; i < _audioNotes.length; i++) Padding(padding: const EdgeInsets.only(bottom: 8), child: _AudioNoteCard(note: _audioNotes[i], onDelete: () => _deleteAudioNote(i)))], if (_audioState == AudioState.recording) _RecordingIndicator(duration: _recordingDuration, onStop: _stopRecording) else SizedBox(width: double.infinity, child: OutlinedButton.icon(onPressed: _startRecording, icon: const Icon(Icons.mic_rounded), label: const Text('Note vocale')))]);
}

class _SalinityPicker extends StatelessWidget {
  const _SalinityPicker({required this.value, required this.onChanged});
  final int? value;
  final ValueChanged<int?> onChanged;
  @override
  Widget build(BuildContext context) {
    return Row(children: [for (int i = 0; i <= 4; i++) ...[if (i > 0) const SizedBox(width: 8), Expanded(child: GestureDetector(onTap: () => onChanged(value == i ? null : i), child: AnimatedContainer(duration: const Duration(milliseconds: 200), height: 48, decoration: BoxDecoration(color: value == i ? _colorFor(i) : AppColors.secondary, borderRadius: BorderRadius.circular(12), border: Border.all(color: value == i ? _colorFor(i) : AppColors.dividerOf(context), width: 1.5)), alignment: Alignment.center, child: Text('$i', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: value == i ? Colors.white : AppColors.textSecondaryOf(context))))))]]);
  }
  Color _colorFor(int i) { if (i == 0) return AppColors.success; if (i <= 1) return AppColors.info; if (i <= 2) return AppColors.warning; return AppColors.danger; }
}

class _PhotoThumbnail extends StatelessWidget {
  const _PhotoThumbnail({required this.photo, required this.onRemove});
  final XFile photo;
  final VoidCallback onRemove;
  Widget _buildImage(BuildContext context) {
    const size = 120.0;
    if (kIsWeb) return Image.network(photo.path, height: size, width: size, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _placeholder(size, context));
    return Image.file(File(photo.path), height: size, width: size, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _placeholder(size, context));
  }
  Widget _placeholder(double size, BuildContext context) => Container(height: size, width: size, color: Theme.of(context).colorScheme.surfaceContainer, alignment: Alignment.center, child: Icon(Icons.broken_image_rounded, color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5)));
  @override
  Widget build(BuildContext context) {
    return Stack(children: [ClipRRect(borderRadius: BorderRadius.circular(14), child: _buildImage(context)), Positioned(top: 4, right: 4, child: GestureDetector(onTap: onRemove, child: Container(height: 26, width: 26, decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.close_rounded, color: Colors.white, size: 16))))]);
  }
}

class _QuickHealthButton extends StatelessWidget {
  const _QuickHealthButton({required this.icon, required this.label, required this.color, required this.selected, required this.onTap});
  final IconData icon; final String label; final Color color; final bool selected; final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return SizedBox(width: double.infinity, height: 64, child: Material(color: selected ? color : color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(16), child: InkWell(borderRadius: BorderRadius.circular(16), onTap: onTap, child: Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: Row(children: [Icon(icon, size: 28, color: selected ? Colors.white : color), const SizedBox(width: 14), Expanded(child: Text(label, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: selected ? Colors.white : color))), if (selected) const Icon(Icons.check_rounded, color: Colors.white, size: 24)])))));
  }
}

class _SymptomCard extends StatelessWidget {
  const _SymptomCard({required this.icon, required this.label, required this.selected, required this.onTap});
  final IconData icon; final String label; final bool selected; final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(duration: const Duration(milliseconds: 200), decoration: BoxDecoration(color: selected ? AppColors.primary.withValues(alpha: 0.12) : Theme.of(context).colorScheme.surfaceContainer, borderRadius: BorderRadius.circular(14), border: Border.all(color: selected ? AppColors.primary : Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.2), width: 2)), child: Material(color: Colors.transparent, child: InkWell(borderRadius: BorderRadius.circular(14), onTap: onTap, child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, size: 28, color: selected ? AppColors.primary : AppColors.textSecondaryOf(context)), const SizedBox(height: 6), Text(label, textAlign: TextAlign.center, style: TextStyle(fontSize: 12, fontWeight: selected ? FontWeight.w700 : FontWeight.w500, color: selected ? AppColors.primary : AppColors.textSecondaryOf(context)))]))));
  }
}

class _SeverityButton extends StatelessWidget {
  const _SeverityButton({required this.label, required this.icon, required this.color, required this.selected, required this.onTap});
  final String label; final IconData icon; final Color color; final bool selected; final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(duration: const Duration(milliseconds: 200), decoration: BoxDecoration(color: selected ? color : Colors.transparent, borderRadius: BorderRadius.circular(14), border: Border.all(color: color, width: 2)), child: Material(color: Colors.transparent, child: InkWell(borderRadius: BorderRadius.circular(14), onTap: onTap, child: Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Column(children: [Icon(icon, size: 24, color: selected ? Colors.white : color), const SizedBox(height: 4), Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: selected ? Colors.white : color))])))));
  }
}

class _RecordingIndicator extends StatelessWidget {
  const _RecordingIndicator({required this.duration, required this.onStop});
  final Duration duration; final VoidCallback onStop;
  String _formatDuration(Duration d) { final m = d.inMinutes.remainder(60).toString().padLeft(2, '0'); final s = d.inSeconds.remainder(60).toString().padLeft(2, '0'); return '$m:$s'; }
  @override
  Widget build(BuildContext context) {
    return Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), decoration: BoxDecoration(color: AppColors.danger.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.danger.withValues(alpha: 0.3))), child: Row(children: [Container(height: 12, width: 12, decoration: const BoxDecoration(color: AppColors.danger, shape: BoxShape.circle)), const SizedBox(width: 12), Text('Enregistrement  ${_formatDuration(duration)}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.danger)), const Spacer(), FilledButton.icon(style: FilledButton.styleFrom(backgroundColor: AppColors.danger, minimumSize: const Size(0, 36), padding: const EdgeInsets.symmetric(horizontal: 14)), onPressed: onStop, icon: const Icon(Icons.stop_rounded, size: 18), label: const Text('Arrêter'))]));
  }
}

class _AudioNoteCard extends StatefulWidget {
  const _AudioNoteCard({required this.note, required this.onDelete});
  final AudioNote note; final VoidCallback onDelete;
  @override State<_AudioNoteCard> createState() => _AudioNoteCardState();
}

class _AudioNoteCardState extends State<_AudioNoteCard> {
  late final AudioPlaybackController _ctrl; bool _isPlaying = false; Duration _position = Duration.zero; Duration _duration = Duration.zero;
  @override void initState() { super.initState(); _ctrl = AudioPlaybackController(); _duration = widget.note.duration; _ctrl.stateStream.listen((v) { if (mounted) setState(() => _isPlaying = v == PlayerState.playing); }); _ctrl.positionStream.listen((p) { if (mounted) setState(() => _position = p); }); _ctrl.durationStream.listen((d) { if (mounted && d > Duration.zero) setState(() => _duration = d); }); }
  @override void dispose() { _ctrl.dispose(); super.dispose(); }
  Future<void> _toggle() async { if (_isPlaying) { _ctrl.pause(); } else { if (_position > Duration.zero && _position < _duration) { await _ctrl.resume(); } else { await _ctrl.play(widget.note.path, fallbackDuration: widget.note.duration); } } }
  String _fmt(Duration d) { final m = d.inMinutes.remainder(60).toString().padLeft(2, '0'); final s = d.inSeconds.remainder(60).toString().padLeft(2, '0'); return '$m:$s'; }
  @override
  Widget build(BuildContext context) {
    final total = _duration.inMilliseconds == 0 ? widget.note.duration.inMilliseconds.toDouble().clamp(1, double.infinity) : _duration.inMilliseconds.toDouble();
    final current = _position.inMilliseconds.toDouble().clamp(0.0, total);
    final shown = _isPlaying || _position > Duration.zero ? _position : _duration;
    return Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10), decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColors.primary.withValues(alpha: 0.3))), child: Row(children: [Material(color: AppColors.primary, shape: const CircleBorder(), child: InkWell(customBorder: const CircleBorder(), onTap: _toggle, child: SizedBox(height: 42, width: 42, child: Icon(_isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded, color: Colors.white, size: 26)))), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [_WaveformProgress(progress: total == 0 ? 0 : current / total, isPlaying: _isPlaying, onSeek: (fraction) => _ctrl.seek(Duration(milliseconds: (total * fraction).round()))), const SizedBox(height: 4), Row(children: [const Icon(Icons.mic_rounded, size: 12, color: AppColors.primary), const SizedBox(width: 4), Text(_fmt(shown), style: TextStyle(fontSize: 11, color: AppColors.textMutedOf(context), fontWeight: FontWeight.w600))])])), IconButton(onPressed: widget.onDelete, icon: const Icon(Icons.delete_outline_rounded), color: AppColors.danger, iconSize: 20)]));
  }
}

class _WaveformProgress extends StatelessWidget {
  const _WaveformProgress({required this.progress, required this.isPlaying, required this.onSeek});
  final double progress; final bool isPlaying; final ValueChanged<double> onSeek;
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) { return GestureDetector(behavior: HitTestBehavior.opaque, onTapDown: (d) => onSeek((d.localPosition.dx / c.maxWidth).clamp(0.0, 1.0)), onHorizontalDragUpdate: (d) => onSeek((d.localPosition.dx / c.maxWidth).clamp(0.0, 1.0)), child: SizedBox(height: 28, width: double.infinity, child: CustomPaint(painter: _WaveformPainter(progress: progress.clamp(0.0, 1.0), activeColor: AppColors.primary, inactiveColor: AppColors.primary.withValues(alpha: 0.25))))); });
  }
}

class _WaveformPainter extends CustomPainter {
  _WaveformPainter({required this.progress, required this.activeColor, required this.inactiveColor});
  final double progress; final Color activeColor; final Color inactiveColor;
  static const _bars = <double>[0.30, 0.55, 0.75, 0.45, 0.85, 0.65, 0.40, 0.70, 0.90, 0.50, 0.35, 0.60, 0.80, 0.55, 0.45, 0.75, 0.95, 0.60, 0.40, 0.70, 0.50, 0.85, 0.65, 0.35, 0.55, 0.75, 0.45, 0.60, 0.80, 0.50, 0.40, 0.70, 0.90, 0.55, 0.35, 0.65];
  @override
  void paint(Canvas canvas, Size size) {
    final barCount = _bars.length; final gap = 2.0; final barWidth = (size.width - gap * (barCount - 1)) / barCount; final centerY = size.height / 2; final activeBars = (progress * barCount).floor();
    for (var i = 0; i < barCount; i++) {
      final h = _bars[i] * size.height; final x = i * (barWidth + gap);
      final paint = Paint()..color = i < activeBars ? activeColor : inactiveColor..strokeCap = StrokeCap.round..strokeWidth = barWidth;
      canvas.drawLine(Offset(x + barWidth / 2, centerY - h / 2), Offset(x + barWidth / 2, centerY + h / 2), paint);
    }
  }
  @override bool shouldRepaint(covariant _WaveformPainter old) => old.progress != progress;
}

class _RulesPreviewCard extends StatelessWidget {
  const _RulesPreviewCard({required this.rules});
  final List<AgroRule> rules;
  @override
  Widget build(BuildContext context) {
    final shown = rules.take(3).toList();
    return GlassCard(
      gradient: const LinearGradient(colors: [AppColors.accent, AppColors.accentDark], begin: Alignment.topLeft, end: Alignment.bottomRight),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [Container(height: 34, width: 34, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.auto_awesome_rounded, color: Colors.white)), const SizedBox(width: 10), Text('${rules.length} conseil${rules.length > 1 ? 's' : ''} disponible${rules.length > 1 ? 's' : ''}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15))]),
          const SizedBox(height: 12),
          for (final r in shown) Padding(padding: const EdgeInsets.only(bottom: 10), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(r.recommendation.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)), const SizedBox(height: 2), Text(r.diagnosis, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 13))])),
          if (rules.length > 3) Text('+ ${rules.length - 3} autre${rules.length - 3 > 1 ? 's' : ''} — visible apres enregistrement', style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12, fontStyle: FontStyle.italic)),
        ],
      ),
    );
  }
}

class _PresetRow extends StatelessWidget {
  const _PresetRow({required this.label, required this.icon, required this.presets, required this.value, required this.onChanged, required this.controller, required this.unit});
  final String label; final IconData icon; final List<int> presets; final int? value; final ValueChanged<int?> onChanged; final TextEditingController controller; final String unit;
  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Icon(icon, size: 18, color: AppColors.primary), const SizedBox(width: 8), Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14))]), const SizedBox(height: 10), Row(children: [for (int i = 0; i < presets.length; i++) ...[if (i > 0) const SizedBox(width: 8), Expanded(child: _PresetChip(label: '${presets[i]}', unit: unit, selected: value == presets[i], onTap: () { if (value == presets[i]) { onChanged(null); controller.clear(); } else { onChanged(presets[i]); controller.text = '${presets[i]}'; } }))]]), const SizedBox(height: 8), SizedBox(height: 48, child: TextField(controller: controller, keyboardType: TextInputType.number, decoration: InputDecoration(hintText: 'Autre valeur', suffixText: unit, contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12), isDense: true), onChanged: (v) => onChanged(int.tryParse(v.trim()))))]);
  }
}

class _PresetChip extends StatelessWidget {
  const _PresetChip({required this.label, required this.unit, required this.selected, required this.onTap});
  final String label, unit; final bool selected; final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(onTap: onTap, child: AnimatedContainer(duration: const Duration(milliseconds: 200), padding: const EdgeInsets.symmetric(vertical: 10), decoration: BoxDecoration(color: selected ? AppColors.primary : AppColors.secondary, borderRadius: BorderRadius.circular(12), border: Border.all(color: selected ? AppColors.primary : AppColors.dividerOf(context), width: 1.5)), alignment: Alignment.center, child: Text('$label $unit', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: selected ? Colors.white : AppColors.textSecondaryOf(context)))));
  }
}

class _ToggleOption { const _ToggleOption({required this.key, required this.label, required this.icon, required this.color}); final String key, label; final IconData icon; final Color color; }

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({required this.options, required this.selected, required this.onChanged});
  final List<_ToggleOption> options; final String? selected; final ValueChanged<String?> onChanged;
  @override Widget build(BuildContext context) { return Row(children: [for (int i = 0; i < options.length; i++) ...[if (i > 0) const SizedBox(width: 10), Expanded(child: _buildButton(options[i]))]]); }
  Widget _buildButton(_ToggleOption opt) {
    final isSelected = selected == opt.key;
    return GestureDetector(onTap: () => onChanged(isSelected ? null : opt.key), child: AnimatedContainer(duration: const Duration(milliseconds: 200), decoration: BoxDecoration(color: isSelected ? opt.color : Colors.transparent, borderRadius: BorderRadius.circular(14), border: Border.all(color: opt.color, width: 2)), padding: const EdgeInsets.symmetric(vertical: 12), child: Column(children: [Icon(opt.icon, size: 24, color: isSelected ? Colors.white : opt.color), const SizedBox(height: 4), Text(opt.label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: isSelected ? Colors.white : opt.color), textAlign: TextAlign.center)])));
  }
}

class _CoverCard extends StatelessWidget {
  const _CoverCard({required this.label, required this.icon, required this.selected, required this.onTap});
  final String label; final IconData icon; final bool selected; final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(duration: const Duration(milliseconds: 200), decoration: BoxDecoration(color: selected ? AppColors.primary.withValues(alpha: 0.08) : AppColors.secondary, borderRadius: BorderRadius.circular(14), border: Border.all(color: selected ? AppColors.primary : Colors.transparent, width: 2)), child: Material(color: Colors.transparent, child: InkWell(borderRadius: BorderRadius.circular(14), onTap: onTap, child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, size: 24, color: selected ? AppColors.primary : AppColors.textSecondaryOf(context)), const SizedBox(height: 4), Text(label, style: TextStyle(fontSize: 12, fontWeight: selected ? FontWeight.w700 : FontWeight.w500, color: selected ? AppColors.primary : AppColors.textSecondaryOf(context)))]))));
  }
}
