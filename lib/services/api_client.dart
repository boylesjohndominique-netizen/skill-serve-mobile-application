import 'package:dio/dio.dart';
import '../core/config/app_config.dart';

/// Thin Dio wrapper prepared for the future Laravel REST API.
///
/// Not called anywhere yet — every feature service currently returns mock
/// data (see lib/data/mock/mock_data.dart) gated by [AppConfig.useMockData].
/// Once the backend is live, inject [ApiClient.dio] into each service and
/// flip that flag off.
class ApiClient {
  ApiClient._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.baseUrl,
        connectTimeout: AppConfig.apiTimeout,
        receiveTimeout: AppConfig.apiTimeout,
        headers: {'Accept': 'application/json'},
      ),
    );

    // Placeholder for a future auth interceptor:
    // _dio.interceptors.add(InterceptorsWrapper(
    //   onRequest: (options, handler) {
    //     final token = TokenStorage.readToken();
    //     if (token != null) options.headers['Authorization'] = 'Bearer $token';
    //     handler.next(options);
    //   },
    // ));
  }

  static final ApiClient instance = ApiClient._internal();
  late final Dio _dio;

  Dio get dio => _dio;
}

/// Simulates network latency so loading/skeleton states feel authentic
/// while the app runs entirely on mock data.
Future<void> simulateNetworkDelay({int ms = 500}) =>
    Future.delayed(Duration(milliseconds: ms));
