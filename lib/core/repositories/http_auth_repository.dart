import '../api/api_client.dart';
import '../api/idempotency_key.dart';
import '../api/api_exception.dart';
import '../models/user_model.dart';
import '../services/secure_session_store.dart';
import 'auth_repository.dart';

/// Authentication against the eBPCO API.
///
/// The mock implementation beside this one verified a PBKDF2 hash held on the
/// device. That was an honest placeholder for a server that did not exist; now
/// that one does, the device holds no verifier and makes no judgement about
/// whether credentials are correct. It asks, and it stores what it is given.
class HttpAuthRepository implements AuthRepository {
  HttpAuthRepository(this._api, this._session);

  final ApiClient _api;
  final SessionStore _session;

  @override
  Future<UserModel?> authenticate({
    required String email,
    required String password,
  }) async {
    try {
      final tokens = await _api.post(
        '/auth/token',
        body: {'grantType': 'password', 'email': email, 'password': password},
        // One key per attempt. The contract requires the header and this app
        // sent it on nothing until 30 August 2026. Note the limit honestly: a
        // key made here is stable across the client's own retry of this call,
        // and NOT across an applicant tapping the button twice — the durable
        // version generates it where the operation is created, as the offline
        // queue already does. Recorded in M-47.
        idempotencyKey: newIdempotencyKey(),
      );

      final access = tokens['accessToken'];
      final refresh = tokens['refreshToken'];
      if (access is! String || refresh is! String) {
        throw const ApiException(
          ApiFailure.malformed,
          'token response missing a token',
        );
      }

      // Stored before the profile call, so the profile request carries it.
      await _session.save(accessToken: access, refreshToken: refresh);

      return await _profile(email);
    } on ApiException catch (error) {
      // The server answers identically for an unknown account and a wrong
      // password, so there is nothing here to distinguish either — which is the
      // point. Null means "not accepted", and the caller must not elaborate.
      if (error.failure == ApiFailure.unauthorized) return null;
      rethrow;
    }
  }

  @override
  Future<bool> registerAccount({
    required String firstName,
    required String lastName,
    required String email,
    required String mobileNumber,
    required String password,
  }) async {
    await _api.post(
      '/auth/register',
      body: {
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'mobileNumber': mobileNumber,
        'password': password,
      },
      // One key per attempt. The contract requires the header and this app
      // sent it on nothing until 30 August 2026. Note the limit honestly: a
      // key made here is stable across the client's own retry of this call,
      // and NOT across an applicant tapping the button twice — the durable
      // version generates it where the operation is created, as the offline
      // queue already does. Recorded in M-47.
      idempotencyKey: newIdempotencyKey(),
    );
    // 202 whether or not the address was already registered. Returning true
    // either way is deliberate: anything else would let the app tell an
    // applicant which of their neighbours already has an account here.
    return true;
  }

  @override
  Future<UserModel?> hydrateUser(String email) => _profile(email);

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
    // Absent keys are omitted; present ones are sent even when their value is
    // null, because that is how the office is told to CLEAR a field. A map
    // built with `if (x != null)` would silently drop every clear and leave a
    // citizen unable to remove a middle name they do not have.
    final body = <String, Object?>{};
    void put(String key, FieldEdit edit) {
      if (edit.isPresent) body[key] = edit.value;
    }

    put('firstName', firstName);
    put('middleName', middleName);
    put('lastName', lastName);
    put('mobileNumber', mobileNumber);
    // `street`, the server's own name for this field on businesses. This app
    // called it `address` and the wizards it prefills already called it
    // `street` — two spellings of one idea inside one service, which is the
    // defect D-10 spent a migration undoing.
    put('street', street);
    put('barangay', barangay);
    put('city', city);
    put('province', province);
    put('postalCode', postalCode);

    // No `email`. The server refuses it with a 400 rather than ignoring it,
    // and rightly: it is the sign-in identity, so a change transfers who can
    // reach the account and needs proof of control of the new address first.
    final me = await _api.patch('/me', body: body);

    return ProfileUpdate(
      user: UserModel(
        firstName: _string(me, 'firstName') ?? '',
        middleName: _string(me, 'middleName') ?? '',
        lastName: _string(me, 'lastName') ?? '',
        email: _string(me, 'email') ?? '',
        mobileNumber: _string(me, 'mobileNumber') ?? '',
        photoPath: _string(me, 'photoPath'),
        street: _string(me, 'street'),
        province: _string(me, 'province'),
        city: _string(me, 'city'),
        barangay: _string(me, 'barangay'),
        postalCode: _string(me, 'postalCode'),
        accountType: _string(me, 'accountType') ?? 'Individual Applicant',
        accountStatus: _accountStatus(_string(me, 'accountStatus')),
        registeredSince: _dateTimeOrNull(me, 'registeredSince'),
      ),
      // Read, not inferred by comparing numbers. The server also deletes any
      // pending challenge against the OLD number — otherwise a code already
      // sent to the old phone could be confirmed afterwards and would verify
      // the new one — and only the server knows it did that.
      mobileVerificationCleared: me['mobileVerificationCleared'] == true,
    );
  }

  @override
  Future<void> deleteAccount() async {
    // 202. The session is invalid immediately afterwards — measured: a GET
    // /me with the same token returns 401 — so the caller signs out rather
    // than leaving a token that will fail on the next screen.
    await _api.delete('/me', idempotencyKey: newIdempotencyKey());
    await _session.clear();
  }

  Future<UserModel?> _profile(String email) async {
    try {
      final me = await _api.getObject('/me');
      return UserModel(
        firstName: _string(me, 'firstName') ?? '',
        middleName: _string(me, 'middleName') ?? '',
        lastName: _string(me, 'lastName') ?? '',
        email: _string(me, 'email') ?? email,
        mobileNumber: _string(me, 'mobileNumber') ?? '',
        // The Profile screen renders every one of these. Filling four of
        // fourteen left a signed-in applicant looking at their own record with
        // no address, no account type, no status and no join date — all of
        // which the screen has rendered since it was built.
        photoPath: _string(me, 'photoPath'),
        // `street` and `postalCode`, which are the keys the server actually
        // sends. This read `address` and `zipCode` — names that exist nowhere
        // on the wire — so the address block came back empty however much the
        // office held.
        //
        // No `?? ''`. Null here means NOT RECORDED: nobody was ever asked for
        // these before `PATCH /me`, and collapsing that to a blank string
        // tells a citizen they left something empty when they were not asked.
        street: _string(me, 'street'),
        province: _string(me, 'province'),
        city: _string(me, 'city'),
        barangay: _string(me, 'barangay'),
        postalCode: _string(me, 'postalCode'),
        accountType: _string(me, 'accountType') ?? 'Individual Applicant',
        accountStatus: _accountStatus(_string(me, 'accountStatus')),
        registeredSince: _dateTimeOrNull(me, 'registeredSince'),
      );
    } on ApiException catch (error) {
      if (error.failure == ApiFailure.unauthorized) return null;
      rethrow;
    }
  }

  /// The account's standing, as the office words it.
  ///
  /// Defaults to pending rather than verified when absent or unrecognised.
  /// Getting this wrong in the safe direction matters: an account shown as
  /// Verified that the office has not verified is a claim this app has no
  /// basis for, while an unnecessary "Pending Verification" costs only a
  /// question at the counter. Deliberately does not throw — a profile that
  /// fails to load locks the applicant out of everything.
  static AccountStatus _accountStatus(String? raw) => switch (raw) {
    'Verified' => AccountStatus.verified,
    'Pending Verification' || 'Pending' => AccountStatus.pending,
    'Suspended' => AccountStatus.suspended,
    _ => AccountStatus.pending,
  };

  static DateTime? _dateTimeOrNull(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is! String || value.isEmpty) return null;
    return DateTime.tryParse(value)?.toLocal();
  }

  static String? _string(Map<String, dynamic> json, String key) {
    final value = json[key];
    return value is String && value.isNotEmpty ? value : null;
  }
}
