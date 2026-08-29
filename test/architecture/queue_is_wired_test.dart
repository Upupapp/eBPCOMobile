import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// B-3, as a gate rather than a note.
///
/// The closing certification recorded that `OfflineQueue` and `SyncEngine`
/// were built, tested, and constructed **nowhere** in `lib/` — and it asserted
/// that fact in `certification_claims_test.dart` so the document could not
/// silently become wrong. Now that they ARE wired, the assertion has to turn
/// around: the risk is no longer that nobody built them, it is that somebody
/// unbuilds them and the only evidence is an applicant losing work.

void main() {
  final app = File('lib/app.dart').readAsStringSync();

  test('the app constructs a durable queue, not an in-memory one', () {
    // An InMemoryQueueStore here would pass every unit test in the suite and
    // lose the applicant's queued work on every app restart — which is the
    // exact failure the queue exists to prevent.
    expect(app, contains('OfflineQueue(SecureQueueStore())'));
    expect(
      app,
      isNot(contains('OfflineQueue(InMemoryQueueStore())')),
      reason: 'the production queue must survive a restart',
    );
  });

  test('something actually flushes it', () {
    // A constructed queue that nothing drains is the same defect wearing a
    // different shape: work accumulates and never leaves.
    expect(app, contains('didChangeAppLifecycleState'));
    expect(app, contains('_sync.flush()'));
    expect(
      app,
      contains('WidgetsBinding.instance.addObserver(this)'),
      reason: 'the lifecycle callback only fires for a registered observer',
    );
  });

  test('the contact verification provider is given the real queue', () {
    // TAB 11 built enqueue-on-failure and could only be handed null. Its
    // acceptance criterion depended on this line existing.
    expect(app, contains('queue: _sync.queue'));
  });

  test('one queue, not two', () {
    // Two OfflineQueue instances over one keychain key would each overwrite
    // the other's saves, which loses work in a way no test of either alone
    // would show.
    final constructions = RegExp(r'OfflineQueue\(').allMatches(app).length;
    expect(constructions, 1, reason: 'found $constructions in lib/app.dart');
  });
}
