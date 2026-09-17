import 'package:flutter_test/flutter_test.dart';
import 'package:skilllink_mobile/features/marketplace/models/category_model.dart';
import 'package:skilllink_mobile/features/marketplace/models/provider_model.dart';
import 'package:skilllink_mobile/features/marketplace/models/service_model.dart';
import 'package:skilllink_mobile/features/notifications/controllers/notification_controller.dart';
import 'package:skilllink_mobile/features/notifications/models/notification_model.dart';
import 'package:skilllink_mobile/features/notifications/services/notification_service.dart';
import 'package:skilllink_mobile/features/reviews/models/review_model.dart';

/// Payload shapes below mirror api-docs/openapi.json (ClientCategory,
/// ClientService, ClientProvider, ClientReview).
void main() {
  test('category parses id, name, provider count and derives an icon', () {
    final category = CategoryModel.fromJson({
      'id': 4,
      'name': 'Plumbing Services',
      'description': null,
      'provider_count': 3,
      'subcategories': [],
    });

    expect(category.id, '4');
    expect(category.name, 'Plumbing Services');
    expect(category.providerCount, 3);
    expect(category.icon, 'plumbing');
    expect(CategoryModel.iconKeyFor('Something Else'), 'work');
  });

  test('service parses nested provider/category and decimal-string price', () {
    final service = ServiceModel.fromJson({
      'id': 21,
      'title': 'Aircon Cleaning',
      'description': 'Split-type units',
      'price': '1500.00',
      'price_type': 'fixed',
      'currency': 'PHP',
      'duration': '2 hours',
      'location': 'Quezon City',
      'category': {'id': 2, 'name': 'Appliance Repair'},
      'provider': {'id': 9, 'business_name': 'Juan Aircon'},
    });

    expect(service.id, '21');
    expect(service.providerId, '9');
    expect(service.categoryId, '2');
    expect(service.categoryName, 'Appliance Repair');
    expect(service.price, 1500);
    expect(service.coverImage, isEmpty);
  });

  test('provider list item parses without a user object', () {
    final provider = ProviderModel.fromJson({
      'id': 9,
      'business_name': 'Juan Aircon Services',
      'bio': null,
      'specialization': 'Aircon repair',
      'experience_years': 6,
      'average_rating': '4.50',
      'total_reviews': 12,
      'completed_bookings': 40,
      'starting_price': '900.00',
      'primary_category': 'Appliance Repair',
      'portfolio': ['https://example.com/a.jpg', {'url': 'https://example.com/b.jpg'}, 'not-a-url'],
    });

    expect(provider.id, '9');
    expect(provider.user.fullName, 'Juan Aircon Services');
    expect(provider.isVerified, isTrue);
    expect(provider.bio, 'Aircon repair');
    expect(provider.yearsExperience, 6);
    expect(provider.averageRating, 4.5);
    expect(provider.reviewCount, 12);
    expect(provider.completedJobs, 40);
    expect(provider.startingPrice, 900);
    expect(provider.categoryName, 'Appliance Repair');
    expect(provider.portfolioImages, ['https://example.com/a.jpg', 'https://example.com/b.jpg']);
  });

  test('provider detail carries its services (owned) and published reviews', () {
    final provider = ProviderModel.fromJson({
      'id': 9,
      'business_name': 'Juan Aircon Services',
      'average_rating': '5.00',
      'total_reviews': 1,
      'completed_bookings': 1,
      'services': [
        {'id': 1, 'title': 'Deep clean', 'price': '1200.00', 'category': {'id': 2, 'name': 'Appliance Repair'}},
        {'id': 2, 'title': 'Check-up', 'price': '500.00', 'category': {'id': 2, 'name': 'Appliance Repair'}},
      ],
      'reviews': [
        {
          'id': 5,
          'rating': 5,
          'comment': 'Great work',
          'status': 'active',
          'reviewer': {'id': 3, 'name': 'Maria'},
          'created_at': '2026-09-01T10:00:00+00:00',
        },
      ],
    });

    expect(provider.services.map((s) => s.providerId), everyElement('9'));
    expect(provider.startingPrice, 500);
    expect(provider.categoryName, 'Appliance Repair');
    expect(provider.reviews.single.clientName, 'Maria');
    expect(provider.reviews.single.rating, 5);
  });

  test('review parses the client API shape', () {
    final review = ReviewModel.fromJson({
      'id': 5,
      'rating': 4,
      'comment': 'Good',
      'booking': {'id': 77, 'booking_number': 'BK-1'},
      'reviewer': {'id': 3, 'name': 'Maria'},
      'created_at': '2026-09-01T10:00:00+00:00',
    });

    expect(review.id, '5');
    expect(review.bookingId, '77');
    expect(review.comment, 'Good');
  });

  group('notification polling', () {
    test('first check sets a baseline; a higher unread count surfaces the newest', () async {
      final service = _FakeNotificationService(unread: 2);
      final controller = NotificationController(service: service);

      await controller.checkForNew();
      expect(controller.unreadCount, 2);
      expect(controller.incoming, isNull);

      service.unread = 3;
      service.feed = [
        _notification('n3', 'Service approved', read: false),
        _notification('n2', 'Older', read: false),
      ];
      await controller.checkForNew();

      expect(controller.unreadCount, 3);
      expect(controller.incoming?.id, 'n3');
      expect(controller.notifications, hasLength(2));

      controller.clearIncoming();
      await controller.checkForNew();
      expect(controller.incoming, isNull);
      controller.dispose();
    });

    test('a pushed notification surfaces immediately even on the first check', () async {
      final service = _FakeNotificationService(unread: 1)
        ..feed = [_notification('n9', 'Service rejected', read: false)];
      final controller = NotificationController(service: service);

      await controller.onRealtimeNotification();

      expect(controller.incoming?.id, 'n9');
      expect(controller.unreadCount, 1);
      controller.dispose();
    });

    test('periodic checks are skipped while realtime is connected', () async {
      final service = _FakeNotificationService(unread: 0);
      final controller = NotificationController(service: service)..realtimeConnected = true;

      controller.startPolling();
      await Future<void>.delayed(Duration.zero);
      final callsAfterStart = service.countCalls;
      controller.stopPolling();

      expect(callsAfterStart, 1, reason: 'only the immediate catch-up check runs');
      controller.dispose();
    });

    test('reset clears state and stops polling', () async {
      final controller = NotificationController(service: _FakeNotificationService(unread: 1));
      controller.startPolling();
      expect(controller.isPolling, isTrue);

      controller.reset();

      expect(controller.isPolling, isFalse);
      expect(controller.unreadCount, 0);
      controller.dispose();
    });
  });
}

NotificationModel _notification(String id, String title, {required bool read}) => NotificationModel(
      id: id,
      title: title,
      message: '',
      type: NotificationType.service,
      createdAt: DateTime(2026, 9, 17),
      isRead: read,
    );

class _FakeNotificationService extends NotificationService {
  _FakeNotificationService({required this.unread});

  int unread;
  List<NotificationModel> feed = [];

  int countCalls = 0;

  @override
  Future<int> unreadCount() async {
    countCalls++;
    return unread;
  }

  @override
  Future<List<NotificationModel>> getNotifications() async => feed;
}
