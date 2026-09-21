import 'dart:convert';

import '../../auth/models/user_model.dart';
import '../../../core/services/api_client.dart';

/// Service for Data and Account Control — live API only.
///
/// Endpoints:
/// - GET    /api/client/v1/auth/me                (profile on screen)
/// - GET    /api/client/v1/auth/me/data-export    (a copy of everything)
/// - DELETE /api/client/v1/auth/me                (close the account)
///
/// Deactivation is not a SkillServe feature — an account is either active or
/// deleted — so only deletion exists here.
class AccountDataService {
  /// GET /api/client/v1/auth/me — the profile the screen renders.
  Future<UserModel> getAccountData(UserModel current) async {
    final response = await ApiClient.instance.dio.get('/client/v1/auth/me');
    return UserModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  /// GET /api/client/v1/auth/me/data-export — the account's own data:
  /// profile, preferences, provider profile, bookings, reviews, reports and
  /// support tickets.
  Future<Map<String, dynamic>> exportAccountData() async {
    final response = await ApiClient.instance.dio.get('/client/v1/auth/me/data-export');
    return (response.data['data'] as Map<String, dynamic>?) ?? const {};
  }

  /// The export as indented JSON, ready to copy out of the app.
  Future<String> exportAccountDataAsJson() async {
    final data = await exportAccountData();
    return const JsonEncoder.withIndent('  ').convert(data);
  }

  /// DELETE /api/client/v1/auth/me — closes the account for good.
  ///
  /// The API confirms the password and refuses while any booking is still open,
  /// so the other party is never left mid-job. The account is soft-deleted and
  /// every device is signed out; an administrator can restore it.
  Future<void> deleteAccount({required String password, String? reason}) async {
    await ApiClient.instance.dio.delete(
      '/client/v1/auth/me',
      data: {
        'password': password,
        if (reason != null && reason.trim().isNotEmpty) 'reason': reason.trim(),
      },
    );
  }
}
