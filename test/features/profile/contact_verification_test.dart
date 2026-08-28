import 'package:flutter_test/flutter_test.dart';

import 'package:ebpco_user_app/core/contract/admin_vocabulary.dart';
import 'package:ebpco_user_app/core/models/contact_verification.dart';
import 'package:ebpco_user_app/core/providers/contact_verification_provider.dart';
import 'package:ebpco_user_app/core/repositories/contact_verification_repository.dart';
import 'package:ebpco_user_app/core/sync/offline_queue.dart';
import 'package:ebpco_user_app/core/sync/queued_operation.dart';

/// Per-channel contact verification, and the three ways it can fail.
///
/// The app registered an account and verified nothing, while the admin has
/// carried four statuses and four methods since the first reconciliation. The
/// office could not rely on the address it sends every notice to.

final _now = DateTime(2026, 8, 28, 10);

class _Refusing implements ContactVerificationRepository {
  @override
  Future<ContactVerification> request(ContactVerification channel) async =>
      channel.copyWith(
        status: ContactVerificationStatus.pendingVerification,
        lastRequestedAt: _now,
      );

  @override
  Future<ContactVerification> confirm(
    ContactVerification channel, {
    required String code,
  }) async => throw const VerificationRejected('That code has expired.');
}

class _Accepting implements ContactVerificationRepository {
  @override
  Future<ContactVerification> request(ContactVerification channel) async =>
      channel.copyWith(
        status: ContactVerificationStatus.pendingVerification,
        lastRequestedAt: _now,
      );

  @override
  Future<ContactVerification> confirm(
    ContactVerification channel, {
    required String code,
  }) async => channel.copyWith(
    status: ContactVerificationStatus.verified,
    verifiedBy: channel.channel.applicantMethod,
    verifiedAt: _now,
  );
}

class _Offline implements ContactVerificationRepository {
  @override
  Future<ContactVerification> request(ContactVerification channel) async =>
      throw Exception('SocketException: failed host lookup');

  @override
  Future<ContactVerification> confirm(
    ContactVerification channel, {
    required String code,
  }) async => throw Exception('SocketException: failed host lookup');
}

ContactVerificationProvider _provider({
  ContactVerificationRepository? repository,
  OfflineQueue? queue,
  String email = 'juan@example.com',
  String mobileNumber = '09171234567',
}) => ContactVerificationProvider(
  repository:
      repository ?? MockContactVerificationRepository(clock: () => _now),
  queue: queue,
  email: email,
  mobileNumber: mobileNumber,
  clock: () => _now,
);

void main() {
  group('per channel, not per account', () {
    test('both channels start unverified and unattempted', () {
      final provider = _provider();
      for (final channel in ContactChannel.values) {
        final state = provider.of(channel);
        expect(state.status, ContactVerificationStatus.unverified);
        expect(state.isUnattempted, isTrue);
        expect(state.label, 'Unverified');
      }
    });

    test('one can be verified while the other is not', () async {
      // The state a single account-level status could not express, and the
      // reason this is modelled per channel at all.
      final provider = _provider(repository: _Accepting());
      await provider.request(ContactChannel.email);
      await provider.confirm(ContactChannel.email, '123456');

      expect(provider.of(ContactChannel.email).isVerified, isTrue);
      expect(provider.of(ContactChannel.mobile).isVerified, isFalse);
    });

    test('a channel with nothing in it is not actionable', () {
      // There is nothing to send a code to. Offering the button anyway is an
      // invitation to a dead end.
      final provider = _provider(mobileNumber: '');
      expect(provider.of(ContactChannel.mobile).isMissing, isTrue);
      expect(provider.of(ContactChannel.mobile).label, 'Not provided');
      expect(provider.actionable.map((c) => c.channel), [ContactChannel.email]);
    });

    test('requesting on an empty channel does nothing', () async {
      final provider = _provider(email: '');
      await provider.request(ContactChannel.email);
      expect(
        provider.of(ContactChannel.email).status,
        ContactVerificationStatus.unverified,
      );
    });
  });

  group('a failed verification is distinguishable from an unattempted one', () {
    test('a rejected code is Verification Failed, with the reason', () async {
      final provider = _provider(repository: _Refusing());
      await provider.request(ContactChannel.mobile);
      await provider.confirm(ContactChannel.mobile, '000000');

      final state = provider.of(ContactChannel.mobile);
      expect(state.status, ContactVerificationStatus.verificationFailed);
      expect(state.label, 'Verification Failed');
      // The reason, verbatim. "Failed" alone leaves the applicant to guess
      // whether to try the same code again.
      expect(state.failureReason, 'That code has expired.');
      expect(state.isUnattempted, isFalse);
      expect(provider.outcome, VerificationOutcome.rejected);
    });

    test('never asking is Unverified and unattempted', () {
      final provider = _provider();
      final state = provider.of(ContactChannel.mobile);
      expect(state.label, 'Unverified');
      expect(state.isUnattempted, isTrue);
      expect(state.failureReason, isNull);
    });

    test('asking and waiting is Pending Verification', () async {
      final provider = _provider();
      await provider.request(ContactChannel.mobile);

      final state = provider.of(ContactChannel.mobile);
      expect(state.label, 'Pending Verification');
      expect(state.lastRequestedAt, _now);
      expect(state.isUnattempted, isFalse);
    });

    test('a fresh request clears the previous failure', () async {
      final provider = _provider(repository: _Refusing());
      await provider.request(ContactChannel.mobile);
      await provider.confirm(ContactChannel.mobile, '000000');
      expect(provider.of(ContactChannel.mobile).hasFailed, isTrue);

      await provider.request(ContactChannel.mobile);
      final state = provider.of(ContactChannel.mobile);
      expect(state.isPending, isTrue);
      expect(state.failureReason, isNull);
    });
  });

  group('nothing is fabricated', () {
    test(
      'the mock repository refuses to confirm rather than inventing a tick',
      () async {
        // The one thing this must never do. A green tick the office did not put
        // there tells the applicant their number is confirmed for the notices
        // that will decide their permit.
        final provider = _provider();
        await provider.request(ContactChannel.email);
        await provider.confirm(ContactChannel.email, '123456');

        expect(provider.of(ContactChannel.email).isVerified, isFalse);
        expect(provider.outcome, VerificationOutcome.unavailable);
        expect(provider.message, contains('has not switched on'));
      },
    );

    test('and does not mark the channel Failed for it', () async {
      // The applicant did nothing wrong. Marking their channel Failed would
      // say they had.
      final provider = _provider();
      await provider.request(ContactChannel.email);
      await provider.confirm(ContactChannel.email, '123456');

      expect(provider.of(ContactChannel.email).hasFailed, isFalse);
      expect(provider.of(ContactChannel.email).isPending, isTrue);
    });
  });

  group('a request survives a failed network call', () {
    test('it is queued rather than dropped', () async {
      final queue = OfflineQueue(InMemoryQueueStore(), clock: () => _now);
      final provider = _provider(repository: _Offline(), queue: queue);

      await provider.request(ContactChannel.mobile);

      final queued = await queue.all();
      expect(queued, hasLength(1));
      expect(
        queued.single.kind,
        QueuedOperationKind.contactVerificationRequest,
      );
      expect(queued.single.payload['value'], '09171234567');
      expect(queued.single.payload['method'], 'Mobile OTP');
      expect(provider.outcome, VerificationOutcome.queued);
      expect(provider.message, contains('offline'));
    });

    test('tapping four times on a bad connection asks once', () async {
      // One outstanding request per channel. Four codes would be four SMS the
      // applicant did not ask for, and a queue that never drains.
      final queue = OfflineQueue(InMemoryQueueStore(), clock: () => _now);
      final provider = _provider(repository: _Offline(), queue: queue);

      for (var i = 0; i < 4; i++) {
        await provider.request(ContactChannel.mobile);
      }

      expect(await queue.all(), hasLength(1));
    });

    test('a queued request records that the applicant asked', () async {
      // They pressed Send and believe they have asked. The channel has to say
      // so, or the screen offers them the button again as if nothing happened.
      final queue = OfflineQueue(InMemoryQueueStore(), clock: () => _now);
      final provider = _provider(repository: _Offline(), queue: queue);

      await provider.request(ContactChannel.mobile);

      expect(provider.of(ContactChannel.mobile).lastRequestedAt, _now);
      expect(provider.of(ContactChannel.mobile).isUnattempted, isFalse);
    });

    test('with no queue at all it still does not claim success', () async {
      final provider = _provider(repository: _Offline());
      await provider.request(ContactChannel.email);
      expect(provider.of(ContactChannel.email).isPending, isFalse);
    });
  });

  group('a changed contact detail is an unverified contact detail', () {
    test('editing the email drops its verified status', () async {
      // Otherwise someone could confirm one mailbox and substitute another.
      final provider = _provider(repository: _Accepting());
      await provider.request(ContactChannel.email);
      await provider.confirm(ContactChannel.email, '123456');
      expect(provider.of(ContactChannel.email).isVerified, isTrue);

      provider.updateContactDetails(email: 'someone.else@example.com');

      final state = provider.of(ContactChannel.email);
      expect(state.value, 'someone.else@example.com');
      expect(state.isVerified, isFalse);
      expect(state.isUnattempted, isTrue);
    });

    test('an unchanged value keeps its status', () async {
      final provider = _provider(repository: _Accepting());
      await provider.request(ContactChannel.email);
      await provider.confirm(ContactChannel.email, '123456');

      provider.updateContactDetails(email: 'juan@example.com');

      expect(provider.of(ContactChannel.email).isVerified, isTrue);
    });

    test('a null means "unchanged", not "cleared"', () {
      final provider = _provider();
      provider.updateContactDetails(mobileNumber: '09998887777');
      expect(provider.of(ContactChannel.email).value, 'juan@example.com');
    });
  });

  test('the two applicant-driven methods are the ones offered', () {
    // The admin models four. A clerk confirming by hand and matching against a
    // verified identity document both happen at the office, and the screen
    // names them rather than pretending they do not exist.
    expect(
      ContactChannel.email.applicantMethod,
      ContactVerificationMethod.emailVerificationLink,
    );
    expect(
      ContactChannel.mobile.applicantMethod,
      ContactVerificationMethod.mobileOtp,
    );
  });

  test('the labels are the office\'s own words', () {
    // The applicant may be quoting these at a counter, so they are the admin's
    // wire strings rather than a friendlier paraphrase.
    for (final status in ContactVerificationStatus.values) {
      final state = ContactVerification(
        channel: ContactChannel.email,
        value: 'juan@example.com',
        status: status,
      );
      expect(state.label, status.wire);
    }
  });
}
