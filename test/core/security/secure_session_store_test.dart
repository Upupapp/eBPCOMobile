import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ebpco_user_app/core/constants/app_constants.dart';
import 'package:ebpco_user_app/core/services/local_storage_service.dart';
import 'package:ebpco_user_app/core/services/secure_session_store.dart';

/// The property this whole TAB exists to establish: **no token, and nothing
/// identifying, is ever written to SharedPreferences.**
///
/// It is an unencrypted XML file on Android and an unencrypted plist on iOS,
/// readable on a rooted or jailbroken device and historically swept into
/// automatic cloud backup. A session token there is a session anyone with the
/// backup can resume.
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('nothing sensitive reaches SharedPreferences', () {
    test('saving a session writes nothing to preferences at all', () async {
      final store = InMemorySessionStore();
      await store.save(
        accessToken: 'header.payload.signature',
        refreshToken: 'refresh-secret-abc',
      );

      final prefs = await SharedPreferences.getInstance();

      expect(prefs.getKeys(), isEmpty);
    });

    test('no preference value contains a token, however it was named', () async {
      // Scanned rather than checked key by key, so a key added later is caught
      // by this test rather than by whoever finds the backup.
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(AppConstants.prefIsLoggedIn, true);

      final store = InMemorySessionStore();
      await store.save(
        accessToken: 'header.payload.signature',
        refreshToken: 'refresh-secret-abc',
      );

      final written = prefs
          .getKeys()
          .map((key) => '${prefs.get(key)}')
          .join(' ');

      expect(written, isNot(contains('header.payload.signature')));
      expect(written, isNot(contains('refresh-secret-abc')));
      expect(written, isNot(contains('eyJ')));
    });

    test('the legacy token key is purged on startup', () async {
      // The token used to be stored here. It returned null in every shipped
      // build, so there is very likely nothing to purge — but "very likely" is
      // not a reason to skip it.
      SharedPreferences.setMockInitialValues({
        AppConstants.prefSessionToken: 'a-token-from-an-older-build',
      });

      await LocalStorageService().purgeLegacySessionToken();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(AppConstants.prefSessionToken), isNull);
    });

    test('purging is safe when there was never a token', () async {
      await LocalStorageService().purgeLegacySessionToken();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(AppConstants.prefSessionToken), isNull);
    });
  });

  group('the store itself', () {
    test('returns null before a session exists', () async {
      final store = InMemorySessionStore();

      expect(await store.accessToken(), isNull);
      expect(await store.refreshToken(), isNull);
    });

    test('round-trips both tokens', () async {
      final store = InMemorySessionStore();
      await store.save(accessToken: 'access-1', refreshToken: 'refresh-1');

      expect(await store.accessToken(), 'access-1');
      expect(await store.refreshToken(), 'refresh-1');
    });

    test('replaces rather than accumulates on refresh', () async {
      // Refresh tokens rotate, and a stale one left behind can be replayed —
      // which the server treats as theft and responds to by revoking the whole
      // family.
      final store = InMemorySessionStore();
      await store.save(accessToken: 'access-1', refreshToken: 'refresh-1');
      await store.save(accessToken: 'access-2', refreshToken: 'refresh-2');

      expect(await store.refreshToken(), 'refresh-2');
    });

    test('clear leaves nothing', () async {
      final store = InMemorySessionStore();
      await store.save(accessToken: 'access-1', refreshToken: 'refresh-1');

      await store.clear();

      expect(await store.accessToken(), isNull);
      expect(await store.refreshToken(), isNull);
    });
  });
}
