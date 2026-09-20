import '../models/user_preferences.dart';
import '../../../core/services/api_client.dart';

/// Account settings, stored server-side so they follow the user to any
/// device.
///
/// Endpoints:
/// - GET /api/client/v1/preferences
/// - PUT /api/client/v1/preferences
class PreferencesService {
  // GET /api/client/v1/preferences
  Future<UserPreferences> fetch() async {
    final response = await ApiClient.instance.dio.get('/client/v1/preferences');
    return UserPreferences.fromJson(
        response.data['data'] as Map<String, dynamic>);
  }

  /// PUT /api/client/v1/preferences — a partial update, so only the changed
  /// settings are sent.
  Future<UserPreferences> save(Map<String, dynamic> changes) async {
    final response = await ApiClient.instance.dio
        .put('/client/v1/preferences', data: changes);
    return UserPreferences.fromJson(
        response.data['data'] as Map<String, dynamic>);
  }
}
