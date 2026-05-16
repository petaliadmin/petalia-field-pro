import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:light/light.dart';

/// Service détectant la luminosité ambiante (en Lux).
/// Utilisé pour activer automatiquement le mode "Plein Soleil" (High Contrast).
class LightService {
  LightService() : _light = Light();

  final Light _light;

  /// Seuil de passage en mode Haute Visibilité (Lux).
  /// 30 000 Lux correspond environ à un ciel dégagé mais pas en plein soleil direct (100k+).
  static const double kSunThreshold = 30000.0;

  Stream<double> watch() {
    try {
      return _light.lightSensorStream.map((l) => l.toDouble());
    } catch (_) {
      return const Stream.empty();
    }
  }
}

final lightServiceProvider = Provider<LightService>((_) => LightService());

final ambientLightProvider = StreamProvider<double>((ref) {
  return ref.watch(lightServiceProvider).watch();
});
