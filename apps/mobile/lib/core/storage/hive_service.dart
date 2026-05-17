import 'dart:convert';
import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../constants/app_constants.dart';

/// Bootstrap Hive avec chiffrement AES-256 des box sensibles.
///
/// La clé AES est :
/// - générée aléatoirement au premier lancement (32 octets / 256 bits),
/// - stockée dans `flutter_secure_storage` (Keychain iOS, Keystore Android,
///   DPAPI Windows, libsecret Linux),
/// - lue telle quelle à chaque démarrage.
///
/// Les box marquées comme sensibles (auth, parcelles, observations, rapports,
/// alertes, file de synchro) sont ouvertes avec [HiveAesCipher]. La box
/// `settings` reste en clair — elle contient uniquement des préférences UI
/// non confidentielles (locale, thème, toggles accessibilité).
class HiveService {
  HiveService._();

  /// Clé dans flutter_secure_storage où l'on stocke la clé AES en base64.
  static const _secureKeyName = 'petalia.hive.aes_key_v1';

  /// Box sensibles — ouvertes avec chiffrement AES.
  static const _encryptedBoxes = <String>{
    AppConstants.boxAuth,
    AppConstants.boxParcels,
    AppConstants.boxObservations,
    AppConstants.boxReports,
    AppConstants.boxAlerts,
    AppConstants.boxSyncQueue,
    AppConstants.boxSyncQueueMedia,
    AppConstants.boxExpertRequests,
  };

  static Future<void> init() async {
    await Hive.initFlutter();

    final cipher = HiveAesCipher(await _loadOrCreateKey());

    // Ouvre en séquence pour pouvoir récupérer individuellement d'une box
    // corrompue (ancienne box en clair d'une version pré-chiffrement, ou
    // clé perdue). En cas d'échec, on supprime la box locale et on la
    // recrée vide — les données seed / syncQueue seront ré-hydratées.
    for (final name in _encryptedBoxes) {
      await _openEncryptedSafely(name, cipher);
    }
    // Settings non chiffré — préférences UI uniquement.
    await Hive.openBox(AppConstants.boxSettings);
    // Cache météo non chiffré — données publiques OpenMeteo.
    await Hive.openBox(AppConstants.boxWeather);
    // Cache NDVI non chiffré — données satellites Petalia Hub.
    await Hive.openBox(AppConstants.boxNdvi);
  }

  static Future<void> _openEncryptedSafely(
    String name,
    HiveAesCipher cipher,
  ) async {
    try {
      await Hive.openBox(name, encryptionCipher: cipher);
    } catch (_) {
      // Box existante incompatible (en clair → chiffré, ou clé changée).
      await Hive.deleteBoxFromDisk(name);
      await Hive.openBox(name, encryptionCipher: cipher);
    }
  }

  static Box box(String name) => Hive.box(name);

  /// Récupère la clé AES 256 bits depuis le secure storage, ou en génère une
  /// nouvelle si aucune n'est encore stockée.
  static Future<List<int>> _loadOrCreateKey() async {
    const storage = FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true),
    );
    final existing = await storage.read(key: _secureKeyName);
    if (existing != null && existing.isNotEmpty) {
      try {
        final bytes = base64Decode(existing);
        if (bytes.length == 32) return bytes;
      } catch (_) {
        // Clé corrompue — régénère plutôt que de crasher. Les box existantes
        // deviendront illisibles : choix assumé, pertes acceptées plutôt que
        // blocage complet au démarrage. Un futur reset soft pourra re-seeder.
      }
    }
    final fresh = _generateKey();
    await storage.write(key: _secureKeyName, value: base64Encode(fresh));
    return fresh;
  }

  /// Génère 32 octets aléatoires cryptographiquement sûrs.
  static List<int> _generateKey() {
    final rng = Random.secure();
    return List<int>.generate(32, (_) => rng.nextInt(256));
  }
}
