import '../models/user_model.dart';
import '../../../core/services/api_client.dart';
import '../../../core/services/token_storage.dart';

/// Auth service — live API only.
///
/// Endpoints:
/// - POST /api/client/v1/auth/login
/// - POST /api/client/v1/auth/register
/// - POST /api/client/v1/auth/forgot-password
/// - POST /api/client/v1/auth/logout
/// - GET /api/client/v1/auth/me
/// - POST /api/client/v1/auth/refresh
class AuthService {
  String? lastAccessToken;
  String? lastRefreshToken;
  String? lastExpiresAt;

  // POST /api/client/v1/auth/login
  Future<UserModel> login(
      {required String email, required String password}) async {
    final response =
        await ApiClient.instance.dio.post('/client/v1/auth/login', data: {
      'email': email,
      'password': password,
    });
    final data = response.data['data'] as Map<String, dynamic>;
    _readSession(data);
    return UserModel.fromJson(data['user'] as Map<String, dynamic>);
  }

  // POST /api/client/v1/auth/register
  Future<UserModel> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required UserRole role,
  }) async {
    if (role != UserRole.client) {
      throw UnsupportedError(
          'The documented client API only registers customer accounts.');
    }
    final response =
        await ApiClient.instance.dio.post('/client/v1/auth/register', data: {
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'password': password,
      'password_confirmation': password,
    });
    final data = response.data['data'] as Map<String, dynamic>;
    _readSession(data);
    return UserModel.fromJson(data['user'] as Map<String, dynamic>);
  }

  // POST /api/client/v1/auth/forgot-password
  Future<void> requestPasswordReset(String email) async {
    await ApiClient.instance.dio
        .post('/client/v1/auth/forgot-password', data: {'email': email});
  }

  // POST /api/client/v1/auth/logout
  Future<void> logout() async {
    await ApiClient.instance.dio.post('/client/v1/auth/logout');
    await TokenStorage.clear();
  }

  // GET /api/client/v1/auth/me
  Future<UserModel> getCurrentUser() async {
    final response = await ApiClient.instance.dio.get('/client/v1/auth/me');
    return UserModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  // POST /api/client/v1/auth/refresh
  Future<UserModel> refresh(String refreshToken) async {
    final response = await ApiClient.instance.dio
        .post('/client/v1/auth/refresh', data: {'refresh_token': refreshToken});
    final data = response.data['data'] as Map<String, dynamic>;
    _readSession(data);
    return UserModel.fromJson(data['user'] as Map<String, dynamic>);
  }

  void _readSession(Map<String, dynamic> data) {
    lastAccessToken = data['token'] as String?;
    lastRefreshToken = data['refresh_token'] as String?;
    lastExpiresAt = data['expires_at'] as String?;
  }
}
