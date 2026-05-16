import 'package:flutter_test/flutter_test.dart';
import 'package:petaliacropassist/core/services/weather_service.dart';

void main() {
  group('WeatherSnapshot', () {
    test('toMap/fromMap is a lossless round-trip', () {
      final original = WeatherSnapshot(
        tempC: 28.5,
        humidity: 65,
        windKmh: 12.3,
        condition: 'Partiellement nuageux',
        icon: 'cloud',
        fetchedAt: DateTime.utc(2026, 5, 12, 9, 30),
        latitude: 14.7167,
        longitude: -17.4677,
        maxRainNext6h: 3.2,
      );

      final restored = WeatherSnapshot.fromMap(original.toMap());
      expect(restored, isNotNull);
      expect(restored!.tempC, original.tempC);
      expect(restored.humidity, original.humidity);
      expect(restored.windKmh, original.windKmh);
      expect(restored.condition, original.condition);
      expect(restored.icon, original.icon);
      expect(restored.fetchedAt.toIso8601String(),
          original.fetchedAt.toIso8601String());
      expect(restored.latitude, original.latitude);
      expect(restored.longitude, original.longitude);
      expect(restored.maxRainNext6h, original.maxRainNext6h);
    });

    test('fromMap returns null on malformed payload', () {
      expect(WeatherSnapshot.fromMap({'garbage': true}), isNull);
    });

    test('fromMap is tolerant to missing optional fields', () {
      final snap = WeatherSnapshot.fromMap({
        'temp': 30,
        'humidity': 50,
        'wind': 10,
        'condition': 'Clair',
        'icon': 'sun',
        'fetchedAt': DateTime.utc(2026, 1, 1).toIso8601String(),
      });
      expect(snap, isNotNull);
      expect(snap!.latitude, 0);
      expect(snap.longitude, 0);
      expect(snap.maxRainNext6h, 0);
    });

    test('fromMap accepts integer temperatures (num → double)', () {
      final snap = WeatherSnapshot.fromMap({
        'temp': 31, // int, not double
        'humidity': 70,
        'wind': 15,
        'condition': 'Pluie',
        'icon': 'rain',
        'fetchedAt': DateTime.utc(2026, 5, 1).toIso8601String(),
        'lat': 14.5,
        'lng': -17.0,
        'maxRain': 4,
      });
      expect(snap, isNotNull);
      expect(snap!.tempC, 31.0);
      expect(snap.maxRainNext6h, 4.0);
    });
  });
}
