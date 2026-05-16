/// Référentiel des régions administratives du Sénégal utilisées pour la
/// géolocalisation des règles agronomiques.
///
/// Les identifiants (`id`) sont stables et utilisés côté données / JSON de
/// règles (`agro_rules.json` → champ `region`). Les centroïdes sont
/// **approximatifs** (chef-lieu de région) et servent uniquement à
/// l'auto-détection par proximité — en cas de doute, l'utilisateur peut
/// corriger manuellement la région dans la fiche parcelle.
///
/// Sources :
/// - ANSD (Agence Nationale de la Statistique et de la Démographie) — découpage
///   administratif 2013 (14 régions).
/// - Coordonnées chefs-lieux : OpenStreetMap, vérifiées à la minute près.
library;

import 'dart:math' as math;

import 'package:latlong2/latlong.dart';

class SenegalRegion {
  /// Identifiant stable ASCII minuscule (utilisé dans les JSON de règles).
  final String id;

  /// Libellé FR (affichage UI par défaut).
  final String labelFr;

  /// Libellé wolof — à valider CLAD/IFAN.
  final String labelWo;

  /// Centroïde approximatif (chef-lieu de région).
  final LatLng centroid;

  /// Zone agro-écologique dominante. Permet de regrouper plusieurs régions
  /// dans une même règle (ex: "bassin_arachidier" = Thiès + Diourbel + Fatick
  /// + Kaolack + Kaffrine).
  final String zone;

  const SenegalRegion({
    required this.id,
    required this.labelFr,
    required this.labelWo,
    required this.centroid,
    required this.zone,
  });
}

class SenegalRegions {
  SenegalRegions._();

  /// 14 régions administratives, ordre alphabétique FR.
  static const List<SenegalRegion> all = [
    SenegalRegion(
      id: 'dakar',
      labelFr: 'Dakar',
      labelWo: 'Ndakaaru',
      centroid: LatLng(14.7167, -17.4677),
      zone: 'niayes',
    ),
    SenegalRegion(
      id: 'diourbel',
      labelFr: 'Diourbel',
      labelWo: 'Njaarel',
      centroid: LatLng(14.6553, -16.2326),
      zone: 'bassin_arachidier',
    ),
    SenegalRegion(
      id: 'fatick',
      labelFr: 'Fatick',
      labelWo: 'Fatik',
      centroid: LatLng(14.3390, -16.4108),
      zone: 'bassin_arachidier',
    ),
    SenegalRegion(
      id: 'kaffrine',
      labelFr: 'Kaffrine',
      labelWo: 'Kafrin',
      centroid: LatLng(14.1058, -15.5497),
      zone: 'bassin_arachidier',
    ),
    SenegalRegion(
      id: 'kaolack',
      labelFr: 'Kaolack',
      labelWo: 'Kawlax',
      centroid: LatLng(14.1500, -16.0726),
      zone: 'bassin_arachidier',
    ),
    SenegalRegion(
      id: 'kedougou',
      labelFr: 'Kédougou',
      labelWo: 'Kedugu',
      centroid: LatLng(12.5556, -12.1747),
      zone: 'sud_est',
    ),
    SenegalRegion(
      id: 'kolda',
      labelFr: 'Kolda',
      labelWo: 'Koldaa',
      centroid: LatLng(12.8939, -14.9411),
      zone: 'casamance',
    ),
    SenegalRegion(
      id: 'louga',
      labelFr: 'Louga',
      labelWo: 'Luga',
      centroid: LatLng(15.6144, -16.2264),
      zone: 'sylvo_pastorale',
    ),
    SenegalRegion(
      id: 'matam',
      labelFr: 'Matam',
      labelWo: 'Matam',
      centroid: LatLng(15.6559, -13.2553),
      zone: 'vallee_fleuve',
    ),
    SenegalRegion(
      id: 'saint_louis',
      labelFr: 'Saint-Louis',
      labelWo: 'Ndar',
      centroid: LatLng(16.0183, -16.4895),
      zone: 'vallee_fleuve',
    ),
    SenegalRegion(
      id: 'sedhiou',
      labelFr: 'Sédhiou',
      labelWo: 'Seju',
      centroid: LatLng(12.7081, -15.5569),
      zone: 'casamance',
    ),
    SenegalRegion(
      id: 'tambacounda',
      labelFr: 'Tambacounda',
      labelWo: 'Tambakunda',
      centroid: LatLng(13.7708, -13.6673),
      zone: 'sud_est',
    ),
    SenegalRegion(
      id: 'thies',
      labelFr: 'Thiès',
      labelWo: 'Cees',
      centroid: LatLng(14.7889, -16.9260),
      zone: 'niayes',
    ),
    SenegalRegion(
      id: 'ziguinchor',
      labelFr: 'Ziguinchor',
      labelWo: 'Siggicoor',
      centroid: LatLng(12.5665, -16.2639),
      zone: 'casamance',
    ),
  ];

  static SenegalRegion? byId(String id) {
    for (final r in all) {
      if (r.id == id) return r;
    }
    return null;
  }

  /// Auto-détection par plus proche voisin (grand-cercle approximé
  /// équi-rectangulaire — suffisant à l'échelle du Sénégal).
  static SenegalRegion nearest(LatLng point) {
    SenegalRegion best = all.first;
    double bestDist = double.infinity;
    for (final r in all) {
      final d = _distanceApproxKm(point, r.centroid);
      if (d < bestDist) {
        bestDist = d;
        best = r;
      }
    }
    return best;
  }

  /// Zones agro-écologiques distinctes (utile pour les règles qui ciblent
  /// plusieurs régions au sein d'une même zone).
  static List<String> get zones => {for (final r in all) r.zone}.toList();

  // ---------------------------------------------------------------------------
  // Distance équi-rectangulaire (pas besoin de haversine à cette échelle).
  // ---------------------------------------------------------------------------
  static double _distanceApproxKm(LatLng a, LatLng b) {
    const earthRadiusKm = 6371.0;
    final dLat = _toRad(b.latitude - a.latitude);
    final dLon = _toRad(b.longitude - a.longitude);
    final meanLat = _toRad((a.latitude + b.latitude) / 2.0);
    final x = dLon * math.cos(meanLat);
    return earthRadiusKm * math.sqrt(x * x + dLat * dLat);
  }

  static double _toRad(double deg) => deg * math.pi / 180.0;
}
