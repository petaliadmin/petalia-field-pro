/// Échelle BBCH (Biologische Bundesanstalt, Bundessortenamt und CHemische
/// Industrie) adaptée aux principales cultures du Sénégal.
///
/// Pour chaque culture du [CropsCatalog], on fournit une suite ordonnée de
/// stades phénologiques `BbchStage` avec :
/// - le code BBCH à deux chiffres (0-99),
/// - un identifiant court (utilisé dans le modèle [Parcel.growthStage] —
///   rétro-compatible avec les valeurs legacy `germination`, `vegetative`,
///   `flowering`, `fruiting`, `maturation`),
/// - un libellé FR,
/// - la borne inférieure de jours après semis (DAS) à laquelle ce stade débute
///   *en conditions typiques Sénégal* (hivernage pluvieux ou contre-saison
///   irriguée). Ces bornes sont **indicatives** et doivent être calées sur le
///   terrain — elles servent uniquement à auto-suggérer le stade.
///
/// Sources consolidées :
/// - Meier, U. (2018) *Growth stages of mono- and dicotyledonous plants*
///   (BBCH Monograph, 3e éd. — Julius Kühn-Institut).
/// - ISRA/CERAAS, guides techniques arachide, mil, sorgho, niébé (2019-2023).
/// - CDH/Niayes, fiches maraîchage (tomate, oignon, piment) 2021.
///
/// ⚠️ Les seuils DAS sont des médianes. Un semis tardif, un stress hydrique
/// ou une variété précoce/tardive décalent la courbe — toujours confirmer
/// visuellement avant d'envoyer une recommandation phyto.
library;

import 'package:flutter/material.dart';
import '../../l10n/gen/app_localizations.dart';

class BbchStage {
  /// Code BBCH (0..99).
  final int code;

  /// Identifiant stable compatible avec [Parcel.growthStage].
  final String id;

  /// Libellé FR (ex: "Levée", "Floraison 50%").
  final String labelFr;

  /// Jours après semis minimum pour entrer dans ce stade (médiane Sénégal).
  final int dasMin;

  const BbchStage({
    required this.code,
    required this.id,
    required this.labelFr,
    required this.dasMin,
  });

  String label(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return switch (id) {
      'semis' => l10n.stageSemis,
      'germination' => l10n.stageGermination,
      'vegetative' => l10n.stageVegetative,
      'flowering' => l10n.stageFlowering,
      'fruiting' => l10n.stageFruiting,
      'maturation' => l10n.stageMaturation,
      _ => labelFr,
    };
  }
}

class BbchCatalog {
  BbchCatalog._();

  /// Map `cropId` → liste ordonnée de stades (du plus précoce au plus tardif).
  ///
  /// Chaque liste **doit** être triée par [BbchStage.dasMin] croissant.
  static const Map<String, List<BbchStage>> _stages = {
    // ------------------------------------------------------------------
    // Arachide (Gerte) — cycle 90-120 j
    // Réf. ISRA/CERAAS, fiche 73-33 / 55-437.
    // ------------------------------------------------------------------
    'arachide': [
      BbchStage(code: 0, id: 'semis', labelFr: 'Semis', dasMin: 0),
      BbchStage(code: 9, id: 'germination', labelFr: 'Levée', dasMin: 5),
      BbchStage(code: 19, id: 'vegetative', labelFr: 'Développement foliaire', dasMin: 12),
      BbchStage(code: 51, id: 'flowering', labelFr: 'Floraison', dasMin: 28),
      BbchStage(code: 71, id: 'fruiting', labelFr: 'Formation gousses', dasMin: 55),
      BbchStage(code: 81, id: 'ripening', labelFr: 'Remplissage gousses', dasMin: 75),
      BbchStage(code: 89, id: 'maturation', labelFr: 'Maturité récolte', dasMin: 95),
    ],

    // ------------------------------------------------------------------
    // Mil (Dugub) — cycle 75-110 j (Souna 3, Thialack 2)
    // ------------------------------------------------------------------
    'mil': [
      BbchStage(code: 0, id: 'semis', labelFr: 'Semis', dasMin: 0),
      BbchStage(code: 9, id: 'germination', labelFr: 'Levée', dasMin: 4),
      BbchStage(code: 19, id: 'vegetative', labelFr: 'Tallage', dasMin: 20),
      BbchStage(code: 31, id: 'stem_elongation', labelFr: 'Montaison', dasMin: 35),
      BbchStage(code: 51, id: 'flowering', labelFr: 'Épiaison', dasMin: 50),
      BbchStage(code: 71, id: 'fruiting', labelFr: 'Grain laiteux', dasMin: 65),
      BbchStage(code: 89, id: 'maturation', labelFr: 'Maturité récolte', dasMin: 85),
    ],

    // ------------------------------------------------------------------
    // Sorgho (Basi) — cycle 90-130 j
    // ------------------------------------------------------------------
    'sorgho': [
      BbchStage(code: 0, id: 'semis', labelFr: 'Semis', dasMin: 0),
      BbchStage(code: 9, id: 'germination', labelFr: 'Levée', dasMin: 5),
      BbchStage(code: 19, id: 'vegetative', labelFr: 'Tallage', dasMin: 22),
      BbchStage(code: 31, id: 'stem_elongation', labelFr: 'Montaison', dasMin: 40),
      BbchStage(code: 51, id: 'flowering', labelFr: 'Épiaison', dasMin: 60),
      BbchStage(code: 71, id: 'fruiting', labelFr: 'Grain laiteux', dasMin: 75),
      BbchStage(code: 89, id: 'maturation', labelFr: 'Maturité récolte', dasMin: 100),
    ],

    // ------------------------------------------------------------------
    // Maïs (Mboq) — cycle 90-120 j
    // ------------------------------------------------------------------
    'mais': [
      BbchStage(code: 0, id: 'semis', labelFr: 'Semis', dasMin: 0),
      BbchStage(code: 9, id: 'germination', labelFr: 'Levée', dasMin: 5),
      BbchStage(code: 15, id: 'vegetative', labelFr: '5 feuilles', dasMin: 20),
      BbchStage(code: 31, id: 'stem_elongation', labelFr: 'Montaison', dasMin: 35),
      BbchStage(code: 51, id: 'flowering', labelFr: 'Panicule / soies', dasMin: 55),
      BbchStage(code: 71, id: 'fruiting', labelFr: 'Remplissage grain', dasMin: 70),
      BbchStage(code: 89, id: 'maturation', labelFr: 'Maturité récolte', dasMin: 95),
    ],

    // ------------------------------------------------------------------
    // Riz (Ceeb) — cycle 90-140 j (Sahel 108, Sahel 202)
    // ------------------------------------------------------------------
    'riz': [
      BbchStage(code: 0, id: 'semis', labelFr: 'Semis / repiquage', dasMin: 0),
      BbchStage(code: 13, id: 'germination', labelFr: 'Levée', dasMin: 7),
      BbchStage(code: 21, id: 'vegetative', labelFr: 'Tallage', dasMin: 25),
      BbchStage(code: 31, id: 'stem_elongation', labelFr: 'Montaison', dasMin: 50),
      BbchStage(code: 51, id: 'flowering', labelFr: 'Épiaison / floraison', dasMin: 70),
      BbchStage(code: 75, id: 'fruiting', labelFr: 'Grain pâteux', dasMin: 90),
      BbchStage(code: 89, id: 'maturation', labelFr: 'Maturité récolte', dasMin: 110),
    ],

    // ------------------------------------------------------------------
    // Niébé (Niebe) — cycle 60-90 j (Mouride, Melakh)
    // ------------------------------------------------------------------
    'niebe': [
      BbchStage(code: 0, id: 'semis', labelFr: 'Semis', dasMin: 0),
      BbchStage(code: 9, id: 'germination', labelFr: 'Levée', dasMin: 4),
      BbchStage(code: 19, id: 'vegetative', labelFr: 'Développement foliaire', dasMin: 15),
      BbchStage(code: 51, id: 'flowering', labelFr: 'Floraison', dasMin: 35),
      BbchStage(code: 71, id: 'fruiting', labelFr: 'Formation gousses', dasMin: 45),
      BbchStage(code: 89, id: 'maturation', labelFr: 'Maturité récolte', dasMin: 65),
    ],

    // ------------------------------------------------------------------
    // Haricot vert — cycle 55-75 j
    // ------------------------------------------------------------------
    'haricot_vert': [
      BbchStage(code: 0, id: 'semis', labelFr: 'Semis', dasMin: 0),
      BbchStage(code: 9, id: 'germination', labelFr: 'Levée', dasMin: 5),
      BbchStage(code: 19, id: 'vegetative', labelFr: 'Développement foliaire', dasMin: 15),
      BbchStage(code: 51, id: 'flowering', labelFr: 'Floraison', dasMin: 30),
      BbchStage(code: 71, id: 'fruiting', labelFr: 'Formation gousses', dasMin: 40),
      BbchStage(code: 89, id: 'maturation', labelFr: 'Récolte', dasMin: 55),
    ],

    // ------------------------------------------------------------------
    // Tomate (Tamaate) — cycle 90-120 j après repiquage
    // ------------------------------------------------------------------
    'tomate': [
      BbchStage(code: 0, id: 'semis', labelFr: 'Semis pépinière', dasMin: 0),
      BbchStage(code: 9, id: 'germination', labelFr: 'Levée', dasMin: 7),
      BbchStage(code: 15, id: 'transplanting', labelFr: 'Repiquage', dasMin: 25),
      BbchStage(code: 19, id: 'vegetative', labelFr: 'Reprise / croissance', dasMin: 35),
      BbchStage(code: 51, id: 'flowering', labelFr: 'Floraison 1er bouquet', dasMin: 50),
      BbchStage(code: 71, id: 'fruiting', labelFr: 'Nouaison', dasMin: 60),
      BbchStage(code: 81, id: 'ripening', labelFr: 'Véraison', dasMin: 80),
      BbchStage(code: 89, id: 'maturation', labelFr: 'Récolte', dasMin: 95),
    ],

    // ------------------------------------------------------------------
    // Oignon (Soble) — cycle 110-150 j
    // ------------------------------------------------------------------
    'oignon': [
      BbchStage(code: 0, id: 'semis', labelFr: 'Semis pépinière', dasMin: 0),
      BbchStage(code: 9, id: 'germination', labelFr: 'Levée', dasMin: 8),
      BbchStage(code: 15, id: 'transplanting', labelFr: 'Repiquage', dasMin: 40),
      BbchStage(code: 19, id: 'vegetative', labelFr: 'Développement foliaire', dasMin: 55),
      BbchStage(code: 41, id: 'bulb_formation', labelFr: 'Bulbaison', dasMin: 90),
      BbchStage(code: 49, id: 'ripening', labelFr: 'Grossissement bulbe', dasMin: 110),
      BbchStage(code: 89, id: 'maturation', labelFr: 'Maturité récolte', dasMin: 130),
    ],

    // ------------------------------------------------------------------
    // Chou (Suu) — cycle 70-100 j
    // ------------------------------------------------------------------
    'chou': [
      BbchStage(code: 0, id: 'semis', labelFr: 'Semis pépinière', dasMin: 0),
      BbchStage(code: 9, id: 'germination', labelFr: 'Levée', dasMin: 6),
      BbchStage(code: 15, id: 'transplanting', labelFr: 'Repiquage', dasMin: 25),
      BbchStage(code: 19, id: 'vegetative', labelFr: 'Développement foliaire', dasMin: 35),
      BbchStage(code: 41, id: 'head_formation', labelFr: 'Pommaison', dasMin: 55),
      BbchStage(code: 89, id: 'maturation', labelFr: 'Récolte', dasMin: 75),
    ],

    // ------------------------------------------------------------------
    // Piment (Kaani) — cycle 90-150 j
    // ------------------------------------------------------------------
    'piment': [
      BbchStage(code: 0, id: 'semis', labelFr: 'Semis pépinière', dasMin: 0),
      BbchStage(code: 9, id: 'germination', labelFr: 'Levée', dasMin: 10),
      BbchStage(code: 15, id: 'transplanting', labelFr: 'Repiquage', dasMin: 35),
      BbchStage(code: 19, id: 'vegetative', labelFr: 'Croissance', dasMin: 50),
      BbchStage(code: 51, id: 'flowering', labelFr: 'Floraison', dasMin: 70),
      BbchStage(code: 71, id: 'fruiting', labelFr: 'Nouaison', dasMin: 85),
      BbchStage(code: 89, id: 'maturation', labelFr: 'Récolte', dasMin: 105),
    ],

    // ------------------------------------------------------------------
    // Gombo (Kañja) — cycle 60-120 j
    // ------------------------------------------------------------------
    'gombo': [
      BbchStage(code: 0, id: 'semis', labelFr: 'Semis', dasMin: 0),
      BbchStage(code: 9, id: 'germination', labelFr: 'Levée', dasMin: 6),
      BbchStage(code: 19, id: 'vegetative', labelFr: 'Croissance', dasMin: 20),
      BbchStage(code: 51, id: 'flowering', labelFr: 'Floraison', dasMin: 40),
      BbchStage(code: 71, id: 'fruiting', labelFr: 'Formation capsules', dasMin: 50),
      BbchStage(code: 89, id: 'maturation', labelFr: 'Récolte continue', dasMin: 60),
    ],

    // ------------------------------------------------------------------
    // Aubergine (Jaxatu) — cycle 90-150 j
    // ------------------------------------------------------------------
    'aubergine': [
      BbchStage(code: 0, id: 'semis', labelFr: 'Semis pépinière', dasMin: 0),
      BbchStage(code: 9, id: 'germination', labelFr: 'Levée', dasMin: 10),
      BbchStage(code: 15, id: 'transplanting', labelFr: 'Repiquage', dasMin: 35),
      BbchStage(code: 19, id: 'vegetative', labelFr: 'Croissance', dasMin: 50),
      BbchStage(code: 51, id: 'flowering', labelFr: 'Floraison', dasMin: 70),
      BbchStage(code: 71, id: 'fruiting', labelFr: 'Nouaison', dasMin: 85),
      BbchStage(code: 89, id: 'maturation', labelFr: 'Récolte', dasMin: 105),
    ],

    // ------------------------------------------------------------------
    // Carotte — cycle 90-120 j
    // ------------------------------------------------------------------
    'carotte': [
      BbchStage(code: 0, id: 'semis', labelFr: 'Semis', dasMin: 0),
      BbchStage(code: 9, id: 'germination', labelFr: 'Levée', dasMin: 12),
      BbchStage(code: 19, id: 'vegetative', labelFr: 'Développement foliaire', dasMin: 30),
      BbchStage(code: 41, id: 'root_formation', labelFr: 'Grossissement racine', dasMin: 60),
      BbchStage(code: 89, id: 'maturation', labelFr: 'Récolte', dasMin: 95),
    ],

    // ------------------------------------------------------------------
    // Laitue — cycle 45-75 j
    // ------------------------------------------------------------------
    'laitue': [
      BbchStage(code: 0, id: 'semis', labelFr: 'Semis pépinière', dasMin: 0),
      BbchStage(code: 9, id: 'germination', labelFr: 'Levée', dasMin: 5),
      BbchStage(code: 15, id: 'transplanting', labelFr: 'Repiquage', dasMin: 20),
      BbchStage(code: 19, id: 'vegetative', labelFr: 'Croissance rosette', dasMin: 28),
      BbchStage(code: 41, id: 'head_formation', labelFr: 'Pommaison', dasMin: 40),
      BbchStage(code: 89, id: 'maturation', labelFr: 'Récolte', dasMin: 50),
    ],

    // ------------------------------------------------------------------
    // Pastèque (Xaal) — cycle 70-100 j
    // ------------------------------------------------------------------
    'pasteque': [
      BbchStage(code: 0, id: 'semis', labelFr: 'Semis', dasMin: 0),
      BbchStage(code: 9, id: 'germination', labelFr: 'Levée', dasMin: 6),
      BbchStage(code: 19, id: 'vegetative', labelFr: 'Développement rames', dasMin: 20),
      BbchStage(code: 51, id: 'flowering', labelFr: 'Floraison', dasMin: 35),
      BbchStage(code: 71, id: 'fruiting', labelFr: 'Nouaison', dasMin: 45),
      BbchStage(code: 81, id: 'ripening', labelFr: 'Grossissement fruits', dasMin: 60),
      BbchStage(code: 89, id: 'maturation', labelFr: 'Récolte', dasMin: 80),
    ],

    // ------------------------------------------------------------------
    // Patate douce (Patasa) — cycle 90-150 j
    // ------------------------------------------------------------------
    'patate_douce': [
      BbchStage(code: 0, id: 'semis', labelFr: 'Plantation boutures', dasMin: 0),
      BbchStage(code: 9, id: 'germination', labelFr: 'Reprise', dasMin: 10),
      BbchStage(code: 19, id: 'vegetative', labelFr: 'Développement rames', dasMin: 30),
      BbchStage(code: 41, id: 'root_formation', labelFr: 'Tubérisation', dasMin: 60),
      BbchStage(code: 89, id: 'maturation', labelFr: 'Récolte', dasMin: 110),
    ],

    // ------------------------------------------------------------------
    // Pomme de terre — cycle 75-110 j
    // ------------------------------------------------------------------
    'pomme_de_terre': [
      BbchStage(code: 0, id: 'semis', labelFr: 'Plantation', dasMin: 0),
      BbchStage(code: 9, id: 'germination', labelFr: 'Levée', dasMin: 14),
      BbchStage(code: 19, id: 'vegetative', labelFr: 'Croissance', dasMin: 30),
      BbchStage(code: 41, id: 'tuber_formation', labelFr: 'Tubérisation', dasMin: 45),
      BbchStage(code: 51, id: 'flowering', labelFr: 'Floraison', dasMin: 55),
      BbchStage(code: 89, id: 'maturation', labelFr: 'Défanage / récolte', dasMin: 85),
    ],

    // ------------------------------------------------------------------
    // Manioc (Ñambi) — cycle 270-365 j
    // ------------------------------------------------------------------
    'manioc': [
      BbchStage(code: 0, id: 'semis', labelFr: 'Plantation boutures', dasMin: 0),
      BbchStage(code: 9, id: 'germination', labelFr: 'Reprise', dasMin: 15),
      BbchStage(code: 19, id: 'vegetative', labelFr: 'Développement aérien', dasMin: 60),
      BbchStage(code: 41, id: 'root_formation', labelFr: 'Tubérisation', dasMin: 120),
      BbchStage(code: 89, id: 'maturation', labelFr: 'Maturité récolte', dasMin: 270),
    ],

    // ------------------------------------------------------------------
    // Mangue (Mango) — arbre pérenne, cycle fructification ~120-180 j
    // DAS compté depuis floraison observée.
    // ------------------------------------------------------------------
    'mangue': [
      BbchStage(code: 51, id: 'flowering', labelFr: 'Floraison', dasMin: 0),
      BbchStage(code: 71, id: 'fruiting', labelFr: 'Nouaison', dasMin: 15),
      BbchStage(code: 75, id: 'growing', labelFr: 'Grossissement', dasMin: 45),
      BbchStage(code: 81, id: 'ripening', labelFr: 'Maturation', dasMin: 120),
      BbchStage(code: 89, id: 'maturation', labelFr: 'Récolte', dasMin: 150),
    ],

    // ------------------------------------------------------------------
    // Anacarde (Darkase) — pérenne
    // ------------------------------------------------------------------
    'anacarde': [
      BbchStage(code: 51, id: 'flowering', labelFr: 'Floraison', dasMin: 0),
      BbchStage(code: 71, id: 'fruiting', labelFr: 'Nouaison', dasMin: 20),
      BbchStage(code: 81, id: 'ripening', labelFr: 'Grossissement noix', dasMin: 80),
      BbchStage(code: 89, id: 'maturation', labelFr: 'Récolte', dasMin: 180),
    ],

    // ------------------------------------------------------------------
    // Banane (Banaana) — pérenne, cycle ~270-365 j
    // ------------------------------------------------------------------
    'banane': [
      BbchStage(code: 0, id: 'semis', labelFr: 'Plantation rejets', dasMin: 0),
      BbchStage(code: 19, id: 'vegetative', labelFr: 'Croissance pseudo-tronc', dasMin: 30),
      BbchStage(code: 51, id: 'flowering', labelFr: 'Floraison / régime', dasMin: 180),
      BbchStage(code: 71, id: 'fruiting', labelFr: 'Formation doigts', dasMin: 200),
      BbchStage(code: 89, id: 'maturation', labelFr: 'Récolte', dasMin: 300),
    ],

    // ------------------------------------------------------------------
    // Canne à sucre (Kan) — cycle 300-360 j
    // ------------------------------------------------------------------
    'canne_a_sucre': [
      BbchStage(code: 0, id: 'semis', labelFr: 'Plantation boutures', dasMin: 0),
      BbchStage(code: 9, id: 'germination', labelFr: 'Germination', dasMin: 20),
      BbchStage(code: 19, id: 'vegetative', labelFr: 'Tallage', dasMin: 60),
      BbchStage(code: 31, id: 'stem_elongation', labelFr: 'Grande croissance', dasMin: 150),
      BbchStage(code: 89, id: 'maturation', labelFr: 'Maturité / récolte', dasMin: 300),
    ],

    // ------------------------------------------------------------------
    // Moringa (Nébédaay) — pérenne, coupes répétées
    // ------------------------------------------------------------------
    'moringa': [
      BbchStage(code: 0, id: 'semis', labelFr: 'Semis / plantation', dasMin: 0),
      BbchStage(code: 9, id: 'germination', labelFr: 'Levée', dasMin: 10),
      BbchStage(code: 19, id: 'vegetative', labelFr: 'Croissance feuillue', dasMin: 45),
      BbchStage(code: 41, id: 'harvest', labelFr: 'Première coupe feuilles', dasMin: 75),
      BbchStage(code: 51, id: 'flowering', labelFr: 'Floraison', dasMin: 180),
      BbchStage(code: 89, id: 'maturation', labelFr: 'Gousses mûres', dasMin: 240),
    ],
  };

  /// Suite ordonnée de stades pour la culture (par id stable), ou `null`
  /// si la culture n'est pas référencée.
  static List<BbchStage>? stagesFor(String cropId) => _stages[cropId];

  /// Estime le stade BBCH courant pour la culture et le nombre de jours
  /// après semis (DAS) fournis.
  ///
  /// Retourne le **dernier** stade dont `dasMin <= das`. Retourne `null` si :
  /// - la culture n'est pas référencée,
  /// - `das < 0`.
  static BbchStage? estimateStage({
    required String cropId,
    required int das,
  }) {
    if (das < 0) return null;
    final list = _stages[cropId];
    if (list == null || list.isEmpty) return null;
    BbchStage? current;
    for (final s in list) {
      if (s.dasMin <= das) {
        current = s;
      } else {
        break;
      }
    }
    return current;
  }
}
