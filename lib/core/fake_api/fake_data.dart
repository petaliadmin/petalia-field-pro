import 'dart:math';

import 'package:latlong2/latlong.dart';

/// Seed + helpers for fake demo data (no external API needed).
class FakeData {
  FakeData._();

  /// Default map center (Thiès, Senegal region).
  static const LatLng defaultCenter = LatLng(14.7889, -16.9260);

  static final _rng = Random(42);

  static String randomPositiveInsight(String crop, String stage) {
    final list = [
      'Le couvert végétal est uniforme et vigoureux.',
      'La couleur des feuilles indique une absorption optimale de l\'azote.',
      'Le niveau d\'humidité est dans la plage idéale.',
      'Aucun signe visible de ravageur ou de maladie aujourd\'hui.',
      'La structure des plantes est conforme au stade $stage du $crop.',
    ];
    return list[_rng.nextInt(list.length)];
  }

  static List<Map<String, dynamic>> seedParcels() {
    return [
      {
        'id': 'p-001',
        'name': 'Keur Samba – Parcelle Nord',
        'owner': 'Samba Diop',
        'village': 'Keur Samba',
        'crop': 'Maïs',
        'growthStage': 'vegetative',
        'irrigation': 'Goutte-à-goutte',
        'healthScore': 0.82,
        'lastVisit': DateTime.now().subtract(const Duration(days: 2)).toIso8601String(),
        'estimatedYield': 4.2,
        'boundary': [
          [14.7921, -16.9287],
          [14.7921, -16.9265],
          [14.7903, -16.9265],
          [14.7903, -16.9287],
        ],
      },
      {
        'id': 'p-002',
        'name': 'Ndiaganiao Champ A',
        'owner': 'Aïssatou Fall',
        'village': 'Ndiaganiao',
        'crop': 'Arachide',
        'growthStage': 'flowering',
        'irrigation': 'Pluvial',
        'healthScore': 0.58,
        'lastVisit': DateTime.now().subtract(const Duration(days: 6)).toIso8601String(),
        'estimatedYield': 2.8,
        'boundary': [
          [14.7821, -16.9190],
          [14.7821, -16.9160],
          [14.7798, -16.9160],
          [14.7798, -16.9190],
        ],
      },
      {
        'id': 'p-003',
        'name': 'Mbour Bloc Tomate',
        'owner': 'Moussa Sow',
        'village': 'Mbour',
        'crop': 'Tomate',
        'growthStage': 'fruiting',
        'irrigation': 'Aspersion',
        'healthScore': 0.41,
        'lastVisit': DateTime.now().subtract(const Duration(days: 11)).toIso8601String(),
        'estimatedYield': 28.0,
        'boundary': [
          [14.7960, -16.9330],
          [14.7960, -16.9308],
          [14.7945, -16.9308],
          [14.7945, -16.9330],
        ],
      },
      {
        'id': 'p-004',
        'name': 'Thiès Terrasse Oignon',
        'owner': 'Fatou Ndiaye',
        'village': 'Thiès',
        'crop': 'Oignon',
        'growthStage': 'bulbing',
        'irrigation': 'Goutte-à-goutte',
        'healthScore': 0.91,
        'lastVisit': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
        'estimatedYield': 18.0,
        'boundary': [
          [14.7870, -16.9380],
          [14.7870, -16.9352],
          [14.7853, -16.9352],
          [14.7853, -16.9380],
        ],
      },
    ];
  }

  static List<Map<String, dynamic>> seedAlerts() {
    return [
      {
        'id': 'a-001',
        'type': 'weather',
        'severity': 'high',
        'title': 'Fortes pluies prévues',
        'message': 'Orage prévu demain à 14h00. Protégez les tomates en plein champ.',
        'parcelId': 'p-003',
        'at': DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(),
        'read': false,
      },
      {
        'id': 'a-002',
        'type': 'irrigation',
        'severity': 'medium',
        'title': 'Irrigation manquée',
        'message': 'Ndiaganiao Champ A — dernière irrigation il y a plus de 6 jours.',
        'parcelId': 'p-002',
        'at': DateTime.now().subtract(const Duration(hours: 12)).toIso8601String(),
        'read': false,
      },
      {
        'id': 'a-003',
        'type': 'visit',
        'severity': 'low',
        'title': 'Visite en retard',
        'message': 'Mbour Bloc Tomate — 11 jours depuis la dernière visite.',
        'parcelId': 'p-003',
        'at': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
        'read': true,
      },
      {
        'id': 'a-004',
        'type': 'pest',
        'severity': 'high',
        'title': 'Invasion de ravageurs signalée',
        'message': 'Pucerons repérés sur les parcelles voisines de Keur Samba.',
        'parcelId': 'p-001',
        'at': DateTime.now().subtract(const Duration(days: 2)).toIso8601String(),
        'read': false,
      },
    ];
  }

  static Map<String, dynamic> weatherToday() => {
        'temp': 29,
        'feels': 31,
        'humidity': 62,
        'wind': 14,
        'condition': 'Partiellement nuageux',
        'icon': 'cloud',
      };

  static List<double> weeklyHealthSeries() =>
      [0.62, 0.65, 0.70, 0.68, 0.74, 0.78, 0.81];

  static List<String> growthStages(String crop) {
    final common = ['germination', 'vegetative', 'flowering', 'fruiting', 'maturation'];
    switch (crop.toLowerCase()) {
      case 'onion':
        return ['germination', 'vegetative', 'bulbing', 'maturation'];
      case 'peanut':
        return ['germination', 'vegetative', 'flowering', 'podding', 'maturation'];
      default:
        return common;
    }
  }
}
