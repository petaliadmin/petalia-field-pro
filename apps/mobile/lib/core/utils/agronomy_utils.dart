/// Utilitaires de calcul agronomique pour le terrain au Sénégal.
class AgroUtils {
  /// Calcule la dose par pulvérisateur de 15L (standard au Sénégal).
  /// [dosePerHa] : Quantité de produit pur à l'hectare (kg ou L).
  /// [volumeBouillieHa] : Volume total de mélange eau+produit par hectare (L/ha).
  /// Généralement 200L/ha pour les herbicides et 400L/ha pour les fongicides.
  static double dosePer15L(double dosePerHa, {double volumeBouillieHa = 200}) {
    if (dosePerHa <= 0 || volumeBouillieHa <= 0) return 0;
    // (dosePerHa / volumeBouillieHa) gives concentration per Liter.
    // Multiply by 15 for a 15L sprayer.
    return (dosePerHa / volumeBouillieHa) * 15;
  }

  /// Calcule le nombre de pulvérisateurs nécessaires pour une surface donnée.
  static int sprayersCount(double areaHa, {double volumeBouillieHa = 200}) {
    if (areaHa <= 0 || volumeBouillieHa <= 0) return 0;
    final totalVolume = areaHa * volumeBouillieHa;
    return (totalVolume / 15).ceil();
  }
}
