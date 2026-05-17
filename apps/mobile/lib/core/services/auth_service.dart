import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../constants/app_constants.dart';
import '../storage/hive_service.dart';
import '../network/dio_provider.dart';

class AuthState {
  final String? token;
  final bool isLoading;
  final String? error;
  final bool otpSent;
  final bool otpVerified;
  final Map<String, dynamic>? user;

  AuthState({
    this.token, 
    this.isLoading = false, 
    this.error,
    this.otpSent = false,
    this.otpVerified = false,
    this.user,
  });

  bool get isAuthenticated => token != null;

  AuthState copyWith({
    String? token,
    bool? isLoading,
    String? error,
    bool? otpSent,
    bool? otpVerified,
    Map<String, dynamic>? user,
  }) {
    return AuthState(
      token: token ?? this.token,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      otpSent: otpSent ?? this.otpSent,
      otpVerified: otpVerified ?? this.otpVerified,
      user: user ?? this.user,
    );
  }
}

class AuthService extends StateNotifier<AuthState> {
  AuthService(this._ref) : super(AuthState(token: _loadToken()));

  final Ref _ref;
  static const _tokenKey = 'jwt_token';

  static String? _loadToken() {
    return HiveService.box(AppConstants.boxAuth).get(_tokenKey);
  }

  Future<bool> requestOtp(String phone) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final dio = _ref.read(dioProvider);
      await dio.post('/auth/request-otp', data: {'phone': phone});
      state = state.copyWith(isLoading: false, otpSent: true);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Erreur lors de l\'envoi de l\'OTP');
      return false;
    }
  }

  Future<bool> verifyOtp(String phone, String code) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final dio = _ref.read(dioProvider);
      await dio.post('/auth/verify-otp', data: {'phone': phone, 'code': code});
      state = state.copyWith(isLoading: false, otpVerified: true);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Code invalide ou expiré');
      return false;
    }
  }

  Future<bool> register({
    required String phone,
    required String name,
    required String pin,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final dio = _ref.read(dioProvider);
      final response = await dio.post('/auth/register', data: {
        'phone': phone,
        'name': name,
        'pin': pin,
      });

      final token = response.data['access_token'];
      final userData = response.data['user'];
      await HiveService.box(AppConstants.boxAuth).put(_tokenKey, token);

      if (Firebase.apps.isNotEmpty) {
        try {
          final fcmToken = await FirebaseMessaging.instance.getToken();
          if (fcmToken != null && userData != null && userData['id'] != null) {
            await dio.patch('/users/${userData['id']}', data: {'fcmToken': fcmToken});
          }
        } catch (_) {}
      }

      state = state.copyWith(token: token, user: userData, isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Erreur lors de l\'inscription API');
      return false;
    }
  }

  Future<void> login(String phone, String pin) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final dio = _ref.read(dioProvider);
      final response = await dio.post('/auth/login', data: {
        'phone': phone,
        'pin': pin,
      });

      final token = response.data['access_token'];
      final userData = response.data['user'];
      await HiveService.box(AppConstants.boxAuth).put(_tokenKey, token);

      if (Firebase.apps.isNotEmpty) {
        try {
          final fcmToken = await FirebaseMessaging.instance.getToken();
          if (fcmToken != null && userData != null && userData['id'] != null) {
            await dio.patch('/users/${userData['id']}', data: {'fcmToken': fcmToken});
          }
        } catch (_) {}
      }

      state = state.copyWith(token: token, user: userData, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Identifiants invalides');
    }
  }

  Future<void> logout() async {
    await HiveService.box(AppConstants.boxAuth).delete(_tokenKey);
    state = AuthState(token: null);
  }
}

final authServiceProvider = StateNotifierProvider<AuthService, AuthState>((ref) {
  return AuthService(ref);
});
