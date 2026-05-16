library;

import '../../../core/services/settings_service.dart';

/// Modèle de règle agronomique consommée par le moteur de recommandation.
///
/// Les règles sont chargées depuis `assets/agro_rules/agro_rules.json` (source
/// de vérité locale) ou, à terme, depuis l'API distante quand
/// `AppConstants.remoteApiEnabled == true`.

class AgroRule {
  /// Identifiant unique (ex: "ARA-R1-YELLOW-SAHEL-RAINY"). Sert de clé pour la
  /// déduplication et la télémétrie.
  final String id;

  /// Culture ciblée (cropId du [CropsCatalog]) ou `"*"` pour une règle
  /// applicable à toutes les cultures.
  final String crop;

  /// Stades BBCH concernés (ids compatibles [BbchStage.id], ex: `flowering`)
  /// ou `["*"]` pour tous stades.
  final List<String> stages;

  /// Symptôme ciblé (ex: `yellow_leaves`, `spots`, `drought`, `pests`,
  /// `weeds`, `healthy`).
  final String symptom;

  /// Saison concernée : `hivernage`, `contreSaison`, `permanent` ou `*`.
  final String season;

  /// Régions administratives où la règle s'applique (ids [SenegalRegions]) ou
  /// `["*"]` pour toutes.
  final List<String> regions;

  /// Sévérité minimale (0..1) à laquelle la règle se déclenche.
  final double severityMin;

  /// Texte de diagnostic affiché au technicien.
  final String diagnosis;

  /// Contexte scientifique et technique (ex: itinéraire technique, noms scientifiques).
  final String? scientificContext;

  /// Nom scientifique du pathogène ou ravageur ciblé (ex: "Spodoptera frugiperda").
  final String? scientificName;

  /// Bloc recommandation structuré.
  final AgroRecommendation recommendation;

  /// Source de validation agronomique (pour traçabilité audit / PDF).
  final String validatedBy;

  const AgroRule({
    required this.id,
    required this.crop,
    required this.stages,
    required this.symptom,
    required this.season,
    required this.regions,
    required this.severityMin,
    required this.diagnosis,
    this.scientificContext,
    this.scientificName,
    required this.recommendation,
    required this.validatedBy,
  });

  factory AgroRule.fromJson(Map<String, dynamic> json) => AgroRule(
        id: json['id'] as String,
        crop: json['crop'] as String,
        stages: ((json['stages'] as List?) ?? const []).cast<String>(),
        symptom: json['symptom'] as String,
        season: (json['season'] as String?) ?? '*',
        regions: ((json['regions'] as List?) ?? const []).cast<String>(),
        severityMin: (json['severityMin'] as num?)?.toDouble() ?? 0.0,
        diagnosis: json['diagnosis'] as String? ?? '',
        scientificContext: json['scientificContext'] as String?,
        scientificName: json['scientificName'] as String?,
        recommendation:
            AgroRecommendation.fromJson(json['recommendation'] as Map<String, dynamic>),
        validatedBy: json['validatedBy'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'crop': crop,
        'stages': stages,
        'symptom': symptom,
        'season': season,
        'regions': regions,
        'severityMin': severityMin,
        'diagnosis': diagnosis,
        if (scientificContext != null) 'scientificContext': scientificContext,
        if (scientificName != null) 'scientificName': scientificName,
        'recommendation': recommendation.toJson(),
        'validatedBy': validatedBy,
      };

  // ---------------------------------------------------------------------------
  // Matching helpers — un champ valant `"*"` est un joker.
  // ---------------------------------------------------------------------------
  bool matches({
    required String crop,
    required String stage,
    required String symptom,
    required String season,
    required String region,
    required double severity,
  }) {
    if (this.symptom != symptom) return false;
    if (this.crop != '*' && this.crop != crop) return false;
    if (!stages.contains('*') && !stages.contains(stage)) return false;
    if (this.season != '*' && this.season != season) return false;
    if (!regions.contains('*') && !regions.contains(region)) return false;
    if (severity < severityMin) return false;
    return true;
  }

  /// Score interne — plus la règle est spécifique, plus son score est élevé
  /// (le moteur trie par score décroissant afin d'afficher les règles les
  /// plus ciblées en premier).
  int specificityScore() {
    var score = 0;
    if (crop != '*') score += 4;
    if (!stages.contains('*')) score += 2;
    if (season != '*') score += 1;
    if (!regions.contains('*')) score += 1;
    return score;
  }

  /// Urgency bucket used by the UI to group recommendations.
  ///
  /// - [RuleUrgency.high]   → red. PPE required OR severity ≥ 0.6.
  /// - [RuleUrgency.medium] → amber. severity ≥ 0.3.
  /// - [RuleUrgency.low]    → green. preventive / informational.
  RuleUrgency get urgency {
    if (recommendation.ppeRequired || severityMin >= 0.6) {
      return RuleUrgency.high;
    }
    if (severityMin >= 0.3) return RuleUrgency.medium;
    return RuleUrgency.low;
  }

  AgroRule copyWith({
    AgroRecommendation? recommendation,
    String? diagnosis,
    String? scientificContext,
    String? scientificName,
  }) =>
      AgroRule(
        id: id,
        crop: crop,
        stages: stages,
        symptom: symptom,
        season: season,
        regions: regions,
        severityMin: severityMin,
        diagnosis: diagnosis ?? this.diagnosis,
        scientificContext: scientificContext ?? this.scientificContext,
        scientificName: scientificName ?? this.scientificName,
        recommendation: recommendation ?? this.recommendation,
        validatedBy: validatedBy,
      );
}

enum RuleUrgency { high, medium, low }

class AgroRecommendation {
  final String title;
  final List<String> actions;
  final int costFcfaPerHa;
  final int delayBeforeHarvestDays;
  final bool ppeRequired;
  final int followupDays;
  final String? resistanceCode;

  /// Matières actives recommandées (ex: ["Acétamipride", "Lambda-cyhalothrine"]).
  final List<String> activeIngredients;

  /// Type de mitigation : chimique, organique, biologique, préventive.
  final String? mitigationType;

  final List<String> actionsWo;
  final List<String> actionsFf;

  const AgroRecommendation({
    required this.title,
    required this.actions,
    required this.costFcfaPerHa,
    required this.delayBeforeHarvestDays,
    required this.ppeRequired,
    required this.followupDays,
    this.resistanceCode,
    this.activeIngredients = const [],
    this.mitigationType,
    this.actionsWo = const [],
    this.actionsFf = const [],
  });

  factory AgroRecommendation.fromJson(Map<String, dynamic> json) =>
      AgroRecommendation(
        title: json['title'] as String? ?? '',
        actions: ((json['actions'] as List?) ?? const []).cast<String>(),
        costFcfaPerHa: (json['costFcfaPerHa'] as num?)?.toInt() ?? 0,
        delayBeforeHarvestDays:
            (json['delayBeforeHarvestDays'] as num?)?.toInt() ?? 0,
        ppeRequired: json['ppeRequired'] as bool? ?? false,
        followupDays: (json['followupDays'] as num?)?.toInt() ?? 7,
        resistanceCode: json['resistanceCode'] as String?,
        activeIngredients: ((json['activeIngredients'] as List?) ?? const []).cast<String>(),
        mitigationType: json['mitigationType'] as String?,
        actionsWo: ((json['actionsWo'] as List?) ?? const []).cast<String>(),
        actionsFf: ((json['actionsFf'] as List?) ?? const []).cast<String>(),
      );

  Map<String, dynamic> toJson() => {
        'title': title,
        'actions': actions,
        'costFcfaPerHa': costFcfaPerHa,
        'delayBeforeHarvestDays': delayBeforeHarvestDays,
        'ppeRequired': ppeRequired,
        'followupDays': followupDays,
        if (resistanceCode != null) 'resistanceCode': resistanceCode,
        'activeIngredients': activeIngredients,
        if (mitigationType != null) 'mitigationType': mitigationType,
        if (actionsWo.isNotEmpty) 'actionsWo': actionsWo,
        if (actionsFf.isNotEmpty) 'actionsFf': actionsFf,
      };

  /// Récupère les actions dans la langue de l'utilisateur. Fallback sur FR.
  List<String> getActionsFor(AppLanguage lang) {
    if (lang == AppLanguage.wo && actionsWo.isNotEmpty) return actionsWo;
    if (lang == AppLanguage.ff && actionsFf.isNotEmpty) return actionsFf;
    return actions;
  }

  /// Calcule le coût réel estimé pour une surface donnée.
  int calculateRealCost(double areaHa) {
    if (costFcfaPerHa <= 0 || areaHa <= 0) return 0;
    return (costFcfaPerHa * areaHa).round();
  }

  AgroRecommendation copyWith({
    List<String>? actions,
    List<String>? actionsWo,
    List<String>? actionsFf,
    bool? ppeRequired,
    List<String>? activeIngredients,
    String? mitigationType,
  }) =>
      AgroRecommendation(
        title: title,
        actions: actions ?? this.actions,
        actionsWo: actionsWo ?? this.actionsWo,
        actionsFf: actionsFf ?? this.actionsFf,
        costFcfaPerHa: costFcfaPerHa,
        delayBeforeHarvestDays: delayBeforeHarvestDays,
        ppeRequired: ppeRequired ?? this.ppeRequired,
        followupDays: followupDays,
        resistanceCode: resistanceCode,
        activeIngredients: activeIngredients ?? this.activeIngredients,
        mitigationType: mitigationType ?? this.mitigationType,
      );
}
