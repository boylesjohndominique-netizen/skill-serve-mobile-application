import '../core/config/app_config.dart';
import '../data/mock/mock_data.dart';
import '../models/user_model.dart';
import 'api_client.dart';
import 'token_storage.dart';

/// Auth placeholder service.
///
/// Every method below documents the Laravel endpoint it will eventually
/// call. Until then, calls resolve against mock data so login/register/
/// forgot-password screens are fully navigable and demoable.
class AuthService {
  String? lastAccessToken;
  String? lastRefreshToken;
  String? lastExpiresAt;

  // API: POST /api/client/v1/auth/login
  Future<UserModel> login(
      {required String email, required String password}) async {
    if (!AppConfig.useMockData) {
      final response =
          await ApiClient.instance.dio.post('/client/v1/auth/login', data: {
        'email': email,
        'password': password,
      });
      final data = response.data['data'] as Map<String, dynamic>;
      _readSession(data);
      return UserModel.fromJson(data['user'] as Map<String, dynamic>);
    }
    await simulateNetworkDelay();
    // Demo convenience: route "provider" in the email to the provider mock account.
    if (email.toLowerCase().contains('provider')) {
      return MockData.currentProvider;
    }
    return MockData.currentClient;
  }

  // API: POST /api/client/v1/auth/register
  Future<UserModel> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required UserRole role,
  }) async {
    if (!AppConfig.useMockData) {
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
    await simulateNetworkDelay(ms: 700);
    return UserModel(
      id: 'NEW-${DateTime.now().millisecondsSinceEpoch}',
      role: role,
      firstName: firstName,
      lastName: lastName,
      email: email,
      createdAt: DateTime.now(),
    );
  }

  // API: POST /api/client/v1/auth/forgot-password
  Future<void> requestPasswordReset(String email) async {
    if (!AppConfig.useMockData) {
      await ApiClient.instance.dio
          .post('/client/v1/auth/forgot-password', data: {'email': email});
      return;
    }
    await simulateNetworkDelay();
  }

  // API: POST /api/client/v1/auth/logout
  Future<void> logout() async {
    if (!AppConfig.useMockData) {
      await ApiClient.instance.dio.post('/client/v1/auth/logout');
      await TokenStorage.clear();
      return;
    }
    await simulateNetworkDelay(ms: 200);
  }

  // API: GET /api/client/v1/auth/me
  Future<UserModel> getCurrentUser() async {
    final response = await ApiClient.instance.dio.get('/client/v1/auth/me');
    return UserModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  // API: POST /api/client/v1/auth/refresh
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
