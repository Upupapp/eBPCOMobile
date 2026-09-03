import '../api/api_exception.dart';
import '../constants/app_constants.dart';
import '../constants/app_strings.dart';
import '../models/user_model.dart';
import '../services/local_storage_service.dart';

/// Mock credential/account source for the prototype's authentication flow.
/// Swap [MockAuthRepository] for a real HTTP-backed implementation once a
/// backend exists — [AuthProvider] only depends on this interface.
/// One field of a profile edit: left alone, or set to a value, or cleared.
///
/// A plain `String?` cannot carry this. Null would have to mean either "leave
/// it" or "clear it", and the server distinguishes them — absent leaves a
/// field alone, null clears it. Collapsing the two would take away the only
/// way a citizen can remove a middle name they do not have.
class FieldEdit {
  /// Leave whatever the office holds untouched.
  const FieldEdit.absent() : value = null, isPresent = false;

  /// Set the field, or clear it when [value] is null.
  const FieldEdit.set(this.value) : isPresent = true;

  /// Clear the field. The same as `FieldEdit.set(null)`, named for what it
  /// does at the call site.
  const FieldEdit.clear() : value = null, isPresent = true;

  /// Set from text the citizen typed: blank means clear.
  ///
  /// The Edit Profile screen sends every field on every save, so an empty box
  /// is the citizen saying they have none — not the caller declining to say.
  factory FieldEdit.fromInput(String text) {
    final trimmed = text.trim();
    return FieldEdit.set(trimmed.isEmpty ? null : trimmed);
  }

  final String? value;
  final bool isPresent;
}

/// What came back from a profile update.
class ProfileUpdate {
  const ProfileUpdate({
    required this.user,
    this.mobileVerificationCleared = false,
  });

  final UserModel user;

  /// The office reset contact verification because the number changed.
  ///
  /// Read from the server's own `mobileVerificationCleared`, not inferred by
  /// comparing numbers: pending challenges against the OLD number are deleted
  /// server-side too, and only the server knows it did that.
  final bool mobileVerificationCleared;
}

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
  /// Corrects the citizen's own details, and returns what the office now has.
  ///
  /// **`null` and absent mean different things, deliberately.** A field left
  /// out is untouched; a field sent as null is cleared. A citizen who typed a
  /// middle name by mistake, or has none, must be able to remove it — a right
  /// to correct that cannot remove is half a right. [FieldEdit] is how the
  /// difference survives a Dart call, where a plain `String?` cannot express
  /// both.
  ///
  /// Changing [mobileNumber] takes effect immediately and resets contact
  /// verification to **unverified** — not pending. The office has no message
  /// provider configured, so a code cannot be delivered at all today; under a
  /// pending model a number change would never take effect and a citizen who
  /// moved would be stranded on their old number permanently.
  ///
  /// Email is refused with a 400 and is not offered here. It is the sign-in
  /// identity, so changing it transfers who can reach the account rather than
  /// correcting a detail, and needs its own proof-of-control flow.
  Future<ProfileUpdate> updateProfile({
    FieldEdit firstName = const FieldEdit.absent(),
    FieldEdit middleName = const FieldEdit.absent(),
    FieldEdit lastName = const FieldEdit.absent(),
    FieldEdit mobileNumber = const FieldEdit.absent(),
    FieldEdit street = const FieldEdit.absent(),
    FieldEdit barangay = const FieldEdit.absent(),
    FieldEdit city = const FieldEdit.absent(),
    FieldEdit province = const FieldEdit.absent(),
    FieldEdit postalCode = const FieldEdit.absent(),
  });

  Future<void> deleteAccount();
}

class MockAuthRepository implements AuthRepository {
  @override
  Future<ProfileUpdate> updateProfile({
    FieldEdit firstName = const FieldEdit.absent(),
    FieldEdit middleName = const FieldEdit.absent(),
    FieldEdit lastName = const FieldEdit.absent(),
    FieldEdit mobileNumber = const FieldEdit.absent(),
    FieldEdit street = const FieldEdit.absent(),
    FieldEdit barangay = const FieldEdit.absent(),
    FieldEdit city = const FieldEdit.absent(),
    FieldEdit province = const FieldEdit.absent(),
    FieldEdit postalCode = const FieldEdit.absent(),
  }) async {
    // Mirrors the live endpoint's refusal so a mock build cannot succeed where
    // a real one is refused: an address the office cannot post to is worse
    // than none, because it gets acted on.
    if (postalCode.isPresent &&
        postalCode.value != null &&
        !RegExp(r'^\d{4}$').hasMatch(postalCode.value!)) {
      throw const ApiException(
        ApiFailure.rejected,
        'A postal code must be four digits.',
      );
    }
    await _storage.updateRegisteredProfile(
      firstName: firstName.value ?? '',
      lastName: lastName.value ?? '',
      mobileNumber: mobileNumber.value ?? '',
      middleName: middleName.value ?? '',
      street: street.value ?? '',
      province: province.value ?? '',
      city: city.value ?? '',
      barangay: barangay.value ?? '',
      postalCode: postalCode.value ?? '',
    );
    final current = await _hydrateRegisteredUser(
      await _storage.getRegisteredEmail() ?? AppStrings.mockEmail,
    );
    return ProfileUpdate(
      user: current,
      mobileVerificationCleared: mobileNumber.isPresent,
    );
  }

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
    street: '123 Rizal Street',
    barangay: 'San Isidro',
    city: 'Quezon City',
    province: 'Metro Manila',
    postalCode: '1100',
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
      middleName: await _storage.getRegisteredMiddleName() ?? '',
      lastName: await _storage.getRegisteredLastName() ?? '',
      email: registeredEmail,
      mobileNumber: await _storage.getRegisteredMobile() ?? '',
      // Null, not '': an account that predates PATCH /me has never been asked
      // for these, and that is not the same as having left them blank.
      street: await _storage.getRegisteredStreet(),
      province: await _storage.getRegisteredProvince(),
      city: await _storage.getRegisteredCity(),
      barangay: await _storage.getRegisteredBarangay(),
      postalCode: await _storage.getRegisteredPostalCode(),
    );
  }
}
