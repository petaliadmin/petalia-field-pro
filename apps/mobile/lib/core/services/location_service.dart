import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

/// Point GPS enrichi avec une estimation de précision horizontale en mètres.
/// [accuracyM] correspond au rayon à 68 % de confiance rapporté par l'OS
/// (dérivé du HDOP sur Android). `null` si l'OS n'en fournit pas.
class GpsFix {
  final LatLng position;
  final double? accuracyM;
  const GpsFix(this.position, this.accuracyM);
}

class LocationService {
  Future<bool> ensurePermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  Future<LatLng?> current() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;
      final ok = await ensurePermission();
      if (!ok) return null;

      // Tentative de récupération de la dernière position connue (instantané)
      final lastPos = await Geolocator.getLastKnownPosition();
      if (lastPos != null) {
        return LatLng(lastPos.latitude, lastPos.longitude);
      }

      // Sinon, on demande la position actuelle avec un timeout pour ne pas bloquer l'UI
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
      return LatLng(pos.latitude, pos.longitude);
    } catch (_) {
      // En cas de timeout ou erreur, on tente une dernière fois avec une précision moindre
      try {
        final lowPos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.low,
            timeLimit: Duration(seconds: 5),
          ),
        );
        return LatLng(lowPos.latitude, lowPos.longitude);
      } catch (__) {
        return null;
      }
    }
  }

  Stream<LatLng> watch() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 2,
      ),
    ).map((p) => LatLng(p.latitude, p.longitude));
  }

  /// Flux enrichi exposant la précision horizontale (m). Utile pour les écrans
  /// de tracé GPS qui veulent bloquer les points trop incertains (HDOP haut).
  Stream<GpsFix> watchWithAccuracy() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 2,
      ),
    ).map((p) => GpsFix(
          LatLng(p.latitude, p.longitude),
          p.accuracy.isFinite ? p.accuracy : null,
        ));
  }

  /// Récupère une position stabilisée en faisant la moyenne de 5 points consécutifs
  /// ayant une précision < 5 mètres. Crucial pour le bornage de parcelles.
  Future<LatLng?> getStabilizedPosition({
    int sampleCount = 5,
    double maxAccuracyM = 5.0,
    Duration timeout = const Duration(seconds: 30),
  }) async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;
      final ok = await ensurePermission();
      if (!ok) return null;

      final List<Position> samples = [];
      final completer = Completer<LatLng?>();
      
      StreamSubscription<Position>? sub;
      Timer? timer;

      void cleanUp() {
        sub?.cancel();
        timer?.cancel();
      }

      timer = Timer(timeout, () {
        if (!completer.isCompleted) {
          cleanUp();
          completer.complete(null);
        }
      });

      sub = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.bestForNavigation,
          distanceFilter: 0,
        ),
      ).listen((p) {
        if (p.accuracy <= maxAccuracyM) {
          samples.add(p);
          if (samples.length >= sampleCount) {
            cleanUp();
            final avgLat = samples.map((s) => s.latitude).reduce((a, b) => a + b) / samples.length;
            final avgLon = samples.map((s) => s.longitude).reduce((a, b) => a + b) / samples.length;
            completer.complete(LatLng(avgLat, avgLon));
          }
        }
      });

      return await completer.future;
    } catch (_) {
      return null;
    }
  }
}

final locationServiceProvider = Provider<LocationService>((_) => LocationService());
