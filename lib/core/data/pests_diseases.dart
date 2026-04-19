library;

import 'package:flutter/material.dart';

class PestDisease {
  final String id;
  final String labelFr;
  final String labelWo;
  final String scientificName;
  final String description;
  final List<String> affectedCrops;
  final List<String> symptoms;
  final String treatment;
  final bool ppeRequired;
  final String severity; // low / medium / high

  const PestDisease({
    required this.id,
    required this.labelFr,
    required this.labelWo,
    required this.scientificName,
    required this.description,
    required this.affectedCrops,
    required this.symptoms,
    required this.treatment,
    required this.ppeRequired,
    required this.severity,
  });
}

class PestsDiseasesCatalog {
  PestsDiseasesCatalog._();

  static const List<PestDisease> all = [
    // ========================================================================
    // ARACHIDE
    // ========================================================================
    PestDisease(
      id: 'cercosporiose_arachide',
      labelFr: 'Cercosporiose',
      labelWo: 'Mbay mbay',
      scientificName: 'Cercospora arachidicola',
      description:
          'Maladie fongique provoquant des tâches brun-rouge sur feuilles. Favorisée par humidité élevée.',
      affectedCrops: ['arachide'],
      symptoms: ['taches_brunes', 'feuilles_jaunes', 'chute_feuilles'],
      treatment:
          'Fongicide à base de cuivre (Bouillie bordelaise 1%) ou Mancozèbe 80g/L. Appliquer à 30 et 45 jours après semis.',
      ppeRequired: true,
      severity: 'high',
    ),
    PestDisease(
      id: 'rosette_arachide',
      labelFr: 'Rosette',
      labelWo: 'Roste',
      scientificName: 'Groundnut rosette virus (GRV)',
      description:
          'Virus transmis par pucerons. Feutilles vert clair en rosette, croissance arrêtée.',
      affectedCrops: ['arachide'],
      symptoms: ['feuilles_jaunes', 'nanisme', 'deformation'],
      treatment:
          'Variétés résistantes (73-33, Fleur 11). Contrôle des pucerons au besoin. Pas de traitement curatif.',
      ppeRequired: false,
      severity: 'high',
    ),
    PestDisease(
      id: 'mottle virus_arachide',
      labelFr: 'Mottle virus',
      labelWo: 'Motel',
      scientificName: 'African groundnut mosaic virus',
      description: 'Virus transmettant mosaïque jaune sur feuilles.',
      affectedCrops: ['arachide'],
      symptoms: ['mosaique_jaune', 'feuilles_deformees'],
      treatment:
          'Arracher et détruire les plantes malades. Utiliser variedades saines.',
      ppeRequired: false,
      severity: 'medium',
    ),
    PestDisease(
      id: 'aphides_arachide',
      labelFr: 'Pucerons',
      labelWo: 'Kisaay',
      scientificName: 'Aphis craccivora',
      description: 'Pucerons noirs suçant la sève et transmettant virus.',
      affectedCrops: ['arachide', 'niebe', 'gombo'],
      symptoms: ['feuilles_colorees', 'miellat', 'fourmis'],
      treatment: 'Neem (5ml/L) ou Acétamipride. Lutte culturale : assolement.',
      ppeRequired: false,
      severity: 'medium',
    ),
    // ========================================================================
    // MIL / SORGHO
    // ========================================================================
    PestDisease(
      id: 'striga_mil',
      labelFr: 'Striga',
      labelWo: 'Xan₃',
      scientificName: 'Striga hermonthica',
      description:
          'Plante parasite attachée aux racines. Forte concurrence hydrique et minérale.',
      affectedCrops: ['mil', 'sorgho', 'mais'],
      symptoms: ['mauvaise_venue', 'florison_retardee', 'paleur'],
      treatment:
          'Rotation avec arachide/niebé. Variétés tolérantes. Désherbage avant floraison.',
      ppeRequired: false,
      severity: 'high',
    ),
    PestDisease(
      id: 'chenille_mineuse_mil',
      labelFr: 'Chenille mineuse',
      labelWo: 'Yappay',
      scientificName: 'Spodoptera exempta',
      description: 'Chenilles défoliatrices réduisant le feuillage.',
      affectedCrops: ['mil', 'sorgho', 'mais'],
      symptoms: ['trous_feuilles', 'defoliation'],
      treatment: 'Bacillus thuringiensis (Bt). Ramassage manuel des pontes.',
      ppeRequired: true,
      severity: 'medium',
    ),
    PestDisease(
      id: 'mildiou_mil',
      labelFr: 'Mildiou',
      labelWo: 'Xob',
      scientificName: 'Sclerospora graminicola',
      description:
          'Champignon dévastateur sur jeunes plants. Feuillex Blanche.',
      affectedCrops: ['mil', 'sorgho'],
      symptoms: ['feuille_blanche', 'nanisme', 'pas_grain'],
      treatment:
          'Variétés résistantes. Pas de fongicide efficace après infection.',
      ppeRequired: false,
      severity: 'high',
    ),
    PestDisease(
      id: 'ergot_sorgho',
      labelFr: 'Ergot',
      labelWo: 'Taan',
      scientificName: 'Claviceps fusiformis',
      description: 'Champignon sur grains. Sécrétion sucréelike « miellat ».',
      affectedCrops: ['sorgho'],
      symptoms: ['grains_noirs', 'miellat', 'mauvaise_floraison'],
      treatment: 'Traitement de semences Imidaclopride. Rotation.',
      ppeRequired: false,
      severity: 'medium',
    ),
    // ========================================================================
    // MAÏS
    // ========================================================================
    PestDisease(
      id: 'chenille_legionnaire_mais',
      labelFr: 'Chenille légionnaire d\'automne',
      labelWo: 'Yappay bu gedd',
      scientificName: 'Spodoptera frugiperda',
      description: 'Ravageur invasif récent en Afrique. Défoliation rapide.',
      affectedCrops: ['mais', 'riz', 'sorgho'],
      symptoms: ['defoliation', 'trous_feuilles', 'chenilles'],
      treatment: 'Spinosad ou Bt. Piégeage à phéromones.',
      ppeRequired: true,
      severity: 'high',
    ),
    PestDisease(
      id: 'helminthosporiose_mais',
      labelFr: 'Helminthosporiose',
      labelWo: 'Takk',
      scientificName: 'Exserohilum turcicum',
      description: 'Tâches allongées brun-gris sur feuilles.',
      affectedCrops: ['mais'],
      symptoms: ['taches_allongees', 'feuilles_sechent'],
      treatment: 'Azoxystrobine ou Mancozèbe. Variétés résistantes.',
      ppeRequired: true,
      severity: 'medium',
    ),
    // ========================================================================
    // RIZ
    // ========================================================================
    PestDisease(
      id: 'pyriculariose_riz',
      labelFr: 'Pyriculariose',
      labelWo: 'Prikul',
      scientificName: 'Magnaporthe oryzae',
      description: 'Plus grave maladie du riz. Tâches elliptiques grises.',
      affectedCrops: ['riz'],
      symptoms: ['taches_elliptiques', 'feuille_sechee', 'piege_grains'],
      treatment:
          'Tricyclazole ou Azoxystrobine. Drainage периodique. Variétés résistantes.',
      ppeRequired: true,
      severity: 'high',
    ),
    PestDisease(
      id: 'rymv_riz',
      labelFr: 'RYMV (Rice Yellow Mosaic Virus)',
      labelWo: 'Raye bu jaarus',
      scientificName: 'Rice yellow mottle virus',
      description: 'Virus transmis par coléoptère. Jaunissement et striures',
      affectedCrops: ['riz'],
      symptoms: ['feuilles_jaunes', 'stries_jaunes', 'nanisme'],
      treatment:
          'Contrôle du coléoptère. Variétés résistantes (Sahel 108). Pas de curatif.',
      ppeRequired: false,
      severity: 'high',
    ),
    PestDisease(
      id: 'foreur_tige_riz',
      labelFr: 'Foreur de tigefeuille',
      labelWo: 'Koor',
      scientificName: 'Tryporyza or notabilis',
      description: 'Larves dans les tigefeuilles. Galles.',
      affectedCrops: ['riz'],
      symptoms: ['galles', 'tige_cassee', 'coeur_dries'],
      treatment: 'Carbofuran en granulés. Drainage. Variétés résistantes.',
      ppeRequired: true,
      severity: 'medium',
    ),
    // ========================================================================
    // TOMATE
    // ========================================================================
    PestDisease(
      id: 'mildiou_tomate',
      labelFr: 'Mildiou',
      labelWo: 'Xob',
      scientificName: 'Phytophthora infestans',
      description: 'Maladie devastating. Tâches noirâtres, moisissure blanche.',
      affectedCrops: ['tomate', 'pomme_de_terre'],
      symptoms: ['taches_noires', 'moississure_blanche', 'fruit_pourris'],
      treatment: 'Mancozèbe en préventif. Éviter irrigation par aspersion.',
      ppeRequired: true,
      severity: 'high',
    ),
    PestDisease(
      id: 'tylcv_tomate',
      labelFr: 'TYLCV (Virus de la jaundice)',
      labelWo: 'Jaunis',
      scientificName: 'Tomato yellow leaf curl virus',
      description: 'Virus transmis par mouche blanche. Jaunissement, curl.',
      affectedCrops: ['tomate'],
      symptoms: ['feuilles_jaunes', 'feuilles_frisees', 'nanisme'],
      treatment: 'Variétés résistantes. Contrôle des mouches blanches.',
      ppeRequired: false,
      severity: 'high',
    ),
    PestDisease(
      id: 'mouche_blanche_tomate',
      labelFr: 'Mouche blanche',
      labelWo: 'Dëppu',
      scientificName: 'Bemisia tabaci',
      description: 'Petit insecte suceur. Transmission virus. Miellat.',
      affectedCrops: ['tomate', 'gombo', 'aubergine'],
      symptoms: ['miellat', 'feuilles_colorees', 'fumagine'],
      treatment: 'Piège jaunes. Savon noir. Acétamipride.',
      ppeRequired: false,
      severity: 'medium',
    ),
    PestDisease(
      id: 'nematodes_tomate',
      labelFr: 'Nématodes',
      labelWo: 'Nematod',
      scientificName: 'Meloidogyne spp.',
      description: 'Vers microscopiques racinaires. Galles.',
      affectedCrops: ['tomate', 'oignon', 'carotte'],
      symptoms: ['flétrissement', 'jaunissement_partiel', 'galles_racines'],
      treatment: 'Rotation longue avec graminées. Solarisation.',
      ppeRequired: false,
      severity: 'medium',
    ),
    PestDisease(
      id: 'acariens_tomate',
      labelFr: 'Acariens',
      labelWo: 'Akari',
      scientificName: 'Tetranychus urticae',
      description: 'Araignée jaune-orange. Points blancs.',
      affectedCrops: ['tomate', 'gombo', 'aubergine'],
      symptoms: ['points_blancs', 'feuille_grise', 'toiles'],
      treatment: 'Soufre mouillable. Acaricide spécifique.',
      ppeRequired: true,
      severity: 'medium',
    ),
    PestDisease(
      id: 'ber_tomate',
      labelFr: 'BER (Blossom End Rot)',
      labelWo: 'Buur',
      scientificName: 'Carence calcium',
      description: 'Tâches noires au bout dufruit. Carence Ca++.',
      affectedCrops: ['tomate', 'poivron'],
      symptoms: ['taches_noires_fruit', 'fruit_deforme'],
      treatment: 'Calcium foliaire. Arrosage régulier. Éviter excédent azote.',
      ppeRequired: false,
      severity: 'low',
    ),
    // ========================================================================
    // OIGNON
    // ========================================================================
    PestDisease(
      id: 'thrips_oignon',
      labelFr: 'Thrips',
      labelWo: 'Trips',
      scientificName: 'Thrips tabaci',
      description: 'Petit insecte suçant cellule. Aspect argenté.',
      affectedCrops: ['oignon', 'ail', 'tomate'],
      symptoms: ['points_argentes', 'feuille_grise', 'deformation'],
      treatment: 'Spinosad ou Acétamipride. Piège bleus.',
      ppeRequired: true,
      severity: 'medium',
    ),
    PestDisease(
      id: 'mildiou_oignon',
      labelFr: 'Mildiou de l\'oignon',
      labelWo: 'Xob soble',
      scientificName: 'Peronospora destructor',
      description: 'Tâches elliptiques jaune paille,velours gris.',
      affectedCrops: ['oignon', 'ail'],
      symptoms: ['taches_jaunes', 'velours_gris', 'feuille_sechee'],
      treatment: 'Mancozèbe en préventif. Variétés résistantes.',
      ppeRequired: true,
      severity: 'medium',
    ),
    PestDisease(
      id: 'pourriture_blanche_oignon',
      labelFr: 'Pourriture blanche',
      labelWo: 'Kor',
      scientificName: 'Sclerotium cepivorum',
      description: 'Champignon racinaire. Blanc cotonneux.',
      affectedCrops: ['oignon', 'ail', 'poireau'],
      symptoms: ['feuille_jaunit', 'pourriture_blanche', 'mort_plante'],
      treatment: 'Rotation 5 ans. Pas de traitement curatif.',
      ppeRequired: false,
      severity: 'high',
    ),
    // ========================================================================
    // NIÉBÉ
    // ========================================================================
    PestDisease(
      id: 'pucerons_niebe',
      labelFr: 'Pucerons',
      labelWo: 'Kisaay',
      scientificName: 'Aphis craccivora',
      description: 'Pucerons suceurs transmettant virus.',
      affectedCrops: ['niebe'],
      symptoms: ['feuilles_colorees', 'miellat', 'fourmis'],
      treatment: 'Neem (5ml/L). Lutte culturale.',
      ppeRequired: false,
      severity: 'medium',
    ),
    PestDisease(
      id: 'thio_niebe',
      labelFr: 'Thrips du niébé',
      labelWo: 'Tab',
      scientificName: 'Megalurothrips sp.',
      description: 'Thrips sur fleurs et jeunes gousses.',
      affectedCrops: ['niebe'],
      symptoms: ['fleurs_perdues', 'grains_deformes'],
      treatment: 'Spinosad. Dates de semis décalées.',
      ppeRequired: true,
      severity: 'medium',
    ),
    // ========================================================================
    // MARAÎCHAGE GÉNÉRAL
    // ========================================================================
    PestDisease(
      id: 'jassides',
      labelFr: 'Jassides',
      labelWo: 'Jasid',
      scientificName: 'Cicadulina spp.',
      description: 'Petites cigales sauteurs. Points blancs.',
      affectedCrops: ['mais', 'tomate', 'poivron'],
      symptoms: ['points_blancs', 'feuille_frisee', 'mosaique'],
      treatment: 'Neem. Piège jaunes. Acétamipride.',
      ppeRequired: false,
      severity: 'low',
    ),
    PestDisease(
      id: 'pucerons_maraichage',
      labelFr: 'Pucerons',
      labelWo: 'Kisaay',
      scientificName: 'Myzus persicae',
      description: 'Pucerons verts transmettre virus.',
      affectedCrops: ['chou', 'laitue', 'carotte', 'tomate'],
      symptoms: ['feuilles_colorees', 'miellat', 'fumagine'],
      treatment: 'Savon noir. Pyréthrines.',
      ppeRequired: false,
      severity: 'low',
    ),
    PestDisease(
      id: 'chenilles_légumes',
      labelFr: 'Chenilles défoliatrices',
      labelWo: 'Yappay',
      scientificName: 'Spodoptera littoralis',
      description: 'Chenilles mangeant feuilles et fruits.',
      affectedCrops: ['tomate', 'chou', 'gombo', 'aubergine'],
      symptoms: ['trous_feuilles', 'defoliation', 'fruit_perce'],
      treatment: 'Bt. Ramassage manuel. Spinosad.',
      ppeRequired: true,
      severity: 'medium',
    ),
  ];

  static List<PestDisease> forCrop(String cropId) {
    return all.where((p) => p.affectedCrops.contains(cropId)).toList();
  }

  static List<String> get allSymptomIds {
    final symptoms = <String>{};
    for (final p in all) {
      symptoms.addAll(p.symptoms);
    }
    return symptoms.toList()..sort();
  }

  static final Map<String, String> symptomLabelsFr = {
    'taches_brunes': 'Taches brunes',
    'taches_elliptiques': 'Taches elliptiques',
    'taches_allongees': 'Taches allongées',
    'taches_noires': 'Taches noires',
    'taches_jaunes': 'Taches jaunes',
    'feuilles_jaunes': 'Feuilles jaunes',
    'feuilles_deformees': 'Feuilles déformées',
    'feuilles_frisees': 'Feuilles frisées',
    'feuilles_sechent': 'Feuilles qui sechent',
    'feuille_blanche': 'Feuille blanche',
    'feuille_grise': 'Feuille grise',
    'deformation': 'Déformation',
    'nanisme': 'Nanisme (croissance arrêtée)',
    'mosaique_jaune': 'Mosaïque jaune',
    'stries_jaunes': 'Stries jaunes',
    'mauvaise_venue': 'Mauvaise levée',
    'florison_retardee': 'Floraison retardée',
    'paleur': 'Paleur anormale',
    'pas_grain': 'Pas de grains',
    'grains_noirs': 'Grains noirs',
    'miellat': 'Miellat (liquide collant)',
    'fourmis': 'Fourmis présentes',
    'trous_feuilles': 'Trous dans les feuilles',
    'defoliation': 'Défoliation importante',
    'galles': 'Galles sur plantes',
    'tige_cassee': 'Tige cassée',
    'coeur_dries': 'Cœur séché',
    'piege_grains': 'Épi vide',
    'fruit_pourris': 'Fruit pourri',
    'fruit_deforme': 'Fruit déformé',
    'points_argentes': 'Points blancs/argentés',
    'points_blancs': 'Points blancs',
    'toiles': 'Toiles d\'araignées',
    'fumagine': 'Fumagine (noir suie)',
    'flétrissement': 'Flétrissement',
    'jaunissement_partiel': 'Jaunissement partiel',
    'galles_racines': 'Galles sur racines',
    'mort_plante': 'Plante mourante',
    'fleurs_perdues': 'Fleurs perdues',
    'grains_deformes': 'Grains déformés',
    'pourriture_blanche': 'Pourriture blanche',
    'velours_gris': 'Velours gris',
    'feuille_sechee': 'Feuille séchée',
    'fruit_perce': 'Fruit percé',
  };
}
