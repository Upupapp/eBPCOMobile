import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:ebpco_user_app/core/api/session_manager.dart';
import 'package:ebpco_user_app/core/services/secure_session_store.dart';

void main() {
  late InMemorySessionStore store;
  late int signedOutCount;

  setUp(() {
    store = InMemorySessionStore();
    signedOutCount = 0;
  });

  SessionManager managerThat(
    Future<RefreshedTokens?> Function(String) refresh,
  ) =>
      SessionManager(store, refresh, () async => signedOutCount += 1);

  group('one refresh at a time', () {
    test('ten simultaneous 401s produce exactly one refresh call', () async {
      // The case this exists for: an applicant opening the app after a while
      // has a home screen firing several requests at once, and every one gets a
      // 401 at the same moment. Without a guard each refreshes — and because
      // refresh tokens rotate and a replay revokes the whole family, the second
      // one to land signs them out and looks like a stolen token from the
      // server's side.
      await store.save(accessToken: 'old', refreshToken: 'refresh-1');
      final gate = Completer<void>();

      final manager = managerThat((_) async {
        await gate.future;
        return const RefreshedTokens(accessToken: 'new', refreshToken: 'refresh-2');
      });

      final attempts = List.generate(10, (_) => manager.refreshAccessToken());
      gate.complete();
      final results = await Future.wait(attempts);

      expect(manager.refreshCallCount, 1);
      expect(results, everyElement('new'));
    });

    test('a refresh after the first has settled starts a new one', () async {
      // The guard must not latch: a completed future left in place would make
      // every later request reuse a dead result.
      await store.save(accessToken: 'old', refreshToken: 'refresh-1');
      var issued = 0;
      final manager = managerThat((_) async {
        issued += 1;
        return RefreshedTokens(accessToken: 'new-$issued', refreshToken: 'refresh-$issued');
      });

      expect(await manager.refreshAccessToken(), 'new-1');
      expect(await manager.refreshAccessToken(), 'new-2');
      expect(manager.refreshCallCount, 2);
    });

    test('a thrown refresh does not latch the guard', () async {
      await store.save(accessToken: 'old', refreshToken: 'refresh-1');
      var call = 0;
      final manager = managerThat((_) async {
        call += 1;
        if (call == 1) throw StateError('network down');
        return const RefreshedTokens(accessToken: 'new', refreshToken: 'refresh-2');
      });

      expect(await manager.refreshAccessToken(), isNull);

      // The session was ended, so there is no refresh token to try with — which
      // is the correct outcome, not a latched guard.
      expect(await manager.refreshAccessToken(), isNull);
      expect(signedOutCount, 2);
    });
  });

  group('the new tokens are kept', () {
    test('a successful refresh stores both', () async {
      await store.save(accessToken: 'old', refreshToken: 'refresh-1');
      final manager = managerThat(
        (_) async => const RefreshedTokens(accessToken: 'new', refreshToken: 'refresh-2'),
      );

      await manager.refreshAccessToken();

      expect(await store.accessToken(), 'new');
      expect(await store.refreshToken(), 'refresh-2');
    });

    test('the rotated refresh token replaces the old one', () async {
      // Keeping the old one risks presenting it later, which the server reads
      // as a replay and answers by revoking every session.
      await store.save(accessToken: 'old', refreshToken: 'refresh-1');
      final manager = managerThat(
        (_) async => const RefreshedTokens(accessToken: 'new', refreshToken: 'refresh-2'),
      );

      await manager.refreshAccessToken();

      expect(await store.refreshToken(), isNot('refresh-1'));
    });
  });

  group('when the session is over', () {
    test('a refused refresh signs out and clears everything', () async {
      await store.save(accessToken: 'old', refreshToken: 'refresh-1');
      final manager = managerThat((_) async => null);

      expect(await manager.refreshAccessToken(), isNull);
      expect(await store.accessToken(), isNull);
      expect(await store.refreshToken(), isNull);
      expect(signedOutCount, 1);
    });

    test('a network failure signs out rather than retrying forever', () async {
      // Not a revoked session, but not a usable one either. The alternative is
      // an app that spins behind a loader with no way out.
      await store.save(accessToken: 'old', refreshToken: 'refresh-1');
      final manager = managerThat((_) async => throw StateError('offline'));

      expect(await manager.refreshAccessToken(), isNull);
      expect(signedOutCount, 1);
    });

    test('refreshing with no stored token signs out without calling out', () async {
      final manager = managerThat((_) async => fail('should not have been called'));

      expect(await manager.refreshAccessToken(), isNull);
      expect(manager.refreshCallCount, 0);
      expect(signedOutCount, 1);
    });

    test('signing out clears the store and notifies once', () async {
      await store.save(accessToken: 'a', refreshToken: 'r');
      final manager = managerThat((_) async => null);

      await manager.signOut();

      expect(await store.accessToken(), isNull);
      expect(signedOutCount, 1);
    });
  });
}
