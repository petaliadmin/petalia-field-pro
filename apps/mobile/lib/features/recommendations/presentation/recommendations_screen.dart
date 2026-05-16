import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;

import '../../../core/constants/app_constants.dart';
import '../../../core/data/pesticide_catalog.dart';
import '../../../core/data/senegal_regions.dart';
import '../../../core/services/pricing_service.dart';
import '../../../core/services/settings_service.dart';
import '../../../core/services/sync_service.dart';
import '../../../core/services/tts_service.dart';
import '../../../core/services/credit_service.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/messenger_utils.dart';
import '../../../core/utils/geo_utils.dart';
import '../../../core/services/weather_service.dart';
import '../../../routes/route_names.dart';
import '../../../shared/widgets/app_state_view.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/skeleton.dart';
import '../../../shared/widgets/workflow_stepper.dart';
import '../../../theme/app_colors.dart';
import '../../parcels/presentation/parcels_providers.dart';
import '../data/agro_rules_repository.dart';
import '../domain/agro_rule.dart';
import '../domain/expert_request.dart';
import 'widgets/sprayer_calculator.dart';

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
    final weatherAsync = ref.watch(weatherProvider);

    return rulesAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Conseils & Actions')),
        body: const SkeletonList(count: 3),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: const Text('Conseils & Actions')),
        body: AppStateView.error(
          'Impossible de charger les conseils',
          message: 'Verifiez votre connexion ou reessayez dans un instant.',
          onRetry: () => ref.invalidate(agroRulesProvider),
        ),
      ),
      data: (allRules) {
        final weather = weatherAsync.valueOrNull;
        final isRainRisk = (weather?.maxRainNext6h ?? 0) >
            AppConstants.rainLeachingThresholdMm;

        var matched = matchRules(
          allRules: allRules,
          crop: parcel.crop,
          stage: stage,
          symptoms: symptoms,
          severity: severity,
          region: parcel.region,
          treatmentHistory: parcel.treatmentHistory,
        );

        // Anti-lessivage logic — §2.2
        // If rain risk is high, we remove foliar sprays but keep other actions
        // (like manual removal, pruning, or soil treatment).
        if (isRainRisk) {
          matched = matched.map((rule) {
            final actions = rule.recommendation.actions;
            final safeActions = actions.where((a) => 
              !a.toLowerCase().contains('pulvérisation') && 
              !a.toLowerCase().contains('foliaire')
            ).toList();
            
            if (safeActions.length != actions.length) {
              return rule.copyWith(
                recommendation: rule.recommendation.copyWith(
                  actions: [
                    '⚠️ RISQUE DE LESSIVAGE : Pulvérisation déconseillée '
                        '(Pluie prévue > ${AppConstants.rainLeachingThresholdMm.toStringAsFixed(0)} mm).',
                    ...safeActions,
                  ],
                  ppeRequired: false, // Override if only safe actions remain
                ),
              );
            }
            return rule;
          }).toList();
        }

        // Determine follow-up days...
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
                style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.8), fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 16),

              // --- Matched agro rules grouped by urgency ---
              if (matched.isNotEmpty) ...[
                for (final group in _groupByUrgency(matched).entries) ...[
                  _UrgencySectionHeader(
                    urgency: group.key,
                    count: group.value.length,
                  ),
                  const SizedBox(height: 8),
                  for (final rule in group.value)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _AgroRuleCard(
                        rule: rule,
                        parcelArea: GeoUtils.polygonAreaHa(parcel.boundary),
                      ),
                    ),
                  const SizedBox(height: 6),
                ],
              ] else ...[
                _NoMatchCard(),
                const SizedBox(height: 10),
              ],

              const SizedBox(height: 8),

              // --- Follow-up timeline (J+X) ---
              _FollowupTimeline(
                followupDays: followupDays,
                nextVisit: nextVisit,
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
class _AgroRuleCard extends ConsumerStatefulWidget {
  const _AgroRuleCard({required this.rule, required this.parcelArea});
  final AgroRule rule;
  final double parcelArea;

  @override
  ConsumerState<_AgroRuleCard> createState() => _AgroRuleCardState();
}

class _AgroRuleCardState extends ConsumerState<_AgroRuleCard> {
  bool _speaking = false;

  AgroRule get rule => widget.rule;
  double get parcelArea => widget.parcelArea;

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

  /// Builds the spoken script from the structured recommendation : title,
  /// diagnosis, then each action prefixed with an ordinal so the user can
  /// keep track without seeing the screen.
  String _buildSpeechScript(AppLanguage lang) {
    final rec = rule.recommendation;
    final actions = rec.getActionsFor(lang);
    final buffer = StringBuffer()
      ..writeln(rec.title);
    
    if (rule.scientificName != null) {
      buffer.writeln('(${rule.scientificName})');
    }
    
    buffer.writeln(rule.diagnosis);
    
    if (rec.activeIngredients.isNotEmpty) {
      buffer.writeln('${lang == AppLanguage.wo ? "Matière active" : "Matière active"} : ${rec.activeIngredients.join(", ")}');
    }
    
    buffer.writeln(lang == AppLanguage.fr ? '\nActions :' : '\nAction :');
    for (var i = 0; i < actions.length; i++) {
      buffer.writeln('${i + 1}. ${actions[i]}');
    }
    if (rec.ppeRequired) {
      buffer.writeln(
        lang == AppLanguage.wo 
          ? '\nAttention : Équipement de protection individuelle obligatoire.' 
          : '\nAttention : équipement de protection individuelle obligatoire.',
      );
    }
    return buffer.toString();
  }

  Future<void> _toggleSpeak() async {
    final tts = ref.read(ttsServiceProvider);
    if (_speaking) {
      await tts.stop();
      if (mounted) setState(() => _speaking = false);
      return;
    }
    final lang = ref.read(settingsProvider).language;
    setState(() => _speaking = true);
    await tts.speak(_buildSpeechScript(lang), lang: lang);
    if (!mounted) return;
    setState(() => _speaking = false);
  }

  Future<void> _shareToFarmer() async {
    final lang = ref.read(settingsProvider).language;
    // Prefix the message specifically for the farmer
    final prefix = lang == AppLanguage.fr 
        ? "Bonjour, suite à ma visite de votre champ, voici mes recommandations :\n\n"
        : "Nuyu naa la, ginaaw bi ma gisee sa tool bi, lii laa la digal nga def ko :\n\n";
    
    final text = prefix + _buildSpeechScript(lang);
    
    // We try to launch a generic SMS intent.
    // Use `sms:?body=` for standard cross-platform behavior.
    final uri = Uri.parse('sms:?body=${Uri.encodeComponent(text)}');
    
    try {
      if (await url_launcher.canLaunchUrl(uri)) {
        await url_launcher.launchUrl(uri);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Impossible d\'ouvrir l\'application SMS ou WhatsApp.'),
              backgroundColor: AppColors.danger,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Share error: $e');
    }
  }

  Future<void> _orderInput() async {
    final rec = rule.recommendation;
    final dynamicPrice = ref.read(pricingServiceProvider).getEffectivePrice(
          rec.title,
          rec.costFcfaPerHa,
        );
    final totalCost = (dynamicPrice * parcelArea).round();
    
    final message = "COMMANDE PETALIA :\n"
        "Produit : ${rec.title}\n"
        "Surface : ${parcelArea.toStringAsFixed(2)} Ha\n"
        "Prix Unitaire : $dynamicPrice FCFA/Ha\n"
        "Total estimé : $totalCost FCFA\n\n"
        "Veuillez confirmer la disponibilité pour livraison.";

    final uri = Uri.parse('sms:?body=${Uri.encodeComponent(message)}');
    
    try {
      if (await url_launcher.canLaunchUrl(uri)) {
        await url_launcher.launchUrl(uri);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Impossible d\'ouvrir l\'application SMS.'),
              backgroundColor: AppColors.danger,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Order error: $e');
    }
  }

  @override
  void dispose() {
    // Don't keep speaking after the user navigates away.
    ref.read(ttsServiceProvider).stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rec = rule.recommendation;
    final lang = ref.watch(settingsProvider).language;
    final localizedActions = rec.getActionsFor(lang);
    final isHighUrgency = rule.urgency == RuleUrgency.high;

    final dynamicPrice = ref.watch(pricingServiceProvider).getEffectivePrice(
          rec.title,
          rec.costFcfaPerHa,
        );
    final totalCost = (dynamicPrice * parcelArea).round();
    final hasScientificContext = rule.scientificContext != null && rule.scientificContext!.isNotEmpty;
    
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
                    if (rule.scientificName != null)
                      Text(
                        rule.scientificName!,
                        style: TextStyle(
                            color: _color.withValues(alpha: 0.8),
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                            fontWeight: FontWeight.w600),
                      ),
                    const SizedBox(height: 2),
                    Text(
                      rule.diagnosis,
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.8), fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              // Listen button — only on high-urgency cards (P4.4). Field
              // workers handling something dangerous deserve to hear the
              // instructions instead of squinting at the phone in sunlight.
              if (isHighUrgency)
                IconButton(
                  tooltip: _speaking ? 'Arrêter' : 'Écouter',
                  onPressed: _toggleSpeak,
                  icon: Icon(
                    _speaking
                        ? Icons.stop_circle_rounded
                        : Icons.volume_up_rounded,
                    color: _color,
                  ),
                ),
            ],
          ),
          
          // Scientific Context Toggle (Fiche Technique)
          if (hasScientificContext) ...[
            const SizedBox(height: 12),
            _ScientificContextSection(contextText: rule.scientificContext!),
          ],
          
          const SizedBox(height: 12),

          // Actions list
          for (final action in localizedActions)
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
                        style: TextStyle(fontSize: 13, height: 1.4, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.9), fontWeight: FontWeight.w500)),
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
              if (dynamicPrice > 0) ...[
                _Chip(
                  icon: Icons.monetization_on_rounded,
                  label: '$dynamicPrice FCFA/ha',
                ),
                _Chip(
                  icon: Icons.account_balance_wallet_rounded,
                  label: 'Total : $totalCost FCFA',
                  color: AppColors.accent,
                ),
              ],
              if (rec.delayBeforeHarvestDays > 0)
                _Chip(
                  icon: Icons.timer_rounded,
                  label: 'DAR ${rec.delayBeforeHarvestDays} j',
                  color: AppColors.warning,
                ),
              if (rec.mitigationType != null)
                _Chip(
                  icon: Icons.auto_awesome_motion_rounded,
                  label: rec.mitigationType!.toUpperCase(),
                  color: AppColors.primary,
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

          // Active Ingredients
          if (rec.activeIngredients.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final ing in rec.activeIngredients)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2)),
                    ),
                    child: Text(
                      ing,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
              ],
            ),
          ],

          // Commercial Specialties (Step 3.2)
          () {
            final commercialNames = PesticideCatalog.getCommercialNames(rec.title);
            if (commercialNames.isEmpty) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.storefront_rounded, size: 16, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Marques : ${commercialNames.join(", ")}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }(),

          // Share to Farmer (SMS/WhatsApp) - Phase 1
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _shareToFarmer,
              icon: const Icon(Icons.share_rounded),
              label: const Text('Partager au producteur (SMS/WhatsApp)'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),

          // Mobile Money Ordering (Step 4.2)
          if (rec.costFcfaPerHa > 0) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _orderInput,
                icon: const Icon(Icons.shopping_cart_checkout_rounded),
                label: const Text('Commander cet intrant (SMS / Order)'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],

          // Source
          if (rule.validatedBy.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Source : ${rule.validatedBy}',
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],

          // Sprayer Calibration (Step 1.3)
          if (rec.actions.any((a) => a.contains('pulvérisation') || a.contains('traiter'))) ...[
            const SizedBox(height: 12),
            SprayerCalculator(rule: rule, parcelArea: parcelArea),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Scientific Context Expandable Section
// ---------------------------------------------------------------------------
class _ScientificContextSection extends StatefulWidget {
  const _ScientificContextSection({required this.contextText});
  final String contextText;

  @override
  State<_ScientificContextSection> createState() => _ScientificContextSectionState();
}

class _ScientificContextSectionState extends State<_ScientificContextSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.info.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.info.withValues(alpha: 0.15)),
            ),
            child: Row(
              children: [
                const Icon(Icons.menu_book_rounded, size: 16, color: AppColors.info),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Contexte Scientifique & Fiche Technique',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.info),
                  ),
                ),
                Icon(
                  _expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                  size: 18,
                  color: AppColors.info,
                ),
              ],
            ),
          ),
        ),
        if (_expanded) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5)),
            ),
            child: Text(
              widget.contextText,
              style: TextStyle(
                fontSize: 12,
                height: 1.5,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ],
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
          Text(
            'Les symptômes, le stade ou la sévérité ne correspondent pas '
            'aux règles enregistrées. Vous pouvez demander l\'avis d\'un '
            'agronome ci-dessous.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.8), fontSize: 13, height: 1.5),
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
    // 1. Demander confirmation de paiement
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Consultation Expert'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Un agronome senior analysera vos photos et symptômes sous 24h.'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.payments_rounded, color: AppColors.primary),
                  SizedBox(width: 12),
                  Text('Tarif : 5 Crédits', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text('Le paiement sera déduit de votre solde Petalia ou via Wave/Orange Money au clic.', style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Payer & Envoyer')),
        ],
      ),
    );

    if (confirmed != true) return;

    final creditService = widget.ref.read(creditServiceProvider.notifier);
    if (creditService.credits < CreditService.costExpertOpinion) {
      if (!context.mounted) return;
      MessengerUtils.showInfo('Crédits insuffisants pour un avis expert (5 crédits requis).');
      context.push(Routes.wallet);
      return;
    }

    setState(() => _sending = true);
    try {
      await creditService.useCredits(CreditService.costExpertOpinion);
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
        'context': contextText,
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
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Demande envoyee',
                      style: TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 14)),
                  Text(
                    'Un agronome analysera votre cas et vous repondra.',
                    style: TextStyle(
                        color: AppColors.textSecondaryOf(context), fontSize: 12),
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
            ? 'Avis Expert (2 000 FCFA)'
            : 'Demander l\'avis d\'un agronome (2 000 FCFA)',
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Group rules by urgency. Returned LinkedHashMap preserves insertion order
// (high → medium → low) which is also the rendering order in the UI.
// Empty buckets are dropped so the UI never shows an empty section header.
// ---------------------------------------------------------------------------
Map<RuleUrgency, List<AgroRule>> _groupByUrgency(List<AgroRule> rules) {
  final out = <RuleUrgency, List<AgroRule>>{
    RuleUrgency.high: [],
    RuleUrgency.medium: [],
    RuleUrgency.low: [],
  };
  for (final r in rules) {
    out[r.urgency]!.add(r);
  }
  out.removeWhere((_, v) => v.isEmpty);
  return out;
}

// ---------------------------------------------------------------------------
// Urgency section header — colored band with icon, label, count badge.
// ---------------------------------------------------------------------------
class _UrgencySectionHeader extends StatelessWidget {
  const _UrgencySectionHeader({required this.urgency, required this.count});
  final RuleUrgency urgency;
  final int count;

  ({Color color, IconData icon, String label, String hint}) get _spec {
    switch (urgency) {
      case RuleUrgency.high:
        return (
          color: AppColors.danger,
          icon: Icons.priority_high_rounded,
          label: 'Urgent',
          hint: 'A traiter sous 24-48h'
        );
      case RuleUrgency.medium:
        return (
          color: AppColors.warning,
          icon: Icons.warning_amber_rounded,
          label: 'A surveiller',
          hint: 'Action sous quelques jours'
        );
      case RuleUrgency.low:
        return (
          color: AppColors.success,
          icon: Icons.shield_rounded,
          label: 'Preventif',
          hint: 'Bonnes pratiques'
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = _spec;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: s.color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(color: s.color, width: 4),
        ),
      ),
      child: Row(
        children: [
          Icon(s.icon, color: s.color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.label,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: s.color,
                  ),
                ),
                Text(
                  s.hint,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textMutedOf(context),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: s.color,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Follow-up timeline — horizontal mini-calendar showing day 0 (today) and
// the recommended next visit at J+followupDays. Falls back to a simple card
// when followupDays > 14 (timeline becomes unreadable beyond 2 weeks).
// ---------------------------------------------------------------------------
class _FollowupTimeline extends StatelessWidget {
  const _FollowupTimeline({
    required this.followupDays,
    required this.nextVisit,
  });
  final int followupDays;
  final DateTime nextVisit;

  @override
  Widget build(BuildContext context) {
    if (followupDays > 14) {
      return _FollowupSimpleCard(
        followupDays: followupDays,
        nextVisit: nextVisit,
      );
    }
    final today = DateTime.now();
    final days = followupDays + 1; // include today (J+0)
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Prochaine visite',
            style: TextStyle(color: AppColors.textSecondaryOf(context), fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            '${Fmt.date(nextVisit)} · J+$followupDays',
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 56,
            child: LayoutBuilder(
              builder: (_, c) {
                // Each marker is 28px wide and centered on its slot. Slot
                // centers are spaced evenly across `c.maxWidth`. The track
                // stretches between the centers of the first and last slots.
                const markerW = 28.0;
                final slotW = c.maxWidth / days;
                final firstCenter = slotW / 2;
                final lastCenter = c.maxWidth - slotW / 2;
                return Stack(
                  children: [
                    // Track (gray) under all markers.
                    Positioned(
                      left: firstCenter,
                      width: lastCenter - firstCenter,
                      top: 22,
                      child: Container(
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.dividerOf(context),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    // Highlighted segment (primary) from today → next visit.
                    Positioned(
                      left: firstCenter,
                      width: lastCenter - firstCenter,
                      top: 22,
                      child: Container(
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    // Day markers — centered on each slot.
                    for (int i = 0; i < days; i++)
                      Positioned(
                        left: (i + 0.5) * slotW - markerW / 2,
                        top: 0,
                        child: _TimelineMarker(
                          date: today.add(Duration(days: i)),
                          isToday: i == 0,
                          isTarget: i == days - 1,
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineMarker extends StatelessWidget {
  const _TimelineMarker({
    required this.date,
    required this.isToday,
    required this.isTarget,
  });
  final DateTime date;
  final bool isToday;
  final bool isTarget;

  static const _wd = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];

  @override
  Widget build(BuildContext context) {
    final color = isTarget
        ? AppColors.danger
        : (isToday ? AppColors.success : Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.4));
    final highlight = isToday || isTarget;
    return SizedBox(
      width: 28,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _wd[(date.weekday - 1) % 7],
            style: TextStyle(
              fontSize: 9,
              color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
              fontWeight: highlight ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Container(
            height: highlight ? 16 : 10,
            width: highlight ? 16 : 10,
            decoration: BoxDecoration(
              color: highlight ? color : AppColors.dividerOf(context),
              shape: BoxShape.circle,
              border: highlight
                  ? Border.all(color: Colors.white, width: 2.5)
                  : null,
              boxShadow: highlight
                  ? [
                      BoxShadow(
                        color: color.withValues(alpha: 0.35),
                        blurRadius: 6,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${date.day}',
            style: TextStyle(
              fontSize: 11,
              fontWeight: highlight ? FontWeight.w800 : FontWeight.w500,
              color: highlight ? color : Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _FollowupSimpleCard extends StatelessWidget {
  const _FollowupSimpleCard({
    required this.followupDays,
    required this.nextVisit,
  });
  final int followupDays;
  final DateTime nextVisit;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return GlassCard(
      color: colorScheme.surfaceContainerHigh,
      borderOpacity: 0.2,
      child: Row(
        children: [
          Container(
            height: 48,
            width: 48,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
            ),
            child: const Icon(Icons.calendar_month_rounded, color: AppColors.primary, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PROCHAINE VISITE',
                  style: TextStyle(
                    color: colorScheme.onSurface.withValues(alpha: 0.7),
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${Fmt.date(nextVisit)} (J+$followupDays)',
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
