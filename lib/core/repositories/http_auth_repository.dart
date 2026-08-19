import '../api/api_client.dart';
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
      final tokens = await _api.post('/auth/token', body: {
        'grantType': 'password',
        'email': email,
        'password': password,
      });

      final access = tokens['accessToken'];
      final refresh = tokens['refreshToken'];
      if (access is! String || refresh is! String) {
        throw const ApiException(ApiFailure.malformed, 'token response missing a token');
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
    await _api.post('/auth/register', body: {
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'mobileNumber': mobileNumber,
      'password': password,
    });
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
        lastName: _string(me, 'lastName') ?? '',
        email: _string(me, 'email') ?? email,
        mobileNumber: _string(me, 'mobileNumber') ?? '',
      );
    } on ApiException catch (error) {
      if (error.failure == ApiFailure.unauthorized) return null;
      rethrow;
    }
  }

  static String? _string(Map<String, dynamic> json, String key) {
    final value = json[key];
    return value is String && value.isNotEmpty ? value : null;
  }
}
