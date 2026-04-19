import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/data/senegal_regions.dart';
import '../../../core/services/sync_service.dart';
import '../../../core/utils/formatters.dart';
import '../../../routes/route_names.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/workflow_stepper.dart';
import '../../../theme/app_colors.dart';
import '../../parcels/presentation/parcels_providers.dart';
import '../data/agro_rules_repository.dart';
import '../domain/agro_rule.dart';
import '../domain/expert_request.dart';

class RecommendationsScreen extends ConsumerWidget {
  const RecommendationsScreen({super.key, required this.parcelId});
  final String parcelId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final parcel = ref.watch(parcelByIdProvider(parcelId));
    if (parcel == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Recommandations')),
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

    final extra = GoRouterState.of(context).extra as Map?;
    final symptoms =
        ((extra?['symptoms'] as List?) ?? const <String>[]).cast<String>();
    final severity = (extra?['severity'] as double?) ?? 0.4;
    final stage = (extra?['stage'] as String?) ?? parcel.growthStage;

    final rulesAsync = ref.watch(agroRulesProvider);

    return rulesAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Conseils & Actions')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: const Text('Conseils & Actions')),
        body: Center(child: Text('Erreur chargement des regles : $e')),
      ),
      data: (allRules) {
        final matched = matchRules(
          allRules: allRules,
          crop: parcel.crop,
          stage: stage,
          symptoms: symptoms,
          severity: severity,
          region: parcel.region,
        );

        // Determine follow-up days from the most specific matched rule,
        // or default based on severity.
        final followupDays = matched.isNotEmpty
            ? matched.first.recommendation.followupDays
            : (severity > 0.6 ? 3 : 7);
        final nextVisit = DateTime.now().add(Duration(days: followupDays));

        // Region label for display.
        final regionLabel = parcel.region != null
            ? SenegalRegions.byId(parcel.region!)?.labelFr
            : null;

        return Scaffold(
          appBar: AppBar(title: const Text('Conseils & Actions')),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              const WorkflowStepper(currentStep: 1),
              const SizedBox(height: 16),
              Text(parcel.name,
                  style: Theme.of(context).textTheme.titleLarge),
              Text(
                '${parcel.crop} · $stage'
                '${regionLabel != null ? ' · $regionLabel' : ''}',
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),

              // --- Matched agro rules ---
              if (matched.isNotEmpty)
                for (final rule in matched)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _AgroRuleCard(rule: rule),
                  )
              else ...[
                _NoMatchCard(),
                const SizedBox(height: 10),
              ],

              const SizedBox(height: 8),

              // --- Next visit ---
              GlassCard(
                child: Row(
                  children: [
                    Container(
                      height: 44,
                      width: 44,
                      decoration: BoxDecoration(
                        color: AppColors.info.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.event_rounded,
                          color: AppColors.info),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Prochaine visite',
                              style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12)),
                          Text('${Fmt.date(nextVisit)} (J+$followupDays)',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 16)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // --- Expert fallback ---
              _ExpertFallbackButton(
                parcelId: parcel.id,
                symptoms: symptoms,
                severity: severity,
                stage: stage,
                hasMatches: matched.isNotEmpty,
                ref: ref,
              ),
              const SizedBox(height: 10),

              PrimaryButton(
                label: 'Creer mon rapport',
                icon: Icons.description_rounded,
                onPressed: () => context.push(Routes.reportPreview,
                    extra: {'parcelId': parcel.id}),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () => context.go(Routes.dashboard),
                icon: const Icon(Icons.home_rounded),
                label: const Text('Retour a l\'accueil'),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Agro rule card — displays diagnosis + structured recommendation
// ---------------------------------------------------------------------------
class _AgroRuleCard extends StatelessWidget {
  const _AgroRuleCard({required this.rule});
  final AgroRule rule;

  IconData get _icon => switch (rule.symptom) {
        'yellow_leaves' => Icons.eco_rounded,
        'spots' || 'taches_brunes' || 'taches_noires' => Icons.healing_rounded,
        'drought' || 'fletrissement' => Icons.water_drop_rounded,
        'pests' || 'defoliation' || 'miellat' => Icons.bug_report_rounded,
        'weeds' => Icons.grass_rounded,
        _ => Icons.auto_awesome_rounded,
      };

  Color get _color {
    if (rule.recommendation.ppeRequired) return AppColors.danger;
    if (rule.severityMin >= 0.6) return AppColors.danger;
    if (rule.severityMin >= 0.3) return AppColors.warning;
    return AppColors.success;
  }

  @override
  Widget build(BuildContext context) {
    final rec = rule.recommendation;
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 42,
                width: 42,
                decoration: BoxDecoration(
                  color: _color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(_icon, color: _color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(rec.title,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 15)),
                    const SizedBox(height: 2),
                    Text(
                      rule.diagnosis,
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Actions list
          for (final action in rec.actions)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Icon(Icons.check_circle_rounded,
                        size: 16, color: AppColors.primary),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(action,
                        style: const TextStyle(fontSize: 13, height: 1.4)),
                  ),
                ],
              ),
            ),

          // Metadata chips
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              if (rec.costFcfaPerHa > 0)
                _Chip(
                  icon: Icons.monetization_on_rounded,
                  label: '${rec.costFcfaPerHa} FCFA/ha',
                ),
              if (rec.delayBeforeHarvestDays > 0)
                _Chip(
                  icon: Icons.timer_rounded,
                  label: 'DAR ${rec.delayBeforeHarvestDays} j',
                  color: AppColors.warning,
                ),
              if (rec.ppeRequired)
                _Chip(
                  icon: Icons.shield_rounded,
                  label: 'EPI requis',
                  color: AppColors.danger,
                ),
              _Chip(
                icon: Icons.replay_rounded,
                label: 'Suivi J+${rec.followupDays}',
              ),
            ],
          ),

          // Source
          if (rule.validatedBy.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Source : ${rule.validatedBy}',
              style: TextStyle(
                fontSize: 11,
                color: AppColors.textMuted,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Metadata chip
// ---------------------------------------------------------------------------
class _Chip extends StatelessWidget {
  const _Chip({required this.icon, required this.label, this.color});
  final IconData icon;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: c),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w600, color: c)),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Card shown when no rules match
// ---------------------------------------------------------------------------
class _NoMatchCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        children: [
          const Icon(Icons.info_outline_rounded,
              size: 40, color: AppColors.info),
          const SizedBox(height: 10),
          const Text(
            'Aucune regle ne correspond a cette observation',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
          ),
          const SizedBox(height: 6),
          const Text(
            'Les symptomes, le stade ou la severite ne correspondent pas '
            'aux regles enregistrees. Vous pouvez demander l\'avis d\'un '
            'agronome ci-dessous.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Expert fallback button — §8.5
// ---------------------------------------------------------------------------
class _ExpertFallbackButton extends StatefulWidget {
  const _ExpertFallbackButton({
    required this.parcelId,
    required this.symptoms,
    required this.severity,
    required this.stage,
    required this.hasMatches,
    required this.ref,
  });

  final String parcelId;
  final List<String> symptoms;
  final double severity;
  final String stage;
  final bool hasMatches;
  final WidgetRef ref;

  @override
  State<_ExpertFallbackButton> createState() => _ExpertFallbackButtonState();
}

class _ExpertFallbackButtonState extends State<_ExpertFallbackButton> {
  bool _sent = false;
  bool _sending = false;

  Future<void> _askExpert() async {
    setState(() => _sending = true);
    try {
      final id = const Uuid().v4();
      final contextText = 'Parcelle: ${widget.parcelId}\n'
          'Stade: ${widget.stage}\n'
          'Symptomes: ${widget.symptoms.join(", ")}\n'
          'Severite: ${(widget.severity * 100).round()}%';

      final request = ExpertRequest(
        id: id,
        parcelId: widget.parcelId,
        context: contextText,
        createdAt: DateTime.now(),
        status: ExpertRequestStatus.queued,
      );

      // Persist locally
      await Hive.box(AppConstants.boxExpertRequests).put(id, request.toJson());

      // Enqueue for sync
      widget.ref.read(syncServiceProvider.notifier).enqueue({
        'op': 'create_expert_request',
        'id': id,
        'parcelId': widget.parcelId,
      });

      if (mounted) {
        setState(() {
          _sent = true;
          _sending = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Demande envoyee ! Un agronome vous repondra.'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _sending = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur : $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_sent) {
      return GlassCard(
        child: Row(
          children: [
            Container(
              height: 40,
              width: 40,
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.check_circle_rounded,
                  color: AppColors.success),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Demande envoyee',
                      style: TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 14)),
                  Text(
                    'Un agronome analysera votre cas et vous repondra.',
                    style: TextStyle(
                        color: AppColors.textSecondary, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return OutlinedButton.icon(
      onPressed: _sending ? null : _askExpert,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.accent,
        side: const BorderSide(color: AppColors.accent),
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
      icon: _sending
          ? const SizedBox(
              height: 16,
              width: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.support_agent_rounded),
      label: Text(
        widget.hasMatches
            ? 'Ce n\'est pas mon cas — demander a un agronome'
            : 'Demander l\'avis d\'un agronome',
      ),
    );
  }
}
