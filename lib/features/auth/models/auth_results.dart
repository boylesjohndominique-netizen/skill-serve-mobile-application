import 'user_model.dart';

/// A sign-up that is not an account yet: it waits for its emailed 6-digit
/// code, then for the password.
///
/// The backend creates no account until both are in, so this carries no user
/// and no session tokens — only what the next screens need.
class PendingRegistration {
  final String email;
  final String firstName;
  final String lastName;
  final UserRole role;

  /// Proves this device started the sign-up. Returned once, when the sign-up
  /// starts, and needed to set the password (or cancel). Null elsewhere.
  final String? registrationToken;

  /// Whether the password is still to be chosen after the code. False only
  /// for sign-ups parked by older app versions, which sent it up front.
  final bool passwordRequired;

  const PendingRegistration({
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.role,
    this.registrationToken,
    this.passwordRequired = true,
  });

  factory PendingRegistration.fromJson(Map<String, dynamic> json) =>
      PendingRegistration(
        email: json['email'] as String? ?? '',
        firstName: json['first_name'] as String? ?? '',
        lastName: json['last_name'] as String? ?? '',
        role: json['user_type'] == 'provider'
            ? UserRole.provider
            : UserRole.client,
        registrationToken: json['registration_token'] as String?,
        passwordRequired: json['password_required'] as bool? ?? true,
      );
}

/// What confirming the sign-up code produced: the account (sign-ups parked by
/// older app versions) or a request to choose the password next.
class OtpResult {
  final UserModel? user;

  const OtpResult.signedIn(UserModel this.user);
  const OtpResult.passwordRequired() : user = null;

  bool get requiresPassword => user == null;
}

/// What Google Sign-In produced: a signed-in user; a request for the
/// account's password (Google alone never signs in); or a draft that the
/// "complete your profile" screen fills in before the account exists.
class GoogleAuthResult {
  final UserModel? user;
  final GoogleProfileDraft? draft;

  /// The account the password is asked for, when [requiresPassword].
  final String? passwordEmail;

  const GoogleAuthResult.signedIn(UserModel this.user)
      : draft = null,
        passwordEmail = null;
  const GoogleAuthResult.registrationRequired(GoogleProfileDraft this.draft)
      : user = null,
        passwordEmail = null;
  const GoogleAuthResult.passwordRequired(String this.passwordEmail)
      : user = null,
        draft = null;

  bool get requiresRegistration => draft != null;
  bool get requiresPassword => passwordEmail != null;
}

/// Google's own details, used to prefill the sign-up form. Nothing has been
/// written server-side yet, so abandoning the form costs nothing.
class GoogleProfileDraft {
  final String idToken;
  final String email;
  final String firstName;
  final String lastName;
  final String? picture;

  const GoogleProfileDraft({
    required this.idToken,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.picture,
  });

  factory GoogleProfileDraft.fromJson(
    Map<String, dynamic> json, {
    required String idToken,
  }) =>
      GoogleProfileDraft(
        idToken: idToken,
        email: json['email'] as String? ?? '',
        firstName: json['first_name'] as String? ?? '',
        lastName: json['last_name'] as String? ?? '',
        picture: json['picture'] as String?,
      );
}
