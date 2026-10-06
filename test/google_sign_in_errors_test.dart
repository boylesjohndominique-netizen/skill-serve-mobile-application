import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skillserve_mobile/features/auth/services/google_sign_in_errors.dart';

void main() {
  // Release builds rename Play services' ApiException, e.g. to "h".
  PlatformException failure(String code, String message) =>
      PlatformException(code: code, message: message);

  test('a network error is recognised, retried and explained without the raw exception', () {
    final error = failure('network_error', 'com.google.android.gms.common.api.h: 7: ');

    expect(isGoogleNetworkError(error), isTrue);
    final message = googleSignInErrorMessage(error);
    expect(message, startsWith('Google could not be reached from this phone.'));
    expect(message, isNot(contains('PlatformException')));
  });

  test('a missing Android OAuth client is told apart, obfuscated or not', () {
    for (final cls in ['com.google.android.gms.common.api.ApiException', 'com.google.android.gms.common.api.h']) {
      expect(googleSignInErrorMessage(failure('sign_in_failed', '$cls: 10: ')),
          startsWith('Google sign-in is not set up'));
    }
  });

  test('outdated Play services and anything else get their own messages', () {
    expect(googleSignInErrorMessage(failure('sign_in_failed', 'h: 12500: ')),
        contains('Update Google Play services'));
    expect(googleSignInErrorMessage(failure('sign_in_failed', 'h: 8: ')),
        'Google sign-in failed. Please try again, or use your email.');
  });

  test('closing the account picker is a cancel, not a network error', () {
    final error = failure('sign_in_canceled', 'h: 12501: ');
    expect(isGoogleSignInCancelled(error), isTrue);
    expect(isGoogleNetworkError(error), isFalse);
  });
}
