import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/app_constants.dart';
import '../domain/user.dart';

class AuthRepository {
  Box get _box => Hive.box(AppConstants.boxAuth);

  AppUser? currentUser() {
    final raw = _box.get(AppConstants.kCurrentUser);
    if (raw == null) return null;
    return AppUser.fromJson(Map<String, dynamic>.from(raw as Map));
  }

  bool hasRegisteredUser() => _box.containsKey(AppConstants.kUserPin);

  bool verifyPin(String pin) {
    final stored = _box.get(AppConstants.kUserPin) as String?;
    return stored != null && stored == pin;
  }

  Future<AppUser> register({
    required String phone,
    required String name,
    required String pin,
  }) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final user = AppUser(
      id: const Uuid().v4(),
      name: name,
      phone: phone,
      role: 'Technicien agronome',
    );
    await _box.put(AppConstants.kCurrentUser, user.toJson());
    await _box.put(AppConstants.kUserPin, pin);
    await _box.put(AppConstants.kRememberSession, true);
    return user;
  }

  Future<AppUser> loginWithPin(String pin) async {
    await Future.delayed(const Duration(milliseconds: 300));
    if (!verifyPin(pin)) {
      throw Exception('Code secret incorrect');
    }
    final user = currentUser();
    if (user == null) {
      throw Exception('Aucun compte enregistre');
    }
    await _box.put(AppConstants.kRememberSession, true);
    return user;
  }

  Future<AppUser> loginWithBiometric() async {
    await Future.delayed(const Duration(milliseconds: 300));
    final existing = currentUser();
    if (existing != null) return existing;
    throw Exception('Aucun compte enregistre');
  }

  Future<void> logout() async {
    await _box.put(AppConstants.kRememberSession, false);
  }
}
