import 'package:flutter_test/flutter_test.dart';
import 'package:skillserve_mobile/core/utils/payment_qr.dart';
import 'package:skillserve_mobile/features/booking/models/booking_model.dart';
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

    test('warns before unpaid commission pauses work, never once it already has', () {
      // Any debt blocks (the default): already blocked, nothing to warn about.
      expect(CommissionSummary.fromJson(summaryPayload()).warnsBeforeBlock, isFalse);

      final upcoming = CommissionSummary.fromJson(summaryPayload({
        'eligible': true,
        'reason': null,
        'block_threshold': '200.00',
        'block_deadline': '2026-10-20T08:00:00+00:00',
      }));
      expect(upcoming.warnsBeforeBlock, isTrue);
      expect(upcoming.hasBlockThreshold, isTrue);
      expect(upcoming.blockDeadline!.isAtSameMomentAs(DateTime.parse('2026-10-20T08:00:00+00:00')), isTrue);

      // Nothing owed, nothing to warn about.
      final clear = CommissionSummary.fromJson(summaryPayload({
        'eligible': true,
        'reason': null,
        'outstanding_count': 0,
        'outstanding': [],
        'block_threshold': '200.00',
      }));
      expect(clear.warnsBeforeBlock, isFalse);

      // An older API without the block fields: no warning, no crash.
      expect(CommissionSummary.fromJson(summaryPayload({'eligible': true, 'reason': null})).warnsBeforeBlock, isFalse);
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

  group('QR payments', () {
    test('the summary says when a QR code can be used instead', () {
      final summary = CommissionSummary.fromJson(summaryPayload({
        'payment_account': {'configured': false, 'qr_payments_available': true},
      }));

      expect(summary.paymentAccount.qrPaymentsAvailable, isTrue);
      expect(summary.paymentAccount.canPay, isTrue);
    });

    test('an open QR payment carries its code and expiry', () {
      final payment = CommissionRemittance.fromJson({
        'id': 9,
        'method': 'qrph',
        'status': 'pending',
        'reference': 'QR-ABCDEF1234',
        'amount_due': '35.00',
        'amount_sent': '35.00',
        'qr_image': 'data:image/png;base64,iVBORw0KGgo=',
        'expires_at': '2026-10-11T09:30:00+00:00',
      });

      expect(payment.isQr, isTrue);
      expect(payment.hasPayableQr, isTrue);
      expect(payment.expiresAt, isNotNull);
      expect(PaymentQr.decodeImage(payment.qrImage!), isNotNull);
    });

    test('an expired or failed QR payment is closed and has no code', () {
      for (final status in ['expired', 'failed']) {
        final payment = CommissionRemittance.fromJson({'id': 9, 'method': 'qrph', 'status': status, 'qr_image': null});
        expect(payment.isClosedUnpaid, isTrue);
        expect(payment.hasPayableQr, isFalse);
      }
    });

    test("a booking carries the provider's QR with the amount", () {
      final instructions = PaymentInstructions.fromJson({
        'method': 'gcash',
        'gcash_number': null,
        'amount': '200.00',
        'reference': 'BK-1',
        'note': 'n',
        'qr_payload': '00020101021227...6304ABCD',
      });

      expect(instructions.hasQr, isTrue);
      // A QR alone is enough to pay, even without a number.
      expect(instructions.isPayable, isTrue);
    });

    test('a decoded image accepts PayMongo\'s data URI or bare base-64', () {
      expect(PaymentQr.decodeImage('data:image/png;base64,iVBORw0KGgo='), isNotNull);
      expect(PaymentQr.decodeImage('iVBORw0KGgo='), isNotNull);
      expect(PaymentQr.decodeImage('not base64 !!'), isNull);
    });

    test('only a QR Ph code is taken for the provider\'s GCash QR', () {
      expect(PaymentQr.looksLikeQrPh('00020101021127...6304ABCD'), isTrue);
      expect(PaymentQr.looksLikeQrPh('https://example.com'), isFalse);
    });
  });
}
