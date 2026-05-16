import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/auth_service.dart' show authServiceProvider;
import '../data/auth_repository.dart';
import '../domain/user.dart';

final authRepositoryProvider = Provider<AuthRepository>((_) => AuthRepository());

class RegistrationData {
  final String name;
  final String phone;
  final String? otp;
  final String? pin;

  RegistrationData({this.name = '', this.phone = '', this.otp, this.pin});

  RegistrationData copyWith({String? name, String? phone, String? otp, String? pin}) {
    return RegistrationData(
      name: name ?? this.name,
      phone: phone ?? this.phone,
      otp: otp ?? this.otp,
      pin: pin ?? this.pin,
    );
  }
}

final registrationDataProvider = StateProvider<RegistrationData>((_) => RegistrationData());

final hasRegisteredUserProvider = Provider<bool>((ref) {
  return ref.read(authRepositoryProvider).hasRegisteredUser();
});

class AuthController extends AsyncNotifier<AuthState> {
  @override
  Future<AuthState> build() async {
    final repo = ref.read(authRepositoryProvider);
    final user = repo.currentUser();
    return AuthState(isAuthenticated: user != null, user: user);
  }

  Future<void> login({
    required String phone,
    required String pin,
  }) async {
    state = const AsyncLoading();
    try {
      // 1. API Login
      await ref.read(authServiceProvider.notifier).login(phone, pin);
      
      final apiState = ref.read(authServiceProvider);
      if (apiState.error != null) throw Exception(apiState.error);

      // 2. Local Save (if needed, but usually API gives user info)
      final user = AppUser(
        id: apiState.user!['id'],
        name: apiState.user!['name'],
        phone: apiState.user!['phone'],
        role: apiState.user!['role'],
      );
      
      await ref.read(authRepositoryProvider).saveUserLocally(user, pin);
      
      state = AsyncData(AuthState(isAuthenticated: true, user: user));
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> register({
    required String phone,
    required String name,
    required String pin,
  }) async {
    state = const AsyncLoading();
    try {
      // 1. API Enrollment
      final success = await ref.read(authServiceProvider.notifier).register(
        phone: phone,
        name: name,
        pin: pin,
      );

      if (!success) {
        final error = ref.read(authServiceProvider).error;
        throw Exception(error ?? 'Erreur d\'inscription API');
      }

      // 2. Local Enrollment (seulement après succès API)
      final apiState = ref.read(authServiceProvider);
      final user = AppUser(
        id: apiState.user?['id'] ?? 'user_${DateTime.now().millisecondsSinceEpoch}',
        name: name,
        phone: phone,
        role: 'Agriculteur',
      );

      await ref.read(authRepositoryProvider).saveUserLocally(user, pin);

      state = AsyncData(AuthState(isAuthenticated: true, user: user));
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> logout() async {
    await ref.read(authServiceProvider.notifier).logout();
    await ref.read(authRepositoryProvider).logout();
    state = const AsyncData(AuthState(isAuthenticated: false));
  }
}

final authStateProvider =
    AsyncNotifierProvider<AuthController, AuthState>(AuthController.new);
