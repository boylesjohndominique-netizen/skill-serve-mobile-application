import 'package:flutter_test/flutter_test.dart';
import 'package:skilllink_mobile/features/booking/models/booking_model.dart';
import 'package:skilllink_mobile/features/booking/views/schedule_picker.dart';
import 'package:skilllink_mobile/features/marketplace/models/service_model.dart';
import 'package:skilllink_mobile/features/provider/models/provider_availability_model.dart';

/// A `ClientBooking` payload as `GET /api/client/v1/bookings` returns it.
Map<String, dynamic> clientPayload([Map<String, dynamic> overrides = const {}]) => {
      'id': 42,
      'booking_number': 'BK-ABC123',
      'status': 'confirmed',
      'payment_status': 'unpaid',
      'service_price': '1500.00',
      'total_price': '1500.00',
      'currency': 'PHP',
      'payment_method': 'gcash',
      'client_notes': 'Second floor unit.',
      'service_address': '12 Mabini St, Quezon City',
      'contact_phone': '09171234567',
      'cancellation_reason': null,
      'scheduled_date': '2026-10-01T09:00:00+08:00',
      'scheduled_end_date': '2026-10-01T11:00:00+08:00',
      'confirmed_at': '2026-09-25T10:30:00+08:00',
      'started_at': null,
      'completed_at': null,
      'cancelled_at': null,
      'is_reviewed': false,
      'service': {
        'id': 7,
        'title': 'Aircon Cleaning',
        'duration': '2 hours',
        'price': '1500.00',
        'provider': {'id': 3, 'business_name': 'Juan Aircon Services'},
      },
      'provider': {'id': 3, 'business_name': 'Juan Aircon Services'},
      'created_at': '2026-09-24T08:00:00+08:00',
      ...overrides,
    };

void main() {
  group('BookingModel.fromJson', () {
    test('parses a client booking payload', () {
      final booking = BookingModel.fromJson(clientPayload());

      expect(booking.id, '42');
      expect(booking.bookingNumber, 'BK-ABC123');
      expect(booking.status, BookingStatus.confirmed);
      // Laravel serializes decimal casts as strings.
      expect(booking.amount, 1500);
      expect(booking.currency, 'PHP');
      expect(booking.serviceId, '7');
      expect(booking.serviceTitle, 'Aircon Cleaning');
      expect(booking.providerId, '3');
      expect(booking.providerName, 'Juan Aircon Services');
      expect(booking.address, '12 Mabini St, Quezon City');
      expect(booking.notes, 'Second floor unit.');
      expect(booking.paymentMethod, 'GCash');
      expect(booking.isCancellable, isTrue);
      expect(booking.canBeReviewed, isFalse);
    });

    test('parses a provider booking payload, customer contact included', () {
      final booking = BookingModel.fromJson(clientPayload({
        'provider': null,
        'client': {
          'id': 11,
          'name': 'Maria Santos',
          'phone': '09171234567',
          'profile_picture': 'https://example.test/avatar.png',
        },
      }));

      expect(booking.clientId, '11');
      expect(booking.clientName, 'Maria Santos');
      expect(booking.clientPhone, '09171234567');
      expect(booking.clientAvatar, 'https://example.test/avatar.png');
      // The provider is still resolved, from the nested service.
      expect(booking.providerId, '3');
      expect(booking.providerName, 'Juan Aircon Services');
    });

    test('the API "active" status is the app\'s inProgress', () {
      expect(BookingModel.statusFromApi('active'), BookingStatus.inProgress);
      expect(BookingModel.statusToApi(BookingStatus.inProgress), 'active');

      for (final status in ['pending', 'confirmed', 'completed', 'cancelled', 'disputed']) {
        expect(BookingModel.statusToApi(BookingModel.statusFromApi(status)), status);
      }
    });

    test('an unknown status reads as pending instead of throwing', () {
      expect(BookingModel.statusFromApi('archived'), BookingStatus.pending);
      expect(BookingModel.statusFromApi(null), BookingStatus.pending);
    });

    test('a completed, unreviewed booking can be reviewed exactly once', () {
      final completed = BookingModel.fromJson(clientPayload({
        'status': 'completed',
        'completed_at': '2026-10-01T11:05:00+08:00',
        'is_reviewed': false,
      }));
      final reviewed = BookingModel.fromJson(clientPayload({
        'status': 'completed',
        'completed_at': '2026-10-01T11:05:00+08:00',
        'is_reviewed': true,
      }));

      expect(completed.canBeReviewed, isTrue);
      expect(reviewed.canBeReviewed, isFalse);
      expect(completed.isCancellable, isFalse);
    });

    test('the schedule reads as the booked window', () {
      final booking = BookingModel.fromJson(clientPayload());
      expect(booking.schedule, contains('–'));

      final openEnded = BookingModel.fromJson(clientPayload({'scheduled_end_date': null}));
      expect(openEnded.schedule, isNot(contains('–')));
    });

    test('the timeline follows the timestamps the API records', () {
      final pending = BookingModel.fromJson(clientPayload({
        'status': 'pending',
        'confirmed_at': null,
      }));
      expect(pending.timeline.map((e) => e.label), ['Requested']);

      final finished = BookingModel.fromJson(clientPayload({
        'status': 'completed',
        'started_at': '2026-10-01T09:05:00+08:00',
        'completed_at': '2026-10-01T11:05:00+08:00',
      }));
      expect(
        finished.timeline.map((e) => e.label),
        ['Requested', 'Accepted', 'Job started', 'Completed'],
      );

      final declined = BookingModel.fromJson(clientPayload({
        'status': 'cancelled',
        'confirmed_at': null,
        'cancelled_at': '2026-09-26T09:00:00+08:00',
        'cancellation_reason': 'Fully booked that day.',
      }));
      expect(declined.timeline.last.label, 'Cancelled');
      expect(declined.cancellationReason, 'Fully booked that day.');
    });

    test('a payload missing its optional blocks still parses', () {
      final booking = BookingModel.fromJson({
        'id': 9,
        'status': 'pending',
        'created_at': '2026-09-24T08:00:00+08:00',
      });

      expect(booking.id, '9');
      expect(booking.serviceTitle, '');
      expect(booking.providerName, '');
      expect(booking.amount, 0);
      expect(booking.address, '');
      expect(booking.paymentMethod, 'Not selected');
    });
  });

  group('payment methods', () {
    test('every offered method is an API enum value with a label', () {
      expect(
        BookingModel.paymentMethods.map((m) => m.$1),
        ['cash', 'gcash', 'credit_card', 'debit_card', 'bank_transfer', 'paypal'],
      );
      for (final method in BookingModel.paymentMethods) {
        expect(BookingModel.paymentMethodLabel(method.$1), method.$2);
      }
    });
  });

  group('ServiceModel.durationMinutes', () {
    ServiceModel service(String duration) => ServiceModel.fromJson({
          'id': 1,
          'title': 'x',
          'price': 100,
          'duration': duration,
          'category_id': 1,
        });

    test('mirrors the backend parse of the free-text duration', () {
      expect(service('2 hours').durationMinutes, 120);
      expect(service('90 minutes').durationMinutes, 90);
      expect(service('1 day').durationMinutes, 1440);
      expect(service('1.5 hours').durationMinutes, 90);
    });

    test('falls back to one hour when nothing parses', () {
      expect(service('').durationMinutes, 60);
      expect(service('varies').durationMinutes, 60);
    });
  });

  group('rescheduling', () {
    test('a moved request carries its reschedule stamp and timeline entry', () {
      final booking = BookingModel.fromJson(clientPayload({
        'status': 'pending',
        'confirmed_at': null,
        'rescheduled_at': '2026-09-26T09:00:00+08:00',
      }));

      expect(booking.rescheduledAt, isNotNull);
      expect(booking.isRescheduledRequest, isTrue);
      expect(booking.isReschedulable, isTrue);
      expect(booking.timeline.map((e) => e.label), ['Requested', 'Rescheduled']);
      expect(booking.length, const Duration(hours: 2));
    });

    test('only pending or confirmed bookings can be moved', () {
      expect(BookingModel.fromJson(clientPayload({'status': 'confirmed'})).isReschedulable, isTrue);
      for (final status in ['active', 'completed', 'cancelled', 'disputed']) {
        expect(BookingModel.fromJson(clientPayload({'status': status})).isReschedulable, isFalse,
            reason: status);
      }
      // Never moved: no reschedule marker even while pending.
      expect(BookingModel.fromJson(clientPayload({'status': 'pending'})).isRescheduledRequest, isFalse);
    });
  });

  group('BookingSlots', () {
    // 2026-10-05 is a Monday (day_of_week 1).
    final monday = DateTime(2026, 10, 5);
    const hours = [ProviderAvailabilityModel(dayOfWeek: 1, startTime: '09:00', endTime: '12:00')];

    test('offers half-hour starts that fit the whole booking in the window', () {
      expect(BookingSlots.options(hours, monday, 120), [9 * 60, 9 * 60 + 30, 10 * 60]);
    });

    test('offers nothing on a day the provider does not work', () {
      expect(BookingSlots.closedOn(hours, monday.add(const Duration(days: 1))), isTrue);
      expect(BookingSlots.options(hours, monday.add(const Duration(days: 1)), 60), isEmpty);
    });

    test('falls back to the open working day without published hours', () {
      final slots = BookingSlots.options(const [], monday, 60);
      expect(slots.first, BookingSlots.openDayStartMinutes);
      expect(slots.last, BookingSlots.openDayEndMinutes - 60);
    });

    test('turns a slot into a wall-clock start and a label', () {
      expect(BookingSlots.at(monday, 14 * 60 + 30), DateTime(2026, 10, 5, 14, 30));
      expect(BookingSlots.label(14 * 60 + 30), '2:30 PM');
      expect(BookingSlots.label(0), '12:00 AM');
    });
  });

  group('payment settlement', () {
    test('a recorded payment and refund come through from the API', () {
      final booking = BookingModel.fromJson(clientPayload({
        'status': 'completed',
        'payment_status': 'partially_refunded',
        'paid_at': '2026-10-01T12:00:00+08:00',
        'refunded_amount': '500.00',
        'refund_reason': 'Finished early.',
      }));

      expect(booking.paidAt, isNotNull);
      expect(booking.refundedAmount, 500);
      expect(booking.refundReason, 'Finished early.');
      expect(booking.paymentLabel, 'Partly refunded');
      expect(booking.isUnpaid, isFalse);
      expect(booking.canRecordPayment, isFalse);
      expect(booking.timeline.map((e) => e.label), contains('Payment recorded'));
    });

    test('only a completed, unpaid job can be confirmed as paid by the provider', () {
      expect(BookingModel.fromJson(clientPayload({'status': 'completed', 'payment_status': 'unpaid'})).canRecordPayment, isTrue);
      expect(BookingModel.fromJson(clientPayload({'status': 'active', 'payment_status': 'unpaid'})).canRecordPayment, isFalse);
      expect(BookingModel.fromJson(clientPayload({'status': 'completed', 'payment_status': 'paid'})).canRecordPayment, isFalse);
    });
  });

  group('schedule times sent to the API', () {
    test('carry their instant in UTC, so the server cannot misread the zone', () {
      final local = DateTime(2026, 10, 5, 9, 0);
      final sent = BookingModel.apiDateTime(local);

      expect(sent.endsWith('Z'), isTrue);
      expect(DateTime.parse(sent).isAtSameMomentAs(local), isTrue);
    });

    test('a time returned by the API reads back as the local time that was picked', () {
      final local = DateTime(2026, 10, 5, 9, 0);
      final booking = BookingModel.fromJson(clientPayload({
        'scheduled_date': BookingModel.apiDateTime(local).replaceFirst('Z', '+00:00'),
      }));

      expect(booking.bookingDate, local);
    });
  });

  group('cancellation rules', () {
    test('a late cancellation policy and a recorded fee come through', () {
      final booking = BookingModel.fromJson(clientPayload({
        'cancellation_fee': null,
        'cancellation_policy': {'window_hours': 24, 'fee_percent': 10, 'is_late': true, 'fee_if_cancelled_now': '150.00'},
      }));
      expect(booking.cancellationPolicy!.chargesFee, isTrue);
      expect(booking.cancellationPolicy!.feeIfCancelledNow, 150);

      final cancelled = BookingModel.fromJson(clientPayload({'status': 'cancelled', 'cancellation_fee': '150.00'}));
      expect(cancelled.cancellationFee, 150);
      expect(cancelled.cancellationPolicy, isNull);
    });

    test('an early cancellation carries no fee', () {
      final booking = BookingModel.fromJson(clientPayload({
        'cancellation_policy': {'window_hours': 24, 'fee_percent': 10, 'is_late': false, 'fee_if_cancelled_now': '0.00'},
      }));
      expect(booking.cancellationPolicy!.chargesFee, isFalse);
    });
  });
}
