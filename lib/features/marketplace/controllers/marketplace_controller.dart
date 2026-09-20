import 'package:flutter/foundation.dart';
import '../models/category_model.dart';
import '../models/discovery_filters.dart';
import '../models/provider_model.dart';
import '../services/service_service.dart';

/// Drives provider discovery on Browse Services, Categories, and the client
/// Home tab: the category list plus the filtered provider list.
///
/// Free-text search lives in `DiscoveryController`; this controller owns the
/// browsing surface only.
class MarketplaceController extends ChangeNotifier {
  MarketplaceController({ServiceService? service})
      : _service = service ?? ServiceService();

  final ServiceService _service;

  List<CategoryModel> categories = [];
  List<ProviderModel> providers = [];
  bool isLoading = false;

  /// Set when the catalog could not be loaded, so screens can show an error
  /// state with a retry instead of an empty list.
  String? error;

  DiscoveryFilters filters = const DiscoveryFilters();

  /// Name of the selected category, or `All` — the category rails render
  /// their selection from this.
  String get selectedCategory => filters.category?.name ?? 'All';

  bool get hasActiveFilters => !filters.isEmpty;

  Future<void> loadInitial() async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      categories = await _service.getCategories();
      providers = await _service.getProviders(filters: filters);
    } catch (_) {
      error = 'We could not load the marketplace. Check your connection and try again.';
      providers = [];
    }
    isLoading = false;
    notifyListeners();
  }

  /// Selects a category by name — `All` clears the category filter. Names
  /// come from the loaded [categories], so an unknown name clears it too.
  Future<void> filterByCategory(String name) {
    final matches = categories.where((category) => category.name == name);
    final match = matches.isEmpty ? null : matches.first;
    return applyFilters(match == null
        ? filters.copyWith(clearCategory: true)
        : filters.copyWith(category: match));
  }

  Future<void> applyFilters(DiscoveryFilters updated) async {
    filters = updated;
    await _loadProviders();
  }

  Future<void> clearFilters() => applyFilters(const DiscoveryFilters());

  Future<void> _loadProviders() async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      providers = await _service.getProviders(filters: filters);
    } catch (_) {
      error = 'We could not load providers. Check your connection and try again.';
      providers = [];
    }
    isLoading = false;
    notifyListeners();
  }
}
