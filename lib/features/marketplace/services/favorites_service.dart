import '../../../core/services/api_client.dart';
import '../models/provider_model.dart';

/// The signed-in customer's saved providers
/// (api-docs/modules/client-favorites.md):
/// - GET    /api/client/v1/favorites
/// - PUT    /api/client/v1/favorites/{provider}
/// - DELETE /api/client/v1/favorites/{provider}
///
/// Saving and removing are idempotent on the server, so a retried tap is safe.
class FavoritesService {
  static const _base = '/client/v1/favorites';

  /// The largest page the API allows; a customer's saved list is short.
  static const _perPage = 100;

  Future<List<ProviderModel>> list() async {
    final response = await ApiClient.instance.dio.get(_base, queryParameters: {'per_page': _perPage});
    return [
      for (final item in response.data['data'] as List? ?? const [])
        ProviderModel.fromJson(item as Map<String, dynamic>),
    ];
  }

  Future<void> add(String providerId) => ApiClient.instance.dio.put('$_base/$providerId');

  Future<void> remove(String providerId) => ApiClient.instance.dio.delete('$_base/$providerId');
}
