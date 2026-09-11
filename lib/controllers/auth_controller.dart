import 'package:flutter/foundation.dart';
import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/token_storage.dart';

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

  bool get isGuest => currentUser == null;
  bool get isClient => currentUser?.role == UserRole.client;
  bool get isProvider => currentUser?.role == UserRole.provider;

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
      await _persistSession();
      notifyListeners();
      return true;
    } catch (e) {
      status = AuthStatus.unauthenticated;
      errorMessage = 'Unable to sign in. Please try again.';
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
  }) async {
    status = AuthStatus.authenticating;
    notifyListeners();
    try {
      currentUser = await _authService.register(
        firstName: firstName,
        lastName: lastName,
        email: email,
        password: password,
        role: role,
      );
      await _saveApiTokens();
      status = AuthStatus.authenticated;
      sessionExpired = false;
      await _persistSession();
      notifyListeners();
      return true;
    } catch (e) {
      status = AuthStatus.unauthenticated;
      errorMessage = 'Registration failed. Please try again.';
      notifyListeners();
      return false;
    }
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
