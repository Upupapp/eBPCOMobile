/// A standard, reusable reason an office turns a document back.
///
/// Owner decision, 2026-08-28: a rejected document carries **both** a standard
/// reusable reason and custom feedback written for this applicant. The two do
/// different jobs. The code is what the LGU can count — "what do we reject
/// most?" is unanswerable from free text — and what renders consistently
/// whoever typed it. The remark is what tells *this* applicant what is wrong
/// with *this* document: "Illegible" does not say which page.
///
/// **Deliberately NOT an enum, and this is the point.**
///
/// Every other vocabulary this app mirrors — permit types, document statuses,
/// payment statuses — is a *closed* set owned by the admin, and
/// `admin_vocabulary.dart` parses them strictly, throwing [UnknownWireValue]
/// rather than defaulting, because a status the app invents a meaning for is
/// how an applicant gets told their document was accepted.
///
/// This one is the opposite. The reasons are a **catalogue the LGU edits** —
/// an office that learns a new way to be disappointed adds a row, and no client
/// ships to accommodate it. Parsing it strictly would turn an ordinary
/// administrative act into a crash on the applicant's phone. So an unrecognised
/// code renders rather than throwing, and the server's label is preferred over
/// anything held here.
class DocumentReviewReason {
  /// Stable across renames. An LGU rewording "Illegible" to "Not readable" has
  /// not created a different reason, and a label used as an identifier would
  /// make it one.
  final String code;

  /// What the office calls it, as the office sent it.
  final String label;

  /// The longer explanation, where the catalogue carries one.
  final String description;

  const DocumentReviewReason({
    required this.code,
    required this.label,
    this.description = '',
  });

  /// Reads a reason off the wire.
  ///
  /// A missing or empty label is not a failure: it means this client has met a
  /// code the LGU added after it shipped. The code is humanised so the
  /// applicant sees *something* meaningful rather than a blank chip or a crash
  /// — `not-certified-true-copy` becomes "Not certified true copy".
  factory DocumentReviewReason.fromWire({
    required String code,
    String? label,
    String? description,
  }) => DocumentReviewReason(
    code: code,
    label: (label != null && label.trim().isNotEmpty)
        ? label.trim()
        : humaniseCode(code),
    description: description?.trim() ?? '',
  );

  /// `not-certified-true-copy` → `Not certified true copy`.
  static String humaniseCode(String code) {
    final words = code.trim().split(RegExp(r'[-_\s]+'))
      ..removeWhere((w) => w.isEmpty);
    if (words.isEmpty) return 'Unspecified reason';
    final first = words.first;
    return [
      first[0].toUpperCase() + first.substring(1),
      ...words.skip(1),
    ].join(' ');
  }

  /// The catalogue's catch-all, which carries no meaning without the custom
  /// remark beside it. Named here because the display has to know not to show
  /// "Other" on its own — that tells the applicant nothing at all.
  static const String otherCode = 'other';

  bool get isOther => code == otherCode;

  @override
  bool operator ==(Object other) =>
      other is DocumentReviewReason && other.code == code;

  @override
  int get hashCode => code.hashCode;
}
