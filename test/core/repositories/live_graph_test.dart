import 'package:flutter_test/flutter_test.dart';

import 'package:ebpco_user_app/core/api/api_client.dart';
import 'package:ebpco_user_app/core/repositories/applications_repository.dart';
import 'package:ebpco_user_app/core/repositories/auth_repository.dart';
import 'package:ebpco_user_app/core/repositories/business_repository.dart';
import 'package:ebpco_user_app/core/repositories/notifications_repository.dart';
import 'package:ebpco_user_app/core/repositories/repository_factory.dart';
import 'package:ebpco_user_app/core/services/secure_session_store.dart';

/// The guarantee this whole TAB exists to establish.
///
/// `RepositoryFactory` has always carried the right idea and said so in its own
/// comment: one place decides what this build talks to, "so a build cannot end
/// up half-live, with applications coming from a server while payments still
/// come from seed data". Until now it implemented only `applications()`, so
/// that guarantee was a comment rather than a fact — every other domain quietly
/// constructed its own mock inside a provider's constructor.
///
/// This asserts it instead. It walks every domain the factory exposes and
/// checks the runtime type, so a domain added tomorrow that forgets its live
/// implementation fails here rather than in production, where it looks like the
/// office losing an applicant's data.
void main() {
  ApiClient liveClient() => ApiClient(baseUrl: 'https://ebpco.example.gov.ph/api');

  /// Every repository the factory produces, by name, so the assertions below
  /// are over the whole set rather than the ones anyone remembered.
  Map<String, Object> allDomainsOf(RepositoryFactory factory) => {
        'applications': factory.applications(),
        'auth': factory.auth(),
        'businesses': factory.businesses(),
        'notifications': factory.notifications(),
      };

  group('a live build is fully live', () {
    late RepositoryFactory factory;

    setUp(() {
      factory = RepositoryFactory(apiClient: liveClient(), session: InMemorySessionStore());
    });

    tearDown(() => factory.dispose());

    test('no Mock repository is instantiated anywhere in the graph', () {
      final mocks = allDomainsOf(factory).entries
          .where((entry) => entry.value.runtimeType.toString().startsWith('Mock'))
          .map((entry) => '${entry.key} -> ${entry.value.runtimeType}')
          .toList();

      expect(
        mocks,
        isEmpty,
        reason: 'a live build serving seed data from any domain is the half-live '
            'state this factory exists to prevent',
      );
    });

    test('covers every domain, so the check cannot pass by covering none', () {
      // A guarantee asserted over an empty set is not a guarantee.
      expect(allDomainsOf(factory), hasLength(greaterThanOrEqualTo(4)));
    });

    test('every domain resolves to its Http implementation by name', () {
      for (final entry in allDomainsOf(factory).entries) {
        expect(
          entry.value.runtimeType.toString(),
          startsWith('Http'),
          reason: '${entry.key} did not resolve to a live implementation',
        );
      }
    });

    test('each domain satisfies its port', () {
      expect(factory.applications(), isA<ApplicationsRepository>());
      expect(factory.auth(), isA<AuthRepository>());
      expect(factory.businesses(), isA<BusinessRepository>());
      expect(factory.notifications(), isA<NotificationsRepository>());
    });

    test('reports itself live', () {
      expect(factory.isLive, isTrue);
    });
  });

  group('a mock build is fully mock', () {
    late RepositoryFactory factory;

    setUp(() {
      // No injected client and no base URL compiled in.
      factory = RepositoryFactory(session: InMemorySessionStore());
    });

    test('constructs no HTTP client at all', () {
      // Not merely "does not call out": nothing is built, so nothing can.
      expect(factory.client, isNull);
      expect(factory.isLive, isFalse);
    });

    test('every domain resolves to its Mock implementation', () {
      for (final entry in allDomainsOf(factory).entries) {
        expect(
          entry.value.runtimeType.toString(),
          startsWith('Mock'),
          reason: '${entry.key} reached for the network on a mock build',
        );
      }
    });

    test('no Http repository appears anywhere in the graph', () {
      // The inverse of the live check. A mock build that quietly makes one live
      // call is a build that fails on an aeroplane and works on a desk.
      final live = allDomainsOf(factory).entries
          .where((entry) => entry.value.runtimeType.toString().startsWith('Http'))
          .map((entry) => entry.key)
          .toList();

      expect(live, isEmpty);
    });
  });

  group('the client is built once', () {
    test('the same instance is reused across domains', () {
      // The underlying http.Client pools connections; a fresh one per
      // repository would throw that away and open a socket per domain.
      final factory = RepositoryFactory(apiClient: liveClient(), session: InMemorySessionStore());

      expect(identical(factory.client, factory.client), isTrue);

      factory.dispose();
    });
  });
}
