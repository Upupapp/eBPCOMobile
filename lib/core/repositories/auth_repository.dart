import '../constants/app_constants.dart';
import '../constants/app_strings.dart';
import '../models/user_model.dart';
import '../services/local_storage_service.dart';

/// Mock credential/account source for the prototype's authentication flow.
/// Swap [MockAuthRepository] for a real HTTP-backed implementation once a
/// backend exists — [AuthProvider] only depends on this interface.
abstract class AuthRepository {
  Future<UserModel?> authenticate({
    required String email,
    required String password,
  });

  Future<bool> registerAccount({
    required String firstName,
    required String lastName,
    required String email,
    required String mobileNumber,
    required String password,
  });

  Future<UserModel?> hydrateUser(String email);

  /// Erases the citizen's account.
  ///
  /// **Apple Guideline 5.1.1(v)**: an app that lets someone create an account
  /// must let them delete it from inside the app. Not an email address to
  /// write to, not a web form — the same app.
  ///
  /// It is also RA 10173 §16(e), the right to erasure, which is the reason
  /// that matters here: a citizen who filed a permit gave this office their
  /// TIN, their address and their government ID, and the law says they may
  /// take it back.
  ///
  /// The server answers **202**. Erasure is queued rather than immediate, so
  /// this returns when the request is accepted, not when the data is gone —
  /// and the app must not tell the citizen otherwise.
  Future<void> deleteAccount();
}

class MockAuthRepository implements AuthRepository {
  @override
  Future<void> deleteAccount() async {
    // Nothing to erase: the mock account is a constant, not a record.
  }

  MockAuthRepository({LocalStorageService? storageService})
    : _storage = storageService ?? LocalStorageService();

  final LocalStorageService _storage;

  static final _mockUser = UserModel(
    firstName: 'Juan',
    middleName: 'Santos',
    lastName: 'Dela Cruz',
    email: AppStrings.mockEmail,
    mobileNumber: '09171234567',
    address: '123 Rizal Street',
    barangay: 'San Isidro',
    city: 'Quezon City',
    province: 'Metro Manila',
    zipCode: '1100',
    accountType: 'Individual Applicant',
    accountStatus: AccountStatus.verified,
    registeredSince: DateTime(2024, 3, 12),
  );

  @override
  Future<UserModel?> authenticate({
    required String email,
    required String password,
  }) async {
    await Future.delayed(AppConstants.mockNetworkDelay);
    final normalizedEmail = email.trim().toLowerCase();

    if (normalizedEmail == AppStrings.mockEmail &&
        password == AppStrings.mockPassword) {
      return _mockUser;
    }

    final registeredEmail = await _storage.getRegisteredEmail();
    if (registeredEmail != null && normalizedEmail == registeredEmail) {
      // The comparison happens inside the storage service against a PBKDF2
      // verifier; no caller ever holds the stored material.
      if (await _storage.isRegisteredPassword(password)) {
        return _hydrateRegisteredUser(registeredEmail);
      }
    }

    return null;
  }

  @override
  Future<bool> registerAccount({
    required String firstName,
    required String lastName,
    required String email,
    required String mobileNumber,
    required String password,
  }) async {
    await Future.delayed(AppConstants.mockNetworkDelay);
    final normalizedEmail = email.trim().toLowerCase();
    if (normalizedEmail == AppStrings.mockEmail) {
      return false;
    }

    await _storage.saveRegisteredUser(
      email: normalizedEmail,
      password: password,
      firstName: firstName,
      lastName: lastName,
      mobileNumber: mobileNumber,
    );
    return true;
  }

  @override
  Future<UserModel?> hydrateUser(String email) async {
    if (email == AppStrings.mockEmail) return _mockUser;

    final registeredEmail = await _storage.getRegisteredEmail();
    if (email == registeredEmail) {
      return _hydrateRegisteredUser(registeredEmail!);
    }
    return null;
  }

  Future<UserModel> _hydrateRegisteredUser(String registeredEmail) async {
    return UserModel(
      firstName: await _storage.getRegisteredFirstName() ?? 'User',
      lastName: await _storage.getRegisteredLastName() ?? '',
      email: registeredEmail,
      mobileNumber: await _storage.getRegisteredMobile() ?? '',
    );
  }
}
