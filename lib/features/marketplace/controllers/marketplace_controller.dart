import 'package:flutter/foundation.dart';
import '../models/category_model.dart';
import '../models/discovery_filters.dart';
import '../models/provider_model.dart';
import '../models/service_model.dart';
import '../services/catalog_updates.dart';
import '../services/service_service.dart';

/// Drives the browsing surface of Browse Services, Categories, and the client
/// Home tab: the category list, the featured rail, the filtered provider list
/// and the newest services.
///
/// Free-text search lives in `DiscoveryController`; this controller owns the
/// browsing surface only. It follows [CatalogUpdates], so a service a
/// provider publishes appears on Home without a manual refresh.
class MarketplaceController extends ChangeNotifier {
  MarketplaceController({ServiceService? service, CatalogUpdates? updates})
      : _service = service ?? ServiceService(),
        _updates = updates ?? CatalogUpdates.instance {
    _updates.addListener(_onCatalogChanged);
  }

  final ServiceService _service;
  final CatalogUpdates _updates;

  /// How many of the newest services Home lists.
  static const latestServicesLimit = 8;

  List<CategoryModel> categories = [];
  List<ProviderModel> providers = [];
  List<ProviderModel> featuredProviders = [];

  /// The newest published services — narrowed by the selected category — so
  /// a service a provider just published shows up on Home.
  List<ServiceModel> services = [];

  bool isLoading = false;

  /// True once the first load finished, whatever its outcome — live updates
  /// only refresh a surface someone has opened.
  bool hasLoaded = false;

  /// Set when neither providers nor services could be loaded, so screens can
  /// show an error state with a retry instead of an empty page.
  String? error;

  /// Guards against an earlier, slower load overwriting a newer one.
  int _requestId = 0;

  /// The catalog changed while a load was already running — it may have read
  /// the old data, so one more refresh follows it.
  bool _refreshQueued = false;

  DiscoveryFilters filters = const DiscoveryFilters();

  /// Name of the selected category, or `All` — the category rails render
  /// their selection from this.
  String get selectedCategory => filters.category?.name ?? 'All';

  bool get hasActiveFilters => !filters.isEmpty;

  Future<void> loadInitial() => _load(includeCatalog: true);

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
    await _load(includeCatalog: false);
  }

  Future<void> clearFilters() => applyFilters(const DiscoveryFilters());

  /// The catalog changed on the server: refetch in place, keeping what is on
  /// screen until the new lists arrive rather than flashing a loader.
  void _onCatalogChanged() {
    if (isLoading) {
      _refreshQueued = true;
      return;
    }
    if (!hasLoaded) return;
    _load(includeCatalog: true, silent: true);
  }

  /// Each list loads on its own, so one failed request does not blank the
  /// whole Home tab. [includeCatalog] also refreshes the categories and the
  /// featured rail, which do not depend on the filters.
  Future<void> _load({required bool includeCatalog, bool silent = false}) async {
    final requestId = ++_requestId;
    if (!silent) {
      isLoading = true;
      error = null;
      notifyListeners();
    }

    final results = await Future.wait<Object?>([
      _attempt(() => _service.getProviders(filters: filters)),
      _attempt(() => _service.getServices(filters: filters, perPage: latestServicesLimit)),
      if (includeCatalog) ...[
        _attempt(_service.getCategories),
        _attempt(_service.getFeaturedProviders),
      ],
    ]);
    if (requestId != _requestId) return;

    final loadedProviders = results[0] as List<ProviderModel>?;
    final loadedServices = results[1] as List<ServiceModel>?;
    // A silent refresh that failed keeps the lists already on screen.
    if (loadedProviders != null || !silent) providers = loadedProviders ?? [];
    if (loadedServices != null || !silent) services = loadedServices ?? [];
    if (includeCatalog) {
      final loadedCategories = results[2] as List<CategoryModel>?;
      final loadedFeatured = results[3] as List<ProviderModel>?;
      if (loadedCategories != null) categories = loadedCategories;
      if (loadedFeatured != null || !silent) featuredProviders = loadedFeatured ?? [];
    }

    final nothingLoaded = loadedProviders == null && loadedServices == null;
    if (!silent || !nothingLoaded) {
      error = nothingLoaded
          ? 'We could not load the marketplace. Check your connection and try again.'
          : null;
    }
    isLoading = false;
    hasLoaded = true;
    notifyListeners();

    if (_refreshQueued) {
      _refreshQueued = false;
      await _load(includeCatalog: true, silent: true);
    }
  }

  /// The result of [request], or null when it failed.
  Future<T?> _attempt<T>(Future<T> Function() request) async {
    try {
      return await request();
    } catch (_) {
      return null;
    }
  }

  @override
  void dispose() {
    _updates.removeListener(_onCatalogChanged);
    super.dispose();
  }
}
