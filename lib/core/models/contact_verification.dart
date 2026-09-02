import '../contract/admin_vocabulary.dart';

/// Which contact detail is being verified.
///
/// Two channels, because the office uses both and for different things: every
/// notice goes to one of them, and the applicant is telephoned about an ocular
/// inspection. An account whose email is confirmed and whose mobile number is
/// not is a real and common state, and one status for the pair could not
/// express it.
enum ContactChannel {
  email('Email address'),
  mobile('Mobile number');

  const ContactChannel(this.label);
  final String label;

  /// The method the applicant can drive themselves.
  ///
  /// The admin models four methods; the other two — a clerk confirming by
  /// hand, and matching against a verified identity document — happen at the
  /// office and are not offered here.
  ContactVerificationMethod get applicantMethod => switch (this) {
    ContactChannel.email => ContactVerificationMethod.emailVerificationLink,
    ContactChannel.mobile => ContactVerificationMethod.mobileOtp,
  };
}

/// Whether a link or a code actually left the office.
///
/// Mirrors the `delivery` field the server returns on a verification request,
/// which answers `not-sent` while the LGU has chosen no email or SMS provider.
/// The app read the 202 and ignored this field, so it showed "Code from the
/// SMS" over a code that could not exist and asked the applicant to wait for
/// it. Anything unrecognised on the wire maps to [notSent]: the failure that
/// costs an applicant an afternoon is claiming a send that did not happen.
enum ContactDelivery {
  sent('sent'),
  notSent('not-sent');

  const ContactDelivery(this.wire);
  final String wire;

  static ContactDelivery fromWire(String? value) =>
      value == ContactDelivery.sent.wire
      ? ContactDelivery.sent
      : ContactDelivery.notSent;
}

/// The state of one contact channel.
///
/// The app registered an account and verified nothing, while the admin has
/// carried four statuses and four methods all along. The office cannot rely on
/// the details it uses to send every notice, and the applicant was never told
/// there was anything to do.
class ContactVerification {
  final ContactChannel channel;

  /// The address or number as the applicant gave it. Empty when they have
  /// given none, which is its own state: nothing to verify is not the same as
  /// unverified.
  final String value;

  final ContactVerificationStatus status;

  /// How it was verified, once it has been. Null while it has not — including
  /// while a request is pending, because the method that eventually succeeds
  /// may not be the one the applicant started.
  final ContactVerificationMethod? verifiedBy;

  final DateTime? verifiedAt;

  /// When the applicant last asked for a link or a code. Null if they never
  /// have, which is what separates "not yet attempted" from "attempted and
  /// failed" even before a status has moved.
  final DateTime? lastRequestedAt;

  /// Why the last attempt failed, in the office's words. Required whenever
  /// [status] is `verificationFailed`, for the same reason a rejected document
  /// carries remarks: "Failed" alone leaves the applicant to guess.
  final String? failureReason;

  /// Whether the last request actually dispatched anything.
  ///
  /// Defaults to [ContactDelivery.notSent] so a channel constructed without
  /// asking cannot imply a code is in flight.
  final ContactDelivery delivery;

  const ContactVerification({
    required this.channel,
    required this.value,
    this.status = ContactVerificationStatus.unverified,
    this.verifiedBy,
    this.verifiedAt,
    this.lastRequestedAt,
    this.failureReason,
    this.delivery = ContactDelivery.notSent,
  });

  bool get isVerified => status == ContactVerificationStatus.verified;
  bool get isPending => status == ContactVerificationStatus.pendingVerification;
  bool get hasFailed => status == ContactVerificationStatus.verificationFailed;

  /// A code or link is genuinely in flight and worth waiting for.
  ///
  /// The condition for showing the code entry field. [isPending] alone is not:
  /// the office records the request whether or not it could send anything.
  bool get awaitingCode => isPending && delivery == ContactDelivery.sent;

  /// Asked for, but nothing was sent — the office has no way to send it yet.
  bool get requestedButUndeliverable =>
      isPending && delivery == ContactDelivery.notSent;

  /// Nothing has been supplied to verify.
  bool get isMissing => value.trim().isEmpty;

  /// Never attempted — as distinct from attempted and failed.
  ///
  /// The acceptance criterion this exists for. An applicant who has never
  /// asked for a code and one whose code was rejected are in different
  /// positions and need different words, and both would otherwise read as
  /// "Unverified".
  bool get isUnattempted =>
      status == ContactVerificationStatus.unverified && lastRequestedAt == null;

  /// What the profile says about it. The office's own vocabulary, not a
  /// friendlier paraphrase — the applicant may be quoting this at a counter.
  String get label {
    if (isMissing) return 'Not provided';
    return status.wire;
  }

  ContactVerification copyWith({
    String? value,
    ContactVerificationStatus? status,
    ContactVerificationMethod? verifiedBy,
    DateTime? verifiedAt,
    DateTime? lastRequestedAt,
    String? failureReason,
    ContactDelivery? delivery,
    bool clearFailure = false,
  }) => ContactVerification(
    channel: channel,
    value: value ?? this.value,
    status: status ?? this.status,
    verifiedBy: verifiedBy ?? this.verifiedBy,
    verifiedAt: verifiedAt ?? this.verifiedAt,
    lastRequestedAt: lastRequestedAt ?? this.lastRequestedAt,
    failureReason: clearFailure ? null : (failureReason ?? this.failureReason),
    delivery: delivery ?? this.delivery,
  );
}
