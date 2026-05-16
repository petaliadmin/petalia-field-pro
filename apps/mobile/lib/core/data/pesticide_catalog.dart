/// Catalogue des spécialités commerciales homologuées au Sénégal (Source DPV).
/// Permet de faire le pont entre la matière active (recommandation agronomique)
/// et le produit disponible en boutique (Agro-dealer).
class PesticideCatalog {
  static const Map<String, List<String>> _activeToCommercial = {
    'acetamipride': ['Mospilan', 'K-Optimal', 'Acetastar'],
    'deltamethrine': ['Decis', 'Delta-P', 'Deltaplant'],
    'spinosad': ['Tracer', 'Success', 'Spino-Petalia'],
    'glyphosate': ['Roundup', 'Kalach', 'Glyphos'],
    'oxychlorure de cuivre': ['Cupravit', 'Cobox', 'Nordox'],
    'mancozeb': ['Dithane M-45', 'Penncozeb', 'Vondozeb'],
    'urea': ['Urée 46%', 'Granulaire'],
    'npk': ['NPK 15-15-15', 'NPK 6-20-10 (Arachide)'],
  };

  /// Récupère les noms commerciaux pour une matière active donnée.
  static List<String> getCommercialNames(String activeIngredient) {
    final key = activeIngredient.toLowerCase().trim();
    return _activeToCommercial[key] ?? [];
  }
}
