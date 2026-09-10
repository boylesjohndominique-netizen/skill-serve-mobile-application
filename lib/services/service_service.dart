import '../core/config/app_config.dart';
import '../data/mock/mock_data.dart';
import '../models/badge_model.dart';
import '../models/category_model.dart';
import '../models/provider_model.dart';
import '../models/service_model.dart';
import 'api_client.dart';

/// Service for browsing categories, providers, and services.
///
/// Live endpoints (when [AppConfig.useMockData] is false):
/// - GET /api/client/v1/categories
/// - GET /api/client/v1/providers
/// - GET /api/client/v1/providers/{provider}
/// - GET /api/client/v1/services/{service}
/// - GET /api/client/v1/services?provider_id=X
class ServiceService {
  // GET /api/client/v1/categories
  Future<List<CategoryModel>> getCategories() async {
    if (!AppConfig.useMockData) {
      final response =
          await ApiClient.instance.dio.get('/client/v1/categories');
      final data = response.data['data'] as List;
      return data
          .map((json) => CategoryModel.fromJson(json as Map<String, dynamic>))
          .toList();
    }
    await simulateNetworkDelay(ms: 350);
    return MockData.categories;
  }

  // GET /api/client/v1/providers?search=&category_id=
  Future<List<ProviderModel>> getProviders(
      {String? category, String? search}) async {
    if (!AppConfig.useMockData) {
      final params = <String, dynamic>{};
      if (search != null && search.isNotEmpty) params['search'] = search;
      if (category != null && category != 'All') {
        final match = MockData.categories
            .where((c) => c.name == category)
            .firstOrNull;
        if (match != null) params['category_id'] = match.id;
      }
      final response = await ApiClient.instance.dio
          .get('/client/v1/providers', queryParameters: params);
      final data = response.data['data'] as List;
      return data
          .map((json) => ProviderModel.fromJson(json as Map<String, dynamic>))
          .toList();
    }
    await simulateNetworkDelay();
    return MockData.providers.where((p) {
      final matchCategory =
          category == null || category == 'All' || p.categoryName == category;
      final matchSearch = search == null ||
          search.isEmpty ||
          p.user.fullName.toLowerCase().contains(search.toLowerCase()) ||
          p.categoryName.toLowerCase().contains(search.toLowerCase());
      return matchCategory && matchSearch;
    }).toList();
  }

  // GET /api/client/v1/providers/{provider}
  Future<ProviderModel> getProviderById(String id) async {
    if (!AppConfig.useMockData) {
      final response =
          await ApiClient.instance.dio.get('/client/v1/providers/$id');
      return ProviderModel.fromJson(
          response.data['data'] as Map<String, dynamic>);
    }
    await simulateNetworkDelay(ms: 300);
    return MockData.providers
        .firstWhere((p) => p.id == id, orElse: () => MockData.providers.first);
  }

  // GET /api/client/v1/services/{service}
  Future<ServiceModel> getServiceById(String id) async {
    if (!AppConfig.useMockData) {
      final response =
          await ApiClient.instance.dio.get('/client/v1/services/$id');
      return ServiceModel.fromJson(
          response.data['data'] as Map<String, dynamic>);
    }
    await simulateNetworkDelay(ms: 300);
    return MockData.services
        .firstWhere((s) => s.id == id, orElse: () => MockData.services.first);
  }

  // GET /api/client/v1/services?provider_id=X
  Future<List<ServiceModel>> getServicesForProvider(String providerId) async {
    if (!AppConfig.useMockData) {
      final response = await ApiClient.instance.dio
          .get('/client/v1/services', queryParameters: {'provider_id': providerId});
      final data = response.data['data'] as List;
      return data
          .map((json) => ServiceModel.fromJson(json as Map<String, dynamic>))
          .toList();
    }
    await simulateNetworkDelay(ms: 250);
    return MockData.services
        .where((s) => s.providerId == providerId && s.status == 'active')
        .toList();
  }

  // No documented client endpoint for featured providers — uses mock only.
  Future<List<ProviderModel>> getFeaturedProviders() async {
    await simulateNetworkDelay(ms: 250);
    return MockData.featuredProviders;
  }

  // No documented client endpoint for provider badges — uses mock only.
  Future<List<BadgeModel>> getProviderBadges(String providerId) async {
    await simulateNetworkDelay(ms: 250);
    return MockData.badges;
  }
}
