import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';

// The plugin reports Play services' ApiException as "<class>: <status>:";
// release builds rename the class (e.g. "h: 7:"), so match the status only.

/// Status 10 (DEVELOPER_ERROR): this app's package name + signing SHA-1 has
/// no Android OAuth client.
final _developerError = RegExp(r':\s*10:');

/// Status 12500 (SIGN_IN_FAILED): usually outdated Google Play services.
final _playServicesError = RegExp(r':\s*12500:');

/// Whether google_sign_in failed with Google Play services' NETWORK_ERROR
/// (status 7). It is often transient, so one retry is worth making.
bool isGoogleNetworkError(Object error) =>
    error is PlatformException && error.code == GoogleSignIn.kNetworkError;

/// Whether the user closed the Google account picker.
bool isGoogleSignInCancelled(Object error) =>
    error is PlatformException && error.code == GoogleSignIn.kSignInCanceledError;

/// A readable message for a google_sign_in failure. Raw Play services
/// exceptions (e.g. `ApiException: 7`) mean nothing to the user.
String googleSignInErrorMessage(PlatformException error) {
  final detail = '${error.message ?? ''} ${error.details ?? ''}';

  if (error.code == GoogleSignIn.kNetworkError) {
    return 'Google could not be reached from this phone. Check that you are online, '
        'the date and time are set automatically, any VPN or Private DNS is off, and '
        'Google Play services is up to date, then try again. You can also sign up with your email.';
  }

  if (_developerError.hasMatch(detail)) {
    return 'Google sign-in is not set up for this version of the app yet. '
        'Please use your email for now.';
  }

  if (_playServicesError.hasMatch(detail)) {
    return 'Google sign-in failed. Update Google Play services, then try again.';
  }

  return 'Google sign-in failed. Please try again, or use your email.';
}
