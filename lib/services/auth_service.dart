import '../core/config/app_config.dart';
import '../data/mock/mock_data.dart';
import '../models/user_model.dart';
import 'api_client.dart';

/// Auth placeholder service.
///
/// Every method below documents the Laravel endpoint it will eventually
/// call. Until then, calls resolve against mock data so login/register/
/// forgot-password screens are fully navigable and demoable.
class AuthService {
  // POST /auth/login
  Future<UserModel> login({required String email, required String password}) async {
    if (!AppConfig.useMockData) {
      // final res = await ApiClient.instance.dio.post('/auth/login', data: {...});
      // return UserModel.fromJson(res.data['user']);
    }
    await simulateNetworkDelay();
    // Demo convenience: route "provider" in the email to the provider mock account.
    if (email.toLowerCase().contains('provider')) return MockData.currentProvider;
    return MockData.currentClient;
  }

  // POST /auth/register
  Future<UserModel> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required UserRole role,
  }) async {
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

  // POST /auth/forgot-password
  Future<void> requestPasswordReset(String email) async {
    await simulateNetworkDelay();
  }

  // POST /auth/logout
  Future<void> logout() async {
    await simulateNetworkDelay(ms: 200);
  }
}
