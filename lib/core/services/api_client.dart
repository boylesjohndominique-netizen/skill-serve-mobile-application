import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../config/app_config.dart';
import '../models/account_restriction.dart';
import 'maintenance_state.dart';
import 'token_storage.dart';

/// Thin Dio wrapper for the Laravel REST API.
///
/// Adds the Sanctum bearer token to every request and keeps the session alive:
/// access tokens are short-lived (an hour), so a 401 is answered by renewing it
/// with the stored refresh token and replaying the request. Only when the
/// refresh itself is refused — the account was signed out elsewhere, suspended
/// or deleted — is the session cleared and [onSessionRevoked] called.
class ApiClient {
  ApiClient._internal() {
    _dio = Dio(_baseOptions());
    // A bare client for the refresh call itself, so renewing a token can never
    // re-enter the interceptor below.
    _refreshDio = Dio(_baseOptions());

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

        // Maintenance mode: the whole mobile API is closed for a while.
        final body = error.response?.data;
        if (error.response?.statusCode == 503 && body is Map && body['meta'] is Map && body['meta']['maintenance'] == true) {
          MaintenanceState.active.value = true;
        }

        // A restricted account (suspended or banned while signed in): the
        // server says why in meta.account. End the session so the login
        // screen can show it, instead of failing request after request.
        final restriction = AccountRestriction.fromError(error);
        if (restriction != null && !_isAuthEndpoint(error.requestOptions)) {
          await _endSession(restriction);
          handler.next(error);
          return;
        }

        if (!_shouldRenew(error)) {
          handler.next(error);
          return;
        }

        if (await _renewAccessToken()) {
          try {
            handler.resolve(await _replay(error.requestOptions));
          } on DioException catch (retryError) {
            handler.next(retryError);
          }
          return;
        }

        handler.next(error);
      },
    ));
  }

  static final ApiClient instance = ApiClient._internal();
  late final Dio _dio;
  late final Dio _refreshDio;

  Dio get dio => _dio;

  /// Called once the server has definitively ended the session, so the app
  /// can return to the login screen — with the reason when the account was
  /// suspended or banned. Network failures never trigger it.
  static void Function(AccountRestriction? restriction)? onSessionRevoked;

  /// The refresh in flight, shared by every request that hit a 401 meanwhile.
  ///
  /// The backend rotates refresh tokens with reuse detection: presenting a
  /// token twice revokes the whole session. So concurrent 401s must wait on one
  /// refresh rather than each sending their own.
  Future<bool>? _renewal;

  /// Endpoints whose 401 means "wrong credentials", not "token expired".
  static const _authEndpoints = [
    '/client/v1/auth/login',
    '/client/v1/auth/refresh',
    '/client/v1/auth/register',
    '/client/v1/auth/google',
    '/client/v1/auth/verify-otp',
    '/client/v1/auth/logout',
  ];

  static BaseOptions _baseOptions() => BaseOptions(
        baseUrl: AppConfig.baseUrl,
        connectTimeout: AppConfig.connectTimeout,
        receiveTimeout: AppConfig.apiTimeout,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      );

  bool _shouldRenew(DioException error) {
    if (error.response?.statusCode != 401) return false;
    final options = error.requestOptions;
    // One renewal per request: a replay that still gets a 401 is final.
    if (options.extra['renewed'] == true) return false;
    return !_isAuthEndpoint(options);
  }

  bool _isAuthEndpoint(RequestOptions options) =>
      _authEndpoints.any((path) => options.path.contains(path));

  Future<bool> _renewAccessToken() {
    return _renewal ??= _refresh().whenComplete(() => _renewal = null);
  }

  Future<bool> _refresh() async {
    final refreshToken = await TokenStorage.readRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      await _endSession();
      return false;
    }

    try {
      final response = await _refreshDio.post(
        '/client/v1/auth/refresh',
        data: {'refresh_token': refreshToken},
      );
      final data = response.data['data'] as Map<String, dynamic>;
      await TokenStorage.save(
        accessToken: data['token'] as String?,
        refreshToken: data['refresh_token'] as String?,
        expiresAt: data['expires_at'] as String?,
      );
      return true;
    } on DioException catch (e) {
      // Only a refusal from the server ends the session. A timeout or an
      // offline device keeps it, so the next request can try again.
      final status = e.response?.statusCode;
      if (status == 401 || status == 403) await _endSession(AccountRestriction.fromError(e));
      return false;
    }
  }

  Future<Response<dynamic>> _replay(RequestOptions options) async {
    final token = await TokenStorage.readAccessToken();
    options.headers['Authorization'] = 'Bearer $token';
    options.extra['renewed'] = true;
    return _dio.fetch<dynamic>(options);
  }

  Future<void> _endSession([AccountRestriction? restriction]) async {
    await TokenStorage.clear();
    onSessionRevoked?.call(restriction);
  }

  /// Fire-and-forget request made at app startup to wake the free-tier
  /// Render backend from its idle sleep (~60-75 s cold start). Without it,
  /// the user's first real action bears the cold start and can time out.
  /// Any HTTP status means the server is awake; network errors are ignored
  /// on purpose (offline is handled by the ConnectivityGate).
  Future<void> warmUp() async {
    try {
      // A real route: the bare API root 404s without CORS headers, which
      // browsers (flutter run -d edge/chrome) report as a CORS failure.
      await _refreshDio.get<void>(
        '/health',
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
