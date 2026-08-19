import 'dart:math';

import '../api/api_exception.dart';
import 'offline_queue.dart';
import 'queued_operation.dart';

/// Sends what the queue is holding, and decides what to do when it cannot.
///
/// The judgement that matters is transient versus permanent. Retrying a
/// validation error forever burns the applicant's battery and data and never
/// succeeds; giving up on a dropped connection loses work that would have gone
/// through a minute later. [ApiFailure] already draws that line, so this does
/// not draw a second one.
class SyncEngine {
  SyncEngine(
    this._queue,
    this._send, {
    DateTime Function()? clock,
    Random? random,
    this.maxAttempts = 8,
  })  : _clock = clock ?? DateTime.now,
        _random = random ?? Random();

  final OfflineQueue _queue;

  /// Performs one operation. Throws [ApiException] on failure.
  final Future<void> Function(QueuedOperation) _send;

  final DateTime Function() _clock;
  final Random _random;

  /// After this many tries, a transient failure is treated as permanent.
  ///
  /// Not because it has stopped being transient, but because something the
  /// applicant should look at has clearly gone wrong, and an item retrying
  /// invisibly forever is indistinguishable from one that was lost.
  final int maxAttempts;

  bool _running = false;

  /// The base of the exponential backoff. Doubling from thirty seconds reaches
  /// roughly an hour by the eighth attempt.
  static const _baseDelay = Duration(seconds: 30);
  static const _maxDelay = Duration(hours: 1);

  /// Sends everything currently due.
  ///
  /// Re-entrant calls are ignored rather than queued: a connectivity event
  /// arriving while a flush is in progress must not start a second one, which
  /// would send the same item twice — and although the idempotency key makes
  /// that safe on the server, it wastes an applicant's data on a connection
  /// that has just proven to be poor.
  Future<SyncOutcome> flush() async {
    if (_running) return const SyncOutcome(skipped: true);
    _running = true;
    try {
      var sent = 0;
      var deferred = 0;
      var failed = 0;

      for (final operation in await _queue.due()) {
        final result = await _attempt(operation);
        switch (result) {
          case _AttemptResult.sent:
            sent += 1;
          case _AttemptResult.deferred:
            deferred += 1;
          case _AttemptResult.failed:
            failed += 1;
        }
      }

      return SyncOutcome(sent: sent, deferred: deferred, failed: failed);
    } finally {
      _running = false;
    }
  }

  Future<_AttemptResult> _attempt(QueuedOperation operation) async {
    await _queue.update(operation.copyWith(state: QueuedOperationState.inFlight));

    try {
      await _send(operation);
    } on ApiException catch (error) {
      return _handleFailure(operation, error);
    } catch (error) {
      // Anything unexpected is treated as transient. Being wrong that way costs
      // a retry; being wrong the other way discards an applicant's filing over
      // a bug.
      return _defer(operation, 'Could not be sent. It will be retried automatically.');
    }

    // The item leaves the queue only after the LGU has it.
    await _queue.remove(operation.id);
    return _AttemptResult.sent;
  }

  Future<_AttemptResult> _handleFailure(QueuedOperation operation, ApiException error) async {
    if (!error.failure.isTransient) {
      // Nothing about retrying changes a rejected filing, an expired session or
      // a contract mismatch.
      await _queue.update(operation.copyWith(
        state: QueuedOperationState.failedPermanently,
        attempts: operation.attempts + 1,
        // The server's own words where it gave them: it knows the specifics.
        failureMessage: error.applicantMessage,
        clearNextAttempt: true,
      ));
      return _AttemptResult.failed;
    }

    if (operation.attempts + 1 >= maxAttempts) {
      await _queue.update(operation.copyWith(
        state: QueuedOperationState.failedPermanently,
        attempts: operation.attempts + 1,
        failureMessage:
            'This could not be sent after several attempts. Open it to try again or to check '
            'your connection.',
        clearNextAttempt: true,
      ));
      return _AttemptResult.failed;
    }

    return _defer(operation, error.applicantMessage);
  }

  Future<_AttemptResult> _defer(QueuedOperation operation, String reason) async {
    final attempts = operation.attempts + 1;
    await _queue.update(operation.copyWith(
      state: QueuedOperationState.pending,
      attempts: attempts,
      nextAttemptAt: _clock().add(backoffFor(attempts)),
      failureMessage: reason,
    ));
    return _AttemptResult.deferred;
  }

  /// Exponential, capped, with jitter.
  ///
  /// The jitter is not decoration: without it every device that lost the same
  /// cell tower retries at the same instant, and the LGU's server meets a
  /// thundering herd exactly as it comes back up.
  Duration backoffFor(int attempts) {
    final exponential = _baseDelay * pow(2, (attempts - 1).clamp(0, 10)).toInt();
    final capped = exponential > _maxDelay ? _maxDelay : exponential;
    // Up to 30% either way.
    final jitter = (capped.inMilliseconds * 0.3 * (_random.nextDouble() * 2 - 1)).round();
    return Duration(milliseconds: (capped.inMilliseconds + jitter).clamp(1000, _maxDelay.inMilliseconds));
  }
}

enum _AttemptResult { sent, deferred, failed }

class SyncOutcome {
  const SyncOutcome({this.sent = 0, this.deferred = 0, this.failed = 0, this.skipped = false});

  final int sent;
  final int deferred;
  final int failed;

  /// True when a flush was already running. Not an error.
  final bool skipped;

  bool get didAnything => sent > 0 || deferred > 0 || failed > 0;
}
