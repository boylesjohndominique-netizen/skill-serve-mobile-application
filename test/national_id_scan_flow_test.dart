import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:skilllink_mobile/core/theme/app_theme.dart';
import 'package:skilllink_mobile/features/identity/controllers/identity_controller.dart';
import 'package:skilllink_mobile/features/identity/models/scanned_national_id.dart';
import 'package:skilllink_mobile/features/identity/services/national_id_reader.dart';
import 'package:skilllink_mobile/features/identity/views/national_id_scan_flow.dart';

/// Answers by photo: the front's text, the back's QR code.
class _FakeReader implements NationalIdReader {
  _FakeReader({this.frontText = '', this.qrCodes = const []});

  final String frontText;
  final List<String> qrCodes;

  @override
  Future<String> readText(String imagePath) async => imagePath.contains('front') ? frontText : '';

  @override
  Future<List<String>> readQrCodes(String imagePath) async => imagePath.contains('back') ? qrCodes : const [];

  @override
  Future<void> close() async {}
}

/// A camera that hands back the front, then the back.
TakePhoto _camera() {
  var shot = 0;
  return () async {
    final side = shot++ == 0 ? 'front' : 'back';
    return XFile.fromData(Uint8List.fromList([1, 2, 3]), name: '$side.jpg', path: '/tmp/$side.jpg');
  };
}

Widget _flow(IdentityController identity, NationalIdReader reader, ValueChanged<ScannedNationalId> onComplete) {
  return ChangeNotifierProvider<IdentityController>.value(
    value: identity,
    child: ScreenUtilInit(
      designSize: const Size(390, 844),
      builder: (context, child) => MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: SingleChildScrollView(
            child: NationalIdScanFlow(onComplete: onComplete, reader: reader, takePhoto: _camera()),
          ),
        ),
      ),
    ),
  );
}

/// The button sits below the card outline; bring it on screen first.
Future<void> _tap(WidgetTester tester, String label) async {
  await tester.ensureVisible(find.text(label));
  await tester.pumpAndSettle();
  await tester.tap(find.text(label));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('the front, then straight on to the back, then the details', (tester) async {
    final identity = IdentityController();
    ScannedNationalId? result;
    final reader = _FakeReader(
      frontText: 'Apelyido/Last Name\nDELA CRUS\nMga Pangalan/Given Names\nJUAN\nTirahan/Address\nBAGONG PAG-ASA, QUEZON CITY',
      qrCodes: ['{"subject":{"lName":"DELA CRUZ","DOB":"January 01, 1990","PCN":"1234-5678-9012-3456"}}'],
    );

    await tester.pumpWidget(_flow(identity, reader, (id) => result = id));
    await tester.pumpAndSettle();
    expect(find.text('Front of your National ID'), findsOneWidget);

    await _tap(tester, 'Take photo of the front');

    // Nobody asked for the back: the flow moved on by itself.
    expect(find.text('Now the back of your National ID'), findsOneWidget);
    expect(identity.hasFront, isTrue);

    await _tap(tester, 'Take photo of the back');

    expect(identity.hasBack, isTrue);
    expect(result, isNotNull);
    // The QR corrected the misread surname and supplied the rest.
    expect(result!.lastName, 'Dela Cruz');
    expect(result!.givenNames, 'Juan');
    expect(result!.birthdate, DateTime(1990, 1, 1));
    expect(result!.cardNumber, '1234567890123456');
    expect(result!.address, 'BAGONG PAG-ASA, QUEZON CITY');
    expect(identity.scanned?.lastName, 'Dela Cruz');
  });

  testWidgets('a card that cannot be read offers a retake or typing instead', (tester) async {
    final identity = IdentityController();
    ScannedNationalId? result;

    await tester.pumpWidget(_flow(identity, _FakeReader(), (id) => result = id));
    await tester.pumpAndSettle();
    await _tap(tester, 'Take photo of the front');
    await _tap(tester, 'Take photo of the back');

    expect(find.text('We could not read your ID'), findsOneWidget);
    await tester.tap(find.text('Type them instead'));
    await tester.pumpAndSettle();

    // The photos are kept for review; the user types the details.
    expect(result?.isEmpty, isTrue);
    expect(identity.hasFront && identity.hasBack, isTrue);
  });
}
