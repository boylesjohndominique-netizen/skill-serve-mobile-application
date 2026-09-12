import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'dart:async';
import 'dart:convert';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../../../core/config/app_config.dart';
import '../../../core/services/token_storage.dart';

enum AuthStatus { unauthenticated, authenticating, authenticated }

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
      errorMessage = _extractApiError(e, 'Unable to sign in. Please try again.');
      notifyListeners();
      return false;
    }
  }

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
    notifyListeners();
    try {
      currentUser = role == UserRole.provider
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
      // Registration does NOT create a usable session: the backend issued
      // tokens, but the email is still unverified, so they are discarded.
      // The user stays [AuthStatus.unauthenticated] and pinned to the OTP
      // screen; a real session is created only after the code is verified.
      _pendingEmailVerification = true;
      _pendingEmail = currentUser!.email;
      _pendingPassword = password;
      status = AuthStatus.unauthenticated;
      sessionExpired = false;
      await TokenStorage.clear();
      notifyListeners();
      return true;
    } catch (e) {
      status = AuthStatus.unauthenticated;
      errorMessage = _extractApiError(e, 'Registration failed. Please try again.');
      notifyListeners();
      return false;
    }
  }

  /// Verifies the account email with the 6-digit OTP emailed at
  /// registration. For a pending registration this activates the session
  /// (a fresh login is performed so real tokens are stored); returns true
  /// and refreshes [currentUser] on success.
  Future<bool> verifyOtp(String email, String code) async {
    status = AuthStatus.authenticating;
    errorMessage = null;
    notifyListeners();
    try {
      final user = await _authService.verifyOtp(email: email, code: code);
      if (currentUser?.email.toLowerCase() == user.email.toLowerCase()) {
        currentUser = user;
      }
      if (_pendingEmailVerification) {
        final pendingEmail = _pendingEmail ?? email;
        final pendingPassword = _pendingPassword;
        _clearPendingRegistration();
        if (pendingPassword != null) {
          try {
            // The verify-otp response carries no tokens, so perform a real
            // login now that the email is verified. Password lived only in
            // memory for this hand-off and is cleared above.
            currentUser =
                await _authService.login(email: pendingEmail, password: pendingPassword);
            await _saveApiTokens();
            status = AuthStatus.authenticated;
            sessionExpired = false;
            await _persistSession();
            notifyListeners();
            return true;
          } catch (_) {
            currentUser = null;
            status = AuthStatus.unauthenticated;
            errorMessage = 'Email verified! Please sign in with your new account.';
            notifyListeners();
            return true;
          }
        }
      }
      status =
          currentUser == null ? AuthStatus.unauthenticated : AuthStatus.authenticated;
      notifyListeners();
      return true;
    } catch (e) {
      status =
          currentUser == null ? AuthStatus.unauthenticated : AuthStatus.authenticated;
      errorMessage = _extractApiError(e, 'Verification failed. Please try again.');
      notifyListeners();
      return false;
    }
  }

  /// Called when the user backs out of the OTP screen. Deletes the
  /// unverified account server-side (so the email becomes reusable) and
  /// drops the half-created registration locally. The password is kept
  /// only for this call and cleared afterwards.
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
        // Server unreachable: the unverified account stays and the next
        // register attempt will say the email is taken — acceptable.
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
  /// SkillServe session. Creates the account on first sign-in.
  Future<bool> loginWithGoogle() async {
    status = AuthStatus.authenticating;
    errorMessage = null;
    notifyListeners();
    try {
      final google = GoogleSignIn(serverClientId: _googleServerClientId);
      final account = await google.signIn();
      if (account == null) {
        status = AuthStatus.unauthenticated;
        notifyListeners();
        return false;
      }
      final auth = await account.authentication;
      final idToken = auth.idToken;
      if (idToken == null) {
        status = AuthStatus.unauthenticated;
        errorMessage = 'Google sign-in did not return a token. Ensure Google Play services are up to date.';
        notifyListeners();
        return false;
      }
      currentUser = await _authService.loginWithGoogle(idToken: idToken);
      await _saveApiTokens();
      status = AuthStatus.authenticated;
      sessionExpired = false;
      _clearPendingRegistration();
      await _persistSession();
      notifyListeners();
      return true;
    } catch (e) {
      status = AuthStatus.unauthenticated;
      errorMessage = _describeGoogleError(e);
      notifyListeners();
      return false;
    } finally {
      // End the Google session so account switching stays possible.
      try {
        await GoogleSignIn().signOut();
      } catch (_) {}
    }
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
