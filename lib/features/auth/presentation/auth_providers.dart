import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/auth_repository.dart';
import '../domain/user.dart';

final authRepositoryProvider = Provider<AuthRepository>((_) => AuthRepository());

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

  Future<void> loginWithPin(String pin) async {
    state = const AsyncLoading();
    try {
      final user = await ref.read(authRepositoryProvider).loginWithPin(pin);
      state = AsyncData(AuthState(isAuthenticated: true, user: user));
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> loginWithBiometric() async {
    state = const AsyncLoading();
    try {
      final user = await ref.read(authRepositoryProvider).loginWithBiometric();
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
      final user = await ref.read(authRepositoryProvider).register(
            phone: phone,
            name: name,
            pin: pin,
          );
      state = AsyncData(AuthState(isAuthenticated: true, user: user));
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> logout() async {
    await ref.read(authRepositoryProvider).logout();
    state = const AsyncData(AuthState(isAuthenticated: false));
  }
}

final authStateProvider =
    AsyncNotifierProvider<AuthController, AuthState>(AuthController.new);
