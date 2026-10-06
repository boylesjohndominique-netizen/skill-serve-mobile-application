import 'package:flutter_test/flutter_test.dart';
import 'package:skilllink_mobile/features/reports/models/report_model.dart';
import 'package:skilllink_mobile/features/support/models/support_ticket_model.dart';

Map<String, dynamic> reportPayload([Map<String, dynamic> overrides = const {}]) => {
      'id': 8,
      'reason': 'no_show',
      'description': 'Booking BK-ABC123: The provider never arrived.',
      'status': 'pending',
      'reported': {'name': 'Juan Aircon Services'},
      'outcome': null,
      'resolved_at': null,
      'rejected_at': null,
      'created_at': '2026-10-01T09:00:00+08:00',
      ...overrides,
    };

Map<String, dynamic> disputePayload([Map<String, dynamic> overrides = const {}]) => {
      'booking_id': 42,
      'booking_number': 'BK-ABC123',
      'booking_status': 'disputed',
      'service_title': 'Aircon Cleaning',
      'provider_name': 'Juan Aircon Services',
      'reason': 'The unit still leaks after the visit.',
      'dispute_status': 'pending',
      'resolution': null,
      'disputed_at': '2026-10-02T10:00:00+08:00',
      'closed_at': null,
      ...overrides,
    };

Map<String, dynamic> ticketPayload([Map<String, dynamic> overrides = const {}]) => {
      'id': 3,
      'ticket_number': 'SUP-XYZ789',
      'subject': 'I was charged twice',
      'description': 'My booking shows two charges.',
      'category': 'payment',
      'priority': 'normal',
      'status': 'open',
      'resolution_note': null,
      'messages': [
        {
          'id': 11,
          'body': 'Thanks for reporting — we are looking into it.',
          'author': {'id': 99, 'name': 'Support Team'},
          'created_at': '2026-10-01T12:00:00+08:00',
        },
      ],
      'created_at': '2026-10-01T11:00:00+08:00',
      'updated_at': '2026-10-01T12:00:00+08:00',
      ...overrides,
    };

void main() {
  group('ReportModel', () {
    test('parses a report payload', () {
      final report = ReportModel.fromJson(reportPayload());

      expect(report.id, '8');
      expect(report.reason, 'no_show');
      expect(report.reasonLabel, 'Provider didn\'t show up');
      expect(report.reportedName, 'Juan Aircon Services');
      expect(report.status, ReportStatus.pending);
      expect(report.isOpen, isTrue);
      // Nothing decided yet, so there is nothing to tell the reporter.
      expect(report.outcome, isNull);
      expect(report.decidedAt, isNull);
    });

    test('a resolved report carries the outcome and the decision date', () {
      final report = ReportModel.fromJson(reportPayload({
        'status': 'resolved',
        'outcome': 'We spoke with the provider.',
        'resolved_at': '2026-10-03T09:00:00+08:00',
      }));

      expect(report.status, ReportStatus.resolved);
      expect(report.isOpen, isFalse);
      expect(report.outcome, 'We spoke with the provider.');
      expect(report.decidedAt, isNotNull);
    });

    test('a rejected report is closed too', () {
      final report = ReportModel.fromJson(reportPayload({
        'status': 'rejected',
        'outcome': 'No breach found.',
        'rejected_at': '2026-10-03T09:00:00+08:00',
      }));

      expect(report.status, ReportStatus.rejected);
      expect(report.isOpen, isFalse);
      expect(report.decidedAt, isNotNull);
    });

    test('a reported service names who offers it and shows its title', () {
      final report = ReportModel.fromJson(reportPayload({
        'subject_type': 'service',
        'reported': {'name': 'Juan Aircon Services', 'excerpt': 'Aircon cleaning'},
      }));

      expect(report.subjectType, 'service');
      expect(report.subjectLabel, 'Service by Juan Aircon Services');
      expect(report.excerpt, 'Aircon cleaning');
      // Every reason offered for a listing is one the API accepts.
      expect(ReportReason.forServices.every(ReportReason.values.contains), isTrue);
    });

    test('an unknown status reads as pending instead of throwing', () {
      expect(ReportModel.statusFromApi('archived'), ReportStatus.pending);
      expect(ReportModel.statusFromApi(null), ReportStatus.pending);
    });

    test('every reason the form offers is an API enum value', () {
      expect(
        ReportReason.values.map((r) => r.value),
        [
          'service_quality',
          'no_show',
          'safety_concern',
          'payment_dispute',
          'misleading_information',
          'harassment',
          'inappropriate_content',
          'spam',
          'other',
        ],
      );
      for (final reason in ReportReason.values) {
        expect(ReportReason.fromValue(reason.value), reason);
        expect(ReportReason.labelFor(reason.value), reason.label);
      }
    });

    test('a reason this build does not know still reads as words', () {
      // An older app must never show a raw enum key to the user.
      expect(ReportReason.labelFor('spam_listing'), 'Spam listing');
      expect(ReportReason.labelFor(null), 'Other');
    });
  });

  group('DisputeModel', () {
    test('parses a dispute payload', () {
      final dispute = DisputeModel.fromJson(disputePayload());

      expect(dispute.bookingId, '42');
      expect(dispute.bookingNumber, 'BK-ABC123');
      expect(dispute.serviceTitle, 'Aircon Cleaning');
      expect(dispute.providerName, 'Juan Aircon Services');
      expect(dispute.disputeStatus, 'pending');
      expect(dispute.isOpen, isTrue);
      expect(dispute.resolution, isNull);
    });

    test('a case under investigation is still open; a decided one is not', () {
      expect(
        DisputeModel.fromJson(disputePayload({'dispute_status': 'investigated'})).isOpen,
        isTrue,
      );
      for (final status in ['resolved', 'rejected', 'closed']) {
        expect(
          DisputeModel.fromJson(disputePayload({'dispute_status': status})).isOpen,
          isFalse,
          reason: '$status should not read as open',
        );
      }
    });

    test('a resolved dispute carries what support decided', () {
      final dispute = DisputeModel.fromJson(disputePayload({
        'dispute_status': 'resolved',
        'resolution': 'Refund arranged with the provider.',
        'closed_at': '2026-10-05T09:00:00+08:00',
      }));

      expect(dispute.resolution, 'Refund arranged with the provider.');
      expect(dispute.closedAt, isNotNull);
    });
  });

  group('SupportTicketModel', () {
    test('parses a ticket and its thread', () {
      final ticket = SupportTicketModel.fromJson(ticketPayload());

      expect(ticket.id, '3');
      expect(ticket.ticketNumber, 'SUP-XYZ789');
      expect(ticket.subject, 'I was charged twice');
      expect(ticket.category, 'payment');
      expect(ticket.categoryLabel, 'Payments');
      expect(ticket.status, TicketStatus.open);
      expect(ticket.isOpen, isTrue);
      expect(ticket.replies, hasLength(1));
      expect(ticket.replies.first.body, 'Thanks for reporting — we are looking into it.');
      expect(ticket.replies.first.authorName, 'Support Team');
      expect(ticket.replies.first.authorId, '99');
    });

    test('in_progress maps to the app\'s inProgress and back', () {
      final ticket = SupportTicketModel.fromJson(ticketPayload({'status': 'in_progress'}));

      expect(ticket.status, TicketStatus.inProgress);
      expect(ticket.isOpen, isTrue);
      expect(SupportTicketModel.statusToApi(TicketStatus.inProgress), 'in_progress');
      expect(SupportTicketModel.statusToApi(TicketStatus.open), 'open');
      expect(SupportTicketModel.statusToApi(TicketStatus.resolved), 'resolved');
    });

    test('a resolved ticket is closed to replies and shows its resolution', () {
      final ticket = SupportTicketModel.fromJson(ticketPayload({
        'status': 'resolved',
        'resolution_note': 'Duplicate charge reversed.',
      }));

      expect(ticket.status, TicketStatus.resolved);
      expect(ticket.isOpen, isFalse);
      expect(ticket.resolutionNote, 'Duplicate charge reversed.');
    });

    test('a list row without a thread parses as an empty conversation', () {
      final ticket = SupportTicketModel.fromJson(ticketPayload({'messages': null}));

      expect(ticket.replies, isEmpty);
      expect(ticket.subject, 'I was charged twice');
    });

    test('an unknown status reads as open instead of throwing', () {
      expect(SupportTicketModel.statusFromApi('escalated'), TicketStatus.open);
      expect(SupportTicketModel.statusFromApi(null), TicketStatus.open);
    });

    test('an unknown category still reads as something', () {
      expect(TicketCategory.labelFor('verification'), 'verification');
      expect(TicketCategory.labelFor(null), 'General question');
      for (final category in TicketCategory.values) {
        expect(TicketCategory.labelFor(category.value), category.label);
      }
    });
  });
}
