import '../models/user_model.dart';
import 'api_client.dart';

/// Service for profile reads/updates — live API only.
///
/// Endpoints:
/// - GET /api/client/v1/auth/me (read profile)
/// - POST /api/client/v1/auth/change-password
class ProfileService {
  // GET /api/client/v1/auth/me
  Future<UserModel> getProfile(UserModel current) async {
    final response = await ApiClient.instance.dio.get('/client/v1/auth/me');
    return UserModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  // No documented client endpoint for profile update.
  Future<UserModel> updateProfile(
    UserModel current, {
    String? firstName,
    String? lastName,
    String? phone,
    String? address,
    String? profilePicture,
    bool clearProfilePicture = false,
  }) async {
    throw UnsupportedError(
        'Client profile update endpoint is not documented.');
  }

  // POST /api/client/v1/auth/change-password
  Future<void> changePassword(
      {required String current, required String next}) async {
    await ApiClient.instance.dio
        .post('/client/v1/auth/change-password', data: {
      'current_password': current,
      'password': next,
      'password_confirmation': next,
    });
  }
}
