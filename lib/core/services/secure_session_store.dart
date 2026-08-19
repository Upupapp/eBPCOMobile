import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Where session tokens live: the platform keychain, and nowhere else.
///
/// SharedPreferences — where the session token read point used to be — is an
/// unencrypted XML file on Android and an unencrypted plist on iOS. It is
/// readable on a rooted or jailbroken device, and on Android it has historically
/// been swept up by automatic cloud backup. A session token there is a session
/// token anyone with the device's backup can use.
///
/// It returned null until now, so nothing was ever exposed. That is precisely
/// why this had to be fixed *before* the server started issuing real tokens
/// rather than after: fixing it after means every token issued in between was,
/// for a period, sitting in the clear.
///
/// The token is the only thing here. Anything else the app caches is a separate
/// decision made in [SessionCleaner], not a reason to widen this.
abstract class SessionStore {
  Future<String?> accessToken();
  Future<String?> refreshToken();
  Future<void> save({required String accessToken, required String refreshToken});
  Future<void> clear();
}

class SecureSessionStore implements SessionStore {
  SecureSessionStore({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              // Android options are left at their defaults deliberately.
              // `encryptedSharedPreferences` is deprecated as of plugin v10:
              // Google deprecated the Jetpack Security library behind it, and
              // the plugin now migrates existing data to its own Keystore-backed
              // ciphers on first access. Passing it would be ignored, and
              // shipping a deprecation warning on the day a file is written is
              // how a codebase accumulates them.
              iOptions: IOSOptions(
                // Readable only while the device is unlocked, and only on this
                // device. `first_unlock_this_device` rather than `first_unlock`
                // is the load-bearing part: the plain variant is included in
                // encrypted iCloud backups and restores onto a *different*
                // device, which would carry an applicant's session with it.
                accessibility: KeychainAccessibility.first_unlock_this_device,
                synchronizable: false,
              ),
            );

  final FlutterSecureStorage _storage;

  static const _accessKey = 'ebpco.session.access';
  static const _refreshKey = 'ebpco.session.refresh';

  @override
  Future<String?> accessToken() => _storage.read(key: _accessKey);

  @override
  Future<String?> refreshToken() => _storage.read(key: _refreshKey);

  @override
  Future<void> save({required String accessToken, required String refreshToken}) async {
    await _storage.write(key: _accessKey, value: accessToken);
    await _storage.write(key: _refreshKey, value: refreshToken);
  }

  @override
  Future<void> clear() async {
    await _storage.delete(key: _accessKey);
    await _storage.delete(key: _refreshKey);
  }
}

/// An in-memory store for tests and for the mock build.
///
/// Deliberately not backed by SharedPreferences even here: a test double that
/// writes to the very place tokens must not go is a test double that can make
/// the storage test pass while the app is wrong.
class InMemorySessionStore implements SessionStore {
  String? _access;
  String? _refresh;

  @override
  Future<String?> accessToken() async => _access;

  @override
  Future<String?> refreshToken() async => _refresh;

  @override
  Future<void> save({required String accessToken, required String refreshToken}) async {
    _access = accessToken;
    _refresh = refreshToken;
  }

  @override
  Future<void> clear() async {
    _access = null;
    _refresh = null;
  }
}
