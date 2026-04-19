/// Modèle de règle agronomique consommée par le moteur de recommandation.
///
/// Les règles sont chargées depuis `assets/agro_rules/agro_rules.json` (source
/// de vérité locale) ou, à terme, depuis l'API distante quand
/// `AppConstants.remoteApiEnabled == true`.
library;

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
}

class AgroRecommendation {
  final String title;
  final List<String> actions;
  final int costFcfaPerHa;
  final int delayBeforeHarvestDays;
  final bool ppeRequired;
  final int followupDays;

  const AgroRecommendation({
    required this.title,
    required this.actions,
    required this.costFcfaPerHa,
    required this.delayBeforeHarvestDays,
    required this.ppeRequired,
    required this.followupDays,
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
      );

  Map<String, dynamic> toJson() => {
        'title': title,
        'actions': actions,
        'costFcfaPerHa': costFcfaPerHa,
        'delayBeforeHarvestDays': delayBeforeHarvestDays,
        'ppeRequired': ppeRequired,
        'followupDays': followupDays,
      };
}
