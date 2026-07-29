import '../models/user_model.dart';
import 'api_client.dart';

/// Placeholder service for profile reads/updates.
class ProfileService {
  // GET /me
  Future<UserModel> getProfile(UserModel current) async {
    await simulateNetworkDelay(ms: 250);
    return current;
  }

  // PUT /me
  Future<UserModel> updateProfile(UserModel current, {
    String? firstName,
    String? lastName,
    String? phone,
    String? address,
  }) async {
    await simulateNetworkDelay(ms: 500);
    return UserModel(
      id: current.id,
      role: current.role,
      firstName: firstName ?? current.firstName,
      lastName: lastName ?? current.lastName,
      email: current.email,
      phone: phone ?? current.phone,
      address: address ?? current.address,
      profilePicture: current.profilePicture,
      status: current.status,
      createdAt: current.createdAt,
    );
  }

  // POST /me/change-password
  Future<void> changePassword({required String current, required String next}) async {
    await simulateNetworkDelay(ms: 500);
  }
}
