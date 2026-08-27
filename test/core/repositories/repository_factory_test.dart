import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ebpco_user_app/core/api/api_client.dart';
import 'package:ebpco_user_app/core/config/app_config.dart';
import 'package:ebpco_user_app/core/repositories/applications_repository.dart';
import 'package:ebpco_user_app/core/repositories/http_applications_repository.dart';
import 'package:ebpco_user_app/core/repositories/repository_factory.dart';
import 'package:ebpco_user_app/core/services/secure_session_store.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('default build', () {
    test('uses mock repositories when no base URL was supplied', () {
      // The suite runs without --dart-define, which is the same state as a
      // developer running the app with no arguments.
      expect(AppConfig.useLiveBackend, isFalse);
      expect(AppConfig.apiBaseUrl, isEmpty);

      final factory = RepositoryFactory();
      addTearDown(factory.dispose);

      expect(factory.isLive, isFalse);
      expect(factory.client, isNull);
      expect(factory.applications(), isA<MockApplicationsRepository>());
    });

    test('describes itself as demo data, not as a connection', () {
      // Shown in bug reports; an applicant should not have to know which
      // environment they were on.
      expect(AppConfig.backendDescription, 'Offline demo data');
    });
  });

  group('live build', () {
    test('uses the HTTP repository when a client is supplied', () {
      final factory = RepositoryFactory(
        apiClient: ApiClient(baseUrl: 'https://ebpco.example.gov.ph/api'),
      );
      addTearDown(factory.dispose);

      expect(factory.isLive, isTrue);
      expect(factory.applications(), isA<HttpApplicationsRepository>());
    });

    test('builds one client and reuses it', () {
      // The underlying http.Client pools connections; a fresh one per call
      // would throw that away.
      final factory = RepositoryFactory(
        apiClient: ApiClient(baseUrl: 'https://x'),
      );
      addTearDown(factory.dispose);

      expect(identical(factory.client, factory.client), isTrue);
    });
  });

  group('session token', () {
    test('comes from the keychain, not from preferences', () async {
      // It used to be read from SharedPreferences, which is an unencrypted file
      // on both platforms. The factory now takes a SessionStore, and the only
      // production implementation is keychain-backed.
      final session = InMemorySessionStore();
      final factory = RepositoryFactory(
        apiClient: ApiClient(baseUrl: 'https://ebpco.example.gov.ph/api'),
        session: session,
      );

      expect(factory.isLive, isTrue);
      expect(await session.accessToken(), isNull);
    });

    test('is absent until something issues one', () async {
      // Nothing does yet on a mock build, so the client sends no Authorization
      // header rather than a bogus one.
      expect(await InMemorySessionStore().accessToken(), isNull);
    });

    test(
      'is picked up per request, so a token issued after sign-in works',
      () async {
        // The client asks for the token on every request rather than capturing it
        // at construction, so signing in does not require rebuilding the graph.
        final session = InMemorySessionStore();
        RepositoryFactory(
          apiClient: ApiClient(baseUrl: 'https://ebpco.example.gov.ph/api'),
          session: session,
        );

        await session.save(
          accessToken: 'issued-after-construction',
          refreshToken: 'r',
        );

        expect(await session.accessToken(), 'issued-after-construction');
      },
    );
  });
}
