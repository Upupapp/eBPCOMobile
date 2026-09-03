import 'package:flutter/material.dart';

import '../models/user_model.dart';
import '../repositories/auth_repository.dart';
import '../services/local_storage_service.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

/// Handles mock authentication state: session restore, login, registration,
/// and logout. Credential/account logic lives in [AuthRepository];
/// [LocalStorageService] only persists session/device state, so swapping in
/// a real backend later means providing a different [AuthRepository].
class AuthProvider extends ChangeNotifier {
  AuthProvider({
    AuthRepository? authRepository,
    LocalStorageService? storageService,
  }) : _storage = storageService ?? LocalStorageService(),
       _repository =
           authRepository ??
           MockAuthRepository(
             storageService: storageService ?? LocalStorageService(),
           );

  final LocalStorageService _storage;
  final AuthRepository _repository;

  AuthStatus _status = AuthStatus.unknown;
  bool _isLoading = false;
  String? _errorMessage;
  UserModel? _currentUser;
  bool _onboardingCompleted = false;
  String? _rememberedEmail;

  AuthStatus get status => _status;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  UserModel? get currentUser => _currentUser;
  bool get isLoggedIn => _status == AuthStatus.authenticated;
  bool get onboardingCompleted => _onboardingCompleted;

  /// Email remembered from a previous "Remember me" login, if any, so
  /// [LoginScreen] can prefill it.
  String? get rememberedEmail => _rememberedEmail;

  Future<void> loadSession() async {
    // An install upgraded from a build that stored the password in plain text
    // still has it on disk. Clear it before anything else touches storage.
    await _storage.purgeLegacyPlainTextPassword();
    _onboardingCompleted = await _storage.isOnboardingCompleted();
    _rememberedEmail = await _storage.getRememberedEmail();
    final loggedIn = await _storage.isLoggedIn();
    if (loggedIn) {
      final email = await _storage.getCurrentUserEmail();
      _currentUser = email != null
          ? await _repository.hydrateUser(email)
          : null;
      await _applySavedPhoto();
      _status = AuthStatus.authenticated;
    } else {
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  /// Re-applies the persisted profile photo path (if any) to
  /// [_currentUser] — [_repository.hydrateUser]/[_repository.authenticate]
  /// don't know about the photo, since it's saved separately by
  /// [ProfilePhotoService], not part of the mock account record itself.
  Future<void> _applySavedPhoto() async {
    final user = _currentUser;
    if (user == null) return;
    final savedPath = await _storage.getProfilePhotoPath();
    if (savedPath == null) return;
    _currentUser = user.copyWith(photoPath: savedPath);
  }

  Future<void> completeOnboarding() async {
    await _storage.setOnboardingCompleted(true);
    _onboardingCompleted = true;
    notifyListeners();
  }

  /// What to tell the applicant when sign-in or registration could not reach
  /// the server at all.
  ///
  /// Deliberately not the exception's own text: a `SocketException` or a
  /// stack trace on the sign-in screen tells the applicant nothing they can
  /// act on. What matters is that this is not the same as being turned away —
  /// saying "incorrect email or password" when the request never arrived
  /// would send someone to reset a password that was fine.
  static const String _couldNotReachServer =
      'Could not reach the server. Check your connection and try again.';

  Future<bool> login({
    required String email,
    required String password,
    required bool rememberMe,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final UserModel? user;
    try {
      user = await _repository.authenticate(email: email, password: password);
    } catch (_) {
      // Without this the button spun forever on any transport failure: the
      // throw skipped every `_isLoading = false` below it, and the applicant
      // got no message at all — the one screen where that is least affordable.
      _errorMessage = _couldNotReachServer;
      _status = AuthStatus.unauthenticated;
      _isLoading = false;
      notifyListeners();
      return false;
    }

    if (user != null) {
      await _storage.setLoggedIn(true);
      await _storage.setRememberMe(rememberMe);
      await _storage.setCurrentUserEmail(user.email);
      await _storage.setRememberedEmail(rememberMe ? user.email : null);
      _rememberedEmail = rememberMe ? user.email : null;
      _currentUser = user;
      await _applySavedPhoto();
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

    final bool success;
    try {
      success = await _repository.registerAccount(
        firstName: firstName,
        lastName: lastName,
        email: email,
        mobileNumber: mobileNumber,
        password: password,
      );
    } catch (_) {
      _errorMessage = _couldNotReachServer;
      _isLoading = false;
      notifyListeners();
      return false;
    }

    if (!success) {
      _errorMessage = 'This email address is already in use.';
    }
    _isLoading = false;
    notifyListeners();
    return success;
  }

  /// Corrects the citizen's own details with the office.
  ///
  /// **Sent, since 2026-09-03.** It wrote three fields to the device, dropped
  /// the rest, returned true, and told nobody: the office kept whatever it had
  /// while the screen said "Profile updated successfully". `PATCH /me` exists
  /// now and this calls it.
  ///
  /// Every field is sent on every save, blank meaning cleared, because the
  /// screen shows them all and an empty box is the citizen saying they have
  /// none. Absent is reserved for a caller that genuinely declines to say.
  ///
  /// Returns the office's own record, or throws. It cannot report a success
  /// that did not happen.
  Future<ProfileUpdate> updateProfile({
    required String firstName,
    String middleName = '',
    required String lastName,
    required String mobileNumber,
    String street = '',
    String province = '',
    String city = '',
    String barangay = '',
    String postalCode = '',
  }) async {
    final update = await _repository.updateProfile(
      firstName: FieldEdit.fromInput(firstName),
      middleName: FieldEdit.fromInput(middleName),
      lastName: FieldEdit.fromInput(lastName),
      mobileNumber: FieldEdit.fromInput(mobileNumber),
      street: FieldEdit.fromInput(street),
      province: FieldEdit.fromInput(province),
      city: FieldEdit.fromInput(city),
      barangay: FieldEdit.fromInput(barangay),
      postalCode: FieldEdit.fromInput(postalCode),
    );

    // The office's record, not the text the citizen typed. They differ
    // whenever the server normalises something, and the office's version is
    // the one the notices will be posted to.
    _currentUser = update.user;
    notifyListeners();
    return update;
  }

  Future<bool> updateProfilePhoto(String? photoPath) async {
    final user = _currentUser;
    if (user == null) return false;

    await _storage.setProfilePhotoPath(photoPath);
    _currentUser = user.copyWith(photoPath: photoPath);
    notifyListeners();
    return true;
  }

  Future<void> logout() async {
    await _storage.clearSession();
    _currentUser = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  /// Erases the account, then signs out.
  ///
  /// Apple Guideline 5.1.1(v) and RA 10173 §16(e). Returns false and leaves
  /// the citizen signed in when the request failed, because the alternative —
  /// signing them out of an account that still exists — reads as success.
  ///
  /// The local session is cleared through the same path as [logout] so a
  /// deleted account leaves nothing on the device: the token, the remembered
  /// email, the cached profile photo and the drafts all go with it.
  Future<bool> deleteAccount() async {
    try {
      await _repository.deleteAccount();
    } catch (error) {
      _errorMessage =
          'Could not delete your account. Check your connection and try '
          'again — nothing has been deleted.';
      notifyListeners();
      return false;
    }
    await logout();
    return true;
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
