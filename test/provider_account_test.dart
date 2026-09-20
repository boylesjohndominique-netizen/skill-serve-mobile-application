import 'package:flutter_test/flutter_test.dart';

import 'package:skilllink_mobile/features/marketplace/models/provider_model.dart';
import 'package:skilllink_mobile/features/provider/controllers/portfolio_controller.dart';
import 'package:skilllink_mobile/features/provider/models/badge_model.dart';
import 'package:skilllink_mobile/features/provider/models/portfolio_model.dart';
import 'package:skilllink_mobile/features/provider/models/provider_availability_model.dart';
import 'package:skilllink_mobile/features/provider/services/portfolio_service.dart';

/// Stands in for the API so the portfolio controller can be exercised
/// without a server.
class _FakePortfolioService implements PortfolioService {
  List<PortfolioModel> stored;
  bool failLoads;
  bool failWrites;

  _FakePortfolioService({
    this.stored = const [],
    this.failLoads = false,
    this.failWrites = false,
  });

  @override
  Future<List<PortfolioModel>> getMyPortfolio() async {
    if (failLoads) throw Exception('offline');
    return stored;
  }

  @override
  Future<List<PortfolioModel>> getPortfolio(String providerId) async {
    if (failLoads) throw Exception('offline');
    return stored;
  }

  @override
  Future<PortfolioModel> uploadPortfolioItem({
    required String title,
    required String description,
    required String imagePath,
  }) async {
    if (failWrites) throw Exception('offline');
    final created = PortfolioModel(
      id: '${stored.length + 1}',
      providerId: 'PV-1',
      image: 'https://example.test/$title.jpg',
      title: title,
      description: description,
    );
    stored = [created, ...stored];
    return created;
  }

  @override
  Future<void> removePortfolioItem(String id) async {
    if (failWrites) throw Exception('offline');
    stored = [for (final item in stored) if (item.id != id) item];
  }
}

const _item = PortfolioModel(
  id: '1',
  providerId: 'PV-1',
  image: 'https://example.test/a.jpg',
  title: 'Bathroom repipe',
);

void main() {
  group('portfolio', () {
    test('loads the provider\'s own items', () async {
      final controller =
          PortfolioController(service: _FakePortfolioService(stored: [_item]));

      await controller.loadMine();

      expect(controller.items.single.title, 'Bathroom repipe');
      expect(controller.isLoading, isFalse);
      expect(controller.errorMessage, isNull);
    });

    test('a failed load surfaces a retryable message', () async {
      final controller =
          PortfolioController(service: _FakePortfolioService(failLoads: true));

      await controller.loadMine();

      expect(controller.items, isEmpty);
      expect(controller.errorMessage, isNotNull);
    });

    test('an uploaded item lands at the top of the grid', () async {
      final controller =
          PortfolioController(service: _FakePortfolioService(stored: [_item]));
      await controller.loadMine();

      final added = await controller.add(
          title: 'Kitchen sink', description: '', imagePath: '/tmp/a.jpg');

      expect(added, isTrue);
      expect(controller.items.first.title, 'Kitchen sink');
      expect(controller.items, hasLength(2));
    });

    test('a failed upload reports the error and adds nothing', () async {
      final controller = PortfolioController(
          service: _FakePortfolioService(stored: [_item], failWrites: true));
      await controller.loadMine();

      final added = await controller.add(
          title: 'Kitchen sink', description: '', imagePath: '/tmp/a.jpg');

      expect(added, isFalse);
      expect(controller.items, hasLength(1));
      expect(controller.errorMessage, isNotNull);
    });

    test('a refused delete puts the item back', () async {
      final service = _FakePortfolioService(stored: [_item]);
      final controller = PortfolioController(service: service);
      await controller.loadMine();

      service.failWrites = true;
      final removed = await controller.remove('1');

      expect(removed, isFalse);
      expect(controller.items, hasLength(1),
          reason: 'the grid must not claim a deletion that did not happen');
      expect(controller.errorMessage, isNotNull);
    });

    test('a successful delete drops the item', () async {
      final controller =
          PortfolioController(service: _FakePortfolioService(stored: [_item]));
      await controller.loadMine();

      expect(await controller.remove('1'), isTrue);
      expect(controller.items, isEmpty);
    });
  });

  group('badges', () {
    test('an earned badge reads as earned', () {
      final badge = BadgeModel.fromJson(const {
        'key': 'top_rated',
        'title': 'Top Rated',
        'criteria': 'Maintain a 4.8 rating.',
        'earned': true,
      });

      expect(badge.key, 'top_rated');
      expect(badge.earned, isTrue);
      expect(badge.progress, 1);
    });

    test('an unearned badge shows its criteria instead of progress', () {
      final badge = BadgeModel.fromJson(const {
        'key': 'veteran',
        'title': 'Veteran',
        'criteria': 'Two years on SkillServe.',
        'earned': false,
      });

      expect(badge.earned, isFalse);
      expect(badge.progress, 0);
      expect(badge.criteria, 'Two years on SkillServe.');
    });
  });

  group('discovery', () {
    test('a provider profile carries its badges and portfolio images', () {
      final provider = ProviderModel.fromJson(const {
        'id': 7,
        'business_name': 'Dela Cruz Services',
        'specialization': 'Plumbing',
        'is_featured': true,
        'badges': [
          {'key': 'top_rated', 'title': 'Top Rated', 'criteria': '', 'earned': true},
          {'key': 'veteran', 'title': 'Veteran', 'criteria': '', 'earned': false},
        ],
        'portfolio': [
          {
            'portfolio_id': 1,
            'provider_id': 7,
            'title': 'Repipe',
            'image': 'https://example.test/one.jpg',
          },
        ],
      });

      expect(provider.badges, hasLength(2));
      expect(provider.badges.where((b) => b.earned), hasLength(1));
      expect(provider.portfolioImages, ['https://example.test/one.jpg']);
    });

    test('a provider profile carries its published weekly hours', () {
      final provider = ProviderModel.fromJson(const {
        'id': 7,
        'business_name': 'Dela Cruz Services',
        'is_accepting_bookings': true,
        'availability': [
          {'day_of_week': 1, 'day': 'Monday', 'start_time': '09:00', 'end_time': '17:00'},
          {'day_of_week': 6, 'day': 'Saturday', 'start_time': '08:00:00', 'end_time': '12:00:00'},
        ],
      });

      expect(provider.isAcceptingBookings, isTrue);
      expect(provider.availability, hasLength(2));
      expect(provider.availability.first.dayName, 'Monday');
      expect(provider.availability.first.label, '9:00 AM – 5:00 PM');
      // A database round trip can surface HH:mm:ss; the app trims it.
      expect(provider.availability.last.startTime, '08:00');
      expect(provider.availability.last.label, '8:00 AM – 12:00 PM');
    });

    test('a paused provider is marked as not accepting bookings', () {
      final provider = ProviderModel.fromJson(const {
        'id': 9,
        'business_name': 'Paused Co.',
        'is_accepting_bookings': false,
      });

      expect(provider.isAcceptingBookings, isFalse);
      expect(provider.availability, isEmpty);
    });

    test('the provider schedule payload exposes the day it was asked for', () {
      final schedule = ProviderAvailability.fromJson(const {
        'is_accepting_bookings': false,
        'availability': [
          {'day_of_week': 3, 'day': 'Wednesday', 'start_time': '13:00', 'end_time': '18:00'},
        ],
      });

      expect(schedule.isAcceptingBookings, isFalse);
      expect(schedule.windowFor(3)?.endTime, '18:00');
      expect(schedule.windowFor(4), isNull);
      expect(
        const ProviderAvailabilityModel(dayOfWeek: 0, startTime: '00:00', endTime: '23:30').label,
        '12:00 AM – 11:30 PM',
      );
    });

    test('a provider with no badges or portfolio parses cleanly', () {
      final provider = ProviderModel.fromJson(const {
        'id': 8,
        'business_name': 'New Provider',
      });

      expect(provider.badges, isEmpty);
      expect(provider.portfolioImages, isEmpty);
    });
  });
}
