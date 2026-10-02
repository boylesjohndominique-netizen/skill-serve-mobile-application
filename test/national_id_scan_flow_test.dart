import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:skilllink_mobile/core/theme/app_theme.dart';
import 'package:skilllink_mobile/features/identity/controllers/identity_controller.dart';
import 'package:skilllink_mobile/features/identity/models/scanned_national_id.dart';
import 'package:skilllink_mobile/features/identity/services/national_id_camera.dart';
import 'package:skilllink_mobile/features/identity/services/national_id_reader.dart';
import 'package:skilllink_mobile/features/identity/views/national_id_scan_flow.dart';

/// Answers by image: [frontText]/[frontQr] for the front, [backQr] for the
/// back. [failFront] makes reading the front throw, as ML Kit can.
class _FakeReader implements NationalIdReader {
  _FakeReader({this.frontText = '', this.frontQr = const [], this.backQr = const [], this.failFront = false});

  final String frontText;
  final List<String> frontQr;
  final List<String> backQr;
  final bool failFront;

  @override
  Future<String> readText(String imagePath) async {
    if (imagePath.contains('front') && failFront) throw PlatformException(code: 'TextRecognizerError', message: 'model not found');
    return imagePath.contains('front') ? frontText : '';
  }

  @override
  Future<List<String>> readQrCodes(String imagePath) async => imagePath.contains('front') ? frontQr : backQr;

  @override
  Future<void> close() async {}
}

/// A scanner that hands back the front, then the back.
CaptureIdPhoto _scanner() {
  var shot = 0;
  return () async => shot++ == 0 ? '/scans/front.jpg' : '/scans/back.jpg';
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
            child: NationalIdScanFlow(
              onComplete: onComplete,
              reader: reader,
              capturePhoto: _scanner(),
              readFile: (_) async => Uint8List.fromList([1, 2, 3]),
            ),
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

/// Lets the back scanner open by itself and finish.
Future<void> _waitForBackScan(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 1));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('scan the front and the back opens by itself, then the details', (tester) async {
    final identity = IdentityController();
    ScannedNationalId? result;
    final reader = _FakeReader(
      frontText: 'Apelyido/Last Name\nDELA CRUS\nMga Pangalan/Given Names\nJUAN\nTirahan/Address\nBAGONG PAG-ASA, QUEZON CITY',
      backQr: ['{"subject":{"lName":"DELA CRUZ","DOB":"January 01, 1990","PCN":"1234-5678-9012-3456"}}'],
    );

    await tester.pumpWidget(_flow(identity, reader, (id) => result = id));
    await tester.pumpAndSettle();
    expect(find.text('Front of your National ID'), findsOneWidget);

    await _tap(tester, 'Scan the front');
    expect(find.text('Now the back of your National ID'), findsOneWidget);
    expect(identity.hasFront, isTrue);

    // Nobody taps "Scan the back": the scanner opens on its own.
    await _waitForBackScan(tester);

    expect(identity.hasBack, isTrue);
    expect(result, isNotNull);
    // The QR corrected the misread surname and supplied the rest.
    expect(result!.lastName, 'Dela Cruz');
    expect(result!.givenNames, 'Juan');
    expect(result!.birthdate, DateTime(1990, 1, 1));
    expect(result!.cardNumber, '1234567890123456');
    expect(result!.address, 'BAGONG PAG-ASA, QUEZON CITY');
  });

  testWidgets('an ePhilID QR on the front is read too', (tester) async {
    ScannedNationalId? result;
    final reader = _FakeReader(frontQr: ['{"last_name":"Reyes","first_name":"Maria","pcn":"9876543210987654"}']);

    await tester.pumpWidget(_flow(IdentityController(), reader, (id) => result = id));
    await tester.pumpAndSettle();
    await _tap(tester, 'Scan the front');
    await _waitForBackScan(tester);

    expect(result?.lastName, 'Reyes');
    expect(result?.cardNumber, '9876543210987654');
  });

  testWidgets('a read that fails does not block: the back still comes, then a choice with the reason', (tester) async {
    final identity = IdentityController();
    ScannedNationalId? result;

    await tester.pumpWidget(_flow(identity, _FakeReader(failFront: true), (id) => result = id));
    await tester.pumpAndSettle();
    await _tap(tester, 'Scan the front');

    // Not stuck on the front with an error.
    expect(find.text('Now the back of your National ID'), findsOneWidget);
    await _waitForBackScan(tester);

    expect(find.text('We could not read your ID'), findsOneWidget);
    expect(find.textContaining('TextRecognizerError: model not found'), findsOneWidget);
    await tester.tap(find.text('Type them instead'));
    await tester.pumpAndSettle();

    // The images are kept for review; the user types the details.
    expect(result?.isEmpty, isTrue);
    expect(identity.hasFront && identity.hasBack, isTrue);
  });
}
