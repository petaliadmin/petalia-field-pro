import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(BaseOptions(
    // En debug, on pointe vers le backend local (localhost pour le Web, 10.0.2.2 pour l'émulateur Android)
    baseUrl: kDebugMode
        ? 'http://52.73.53.182:3000'
        : 'https://api.petalia-agro.com/v1',
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 15),
  ));

  dio.interceptors.add(LogInterceptor(
    requestBody: true,
    responseBody: true,
    logPrint: (obj) => debugPrint('DIO: $obj'),
  ));

  // Intercepteur pour l'authentification
  dio.interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) async {
      final token = ref.read(authServiceProvider).token;
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
      return handler.next(options);
    },
    onError: (DioException e, handler) {
      if (e.response?.statusCode == 401) {
        debugPrint('AUTH ERROR: Token expiré ou invalide');
      }
      return handler.next(e);
    },
  ));

  return dio;
});
