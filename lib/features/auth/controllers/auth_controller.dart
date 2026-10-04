import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../../core/models/account_restriction.dart';
import 'package:dio/dio.dart';
import 'dart:async';
import 'dart:convert';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/auth_results.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/google_sign_in_errors.dart';
import '../../../core/config/app_config.dart';
import '../../../core/services/api_client.dart';
import '../../../core/services/token_storage.dart';

enum AuthStatus { unauthenticated, authenticating, authenticated }

/// What a "Continue with Google" tap produced.
enum GoogleAuthOutcome {
  /// Signed in; the session is live.
  signedIn,

  /// This Google account has no SkillServe account yet — send the user to
  /// the profile form ([googleDraft] holds the prefill).
  registrationRequired,

  /// The Google account has a SkillServe account; ask for its password and
  /// call [AuthController.signInWithGooglePassword]. Google alone never
  /// signs in.
  passwordRequired,

  /// The user dismissed the Google account picker. Nothing to report.
  cancelled,

  /// Something failed; [AuthController.errorMessage] explains it.
  failed,
}

/// What confirming the emailed sign-up code produced.
enum OtpOutcome {
  /// The address is confirmed; the password is chosen next (/create-password).
  passwordRequired,

  /// A sign-up parked by an older app version, which already had its
  /// password: the account exists and the session is live.
  signedIn,

  /// Wrong or expired code, or a network failure; see [AuthController.errorMessage].
  failed,
}

/// Session state — who's signed in (if anyone) and as what role.
///
/// A session lasts until the user signs out. Closing the app does not end it:
/// the signed-in account is cached locally and restored at launch, and the
/// short-lived access token is renewed from the refresh token as needed (see
/// [ApiClient]). Only the server can end a session early — a sign-out on the
/// server, a suspension or a deleted account — and then [sessionExpired] is set
/// so the login screen can say why.
class AuthController extends ChangeNotifier {
  AuthController() {
    ApiClient.onSessionRevoked = _onSessionRevoked;
  }

  final AuthService _authService = AuthService();

  AuthStatus status = AuthStatus.unauthenticated;
  UserModel? currentUser;
  String? errorMessage;

  /// True when the server ended the session (not when the user signed out),
  /// so the login screen can explain why they are there.
  bool sessionExpired = false;

  /// Set when the server refused the account (suspended or banned) — at
  /// sign-in or mid-session — so the login screen can explain why.
  AccountRestriction? restriction;

  static const _sessionUserKey = 'skillserve.session.user';

  /// Written by earlier builds that timed sessions out after eight hours;
  /// removed at launch so it cannot linger.
  static const _legacySessionExpiryKey = 'skillserve.session.expiresAt';

  final Completer<void> _ready = Completer<void>();

  /// Completes once launch has decided whether someone is signed in. The
  /// splash screen waits on this instead of guessing with a fixed delay, so a
  /// slow backend can never make a signed-in user look signed out.
  Future<void> get ready => _ready.future;

  /// Google OAuth **Web** client ID (see [AppConfig.googleWebClientId]).
  /// Required so google_sign_in returns an ID token on Android.
  static const _googleServerClientId = AppConfig.googleWebClientId;

  bool get isGuest => currentUser == null;
  bool get isClient => currentUser?.role == UserRole.client;
  bool get isProvider => currentUser?.role == UserRole.provider;

  /// Sign-up runs details -> emailed code -> password. Until the password is
  /// in, the registration has NOT produced a session: no tokens are kept,
  /// [status] stays [AuthStatus.unauthenticated], and the router pins the
  /// user to /verify-email, then to /create-password, so the app cannot be
  /// reached half-registered.
  bool _pendingEmailVerification = false;
  bool _pendingPasswordSetup = false;
  String? _pendingEmail;

  /// Returned when the sign-up started; proves this device started it, so
  /// it is needed to set the password and to cancel. Memory only.
  String? _registrationToken;

  /// Only for a sign-up parked by an older app version and resumed from the
  /// login screen: the password typed there is what can cancel it.
  String? _pendingPassword;

  bool get requiresEmailVerification => _pendingEmailVerification;

  /// The code is confirmed and the password is still to be chosen.
  bool get requiresPasswordSetup => _pendingPasswordSetup;

  /// The address awaiting its 6-digit code, so the OTP screen can be
  /// reached without carrying the email through the route.
  String? get pendingEmail => _pendingEmail;

  /// Google's prefill for the profile form, set when [loginWithGoogle]
  /// returns [GoogleAuthOutcome.registrationRequired]. Nothing exists
  /// server-side while this is set — dropping it cancels the sign-up.
  GoogleProfileDraft? googleDraft;

  /// The account Google picked, set when [loginWithGoogle] returns
  /// [GoogleAuthOutcome.passwordRequired]; its password is asked for next.
  String? googlePasswordEmail;

  /// The Google ID token waiting for that password. Google tokens last about
  /// an hour, plenty for typing a password; memory only.
  String? _googleIdToken;

  /// Restores the session saved by the last sign-in.
  ///
  /// The cached account is used at once, so the app opens straight onto the
  /// user's home screen even offline or while the free-tier backend is still
  /// waking up. The account is then refreshed from the API in the background.
  /// Nothing here signs the user out except a refusal from the server.
  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_legacySessionExpiryKey);

      final hasTokens = await TokenStorage.readAccessToken() != null ||
          await TokenStorage.readRefreshToken() != null;
      if (!hasTokens) return;

      final cached = _cachedUser(prefs);
      if (cached != null) {
        currentUser = cached;
        status = AuthStatus.authenticated;
        notifyListeners();
        // Not awaited: the user is already in; this only brings them up to date.
        unawaited(_refreshCurrentUser());
        return;
      }

      // No cached account (a build that predates the cache): the API has to say
      // who this is before the app can pick a home screen.
      await _refreshCurrentUser();
    } finally {
      if (!_ready.isCompleted) _ready.complete();
    }
  }

  UserModel? _cachedUser(SharedPreferences prefs) {
    final raw = prefs.getString(_sessionUserKey);
    if (raw == null) return null;
    try {
      return UserModel.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  /// Reloads the signed-in account from the API. A network failure keeps the
  /// cached session; a 401 has already been handled by [ApiClient], which
  /// tried the refresh token first and only then called [_onSessionRevoked].
  /// Re-reads the account from the server — after a notification says an
  /// administrator changed it (verification, provider suspension).
  Future<void> refreshCurrentUser() {
    if (status != AuthStatus.authenticated) return Future.value();
    return _refreshCurrentUser();
  }

  Future<void> _refreshCurrentUser() async {
    try {
      final user = await _authService.getCurrentUser();
      currentUser = user;
      status = AuthStatus.authenticated;
      await _persistSession();
      notifyListeners();
    } catch (_) {
      // Offline, or the backend is still waking: stay signed in.
    }
  }

  /// The server ended the session. Clears it locally and returns to login.
  Future<void> _onSessionRevoked(AccountRestriction? restriction) async {
    if (restriction != null) this.restriction = restriction;
    if (status != AuthStatus.authenticated && currentUser == null) {
      if (restriction != null) notifyListeners();
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    await _clearSession(prefs);
    _clearPendingRegistration();
    currentUser = null;
    status = AuthStatus.unauthenticated;
    sessionExpired = true;
    notifyListeners();
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
      restriction = null;
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
      restriction = AccountRestriction.fromError(e);
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
  /// no account and no session exist until [verifyOtp] confirms the code and
  /// [completeRegistration] sets the password, so backing out leaves the
  /// email free to use again.
  ///
  /// [signUpDetails] carries what was read off the National ID: `birthday`
  /// and the structured `address_details`.
  Future<bool> register({
    required String firstName,
    required String lastName,
    required String email,
    required UserRole role,
    String? businessName,
    String specialization = '',
    int experienceYears = 0,
    String? bio,
    Map<String, dynamic> signUpDetails = const {},
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
              businessName: businessName,
              specialization: specialization.isEmpty ? 'General Services' : specialization,
              experienceYears: experienceYears,
              bio: bio,
              signUpDetails: signUpDetails,
            )
          : await _authService.register(
              firstName: firstName,
              lastName: lastName,
              email: email,
              signUpDetails: signUpDetails,
            );
      await _startPendingRegistration(pending);
      notifyListeners();
      return true;
    } catch (e) {
      status = AuthStatus.unauthenticated;
      // The address already has a sign-up waiting on a code that is still
      // valid (a double tap): resume that verification instead of starting
      // over. The registration token from the first tap is still held.
      final pendingEmail = _pendingVerificationEmail(e);
      if (pendingEmail != null) {
        _pendingEmailVerification = true;
        _pendingEmail = pendingEmail;
        errorMessage = _extractApiError(e, 'Registration failed. Please try again.');
        notifyListeners();
        return true;
      }
      errorMessage = _extractApiError(e, 'Registration failed. Please try again.');
      notifyListeners();
      return false;
    }
  }

  /// The sign-up is parked server-side and a code is on its way: pin the
  /// user to the code screen with no session.
  Future<void> _startPendingRegistration(PendingRegistration pending) async {
    _pendingEmailVerification = true;
    _pendingPasswordSetup = false;
    _pendingEmail = pending.email;
    _registrationToken = pending.registrationToken;
    _pendingPassword = null;
    currentUser = null;
    status = AuthStatus.unauthenticated;
    sessionExpired = false;
    restriction = null;
    await TokenStorage.clear();
  }

  /// Confirms the 6-digit code emailed at registration. The password is
  /// chosen next ([completeRegistration]); a sign-up parked by an older app
  /// version already has one, so the account is created here instead.
  Future<OtpOutcome> verifyOtp(String email, String code) async {
    status = AuthStatus.authenticating;
    errorMessage = null;
    notifyListeners();
    try {
      final result = await _authService.verifyOtp(email: email, code: code);
      if (result.requiresPassword) {
        // Moves the router's pin from /verify-email to /create-password.
        _pendingEmailVerification = false;
        _pendingPasswordSetup = true;
        _pendingEmail = email;
        status = AuthStatus.unauthenticated;
        notifyListeners();
        return OtpOutcome.passwordRequired;
      }
      currentUser = result.user;
      await _signedIn();
      return OtpOutcome.signedIn;
    } catch (e) {
      status = AuthStatus.unauthenticated;
      errorMessage = _extractApiError(e, 'Verification failed. Please try again.');
      notifyListeners();
      return OtpOutcome.failed;
    }
  }

  /// The last sign-up step: sets the password, which creates the account
  /// and signs in.
  Future<bool> completeRegistration(String password) async {
    final email = _pendingEmail;
    final token = _registrationToken;
    if (email == null || token == null) {
      errorMessage = 'Your sign-up expired. Please start again.';
      notifyListeners();
      return false;
    }

    status = AuthStatus.authenticating;
    errorMessage = null;
    notifyListeners();
    try {
      currentUser = await _authService.completeRegistration(
        email: email,
        registrationToken: token,
        password: password,
      );
      await _signedIn();
      return true;
    } catch (e) {
      status = AuthStatus.unauthenticated;
      errorMessage = _extractApiError(e, 'We could not create your account. Please try again.');
      notifyListeners();
      return false;
    }
  }

  /// A session was just issued: keep it and release the sign-up pins.
  Future<void> _signedIn() async {
    await _saveApiTokens();
    _clearPendingRegistration();
    googleDraft = null;
    _clearGooglePassword();
    status = AuthStatus.authenticated;
    sessionExpired = false;
    restriction = null;
    await _persistSession();
    notifyListeners();
  }

  /// Called when the user backs out of the code or password screen. Discards
  /// the parked sign-up server-side so the email is immediately reusable,
  /// and drops it locally.
  Future<void> cancelPendingVerification() async {
    final email = _pendingEmail;
    final token = _registrationToken;
    final password = _pendingPassword;

    _clearPendingRegistration();
    await TokenStorage.clear();
    currentUser = null;
    status = AuthStatus.unauthenticated;
    errorMessage = null;
    notifyListeners();

    if (email != null && (token != null || password != null)) {
      try {
        await _authService.cancelRegistration(
            email: email, registrationToken: token, password: password);
      } catch (_) {
        // Server unreachable: the parked sign-up lives on until it expires,
        // but registering again simply replaces it, so nothing is lost.
      }
    }
  }

  void _clearPendingRegistration() {
    _pendingEmailVerification = false;
    _pendingPasswordSetup = false;
    _pendingEmail = null;
    _registrationToken = null;
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

  /// Google Sign-In: obtains an ID token on device and asks the backend who
  /// it belongs to.
  ///
  /// An account already linked to this Google identity — or one that simply
  /// owns the same (Google-verified) email — still needs its password:
  /// [GoogleAuthOutcome.passwordRequired], then [signInWithGooglePassword].
  /// A Google account with no SkillServe account creates nothing: the caller
  /// is told to show the profile form.
  Future<GoogleAuthOutcome> loginWithGoogle() async {
    status = AuthStatus.authenticating;
    errorMessage = null;
    googleDraft = null;
    _clearGooglePassword();
    notifyListeners();
    try {
      final account = await _pickGoogleAccount();
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

      if (result.requiresPassword) {
        _googleIdToken = idToken;
        googlePasswordEmail = result.passwordEmail;
        status = AuthStatus.unauthenticated;
        notifyListeners();
        return GoogleAuthOutcome.passwordRequired;
      }

      currentUser = result.user;
      await _signedIn();
      return GoogleAuthOutcome.signedIn;
    } catch (e) {
      status = AuthStatus.unauthenticated;
      if (isGoogleSignInCancelled(e)) {
        notifyListeners();
        return GoogleAuthOutcome.cancelled;
      }
      restriction = AccountRestriction.fromError(e);
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

  /// Opens the Google account picker. Play services' NETWORK_ERROR is often
  /// a passing hiccup (Play services still connecting), so it is retried once
  /// before the user sees it.
  Future<GoogleSignInAccount?> _pickGoogleAccount() async {
    final google = GoogleSignIn(serverClientId: _googleServerClientId);
    try {
      return await google.signIn();
    } catch (e) {
      if (!isGoogleNetworkError(e)) rethrow;
      await Future<void>.delayed(const Duration(seconds: 1));
      return google.signIn();
    }
  }

  /// Finishes a Google sign-in with the account password, after
  /// [loginWithGoogle] returned [GoogleAuthOutcome.passwordRequired].
  Future<bool> signInWithGooglePassword(String password) async {
    final idToken = _googleIdToken;
    if (idToken == null) {
      errorMessage = 'Your Google sign-in expired. Please try again.';
      notifyListeners();
      return false;
    }

    status = AuthStatus.authenticating;
    errorMessage = null;
    notifyListeners();
    try {
      final result = await _authService.loginWithGoogle(idToken: idToken, password: password);
      currentUser = result.user;
      await _signedIn();
      return true;
    } catch (e) {
      status = AuthStatus.unauthenticated;
      restriction = AccountRestriction.fromError(e);
      errorMessage = _extractApiError(e, 'Google sign-in failed. Please try again.');
      notifyListeners();
      return false;
    }
  }

  /// The user closed the password prompt: forget the Google token.
  void cancelGooglePassword() {
    _clearGooglePassword();
    errorMessage = null;
    notifyListeners();
  }

  void _clearGooglePassword() {
    _googleIdToken = null;
    googlePasswordEmail = null;
  }

  /// Starts the sign-up for the Google identity held in [googleDraft], using
  /// the details the user typed on the profile form. Like an email sign-up,
  /// a code then goes to the Google address and the password comes after it.
  Future<bool> completeGoogleRegistration({
    required String firstName,
    required String lastName,
    required UserRole role,
    String? businessName,
    String specialization = '',
    int experienceYears = 0,
    String? bio,
    Map<String, dynamic> signUpDetails = const {},
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
      final pending = await _authService.completeGoogleRegistration(
        idToken: draft.idToken,
        firstName: firstName,
        lastName: lastName,
        role: role,
        businessName: businessName,
        specialization: specialization,
        experienceYears: experienceYears,
        bio: bio,
        signUpDetails: signUpDetails,
      );
      googleDraft = null;
      await _startPendingRegistration(pending);
      notifyListeners();
      return true;
    } catch (e) {
      status = AuthStatus.unauthenticated;
      // A double tap: the code from the first one is still valid.
      final pendingEmail = _pendingVerificationEmail(e);
      if (pendingEmail != null && _registrationToken != null) {
        googleDraft = null;
        _pendingEmailVerification = true;
        _pendingEmail = pendingEmail;
        errorMessage = _extractApiError(e, 'A code was already sent.');
        notifyListeners();
        return true;
      }
      errorMessage = _extractApiError(e, 'We could not start your sign-up. Please try again.');
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
    if (e is PlatformException) return googleSignInErrorMessage(e);
    return 'Google sign-in failed. Please try again, or use your email.';
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
    try {
      await _authService.logout();
    } catch (_) {
      // Signing out must work offline too; the server token simply expires.
    }
    final prefs = await SharedPreferences.getInstance();
    await _clearSession(prefs);
    await TokenStorage.clear();
    sessionExpired = false;
    _clearPendingRegistration();
    googleDraft = null;
    _clearGooglePassword();
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

  /// Caches the signed-in account so the next launch can restore it without
  /// waiting on the network. There is deliberately no expiry: a session lasts
  /// until the user signs out or the server revokes it.
  Future<void> _persistSession() async {
    final user = currentUser;
    if (user == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sessionUserKey, jsonEncode(user.toJson()));
  }

  Future<void> _saveApiTokens() => TokenStorage.save(
        accessToken: _authService.lastAccessToken,
        refreshToken: _authService.lastRefreshToken,
        expiresAt: _authService.lastExpiresAt,
      );

  Future<void> _clearSession(SharedPreferences prefs) async {
    await prefs.remove(_sessionUserKey);
    await prefs.remove(_legacySessionExpiryKey);
  }

  @override
  void dispose() {
    if (ApiClient.onSessionRevoked == _onSessionRevoked) {
      ApiClient.onSessionRevoked = null;
    }
    super.dispose();
  }
}
