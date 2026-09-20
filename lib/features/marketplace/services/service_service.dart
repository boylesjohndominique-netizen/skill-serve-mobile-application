import '../models/category_model.dart';
import '../models/discovery_filters.dart';
import '../models/provider_model.dart';
import '../models/service_model.dart';
import '../../../core/services/api_client.dart';

/// Service for browsing categories, providers, and services.
///
/// Live endpoints:
/// - GET /api/client/v1/categories
/// - GET /api/client/v1/providers
/// - GET /api/client/v1/providers/{provider}
/// - GET /api/client/v1/services
/// - GET /api/client/v1/services/{service}
class ServiceService {
  /// Default page size for discovery lists — large enough to fill a screen
  /// without pulling the whole catalog.
  static const int discoveryPageSize = 30;

  // GET /api/client/v1/categories
  Future<List<CategoryModel>> getCategories() async {
    final response = await ApiClient.instance.dio
        .get('/client/v1/categories', queryParameters: {'per_page': 100});
    final data = response.data['data'] as List;
    return data
        .map((json) => CategoryModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// GET /api/client/v1/providers — verified providers, narrowed by the
  /// discovery filters the client applied.
  Future<List<ProviderModel>> getProviders({
    String? search,
    DiscoveryFilters filters = const DiscoveryFilters(),
    int perPage = discoveryPageSize,
  }) async {
    final response = await ApiClient.instance.dio.get(
      '/client/v1/providers',
      queryParameters: {
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
        ...filters.toProviderQuery(),
        'per_page': perPage,
      },
    );
    return _providers(response.data);
  }

  // GET /api/client/v1/providers/{provider}
  Future<ProviderModel> getProviderById(String id) async {
    final response =
        await ApiClient.instance.dio.get('/client/v1/providers/$id');
    return ProviderModel.fromJson(
        response.data['data'] as Map<String, dynamic>);
  }

  /// GET /api/client/v1/services — published, bookable services, narrowed by
  /// the discovery filters the client applied.
  Future<List<ServiceModel>> getServices({
    String? search,
    DiscoveryFilters filters = const DiscoveryFilters(),
    int perPage = discoveryPageSize,
  }) async {
    final response = await ApiClient.instance.dio.get(
      '/client/v1/services',
      queryParameters: {
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
        ...filters.toServiceQuery(),
        'per_page': perPage,
      },
    );
    return _services(response.data);
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
    return _services(response.data);
  }

  /// GET /api/client/v1/providers?featured=1 — the providers
  /// administrators have highlighted, used by the home screen's rail.
  Future<List<ProviderModel>> getFeaturedProviders({int limit = 10}) async {
    final response = await ApiClient.instance.dio.get(
      '/client/v1/providers',
      queryParameters: {'featured': 1, 'per_page': limit},
    );
    return _providers(response.data);
  }

  /// GET /api/client/v1/providers?sort=average_rating — providers recognized
  /// for strong ratings, used by the discovery screen.
  Future<List<ProviderModel>> getTopRatedProviders({
    int limit = 10,
    double minRating = 4,
  }) async {
    final response = await ApiClient.instance.dio.get(
      '/client/v1/providers',
      queryParameters: {
        'min_rating': minRating,
        'sort': 'average_rating',
        'direction': 'desc',
        'per_page': limit,
      },
    );
    return _providers(response.data);
  }

  List<ProviderModel> _providers(dynamic body) => [
        for (final item in (body['data'] as List? ?? const []))
          ProviderModel.fromJson(item as Map<String, dynamic>),
      ];

  List<ServiceModel> _services(dynamic body) => [
        for (final item in (body['data'] as List? ?? const []))
          ServiceModel.fromJson(item as Map<String, dynamic>),
      ];
}
