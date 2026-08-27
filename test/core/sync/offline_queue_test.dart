import 'package:flutter_test/flutter_test.dart';

import 'package:ebpco_user_app/core/sync/offline_queue.dart';
import 'package:ebpco_user_app/core/sync/queued_operation.dart';

QueuedOperation op({
  required String id,
  QueuedOperationKind kind = QueuedOperationKind.applicationSubmission,
  String? applicationId,
  List<String> dependsOn = const [],
  QueuedOperationState state = QueuedOperationState.pending,
  DateTime? enqueuedAt,
  DateTime? nextAttemptAt,
  String? key,
}) => QueuedOperation(
  id: id,
  kind: kind,
  idempotencyKey: key ?? 'key-$id',
  enqueuedAt: enqueuedAt ?? DateTime.utc(2026, 8, 19, 10),
  payload: const {'permitType': 'Fencing'},
  applicationId: applicationId,
  dependsOn: dependsOn,
  state: state,
  nextAttemptAt: nextAttemptAt,
);

void main() {
  late InMemoryQueueStore store;
  late DateTime now;
  OfflineQueue queue({QueueBounds bounds = const QueueBounds()}) =>
      OfflineQueue(store, bounds: bounds, clock: () => now);

  setUp(() {
    store = InMemoryQueueStore();
    now = DateTime.utc(2026, 8, 19, 12);
  });

  group('durability', () {
    test('an item survives a round trip through storage', () async {
      // The store re-encodes on every save, so a field that does not serialise
      // fails here rather than on a device restart.
      await queue().enqueue(
        op(id: 'a', applicationId: 'app-1', dependsOn: const ['b']),
      );

      final loaded = (await queue().all()).single;

      expect(loaded.id, 'a');
      expect(loaded.idempotencyKey, 'key-a');
      expect(loaded.applicationId, 'app-1');
      expect(loaded.dependsOn, ['b']);
      expect(loaded.payload['permitType'], 'Fencing');
    });

    test('survives what is effectively a restart', () async {
      // A new queue over the same store is the closest thing to relaunching.
      await queue().enqueue(op(id: 'a'));

      expect(await OfflineQueue(store, clock: () => now).all(), hasLength(1));
    });
  });

  group('enqueuing', () {
    test('ignores a repeat of the same idempotency key', () async {
      // A double tap is not two filings. Erroring would make a slow network
      // look like a bug in the app.
      await queue().enqueue(op(id: 'a', key: 'same'));
      await queue().enqueue(op(id: 'b', key: 'same'));

      expect(await queue().all(), hasLength(1));
    });

    test('refuses past the bound, and says what to do about it', () async {
      final bounded = queue(bounds: const QueueBounds(maxItems: 2));
      await bounded.enqueue(op(id: 'a'));
      await bounded.enqueue(op(id: 'b'));

      await expectLater(
        bounded.enqueue(op(id: 'c')),
        throwsA(
          isA<QueueFullException>().having(
            (e) => e.applicantMessage,
            'message',
            contains('Connect to the internet'),
          ),
        ),
      );
    });
  });

  group('what is due, and in what order', () {
    test('holds a submission behind the uploads it references', () async {
      // The server would reject a filing that names documents which do not
      // exist yet.
      final q = queue();
      await q.enqueue(
        op(
          id: 'upload',
          kind: QueuedOperationKind.documentUpload,
          applicationId: 'app-1',
        ),
      );
      await q.enqueue(
        op(id: 'submit', applicationId: 'app-1', dependsOn: const ['upload']),
      );

      expect((await q.due()).map((o) => o.id), ['upload']);
    });

    test('releases the submission once its uploads are done', () async {
      final q = queue();
      await q.enqueue(
        op(
          id: 'upload',
          kind: QueuedOperationKind.documentUpload,
          applicationId: 'app-1',
        ),
      );
      await q.enqueue(
        op(id: 'submit', applicationId: 'app-1', dependsOn: const ['upload']),
      );

      await q.update(
        (await q.all())
            .firstWhere((o) => o.id == 'upload')
            .copyWith(state: QueuedOperationState.completed),
      );

      expect((await q.due()).map((o) => o.id), ['submit']);
    });

    test(
      'sends uploads before a submission for the same application',
      () async {
        final q = queue();
        await q.enqueue(
          op(
            id: 'submit',
            applicationId: 'app-1',
            enqueuedAt: DateTime.utc(2026, 8, 19, 9),
          ),
        );
        await q.enqueue(
          op(
            id: 'upload',
            kind: QueuedOperationKind.documentUpload,
            applicationId: 'app-1',
            enqueuedAt: DateTime.utc(2026, 8, 19, 10),
          ),
        );

        expect((await q.due()).map((o) => o.id), ['upload', 'submit']);
      },
    );

    test('does not hold one application behind another', () async {
      // One stuck filing must not stop an unrelated one.
      final q = queue();
      await q.enqueue(
        op(
          id: 'a',
          applicationId: 'app-1',
          nextAttemptAt: DateTime.utc(2026, 8, 19, 23),
        ),
      );
      await q.enqueue(op(id: 'b', applicationId: 'app-2'));

      expect((await q.due()).map((o) => o.id), ['b']);
    });

    test('respects a backoff that has not elapsed', () async {
      final q = queue();
      await q.enqueue(
        op(id: 'a', nextAttemptAt: DateTime.utc(2026, 8, 19, 13)),
      );

      expect(await q.due(), isEmpty);

      now = DateTime.utc(2026, 8, 19, 14);
      expect(await q.due(), hasLength(1));
    });

    test('never returns an item that already failed permanently', () async {
      final q = queue();
      await q.enqueue(
        op(id: 'a', state: QueuedOperationState.failedPermanently),
      );

      expect(await q.due(), isEmpty);
    });
  });

  group('bounds', () {
    test('prunes what has aged out and reports it', () async {
      // A submission made a year ago is not one the applicant still expects to
      // be filed, but they should be told rather than left to discover it.
      final q = queue(bounds: const QueueBounds(maxAge: Duration(days: 30)));
      await q.enqueue(op(id: 'old', enqueuedAt: DateTime.utc(2026, 6, 1)));
      await q.enqueue(op(id: 'recent', enqueuedAt: DateTime.utc(2026, 8, 18)));

      final pruned = await q.pruneAged();

      expect(pruned.map((o) => o.id), ['old']);
      expect((await q.all()).map((o) => o.id), ['recent']);
    });

    test('prunes nothing when everything is current', () async {
      final q = queue();
      await q.enqueue(op(id: 'a', enqueuedAt: DateTime.utc(2026, 8, 18)));

      expect(await q.pruneAged(), isEmpty);
    });
  });

  group('what the applicant is told', () {
    test('a queued item is NEVER shown as submitted', () async {
      // Believing a filing reached the LGU when it is on the phone means not
      // resending it, and finding out at the counter — possibly after a
      // deadline they thought they had met.
      expect(op(id: 'a').applicantStatus, 'Queued');
      expect(
        op(id: 'a', state: QueuedOperationState.inFlight).applicantStatus,
        'Sending',
      );
      expect(op(id: 'a').isWaitingToReachTheLgu, isTrue);
    });

    test('only a completed item is called submitted', () {
      expect(
        op(id: 'a', state: QueuedOperationState.completed).applicantStatus,
        'Submitted',
      );
    });

    test('a permanently failed item asks for attention rather than hiding', () {
      expect(
        op(
          id: 'a',
          state: QueuedOperationState.failedPermanently,
        ).applicantStatus,
        'Needs your attention',
      );
    });

    test('no state that is waiting is described as submitted', () {
      for (final state in QueuedOperationState.values) {
        final item = op(id: 'a', state: state);
        if (item.isWaitingToReachTheLgu) {
          expect(item.applicantStatus, isNot('Submitted'));
        }
      }
    });
  });
}
