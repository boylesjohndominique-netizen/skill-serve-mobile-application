import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:skillserve_mobile/features/identity/controllers/identity_controller.dart';
import 'package:skillserve_mobile/features/identity/models/identity_verification_model.dart';
import 'package:skillserve_mobile/features/identity/services/identity_service.dart';
import 'package:skillserve_mobile/features/provider/models/commission_model.dart';

/// Stands in for the API. The real service is HTTP-only, so the controller is
/// exercised against the payload shapes in
/// api-docs/modules/identity-verification.md and transaction-eligibility.md.
class _FakeIdentityService extends IdentityService {
  IdentityVerification state = IdentityVerification.fromJson(const {
    'status': 'unverified',
    'can_submit': true,
  });
  TransactionEligibility eligibilityState = TransactionEligibility.fromJson(const {
    'eligible': false,
    'reason': 'identity_unverified',
    'identity_status': 'unverified',
    'identity_required': true,
  });

  List<PendingIdentityDocument>? sent;
  String? sentNumber;
  bool fail = false;

  @override
  Future<IdentityVerification> get() async => state;

  @override
  Future<TransactionEligibility> eligibility() async => eligibilityState;

  @override
  Future<IdentityVerification> submit({
    required String idNumber,
    required String fullName,
    required DateTime birthdate,
    required List<PendingIdentityDocument> documents,
    void Function(double progress)? onProgress,
  }) async {
    if (fail) throw Exception('offline');
    sent = documents;
    sentNumber = idNumber;
    onProgress?.call(1);
    eligibilityState = TransactionEligibility.fromJson(const {
      'eligible': false,
      'reason': 'identity_pending',
      'identity_status': 'pending',
      'identity_required': true,
    });
    return state = IdentityVerification.fromJson(const {
      'status': 'pending',
      'can_submit': false,
      'id_number_last4': '4821',
      'submitted_at': '2026-09-24T02:11:00+00:00',
    });
  }
}

PendingIdentityDocument _doc(String type, {String name = 'id.jpg', int size = 10}) =>
    PendingIdentityDocument(type: type, fileName: name, bytes: Uint8List(size));

Future<IdentityController> _signedIn(_FakeIdentityService service) async {
  final controller = IdentityController(service: service);
  await controller.onAuthChanged(signedIn: true);
  return controller;
}

void main() {
  group('IdentityVerification.fromJson', () {
    test('reads the status, the rejection reason and the last four digits', () {
      final verification = IdentityVerification.fromJson(const {
        'status': 'rejected',
        'can_submit': true,
        'id_number_last4': '4821',
        'full_name': 'Juan Dela Cruz',
        'birthdate': '1995-04-02',
        'reviewed_at': '2026-09-21T06:40:00+00:00',
        'rejection_reason': 'The photo of the back of the card was unreadable.',
      });

      expect(verification.isRejected, isTrue);
      expect(verification.canSubmit, isTrue);
      expect(verification.idNumberLast4, '4821');
      expect(verification.rejectionReason,
          'The photo of the back of the card was unreadable.');
      expect(verification.reviewedAt, isNotNull);
    });

    test('an unknown or absent status reads as unverified rather than crashing', () {
      expect(IdentityVerification.fromJson(const {}).isUnverified, isTrue);
      expect(IdentityVerification.fromJson(const {}).canSubmit, isFalse);
    });
  });

  group('TransactionEligibility', () {
    test('a fresh install assumes nothing is required until the API says so', () {
      // Assuming a block would lock people out of a platform that does not
      // require verification at all.
      expect(TransactionEligibility.unknown.eligible, isTrue);
      expect(TransactionEligibility.unknown.reason, isNull);
    });

    test('an identity reason and a commission reason are told apart', () {
      final identity = TransactionEligibility.fromJson(const {
        'eligible': false,
        'reason': 'identity_pending',
        'identity_status': 'pending',
        'identity_required': true,
      });
      expect(identity.blockedByIdentity, isTrue);
      expect(identity.blockedByCommission, isFalse);

      final commission = TransactionEligibility.fromJson(const {
        'account_type': 'provider',
        'eligible': false,
        'reason': 'outstanding_commission',
        'identity_status': 'verified',
        'identity_required': true,
        'outstanding_total': '20.00',
        'outstanding_count': 1,
      });
      expect(commission.blockedByCommission, isTrue);
      expect(commission.blockedByIdentity, isFalse);
      expect(commission.outstandingTotal, '20.00');
      expect(commission.outstandingCount, 1);
    });

    test('a grandfathered account reports that nothing is required of it', () {
      final eligibility = TransactionEligibility.fromJson(const {
        'eligible': true,
        'reason': null,
        'identity_status': 'unverified',
        'identity_required': false,
      });
      expect(eligibility.eligible, isTrue);
      expect(eligibility.identityRequired, isFalse);
    });
  });

  group('IdentityController', () {
    test('load() reads the status and the eligibility together', () async {
      final service = _FakeIdentityService();
      final controller = await _signedIn(service);

      await controller.load();

      expect(controller.verification!.isUnverified, isTrue);
      expect(controller.eligibility.reason, 'identity_unverified');
      expect(controller.isRequired, isTrue);
      expect(controller.errorMessage, isNull);
    });

    test('a photo that is the wrong type or too large is refused before sending', () async {
      final controller = await _signedIn(_FakeIdentityService());

      expect(
        controller.capture(_doc(PendingIdentityDocument.frontType, name: 'card.gif')),
        'Use a JPG or PNG photo.',
      );
      expect(
        controller.capture(_doc(PendingIdentityDocument.frontType,
            size: PendingIdentityDocument.maxBytes + 1)),
        'That photo is larger than 10 MB. Try again with a smaller one.',
      );
      expect(controller.captured, isEmpty);
    });

    test('both sides of the card are required, and re-capturing replaces a side', () async {
      final controller = await _signedIn(_FakeIdentityService());

      expect(controller.canSubmit, isFalse);
      controller.capture(_doc(PendingIdentityDocument.frontType, name: 'front.jpg'));
      expect(controller.canSubmit, isFalse);
      controller.capture(_doc(PendingIdentityDocument.backType, name: 'back.png'));
      expect(controller.canSubmit, isTrue);

      controller.capture(_doc(PendingIdentityDocument.frontType, name: 'front-again.jpg'));
      expect(controller.captured.length, 2);
      expect(controller.captured[PendingIdentityDocument.frontType]!.fileName,
          'front-again.jpg');

      controller.remove(PendingIdentityDocument.backType);
      expect(controller.canSubmit, isFalse);
    });

    test('a submission sends both sides, clears the photos and refreshes eligibility',
        () async {
      final service = _FakeIdentityService();
      final controller = await _signedIn(service);
      controller.capture(_doc(PendingIdentityDocument.frontType, name: 'front.jpg'));
      controller.capture(_doc(PendingIdentityDocument.backType, name: 'back.jpg'));

      final ok = await controller.submit(
        idNumber: '1234-5678-9012-3456',
        fullName: 'Juan Dela Cruz',
        birthdate: DateTime(1995, 4, 2),
      );

      expect(ok, isTrue);
      expect(service.sent!.map((d) => d.type),
          [PendingIdentityDocument.frontType, PendingIdentityDocument.backType]);
      // Sent as typed: the API strips the separators itself.
      expect(service.sentNumber, '1234-5678-9012-3456');
      expect(controller.captured, isEmpty);
      expect(controller.isPending, isTrue);
      expect(controller.eligibility.reason, 'identity_pending');
    });

    test('a failed submission keeps the photos so it can be retried', () async {
      final service = _FakeIdentityService()..fail = true;
      final controller = await _signedIn(service);
      controller.capture(_doc(PendingIdentityDocument.frontType, name: 'front.jpg'));
      controller.capture(_doc(PendingIdentityDocument.backType, name: 'back.jpg'));

      final ok = await controller.submit(
        idNumber: '1234567890123456',
        fullName: 'Juan Dela Cruz',
        birthdate: DateTime(1995, 4, 2),
      );

      expect(ok, isFalse);
      expect(controller.errorMessage, isNotNull);
      expect(controller.captured.length, 2);
      expect(controller.isSubmitting, isFalse);
    });

    test('signing out drops the previous account\'s verification and photos', () async {
      final service = _FakeIdentityService();
      final controller = await _signedIn(service);
      await controller.load();
      controller.capture(_doc(PendingIdentityDocument.frontType, name: 'front.jpg'));

      await controller.onAuthChanged(signedIn: false);

      expect(controller.verification, isNull);
      expect(controller.captured, isEmpty);
      expect(controller.eligibility.eligible, isTrue);
    });
  });

  group('CommissionSummary.fromJson', () {
    test('reads the balance, the block and the bookings behind it', () {
      final summary = CommissionSummary.fromJson(const {
        'eligible': false,
        'reason': 'outstanding_commission',
        'outstanding_total': '20.00',
        'outstanding_count': 1,
        'currency': 'PHP',
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
      });

      expect(summary.isBlockedByCommission, isTrue);
      expect(summary.hasOutstanding, isTrue);
      // Kept as the API formatted it, never re-parsed for display.
      expect(summary.outstandingTotal, '20.00');
      expect(summary.outstanding.single.serviceTitle, 'Aircon Cleaning');
      expect(summary.outstanding.single.commissionAmount, '20.00');
      expect(summary.outstanding.single.paidAt, isNotNull);
    });

    test('a provider blocked on identity is not sent to the commission screen', () {
      final summary = CommissionSummary.fromJson(const {
        'eligible': false,
        'reason': 'identity_unverified',
        'outstanding_total': '0.00',
        'outstanding_count': 0,
        'outstanding': [],
      });

      expect(summary.isBlockedByCommission, isFalse);
      expect(summary.hasOutstanding, isFalse);
    });
  });
}
