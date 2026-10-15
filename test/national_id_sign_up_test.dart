import 'package:flutter_test/flutter_test.dart';
import 'package:skillserve_mobile/features/identity/views/sign_up_identity_fields.dart';

/// Sign-up sends the scanned card number so the server can refuse a second
/// provider (or customer) account on one National ID before it is created.
void main() {
  test('a complete card number goes with the sign-up, digits only', () {
    final form = SignUpIdentityForm()..cardNumber.text = '1234-5678-9012-3456';
    expect(form.signUpDetails['id_number'], '1234567890123456');
    form.dispose();
  });

  test('an incomplete or empty card number is left out', () {
    final form = SignUpIdentityForm()..cardNumber.text = '1234-5678';
    expect(form.signUpDetails.containsKey('id_number'), isFalse);
    form.cardNumber.text = '';
    expect(form.signUpDetails.containsKey('id_number'), isFalse);
    form.dispose();
  });
}
