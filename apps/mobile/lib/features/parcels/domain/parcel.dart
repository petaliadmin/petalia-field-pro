import 'package:latlong2/latlong.dart';
import 'treatment_history.dart';

class Parcel {
  final String id;
  final String name;
  final String owner;
  final String village;
  final String crop;
  final String growthStage;
  final String irrigation;
  final double healthScore;
  final DateTime lastVisit;
  final double estimatedYield; // t/ha
  final List<LatLng> boundary;

  /// Numéro de téléphone de l'agriculteur (E.164 ou format local). Optionnel.
  /// Peut être saisi à la main ou importé depuis le carnet de contacts.
  final String? phone;

  /// Variété spécifique (ex: arachide "73-33"). Optionnel pour conserver la
  /// compatibilité avec les parcelles créées avant l'enrichissement du modèle.
  final String? variety;

  /// Date de semis — base du calcul du stade phénologique (BBCH) et des
  /// recommandations agronomiques. Optionnel pour les parcelles historiques.
  final DateTime? semisDate;

  /// Région administrative (ex: "thies", "fatick"). Permet de filtrer les
  /// règles agronomiques par zone agro-écologique.
  final String? region;

  /// Type de sol dominant (ex: "sandy", "sandy_loam", "loam", "clay_loam",
  /// "clay", "silt"). Utilisé par les règles agronomiques pour adapter les
  /// recommandations (rétention d'eau, drainage, fertilisation). Optionnel.
  final String? soilType;

  /// Culture précédente sur la parcelle (rotation). Label FR tel que renvoyé
  /// par [CropsCatalog.allLabelsFr], ou chaîne libre. Utilisé pour détecter
  /// les risques de monoculture et ajuster les apports en azote (légumineuse
  /// précédente → moindre dose). Optionnel.
  final String? previousCrop;

  final List<TreatmentRecord> treatmentHistory;

  const Parcel({
    required this.id,
    required this.name,
    required this.owner,
    required this.village,
    required this.crop,
    required this.growthStage,
    required this.irrigation,
    required this.healthScore,
    required this.lastVisit,
    required this.estimatedYield,
    required this.boundary,
    this.phone,
    this.variety,
    this.semisDate,
    this.region,
    this.soilType,
    this.previousCrop,
    this.treatmentHistory = const [],
  });

  /// Jours écoulés depuis le semis (`null` si [semisDate] non renseigné).
  int? daysAfterSowing([DateTime? ref]) {
    if (semisDate == null) return null;
    final now = ref ?? DateTime.now();
    return now.difference(semisDate!).inDays;
  }

  factory Parcel.fromJson(Map json) => Parcel(
        id: json['id'] as String,
        name: json['name'] as String,
        owner: json['owner'] as String,
        village: json['village'] as String? ?? '',
        crop: json['crop'] as String,
        growthStage: json['growthStage'] as String? ?? 'vegetative',
        irrigation: json['irrigation'] as String? ?? 'Rainfed',
        healthScore: (json['healthScore'] as num).toDouble(),
        lastVisit: DateTime.parse(json['lastVisit'] as String),
        estimatedYield: (json['estimatedYield'] as num?)?.toDouble() ?? 0.0,
        boundary: (json['boundary'] as List)
            .map((p) => LatLng((p[0] as num).toDouble(), (p[1] as num).toDouble()))
            .toList(),
        phone: json['phone'] as String?,
        variety: json['variety'] as String?,
        semisDate: json['semisDate'] == null
            ? null
            : DateTime.parse(json['semisDate'] as String),
        region: json['region'] as String?,
        soilType: json['soilType'] as String?,
        previousCrop: json['previousCrop'] as String?,
        treatmentHistory: (json['treatmentHistory'] as List?)
                ?.map((t) => TreatmentRecord.fromJson(t as Map<String, dynamic>))
                .toList() ??
            const [],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'owner': owner,
        'village': village,
        'crop': crop,
        'growthStage': growthStage,
        'irrigation': irrigation,
        'healthScore': healthScore,
        'lastVisit': lastVisit.toIso8601String(),
        'estimatedYield': estimatedYield,
        'boundary': boundary.map((p) => [p.latitude, p.longitude]).toList(),
        if (phone != null) 'phone': phone,
        if (variety != null) 'variety': variety,
        if (semisDate != null) 'semisDate': semisDate!.toIso8601String(),
        if (region != null) 'region': region,
        if (soilType != null) 'soilType': soilType,
        if (previousCrop != null) 'previousCrop': previousCrop,
        'treatmentHistory': treatmentHistory.map((t) => t.toJson()).toList(),
      };

  Parcel copyWith({
    String? name,
    String? owner,
    String? village,
    String? crop,
    String? growthStage,
    String? irrigation,
    double? healthScore,
    DateTime? lastVisit,
    double? estimatedYield,
    List<LatLng>? boundary,
    String? phone,
    String? variety,
    DateTime? semisDate,
    String? region,
    String? soilType,
    String? previousCrop,
    List<TreatmentRecord>? treatmentHistory,
  }) =>
      Parcel(
        id: id,
        name: name ?? this.name,
        owner: owner ?? this.owner,
        village: village ?? this.village,
        crop: crop ?? this.crop,
        growthStage: growthStage ?? this.growthStage,
        irrigation: irrigation ?? this.irrigation,
        healthScore: healthScore ?? this.healthScore,
        lastVisit: lastVisit ?? this.lastVisit,
        estimatedYield: estimatedYield ?? this.estimatedYield,
        boundary: boundary ?? this.boundary,
        phone: phone ?? this.phone,
        variety: variety ?? this.variety,
        semisDate: semisDate ?? this.semisDate,
        region: region ?? this.region,
        soilType: soilType ?? this.soilType,
        previousCrop: previousCrop ?? this.previousCrop,
        treatmentHistory: treatmentHistory ?? this.treatmentHistory,
      );
}
