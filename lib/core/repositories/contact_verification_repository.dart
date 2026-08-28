import '../contract/admin_vocabulary.dart';
import '../models/contact_verification.dart';

/// Thrown when the LGU has not switched this on yet.
///
/// Distinct from a network failure and from a rejected code, and treated
/// differently by all three: a queued request is worth retrying, a rejected
/// code is the applicant's to fix, and this is neither.
class VerificationNotAvailable implements Exception {
  const VerificationNotAvailable();
  @override
  String toString() => 'Contact verification is not yet available.';
}

/// The office rejected the code or the link.
class VerificationRejected implements Exception {
  const VerificationRejected(this.reason);
  final String reason;
  @override
  String toString() => reason;
}

/// Asks the LGU to verify a contact channel, and confirms it.
///
/// **Neither half can be completed by this app.** Sending an email link or an
/// SMS one-time code, and checking what comes back, is the server's work: a
/// code this app generated and then checked against itself would verify
/// nothing except that the applicant can read their own screen.
///
/// So the interface exists, the screens exist, and the mock below refuses to
/// fabricate a success. Recorded for the backend lane as M-45 rather than
/// mocked into looking finished.
abstract class ContactVerificationRepository {
  /// Asks for a link or a code. Returns the channel's new state.
  Future<ContactVerification> request(ContactVerification channel);

  /// Submits the code the applicant received.
  ///
  /// Throws [VerificationRejected] when the office refuses it, and
  /// [VerificationNotAvailable] where there is nothing to submit to.
  Future<ContactVerification> confirm(
    ContactVerification channel, {
    required String code,
  });
}

/// What the app can honestly do with no server behind it.
class MockContactVerificationRepository
    implements ContactVerificationRepository {
  MockContactVerificationRepository({DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final DateTime Function() _clock;

  @override
  Future<ContactVerification> request(ContactVerification channel) async {
    // Recording that a request was made is true. Anything beyond it would not
    // be: no link has been sent, and the applicant should not be left waiting
    // for one — the screen says so.
    return channel.copyWith(
      status: ContactVerificationStatus.pendingVerification,
      lastRequestedAt: _clock(),
    );
  }

  @override
  Future<ContactVerification> confirm(
    ContactVerification channel, {
    required String code,
  }) async {
    // The one thing this must never do is return `verified`. A green tick the
    // office did not put there is worse than no tick at all: it tells the
    // applicant their number is confirmed for the notices that will decide
    // their permit.
    throw const VerificationNotAvailable();
  }
}
