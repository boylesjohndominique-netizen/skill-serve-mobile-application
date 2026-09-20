import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/category_model.dart';
import '../models/discovery_filters.dart';
import '../models/provider_model.dart';
import '../models/service_model.dart';
import '../services/recent_searches_service.dart';
import '../services/service_service.dart';

/// Drives the Explore tab: one search box over services and providers, the
/// suggestions and recent terms that lead into it, and the featured and
/// top-rated rails shown before a search is made.
class DiscoveryController extends ChangeNotifier {
  DiscoveryController({
    ServiceService? service,
    RecentSearchesService? recentSearches,
    Duration debounce = const Duration(milliseconds: 350),
  })  : _service = service ?? ServiceService(),
        _recentSearches = recentSearches ?? RecentSearchesService(),
        _debounce = debounce;

  final ServiceService _service;
  final RecentSearchesService _recentSearches;
  final Duration _debounce;

  Timer? _debounceTimer;

  bool _loadedHighlights = false;

  /// Last observed session state; `null` until the first report.
  bool? _signedIn;

  /// Guards against an earlier, slower request overwriting newer results.
  int _requestId = 0;

  String query = '';
  DiscoveryFilters filters = const DiscoveryFilters();

  List<CategoryModel> categories = [];
  List<ServiceModel> services = [];
  List<ProviderModel> providers = [];
  List<ProviderModel> featuredProviders = [];
  List<ProviderModel> topRatedProviders = [];
  List<String> recentSearches = [];

  bool isLoading = false;
  bool isLoadingHighlights = false;
  String? error;

  /// True once a search has run, so the screen can tell "no results" apart
  /// from "nothing searched yet".
  bool hasSearched = false;

  bool get hasQuery => query.trim().isNotEmpty;

  bool get hasResults => services.isNotEmpty || providers.isNotEmpty;

  int get resultCount => services.length + providers.length;

  /// Search suggestions drawn from what the platform actually offers: the
  /// enabled categories plus the titles and provider names already matched
  /// by the current query.
  List<String> get suggestions {
    final term = query.trim().toLowerCase();
    if (term.isEmpty) return const [];

    final seen = <String>{};
    final matches = <String>[];

    void offer(String value) {
      final text = value.trim();
      if (text.isEmpty || text.toLowerCase() == term) return;
      if (!text.toLowerCase().contains(term)) return;
      if (seen.add(text.toLowerCase())) matches.add(text);
    }

    for (final category in categories) {
      offer(category.name);
    }
    for (final service in services) {
      offer(service.title);
    }
    for (final provider in providers) {
      offer(provider.user.fullName);
    }

    return matches.take(6).toList();
  }

  /// Loads the categories used for filtering and suggestions, the recent
  /// terms, and the highlight rails shown before a search.
  ///
  /// The controller outlives the screen, so remounting Explore refreshes the
  /// recent terms only; the rails are re-fetched on pull-to-refresh.
  Future<void> initialize() async {
    recentSearches = await _readRecents();
    notifyListeners();
    if (_loadedHighlights) return;
    await loadHighlights();
  }

  Future<void> loadHighlights() async {
    isLoadingHighlights = true;
    notifyListeners();
    try {
      final results = await Future.wait([
        _service.getCategories(),
        _service.getFeaturedProviders(),
        _service.getTopRatedProviders(),
      ]);
      categories = results[0] as List<CategoryModel>;
      featuredProviders = results[1] as List<ProviderModel>;
      topRatedProviders = results[2] as List<ProviderModel>;
      _loadedHighlights = true;
    } catch (_) {
      // The rails are supporting content: leave them empty rather than
      // blocking the search box behind an error screen.
      featuredProviders = [];
      topRatedProviders = [];
    }
    isLoadingHighlights = false;
    notifyListeners();
  }

  /// Called on every keystroke — debounced so typing does not fire a request
  /// per character.
  void onQueryChanged(String value) {
    query = value;
    _debounceTimer?.cancel();

    if (!hasQuery) {
      _clearResults();
      notifyListeners();
      return;
    }

    notifyListeners();
    _debounceTimer = Timer(_debounce, () => _search());
  }

  /// Runs the search immediately and remembers the term — used by the
  /// keyboard's search action, suggestions, and recent-search chips.
  Future<void> submit([String? term]) async {
    if (term != null) query = term;
    _debounceTimer?.cancel();
    if (!hasQuery) {
      _clearResults();
      notifyListeners();
      return;
    }

    notifyListeners();
    await _search();
    await _rememberSearch(query);
  }

  Future<void> applyFilters(DiscoveryFilters updated) async {
    filters = updated;
    if (hasQuery) {
      await _search();
    } else {
      notifyListeners();
    }
  }

  Future<void> clearFilters() => applyFilters(const DiscoveryFilters());

  void clearQuery() {
    _debounceTimer?.cancel();
    query = '';
    _clearResults();
    notifyListeners();
  }

  /// Search history is stored on the device, so it is dropped when a session
  /// ends — the next account to sign in must not inherit the previous user's
  /// terms.
  Future<void> onAuthChanged({required bool signedIn}) async {
    final previous = _signedIn;
    if (previous == signedIn) return;
    _signedIn = signedIn;
    if (previous != true) return;

    clearQuery();
    await clearRecents();
  }

  Future<void> removeRecent(String term) async {
    try {
      recentSearches = await _recentSearches.remove(term);
    } catch (_) {
      recentSearches = recentSearches
          .where((entry) => entry.toLowerCase() != term.toLowerCase())
          .toList();
    }
    notifyListeners();
  }

  Future<void> clearRecents() async {
    try {
      await _recentSearches.clear();
    } catch (_) {
      // Local history is a convenience; drop it from memory either way.
    }
    recentSearches = [];
    notifyListeners();
  }

  /// Search history lives in on-device storage, which can be unavailable.
  /// It never blocks searching, so read and write failures are absorbed.
  Future<List<String>> _readRecents() async {
    try {
      return await _recentSearches.read();
    } catch (_) {
      return const [];
    }
  }

  Future<void> _rememberSearch(String term) async {
    try {
      recentSearches = await _recentSearches.add(term);
    } catch (_) {
      return;
    }
    notifyListeners();
  }

  /// Retries the current search after a failure.
  Future<void> retry() => hasQuery ? _search() : loadHighlights();

  Future<void> _search() async {
    final term = query.trim();
    final requestId = ++_requestId;

    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _service.getServices(search: term, filters: filters),
        _service.getProviders(search: term, filters: filters),
      ]);
      if (requestId != _requestId) return;
      services = results[0] as List<ServiceModel>;
      providers = results[1] as List<ProviderModel>;
    } catch (_) {
      if (requestId != _requestId) return;
      services = [];
      providers = [];
      error = 'We could not run that search. Check your connection and try again.';
    }

    isLoading = false;
    hasSearched = true;
    notifyListeners();
  }

  void _clearResults() {
    _requestId++;
    services = [];
    providers = [];
    isLoading = false;
    hasSearched = false;
    error = null;
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}
