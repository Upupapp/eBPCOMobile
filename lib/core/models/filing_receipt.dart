/// What the office actually received, as the office answered it.
///
/// The confirmation screens showed a green tick, a reference number and the
/// permit type, and nothing about the filing itself. That shape is how this
/// app's two worst defects stayed hidden for their whole lives: `documents`
/// was hardcoded to `const []`, so not one attachment was ever sent, and no
/// wizard sent `form`, so 239 typed fields were dropped at the wire. In both
/// cases the wizard collected the work, the review step listed it, and the
/// confirmation said Submitted. Nothing on any screen was in a position to
/// disagree.
///
/// So every number here is **what came back or what the server issued**, never
/// what the draft held. [documentIdsIssued] are ids the server minted during
/// upload; [attachmentsOffered] is what the citizen attached. When those two
/// disagree the receipt says so rather than reporting the larger one.
class FilingReceipt {
  final String applicationId;

  /// The reference the server assigned, not the one generated locally.
  final String referenceNumber;

  /// The permit type **as the server recorded it**, which is not always what
  /// was sent: the office's list is the authority, and a type it does not hold
  /// is refused rather than quietly renamed. Null when it answered none.
  final String? permitType;

  final DateTime submittedAt;

  /// The one-line site, echoed back. Null where the wizard has no site of its
  /// own — the two BFP clearances attach to a building permit that carries it.
  final String? location;

  /// How many attachments the citizen added in the wizard.
  final int attachmentsOffered;

  /// The ids the server minted, one per file it accepted.
  final List<String> documentIdsIssued;

  /// How many answers were sent in `form`.
  final int answersSent;

  const FilingReceipt({
    required this.applicationId,
    required this.referenceNumber,
    required this.permitType,
    required this.submittedAt,
    required this.location,
    required this.attachmentsOffered,
    required this.documentIdsIssued,
    required this.answersSent,
  });

  int get attachmentsAccepted => documentIdsIssued.length;

  /// The citizen attached files and the office holds fewer of them.
  ///
  /// The state the old confirmation screen could not express. It is reachable
  /// on a build with no upload repository, where every id comes back empty —
  /// which is precisely the condition that shipped for weeks unnoticed.
  bool get attachmentsAreShort => attachmentsAccepted < attachmentsOffered;

  /// Nothing was typed anywhere, or nothing was sent. Worth saying out loud:
  /// a filing carrying no answers is one the office cannot assess.
  bool get carriesNoAnswers => answersSent == 0;
}
