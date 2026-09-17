import '../../../core/services/api_client.dart';
import '../../marketplace/models/provider_model.dart';
import '../models/provider_service_model.dart';

/// Provider-owned services — live API only.
///
/// Endpoints (see api-docs/modules/provider-services.md):
/// - GET    /api/client/v1/provider/services
/// - POST   /api/client/v1/provider/services
/// - GET    /api/client/v1/provider/services/{service}
/// - PUT    /api/client/v1/provider/services/{service}
/// - DELETE /api/client/v1/provider/services/{service}
/// - GET    /api/client/v1/categories (category + subcategory choices)
/// - GET    /api/client/v1/provider/profile (own profile, any verification state)
///
/// New services and every change wait for administrator approval.
class ProviderServiceService {
  static const _base = '/client/v1/provider/services';

  Future<List<ProviderServiceModel>> getMyServices() async {
    final response = await ApiClient.instance.dio.get(_base, queryParameters: {'per_page': 100});
    return [
      for (final item in response.data['data'] as List)
        ProviderServiceModel.fromJson(item as Map<String, dynamic>),
    ];
  }

  Future<ProviderServiceModel> getMyService(String id) async {
    final response = await ApiClient.instance.dio.get('$_base/$id');
    return ProviderServiceModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<ProviderServiceModel> create(Map<String, dynamic> values) async {
    final response = await ApiClient.instance.dio.post(_base, data: values);
    return ProviderServiceModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<ProviderServiceModel> update(String id, Map<String, dynamic> values) async {
    final response = await ApiClient.instance.dio.put('$_base/$id', data: values);
    return ProviderServiceModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<void> delete(String id) async {
    await ApiClient.instance.dio.delete('$_base/$id');
  }

  /// The signed-in provider's own profile. Unlike the public catalog, this
  /// works before verification and includes the verification status.
  Future<ProviderModel> getMyProfile() async {
    final response = await ApiClient.instance.dio.get('/client/v1/provider/profile');
    return ProviderModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<List<ServiceCategoryOption>> getCategories() async {
    final response = await ApiClient.instance.dio.get('/client/v1/categories', queryParameters: {'per_page': 100});
    return [
      for (final item in response.data['data'] as List)
        ServiceCategoryOption.fromJson(item as Map<String, dynamic>),
    ];
  }
}
