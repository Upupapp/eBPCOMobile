import 'package:flutter/material.dart';

import '../constants/app_strings.dart';
import '../models/user_model.dart';
import '../services/local_storage_service.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

/// Handles mock authentication state: session restore, login, registration,
/// and logout. No real network calls are made - everything is backed by
/// [LocalStorageService] for this frontend-only prototype.
class AuthProvider extends ChangeNotifier {
  AuthProvider({LocalStorageService? storageService})
    : _storage = storageService ?? LocalStorageService();

  final LocalStorageService _storage;

  AuthStatus _status = AuthStatus.unknown;
  bool _isLoading = false;
  String? _errorMessage;
  UserModel? _currentUser;
  bool _onboardingCompleted = false;

  AuthStatus get status => _status;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  UserModel? get currentUser => _currentUser;
  bool get isLoggedIn => _status == AuthStatus.authenticated;
  bool get onboardingCompleted => _onboardingCompleted;

  Future<void> loadSession() async {
    _onboardingCompleted = await _storage.isOnboardingCompleted();
    final loggedIn = await _storage.isLoggedIn();
    if (loggedIn) {
      await _hydrateCurrentUser();
      _status = AuthStatus.authenticated;
    } else {
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  Future<void> completeOnboarding() async {
    await _storage.setOnboardingCompleted(true);
    _onboardingCompleted = true;
    notifyListeners();
  }

  Future<void> _hydrateCurrentUser() async {
    final email = await _storage.getCurrentUserEmail();
    if (email == AppStrings.mockEmail) {
      _currentUser = const UserModel(
        firstName: 'Juan',
        lastName: 'Dela Cruz',
        email: AppStrings.mockEmail,
        mobileNumber: '09171234567',
      );
      return;
    }

    final registeredEmail = await _storage.getRegisteredEmail();
    if (email != null && email == registeredEmail) {
      _currentUser = UserModel(
        firstName: await _storage.getRegisteredFirstName() ?? 'User',
        lastName: await _storage.getRegisteredLastName() ?? '',
        email: registeredEmail!,
        mobileNumber: await _storage.getRegisteredMobile() ?? '',
      );
    }
  }

  Future<bool> login({
    required String email,
    required String password,
    required bool rememberMe,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 900));

    final normalizedEmail = email.trim().toLowerCase();
    final registeredEmail = await _storage.getRegisteredEmail();
    final registeredPassword = await _storage.getRegisteredPassword();

    final isMockMatch =
        normalizedEmail == AppStrings.mockEmail &&
        password == AppStrings.mockPassword;
    final isRegisteredMatch =
        registeredEmail != null &&
        normalizedEmail == registeredEmail &&
        password == registeredPassword;

    if (isMockMatch || isRegisteredMatch) {
      await _storage.setLoggedIn(true);
      await _storage.setRememberMe(rememberMe);
      await _storage.setCurrentUserEmail(normalizedEmail);
      await _hydrateCurrentUser();
      _status = AuthStatus.authenticated;
      _isLoading = false;
      notifyListeners();
      return true;
    }

    _errorMessage = 'Incorrect email or password. Please try again.';
    _status = AuthStatus.unauthenticated;
    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> register({
    required String firstName,
    required String lastName,
    required String email,
    required String mobileNumber,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 900));

    final normalizedEmail = email.trim().toLowerCase();
    if (normalizedEmail == AppStrings.mockEmail) {
      _errorMessage = 'This email address is already in use.';
      _isLoading = false;
      notifyListeners();
      return false;
    }

    await _storage.saveRegisteredUser(
      email: normalizedEmail,
      password: password,
      firstName: firstName,
      lastName: lastName,
      mobileNumber: mobileNumber,
    );

    _isLoading = false;
    notifyListeners();
    return true;
  }

  Future<void> logout() async {
    await _storage.clearSession();
    _currentUser = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
