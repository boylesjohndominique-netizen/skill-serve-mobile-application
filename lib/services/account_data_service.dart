import '../models/user_model.dart';
import 'api_client.dart';

/// Service for Data and Account Control (PDF §15).
///
/// The documented data-management endpoints (`/api/data-management/*`) are
/// admin-only. No client-facing account-data, deactivation, or deletion
/// endpoints exist yet, so these methods throw [UnsupportedError].
class AccountDataService {
  // GET /api/client/v1/auth/me — returns current profile data.
  Future<UserModel> getAccountData(UserModel current) async {
    final response =
        await ApiClient.instance.dio.get('/client/v1/auth/me');
    return UserModel.fromJson(
        response.data['data'] as Map<String, dynamic>);
  }

  // No documented client endpoint for account deactivation (PDF §15.2).
  Future<void> requestDeactivation({required String reason}) async {
    throw UnsupportedError(
        'Client account deactivation endpoint is not documented.');
  }

  // No documented client endpoint for account deletion (PDF §15.3).
  Future<void> requestDeletion(
      {required String reason, required String password}) async {
    throw UnsupportedError(
        'Client account deletion endpoint is not documented.');
  }
}
