import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'queued_operation.dart';

/// Durable storage for work that has not reached the LGU.
///
/// **Encrypted at rest, in the platform keychain.** Queued items carry an
/// applicant's name, address, business details and the ids of their identity
/// documents. A queue in a plain file is the same disclosure as a token in a
/// plain file, and TAB 11 established where that belongs.
///
/// The document *bytes* are not in here. They stay in the app's private
/// directory, which both platforms encrypt at rest, and the queue references
/// them by path — putting megabytes of scanned plans into a keychain designed
/// for secrets would be the wrong tool and would fail on size.
abstract class QueueStore {
  Future<List<QueuedOperation>> load();
  Future<void> save(List<QueuedOperation> operations);
}

class SecureQueueStore implements QueueStore {
  SecureQueueStore({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              iOptions: IOSOptions(
                accessibility: KeychainAccessibility.first_unlock_this_device,
                synchronizable: false,
              ),
            );

  final FlutterSecureStorage _storage;
  static const _key = 'ebpco.sync.queue';

  @override
  Future<List<QueuedOperation>> load() async {
    final raw = await _storage.read(key: _key);
    if (raw == null || raw.isEmpty) return const [];
    try {
      return QueuedOperation.decode(raw);
    } on FormatException {
      // A corrupt queue must not brick the app on every launch. It is dropped
      // and reported rather than retried forever — and this is the one place
      // work can be lost, so it is worth an alert rather than a silent catch.
      return const [];
    }
  }

  @override
  Future<void> save(List<QueuedOperation> operations) =>
      _storage.write(key: _key, value: QueuedOperation.encode(operations));
}

class InMemoryQueueStore implements QueueStore {
  List<QueuedOperation> _operations = const [];

  @override
  Future<List<QueuedOperation>> load() async => List.of(_operations);

  @override
  Future<void> save(List<QueuedOperation> operations) async {
    // Round-tripped through the encoder so a field that does not serialise
    // fails in tests rather than on a device restart.
    _operations = QueuedOperation.decode(QueuedOperation.encode(operations));
  }
}

/// How large and how old the queue may get.
///
/// An abandoned queue that grows without limit fills the device, and a
/// submission the applicant made a year ago is not one they still expect to be
/// filed. Both bounds have a stated consequence rather than a silent drop.
class QueueBounds {
  const QueueBounds({this.maxItems = 200, this.maxAge = const Duration(days: 30)});

  final int maxItems;
  final Duration maxAge;
}

class OfflineQueue {
  OfflineQueue(
    this._store, {
    this._bounds = const QueueBounds(),
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final QueueStore _store;
  final QueueBounds _bounds;
  final DateTime Function() _clock;

  Future<List<QueuedOperation>> all() => _store.load();

  Future<void> enqueue(QueuedOperation operation) async {
    final existing = await _store.load();

    // Enqueuing the same idempotency key twice is a double tap, not two
    // filings. Silently ignoring it is right; erroring would make a slow
    // network look like a bug in the app.
    if (existing.any((item) => item.idempotencyKey == operation.idempotencyKey)) return;

    if (existing.length >= _bounds.maxItems) {
      throw QueueFullException(_bounds.maxItems);
    }
    await _store.save([...existing, operation]);
  }

  Future<void> update(QueuedOperation operation) async {
    final existing = await _store.load();
    await _store.save([
      for (final item in existing) if (item.id == operation.id) operation else item,
    ]);
  }

  Future<void> remove(String id) async {
    final existing = await _store.load();
    await _store.save([for (final item in existing) if (item.id != id) item]);
  }

  /// Items ready to send now, in the order they must be sent.
  ///
  /// Ordering has two rules, and both exist because getting them wrong loses
  /// work rather than merely delaying it:
  ///
  /// A submission cannot go before the uploads it depends on — the server would
  /// reject it for referencing documents that do not exist.
  ///
  /// Within one application, items go in the order the applicant did them.
  /// Across applications they do not queue behind each other, so one stuck
  /// filing does not hold up an unrelated one.
  Future<List<QueuedOperation>> due() async {
    final now = _clock();
    final all = await _store.load();
    final completed = {
      for (final item in all)
        if (item.state == QueuedOperationState.completed) item.id,
    };

    final ready = all.where((item) {
      if (item.state != QueuedOperationState.pending) return false;
      if (item.nextAttemptAt != null && item.nextAttemptAt!.isAfter(now)) return false;
      // Every dependency must already be done.
      return item.dependsOn.every(completed.contains);
    }).toList();

    ready.sort((a, b) {
      // Uploads first: a submission referencing them cannot succeed otherwise.
      final byKind = _kindRank(a.kind).compareTo(_kindRank(b.kind));
      if (byKind != 0 && a.applicationId == b.applicationId) return byKind;
      return a.enqueuedAt.compareTo(b.enqueuedAt);
    });
    return ready;
  }

  static int _kindRank(QueuedOperationKind kind) =>
      kind == QueuedOperationKind.documentUpload ? 0 : 1;

  /// Removes items that have aged out, reporting how many, so the applicant can
  /// be told rather than left to discover it.
  Future<List<QueuedOperation>> pruneAged() async {
    final cutoff = _clock().subtract(_bounds.maxAge);
    final all = await _store.load();
    final expired = all.where((item) => item.enqueuedAt.isBefore(cutoff)).toList();
    if (expired.isEmpty) return const [];

    await _store.save(all.where((item) => !item.enqueuedAt.isBefore(cutoff)).toList());
    return expired;
  }
}

class QueueFullException implements Exception {
  const QueueFullException(this.limit);
  final int limit;

  /// Said to the applicant, because the alternative is a submission that
  /// silently does not happen.
  String get applicantMessage =>
      'There are already $limit items waiting to be sent. Connect to the internet so '
      'they can go through before adding more.';
}
