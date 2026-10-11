import 'package:flutter_test/flutter_test.dart';
import 'package:skillserve_mobile/features/provider/controllers/commission_controller.dart';
import 'package:skillserve_mobile/features/provider/models/commission_model.dart';
import 'package:skillserve_mobile/features/provider/services/commission_service.dart';

/// Answers with whatever balance the test sets, counting the calls.
class _FakeCommissionService extends CommissionService {
  Map<String, dynamic> payload = summaryPayload();
  int calls = 0;

  @override
  Future<CommissionSummary> getSummary() async {
    calls++;
    return CommissionSummary.fromJson(payload);
  }
}

Map<String, dynamic> summaryPayload([Map<String, dynamic> overrides = const {}]) => {
      'eligible': false,
      'reason': 'outstanding_commission',
      'outstanding_total': '20.00',
      'outstanding_count': 1,
      'currency': 'PHP',
      'payment_account': {
        'gcash_account_name': 'SkillServe Inc.',
        'gcash_number': '09171234567',
        'payment_instructions': 'Send the exact amount.',
        'configured': true,
      },
      'latest_remittance': null,
      'outstanding': [
        {
          'booking_number': 'BK-AB12CD34EF56',
          'service': 'Aircon Cleaning',
          'total_price': '200.00',
          'commission_rate': '10.00',
          'commission_amount': '20.00',
          'paid_at': '2026-09-24T08:00:00+00:00',
        },
      ],
      ...overrides,
    };

void main() {
  group('CommissionSummary', () {
    test("reads SkillServe's GCash from the summary", () {
      final summary = CommissionSummary.fromJson(summaryPayload());

      expect(summary.paymentAccount.configured, isTrue);
      expect(summary.paymentAccount.gcashNumber, '09171234567');
      expect(summary.paymentAccount.gcashAccountName, 'SkillServe Inc.');
      expect(summary.latestRemittance, isNull);
      expect(summary.hasPendingRemittance, isFalse);
    });

    test('an older API without the payment fields still parses', () {
      final payload = summaryPayload()
        ..remove('payment_account')
        ..remove('latest_remittance');
      final summary = CommissionSummary.fromJson(payload);

      expect(summary.paymentAccount.configured, isFalse);
      expect(summary.latestRemittance, isNull);
    });

    test('a payment waiting for confirmation is pending', () {
      final summary = CommissionSummary.fromJson(summaryPayload({
        'latest_remittance': {
          'id': 7,
          'status': 'pending',
          'reference': '1012345678901',
          'amount_due': '20.00',
          'amount_sent': '20.00',
          'rejection_reason': null,
          'submitted_at': '2026-10-11T08:00:00+00:00',
          'reviewed_at': null,
        },
      }));

      expect(summary.hasPendingRemittance, isTrue);
      expect(summary.latestRemittance!.reference, '1012345678901');
      expect(summary.latestRemittance!.submittedAt, isNotNull);
    });

    test('a rejected payment carries its reason', () {
      final summary = CommissionSummary.fromJson(summaryPayload({
        'latest_remittance': {
          'id': 7,
          'status': 'rejected',
          'reference': '1012345678901',
          'amount_due': '20.00',
          'amount_sent': '20.00',
          'rejection_reason': 'Reference not found.',
        },
      }));

      expect(summary.hasPendingRemittance, isFalse);
      expect(summary.latestRemittance!.isRejected, isTrue);
      expect(summary.latestRemittance!.rejectionReason, 'Reference not found.');
    });
  });

  group('CommissionController', () {
    test('a reload shows the decision on a payment', () async {
      final service = _FakeCommissionService();
      final controller = CommissionController(service: service);
      controller.onAuthChanged(signedIn: true);

      await controller.load();
      expect(controller.summary!.hasOutstanding, isTrue);

      // What the notification poller does once SkillServe confirms it.
      service.payload = summaryPayload({
        'eligible': true,
        'reason': null,
        'outstanding_total': '0.00',
        'outstanding_count': 0,
        'outstanding': [],
        'latest_remittance': {'id': 7, 'status': 'confirmed', 'reference': '1012345678901'},
      });
      await controller.load();

      expect(service.calls, 2);
      expect(controller.summary!.hasOutstanding, isFalse);
      expect(controller.summary!.latestRemittance!.status, 'confirmed');
    });

    test("signing out drops one provider's balance", () async {
      final controller = CommissionController(service: _FakeCommissionService());
      controller.onAuthChanged(signedIn: true);
      await controller.load();

      controller.onAuthChanged(signedIn: false);

      expect(controller.summary, isNull);
    });
  });
}
