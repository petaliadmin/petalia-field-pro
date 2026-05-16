import 'package:dio/dio.dart';

class DioClient {
  DioClient._(this._dio);
  final Dio _dio;
  Dio get instance => _dio;

  factory DioClient.create({String baseUrl = 'https://api.petalia.local'}) {
    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 12),
        receiveTimeout: const Duration(seconds: 15),
        sendTimeout: const Duration(seconds: 15),
        headers: {'Content-Type': 'application/json'},
      ),
    );
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) => handler.next(options),
        onError: (e, handler) => handler.next(e),
      ),
    );
    return DioClient._(dio);
  }
}
