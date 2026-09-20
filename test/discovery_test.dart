import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skilllink_mobile/features/marketplace/controllers/discovery_controller.dart';
import 'package:skilllink_mobile/features/marketplace/models/category_model.dart';
import 'package:skilllink_mobile/features/marketplace/models/discovery_filters.dart';
import 'package:skilllink_mobile/features/marketplace/models/provider_model.dart';
import 'package:skilllink_mobile/features/marketplace/models/service_model.dart';
import 'package:skilllink_mobile/features/marketplace/services/recent_searches_service.dart';
import 'package:skilllink_mobile/features/marketplace/services/service_service.dart';

/// Payload shapes below mirror api-docs/openapi.json (ClientProvider,
/// ClientService) and the query parameters documented for
/// GET /api/client/v1/providers and /services.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('discovery filters', () {
    final category = CategoryModel.fromJson({'id': 4, 'name': 'Plumbing'});

    test('an empty filter set sends only the defaults', () {
      const filters = DiscoveryFilters();

      expect(filters.isEmpty, isTrue);
      expect(filters.activeCount, 0);
      expect(filters.toProviderQuery(), {'sort': 'created_at', 'direction': 'desc'});
      expect(filters.toServiceQuery(), {'sort': 'created_at', 'direction': 'desc'});
    });

    test('provider filters map onto the documented query parameters', () {
      final filters = DiscoveryFilters(
        category: category,
        minRating: 4.5,
        featuredOnly: true,
        availableOnly: true,
        sort: DiscoverySort.topRated,
      );

      expect(filters.activeCount, 5);
      expect(filters.toProviderQuery(), {
        'category_id': '4',
        'min_rating': 4.5,
        'featured': 1,
        'available': 1,
        'sort': 'average_rating',
        'direction': 'desc',
      });
    });

    test('recognition and availability are dropped from the services query', () {
      final filters = DiscoveryFilters(
        category: category,
        minRating: 4,
        featuredOnly: true,
        availableOnly: true,
        sort: DiscoverySort.priceLowToHigh,
      );

      expect(filters.toServiceQuery(), {
        'category_id': '4',
        'min_rating': 4.0,
        'sort': 'price',
        'direction': 'asc',
      });
      // `price` is not a provider sort, so the provider query falls back to
      // the endpoint's default ordering.
      expect(filters.toProviderQuery().containsKey('sort'), isFalse);
    });

    test('the weekday filter is provider-only and clears explicitly', () {
      final filters = DiscoveryFilters(category: category, availableDay: 6);

      expect(filters.activeCount, 2);
      expect(filters.availableDayLabel, 'Saturday');
      expect(filters.toProviderQuery()['available_day'], 6);
      expect(filters.toServiceQuery().containsKey('available_day'), isFalse);
      expect(filters.copyWith(clearAvailableDay: true).availableDay, isNull);
      expect(filters.copyWith(availableDay: 0).availableDay, 0);
    });

    test('copyWith clears the category and rating explicitly', () {
      final filters = DiscoveryFilters(category: category, minRating: 4);

      expect(filters.copyWith(clearCategory: true).category, isNull);
      expect(filters.copyWith(clearMinRating: true).minRating, isNull);
      expect(filters.copyWith(featuredOnly: true).category?.id, '4');
      expect(filters, DiscoveryFilters(category: category, minRating: 4));
    });

    test('rating thresholds read as whole or half stars', () {
      expect(DiscoveryFilters.ratingLabel(4), '4+');
      expect(DiscoveryFilters.ratingLabel(4.5), '4.5+');
    });
  });

  group('catalog models', () {
    test('provider parses recognition, skills and verification', () {
      final provider = ProviderModel.fromJson({
        'id': 9,
        'business_name': 'Juan Aircon Services',
        'skills': ['Aircon cleaning', '  ', 'Installation'],
        'is_featured': true,
        'verification_status': 'verified',
        'verified_at': '2026-09-01T10:00:00+00:00',
        'average_rating': '4.90',
        'badges': [
          {'key': 'top_rated', 'title': 'Top Rated', 'earned': true},
          {'key': 'veteran', 'title': 'Veteran', 'earned': false},
        ],
      });

      expect(provider.isFeatured, isTrue);
      expect(provider.skills, ['Aircon cleaning', 'Installation']);
      expect(provider.isVerified, isTrue);
      expect(provider.verifiedAt, DateTime.parse('2026-09-01T10:00:00+00:00'));
      expect(provider.isTopRated, isTrue);
      expect(provider.earnedBadges.map((b) => b.key), ['top_rated']);
    });

    test('service carries its rating and its provider name', () {
      final service = ServiceModel.fromJson({
        'id': 21,
        'title': 'Aircon Cleaning',
        'price': '1500.00',
        'price_type': 'fixed',
        'average_rating': '4.25',
        'total_reviews': 8,
        'provider': {'id': 9, 'business_name': 'Juan Aircon'},
      });

      expect(service.providerName, 'Juan Aircon');
      expect(service.averageRating, 4.25);
      expect(service.reviewCount, 8);
      expect(service.isQuoteOnly, isFalse);
    });

    test('a custom-priced service is quote only', () {
      final service = ServiceModel.fromJson({
        'id': 22,
        'title': 'Bespoke install',
        'price': null,
        'price_type': 'custom',
      });

      expect(service.isQuoteOnly, isTrue);
    });
  });

  group('recent searches', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('newest term wins, duplicates collapse and the list is capped', () async {
      final service = RecentSearchesService();

      await service.add('plumber');
      await service.add('  ');
      var stored = await service.add('Electrician');
      expect(stored, ['Electrician', 'plumber']);

      // Case-insensitive de-duplication moves the term back to the front.
      stored = await service.add('PLUMBER');
      expect(stored, ['PLUMBER', 'Electrician']);

      for (var i = 0; i < RecentSearchesService.maxEntries; i++) {
        stored = await service.add('term $i');
      }
      expect(stored, hasLength(RecentSearchesService.maxEntries));
      expect(stored.first, 'term ${RecentSearchesService.maxEntries - 1}');
    });

    test('entries can be removed one by one or cleared', () async {
      final service = RecentSearchesService();
      await service.add('plumber');
      await service.add('tutor');

      expect(await service.remove('PLUMBER'), ['tutor']);

      await service.clear();
      expect(await service.read(), isEmpty);
    });
  });

  group('discovery controller', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('initialize loads the recent terms and the highlight rails', () async {
      final controller = DiscoveryController(service: _FakeServiceService());

      await controller.initialize();

      expect(controller.categories.map((c) => c.name), ['Plumbing', 'Tutoring']);
      expect(controller.featuredProviders.single.user.fullName, 'Featured Co.');
      expect(controller.topRatedProviders.single.user.fullName, 'Top Rated Co.');
      expect(controller.isLoadingHighlights, isFalse);
      controller.dispose();
    });

    test('the rails load once per session but refresh on demand', () async {
      final fake = _FakeServiceService();
      final controller = DiscoveryController(service: fake);

      await controller.initialize();
      await controller.initialize();
      expect(fake.highlightLoads, 1, reason: 'remounting Explore must not refetch');

      await controller.loadHighlights();
      expect(fake.highlightLoads, 2, reason: 'pull-to-refresh reloads');
      controller.dispose();
    });

    test('submitting searches services and providers and records the term', () async {
      final fake = _FakeServiceService();
      final controller = DiscoveryController(service: fake);

      await controller.submit('aircon');

      expect(fake.serviceSearches, ['aircon']);
      expect(fake.providerSearches, ['aircon']);
      expect(controller.services.single.title, 'Aircon Cleaning');
      expect(controller.providers.single.user.fullName, 'Juan Aircon');
      expect(controller.hasSearched, isTrue);
      expect(controller.resultCount, 2);
      expect(controller.recentSearches, ['aircon']);
      controller.dispose();
    });

    test('suggestions come from categories and matched results', () async {
      final controller = DiscoveryController(service: _FakeServiceService());
      await controller.initialize();
      await controller.submit('plumb');

      // "Plumbing" is an enabled category; the matched result names follow.
      expect(controller.suggestions, contains('Plumbing'));
      expect(controller.suggestions.length, lessThanOrEqualTo(6));
      controller.dispose();
    });

    test('typing is debounced and clearing the query drops the results', () async {
      final fake = _FakeServiceService();
      final controller = DiscoveryController(
        service: fake,
        debounce: const Duration(milliseconds: 5),
      );

      controller.onQueryChanged('a');
      controller.onQueryChanged('ai');
      controller.onQueryChanged('aircon');
      await Future<void>.delayed(const Duration(milliseconds: 40));

      expect(fake.serviceSearches, ['aircon'], reason: 'only the settled term is sent');
      expect(controller.hasResults, isTrue);
      // A keystroke search is not remembered; only a submitted one is.
      expect(controller.recentSearches, isEmpty);

      controller.onQueryChanged('');
      expect(controller.hasResults, isFalse);
      expect(controller.hasSearched, isFalse);
      controller.dispose();
    });

    test('signing out forgets the search history and the active query', () async {
      final controller = DiscoveryController(service: _FakeServiceService());

      await controller.onAuthChanged(signedIn: true);
      await controller.submit('aircon');
      expect(controller.recentSearches, ['aircon']);

      await controller.onAuthChanged(signedIn: false);

      expect(controller.recentSearches, isEmpty);
      expect(await RecentSearchesService().read(), isEmpty);
      expect(controller.query, isEmpty);
      expect(controller.hasResults, isFalse);
      controller.dispose();
    });

    test('a failed search surfaces an error instead of stale results', () async {
      final fake = _FakeServiceService()..failing = true;
      final controller = DiscoveryController(service: fake);

      await controller.submit('aircon');

      expect(controller.error, isNotNull);
      expect(controller.hasResults, isFalse);

      fake.failing = false;
      await controller.retry();

      expect(controller.error, isNull);
      expect(controller.hasResults, isTrue);
      controller.dispose();
    });
  });
}

class _FakeServiceService extends ServiceService {
  bool failing = false;

  final List<String?> serviceSearches = [];
  final List<String?> providerSearches = [];

  @override
  Future<List<CategoryModel>> getCategories() async => [
        CategoryModel.fromJson({'id': 1, 'name': 'Plumbing'}),
        CategoryModel.fromJson({'id': 2, 'name': 'Tutoring'}),
      ];

  int highlightLoads = 0;

  @override
  Future<List<ProviderModel>> getFeaturedProviders({int limit = 10}) async {
    highlightLoads++;
    return [_provider(1, 'Featured Co.')];
  }

  @override
  Future<List<ProviderModel>> getTopRatedProviders({int limit = 10, double minRating = 4}) async =>
      [_provider(2, 'Top Rated Co.')];

  @override
  Future<List<ServiceModel>> getServices({
    String? search,
    DiscoveryFilters filters = const DiscoveryFilters(),
    int perPage = ServiceService.discoveryPageSize,
  }) async {
    serviceSearches.add(search);
    if (failing) throw Exception('offline');
    return [
      ServiceModel.fromJson({
        'id': 21,
        'title': 'Aircon Cleaning',
        'price': '1500.00',
        'provider': {'id': 9, 'business_name': 'Juan Aircon'},
      }),
    ];
  }

  @override
  Future<List<ProviderModel>> getProviders({
    String? search,
    DiscoveryFilters filters = const DiscoveryFilters(),
    int perPage = ServiceService.discoveryPageSize,
  }) async {
    providerSearches.add(search);
    if (failing) throw Exception('offline');
    return [_provider(9, 'Juan Aircon')];
  }

  ProviderModel _provider(int id, String name) => ProviderModel.fromJson({
        'id': id,
        'business_name': name,
        'average_rating': '4.80',
      });
}
