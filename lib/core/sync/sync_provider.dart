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
  bool _flushing = false;
  SyncOutcome? _lastOutcome;

  /// How much work has not reached the LGU.
  ///
  /// Shown as "Queued", never as "Submitted" — the applicant is owed the
  /// difference.
  int get pendingCount => _pending;
  bool get isFlushing => _flushing;
  SyncOutcome? get lastOutcome => _lastOutcome;
  bool get hasPendingWork => _pending > 0;

  /// Recounts what is waiting. Cheap, and safe to call on every resume.
  Future<void> refresh() async {
    final all = await _queue.all();
    if (all.length == _pending) return;
    _pending = all.length;
    notifyListeners();
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
