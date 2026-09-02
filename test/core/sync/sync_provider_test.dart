import 'package:flutter_test/flutter_test.dart';

import 'package:ebpco_user_app/core/api/api_exception.dart';
import 'package:ebpco_user_app/core/sync/offline_queue.dart';
import 'package:ebpco_user_app/core/sync/queued_operation.dart';
import 'package:ebpco_user_app/core/sync/sync_engine.dart';
import 'package:ebpco_user_app/core/sync/sync_provider.dart';

/// B-3: the queue is finally constructed and actually runs.
///
/// `OfflineQueue` and `SyncEngine` were complete and correct since TAB 12 and
/// built by nothing. The closing certification named it: real code with no live
/// wiring, which made TAB 11's "requests survive a failed network call" true of
/// the unit and false of the product.

final _now = DateTime(2026, 8, 29, 10);

QueuedOperation _op(String id, {String channel = 'mobile'}) => QueuedOperation(
  id: id,
  kind: QueuedOperationKind.contactVerificationRequest,
  idempotencyKey: 'contact-verification:$channel:$id',
  enqueuedAt: _now,
  payload: {'channel': channel, 'value': '09171234567'},
);

SyncProvider _provider(
  OfflineQueue queue, {
  Future<void> Function(QueuedOperation)? send,
}) => SyncProvider(
  queue: queue,
  engine: SyncEngine(
    queue,
    send ?? (_) async => throw ApiException(ApiFailure.network, 'offline'),
    clock: () => _now,
  ),
);

void main() {
  test('it counts what is waiting before anything is sent', () async {
    final queue = OfflineQueue(InMemoryQueueStore(), clock: () => _now);
    await queue.enqueue(_op('a'));
    await queue.enqueue(_op('b', channel: 'email'));

    final sync = _provider(queue);
    await sync.refresh();

    expect(sync.pendingCount, 2);
    expect(sync.hasPendingWork, isTrue);
  });

  test('a successful flush empties the queue', () async {
    final queue = OfflineQueue(InMemoryQueueStore(), clock: () => _now);
    await queue.enqueue(_op('a'));

    final sent = <String>[];
    final sync = _provider(
      queue,
      send: (operation) async => sent.add(operation.id),
    );

    final outcome = await sync.flush();

    expect(sent, ['a']);
    expect(outcome!.sent, 1);
    expect(sync.pendingCount, 0);
    expect(await queue.all(), isEmpty);
  });

  test('a failed flush KEEPS the work rather than losing it', () async {
    // The whole point. An applicant who pressed Send on a train believes they
    // have asked; dropping the item would make that belief false silently.
    final queue = OfflineQueue(InMemoryQueueStore(), clock: () => _now);
    await queue.enqueue(_op('a'));

    final sync = _provider(queue);
    await sync.flush();

    expect(sync.pendingCount, 1);
    expect((await queue.all()).single.id, 'a');
    expect(sync.lastOutcome!.sent, 0);
  });

  test('a second flush during the first is ignored, not queued', () async {
    // A resume landing mid-flush is the same flush. Starting a second would
    // double-send anything in flight the engine has not yet marked.
    final queue = OfflineQueue(InMemoryQueueStore(), clock: () => _now);
    await queue.enqueue(_op('a'));

    var calls = 0;
    final sync = _provider(
      queue,
      send: (_) async {
        calls++;
        await Future<void>.delayed(const Duration(milliseconds: 20));
      },
    );

    final first = sync.flush();
    final second = await sync.flush();
    await first;

    expect(second, isNull, reason: 're-entrant flush returns null');
    expect(calls, 1);
  });

  test('listeners hear about the flush starting and finishing', () async {
    final queue = OfflineQueue(InMemoryQueueStore(), clock: () => _now);
    await queue.enqueue(_op('a'));

    final sync = _provider(queue, send: (_) async {});
    var notifications = 0;
    sync.addListener(() => notifications++);

    await sync.flush();

    expect(notifications, greaterThan(1));
    expect(sync.isFlushing, isFalse);
  });

  test('with no API configured, work stays queued and says so', () async {
    // The honest outcome for this build, not a bug: nothing is deployed, so
    // nothing can be sent, and the item must not be reported as delivered.
    final queue = OfflineQueue(InMemoryQueueStore(), clock: () => _now);
    await queue.enqueue(_op('a'));

    final sync = SyncProvider(queue: queue, api: null);
    await sync.flush();

    expect(sync.pendingCount, 1);
    expect(sync.lastOutcome!.sent, 0);
  });

  test('an unwired operation kind is never reported as sent', () async {
    // A `_send` that silently succeeded would drop the applicant's work while
    // telling them it arrived. Each unimplemented kind throws instead.
    final queue = OfflineQueue(InMemoryQueueStore(), clock: () => _now);
    await queue.enqueue(
      QueuedOperation(
        id: 'sub-1',
        kind: QueuedOperationKind.applicationSubmission,
        idempotencyKey: 'sub-1',
        enqueuedAt: _now,
        payload: const {},
      ),
    );

    final sync = SyncProvider(queue: queue, api: null);
    await sync.flush();

    expect(sync.lastOutcome!.sent, 0);
    expect(await queue.all(), hasLength(1));
  });

  test('the breakdown follows the kinds, not just the total', () async {
    // The guard used to return early whenever the total was unchanged, which
    // held a stale breakdown when one operation replaced another of a
    // different kind: the same number waiting, a different thing to tell the
    // citizen.
    final queue = OfflineQueue(InMemoryQueueStore(), clock: () => _now);
    await queue.enqueue(_op('a'));
    final provider = _provider(queue);
    await provider.refresh();

    expect(provider.pendingByKind, {
      QueuedOperationKind.contactVerificationRequest: 1,
    });

    await queue.remove('a');
    await queue.enqueue(
      QueuedOperation(
        id: 'b',
        kind: QueuedOperationKind.documentUpload,
        idempotencyKey: 'k',
        enqueuedAt: _now,
        payload: const {'filePath': '/tmp/a.pdf', 'label': 'Lot Plan'},
      ),
    );
    await provider.refresh();

    expect(provider.pendingByKind, {
      QueuedOperationKind.documentUpload: 1,
    }, reason: 'one in, one out — the total never moved');
  });
}
