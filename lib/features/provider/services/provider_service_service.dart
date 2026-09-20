import '../../../core/services/api_client.dart';
import '../../marketplace/models/provider_model.dart';
import '../models/badge_model.dart';
import '../models/provider_availability_model.dart';
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
/// - PATCH  /api/client/v1/provider/profile (edit the professional profile)
/// - GET    /api/client/v1/provider/badges  (earned and still-available badges)
/// - GET    /api/client/v1/provider/availability (own weekly hours)
/// - PUT    /api/client/v1/provider/availability (replace the weekly hours)
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

  /// PATCH /api/client/v1/provider/profile — a partial update of the
  /// provider's own professional details. Verification status and featured
  /// flag are not editable; the API ignores them.
  Future<ProviderModel> updateMyProfile(Map<String, dynamic> values) async {
    final response = await ApiClient.instance.dio
        .patch('/client/v1/provider/profile', data: values);
    return ProviderModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  /// GET /api/client/v1/provider/badges — every active badge, flagged with
  /// whether this provider has earned it.
  Future<List<BadgeModel>> getMyBadges() async {
    final response =
        await ApiClient.instance.dio.get('/client/v1/provider/badges');
    final data = response.data['data'] as Map<String, dynamic>;
    return [
      for (final item in (data['earned'] as List? ?? const []))
        BadgeModel.fromJson(item as Map<String, dynamic>),
      for (final item in (data['available'] as List? ?? const []))
        BadgeModel.fromJson(item as Map<String, dynamic>),
    ];
  }

  /// GET /api/client/v1/provider/availability — the provider's own weekly
  /// hours and whether they are taking new bookings.
  Future<ProviderAvailability> getMyAvailability() async {
    final response =
        await ApiClient.instance.dio.get('/client/v1/provider/availability');
    return ProviderAvailability.fromJson(
        response.data['data'] as Map<String, dynamic>);
  }

  /// PUT /api/client/v1/provider/availability — replaces the whole
  /// schedule. Sending an empty list clears it, which means the provider
  /// publishes no hours rather than being unavailable.
  Future<ProviderAvailability> updateMyAvailability({
    required bool isAcceptingBookings,
    required List<ProviderAvailabilityModel> availability,
  }) async {
    final response = await ApiClient.instance.dio.put(
      '/client/v1/provider/availability',
      data: {
        'is_accepting_bookings': isAcceptingBookings,
        'availability': [for (final window in availability) window.toJson()],
      },
    );
    return ProviderAvailability.fromJson(
        response.data['data'] as Map<String, dynamic>);
  }

  Future<List<ServiceCategoryOption>> getCategories() async {
    final response = await ApiClient.instance.dio.get('/client/v1/categories', queryParameters: {'per_page': 100});
    return [
      for (final item in response.data['data'] as List)
        ServiceCategoryOption.fromJson(item as Map<String, dynamic>),
    ];
  }
}
