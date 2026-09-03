import 'package:flutter/foundation.dart';

import '../api/api_client.dart';
import '../api/api_exception.dart';
import 'offline_queue.dart';
import 'queued_operation.dart';
import 'sync_engine.dart';

/// Owns the offline queue and drives it.
///
/// **`OfflineQueue` and `SyncEngine` were built, tested, and constructed
/// nowhere.** Both have been complete since TAB 12 — a durable keychain-backed
/// queue with idempotent replay and jittered backoff, and an engine that
/// retries with exponential delay and gives up loudly after eight attempts —
/// and `grep -rn "OfflineQueue(" lib` outside their own files returned nothing.
/// This is B-3 in the closing certification: real code with no live wiring,
/// which made TAB 11's "requests survive a failed network call" true of the
/// unit and false of the product.
///
/// ## What triggers a flush, and what deliberately does not yet
///
/// Foreground only, on purpose, because both alternatives are decisions that
/// are not this lane's to take:
///
/// * **On app resume** and **on explicit retry**. Neither needs a package nor
///   a platform capability, so both work today.
/// * **On regaining connectivity** needs `connectivity_plus` — a new
///   dependency, and adding one to a public LGU app is the owner's call. The
///   [ConnectivityMonitor] seam below exists so that becomes one class rather
///   than a refactor.
/// * **While backgrounded** needs a background-execution entitlement, which
///   changes what Apple reviews. Recorded, not taken.
class SyncProvider extends ChangeNotifier {
  SyncProvider({
    required OfflineQueue queue,
    ApiClient? api,
    SyncEngine? engine,
  }) : _queue = queue,
       _engine =
           engine ?? SyncEngine(queue, (operation) => _send(api, operation));

  final OfflineQueue _queue;
  final SyncEngine _engine;

  OfflineQueue get queue => _queue;

  int _pending = 0;
  int _blocked = 0;
  List<({QueuedOperationKind kind, String? reason})> _blockedDetail = const [];
  bool _flushing = false;
  SyncOutcome? _lastOutcome;

  /// How much work has not reached the LGU **and still can**.
  ///
  /// Shown as "Queued", never as "Submitted" — the applicant is owed the
  /// difference.
  ///
  /// Counts only operations the engine will actually retry. It counted
  /// `all()` until 2026-09-03, which silently included the ones that had
  /// failed permanently: `due()` takes only `pending`, so those are never
  /// sent again, and the banner promised a citizen they would go "when you
  /// are back on a connection" for as long as the app was installed. Try now
  /// could not move them either.
  int get pendingCount => _pending;

  /// Work the office refused, which no amount of retrying will change.
  ///
  /// Kept in the queue rather than discarded — the engine is careful about
  /// that — and reported separately because the citizen has to do something
  /// different about it.
  int get blockedCount => _blocked;
  bool get hasBlockedWork => _blocked > 0;

  /// Why each blocked operation was refused, in the server's own words where
  /// it gave them. Written by the engine since it was built and read by
  /// nothing until now.
  List<({QueuedOperationKind kind, String? reason})> get blocked =>
      List.unmodifiable(_blockedDetail);
  bool get isFlushing => _flushing;
  SyncOutcome? get lastOutcome => _lastOutcome;
  bool get hasPendingWork => _pending > 0;

  /// What is waiting, by kind.
  ///
  /// The count alone cannot be told to the applicant usefully: "3 items
  /// waiting" is not the same statement as "3 files waiting" or "a payment
  /// receipt waiting", and only one of those tells them whether to act.
  Map<QueuedOperationKind, int> get pendingByKind =>
      Map.unmodifiable(_pendingByKind);
  Map<QueuedOperationKind, int> _pendingByKind = const {};

  /// Recounts what is waiting. Cheap, and safe to call on every resume.
  Future<void> refresh() async {
    final all = await _queue.all();
    // Split by what can still happen to it, not by what is in the store.
    final waiting = all
        .where((o) => o.state != QueuedOperationState.failedPermanently)
        .toList();
    final stuck = all
        .where((o) => o.state == QueuedOperationState.failedPermanently)
        .toList();
    final byKind = <QueuedOperationKind, int>{};
    for (final operation in waiting) {
      byKind[operation.kind] = (byKind[operation.kind] ?? 0) + 1;
    }
    final blockedChanged = stuck.length != _blocked;
    _blocked = stuck.length;
    _blockedDetail = [
      for (final o in stuck) (kind: o.kind, reason: o.failureMessage),
    ];
    // Both are compared. Guarding on the count alone held a stale breakdown
    // whenever one operation replaced another of a different kind — the same
    // total, a different thing to tell the applicant.
    // `blockedChanged` is in the guard because the assignment above already
    // happened: returning early on an unchanged waiting count would leave the
    // banner rendering a blocked item the provider has already forgotten.
    if (waiting.length == _pending && _sameKinds(byKind) && !blockedChanged) {
      return;
    }
    _pending = waiting.length;
    _pendingByKind = byKind;
    notifyListeners();
  }

  bool _sameKinds(Map<QueuedOperationKind, int> other) {
    if (other.length != _pendingByKind.length) return false;
    for (final entry in other.entries) {
      if (_pendingByKind[entry.key] != entry.value) return false;
    }
    return true;
  }

  /// Sends everything due.
  ///
  /// Re-entrant calls are ignored rather than queued: a resume that lands
  /// while a flush is already running is the same flush, and starting a second
  /// would double-send anything mid-flight that the engine has not yet marked.
  Future<SyncOutcome?> flush() async {
    if (_flushing) return null;
    _flushing = true;
    notifyListeners();
    try {
      _lastOutcome = await _engine.flush();
      return _lastOutcome;
    } finally {
      _flushing = false;
      await refresh();
      notifyListeners();
    }
  }

  /// Maps a queued operation onto the call that performs it.
  ///
  /// Throws [ApiException] on failure, which is the engine's contract: it
  /// decides from the failure kind whether to defer with backoff or give up.
  /// With no API configured this throws immediately, and the item stays queued
  /// — which is the honest outcome, not a bug.
  static Future<void> _send(ApiClient? api, QueuedOperation operation) async {
    if (api == null) {
      throw ApiException(
        ApiFailure.network,
        'No server is configured for this build, so queued work cannot be '
        'sent. It stays queued.',
      );
    }

    switch (operation.kind) {
      case QueuedOperationKind.contactVerificationRequest:
        final channel = operation.payload['channel'];
        await api.post(
          '/me/contacts/$channel/request',
          body: const {},
          // The queue's own key, created when the operation was enqueued and
          // reused on every retry — which is exactly what the header is for.
          // Every other write in this app makes a fresh key per attempt; this
          // is the one path where a retry is provably the same operation.
          idempotencyKey: operation.idempotencyKey,
        );
      case QueuedOperationKind.documentUpload:
        // The one write the queue can complete on its own: it needs the bytes
        // and a label, both of which are in the payload, and it depends on
        // nothing. The bytes are in the app's own directory — attachments are
        // copied there when picked — so they are still readable after a
        // restart, which is what makes replaying this honest.
        final filePath = operation.payload['filePath'];
        final label = operation.payload['label'];
        if (filePath is! String || label is! String) {
          throw const ApiException(
            ApiFailure.rejected,
            'this queued upload has no file to send',
          );
        }
        await api.upload(
          '/documents',
          filePath: filePath,
          label: label,
          applicationId: operation.applicationId,
          // The queue's own key, so a replay after the server committed
          // returns the original document rather than storing it twice.
          idempotencyKey: operation.idempotencyKey,
        );
      case QueuedOperationKind.applicationSubmission:
      case QueuedOperationKind.instructionResponse:
      case QueuedOperationKind.paymentProof:
        // Deliberately unimplemented rather than faked. Each needs the write
        // path it belongs to — the wizard's draft for a submission, the
        // instruction items for a response — and a `_send` that silently
        // succeeded would drop the applicant's work while reporting it sent.
        //
        // `documentUpload` was one of these until 30 August 2026. It became
        // implementable when two things landed: `POST /documents`, and picked
        // attachments being copied into the app's own directory so their bytes
        // survive to be replayed.
        throw ApiException(
          ApiFailure.network,
          'Replaying ${operation.kind.name} is not wired yet; the item stays '
          'queued rather than being reported as sent.',
        );
    }
  }
}

/// Tells the app when a connection comes back.
///
/// A seam, not an implementation. The only thing standing between this and a
/// connectivity-triggered flush is the owner's decision on adding
/// `connectivity_plus`; when it is taken, one class implements this and
/// nothing else moves.
abstract class ConnectivityMonitor {
  /// Fires when the device regains a usable connection.
  Stream<void> get onRestored;
}
