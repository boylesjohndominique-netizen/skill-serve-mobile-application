import '../../provider/models/badge_model.dart';
import '../models/category_model.dart';
import '../models/provider_model.dart';
import '../models/service_model.dart';
import '../../../core/services/api_client.dart';

/// Service for browsing categories, providers, and services.
///
/// Live endpoints:
/// - GET /api/client/v1/categories
/// - GET /api/client/v1/providers
/// - GET /api/client/v1/providers/{provider}
/// - GET /api/client/v1/services/{service}
/// - GET /api/client/v1/services?provider_id=X
class ServiceService {
  // GET /api/client/v1/categories
  Future<List<CategoryModel>> getCategories() async {
    final response = await ApiClient.instance.dio
        .get('/client/v1/categories', queryParameters: {'per_page': 100});
    final data = response.data['data'] as List;
    return data
        .map((json) => CategoryModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  // GET /api/client/v1/providers?search=&category_id=
  Future<List<ProviderModel>> getProviders(
      {String? category, String? search}) async {
    final params = <String, dynamic>{};
    if (search != null && search.isNotEmpty) params['search'] = search;
    if (category != null && category != 'All') {
      final cats = await getCategories();
      final match = cats.where((c) => c.name == category).firstOrNull;
      if (match != null) params['category_id'] = match.id;
    }
    final response = await ApiClient.instance.dio
        .get('/client/v1/providers', queryParameters: params);
    final data = response.data['data'] as List;
    return data
        .map((json) => ProviderModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  // GET /api/client/v1/providers/{provider}
  Future<ProviderModel> getProviderById(String id) async {
    final response =
        await ApiClient.instance.dio.get('/client/v1/providers/$id');
    return ProviderModel.fromJson(
        response.data['data'] as Map<String, dynamic>);
  }

  // GET /api/client/v1/services/{service}
  Future<ServiceModel> getServiceById(String id) async {
    final response =
        await ApiClient.instance.dio.get('/client/v1/services/$id');
    return ServiceModel.fromJson(
        response.data['data'] as Map<String, dynamic>);
  }

  // GET /api/client/v1/services?provider_id=X
  Future<List<ServiceModel>> getServicesForProvider(String providerId) async {
    final response = await ApiClient.instance.dio
        .get('/client/v1/services', queryParameters: {'provider_id': providerId});
    final data = response.data['data'] as List;
    return data
        .map((json) => ServiceModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  // No documented client endpoint for featured providers.
  Future<List<ProviderModel>> getFeaturedProviders() async {
    throw UnsupportedError(
        'Featured providers endpoint is not documented for clients.');
  }

  // No documented client endpoint for provider badges.
  Future<List<BadgeModel>> getProviderBadges(String providerId) async {
    throw UnsupportedError(
        'Provider badges endpoint is not documented for clients.');
  }
}
