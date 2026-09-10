import '../core/config/app_config.dart';
import '../models/user_model.dart';
import 'api_client.dart';

/// Service for Data and Account Control (PDF §15).
///
/// The documented data-management endpoints (`/api/data-management/*`) are
/// admin-only. No client-facing account-data, deactivation, or deletion
/// endpoints exist yet, so live mode throws [UnsupportedError] while mock
/// mode returns realistic placeholder data.
class AccountDataService {
  // No documented client endpoint for account data export/view.
  Future<UserModel> getAccountData(UserModel current) async {
    if (!AppConfig.useMockData) {
      // Use GET /api/client/v1/auth/me to return the current profile data.
      final response =
          await ApiClient.instance.dio.get('/client/v1/auth/me');
      return UserModel.fromJson(
          response.data['data'] as Map<String, dynamic>);
    }
    return current;
  }

  // No documented client endpoint for account deactivation (PDF §15.2).
  Future<void> requestDeactivation({required String reason}) async {
    if (!AppConfig.useMockData) {
      throw UnsupportedError(
          'Client account deactivation endpoint is not documented.');
    }
    await Future.delayed(const Duration(milliseconds: 600));
  }

  // No documented client endpoint for account deletion (PDF §15.3).
  Future<void> requestDeletion({required String reason, required String password}) async {
    if (!AppConfig.useMockData) {
      throw UnsupportedError(
          'Client account deletion endpoint is not documented.');
    }
    await Future.delayed(const Duration(milliseconds: 600));
  }
}
