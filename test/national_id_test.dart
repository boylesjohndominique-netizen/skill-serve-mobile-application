import 'package:flutter_test/flutter_test.dart';
import 'package:skilllink_mobile/features/identity/models/scanned_national_id.dart';
import 'package:skilllink_mobile/features/identity/services/national_id_parser.dart';
import 'package:skilllink_mobile/features/locations/models/ph_address.dart';

/// The front of a plastic PhilSys card as the camera reads it: a bilingual
/// label on one line and its value on the next, the address over two lines.
const _philsysFront = '''
REPUBLIKA NG PILIPINAS
Republic of the Philippines
PAMBANSANG PAGKAKAKILANLAN
Philippine Identification Card
1234-5678-9012-3456
Apelyido/Last Name
DELA CRUZ
Mga Pangalan/Given Names
JUAN CARLO
Gitnang Apelyido/Middle Name
SANTOS
Petsa ng Kapanganakan/Date of Birth
JANUARY 01, 1990
Tirahan/Address
123 RIZAL ST, BRGY BAGONG PAG-ASA,
QUEZON CITY, METRO MANILA
''';

/// A printed ePhilID, where values often land on the label's own line, and a
/// camera that read one 0 of the card number as the letter O.
const _ePhilId = '''
PhilSys Card Number: 1234 5678 9O12 3456
Last Name: REYES
Given Names: MARIA
Middle Name: LOPEZ
Sex: FEMALE
Date of Birth: 25 DEC 1990
Lugar ng Kapanganakan/Place of Birth
CITY OF MANILA
Address: PUROK 3, BALIBAGO, CITY OF STA. ROSA, LAGUNA
''';

void main() {
  group('front of the card', () {
    test('a PhilSys card fills every field', () {
      final id = NationalIdParser.parseFront(_philsysFront);

      expect(id.cardNumber, '1234567890123456');
      expect(id.lastName, 'Dela Cruz');
      expect(id.givenNames, 'Juan Carlo');
      expect(id.middleName, 'Santos');
      expect(id.birthdate, DateTime(1990, 1, 1));
      expect(id.address, '123 RIZAL ST, BRGY BAGONG PAG-ASA, QUEZON CITY, METRO MANILA');
      expect(id.fullName, 'Juan Carlo Santos Dela Cruz');
      expect(id.formattedCardNumber, '1234-5678-9012-3456');
    });

    test('an ePhilID with values beside their labels and a misread digit', () {
      final id = NationalIdParser.parseFront(_ePhilId);

      expect(id.cardNumber, '1234567890123456');
      expect(id.lastName, 'Reyes');
      expect(id.givenNames, 'Maria');
      expect(id.middleName, 'Lopez');
      expect(id.sex, 'female');
      // "Place of birth" shares a word with "date of birth" but is not it.
      expect(id.birthdate, DateTime(1990, 12, 25));
      expect(id.address, 'PUROK 3, BALIBAGO, CITY OF STA. ROSA, LAGUNA');
    });

    test('unreadable text gives an empty reading rather than guesses', () {
      final id = NationalIdParser.parseFront('blurry\n### ###\n');

      expect(id.isEmpty, isTrue);
    });
  });

  group('QR code on the back', () {
    test('the PhilSys JSON with the holder under "subject"', () {
      final id = NationalIdParser.parseQr(
        '{"DateIssued":"June 01, 2023","Issuer":"PSA","subject":{"Suffix":"JR","lName":"DELA CRUZ","fName":"JUAN CARLO","mName":"SANTOS","sex":"Male","DOB":"January 01, 1990","POB":"Quezon City","PCN":"1234-5678-9012-3456"},"alg":"EDDSA","signature":"abc"}',
      );

      expect(id.lastName, 'Dela Cruz');
      expect(id.givenNames, 'Juan Carlo');
      expect(id.middleName, 'Santos');
      expect(id.suffix, 'Jr');
      expect(id.sex, 'male');
      expect(id.birthdate, DateTime(1990, 1, 1));
      expect(id.cardNumber, '1234567890123456');
    });

    test('flat keys in another spelling are read too', () {
      final id = NationalIdParser.parseQr('{"last_name":"Reyes","first_name":"Maria","date_of_birth":"1990-12-25","pcn":"1234567890123456"}');

      expect(id.lastName, 'Reyes');
      expect(id.givenNames, 'Maria');
      expect(id.birthdate, DateTime(1990, 12, 25));
      expect(id.cardNumber, '1234567890123456');
    });

    test('a QR that is not the card changes nothing', () {
      expect(NationalIdParser.parseQr('https://example.com').isEmpty, isTrue);
      expect(NationalIdParser.parseQr('[1,2,3]').isEmpty, isTrue);
    });

    test('the QR corrects what the camera read, and the address stays', () {
      final front = NationalIdParser.parseFront(_philsysFront.replaceFirst('DELA CRUZ', 'DELA CRUS'));
      final merged = front.overriddenBy(NationalIdParser.parseQr('{"subject":{"lName":"DELA CRUZ"}}'));

      expect(merged.lastName, 'Dela Cruz');
      expect(merged.givenNames, 'Juan Carlo');
      expect(merged.address, front.address);
    });
  });

  group('dates', () {
    test('the formats printed on cards', () {
      expect(NationalIdParser.parseDate('JAN 1 1990'), DateTime(1990, 1, 1));
      expect(NationalIdParser.parseDate('1990/01/31'), DateTime(1990, 1, 31));
      expect(NationalIdParser.parseDate('01/31/1990'), DateTime(1990, 1, 31));
    });

    test('impossible or future dates are refused', () {
      expect(NationalIdParser.parseDate('02/30/1990'), isNull);
      expect(NationalIdParser.parseDate('JANUARY 01, ${DateTime.now().year + 1}'), isNull);
      expect(NationalIdParser.parseDate('not a date'), isNull);
    });
  });

  group('picked address', () {
    const ncr = PhPlace(code: '130000000', name: 'National Capital Region (NCR)', level: 'region');
    const qc = PhPlace(code: '137404000', name: 'Quezon City', level: 'city');
    const bagongPagAsa = PhPlace(code: '137404009', name: 'Bagong Pag-asa', level: 'barangay');

    test('formats like the API, with Metro Manila for NCR', () {
      const address = PhAddress(region: ncr, city: qc, barangay: bagongPagAsa, street: '123 Rizal St', postalCode: '1105');

      expect(address.formatted, '123 Rizal St, Bagong Pag-asa, Quezon City, Metro Manila 1105');
      expect(address.toDoorJson(), {'barangay_code': '137404009', 'street': '123 Rizal St', 'postal_code': '1105'});
    });

    test('a service area sends the city and only a chosen barangay', () {
      const address = PhAddress(region: ncr, city: qc);

      expect(address.toAreaJson(), {'city_code': '137404000'});
      expect(address.hasBarangay, isFalse);
    });

    test('a stored address is read back for the picker', () {
      final address = PhAddress.fromJson({
        'region': {'code': '130000000', 'name': 'National Capital Region (NCR)'},
        'province': null,
        'city': {'code': '137404000', 'name': 'Quezon City'},
        'barangay': {'code': '137404009', 'name': 'Bagong Pag-asa'},
        'street': '123 Rizal St',
        'postal_code': null,
      })!;

      expect(address.city, qc);
      expect(address.province, isNull);
      expect(address.street, '123 Rizal St');
      expect(PhAddress.fromJson(null), isNull);
    });
  });

  test('an empty reading has no name', () {
    expect(ScannedNationalId.empty.fullName, '');
    expect(ScannedNationalId.empty.isEmpty, isTrue);
  });
}
