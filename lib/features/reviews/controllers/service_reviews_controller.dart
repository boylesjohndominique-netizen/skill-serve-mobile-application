import 'package:flutter/foundation.dart';

import '../../marketplace/services/catalog_updates.dart';
import '../models/review_model.dart';
import '../services/review_service.dart';

/// One service's reviews: the summary, the reviews loaded so far (page by
/// page), and an optional star filter. Follows [CatalogUpdates], so a review
/// another customer posts appears while the screen is open.
class ServiceReviewsController extends ChangeNotifier {
  ServiceReviewsController({
    required this.serviceId,
    this.pageSize = 10,
    ReviewService? service,
    CatalogUpdates? updates,
  })  : _service = service ?? ReviewService(),
        _updates = updates ?? CatalogUpdates.instance {
    _updates.addListener(_onCatalogChanged);
  }

  final String serviceId;
  final int pageSize;
  final ReviewService _service;
  final CatalogUpdates _updates;

  List<ReviewModel> reviews = [];
  double average = 0;
  int total = 0;
  Map<int, int> breakdown = const {};

  /// Only reviews with this many stars; null for all.
  int? rating;

  bool isLoading = false;
  bool isLoadingMore = false;
  bool hasMore = false;
  bool hasLoaded = false;
  String? error;

  int _page = 1;
  int _requestId = 0;
  bool _disposed = false;

  Future<void> load() => _loadFirst(silent: false);

  Future<void> filter(int? stars) async {
    if (stars == rating) return;
    rating = stars;
    await _loadFirst(silent: false);
  }

  Future<void> loadMore() async {
    if (!hasMore || isLoadingMore || isLoading) return;
    isLoadingMore = true;
    _notify();
    final requestId = _requestId;
    try {
      final page = await _service.getServiceReviews(serviceId, page: _page + 1, perPage: pageSize, rating: rating);
      if (requestId != _requestId) return;
      _page = page.currentPage;
      // A review may already be listed if new ones shifted the pages.
      final seen = {for (final r in reviews) r.id};
      reviews = [...reviews, ...page.reviews.where((r) => !seen.contains(r.id))];
      hasMore = page.hasMore;
    } catch (_) {
      // Keep what is shown; the next scroll tries again.
    }
    isLoadingMore = false;
    _notify();
  }

  void _onCatalogChanged() {
    if (hasLoaded) _loadFirst(silent: true);
  }

  /// Reloads from the first page. [silent] keeps the list on screen and
  /// leaves it as it is when the refresh fails.
  Future<void> _loadFirst({required bool silent}) async {
    final requestId = ++_requestId;
    if (!silent) {
      isLoading = true;
      error = null;
      _notify();
    }
    try {
      // A live refresh reloads as many reviews as are already shown.
      final perPage = silent ? reviews.length.clamp(pageSize, 50) : pageSize;
      final page = await _service.getServiceReviews(serviceId, perPage: perPage, rating: rating);
      if (requestId != _requestId) return;
      reviews = page.reviews;
      average = page.average;
      total = page.total;
      breakdown = page.breakdown;
      hasMore = page.hasMore;
      _page = silent ? (reviews.length / pageSize).ceil().clamp(1, 1 << 30) : 1;
      error = null;
      hasLoaded = true;
    } catch (_) {
      if (requestId != _requestId) return;
      if (!silent) error = 'We could not load the reviews. Check your connection and try again.';
    }
    isLoading = false;
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _updates.removeListener(_onCatalogChanged);
    super.dispose();
  }
}
