import 'package:flutter_test/flutter_test.dart';
import 'package:skilllink_mobile/features/identity/controllers/identity_controller.dart';
import 'package:skilllink_mobile/features/identity/models/identity_verification_model.dart';
import 'package:skilllink_mobile/features/identity/models/scanned_national_id.dart';
import 'package:skilllink_mobile/features/identity/services/identity_service.dart';
import 'package:skilllink_mobile/features/identity/views/sign_up_identity_fields.dart';

import 'support/scanned_identity.dart';

/// Records what would be sent for review instead of calling the API.
class _FakeIdentityService extends IdentityService {
  _FakeIdentityService({this.refuse = false});

  final bool refuse;
  final sent = <Map<String, Object>>[];

  @override
  Future<IdentityVerification> submit({
    required String idNumber,
    required String fullName,
    required DateTime birthdate,
    required List<PendingIdentityDocument> documents,
    void Function(double progress)? onProgress,
  }) async {
    if (refuse) throw Exception('422');
    sent.add({'id_number': idNumber, 'full_name': fullName, 'birthdate': birthdate, 'documents': documents.map((d) => d.type).toList()});
    return IdentityVerification.fromJson({'status': 'pending'});
  }
}

/// [scannedIdentity]'s photos and fields, on a controller with [service].
IdentityController _scanned(IdentityService service) {
  final source = scannedIdentity();
  final identity = IdentityController(service: service);
  source.captured.values.forEach(identity.capture);
  identity.setScanned(source.scanned!);
  return identity;
}

void main() {
  test('after sign-up the scanned card goes for review and the user goes home', () async {
    final service = _FakeIdentityService();
    final identity = _scanned(service);

    expect(await submitScannedIdAndRoute(identity, isProvider: false), '/client');
    expect(service.sent.single['id_number'], '9876543210987654');
    expect(service.sent.single['full_name'], 'Juan Santos Dela Cruz');
    expect(service.sent.single['birthdate'], DateTime(1995, 4, 2));
    expect(service.sent.single['documents'], [PendingIdentityDocument.frontType, PendingIdentityDocument.backType]);
    // Sent once, then forgotten.
    expect(identity.scanned, isNull);
  });

  test('a provider carries on to business onboarding', () async {
    expect(await submitScannedIdAndRoute(_scanned(_FakeIdentityService()), isProvider: true), '/provider-onboarding');
  });

  test('an incomplete scan is not sent; the ID screen takes over', () async {
    final service = _FakeIdentityService();
    final identity = _scanned(service)..setScanned(const ScannedNationalId(givenNames: 'Juan', lastName: 'Dela Cruz'));

    expect(identity.hasScannedSubmission, isFalse);
    expect(
      await submitScannedIdAndRoute(identity, isProvider: true),
      '/identity-verification?next=${Uri.encodeComponent('/provider-onboarding')}',
    );
    expect(service.sent, isEmpty);
  });

  test('a refused submission keeps the scan for the pre-filled ID screen', () async {
    final identity = _scanned(_FakeIdentityService(refuse: true));

    expect(await submitScannedIdAndRoute(identity, isProvider: false), '/identity-verification');
    expect(identity.scanned?.cardNumber, '9876543210987654');
  });

  test('signing out drops the scan and the photos', () async {
    final identity = _scanned(_FakeIdentityService());
    await identity.onAuthChanged(signedIn: true);
    await identity.onAuthChanged(signedIn: false);

    expect(identity.scanned, isNull);
    expect(identity.hasFront, isFalse);
  });
}
