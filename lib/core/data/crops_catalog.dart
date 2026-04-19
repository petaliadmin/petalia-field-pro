/// Catalogue des cultures pratiquées au Sénégal (bassin arachidier, Niayes,
/// vallée du fleuve, Casamance).
///
/// Chaque [CropDefinition] fournit :
/// - un identifiant stable (utilisé côté stockage / règles agronomiques),
/// - un libellé FR + WO,
/// - les variétés courantes diffusées par l'ISRA / la SEMSEN,
/// - la saison principale et la durée de cycle indicative (jours).
///
/// Les libellés wolof utilisent l'orthographe du décret 2005-980 — à valider
/// par le CLAD / IFAN avant mise en production.
library;

import 'package:flutter/material.dart';

enum CropSeason { hivernage, contreSaison, permanent }

class CropDefinition {
  final String id; // lowercase ASCII, stable
  final String labelFr;
  final String labelWo;
  final IconData icon;
  final Color color;
  final CropSeason season;
  final int cycleDaysMin;
  final int cycleDaysMax;
  final List<String> varieties;

  const CropDefinition({
    required this.id,
    required this.labelFr,
    required this.labelWo,
    required this.icon,
    required this.color,
    required this.season,
    required this.cycleDaysMin,
    required this.cycleDaysMax,
    required this.varieties,
  });

  int get cycleDaysAverage => (cycleDaysMin + cycleDaysMax) ~/ 2;
}

class CropsCatalog {
  CropsCatalog._();

  static const List<CropDefinition> all = [
    // ------------------------------------------------------------------
    // Céréales
    // ------------------------------------------------------------------
    CropDefinition(
      id: 'mais',
      labelFr: 'Maïs',
      labelWo: 'Mboq',
      icon: Icons.grass_rounded,
      color: Color(0xFFE3A51A),
      season: CropSeason.hivernage,
      cycleDaysMin: 90,
      cycleDaysMax: 120,
      varieties: ['Jaabaar', 'Synthetic C', 'Early Thai', 'Obatampa'],
    ),
    CropDefinition(
      id: 'mil',
      labelFr: 'Mil',
      labelWo: 'Dugub',
      icon: Icons.spa_rounded,
      color: Color(0xFFBBA55B),
      season: CropSeason.hivernage,
      cycleDaysMin: 75,
      cycleDaysMax: 110,
      varieties: ['Souna 3', 'Thialack 2', 'IBV 8004', 'Nafoore'],
    ),
    CropDefinition(
      id: 'sorgho',
      labelFr: 'Sorgho',
      labelWo: 'Basi',
      icon: Icons.grass_rounded,
      color: Color(0xFFB7742F),
      season: CropSeason.hivernage,
      cycleDaysMin: 90,
      cycleDaysMax: 130,
      varieties: ['Faourou', 'Nguinthe', 'CE-151', '621B'],
    ),
    CropDefinition(
      id: 'riz',
      labelFr: 'Riz',
      labelWo: 'Ceeb',
      icon: Icons.rice_bowl_rounded,
      color: Color(0xFF7CAE5B),
      season: CropSeason.hivernage,
      cycleDaysMin: 90,
      cycleDaysMax: 140,
      varieties: ['Sahel 108', 'Sahel 202', 'Sahel 134', 'Nerica 4', 'IR1529'],
    ),
    // ------------------------------------------------------------------
    // Légumineuses
    // ------------------------------------------------------------------
    CropDefinition(
      id: 'arachide',
      labelFr: 'Arachide',
      labelWo: 'Gerte',
      icon: Icons.eco_rounded,
      color: Color(0xFFC28E3A),
      season: CropSeason.hivernage,
      cycleDaysMin: 90,
      cycleDaysMax: 120,
      varieties: ['73-33', '55-437', 'Fleur 11', 'GC-8-35', '73-30', 'Essamay'],
    ),
    CropDefinition(
      id: 'niebe',
      labelFr: 'Niébé',
      labelWo: 'Niebe',
      icon: Icons.eco_rounded,
      color: Color(0xFF9AB76A),
      season: CropSeason.hivernage,
      cycleDaysMin: 60,
      cycleDaysMax: 90,
      varieties: ['Mouride', 'Melakh', 'Yacine', 'Bambey 21'],
    ),
    CropDefinition(
      id: 'haricot_vert',
      labelFr: 'Haricot vert',
      labelWo: 'Ñebbe bu wert',
      icon: Icons.grass_rounded,
      color: Color(0xFF3F9E3E),
      season: CropSeason.contreSaison,
      cycleDaysMin: 55,
      cycleDaysMax: 75,
      varieties: ['Jade', 'Paulista', 'Serengeti', 'Amy'],
    ),
    // ------------------------------------------------------------------
    // Maraîchage (Niayes, horticulture)
    // ------------------------------------------------------------------
    CropDefinition(
      id: 'tomate',
      labelFr: 'Tomate',
      labelWo: 'Tamaate',
      icon: Icons.local_florist_rounded,
      color: Color(0xFFD94A38),
      season: CropSeason.contreSaison,
      cycleDaysMin: 90,
      cycleDaysMax: 120,
      varieties: ['Mongal F1', 'Ninja F1', 'Xewel F1', 'Lindo F1', 'Cobra 26'],
    ),
    CropDefinition(
      id: 'oignon',
      labelFr: 'Oignon',
      labelWo: 'Soble',
      icon: Icons.brightness_1_rounded,
      color: Color(0xFFCFA96B),
      season: CropSeason.contreSaison,
      cycleDaysMin: 110,
      cycleDaysMax: 150,
      varieties: ['Violet de Galmi', 'Safari', 'Red Creole', 'Noflaye'],
    ),
    CropDefinition(
      id: 'chou',
      labelFr: 'Chou',
      labelWo: 'Suu',
      icon: Icons.circle_rounded,
      color: Color(0xFF6EA76D),
      season: CropSeason.contreSaison,
      cycleDaysMin: 70,
      cycleDaysMax: 100,
      varieties: ['KK Cross', 'Tropicana', 'Oxylus F1'],
    ),
    CropDefinition(
      id: 'piment',
      labelFr: 'Piment',
      labelWo: 'Kaani',
      icon: Icons.local_fire_department_rounded,
      color: Color(0xFFC2352A),
      season: CropSeason.contreSaison,
      cycleDaysMin: 90,
      cycleDaysMax: 150,
      varieties: ['Safi', 'Avenir F1', 'Big Sun'],
    ),
    CropDefinition(
      id: 'gombo',
      labelFr: 'Gombo',
      labelWo: 'Kañja',
      icon: Icons.grass_rounded,
      color: Color(0xFF5A8F3D),
      season: CropSeason.hivernage,
      cycleDaysMin: 60,
      cycleDaysMax: 120,
      varieties: ['Clemson Spineless', 'Volta', 'Hire F1'],
    ),
    CropDefinition(
      id: 'aubergine',
      labelFr: 'Aubergine',
      labelWo: 'Jaxatu',
      icon: Icons.local_florist_rounded,
      color: Color(0xFF7B5DA7),
      season: CropSeason.contreSaison,
      cycleDaysMin: 90,
      cycleDaysMax: 150,
      varieties: ['Black Beauty', 'Kalenda F1', 'Soxna'],
    ),
    CropDefinition(
      id: 'carotte',
      labelFr: 'Carotte',
      labelWo: 'Karot',
      icon: Icons.grass_rounded,
      color: Color(0xFFE58F2D),
      season: CropSeason.contreSaison,
      cycleDaysMin: 90,
      cycleDaysMax: 120,
      varieties: ['Amazonia', 'Touchon', 'Nantaise'],
    ),
    CropDefinition(
      id: 'laitue',
      labelFr: 'Laitue',
      labelWo: 'Salaat',
      icon: Icons.local_florist_rounded,
      color: Color(0xFF83B76E),
      season: CropSeason.contreSaison,
      cycleDaysMin: 45,
      cycleDaysMax: 75,
      varieties: ['Minetto', 'Batavia', 'Romaine'],
    ),
    CropDefinition(
      id: 'pasteque',
      labelFr: 'Pastèque',
      labelWo: 'Xaal',
      icon: Icons.circle_rounded,
      color: Color(0xFF52A05E),
      season: CropSeason.contreSaison,
      cycleDaysMin: 70,
      cycleDaysMax: 100,
      varieties: ['Sugar Baby', 'Crimson Sweet', 'Koloss F1'],
    ),
    CropDefinition(
      id: 'patate_douce',
      labelFr: 'Patate douce',
      labelWo: 'Patasa',
      icon: Icons.spa_rounded,
      color: Color(0xFFB45E3A),
      season: CropSeason.contreSaison,
      cycleDaysMin: 90,
      cycleDaysMax: 150,
      varieties: ['Apomuden', 'Naspot 8', 'CIP 440015'],
    ),
    CropDefinition(
      id: 'pomme_de_terre',
      labelFr: 'Pomme de terre',
      labelWo: 'Pompiteer',
      icon: Icons.circle_rounded,
      color: Color(0xFFD9B07A),
      season: CropSeason.contreSaison,
      cycleDaysMin: 75,
      cycleDaysMax: 110,
      varieties: ['Spunta', 'Desiree', 'Bartina'],
    ),
    CropDefinition(
      id: 'manioc',
      labelFr: 'Manioc',
      labelWo: 'Ñambi',
      icon: Icons.spa_rounded,
      color: Color(0xFF8B6B4F),
      season: CropSeason.permanent,
      cycleDaysMin: 270,
      cycleDaysMax: 365,
      varieties: ['Soso', 'TMS 30572', 'Kombass'],
    ),
    // ------------------------------------------------------------------
    // Arboriculture / vivrier
    // ------------------------------------------------------------------
    CropDefinition(
      id: 'mangue',
      labelFr: 'Mangue',
      labelWo: 'Mango',
      icon: Icons.park_rounded,
      color: Color(0xFFE8A23B),
      season: CropSeason.permanent,
      cycleDaysMin: 120,
      cycleDaysMax: 180,
      varieties: ['Kent', 'Keitt', 'Amelie', 'Sierra Leone'],
    ),
    CropDefinition(
      id: 'anacarde',
      labelFr: 'Anacarde',
      labelWo: 'Darkase',
      icon: Icons.park_rounded,
      color: Color(0xFFC48641),
      season: CropSeason.permanent,
      cycleDaysMin: 150,
      cycleDaysMax: 210,
      varieties: ['Tout venant', 'Clone 86/10', 'Clone 16/4'],
    ),
    CropDefinition(
      id: 'banane',
      labelFr: 'Banane',
      labelWo: 'Banaana',
      icon: Icons.park_rounded,
      color: Color(0xFFE4C143),
      season: CropSeason.permanent,
      cycleDaysMin: 270,
      cycleDaysMax: 365,
      varieties: ['Grande Naine', 'Poyo', 'Williams'],
    ),
    CropDefinition(
      id: 'canne_a_sucre',
      labelFr: 'Canne à sucre',
      labelWo: 'Kan',
      icon: Icons.grass_rounded,
      color: Color(0xFF8AAA52),
      season: CropSeason.permanent,
      cycleDaysMin: 300,
      cycleDaysMax: 360,
      varieties: ['Co 449', 'NCo 376', 'R570'],
    ),
    CropDefinition(
      id: 'moringa',
      labelFr: 'Moringa',
      labelWo: 'Nébédaay',
      icon: Icons.park_rounded,
      color: Color(0xFF4A8A4A),
      season: CropSeason.permanent,
      cycleDaysMin: 180,
      cycleDaysMax: 365,
      varieties: ['PKM-1', 'Oleifera local'],
    ),
  ];

  /// Tous les libellés FR (ordre du catalogue).
  static List<String> get allLabelsFr =>
      all.map((c) => c.labelFr).toList(growable: false);

  /// Recherche par libellé FR (insensible à la casse, tolère accents).
  static CropDefinition? byLabelFr(String label) {
    final norm = _norm(label);
    for (final c in all) {
      if (_norm(c.labelFr) == norm) return c;
    }
    return null;
  }

  /// Recherche par identifiant stable.
  static CropDefinition? byId(String id) {
    for (final c in all) {
      if (c.id == id) return c;
    }
    return null;
  }

  static String _norm(String s) => s
      .toLowerCase()
      .replaceAll(RegExp('[àáâãäå]'), 'a')
      .replaceAll(RegExp('[èéêë]'), 'e')
      .replaceAll(RegExp('[ìíîï]'), 'i')
      .replaceAll(RegExp('[òóôõö]'), 'o')
      .replaceAll(RegExp('[ùúûü]'), 'u')
      .replaceAll(RegExp('[ç]'), 'c')
      .trim();
}
