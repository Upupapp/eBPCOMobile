import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:ebpco_user_app/core/api/api_exception.dart';
import 'package:ebpco_user_app/core/sync/offline_queue.dart';
import 'package:ebpco_user_app/core/sync/queued_operation.dart';
import 'package:ebpco_user_app/core/sync/sync_engine.dart';

QueuedOperation op(String id, {String? key, int attempts = 0}) =>
    QueuedOperation(
      id: id,
      kind: QueuedOperationKind.applicationSubmission,
      idempotencyKey: key ?? 'key-$id',
      enqueuedAt: DateTime.utc(2026, 8, 19, 10),
      payload: const {'permitType': 'Fencing'},
      attempts: attempts,
    );

void main() {
  late InMemoryQueueStore store;
  late OfflineQueue queue;
  late DateTime now;

  setUp(() {
    store = InMemoryQueueStore();
    now = DateTime.utc(2026, 8, 19, 12);
    queue = OfflineQueue(store, clock: () => now);
  });

  SyncEngine engineThat(
    Future<void> Function(QueuedOperation) send, {
    int maxAttempts = 8,
  }) => SyncEngine(
    queue,
    send,
    clock: () => now,
    random: Random(1),
    maxAttempts: maxAttempts,
  );

  group('a successful send', () {
    test('removes the item from the queue', () async {
      await queue.enqueue(op('a'));

      final outcome = await engineThat((_) async {}).flush();

      expect(outcome.sent, 1);
      expect(await queue.all(), isEmpty);
    });

    test('reuses the SAME idempotency key on every attempt', () async {
      // Criterion 2. A submission interrupted after the server committed but
      // before the response arrived is replayed with the same key, so the
      // server returns the original result rather than filing a second
      // application. Regenerating it per attempt turns one bad connection into
      // two permits.
      await queue.enqueue(op('a', key: 'stable-key'));
      final seen = <String>[];
      var firstAttempt = true;

      final engine = engineThat((operation) async {
        seen.add(operation.idempotencyKey);
        if (firstAttempt) {
          firstAttempt = false;
          throw const ApiException(ApiFailure.timeout, 'response lost');
        }
      });

      await engine.flush();
      now = now.add(const Duration(hours: 2));
      await engine.flush();

      expect(seen, ['stable-key', 'stable-key']);
      expect(await queue.all(), isEmpty);
    });
  });

  group('a transient failure', () {
    test('keeps the item and schedules a retry', () async {
      await queue.enqueue(op('a'));

      final outcome = await engineThat(
        (_) async => throw const ApiException(ApiFailure.network, 'offline'),
      ).flush();

      expect(outcome.deferred, 1);
      final item = (await queue.all()).single;
      expect(item.state, QueuedOperationState.pending);
      expect(item.attempts, 1);
      expect(item.nextAttemptAt, isNotNull);
    });

    test('backs off further on each attempt', () async {
      final engine = engineThat(
        (_) async => throw const ApiException(ApiFailure.network, 'offline'),
      );

      expect(engine.backoffFor(1) < engine.backoffFor(3), isTrue);
      expect(engine.backoffFor(3) < engine.backoffFor(5), isTrue);
    });

    test('caps the delay, so an item does not disappear for a day', () async {
      final engine = engineThat((_) async {});

      expect(engine.backoffFor(20) <= const Duration(hours: 1), isTrue);
      expect(engine.backoffFor(20) >= const Duration(minutes: 30), isTrue);
    });

    test(
      'adds jitter, so every device on one cell tower does not retry together',
      () async {
        // Without it the LGU's server meets a thundering herd exactly as it comes
        // back up.
        final engine = SyncEngine(
          queue,
          (_) async {},
          clock: () => now,
          random: Random(),
        );
        final delays = {
          for (var i = 0; i < 20; i += 1) engine.backoffFor(4).inMilliseconds,
        };

        expect(delays.length, greaterThan(1));
      },
    );

    test(
      'gives up after enough attempts, rather than retrying invisibly forever',
      () async {
        // Not because it stopped being transient, but because an item retrying
        // silently forever is indistinguishable from one that was lost.
        await queue.enqueue(op('a', attempts: 2));

        final outcome = await engineThat(
          (_) async => throw const ApiException(ApiFailure.network, 'offline'),
          maxAttempts: 3,
        ).flush();

        expect(outcome.failed, 1);
        final item = (await queue.all()).single;
        expect(item.state, QueuedOperationState.failedPermanently);
        expect(item.failureMessage, contains('try again'));
      },
    );
  });

  group('a permanent failure', () {
    test('stops retrying immediately', () async {
      // Nothing about retrying changes a rejected filing.
      await queue.enqueue(op('a'));
      var calls = 0;

      final engine = engineThat((_) async {
        calls += 1;
        throw const ApiException(ApiFailure.rejected, 'validation');
      });

      await engine.flush();
      now = now.add(const Duration(hours: 2));
      await engine.flush();

      expect(calls, 1);
    });

    test('is NEVER discarded silently', () async {
      // Criterion 4. Discarding an applicant's work without telling them is
      // worse than any error message.
      await queue.enqueue(op('a'));

      await engineThat(
        (_) async =>
            throw const ApiException(ApiFailure.rejected, 'validation'),
      ).flush();

      expect(await queue.all(), hasLength(1));
    });

    test(
      'carries the server’s own explanation, which knows the specifics',
      () async {
        await queue.enqueue(op('a'));

        await engineThat(
          (_) async => throw const ApiException(
            ApiFailure.rejected,
            'engineering detail',
            problem: ProblemDetails(
              type: '/problems/precondition-unmet',
              title: 'A precondition is unmet',
              detail:
                  'No Order of Payment has been issued for this application, so there is nothing to pay.',
            ),
          ),
        ).flush();

        expect(
          (await queue.all()).single.failureMessage,
          contains('nothing to pay'),
        );
      },
    );

    test('shows the applicant it needs them, not a silent spinner', () async {
      await queue.enqueue(op('a'));

      await engineThat(
        (_) async =>
            throw const ApiException(ApiFailure.forbidden, 'not permitted'),
      ).flush();

      expect(
        (await queue.all()).single.applicantStatus,
        'Needs your attention',
      );
    });
  });

  group('an unexpected error', () {
    test(
      'is treated as transient, because the other way discards work',
      () async {
        // Being wrong this way costs a retry. Being wrong the other way throws
        // away an applicant's filing over a bug.
        await queue.enqueue(op('a'));

        final outcome = await engineThat(
          (_) async => throw StateError('a bug'),
        ).flush();

        expect(outcome.deferred, 1);
        expect((await queue.all()).single.state, QueuedOperationState.pending);
      },
    );
  });

  group('concurrent flushes', () {
    test('a second flush while one is running is skipped, not queued', () async {
      // A connectivity event arriving mid-flush must not start a second pass:
      // the idempotency key makes it safe on the server, but it wastes data on
      // a connection that has just proven poor.
      await queue.enqueue(op('a'));
      late SyncEngine engine;
      SyncOutcome? nested;

      engine = engineThat((_) async {
        nested = await engine.flush();
      });

      await engine.flush();

      expect(nested?.skipped, isTrue);
    });
  });

  group('nothing to do', () {
    test('reports having done nothing', () async {
      final outcome = await engineThat(
        (_) async => fail('nothing should be sent'),
      ).flush();

      expect(outcome.didAnything, isFalse);
    });
  });
}
