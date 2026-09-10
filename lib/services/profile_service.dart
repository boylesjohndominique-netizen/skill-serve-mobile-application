import '../models/user_model.dart';
import '../core/config/app_config.dart';
import 'api_client.dart';

/// Placeholder service for profile reads/updates.
class ProfileService {
  // API: GET /api/client/v1/auth/me. This is the documented client profile read.
  Future<UserModel> getProfile(UserModel current) async {
    if (!AppConfig.useMockData) {
      final response = await ApiClient.instance.dio.get('/client/v1/auth/me');
      return UserModel.fromJson(response.data['data'] as Map<String, dynamic>);
    }
    await simulateNetworkDelay(ms: 250);
    return current;
  }

  // PUT /me
  Future<UserModel> updateProfile(
    UserModel current, {
    String? firstName,
    String? lastName,
    String? phone,
    String? address,
    String? profilePicture,
    bool clearProfilePicture = false,
  }) async {
    // No client-owned profile update endpoint is documented. Do not call the
    // admin-only /api/users/{user} endpoint from this mobile client.
    if (!AppConfig.useMockData) {
      throw UnsupportedError(
          'Client profile update endpoint is not documented.');
    }
    await simulateNetworkDelay(ms: 500);
    return UserModel(
      id: current.id,
      role: current.role,
      firstName: firstName ?? current.firstName,
      lastName: lastName ?? current.lastName,
      email: current.email,
      phone: phone ?? current.phone,
      address: address ?? current.address,
      profilePicture:
          clearProfilePicture ? null : profilePicture ?? current.profilePicture,
      status: current.status,
      createdAt: current.createdAt,
    );
  }

  // API: POST /api/client/v1/auth/change-password
  Future<void> changePassword(
      {required String current, required String next}) async {
    if (!AppConfig.useMockData) {
      await ApiClient.instance.dio
          .post('/client/v1/auth/change-password', data: {
        'current_password': current,
        'password': next,
        'password_confirmation': next,
      });
      return;
    }
    await simulateNetworkDelay(ms: 500);
  }
}
