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

  const ContactVerification({
    required this.channel,
    required this.value,
    this.status = ContactVerificationStatus.unverified,
    this.verifiedBy,
    this.verifiedAt,
    this.lastRequestedAt,
    this.failureReason,
  });

  bool get isVerified => status == ContactVerificationStatus.verified;
  bool get isPending => status == ContactVerificationStatus.pendingVerification;
  bool get hasFailed => status == ContactVerificationStatus.verificationFailed;

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
    bool clearFailure = false,
  }) => ContactVerification(
    channel: channel,
    value: value ?? this.value,
    status: status ?? this.status,
    verifiedBy: verifiedBy ?? this.verifiedBy,
    verifiedAt: verifiedAt ?? this.verifiedAt,
    lastRequestedAt: lastRequestedAt ?? this.lastRequestedAt,
    failureReason: clearFailure ? null : (failureReason ?? this.failureReason),
  );
}
