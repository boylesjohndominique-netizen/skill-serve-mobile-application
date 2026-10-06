import 'package:flutter_test/flutter_test.dart';
import 'package:skillserve_mobile/features/notifications/models/notification_model.dart';
import 'package:skillserve_mobile/features/reviews/models/review_model.dart';

Map<String, dynamic> notificationPayload([Map<String, dynamic> overrides = const {}]) => {
      'id': 'a1b2c3',
      'type': 'booking_status',
      'title': 'Booking accepted',
      'message': 'Your provider accepted your booking.',
      'data': {'type': 'booking_status', 'booking_id': 42},
      'read_at': null,
      'created_at': '2026-10-01T09:00:00+08:00',
      ...overrides,
    };

Map<String, dynamic> reviewPayload([Map<String, dynamic> overrides = const {}]) => {
      'id': 5,
      'rating': 4,
      'comment': 'Prompt and tidy work.',
      'status': 'active',
      'booking': {'id': 42, 'booking_number': 'BK-ABC123'},
      'reviewer': {'id': 11, 'name': 'Maria Santos'},
      'provider': {'id': 3, 'business_name': 'Juan Aircon Services'},
      'service': {'id': 7, 'title': 'Aircon Cleaning'},
      'created_at': '2026-10-01T09:00:00+08:00',
      'updated_at': '2026-10-01T09:00:00+08:00',
      ...overrides,
    };

void main() {
  group('NotificationModel', () {
    test('parses a notification and keeps its payload', () {
      final notification = NotificationModel.fromJson(notificationPayload());

      expect(notification.id, 'a1b2c3');
      expect(notification.title, 'Booking accepted');
      expect(notification.type, NotificationType.booking);
      expect(notification.isRead, isFalse);
      // The payload has to survive, or a tap has nowhere to go.
      expect(notification.data['booking_id'], 42);
    });

    test('read state comes from read_at', () {
      expect(
        NotificationModel.fromJson(
                notificationPayload({'read_at': '2026-10-01T10:00:00+08:00'}))
            .isRead,
        isTrue,
      );
    });

    test('backend types map onto the feed categories', () {
      expect(NotificationModel.typeFromApi('booking_status'), NotificationType.booking);
      // A chat message about a booking belongs with Messages, not Bookings.
      expect(NotificationModel.typeFromApi('booking_message'), NotificationType.message);
      expect(NotificationModel.typeFromApi('service_moderation'), NotificationType.service);
      expect(NotificationModel.typeFromApi('support_ticket_response'), NotificationType.message);
      expect(NotificationModel.typeFromApi('announcement'), NotificationType.announcement);
      expect(NotificationModel.typeFromApi('provider_verification'), NotificationType.verification);
      // Anything unrecognised is shown rather than dropped.
      expect(NotificationModel.typeFromApi('something_new'), NotificationType.system);
      expect(NotificationModel.typeFromApi(null), NotificationType.system);
    });

    group('destination', () {
      test('a booking notification opens the booking', () {
        expect(NotificationModel.fromJson(notificationPayload()).destination,
            '/booking-details/42');
      });

      test('a message notification opens the conversation, not the booking', () {
        final notification = NotificationModel.fromJson(notificationPayload({
          'type': 'booking_message',
          'data': {'type': 'booking_message', 'booking_id': 42},
        }));

        expect(notification.type, NotificationType.message);
        expect(notification.destination, '/chat-conversation/42');
      });

      test('a support reply opens the ticket', () {
        final notification = NotificationModel.fromJson(notificationPayload({
          'type': 'support_ticket_response',
          'data': {'type': 'support_ticket_response', 'ticket_id': 9},
        }));

        expect(notification.destination, '/support/tickets/9');
      });

      test('a service moderation notice opens that service', () {
        final notification = NotificationModel.fromJson(notificationPayload({
          'type': 'service_moderation',
          'data': {'type': 'service_moderation', 'service_id': 7},
        }));

        expect(notification.destination, '/edit-service/7');
      });

      test('a verification decision opens the verification screen', () {
        final notification = NotificationModel.fromJson(notificationPayload({
          'type': 'provider_verification',
          'data': {'type': 'provider_verification', 'action': 'rejected', 'reason': 'Blurry photo.'},
        }));

        expect(notification.type, NotificationType.verification);
        expect(notification.destination, '/verification-status');
      });

      test('a report outcome opens My Reports', () {
        final notification = NotificationModel.fromJson(notificationPayload({
          'type': 'report_update',
          'data': {'type': 'report_update', 'report_id': 12},
        }));

        expect(notification.destination, '/my-reports');
      });

      test('a dispute update is a booking notice that opens the booking', () {
        final notification = NotificationModel.fromJson(notificationPayload({
          'type': 'dispute_update',
          'data': {'type': 'dispute_update', 'booking_id': 42},
        }));

        expect(notification.type, NotificationType.booking);
        expect(notification.destination, '/booking-details/42');
      });

      test('an announcement has nowhere to go, and says so', () {
        final notification = NotificationModel.fromJson(notificationPayload({
          'type': 'announcement',
          'data': {'type': 'announcement', 'announcement_id': 2},
        }));

        // Better no destination than a route the app cannot build.
        expect(notification.destination, isNull);
      });

      test('a payload with no ids has no destination', () {
        expect(
          NotificationModel.fromJson(notificationPayload({'data': const {}})).destination,
          isNull,
        );
      });
    });

    test('copyWith flips read state and keeps the payload', () {
      final read = NotificationModel.fromJson(notificationPayload()).copyWith(isRead: true);

      expect(read.isRead, isTrue);
      expect(read.data['booking_id'], 42);
      expect(read.title, 'Booking accepted');
    });
  });

  group('ReviewModel', () {
    test('parses a review with what it is about', () {
      final review = ReviewModel.fromJson(reviewPayload());

      expect(review.id, '5');
      expect(review.bookingId, '42');
      expect(review.bookingNumber, 'BK-ABC123');
      expect(review.rating, 4);
      expect(review.comment, 'Prompt and tidy work.');
      expect(review.serviceTitle, 'Aircon Cleaning');
      expect(review.providerName, 'Juan Aircon Services');
      expect(review.clientName, 'Maria Santos');
      expect(review.isPublished, isTrue);
      expect(review.wasEdited, isFalse);
    });

    test('a hidden review is still the author\'s, and is flagged', () {
      final hidden = ReviewModel.fromJson(reviewPayload({'status': 'hidden'}));

      expect(hidden.status, 'hidden');
      expect(hidden.isPublished, isFalse);
    });

    test('an edited review is recognisable', () {
      final edited = ReviewModel.fromJson(reviewPayload({
        'updated_at': '2026-10-02T09:00:00+08:00',
      }));

      expect(edited.wasEdited, isTrue);
    });

    test('a provider-profile review payload still parses', () {
      // Embedded in a provider, a review carries no service or provider block.
      final review = ReviewModel.fromJson({
        'id': 8,
        'rating': 5,
        'comment': 'Excellent.',
        'reviewer': {'id': 12, 'name': 'Ana Cruz'},
        'created_at': '2026-10-01T09:00:00+08:00',
      });

      expect(review.clientName, 'Ana Cruz');
      expect(review.rating, 5);
      expect(review.serviceTitle, '');
      expect(review.providerName, '');
      expect(review.bookingId, '');
    });

    test('a review with no reviewer falls back to a neutral label', () {
      final review = ReviewModel.fromJson({
        'id': 9,
        'rating': 3,
        'created_at': '2026-10-01T09:00:00+08:00',
      });

      expect(review.clientName, 'Customer');
      expect(review.comment, '');
    });
  });
}
