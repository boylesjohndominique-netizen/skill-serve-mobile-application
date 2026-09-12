import '../models/user_model.dart';
import '../../../core/services/api_client.dart';
import '../../../core/services/token_storage.dart';

/// Auth service — live API only.
///
/// Endpoints:
/// - POST /api/client/v1/auth/login
/// - POST /api/client/v1/auth/register (client accounts)
/// - POST /api/client/v1/auth/register-provider (provider accounts)
/// - POST /api/client/v1/auth/verify-otp (6-digit email code)
/// - POST /api/client/v1/auth/resend-otp
/// - POST /api/client/v1/auth/google (Google Sign-In ID token)
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
  }) async {
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

  // POST /api/client/v1/auth/register-provider
  Future<UserModel> registerProvider({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    String? businessName,
    required String specialization,
    int experienceYears = 0,
    String? bio,
  }) async {
    final response = await ApiClient.instance.dio
        .post('/client/v1/auth/register-provider', data: {
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'password': password,
      'password_confirmation': password,
      if (businessName != null && businessName.isNotEmpty)
        'business_name': businessName,
      'specialization': specialization,
      'experience_years': experienceYears,
      if (bio != null && bio.isNotEmpty) 'bio': bio,
    });
    final data = response.data['data'] as Map<String, dynamic>;
    _readSession(data);
    return UserModel.fromJson(data['user'] as Map<String, dynamic>);
  }

  // POST /api/client/v1/auth/verify-otp
  Future<UserModel> verifyOtp({required String email, required String code}) async {
    final response = await ApiClient.instance.dio
        .post('/client/v1/auth/verify-otp', data: {
      'email': email,
      'code': code,
    });
    return UserModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  // POST /api/client/v1/auth/resend-otp
  Future<void> resendOtp({required String email}) async {
    await ApiClient.instance.dio
        .post('/client/v1/auth/resend-otp', data: {'email': email});
  }

  // POST /api/client/v1/auth/cancel-registration — deletes the unverified
  // account created by register/register-provider. No-ops (200) for
  // verified or unknown accounts; the app ignores the outcome either way.
  Future<void> cancelRegistration(
      {required String email, required String password}) async {
    await ApiClient.instance.dio.post('/client/v1/auth/cancel-registration',
        data: {'email': email, 'password': password});
  }

  // POST /api/client/v1/auth/google
  Future<UserModel> loginWithGoogle({required String idToken}) async {
    final response = await ApiClient.instance.dio
        .post('/client/v1/auth/google', data: {'id_token': idToken});
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
