class ChecklistTemplate {
  final String id;
  final String crop;
  final String phase; // semis, vegetation, flowering, fruiting, harvest
  final List<ChecklistItem> items;

  const ChecklistTemplate({
    required this.id,
    required this.crop,
    required this.phase,
    required this.items,
  });
}

class ChecklistItem {
  final String id;
  final String labelFr;
  final String labelWo;

  const ChecklistItem({
    required this.id,
    required this.labelFr,
    required this.labelWo,
  });
}

class ChecklistInstance {
  final String id;
  final String parcelId;
  final String templateId;
  final Map<String, bool> checkedItems; // itemId -> checked
  final DateTime createdAt;
  final DateTime? completedAt;

  const ChecklistInstance({
    required this.id,
    required this.parcelId,
    required this.templateId,
    required this.checkedItems,
    required this.createdAt,
    this.completedAt,
  });

  ChecklistInstance copyWith({
    String? id,
    String? parcelId,
    String? templateId,
    Map<String, bool>? checkedItems,
    DateTime? createdAt,
    DateTime? completedAt,
  }) {
    return ChecklistInstance(
      id: id ?? this.id,
      parcelId: parcelId ?? this.parcelId,
      templateId: templateId ?? this.templateId,
      checkedItems: checkedItems ?? this.checkedItems,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}

const cropChecklistTemplates = [
  // ========================================================================
  // ARACHIDE
  // ========================================================================
  ChecklistTemplate(
    id: 'ARA-SEMIS',
    crop: 'arachide',
    phase: 'semis',
    items: [
      ChecklistItem(
        id: 'ARA-S1',
        labelFr: 'Semis réalisés à bonne profondeur (5-7 cm)',
        labelWo: 'Ñal bi amul',
      ),
      ChecklistItem(
        id: 'ARA-S2',
        labelFr: 'Densité respectée (40-50 plants/m²)',
        labelWo: 'Gis bi ñuñal',
      ),
      ChecklistItem(
        id: 'ARA-S3',
        labelFr: 'Traitement semences fait',
        labelWo: 'Ndox bi ñu teg',
      ),
      ChecklistItem(
        id: 'ARA-S4',
        labelFr: 'Écartement inter-rangs correct',
        labelWo: 'Yaye bi',
      ),
      ChecklistItem(
        id: 'ARA-S5',
        labelFr: 'Date de semis conforme calendrier',
        labelWo: 'Birt bi',
      ),
    ],
  ),
  ChecklistTemplate(
    id: 'ARA-VEG',
    crop: 'arachide',
    phase: 'vegetation',
    items: [
      ChecklistItem(id: 'ARA-V1', labelFr: 'Levée均匀e', labelWo: 'Gaal bi'),
      ChecklistItem(
        id: 'ARA-V2',
        labelFr: 'Nodulation observée (coupe test)',
        labelWo: 'Koktu',
      ),
      ChecklistItem(
        id: 'ARA-V3',
        labelFr: 'Absence de jaunissement anormal',
        labelWo: 'Yelightu',
      ),
      ChecklistItem(
        id: 'ARA-V4',
        labelFr: 'Contrôle adventices',
        labelWo: 'Sakku',
      ),
      ChecklistItem(
        id: 'ARA-V5',
        labelFr: 'Inspection pests (pucerons)',
        labelWo: 'Kisaay',
      ),
    ],
  ),
  ChecklistTemplate(
    id: 'ARA-HARVEST',
    crop: 'arachide',
    phase: 'harvest',
    items: [
      ChecklistItem(
        id: 'ARA-H1',
        labelFr: 'Maturité correcte (>70% gousses matures)',
        labelWo: 'Maaro',
      ),
      ChecklistItem(
        id: 'ARA-H2',
        labelFr: 'Récolte avantverse dégradée',
        labelWo: 'Juntu',
      ),
      ChecklistItem(id: 'ARA-H3', labelFr: 'Séchage adéquat', labelWo: 'Takk'),
      ChecklistItem(
        id: 'ARA-H4',
        labelFr: 'Stockage protégé',
        labelWo: 'Dundu',
      ),
    ],
  ),
  // ========================================================================
  // NIÉBÉ
  // ========================================================================
  ChecklistTemplate(
    id: 'NIEBE-SEMIS',
    crop: 'niebe',
    phase: 'semis',
    items: [
      ChecklistItem(
        id: 'NIE-S1',
        labelFr: 'Semis à bonne profondeur (3-4 cm)',
        labelWo: 'Ñal',
      ),
      ChecklistItem(id: 'NIE-S2', labelFr: 'Densité correcte', labelWo: 'Ñall'),
      ChecklistItem(
        id: 'NIE-S3',
        labelFr: 'Inoculum si disponible',
        labelWo: 'Ndox',
      ),
    ],
  ),
  ChecklistTemplate(
    id: 'NIEBE-VEG',
    crop: 'niebe',
    phase: 'vegetation',
    items: [
      ChecklistItem(
        id: 'NIE-V1',
        labelFr: 'Bonne vigueur végétative',
        labelWo: 'Yay',
      ),
      ChecklistItem(
        id: 'NIE-V2',
        labelFr: 'Absence pucerons',
        labelWo: 'Kisaay',
      ),
      ChecklistItem(
        id: 'NIE-V3',
        labelFr: 'Nodosités présentes',
        labelWo: 'Koktu',
      ),
    ],
  ),
  // ========================================================================
  // MIL
  // ========================================================================
  ChecklistTemplate(
    id: 'MIL-SEMIS',
    crop: 'mil',
    phase: 'semis',
    items: [
      ChecklistItem(
        id: 'MIL-S1',
        labelFr: 'Poquet (3-5 grains)',
        labelWo: 'Ñal',
      ),
      ChecklistItem(
        id: 'MIL-S2',
        labelFr: 'Profondeur 3-4 cm',
        labelWo: 'Doff',
      ),
      ChecklistItem(
        id: 'MIL-S3',
        labelFr: 'Écart correct (0.80 x 0.40 m)',
        labelWo: 'Yay',
      ),
    ],
  ),
  ChecklistTemplate(
    id: 'MIL-VEG',
    crop: 'mil',
    phase: 'vegetation',
    items: [
      ChecklistItem(id: 'MIL-V1', labelFr: 'Tallage normal', labelWo: 'Yapp'),
      ChecklistItem(id: 'MIL-V2', labelFr: 'Absence striga', labelWo: 'Xan'),
      ChecklistItem(
        id: 'MIL-V3',
        labelFr: 'Élimination adventices',
        labelWo: 'Sakku',
      ),
    ],
  ),
  ChecklistTemplate(
    id: 'MIL-FLO',
    crop: 'mil',
    phase: 'flowering',
    items: [
      ChecklistItem(id: 'MIL-F1', labelFr: 'Épiage uniforme', labelWo: 'Sama'),
      ChecklistItem(id: 'MIL-F2', labelFr: 'Pas de mildiou', labelWo: 'Xob'),
      ChecklistItem(id: 'MIL-F3', labelFr: 'Pollinisation OK', labelWo: 'Leru'),
    ],
  ),
  // ========================================================================
  // MAÏS
  // ========================================================================
  ChecklistTemplate(
    id: 'MAIS-SEMIS',
    crop: 'mais',
    phase: 'semis',
    items: [
      ChecklistItem(
        id: 'MAI-S1',
        labelFr: 'Profondeur 3-5 cm',
        labelWo: 'Doff',
      ),
      ChecklistItem(
        id: 'MAI-S2',
        labelFr: 'Densité (6-8 plants/m²)',
        labelWo: 'Ñall',
      ),
      ChecklistItem(
        id: 'MAI-S3',
        labelFr: 'Variété appropriée',
        labelWo: 'Xeet',
      ),
    ],
  ),
  ChecklistTemplate(
    id: 'MAIS-VEG',
    crop: 'mais',
    phase: 'vegetation',
    items: [
      ChecklistItem(id: 'MAI-V1', labelFr: 'Levéeuniforme', labelWo: 'Gaal'),
      ChecklistItem(id: 'MAI-V2', labelFr: 'Nutrition (NPK)', labelWo: 'NPK'),
      ChecklistItem(
        id: 'MAI-V3',
        labelFr: 'Contrôle chenilles',
        labelWo: 'Yappay',
      ),
    ],
  ),
  ChecklistTemplate(
    id: 'MAIS-FLO',
    crop: 'mais',
    phase: 'flowering',
    items: [
      ChecklistItem(
        id: 'MAI-F1',
        labelFr: 'Emission panicules',
        labelWo: 'Suu',
      ),
      ChecklistItem(id: 'MAI-F2', labelFr: 'Fécondation OK', labelWo: 'Leru'),
      ChecklistItem(id: 'MAI-F3', labelFr: 'Pas de stries', labelWo: 'Solo'),
    ],
  ),
  // ========================================================================
  // RIZ
  // ========================================================================
  ChecklistTemplate(
    id: 'RIZ-SEMIS',
    crop: 'riz',
    phase: 'semis',
    items: [
      ChecklistItem(
        id: 'RIZ-S1',
        labelFr: 'Semis en ligne ou à la volée',
        labelWo: 'Ñal',
      ),
      ChecklistItem(
        id: 'RIZ-S2',
        labelFr: 'Niveau eau maîtrisé',
        labelWo: 'Tce',
      ),
      ChecklistItem(id: 'RIZ-S3', labelFr: 'Drainage OK', labelWo: 'Paxe'),
    ],
  ),
  ChecklistTemplate(
    id: 'RIZ-VEG',
    crop: 'riz',
    phase: 'vegetation',
    items: [
      ChecklistItem(
        id: 'RIZ-V1',
        labelFr: 'Tallage satisfaisant',
        labelWo: 'Tal',
      ),
      ChecklistItem(
        id: 'RIZ-V2',
        labelFr: 'Pas pyriculariose',
        labelWo: 'Prikul',
      ),
      ChecklistItem(
        id: 'RIZ-V3',
        labelFr: 'Contrôle adventices',
        labelWo: 'Sakku',
      ),
    ],
  ),
  // ========================================================================
  // TOMATE
  // ========================================================================
  ChecklistTemplate(
    id: 'TOM-SEMIS',
    crop: 'tomate',
    phase: 'semis',
    items: [
      ChecklistItem(
        id: 'TOM-S1',
        labelFr: 'Semis en pépinière',
        labelWo: 'Ñal',
      ),
      ChecklistItem(
        id: 'TOM-S2',
        labelFr: 'Repiquage à 20-25 jours',
        labelWo: 'Tegl',
      ),
      ChecklistItem(
        id: 'TOM-S3',
        labelFr: 'Distance plantation (60-80 cm)',
        labelWo: 'Yay',
      ),
    ],
  ),
  ChecklistTemplate(
    id: 'TOM-VEG',
    crop: 'tomate',
    phase: 'vegetation',
    items: [
      ChecklistItem(
        id: 'TOM-V1',
        labelFr: 'Bon développement foliaire',
        labelWo: 'Yapp',
      ),
      ChecklistItem(id: 'TOM-V2', labelFr: 'Tuteurage fait', labelWo: 'Soxn'),
      ChecklistItem(id: 'TOM-V3', labelFr: 'Pas de mildiou', labelWo: 'Xob'),
      ChecklistItem(
        id: 'TOM-V4',
        labelFr: 'Irrigation goutte-à-goutte',
        labelWo: 'Ndundul',
      ),
    ],
  ),
  ChecklistTemplate(
    id: 'TOM-FLO',
    crop: 'tomate',
    phase: 'flowering',
    items: [
      ChecklistItem(
        id: 'TOM-F1',
        labelFr: 'Floraison abondante',
        labelWo: 'Fajar',
      ),
      ChecklistItem(
        id: 'TOM-F2',
        labelFr: 'Pollinisation (bumblebees)',
        labelWo: 'Leru',
      ),
      ChecklistItem(
        id: 'TOM-F3',
        labelFr: ' Nutrition calcium (BER)',
        labelWo: 'Kalsige',
      ),
    ],
  ),
  // ========================================================================
  // OIGNON
  // ========================================================================
  ChecklistTemplate(
    id: 'OIG-SEMIS',
    crop: 'oignon',
    phase: 'semis',
    items: [
      ChecklistItem(
        id: 'OIG-S1',
        labelFr: 'Semis en pépinière',
        labelWo: 'Ñal',
      ),
      ChecklistItem(
        id: 'OIG-S2',
        labelFr: 'Repiquage 45-60 jours',
        labelWo: 'Tegl',
      ),
      ChecklistItem(id: 'OIG-S3', labelFr: 'Sol drainant', labelWo: 'Digg'),
    ],
  ),
  ChecklistTemplate(
    id: 'OIG-VEG',
    crop: 'oignon',
    phase: 'vegetation',
    items: [
      ChecklistItem(
        id: 'OIG-V1',
        labelFr: 'Arrosage régulier',
        labelWo: 'Ndundul',
      ),
      ChecklistItem(id: 'OIG-V2', labelFr: 'Pas de thrips', labelWo: 'Tab'),
      ChecklistItem(id: 'OIG-V3', labelFr: 'Binage fait', labelWo: 'Kwal'),
    ],
  ),
  ChecklistTemplate(
    id: 'OIG-HARVEST',
    crop: 'oignon',
    phase: 'harvest',
    items: [
      ChecklistItem(
        id: 'OIG-H1',
        labelFr: 'Feuilles couchées (70%)',
        labelWo: 'Yapp',
      ),
      ChecklistItem(
        id: 'OIG-H2',
        labelFr: 'Séchage avant tressage',
        labelWo: 'Takk',
      ),
      ChecklistItem(id: 'OIG-H3', labelFr: 'Conservation OK', labelWo: 'Dundu'),
    ],
  ),
  // ========================================================================
  // GLOBALGAP (applicable to all)
  // ========================================================================
  ChecklistTemplate(
    id: 'GLOBALGAP',
    crop: '*',
    phase: 'all',
    items: [
      ChecklistItem(
        id: 'GG-1',
        labelFr: 'Registre intrants tenu',
        labelWo: 'Kax',
      ),
      ChecklistItem(
        id: 'GG-2',
        labelFr: 'Délai attente produit respecté',
        labelWo: 'Rikk',
      ),
      ChecklistItem(
        id: 'GG-3',
        labelFr: 'Équipement protection utilisé',
        labelWo: 'Yaye',
      ),
      ChecklistItem(id: 'GG-4', labelFr: 'Traçabilité lot OK', labelWo: 'Koy'),
      ChecklistItem(id: 'GG-5', labelFr: 'Agriculteur formé', labelWo: 'Jàng'),
    ],
  ),
];

List<ChecklistTemplate> getTemplatesForCrop(String cropId) {
  return cropChecklistTemplates
      .where((t) => t.crop == cropId || t.crop == '*')
      .toList();
}

ChecklistTemplate? getTemplate(String templateId) {
  for (final t in cropChecklistTemplates) {
    if (t.id == templateId) return t;
  }
  return null;
}
