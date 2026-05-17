import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:audioplayers/audioplayers.dart';

import '../../../theme/app_colors.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/health_badge.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/messenger_utils.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/ai_diagnostic_service.dart';
import '../../../core/services/credit_service.dart';
import '../../../core/services/sync_service.dart';
import '../../../core/services/audio_service.dart';
import '../../../core/network/dio_provider.dart';
import '../../../routes/route_names.dart';

import '../../parcels/presentation/parcels_providers.dart';
import '../../recommendations/domain/expert_request.dart';
import '../../recommendations/presentation/expert_requests_screen.dart';

class VisitDetailsScreen extends ConsumerStatefulWidget {
  const VisitDetailsScreen({super.key, required this.visitId});
  final String visitId;

  @override
  ConsumerState<VisitDetailsScreen> createState() => _VisitDetailsScreenState();
}

class _VisitDetailsScreenState extends ConsumerState<VisitDetailsScreen> {
  bool _isAnalyzing = false;
  bool _isAskingExpert = false;
  String? _pendingAiRequestId;
  String? _pendingExpertRequestId;

  Future<void> _requestAiDiagnostic(dynamic parcel, List<String> photos, List<Uint8List> photoBytes) async {
    if (photos.isEmpty) {
      MessengerUtils.showInfo('Aucune photo disponible dans cette visite pour l\'analyse IA.');
      return;
    }

    final creditService = ref.read(creditServiceProvider.notifier);
    if (creditService.credits < CreditService.costAiDiagnostic) {
      MessengerUtils.showInfo('Crédits insuffisants (2 crédits requis).');
      context.push(Routes.wallet);
      return;
    }

    setState(() => _isAnalyzing = true);
    try {
      await creditService.useCredits(
        CreditService.costAiDiagnostic,
        description: 'Diagnostic IA (Claude) pour la parcelle ${parcel.name}',
      );
      final ai = ref.read(aiDiagnosticServiceProvider);

      Uint8List? pBytes;
      if (kIsWeb && photoBytes.isNotEmpty) {
        pBytes = photoBytes.last;
      }

      final requestId = await ai.submitRequest(
        parcelId: parcel.id,
        ownerName: parcel.owner,
        ownerPhone: parcel.phone ?? '',
        photoPath: photos.last,
        photoBytes: pBytes,
      );

      if (mounted) {
        setState(() {
          _pendingAiRequestId = requestId;
          _isAnalyzing = false;
        });
        MessengerUtils.showSuccess('Demande de diagnostic IA (Claude) envoyée avec succès !');
      }
    } catch (e) {
      if (mounted) setState(() => _isAnalyzing = false);
      MessengerUtils.showError('Erreur d\'envoi : $e');
    }
  }

  Future<void> _requestExpertOpinion(dynamic parcel, String stage, List<String> symptoms, double severity, String note) async {
    final creditService = ref.read(creditServiceProvider.notifier);
    if (creditService.credits < CreditService.costExpertOpinion) {
      MessengerUtils.showInfo('Crédits insuffisants (5 crédits requis).');
      context.push(Routes.wallet);
      return;
    }

    setState(() => _isAskingExpert = true);
    try {
      await creditService.useCredits(
        CreditService.costExpertOpinion,
        description: 'Avis Agronome Senior pour la parcelle ${parcel.name}',
      );
      final id = const Uuid().v4();
      final contextText = 'Visite: ${widget.visitId}\n'
          'Parcelle: ${parcel.name}\n'
          'Stade: $stage\n'
          'Symptomes: ${symptoms.join(", ")}\n'
          'Note: $note\n'
          'Severite: ${(severity * 100).round()}%';

      final request = ExpertRequest(
        id: id,
        parcelId: parcel.id,
        context: contextText,
        createdAt: DateTime.now(),
        status: ExpertRequestStatus.queued,
      );

      await Hive.box(AppConstants.boxExpertRequests).put(id, request.toJson());

      ref.read(syncServiceProvider.notifier).enqueue({
        'op': 'create_expert_request',
        'id': id,
        'parcelId': parcel.id,
        'context': contextText,
      });

      if (mounted) {
        setState(() {
          _pendingExpertRequestId = id;
          _isAskingExpert = false;
        });
        MessengerUtils.showSuccess('Demande d\'avis envoyée à un Agronome Senior !');
      }
    } catch (e) {
      if (mounted) setState(() => _isAskingExpert = false);
      MessengerUtils.showError('Erreur d\'envoi : $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final box = Hive.box(AppConstants.boxObservations);
    final data = box.get(widget.visitId);

    if (data == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Visite introuvable')),
        body: const Center(child: Text('Les données de cette visite ne sont pas disponibles.')),
      );
    }

    final parcel = ref.watch(parcelByIdProvider(data['parcelId'] as String));
    final date = DateTime.parse(data['at'] as String);
    final stage = data['stage'] as String? ?? 'Visite';
    final symptoms = (data['symptoms'] as List?)?.cast<String>() ?? [];
    final severity = data['severity'] as double? ?? 0.0;
    final healthScore = 1.0 - severity;
    final note = data['note'] as String? ?? '';
    final photos = (data['photoPaths'] as List?)?.cast<String>() ?? [];
    final photoBytes = (data['photoBytes'] as List?)?.cast<Uint8List>() ?? [];
    final audioPaths = (data['audioPaths'] as List?)?.cast<String>() ?? [];

    // Flux des diagnostics IA et Expert
    final aiRequestsAsync = ref.watch(diagnosticRequestsProvider);
    final expertRequestsAsync = ref.watch(expertRequestsListProvider);

    final aiRequests = aiRequestsAsync.whenOrNull(data: (list) => list.where((r) => r.parcelId == parcel?.id).toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt))) ?? [];
    final expertRequests = expertRequestsAsync.whenOrNull(data: (list) => list.where((r) => r.parcelId == parcel?.id).toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt))) ?? [];

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context, date, stage, healthScore, parcel),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildActionsSection(context, parcel, photos, photoBytes, stage, symptoms, severity, note),
                  const SizedBox(height: 24),
                  
                  if (aiRequests.isNotEmpty || expertRequests.isNotEmpty) ...[
                    _buildSectionTitle(context, 'Résultats d\'Analyses & Avis Experts'),
                    const SizedBox(height: 12),
                    _buildResultsSection(context, aiRequests, expertRequests),
                    const SizedBox(height: 24),
                  ],

                  _buildSectionTitle(context, 'Ressources & Environnement'),
                  const SizedBox(height: 12),
                  _buildWeatherAndSoilCard(context, data),
                  const SizedBox(height: 24),

                  _buildSectionTitle(context, 'Mesures Phénologiques'),
                  const SizedBox(height: 12),
                  _buildPhenologyCard(context, data),
                  const SizedBox(height: 24),

                  _buildSectionTitle(context, 'Pratiques & Intrants'),
                  const SizedBox(height: 12),
                  _buildPracticesCard(context, data),
                  const SizedBox(height: 24),

                  _buildSectionTitle(context, 'Observations Terrain'),
                  const SizedBox(height: 12),
                  _buildObservationsCard(context, note, symptoms),
                  const SizedBox(height: 24),

                  if (audioPaths.isNotEmpty) ...[
                    _buildSectionTitle(context, 'Notes Vocales'),
                    const SizedBox(height: 12),
                    _buildAudioNotesCard(context, audioPaths),
                    const SizedBox(height: 24),
                  ],

                  _buildSectionTitle(context, 'Photos de la visite'),
                  const SizedBox(height: 12),
                  _buildPhotoGrid(context, photos),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, DateTime date, String type, double healthScore, dynamic parcel) {
    return SliverAppBar(
      expandedHeight: 180,
      pinned: true,
      backgroundColor: AppColors.primary,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(Fmt.date(date), style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.white)),
        background: Stack(
          fit: StackFit.expand,
          children: [
            Container(color: AppColors.primary),
            Positioned(
              bottom: 60,
              left: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(type.toUpperCase(), style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 1)),
                  if (parcel != null) ...[
                    const SizedBox(height: 4),
                    Text('${parcel.crop} · ${parcel.owner}', style: TextStyle(color: Colors.white.withValues(alpha: 0.95), fontSize: 15, fontWeight: FontWeight.bold)),
                  ],
                  const SizedBox(height: 8),
                  HealthBadge(score: healthScore),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(title.toUpperCase(),
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 1, color: AppColors.primary));
  }

  Widget _buildActionsSection(BuildContext context, dynamic parcel, List<String> photos, List<Uint8List> photoBytes, String stage, List<String> symptoms, double severity, String note) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      borderOpacity: 0.3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Solliciter une Expertise', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary)),
          const SizedBox(height: 6),
          Text('Obtenez une analyse immédiate par IA ou l\'avis d\'un agronome senior.', style: TextStyle(fontSize: 12, color: AppColors.textSecondaryOf(context))),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: (_isAnalyzing || _pendingAiRequestId != null || parcel == null) ? null : () => _requestAiDiagnostic(parcel, photos, photoBytes),
              icon: _isAnalyzing
                  ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Icon(_pendingAiRequestId != null ? Icons.check_circle_rounded : Icons.auto_awesome_rounded),
              label: Text(_pendingAiRequestId != null ? 'Diagnostic IA demandé' : 'Diagnostic IA (Claude) — 2 Crédits'),
              style: FilledButton.styleFrom(backgroundColor: AppColors.accent, padding: const EdgeInsets.symmetric(vertical: 14)),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: (_isAskingExpert || _pendingExpertRequestId != null || parcel == null) ? null : () => _requestExpertOpinion(parcel, stage, symptoms, severity, note),
              icon: _isAskingExpert
                  ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : Icon(_pendingExpertRequestId != null ? Icons.check_circle_rounded : Icons.support_agent_rounded),
              label: Text(_pendingExpertRequestId != null ? 'Avis Expert demandé' : 'Avis Agronome Senior — 5 Crédits'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary, width: 1.5),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherAndSoilCard(BuildContext context, Map<dynamic, dynamic> data) {
    final soilMoisture = data['soilMoisture'] as String? ?? 'N/A';
    final groundCover = data['groundCover'] as String? ?? 'N/A';
    final salinityIndex = data['salinityIndex'] as int?;

    String moistureLabel = soilMoisture;
    if (soilMoisture == 'dry') moistureLabel = 'Sec';
    if (soilMoisture == 'moist') moistureLabel = 'Humide';
    if (soilMoisture == 'soaked') moistureLabel = 'Trempé';

    String coverLabel = groundCover;
    if (groundCover == 'low') coverLabel = '< 25%';
    if (groundCover == 'medium') coverLabel = '25 - 50%';
    if (groundCover == 'high') coverLabel = '50 - 75%';
    if (groundCover == 'full') coverLabel = '> 75%';

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(context, Icons.thermostat_rounded, '28°C', 'Température'),
          _buildStatItem(context, Icons.water_drop_rounded, moistureLabel, 'Humidité Sol'),
          _buildStatItem(context, Icons.grass_rounded, coverLabel, 'Couverture'),
          _buildStatItem(context, Icons.grain_rounded, salinityIndex != null ? 'Niv. $salinityIndex' : 'N/A', 'Salinité'),
        ],
      ),
    );
  }

  Widget _buildPhenologyCard(BuildContext context, Map<dynamic, dynamic> data) {
    final cropHeight = data['cropHeightCm'] as int?;
    final plantSpacing = data['plantSpacingCm'] as int?;
    final plantDensity = data['plantDensity'] as String? ?? 'N/A';
    final floweringStatus = data['floweringStatus'] as String? ?? 'N/A';

    String densityLabel = plantDensity;
    if (plantDensity == 'sparse') densityLabel = 'Clairsemé';
    if (plantDensity == 'normal') densityLabel = 'Normale';
    if (plantDensity == 'dense') densityLabel = 'Dense';

    String floweringLabel = floweringStatus;
    if (floweringStatus == 'none') floweringLabel = 'Aucune';
    if (floweringStatus == 'partial') floweringLabel = 'Partielle';
    if (floweringStatus == 'full') floweringLabel = 'Pleine';

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(context, Icons.height_rounded, cropHeight != null ? '$cropHeight cm' : 'N/A', 'Hauteur'),
          _buildStatItem(context, Icons.swap_horiz_rounded, plantSpacing != null ? '$plantSpacing cm' : 'N/A', 'Espacement'),
          _buildStatItem(context, Icons.group_work_rounded, densityLabel, 'Densité'),
          _buildStatItem(context, Icons.local_florist_rounded, floweringLabel, 'Floraison'),
        ],
      ),
    );
  }

  Widget _buildPracticesCard(BuildContext context, Map<dynamic, dynamic> data) {
    final recentInput = data['recentInput'] as String? ?? 'none';
    final inputDosage = data['inputDosage'] as String? ?? '';
    final irrigationStatus = data['irrigationStatus'] as String? ?? 'working';

    String inputLabel = 'Aucun';
    if (recentInput == 'fertilizer') inputLabel = 'Engrais';
    if (recentInput == 'pesticide') inputLabel = 'Pesticide';
    if (recentInput == 'organic') inputLabel = 'Organique';

    String irrigationLabel = 'Fonctionnelle';
    Color irrigationColor = AppColors.success;
    if (irrigationStatus == 'attention') { irrigationLabel = 'À surveiller'; irrigationColor = AppColors.warning; }
    if (irrigationStatus == 'broken') { irrigationLabel = 'En Panne'; irrigationColor = AppColors.danger; }

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.water_rounded, color: AppColors.primary, size: 22),
              const SizedBox(width: 8),
              const Text('Système d\'Irrigation :', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: irrigationColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                child: Text(irrigationLabel, style: TextStyle(color: irrigationColor, fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            ],
          ),
          const Divider(height: 24),
          Row(
            children: [
              const Icon(Icons.science_rounded, color: AppColors.primary, size: 22),
              const SizedBox(width: 8),
              Text('Dernier Intrant : $inputLabel', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
          if (inputDosage.isNotEmpty) ...[
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.only(left: 30),
              child: Text('Dosage / Produit : $inputDosage', style: TextStyle(fontSize: 13, color: AppColors.textSecondaryOf(context), fontStyle: FontStyle.italic)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primary, size: 24),
        const SizedBox(height: 6),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.8))),
      ],
    );
  }

  Widget _buildObservationsCard(BuildContext context, String note, List<String> symptoms) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (note.isNotEmpty) ...[
            Text('Note du Technicien :', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textSecondaryOf(context))),
            const SizedBox(height: 6),
            Text(note, style: const TextStyle(fontSize: 15, fontStyle: FontStyle.italic)),
            const SizedBox(height: 16),
          ],
          Text('Symptômes Identifiés :', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textSecondaryOf(context))),
          const SizedBox(height: 8),
          if (symptoms.isEmpty)
            _buildObservationItem(context, 'Aucune anomalie signalée.')
          else
            ...symptoms.map((s) => _buildObservationItem(context, s)),
        ],
      ),
    );
  }

  Widget _buildObservationItem(BuildContext context, String obs) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle_outline_rounded, size: 18, color: AppColors.success),
          const SizedBox(width: 12),
          Expanded(child: Text(obs, style: TextStyle(fontSize: 14, height: 1.4, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.9), fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }

  Widget _buildAudioNotesCard(BuildContext context, List<String> audioPaths) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: audioPaths.map((path) => _MiniAudioPlayer(path: path)).toList(),
      ),
    );
  }

  Widget _buildResultsSection(BuildContext context, List<DiagnosticRequest> aiRequests, List<ExpertRequest> expertRequests) {
    return Column(
      children: [
        if (aiRequests.isNotEmpty) ...[
          _buildAiDiagnosticCard(context, aiRequests.first),
          const SizedBox(height: 16),
        ],
        if (expertRequests.isNotEmpty) ...[
          _buildExpertRequestCard(context, expertRequests.first),
        ],
      ],
    );
  }

  Widget _buildAiDiagnosticCard(BuildContext context, DiagnosticRequest request) {
    final isAnalyzed = request.status == DiagnosticStatus.analyzed;
    final isValidated = request.status == DiagnosticStatus.validated;
    final isRejected = request.status == DiagnosticStatus.rejected;

    Color statusColor = Colors.grey;
    String statusLabel = 'En attente';
    if (isAnalyzed) { statusColor = AppColors.info; statusLabel = 'Analysé (Claude)'; }
    if (isValidated) { statusColor = AppColors.success; statusLabel = 'Validé par Expert'; }
    if (isRejected) { statusColor = AppColors.danger; statusLabel = 'Rejeté par Expert'; }

    String imageUrl = request.photoUrl;
    if (!imageUrl.startsWith('http')) {
      final baseUrl = ref.read(dioProvider).options.baseUrl;
      imageUrl = '$baseUrl/$imageUrl';
    }

    return GlassCard(
      padding: const EdgeInsets.all(16),
      borderOpacity: 0.4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  height: 46,
                  width: 46,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(height: 46, width: 46, color: Colors.grey.withValues(alpha: 0.1)),
                  errorWidget: (_, __, ___) => Container(height: 46, width: 46, color: Colors.grey.withValues(alpha: 0.2), child: const Icon(Icons.broken_image_rounded, size: 20)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Diagnostic IA (Claude)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    Text(
                      'Mis à jour le ${request.createdAt.day}/${request.createdAt.month}',
                      style: TextStyle(fontSize: 12, color: AppColors.textMutedOf(context)),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                child: Text(statusLabel.toUpperCase(), style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.w900)),
              ),
            ],
          ),
          if (request.aiResult != null) ...[
            const Divider(height: 24),
            Row(
              children: [
                const Icon(Icons.auto_awesome_rounded, size: 18, color: AppColors.accent),
                const SizedBox(width: 8),
                Expanded(child: Text(request.aiResult!.label, style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.accent, fontSize: 14))),
              ],
            ),
            const SizedBox(height: 8),
            Text(request.aiResult!.recommendations, style: const TextStyle(fontSize: 13, height: 1.4)),
          ],
          if (request.adminComment != null && request.adminComment!.isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              width: double.infinity,
              decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: statusColor.withValues(alpha: 0.3))),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.comment_rounded, size: 16, color: statusColor),
                      const SizedBox(width: 8),
                      Text('Commentaire de l\'Expert', style: TextStyle(fontWeight: FontWeight.w800, color: statusColor, fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(request.adminComment!, style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic, height: 1.3)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildExpertRequestCard(BuildContext context, ExpertRequest request) {
    Color statusColor = Colors.grey;
    String statusLabel = 'Brouillon';
    switch (request.status) {
      case ExpertRequestStatus.draft: statusColor = Colors.grey; statusLabel = 'Brouillon'; break;
      case ExpertRequestStatus.queued: statusColor = AppColors.warning; statusLabel = 'En attente de synchro'; break;
      case ExpertRequestStatus.sent: statusColor = AppColors.info; statusLabel = 'Envoyé à l\'expert'; break;
      case ExpertRequestStatus.received: statusColor = AppColors.info; statusLabel = 'En cours d\'analyse'; break;
      case ExpertRequestStatus.answered: statusColor = AppColors.success; statusLabel = 'Répondu par l\'expert'; break;
      case ExpertRequestStatus.closed: statusColor = AppColors.success; statusLabel = 'Dossier clos'; break;
    }

    return GlassCard(
      padding: const EdgeInsets.all(16),
      borderOpacity: 0.4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 46, width: 46,
                decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
                child: Icon(Icons.support_agent_rounded, color: statusColor, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Avis Agronome Senior', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    Text('Demandé le ${request.createdAt.day}/${request.createdAt.month}', style: TextStyle(fontSize: 12, color: AppColors.textMutedOf(context))),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                child: Text(statusLabel.toUpperCase(), style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.w900)),
              ),
            ],
          ),
          if (request.answer != null && request.answer!.isNotEmpty) ...[
            const Divider(height: 24),
            Container(
              padding: const EdgeInsets.all(14),
              width: double.infinity,
              decoration: BoxDecoration(color: AppColors.success.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.success.withValues(alpha: 0.3))),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.verified_rounded, size: 18, color: AppColors.success),
                      SizedBox(width: 8),
                      Text('Réponse de l\'Agronome Senior', style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.success, fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(request.answer!, style: const TextStyle(fontSize: 13, height: 1.4)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPhotoGrid(BuildContext context, List<String> photos) {
    if (photos.isEmpty) {
      return Container(
        height: 100, width: double.infinity,
        decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainer, borderRadius: BorderRadius.circular(16), border: Border.all(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.2))),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.photo_library_outlined, color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.4)),
            const SizedBox(height: 8),
            Text('Aucune photo pour cette visite', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.6), fontSize: 12)),
          ],
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 10, mainAxisSpacing: 10),
      itemCount: photos.length,
      itemBuilder: (context, index) {
        final path = photos[index];
        Widget image;
        if (kIsWeb) {
          image = Image.network(path, fit: BoxFit.cover);
        } else {
          final file = File(path);
          image = file.existsSync() ? Image.file(file, fit: BoxFit.cover) : Icon(Icons.broken_image_rounded, color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5));
        }

        return ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Container(color: Theme.of(context).colorScheme.surfaceContainer, child: image),
        );
      },
    );
  }
}

class _MiniAudioPlayer extends StatefulWidget {
  const _MiniAudioPlayer({required this.path});
  final String path;
  @override State<_MiniAudioPlayer> createState() => _MiniAudioPlayerState();
}

class _MiniAudioPlayerState extends State<_MiniAudioPlayer> {
  late final AudioPlaybackController _ctrl;
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  @override void initState() {
    super.initState();
    _ctrl = AudioPlaybackController();
    _ctrl.stateStream.listen((v) { if (mounted) setState(() => _isPlaying = v == PlayerState.playing); });
    _ctrl.positionStream.listen((p) { if (mounted) setState(() => _position = p); });
    _ctrl.durationStream.listen((d) { if (mounted && d > Duration.zero) setState(() => _duration = d); });
  }

  @override void dispose() { _ctrl.dispose(); super.dispose(); }

  Future<void> _toggle() async {
    if (_isPlaying) {
      _ctrl.pause();
    } else {
      if (_position > Duration.zero && _position < _duration) {
        await _ctrl.resume();
      } else {
        await _ctrl.play(widget.path);
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
    final shown = _isPlaying || _position > Duration.zero ? _position : _duration;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColors.primary.withValues(alpha: 0.3))),
      child: Row(
        children: [
          Material(color: AppColors.primary, shape: const CircleBorder(), child: InkWell(customBorder: const CircleBorder(), onTap: _toggle, child: SizedBox(height: 42, width: 42, child: Icon(_isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded, color: Colors.white, size: 26)))),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(widget.path.split('/').last, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Row(children: [const Icon(Icons.mic_rounded, size: 12, color: AppColors.primary), const SizedBox(width: 4), Text(_fmt(shown), style: TextStyle(fontSize: 11, color: AppColors.textMutedOf(context), fontWeight: FontWeight.w600))]),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
