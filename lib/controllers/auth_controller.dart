import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

enum AuthStatus { unauthenticated, authenticating, authenticated }

/// Session state — who's signed in (if anyone) and as what role.
/// Backed by [AuthService] placeholders; swap for real token persistence
/// (SharedPreferences / secure storage) once the backend exists.
class AuthController extends ChangeNotifier {
  final AuthService _authService = AuthService();

  AuthStatus status = AuthStatus.unauthenticated;
  UserModel? currentUser;
  String? errorMessage;

  bool get isGuest => currentUser == null;
  bool get isClient => currentUser?.role == UserRole.client;
  bool get isProvider => currentUser?.role == UserRole.provider;

  Future<bool> login(String email, String password) async {
    status = AuthStatus.authenticating;
    errorMessage = null;
    notifyListeners();
    try {
      currentUser = await _authService.login(email: email, password: password);
      status = AuthStatus.authenticated;
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
      status = AuthStatus.authenticated;
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
    currentUser = null;
    status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  /// Applies an updated user object (e.g. after Edit Profile / Change
  /// Password) and notifies listeners so the UI reflects the change.
  void updateCurrentUser(UserModel user) {
    currentUser = user;
    notifyListeners();
  }
}
