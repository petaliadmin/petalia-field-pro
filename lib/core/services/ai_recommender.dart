import '../fake_api/fake_data.dart';

class AiRecommendation {
  final String title;
  final String detail;
  final String severity; // low / medium / high
  final String category; // irrigation / fertilizer / disease / pest / other

  const AiRecommendation({
    required this.title,
    required this.detail,
    required this.severity,
    required this.category,
  });
}

class _AgroRule {
  final String id;
  final List<String> crops;
  final List<String> symptoms;
  final List<String> growthStages;
  final String title;
  final String detail;
  final String severity;
  final String category;

  const _AgroRule({
    required this.id,
    required this.crops,
    required this.symptoms,
    required this.growthStages,
    required this.title,
    required this.detail,
    required this.severity,
    required this.category,
  });

  bool matches(String crop, List<String> obsSymptoms, String stage) {
    final cropMatch = crops.contains(crop);
    final symMatch = symptoms.any((s) => obsSymptoms.contains(s));
    return cropMatch && symMatch;
  }
}

const _agronomicRules = [
  // Arachide rules
  _AgroRule(
    id: 'ARA-YELLOW-NOD',
    crops: ['arachide'],
    symptoms: ['yellow_leaves', 'nanisme'],
    growthStages: ['vegetative'],
    title: 'Carence azote + nodulation',
    detail:
        'Vérifier nodulation (coupez 1 racine - nodule rose = OK). Si pas de nodulation : NPK 15-15-15 à 50 kg/ha. Ne pas urée sur arachide!',
    severity: 'medium',
    category: 'fertilizer',
  ),
  _AgroRule(
    id: 'ARA-CERCOSPO',
    crops: ['arachide'],
    symptoms: ['taches_brunes', 'taches_noires', 'defoliation'],
    growthStages: ['vegetative', 'flowering'],
    title: 'Cercosporiose probable',
    detail:
        'Fongicide Cuivre (Bouillie bordelaise 1%) + Mancozèbe. Appliquer à 30 et 45 jours. Réduire humidité.',
    severity: 'high',
    category: 'disease',
  ),
  _AgroRule(
    id: 'ARA-ROSETTE',
    crops: ['arachide'],
    symptoms: ['yellow_leaves', 'nanisme', 'mosaique'],
    growthStages: ['vegetative'],
    title: 'Rosette (virus) suspectée',
    detail:
        'Arracher et détruire plantes atteintes. Contrôle pucerons. Variétés résistantes (73-33, Fleur 11).',
    severity: 'high',
    category: 'disease',
  ),
  // Niébé rules
  _AgroRule(
    id: 'NIEBE-PUCERON',
    crops: ['niebe'],
    symptoms: ['yellow_leaves', 'miellat'],
    growthStages: ['vegetative', 'flowering'],
    title: 'Pucerons - risque viral',
    detail:
        'Traitement Neem (5ml/L) ou Acétamipride. Réduire aussi transmission virus.',
    severity: 'medium',
    category: 'pest',
  ),
  _AgroRule(
    id: 'NIEBE-THRIPS',
    crops: ['niebe'],
    symptoms: ['fletrissement', 'fleurs_perdues'],
    growthStages: ['flowering'],
    title: 'Thrips sur fleurs',
    detail:
        'Spinosad. Dates semis décalées pour éviter pic. Réinspecter 7 j après traitement.',
    severity: 'medium',
    category: 'pest',
  ),
  // Mil/Sorgho rules
  _AgroRule(
    id: 'MIL-STRIGA',
    crops: ['mil', 'sorgho'],
    symptoms: ['mauvaise_levee', 'nanisme', 'paleur'],
    growthStages: ['vegetative'],
    title: 'Suspicion de Striga',
    detail:
        'Rotation avec arachide/niebé. Désherbage avant floralescence. Variétés tolérantes. APW 30j avant semis.',
    severity: 'high',
    category: 'other',
  ),
  _AgroRule(
    id: 'MIL-MILDIOU',
    crops: ['mil', 'sorgho'],
    symptoms: ['feuille_blanche', 'nanisme'],
    growthStages: ['vegetative'],
    title: 'Mildiou - urgent',
    detail:
        'Pas de curatif! Variétés résistantes obligatoire. Destruction résidus. Rotation 3 ans.',
    severity: 'high',
    category: 'disease',
  ),
  // Maïs rules
  _AgroRule(
    id: 'MAIS-LEGIONNAIRE',
    crops: ['mais'],
    symptoms: ['defoliation', 'trous_feuilles'],
    growthStages: ['vegetative'],
    title: 'Chenille légionnaire',
    detail:
        'Spinosad ou Bt. Piégeage phéromones. Surveillance jeune plants (15-40 jours).',
    severity: 'high',
    category: 'pest',
  ),
  // Riz rules
  _AgroRule(
    id: 'RIZ-PYRICU',
    crops: ['riz'],
    symptoms: ['taches_brunes', 'taches_allongees', 'pas_grain'],
    growthStages: ['flowering', 'fruiting'],
    title: 'Pyriculariose',
    detail:
        'Tricyclazole ou Azoxystrobine. Drainage périodique. Variétés résistantes (Sahel 108).',
    severity: 'high',
    category: 'disease',
  ),
  // Tomate rules
  _AgroRule(
    id: 'TOM-MILDIOU',
    crops: ['tomate'],
    symptoms: ['taches_noires', 'fruit_pourri'],
    growthStages: ['flowering', 'fruiting'],
    title: 'Mildiou - très grave',
    detail:
        'Mancozèbe en préventif ONLY! Enlever plants atteints. Pas d\'aspersion!',
    severity: 'high',
    category: 'disease',
  ),
  _AgroRule(
    id: 'TOM-TYLCV',
    crops: ['tomate'],
    symptoms: ['yellow_leaves', 'feuille_blanche'],
    growthStages: ['vegetative'],
    title: 'Virus jaunisse',
    detail:
        'Pas de curatif. Variétés résistantes (Mongal F1). Contrôle mouche blanche.',
    severity: 'high',
    category: 'disease',
  ),
  _AgroRule(
    id: 'TOM-BER',
    crops: ['tomate'],
    symptoms: ['fruit_pourri'],
    growthStages: ['fruiting'],
    title: 'BER (carence calcium)',
    detail:
        'Calcium foliaire. Arrosage régulier. Éviter excédent azote. Rééquilibre potassium.',
    severity: 'low',
    category: 'fertilizer',
  ),
  // General rules
  _AgroRule(
    id: 'GEN-DROUGHT',
    crops: ['*'],
    symptoms: ['drought', 'fletrissement', 'yellow_leaves'],
    growthStages: ['*'],
    title: 'Stress hydrique',
    detail: 'Irriguer à l\'aube ou crépuscule. Paillage. 6mm par cycle mini.',
    severity: 'high',
    category: 'irrigation',
  ),
  _AgroRule(
    id: 'GEN-WEEDS',
    crops: ['*'],
    symptoms: ['weeds'],
    growthStages: ['*'],
    title: 'Désherbage urgent',
    detail: 'Désherbage mécanique sous 48h. Concurrence nutriments/eau.',
    severity: 'low',
    category: 'other',
  ),
];

/// Deterministic agronomic rules engine.
/// Takes observation inputs and returns crop-specific actionable recommendations.
class AiRecommender {
  const AiRecommender();

  List<AiRecommendation> recommend({
    required List<String> symptoms,
    required String cropType,
    required String growthStage,
    required double severity, // 0..1
  }) {
    final out = <AiRecommendation>[];

    // 1. Try specific agronomic rules first
    for (final rule in _agronomicRules) {
      if (rule.matches(cropType, symptoms, growthStage)) {
        out.add(
          AiRecommendation(
            title: rule.title,
            detail: rule.detail,
            severity: rule.severity,
            category: rule.category,
          ),
        );
      }
    }

    // 2. Generic rules for unmatched symptoms
    if (symptoms.contains('spots') &&
        !out.any((r) => r.category == 'disease')) {
      out.add(
        const AiRecommendation(
          title: 'Infection fongique possible',
          detail:
              'Fongicide préventif Cuivre. Éviter aspersion 48h. Surveillance.',
          severity: 'high',
          category: 'disease',
        ),
      );
    }
    if (symptoms.contains('pests') && !out.any((r) => r.category == 'pest')) {
      out.add(
        const AiRecommendation(
          title: 'Pression parasitaire',
          detail:
              'Biopicentiel à base de neem sur zones affectées. Surveiller évolution.',
          severity: 'medium',
          category: 'pest',
        ),
      );
    }

    if (out.isEmpty || symptoms.isEmpty) {
      out.add(
        AiRecommendation(
          title: 'Parcelle en bonne santé',
          detail: FakeData.randomPositiveInsight(cropType, growthStage),
          severity: 'low',
          category: 'other',
        ),
      );
    }

    // 3. Follow-up reminder for high severity
    if (severity >= 0.7) {
      out.add(
        const AiRecommendation(
          title: 'Visite suivi recommandée',
          detail: 'Sévérité élevée → revenir dans 3 jours pour réévaluer.',
          severity: 'high',
          category: 'other',
        ),
      );
    }

    return out;
  }
}
