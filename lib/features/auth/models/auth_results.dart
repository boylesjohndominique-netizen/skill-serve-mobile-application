import 'user_model.dart';

/// A sign-up that is waiting for its emailed 6-digit code.
///
/// The backend creates no account until the code is confirmed, so this
/// carries no user and no tokens — only what the OTP screen needs.
class PendingRegistration {
  final String email;
  final String firstName;
  final String lastName;
  final UserRole role;

  const PendingRegistration({
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.role,
  });

  factory PendingRegistration.fromJson(Map<String, dynamic> json) =>
      PendingRegistration(
        email: json['email'] as String? ?? '',
        firstName: json['first_name'] as String? ?? '',
        lastName: json['last_name'] as String? ?? '',
        role: json['user_type'] == 'provider'
            ? UserRole.provider
            : UserRole.client,
      );
}

/// What Google Sign-In produced: either a signed-in user, or a draft that
/// the "complete your profile" screen fills in before the account exists.
class GoogleAuthResult {
  final UserModel? user;
  final GoogleProfileDraft? draft;

  const GoogleAuthResult.signedIn(UserModel this.user) : draft = null;
  const GoogleAuthResult.registrationRequired(GoogleProfileDraft this.draft)
      : user = null;

  bool get requiresRegistration => draft != null;
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
