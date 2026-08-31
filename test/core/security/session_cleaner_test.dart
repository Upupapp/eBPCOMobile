import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ebpco_user_app/core/constants/app_constants.dart';
import 'package:ebpco_user_app/core/services/secure_session_store.dart';
import 'package:ebpco_user_app/core/services/session_cleaner.dart';

/// Signing out must leave nothing of the previous applicant behind.
///
/// On a shared or handed-on device — common here, not exotic — a sign-out that
/// only forgets the token leaves the next person looking at somebody's address,
/// their business, and their identity documents.
void main() {
  late Directory cache;
  late InMemorySessionStore store;

  setUp(() async {
    cache = await Directory.systemTemp.createTemp('ebpco-docs-');
    store = InMemorySessionStore();
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(() {
    if (cache.existsSync()) cache.deleteSync(recursive: true);
  });

  SessionCleaner cleaner() =>
      SessionCleaner(store, cache, SharedPreferences.getInstance);

  Future<void> seedASession() async {
    await store.save(accessToken: 'access-1', refreshToken: 'refresh-1');
    final prefs = await SharedPreferences.getInstance();
    // **The keys the APP writes, not invented ones.** This fixture used to
    // seed `is_logged_in`, `applicant_email` and `onboarding_completed` —
    // none of which the app uses. So the suite proved sign-out kept a key
    // nobody wrote, while the real `onboardingCompleted` was being deleted
    // and every returning applicant was shown the introduction again.
    await prefs.setBool(AppConstants.prefIsLoggedIn, true);
    await prefs.setString(
      AppConstants.prefCurrentUserEmail,
      'maria.santos@example.ph',
    );
    await prefs.setString('last_application_id', 'BP-2026-000418');
    await prefs.setBool(AppConstants.prefOnboardingCompleted, true);
    await prefs.setString('preferred_language', 'en');
    File(
      '${cache.path}/tct-142-rizal-ext.pdf',
    ).writeAsStringSync('%PDF-1.4 title deed');
    File(
      '${cache.path}/permit-BP-2026-000418.pdf',
    ).writeAsStringSync('%PDF-1.4 signed permit');
  }

  group('what sign-out removes', () {
    test('the tokens', () async {
      await seedASession();

      await cleaner().signOut();

      expect(await store.accessToken(), isNull);
      expect(await store.refreshToken(), isNull);
    });

    test('every cached document on the filesystem', () async {
      // The most sensitive thing the app holds locally: a title deed, a
      // government ID, a signed permit. Leaving them because the token is gone
      // confuses "cannot fetch it again" with "no longer has it".
      await seedASession();
      expect(cache.listSync(), isNotEmpty);

      await cleaner().signOut();

      expect(cache.listSync(), isEmpty);
    });

    test('the fixture actually writes something first', () async {
      // The guard that would have caught both halves of this. An assertion
      // that a key is null after sign-out proves nothing unless the key was
      // non-null before it.
      await seedASession();
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(AppConstants.prefCurrentUserEmail), isNotNull);
      expect(prefs.getBool(AppConstants.prefIsLoggedIn), isNotNull);
      expect(prefs.getBool(AppConstants.prefOnboardingCompleted), isNotNull);
      expect(prefs.getString('last_application_id'), isNotNull);
    });

    test('preference keys carrying personal data', () async {
      await seedASession();

      await cleaner().signOut();

      final prefs = await SharedPreferences.getInstance();
      // The keys the app writes. These asserted `applicant_email` and
      // `is_logged_in` until 31 August 2026 — names nothing writes — so they
      // were null before sign-out as well as after, and would have passed
      // against a signOut() that did nothing at all.
      expect(prefs.getString(AppConstants.prefCurrentUserEmail), isNull);
      expect(prefs.getBool(AppConstants.prefIsLoggedIn), isNull);
      // Not a constant on purpose: an arbitrary key, standing for whatever
      // some future feature stores without telling this list about it.
      expect(prefs.getString('last_application_id'), isNull);
    });

    test(
      'a key nobody thought about, because the list is an allow-list',
      () async {
        // A deny-list would leave every key added later behind by default, and
        // the thing forgotten would be somebody's data.
        await seedASession();
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('some_future_key_with_a_name', 'Maria Santos');

        await cleaner().signOut();

        expect(
          (await SharedPreferences.getInstance()).getString(
            'some_future_key_with_a_name',
          ),
          isNull,
        );
      },
    );

    test('leaves nothing identifying anywhere in preferences', () async {
      await seedASession();

      await cleaner().signOut();

      final prefs = await SharedPreferences.getInstance();
      final remaining = prefs
          .getKeys()
          .map((key) => '$key=${prefs.get(key)}')
          .join(' ');

      expect(remaining, isNot(contains('maria.santos')));
      expect(remaining, isNot(contains('BP-2026-000418')));
    });
  });

  group('what sign-out deliberately keeps', () {
    test('the allow-list names the key the app actually writes', () {
      // The defect this group failed to catch for as long as it existed: the
      // allow-list held 'onboarding_completed' and the app writes
      // 'onboardingCompleted'. An allow-list that misspells a key does not
      // fail loudly — it forgets, quietly, at sign-out.
      expect(
        SessionCleaner.kept,
        contains(AppConstants.prefOnboardingCompleted),
        reason:
            'the allow-list and the writer disagree on the spelling, so the '
            'key is not protected by the list that names it',
      );
    });

    test('whether onboarding has been seen', () async {
      // Device settings, not personal data. Wiping them makes every sign-out
      // feel like a factory reset without protecting anyone.
      await seedASession();

      await cleaner().signOut();

      expect(
        (await SharedPreferences.getInstance()).getBool(
          AppConstants.prefOnboardingCompleted,
        ),
        isTrue,
        reason:
            'signing out sent a returning applicant back through the '
            'three-page introduction',
      );
    });

    test('the chosen language', () async {
      await seedASession();

      await cleaner().signOut();

      expect(
        (await SharedPreferences.getInstance()).getString('preferred_language'),
        'en',
      );
    });
  });

  group('robustness', () {
    test('is safe when there is nothing to clear', () async {
      await cleaner().signOut();

      expect(await store.accessToken(), isNull);
    });

    test('is safe when the document cache does not exist', () async {
      cache.deleteSync(recursive: true);

      await expectLater(cleaner().signOut(), completes);
    });

    test('is idempotent', () async {
      await seedASession();

      await cleaner().signOut();
      await cleaner().signOut();

      expect(cache.listSync(), isEmpty);
    });

    test('clears nested directories, not only top-level files', () async {
      await seedASession();
      Directory('${cache.path}/BP-2026-000418').createSync();
      File(
        '${cache.path}/BP-2026-000418/id.jpg',
      ).writeAsStringSync('government ID');

      await cleaner().signOut();

      expect(cache.listSync(), isEmpty);
    });
  });
}
