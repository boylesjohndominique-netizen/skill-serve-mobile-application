import '../models/auth_results.dart';
import '../models/user_model.dart';
import '../../../core/services/api_client.dart';
import '../../../core/services/token_storage.dart';

/// Auth service — live API only.
///
/// Endpoints:
/// - POST /api/client/v1/auth/login
/// - POST /api/client/v1/auth/register (client accounts)
/// - POST /api/client/v1/auth/register-provider (provider accounts)
/// - POST /api/client/v1/auth/verify-otp (6-digit email code)
/// - POST /api/client/v1/auth/complete-registration (password, last step)
/// - POST /api/client/v1/auth/resend-otp
/// - POST /api/client/v1/auth/google (Google ID token + account password)
/// - POST /api/client/v1/auth/google/register (start a Google sign-up)
/// - POST /api/client/v1/auth/forgot-password (emails a 6-digit code)
/// - POST /api/client/v1/auth/verify-reset-code
/// - POST /api/client/v1/auth/reset-password
/// - POST /api/client/v1/auth/logout
/// - GET /api/client/v1/auth/me
/// - POST /api/client/v1/auth/refresh
class AuthService {
  String? lastAccessToken;
  String? lastRefreshToken;
  String? lastExpiresAt;

  // POST /api/client/v1/auth/login
  Future<UserModel> login(
      {required String email, required String password}) async {
    final response =
        await ApiClient.instance.dio.post('/client/v1/auth/login', data: {
      'email': email,
      'password': password,
    });
    final data = response.data['data'] as Map<String, dynamic>;
    _readSession(data);
    return UserModel.fromJson(data['user'] as Map<String, dynamic>);
  }

  // POST /api/client/v1/auth/register — parks the sign-up and emails a
  // code. No account exists until the code (verifyOtp) and then the password
  // (completeRegistration) are in, so no session is returned here.
  Future<PendingRegistration> register({
    required String firstName,
    required String lastName,
    required String email,
    Map<String, dynamic> signUpDetails = const {},
  }) async {
    final response =
        await ApiClient.instance.dio.post('/client/v1/auth/register', data: {
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      ...signUpDetails,
    });
    return PendingRegistration.fromJson(
        response.data['data'] as Map<String, dynamic>);
  }

  // POST /api/client/v1/auth/register-provider — parked the same way as a
  // customer sign-up; the provider profile is created on verification.
  Future<PendingRegistration> registerProvider({
    required String firstName,
    required String lastName,
    required String email,
    String? businessName,
    required String specialization,
    int experienceYears = 0,
    String? bio,
    Map<String, dynamic> signUpDetails = const {},
  }) async {
    final response = await ApiClient.instance.dio
        .post('/client/v1/auth/register-provider', data: {
      ...signUpDetails,
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      if (businessName != null && businessName.isNotEmpty)
        'business_name': businessName,
      'specialization': specialization,
      'experience_years': experienceYears,
      if (bio != null && bio.isNotEmpty) 'bio': bio,
    });
    return PendingRegistration.fromJson(
        response.data['data'] as Map<String, dynamic>);
  }

  // POST /api/client/v1/auth/verify-otp — confirms the address. The
  // password comes next (completeRegistration); a sign-up parked by an older
  // app version, which already sent its password, is created here instead.
  Future<OtpResult> verifyOtp({required String email, required String code}) async {
    final response = await ApiClient.instance.dio
        .post('/client/v1/auth/verify-otp', data: {
      'email': email,
      'code': code,
    });
    final data = response.data['data'] as Map<String, dynamic>;
    if (data['password_required'] == true) {
      return const OtpResult.passwordRequired();
    }
    _readSession(data);
    return OtpResult.signedIn(
        UserModel.fromJson(data['user'] as Map<String, dynamic>));
  }

  // POST /api/client/v1/auth/complete-registration — the last sign-up step:
  // sets the password, creates the account and returns a real session.
  Future<UserModel> completeRegistration({
    required String email,
    required String registrationToken,
    required String password,
  }) async {
    final response = await ApiClient.instance.dio
        .post('/client/v1/auth/complete-registration', data: {
      'email': email,
      'registration_token': registrationToken,
      'password': password,
      'password_confirmation': password,
    });
    final data = response.data['data'] as Map<String, dynamic>;
    _readSession(data);
    return UserModel.fromJson(data['user'] as Map<String, dynamic>);
  }

  // POST /api/client/v1/auth/resend-otp
  Future<void> resendOtp({required String email}) async {
    await ApiClient.instance.dio
        .post('/client/v1/auth/resend-otp', data: {'email': email});
  }

  // POST /api/client/v1/auth/cancel-registration — discards the parked
  // sign-up so the email is free again. Guarded by the registration token
  // (or, for a sign-up resumed from login, the password typed there).
  // No-ops (200) for verified or unknown accounts; the app ignores the
  // outcome either way.
  Future<void> cancelRegistration({
    required String email,
    String? registrationToken,
    String? password,
  }) async {
    await ApiClient.instance.dio.post('/client/v1/auth/cancel-registration', data: {
      'email': email,
      if (registrationToken != null) 'registration_token': registrationToken,
      if (password != null) 'password': password,
    });
  }

  // POST /api/client/v1/auth/google — Google identifies the person, the
  // account password signs in. Without [password] an existing account
  // answers password_required; an unknown Google account returns a draft to
  // fill the sign-up form with.
  Future<GoogleAuthResult> loginWithGoogle(
      {required String idToken, String? password}) async {
    final response = await ApiClient.instance.dio.post('/client/v1/auth/google',
        data: {'id_token': idToken, if (password != null) 'password': password});
    final data = response.data['data'] as Map<String, dynamic>;

    if (data['password_required'] == true) {
      return GoogleAuthResult.passwordRequired(data['email'] as String? ?? '');
    }

    if (data['registration_required'] == true) {
      return GoogleAuthResult.registrationRequired(
        GoogleProfileDraft.fromJson(
          (data['google'] as Map?)?.cast<String, dynamic>() ?? const {},
          idToken: idToken,
        ),
      );
    }

    _readSession(data);
    return GoogleAuthResult.signedIn(
        UserModel.fromJson(data['user'] as Map<String, dynamic>));
  }

  // POST /api/client/v1/auth/google/register — parks the sign-up of a
  // Google identity that has no account and emails a code to its address;
  // from there it takes the same code and password steps as an email sign-up.
  Future<PendingRegistration> completeGoogleRegistration({
    required String idToken,
    required String firstName,
    required String lastName,
    required UserRole role,
    String? businessName,
    String specialization = '',
    int experienceYears = 0,
    String? bio,
    Map<String, dynamic> signUpDetails = const {},
  }) async {
    final isProvider = role == UserRole.provider;
    final response = await ApiClient.instance.dio
        .post('/client/v1/auth/google/register', data: {
      ...signUpDetails,
      'id_token': idToken,
      'first_name': firstName,
      'last_name': lastName,
      'role': isProvider ? 'provider' : 'customer',
      if (isProvider) ...{
        if (businessName != null && businessName.isNotEmpty)
          'business_name': businessName,
        'specialization': specialization,
        'experience_years': experienceYears,
        if (bio != null && bio.isNotEmpty) 'bio': bio,
      },
    });
    return PendingRegistration.fromJson(
        response.data['data'] as Map<String, dynamic>);
  }

  // POST /api/client/v1/auth/forgot-password — emails a 6-digit code. The
  // answer is the same whether or not the address has an account.
  Future<void> requestPasswordReset(String email) async {
    await ApiClient.instance.dio
        .post('/client/v1/auth/forgot-password', data: {'email': email});
  }

  // POST /api/client/v1/auth/verify-reset-code — trades the emailed code
  // for the single-use token resetPassword() needs.
  Future<String> verifyResetCode(
      {required String email, required String code}) async {
    final response = await ApiClient.instance.dio.post(
        '/client/v1/auth/verify-reset-code',
        data: {'email': email, 'code': code});
    return (response.data['data'] as Map<String, dynamic>)['reset_token']
        as String;
  }

  // POST /api/client/v1/auth/reset-password — sets the new password and
  // signs the account out everywhere.
  Future<void> resetPassword({
    required String email,
    required String resetToken,
    required String password,
  }) async {
    await ApiClient.instance.dio.post('/client/v1/auth/reset-password', data: {
      'email': email,
      'token': resetToken,
      'password': password,
      'password_confirmation': password,
    });
  }

  // POST /api/client/v1/auth/logout
  Future<void> logout() async {
    await ApiClient.instance.dio.post('/client/v1/auth/logout');
    await TokenStorage.clear();
  }

  // GET /api/client/v1/auth/me
  Future<UserModel> getCurrentUser() async {
    final response = await ApiClient.instance.dio.get('/client/v1/auth/me');
    return UserModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  // POST /api/client/v1/auth/refresh
  Future<UserModel> refresh(String refreshToken) async {
    final response = await ApiClient.instance.dio
        .post('/client/v1/auth/refresh', data: {'refresh_token': refreshToken});
    final data = response.data['data'] as Map<String, dynamic>;
    _readSession(data);
    return UserModel.fromJson(data['user'] as Map<String, dynamic>);
  }

  void _readSession(Map<String, dynamic> data) {
    lastAccessToken = data['token'] as String?;
    lastRefreshToken = data['refresh_token'] as String?;
    lastExpiresAt = data['expires_at'] as String?;
  }
}
