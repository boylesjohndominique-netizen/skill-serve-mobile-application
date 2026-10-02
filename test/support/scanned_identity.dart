import 'dart:typed_data';

import 'package:skilllink_mobile/features/identity/controllers/identity_controller.dart';
import 'package:skilllink_mobile/features/identity/models/identity_verification_model.dart';
import 'package:skilllink_mobile/features/identity/models/scanned_national_id.dart';

/// An [IdentityController] holding a National ID already scanned at sign-up
/// — both photos and the fields read from them — so a sign-up screen opens
/// straight on its form. No address, so nothing calls the location API.
IdentityController scannedIdentity({
  String givenNames = 'Juan',
  String lastName = 'Dela Cruz',
}) {
  final identity = IdentityController();
  for (final type in [PendingIdentityDocument.frontType, PendingIdentityDocument.backType]) {
    identity.capture(PendingIdentityDocument(type: type, fileName: '$type.jpg', bytes: Uint8List.fromList([1, 2, 3])));
  }
  identity.setScanned(ScannedNationalId(
    cardNumber: '9876543210987654',
    givenNames: givenNames,
    middleName: 'Santos',
    lastName: lastName,
    birthdate: DateTime(1995, 4, 2),
  ));
  return identity;
}
