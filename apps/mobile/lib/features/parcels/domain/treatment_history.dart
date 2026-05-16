/// Représente un enregistrement de traitement phytosanitaire ou fertilisation
/// effectué sur une parcelle.
class TreatmentRecord {
  final String id;
  final DateTime date;
  
  /// Nom du produit utilisé (ex: "Oxychlorure de cuivre", "Urée").
  final String product;
  
  /// Catégorie du traitement (ex: "insecticide", "fungicide", "fertilizer").
  final String category;
  
  /// Code IRAC (Insecticides) ou FRAC (Fongicides) pour la gestion des résistances.
  /// Optionnel pour les fertilisants.
  final String? resistanceCode;
  
  /// Quantité appliquée par hectare (ex: "2 kg/ha").
  final String dosage;

  const TreatmentRecord({
    required this.id,
    required this.date,
    required this.product,
    required this.category,
    this.resistanceCode,
    required this.dosage,
  });

  factory TreatmentRecord.fromJson(Map<String, dynamic> json) => TreatmentRecord(
        id: json['id'] as String,
        date: DateTime.parse(json['date'] as String),
        product: json['product'] as String,
        category: json['category'] as String,
        resistanceCode: json['resistanceCode'] as String?,
        dosage: json['dosage'] as String,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date.toIso8601String(),
        'product': product,
        'category': category,
        'resistanceCode': resistanceCode,
        'dosage': dosage,
      };
}
