import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ebpco_user_app/core/constants/app_constants.dart';
import 'package:ebpco_user_app/core/services/credential_verifier.dart';
import 'package:ebpco_user_app/core/services/local_storage_service.dart';

void main() {
  group('CredentialVerifier', () {
    const verifier = CredentialVerifier();

    test('a verifier does not contain the password', () {
      final salt = verifier.newSalt();
      final derived = verifier.derive('password123', salt);

      expect(derived, isNot(contains('password123')));
      expect(derived.length, greaterThan(20));
    });

    test('the same password and salt derive the same verifier', () {
      final salt = verifier.newSalt();
      expect(
        verifier.derive('password123', salt),
        verifier.derive('password123', salt),
      );
    });

    test('the same password under different salts derives differently', () {
      // Which is the point of the salt: two accounts sharing a password must
      // not share a verifier.
      final a = verifier.derive('password123', verifier.newSalt());
      final b = verifier.derive('password123', verifier.newSalt());
      expect(a, isNot(b));
    });

    test('salts are random', () {
      final salts = List.generate(20, (_) => verifier.newSalt()).toSet();
      expect(salts, hasLength(20));
    });

    test('matches accepts the right password and rejects near misses', () {
      final salt = verifier.newSalt();
      final expected = verifier.derive('password123', salt);

      expect(
        verifier.matches(
          password: 'password123',
          salt: salt,
          expectedVerifier: expected,
        ),
        isTrue,
      );
      for (final wrong in ['password124', 'Password123', 'password12', '']) {
        expect(
          verifier.matches(
            password: wrong,
            salt: salt,
            expectedVerifier: expected,
          ),
          isFalse,
          reason: wrong,
        );
      }
    });

    test('runs at full strength when not overridden', () {
      final original = CredentialVerifier.iterationsOverride;
      addTearDown(() => CredentialVerifier.iterationsOverride = original);

      CredentialVerifier.iterationsOverride = 0;
      expect(CredentialVerifier.iterations, 12000);

      // And still produces a usable verifier at that cost.
      final salt = verifier.newSalt();
      expect(
        verifier.matches(
          password: 'password123',
          salt: salt,
          expectedVerifier: verifier.derive('password123', salt),
        ),
        isTrue,
      );
    });
  });

  group('credential storage', () {
    late LocalStorageService storage;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      storage = LocalStorageService();
    });

    test('registering writes no password to disk in any form', () async {
      await storage.saveRegisteredUser(
        email: 'juan@example.com',
        password: 'password123',
        firstName: 'Juan',
        lastName: 'Dela Cruz',
        mobileNumber: '09171234567',
      );

      final prefs = await SharedPreferences.getInstance();
      // Every stored value, whatever the key.
      final stored = prefs
          .getKeys()
          .map((key) => prefs.get(key)?.toString() ?? '')
          .join(' ');

      expect(
        stored.contains('password123'),
        isFalse,
        reason: 'the password appears somewhere in SharedPreferences',
      );
      expect(prefs.getString(AppConstants.prefRegisteredVerifier), isNotNull);
      expect(prefs.getString(AppConstants.prefRegisteredSalt), isNotNull);
      expect(
        prefs.getString(AppConstants.legacyPrefRegisteredPassword),
        isNull,
      );
    });

    test('the stored verifier authenticates the right password only', () async {
      await storage.saveRegisteredUser(
        email: 'juan@example.com',
        password: 'password123',
        firstName: 'Juan',
        lastName: 'Dela Cruz',
        mobileNumber: '09171234567',
      );

      expect(await storage.isRegisteredPassword('password123'), isTrue);
      expect(await storage.isRegisteredPassword('password124'), isFalse);
    });

    test('no password is registered before anyone registers', () async {
      expect(await storage.isRegisteredPassword('anything'), isFalse);
    });

    test('a plain-text password from an older build is purged', () async {
      // Simulates an install upgraded from the build that stored it.
      SharedPreferences.setMockInitialValues({
        AppConstants.legacyPrefRegisteredPassword: 'password123',
        AppConstants.prefRegisteredEmail: 'juan@example.com',
      });
      final upgraded = LocalStorageService();

      await upgraded.purgeLegacyPlainTextPassword();

      final prefs = await SharedPreferences.getInstance();
      expect(
        prefs.getString(AppConstants.legacyPrefRegisteredPassword),
        isNull,
      );
      // The account itself survives the cleanup.
      expect(prefs.getString(AppConstants.prefRegisteredEmail), isNotNull);
    });
  });
}
