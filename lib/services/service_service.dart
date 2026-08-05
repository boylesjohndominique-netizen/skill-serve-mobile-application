import '../data/mock/mock_data.dart';
import '../models/badge_model.dart';
import '../models/category_model.dart';
import '../models/provider_model.dart';
import '../models/service_model.dart';
import 'api_client.dart';

/// Placeholder service for browsing categories, providers, and services.
class ServiceService {
  // GET /categories
  Future<List<CategoryModel>> getCategories() async {
    await simulateNetworkDelay(ms: 350);
    return MockData.categories;
  }

  // GET /providers?category=&search=
  Future<List<ProviderModel>> getProviders({String? category, String? search}) async {
    await simulateNetworkDelay();
    return MockData.providers.where((p) {
      final matchCategory = category == null || category == 'All' || p.categoryName == category;
      final matchSearch = search == null ||
          search.isEmpty ||
          p.user.fullName.toLowerCase().contains(search.toLowerCase()) ||
          p.categoryName.toLowerCase().contains(search.toLowerCase());
      return matchCategory && matchSearch;
    }).toList();
  }

  // GET /providers/:id
  Future<ProviderModel> getProviderById(String id) async {
    await simulateNetworkDelay(ms: 300);
    return MockData.providers.firstWhere((p) => p.id == id, orElse: () => MockData.providers.first);
  }

  // GET /services/:id
  Future<ServiceModel> getServiceById(String id) async {
    await simulateNetworkDelay(ms: 300);
    return MockData.services.firstWhere((s) => s.id == id, orElse: () => MockData.services.first);
  }

  // GET /providers/:id/services (active only — what clients can book)
  Future<List<ServiceModel>> getServicesForProvider(String providerId) async {
    await simulateNetworkDelay(ms: 250);
    return MockData.services
        .where((s) => s.providerId == providerId && s.status == 'active')
        .toList();
  }

  // GET /providers?featured=1
  Future<List<ProviderModel>> getFeaturedProviders() async {
    await simulateNetworkDelay(ms: 250);
    return MockData.featuredProviders;
  }

  // GET /providers/:id/badges
  Future<List<BadgeModel>> getProviderBadges(String providerId) async {
    await simulateNetworkDelay(ms: 250);
    return MockData.badges;
  }
}
