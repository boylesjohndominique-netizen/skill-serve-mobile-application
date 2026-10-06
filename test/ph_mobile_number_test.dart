import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skillserve_mobile/core/utils/ph_mobile_number.dart';
import 'package:skillserve_mobile/core/utils/validators.dart';

void main() {
  test('every way of typing a number becomes 09 and 11 digits', () {
    for (final typed in ['09123456789', '+63 912 345 6789', '639123456789', '9123456789', '0912-345-6789']) {
      expect(PhMobileNumber.normalise(typed), '09123456789', reason: typed);
    }
    // Nothing past the 11th digit.
    expect(PhMobileNumber.normalise('091234567890000'), '09123456789');
  });

  test('only an 11-digit 09 number is valid', () {
    expect(Validators.phone('09123456789'), isNull);
    expect(Validators.phone('+63 912 345 6789'), isNull);
    expect(Validators.phone(''), 'Phone number is required');
    expect(Validators.phone('0912345678'), PhMobileNumber.message);
    expect(Validators.phone('08123456789'), PhMobileNumber.message);
    // GCash: empty is fine while the provider is clearing their details.
    expect(PhMobileNumber.validate('', required: false), isNull);
  });

  test('the field turns a pasted +63 number into 09 and stops at 11 digits', () {
    TextEditingValue type(String text) =>
        PhMobileNumber.formatter.formatEditUpdate(TextEditingValue.empty, TextEditingValue(text: text));

    expect(type('+63 912 345 6789').text, '09123456789');
    expect(type('0912345678901').text, '09123456789');
    expect(type('09a1b2').text, '0912');
  });
}
