import '../../auth/models/user_model.dart';
import '../../../core/services/api_client.dart';

/// Service for Data and Account Control (PDF §15).
///
/// Account data is read from the client profile endpoint. Deactivation is
/// not a SkillServe feature — accounts are either active or deleted — so
/// only deletion remains, and the documented data-management endpoints
/// (`/api/data-management/*`) are admin-only, leaving it unsupported for
/// now.
class AccountDataService {
  // GET /api/client/v1/auth/me — returns current profile data.
  Future<UserModel> getAccountData(UserModel current) async {
    final response =
        await ApiClient.instance.dio.get('/client/v1/auth/me');
    return UserModel.fromJson(
        response.data['data'] as Map<String, dynamic>);
  }

  // No documented client endpoint for account deletion (PDF §15.3).
  Future<void> requestDeletion(
      {required String reason, required String password}) async {
    throw UnsupportedError(
        'Client account deletion endpoint is not documented.');
  }
}
