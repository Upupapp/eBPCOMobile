import '../contract/admin_vocabulary.dart';

/// One earlier submission of the same requirement, kept when a document is
/// replaced.
///
/// The office keeps this history and never clears it on resubmission, so an
/// applicant can see what they sent before and when — which matters when the
/// question is whether the right version was ever received.
class DocumentSubmission {
  final String fileName;
  final DateTime submittedAt;
  final DocumentStatus status;

  /// The evaluator's words, when this submission was turned back.
  final String? remarks;

  const DocumentSubmission({
    required this.fileName,
    required this.submittedAt,
    required this.status,
    this.remarks,
  });
}

/// Represents one attached file — used both for permit requirement
/// uploads and proof-of-payment uploads. Most call sites still fabricate
/// a mock filename when the user taps upload (no real file picking), but
/// [filePath] is optionally set when a real file was picked (camera,
/// gallery, device files, or an existing "My Documents" item), so a
/// preview action can open the real file when one exists.
///
/// Once an application is filed, the office reviews each document and records
/// what it decided. Those fields are all nullable and all null on a draft
/// attachment, which is honest: a file the applicant has picked but not sent
/// has no review status, and showing one would be a claim about a decision
/// nobody has made.
class DocumentModel {
  final String id;
  final String label;
  final String fileName;
  final DateTime uploadedAt;
  final int? fileSizeBytes;

  /// Absolute path to the real file backing this attachment, if any. Null
  /// for the mock/fabricated documents used everywhere else in the app.
  final String? filePath;

  // ── What the office decided ─────────────────────────────────────────────
  //
  // Mirrors the admin portal's ApplicationDocument. Before these existed the
  // app could show an applicant that a document had been *sent* and nothing
  // more — so a document turned back for revision, with the evaluator's reason
  // recorded against it in the portal, reached the applicant only if somebody
  // also raised a Letter of Instruction about it.

  /// Null until the office has looked at it.
  final DocumentStatus? status;

  /// Required by the office whenever [status] is rejected or revisionRequired,
  /// and the whole point of surfacing status at all: "Rejected" without a
  /// reason tells the applicant to guess.
  final String? remarks;

  /// The office or agency that issued the document itself — a barangay, the
  /// BFP, the DPWH. Distinct from whoever reviews it.
  final String? issuingOffice;

  final DateTime? issueDate;

  /// When the document itself stops being valid — a clearance has a life of
  /// its own, independent of the application it was submitted to.
  final DateTime? expiryDate;

  /// Earlier submissions of this same requirement, oldest first.
  final List<DocumentSubmission> history;

  const DocumentModel({
    required this.id,
    required this.label,
    required this.fileName,
    required this.uploadedAt,
    this.fileSizeBytes,
    this.filePath,
    this.status,
    this.remarks,
    this.issuingOffice,
    this.issueDate,
    this.expiryDate,
    this.history = const [],
  });

  /// Whether the applicant has something to do about this document.
  ///
  /// Deliberately excludes `missing` and `uploaded`: those describe where the
  /// document is, not a decision the office has taken and handed back.
  bool get needsApplicantAction =>
      status == DocumentStatus.rejected ||
      status == DocumentStatus.revisionRequired ||
      isExpired;

  /// Past its own expiry, whatever the office has got round to recording.
  ///
  /// The applicant can act on this before the desk does, and should: a
  /// clearance that lapsed last week will be turned back whether or not
  /// anyone has marked it yet.
  bool get isExpired {
    if (status == DocumentStatus.expired) return true;
    final expiry = expiryDate;
    if (expiry == null) return false;
    return expiry.isBefore(DateTime.now());
  }

  DocumentModel copyWith({
    String? fileName,
    DateTime? uploadedAt,
    DocumentStatus? status,
    String? remarks,
    List<DocumentSubmission>? history,
  }) => DocumentModel(
    id: id,
    label: label,
    fileName: fileName ?? this.fileName,
    uploadedAt: uploadedAt ?? this.uploadedAt,
    fileSizeBytes: fileSizeBytes,
    filePath: filePath,
    status: status ?? this.status,
    remarks: remarks,
    issuingOffice: issuingOffice,
    issueDate: issueDate,
    expiryDate: expiryDate,
    history: history ?? this.history,
  );

  /// Replaces this document with a newly supplied file, keeping what was sent
  /// before.
  ///
  /// The prior submission is appended rather than overwritten — the office
  /// does the same, and an applicant who resubmits should not lose the record
  /// of what was already rejected.
  DocumentModel resubmittedWith({
    required String fileName,
    required DateTime submittedAt,
  }) => copyWith(
    fileName: fileName,
    uploadedAt: submittedAt,
    status: DocumentStatus.submitted,
    history: [
      ...history,
      DocumentSubmission(
        fileName: this.fileName,
        submittedAt: uploadedAt,
        status: status ?? DocumentStatus.submitted,
        remarks: remarks,
      ),
    ],
  );
}
