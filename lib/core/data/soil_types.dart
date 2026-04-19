/// Catalogue des types de sol rencontrés dans le bassin arachidier et les
/// Niayes. Les étiquettes FR reprennent la terminologie ISRA/CNRA usuelle,
/// l'id est la valeur stockée en base (stable, indépendante de la langue).
///
/// Les recommandations agronomiques ajustent les doses d'eau et d'engrais
/// selon le type de sol — d'où la nécessité de conserver un référentiel
/// identifié plutôt qu'une chaîne libre.
class SoilType {
  final String id;
  final String labelFr;
  final String descriptionFr;

  const SoilType({
    required this.id,
    required this.labelFr,
    required this.descriptionFr,
  });
}

class SoilTypes {
  SoilTypes._();

  static const List<SoilType> all = [
    SoilType(
      id: 'sandy',
      labelFr: 'Sableux (Dior)',
      descriptionFr: 'Drainage rapide, faible rétention d\'eau',
    ),
    SoilType(
      id: 'sandy_loam',
      labelFr: 'Sablo-limoneux',
      descriptionFr: 'Bon compromis drainage / rétention',
    ),
    SoilType(
      id: 'loam',
      labelFr: 'Limoneux',
      descriptionFr: 'Polyvalent, rétention moyenne',
    ),
    SoilType(
      id: 'clay_loam',
      labelFr: 'Argilo-limoneux (Deck)',
      descriptionFr: 'Bonne rétention, risque de tassement',
    ),
    SoilType(
      id: 'clay',
      labelFr: 'Argileux (Deck-dior)',
      descriptionFr: 'Rétention forte, drainage lent',
    ),
    SoilType(
      id: 'silt',
      labelFr: 'Limoneux fin',
      descriptionFr: 'Battant, sensible à la croûte',
    ),
  ];

  static SoilType? byId(String? id) {
    if (id == null) return null;
    for (final s in all) {
      if (s.id == id) return s;
    }
    return null;
  }
}
