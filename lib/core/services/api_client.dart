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
        connectTimeout: AppConfig.apiTimeout,
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
}
