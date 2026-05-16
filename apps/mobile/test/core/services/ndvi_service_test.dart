import 'package:flutter_test/flutter_test.dart';
import 'package:petaliacropassist/core/services/ndvi_service.dart';

void main() {
  group('NdviSnapshot', () {
    test('toMap/fromMap is a lossless round-trip', () {
      final original = NdviSnapshot(
        value: 0.72,
        fetchedAt: DateTime.utc(2026, 5, 12, 8, 0),
        parcelId: 'parcel-123',
      );

      final restored = NdviSnapshot.fromMap(original.toMap());
      expect(restored, isNotNull);
      expect(restored!.value, 0.72);
      expect(restored.parcelId, 'parcel-123');
      expect(restored.fetchedAt.toIso8601String(),
          original.fetchedAt.toIso8601String());
    });

    test('fromMap returns null on malformed payload', () {
      expect(NdviSnapshot.fromMap({'value': 'not-a-number'}), isNull);
      expect(NdviSnapshot.fromMap({}), isNull);
    });

    test('fromMap accepts integer NDVI value (num → double)', () {
      final snap = NdviSnapshot.fromMap({
        'value': 1, // int
        'fetchedAt': DateTime.utc(2026, 1, 1).toIso8601String(),
        'parcelId': 'p1',
      });
      expect(snap, isNotNull);
      expect(snap!.value, 1.0);
    });
  });
}
