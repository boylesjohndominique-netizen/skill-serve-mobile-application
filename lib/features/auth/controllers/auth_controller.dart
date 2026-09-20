import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'dart:async';
import 'dart:convert';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/auth_results.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../../../core/config/app_config.dart';
import '../../../core/services/token_storage.dart';

enum AuthStatus { unauthenticated, authenticating, authenticated }

/// What a "Continue with Google" tap produced.
enum GoogleAuthOutcome {
  /// Signed in; the session is live.
  signedIn,

  /// This Google account has no SkillServe account yet — send the user to
  /// the profile form ([googleDraft] holds the prefill).
  registrationRequired,

  /// The user dismissed the Google account picker. Nothing to report.
  cancelled,

  /// Something failed; [AuthController.errorMessage] explains it.
  failed,
}

/// Session state — who's signed in (if anyone) and as what role.
/// Backed by [AuthService] placeholders; swap for real token persistence
/// (SharedPreferences / secure storage) once the backend exists.
class AuthController extends ChangeNotifier {
  final AuthService _authService = AuthService();

  AuthStatus status = AuthStatus.unauthenticated;
  UserModel? currentUser;
  String? errorMessage;
  bool sessionExpired = false;
  Timer? _sessionTimer;

  static const _sessionUserKey = 'skillserve.session.user';
  static const _sessionExpiryKey = 'skillserve.session.expiresAt';
  static const sessionDuration = Duration(hours: 8);

  /// Google OAuth **Web** client ID (see [AppConfig.googleWebClientId]).
  /// Required so google_sign_in returns an ID token on Android.
  static const _googleServerClientId = AppConfig.googleWebClientId;

  bool get isGuest => currentUser == null;
  bool get isClient => currentUser?.role == UserRole.client;
  bool get isProvider => currentUser?.role == UserRole.provider;

  /// Set between registration and successful OTP verification. While true,
  /// the registration has NOT produced a session: no tokens are kept,
  /// [status] stays [AuthStatus.unauthenticated], and the router pins the
  /// user to /verify-email so the app cannot be reached unverified.
  bool _pendingEmailVerification = false;
  String? _pendingEmail;
  String? _pendingPassword;

  bool get requiresEmailVerification => _pendingEmailVerification;

  /// The address awaiting its 6-digit code, so the OTP screen can be
  /// reached without carrying the email through the route.
  String? get pendingEmail => _pendingEmail;

  /// Google's prefill for the profile form, set when [loginWithGoogle]
  /// returns [GoogleAuthOutcome.registrationRequired]. Nothing exists
  /// server-side while this is set — dropping it cancels the sign-up.
  GoogleProfileDraft? googleDraft;

  Future<void> initialize() async {
    final accessToken = await TokenStorage.readAccessToken();
    if (accessToken == null) return;
    try {
      currentUser = await _authService.getCurrentUser();
      status = AuthStatus.authenticated;
      _scheduleExpiry(DateTime.now().add(sessionDuration));
      notifyListeners();
    } catch (_) {
      await TokenStorage.clear();
    }
  }

  Future<bool> login(String email, String password) async {
    status = AuthStatus.authenticating;
    errorMessage = null;
    notifyListeners();
    try {
      currentUser = await _authService.login(email: email, password: password);
      await _saveApiTokens();
      status = AuthStatus.authenticated;
      sessionExpired = false;
      _clearPendingRegistration();
      await _persistSession();
      notifyListeners();
      return true;
    } catch (e) {
      status = AuthStatus.unauthenticated;
      // A sign-up that never confirmed its code has no account yet; the
      // backend says so in meta so we can resume verification instead of
      // showing a misleading "invalid credentials".
      final pendingEmail = _pendingVerificationEmail(e);
      if (pendingEmail != null) {
        _pendingEmailVerification = true;
        _pendingEmail = pendingEmail;
        _pendingPassword = password;
      }
      errorMessage = _extractApiError(e, 'Unable to sign in. Please try again.');
      notifyListeners();
      return false;
    }
  }

  /// The email the API reports as awaiting verification, when a failure
  /// says so in `meta` — a login for a sign-up that never confirmed its
  /// code (403), or a repeat sign-up while that code is still valid (429).
  String? _pendingVerificationEmail(Object e) {
    if (e is! DioException) return null;
    final status = e.response?.statusCode;
    if (status != 403 && status != 429) return null;
    final data = e.response?.data;
    if (data is! Map<String, dynamic>) return null;
    final meta = data['meta'];
    if (meta is! Map || meta['verification_required'] != true) return null;
    final email = meta['email'];
    return email is String && email.isNotEmpty ? email : null;
  }

  /// Starts a sign-up. The backend parks it and emails a 6-digit code —
  /// no account and no session exist until [verifyOtp] confirms it, so
  /// backing out here leaves the email free to use again.
  Future<bool> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required UserRole role,
    String? businessName,
    String specialization = '',
    int experienceYears = 0,
    String? bio,
  }) async {
    status = AuthStatus.authenticating;
    errorMessage = null;
    notifyListeners();
    try {
      final pending = role == UserRole.provider
          ? await _authService.registerProvider(
              firstName: firstName,
              lastName: lastName,
              email: email,
              password: password,
              businessName: businessName,
              specialization: specialization.isEmpty ? 'General Services' : specialization,
              experienceYears: experienceYears,
              bio: bio,
            )
          : await _authService.register(
              firstName: firstName,
              lastName: lastName,
              email: email,
              password: password,
            );
      _pendingEmailVerification = true;
      _pendingEmail = pending.email;
      // Kept in memory only so the OTP screen can cancel the sign-up,
      // which the backend guards with this password.
      _pendingPassword = password;
      currentUser = null;
      status = AuthStatus.unauthenticated;
      sessionExpired = false;
      await TokenStorage.clear();
      notifyListeners();
      return true;
    } catch (e) {
      status = AuthStatus.unauthenticated;
      // The address already has a sign-up waiting on a code that is still
      // valid: resume that verification instead of starting over.
      final pendingEmail = _pendingVerificationEmail(e);
      if (pendingEmail != null) {
        _pendingEmailVerification = true;
        _pendingEmail = pendingEmail;
        _pendingPassword = password;
        errorMessage = _extractApiError(e, 'Registration failed. Please try again.');
        notifyListeners();
        return true;
      }
      errorMessage = _extractApiError(e, 'Registration failed. Please try again.');
      notifyListeners();
      return false;
    }
  }

  /// Confirms the 6-digit code emailed at registration. For a parked
  /// sign-up this creates the account server-side and returns a real
  /// session, so the user lands straight in the app.
  Future<bool> verifyOtp(String email, String code) async {
    status = AuthStatus.authenticating;
    errorMessage = null;
    notifyListeners();
    try {
      currentUser = await _authService.verifyOtp(email: email, code: code);
      await _saveApiTokens();
      _clearPendingRegistration();
      status = AuthStatus.authenticated;
      sessionExpired = false;
      await _persistSession();
      notifyListeners();
      return true;
    } catch (e) {
      status = AuthStatus.unauthenticated;
      errorMessage = _extractApiError(e, 'Verification failed. Please try again.');
      notifyListeners();
      return false;
    }
  }

  /// Called when the user backs out of the OTP screen. Discards the parked
  /// sign-up server-side so the email is immediately reusable, and drops it
  /// locally. The password is kept only for this call and cleared after.
  Future<void> cancelPendingVerification() async {
    final email = _pendingEmail;
    final password = _pendingPassword;

    _clearPendingRegistration();
    await TokenStorage.clear();
    currentUser = null;
    status = AuthStatus.unauthenticated;
    errorMessage = null;
    notifyListeners();

    if (email != null && password != null) {
      try {
        await _authService.cancelRegistration(email: email, password: password);
      } catch (_) {
        // Server unreachable: the parked sign-up lives on until it expires,
        // but registering again simply replaces it, so nothing is lost.
      }
    }
  }

  void _clearPendingRegistration() {
    _pendingEmailVerification = false;
    _pendingEmail = null;
    _pendingPassword = null;
  }

  /// Asks the backend to email a fresh OTP (60s cooldown applies).
  Future<bool> resendOtp(String email) async {
    errorMessage = null;
    notifyListeners();
    try {
      await _authService.resendOtp(email: email);
      notifyListeners();
      return true;
    } catch (e) {
      errorMessage = _extractApiError(e, 'Could not resend the code. Try again shortly.');
      notifyListeners();
      return false;
    }
  }

  /// Google Sign-In: obtains an ID token on device and exchanges it for a
  /// SkillServe session.
  ///
  /// An account already linked to this Google identity — or one that simply
  /// owns the same (Google-verified) email — signs in. A Google account
  /// with no SkillServe account creates nothing: the caller is told to show
  /// the profile form, and only submitting it registers the account.
  Future<GoogleAuthOutcome> loginWithGoogle() async {
    status = AuthStatus.authenticating;
    errorMessage = null;
    googleDraft = null;
    notifyListeners();
    try {
      final google = GoogleSignIn(serverClientId: _googleServerClientId);
      final account = await google.signIn();
      if (account == null) {
        status = AuthStatus.unauthenticated;
        notifyListeners();
        return GoogleAuthOutcome.cancelled;
      }
      final auth = await account.authentication;
      final idToken = auth.idToken;
      if (idToken == null) {
        status = AuthStatus.unauthenticated;
        errorMessage = 'Google sign-in did not return a token. Ensure Google Play services are up to date.';
        notifyListeners();
        return GoogleAuthOutcome.failed;
      }

      final result = await _authService.loginWithGoogle(idToken: idToken);

      if (result.requiresRegistration) {
        googleDraft = result.draft;
        status = AuthStatus.unauthenticated;
        notifyListeners();
        return GoogleAuthOutcome.registrationRequired;
      }

      currentUser = result.user;
      await _saveApiTokens();
      status = AuthStatus.authenticated;
      sessionExpired = false;
      _clearPendingRegistration();
      await _persistSession();
      notifyListeners();
      return GoogleAuthOutcome.signedIn;
    } catch (e) {
      status = AuthStatus.unauthenticated;
      errorMessage = _describeGoogleError(e);
      notifyListeners();
      return GoogleAuthOutcome.failed;
    } finally {
      // End the Google session so account switching stays possible.
      try {
        await GoogleSignIn().signOut();
      } catch (_) {}
    }
  }

  /// Creates the account for the Google identity held in [googleDraft],
  /// using the details the user typed on the profile form, and signs in.
  Future<bool> completeGoogleRegistration({
    required String firstName,
    required String lastName,
    required UserRole role,
    String? businessName,
    String specialization = '',
    int experienceYears = 0,
    String? bio,
  }) async {
    final draft = googleDraft;
    if (draft == null) {
      errorMessage = 'Your Google sign-in expired. Please try again.';
      notifyListeners();
      return false;
    }

    status = AuthStatus.authenticating;
    errorMessage = null;
    notifyListeners();
    try {
      currentUser = await _authService.completeGoogleRegistration(
        idToken: draft.idToken,
        firstName: firstName,
        lastName: lastName,
        role: role,
        businessName: businessName,
        specialization: specialization,
        experienceYears: experienceYears,
        bio: bio,
      );
      await _saveApiTokens();
      googleDraft = null;
      status = AuthStatus.authenticated;
      sessionExpired = false;
      _clearPendingRegistration();
      await _persistSession();
      notifyListeners();
      return true;
    } catch (e) {
      status = AuthStatus.unauthenticated;
      errorMessage = _extractApiError(e, 'We could not finish creating your account. Please try again.');
      notifyListeners();
      return false;
    }
  }

  /// Backing out of the Google profile form. Nothing was created
  /// server-side, so this only clears the local draft.
  void cancelGoogleRegistration() {
    googleDraft = null;
    errorMessage = null;
    notifyListeners();
  }

  /// Google plugin errors are developer-facing, so surface the raw code
  /// (e.g. `ApiException: 10: DEVELOPER_ERROR`) to make GCP misconfig
  /// diagnosable. Backend/network errors keep the friendly API messages.
  String _describeGoogleError(Object e) {
    if (e is DioException) {
      return _extractApiError(e, 'Google sign-in failed. Please try again.');
    }
    return 'Google sign-in failed: $e';
  }

  /// Pulls the most specific message out of a Laravel API error envelope:
  /// per-field `errors` first (e.g. "The email has already been taken."),
  /// then the generic envelope `message`, falling back to [fallback].
  /// Network-level failures (timeout / no connection) get a dedicated
  /// message instead of the generic fallback.
  String _extractApiError(Object e, String fallback) {
    if (e is DioException) {
      switch (e.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return 'The server is waking up (free hosting can take ~1 min). If a retry says the email is already taken, your first attempt did register — just sign in.';
        case DioExceptionType.connectionError:
          return 'Could not reach the server. Check your internet connection and try again.';
        default:
          break;
      }
    }
    if (e is! DioException || e.response?.data == null) return fallback;
    final data = e.response!.data;
    if (data is Map<String, dynamic> && data['errors'] is Map<String, dynamic>) {
      final errors = data['errors'] as Map<String, dynamic>;
      if (errors.isNotEmpty) {
        final firstError = errors.values.first;
        if (firstError is List && firstError.isNotEmpty) {
          return firstError.first.toString();
        }
        return firstError.toString();
      }
    }
    if (data is Map<String, dynamic> && data['message'] is String) {
      final message = data['message'] as String;
      if (message.isNotEmpty) return message;
    }
    return fallback;
  }

  Future<void> continueAsGuest() async {
    currentUser = null;
    status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  Future<void> logout() async {
    await _authService.logout();
    final prefs = await SharedPreferences.getInstance();
    await _clearSession(prefs);
    await TokenStorage.clear();
    _sessionTimer?.cancel();
    _clearPendingRegistration();
    googleDraft = null;
    currentUser = null;
    status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  /// Applies an updated user object (e.g. after Edit Profile / Change
  /// Password) and notifies listeners so the UI reflects the change.
  void updateCurrentUser(UserModel user) {
    currentUser = user;
    _persistSession();
    notifyListeners();
  }

  Future<void> _persistSession() async {
    final user = currentUser;
    if (user == null) return;
    final prefs = await SharedPreferences.getInstance();
    final expiry = DateTime.now().add(sessionDuration);
    await prefs.setString(_sessionUserKey, jsonEncode(user.toJson()));
    await prefs.setInt(_sessionExpiryKey, expiry.millisecondsSinceEpoch);
    _scheduleExpiry(expiry);
  }

  Future<void> _saveApiTokens() => TokenStorage.save(
        accessToken: _authService.lastAccessToken,
        refreshToken: _authService.lastRefreshToken,
        expiresAt: _authService.lastExpiresAt,
      );

  void _scheduleExpiry(DateTime expiry) {
    _sessionTimer?.cancel();
    final delay = expiry.difference(DateTime.now());
    _sessionTimer =
        Timer(delay.isNegative ? Duration.zero : delay, _expireSession);
  }

  Future<void> _expireSession() async {
    final prefs = await SharedPreferences.getInstance();
    await _clearSession(prefs);
    await TokenStorage.clear();
    _clearPendingRegistration();
    currentUser = null;
    status = AuthStatus.unauthenticated;
    sessionExpired = true;
    notifyListeners();
  }

  Future<void> _clearSession(SharedPreferences prefs) async {
    await prefs.remove(_sessionUserKey);
    await prefs.remove(_sessionExpiryKey);
  }

  @override
  void dispose() {
    _sessionTimer?.cancel();
    super.dispose();
  }
}
