import '../../parcels/domain/parcel.dart';

class Producer {
  final String id; // Derived from name/phone or unique hash
  final String name;
  final String? phone;
  final String village;
  final List<Parcel> parcels;

  Producer({
    required this.id,
    required this.name,
    this.phone,
    required this.village,
    this.parcels = const [],
  });

  double get averageHealth {
    if (parcels.isEmpty) return 0.0;
    return parcels.map((p) => p.healthScore).reduce((a, b) => a + b) / parcels.length;
  }

  int get totalParcels => parcels.length;
  
  Set<String> get crops => parcels.map((p) => p.crop).toSet();

  Producer copyWith({
    String? name,
    String? phone,
    String? village,
    List<Parcel>? parcels,
  }) => Producer(
    id: id,
    name: name ?? this.name,
    phone: phone ?? this.phone,
    village: village ?? this.village,
    parcels: parcels ?? this.parcels,
  );
}
