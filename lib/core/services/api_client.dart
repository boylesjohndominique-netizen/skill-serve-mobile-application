import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../config/app_config.dart';
import 'token_storage.dart';

/// Thin Dio wrapper for the Laravel REST API.
///
/// Adds Sanctum bearer tokens to every request and clears the stored
/// session on 401 responses.
class ApiClient {
  ApiClient._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.baseUrl,
        connectTimeout: AppConfig.connectTimeout,
        receiveTimeout: AppConfig.apiTimeout,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ),
    );

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await TokenStorage.readAccessToken();
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        debugPrint('[API] ${options.method} ${options.uri}');
        handler.next(options);
      },
      onResponse: (response, handler) {
        debugPrint('[API] ${response.statusCode} ${response.requestOptions.uri}');
        handler.next(response);
      },
      onError: (error, handler) async {
        debugPrint('[API ERROR] ${error.type} ${error.message}');
        debugPrint('[API ERROR] URL: ${error.requestOptions.uri}');
        debugPrint('[API ERROR] Status: ${error.response?.statusCode}');
        debugPrint('[API ERROR] Data: ${error.response?.data}');
        if (error.response?.statusCode == 401) {
          await TokenStorage.clear();
        }
        handler.next(error);
      },
    ));
  }

  static final ApiClient instance = ApiClient._internal();
  late final Dio _dio;

  Dio get dio => _dio;

  /// Fire-and-forget request made at app startup to wake the free-tier
  /// Render backend from its idle sleep (~60-75 s cold start). Without it,
  /// the user's first real action bears the cold start and can time out.
  /// Any HTTP status means the server is awake; network errors are ignored
  /// on purpose (offline is handled by the ConnectivityGate).
  Future<void> warmUp() async {
    try {
      await _dio.get<void>(
        '',
        options: Options(
          validateStatus: (_) => true,
          receiveTimeout: const Duration(seconds: 120),
          sendTimeout: const Duration(seconds: 30),
        ),
      );
      debugPrint('[API] Backend warm-up complete');
    } catch (_) {
      // Still sleeping or offline — real requests will surface errors.
    }
  }
}
