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
        address: _string(me, 'address') ?? '',
        province: _string(me, 'province') ?? '',
        city: _string(me, 'city') ?? '',
        barangay: _string(me, 'barangay') ?? '',
        zipCode: _string(me, 'zipCode') ?? '',
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
