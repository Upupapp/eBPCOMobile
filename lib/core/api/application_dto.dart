import '../models/application_detail.dart';
import '../models/application_model.dart';
import '../contract/admin_vocabulary.dart';
import '../models/document_model.dart';
import '../models/document_review_reason.dart';
import '../models/lifecycle_status.dart';
import '../models/order_of_payment.dart';
import '../models/payment_assessment_model.dart';
import '../models/permit_classification.dart';
import 'api_exception.dart';

/// Parses the §7.2 wire contract into domain models.
///
/// The wire uses the web admin's own labels — "Document Verification",
/// "Ready for Release", "Highly Technical" — because both apps describe the
/// same record and inventing a third spelling on the way in would be how they
/// drift apart.
///
/// Unknown enum values throw rather than defaulting. A status the app does not
/// understand, silently rendered as "Submitted", would tell an applicant their
/// permit is progressing when it may have been rejected; a loud failure is far
/// less harmful than a confident wrong answer.
class ApplicationDto {
  const ApplicationDto._();

  static ApplicationModel parse(Map<String, dynamic> json) {
    final id = _string(json, 'id');
    final lifecycle = _lifecycleStatus(_string(json, 'lifecycleStatus'));
    final instructions = _instructions(json['instructions']);

    var openInstructions = 0;
    for (final letter in instructions) {
      openInstructions += letter.openCount;
    }

    return ApplicationModel(
      id: id,
      applicationNumber: _string(json, 'referenceNumber'),
      businessId: _stringOrNull(json, 'businessId') ?? '',
      businessName: _stringOrNull(json, 'businessName') ?? '',
      type: _applicationAction(_stringOrNull(json, 'applicationAction')),
      // Kept in step with the lifecycle rather than read separately, so the
      // two can never disagree on the same record.
      status: lifecycle.applicantStatus,
      lifecycleStatus: lifecycle,
      classification: _classification(_stringOrNull(json, 'classification')),
      permitTypeLabel: _stringOrNull(json, 'permitType'),
      submittedDate: _dateTime(json, 'dateSubmitted'),
      // Trusted from the server when present, since a summary payload may omit
      // the letters themselves; derived otherwise.
      openInstructionCount:
          _intOrNull(json, 'openInstructionCount') ?? openInstructions,
      documents: _documents(json['documents']),
      timeline: _timeline(json['timeline']),
      evaluations: _evaluations(json['evaluations']),
      instructions: instructions,
      inspection: _inspection(json['inspection']),
      permit: _permit(json['permit']),
      release: _release(json['release']),
      payment: _payment(json['payment']),
      permitNumber: json['permit'] is Map
          ? _stringOrNull(
              json['permit'] as Map<String, dynamic>,
              'permitNumber',
            )
          : null,
      issuedDate: json['permit'] is Map
          ? _dateTimeOrNull(
              json['permit'] as Map<String, dynamic>,
              'issuedDate',
            )
          : null,
    );
  }

  static List<ApplicationModel> parseList(List<dynamic> rows) => [
    for (final row in rows)
      if (row is Map<String, dynamic>)
        parse(row)
      else
        throw ApiException(
          ApiFailure.malformed,
          'expected application objects, got ${row.runtimeType}',
        ),
  ];

  // -- enums ---------------------------------------------------------------

  /// Wire labels are the admin's, verbatim from `status.model.ts`.
  static const _lifecycleByLabel = <String, ApplicationLifecycleStatus>{
    'Draft': ApplicationLifecycleStatus.draft,
    'Submitted': ApplicationLifecycleStatus.submitted,
    'Received': ApplicationLifecycleStatus.received,
    'Document Verification': ApplicationLifecycleStatus.documentVerification,
    'Under Evaluation': ApplicationLifecycleStatus.underEvaluation,
    'Revision Required': ApplicationLifecycleStatus.revisionRequired,
    'Assessed': ApplicationLifecycleStatus.assessed,
    'Payment Submitted': ApplicationLifecycleStatus.paymentSubmitted,
    'Payment Under Verification':
        ApplicationLifecycleStatus.paymentUnderVerification,
    'Payment Verified': ApplicationLifecycleStatus.paymentVerified,
    'For Approval': ApplicationLifecycleStatus.forApproval,
    'Approved': ApplicationLifecycleStatus.approved,
    'Permit Generated': ApplicationLifecycleStatus.permitGenerated,
    'Ready for Release': ApplicationLifecycleStatus.readyForRelease,
    'Released': ApplicationLifecycleStatus.released,
    'Completed': ApplicationLifecycleStatus.completed,
    'Rejected': ApplicationLifecycleStatus.rejected,
    'Cancelled': ApplicationLifecycleStatus.cancelled,
    'Expired': ApplicationLifecycleStatus.expired,
  };

  static ApplicationLifecycleStatus _lifecycleStatus(String raw) {
    final value = _lifecycleByLabel[raw];
    if (value == null) {
      throw ApiException(
        ApiFailure.malformed,
        'unknown lifecycleStatus "$raw" — the app and the admin have drifted',
      );
    }
    return value;
  }

  static PermitClassification? _classification(String? raw) {
    if (raw == null) return null;
    switch (raw) {
      case 'Simple':
        return PermitClassification.simple;
      case 'Complex':
        return PermitClassification.complex;
      case 'Highly Technical':
        return PermitClassification.highlyTechnical;
    }
    throw ApiException(ApiFailure.malformed, 'unknown classification "$raw"');
  }

  static ApplicationType _applicationAction(String? raw) {
    switch (raw) {
      case null:
      case 'New':
        return ApplicationType.newPermit;
      case 'Renewal':
        return ApplicationType.renewal;
      case 'Amendment':
        return ApplicationType.amendment;
    }
    throw ApiException(
      ApiFailure.malformed,
      'unknown applicationAction "$raw"',
    );
  }

  static EvaluationStage _stage(String raw) {
    switch (raw) {
      case 'Initial':
        return EvaluationStage.initial;
      case 'Zoning':
        return EvaluationStage.zoning;
      case 'Fire Safety':
        return EvaluationStage.fireSafety;
      case 'OBO':
        return EvaluationStage.obo;
      case 'Final Approval':
        return EvaluationStage.finalApproval;
    }
    throw ApiException(ApiFailure.malformed, 'unknown evaluation stage "$raw"');
  }

  static EvaluationResult _result(String raw) {
    switch (raw) {
      case 'Pending':
        return EvaluationResult.pending;
      case 'Passed':
        return EvaluationResult.passed;
      case 'Revision Required':
        return EvaluationResult.revisionRequired;
      case 'Rejected':
        return EvaluationResult.rejected;
    }
    throw ApiException(
      ApiFailure.malformed,
      'unknown evaluation result "$raw"',
    );
  }

  static PaymentAssessmentStatus _paymentStatus(String raw) {
    switch (raw) {
      case 'Not Yet Available':
        return PaymentAssessmentStatus.notYetAvailable;
      case 'Pending Verification':
        return PaymentAssessmentStatus.pending;
      case 'Paid':
        return PaymentAssessmentStatus.paid;
      case 'Overdue':
        return PaymentAssessmentStatus.overdue;
    }
    throw ApiException(ApiFailure.malformed, 'unknown payment status "$raw"');
  }

  static PaymentMethod? _paymentMethod(String? raw) {
    switch (raw) {
      case null:
        return null;
      case 'Bank Transfer':
        return PaymentMethod.bankTransfer;
      case 'Onsite':
        return PaymentMethod.onsite;
    }
    throw ApiException(ApiFailure.malformed, 'unknown payment method "$raw"');
  }

  static PermitReleaseStatus _releaseStatus(String raw) {
    switch (raw) {
      case 'Not Ready':
        return PermitReleaseStatus.notReady;
      case 'Ready for Release':
        return PermitReleaseStatus.readyForRelease;
      case 'Released':
        return PermitReleaseStatus.released;
    }
    throw ApiException(ApiFailure.malformed, 'unknown release status "$raw"');
  }

  static ReleaseMethod? _releaseMethod(String? raw) {
    switch (raw) {
      case null:
        return null;
      case 'Physical Claim':
        return ReleaseMethod.physicalClaim;
      case 'Authorized Representative':
        return ReleaseMethod.authorizedRepresentative;
    }
    throw ApiException(ApiFailure.malformed, 'unknown release method "$raw"');
  }

  // -- nested records ------------------------------------------------------

  /// One attached document, INCLUDING what the office decided about it.
  ///
  /// Until now this read four fields — id, label, fileName, uploadedAt — and
  /// dropped the rest on the floor. The whole per-document review layer built
  /// in TAB 02 (status, the evaluator's remarks, the issuing office, the
  /// document's own expiry, the submission history) was therefore reachable
  /// from the mock repository and from nowhere else: the models held it, three
  /// screens rendered it, and a live server could not have filled any of it.
  static List<DocumentModel> _documents(dynamic raw) {
    if (raw is! List) return const [];
    return [
      for (final row in raw.whereType<Map<String, dynamic>>())
        DocumentModel(
          id: _string(row, 'id'),
          label: _string(row, 'label'),
          fileName: _stringOrNull(row, 'fileName') ?? '',
          uploadedAt: _dateTime(row, 'uploadedAt'),
          status: _documentStatus(_stringOrNull(row, 'status')),
          remarks: _stringOrNull(row, 'remarks'),
          reviewReason: _reviewReason(row['reviewReason']),
          issuingOffice: _stringOrNull(row, 'issuingOffice'),
          issueDate: _dateTimeOrNull(row, 'issueDate'),
          expiryDate: _dateTimeOrNull(row, 'expiryDate'),
          history: _submissions(row['history']),
        ),
    ];
  }

  /// Absent means nobody has reviewed it, which is a real state and not a
  /// failure. Present but unrecognised is a failure: this vocabulary is the
  /// admin's closed set, and guessing at a status is how an applicant gets
  /// told their document was accepted.
  static DocumentStatus? _documentStatus(String? raw) {
    if (raw == null) return null;
    try {
      return documentStatusFromWire(raw);
    } on UnknownWireValue {
      throw ApiException(
        ApiFailure.malformed,
        'unknown document status "$raw"',
      );
    }
  }

  /// The office's standard reason, from a catalogue the LGU edits.
  ///
  /// **Deliberately never throws**, unlike every other vocabulary parsed in
  /// this file. An office adding a reason is an ordinary administrative act,
  /// and a client that crashes on one it has not seen would turn that act into
  /// an outage on the applicant's phone. An unknown code renders; a missing
  /// label is humanised from the code.
  static DocumentReviewReason? _reviewReason(dynamic raw) {
    if (raw is! Map<String, dynamic>) return null;
    final code = _stringOrNull(raw, 'code');
    if (code == null || code.trim().isEmpty) return null;
    return DocumentReviewReason.fromWire(
      code: code,
      label: _stringOrNull(raw, 'label'),
      description: _stringOrNull(raw, 'description'),
    );
  }

  /// Earlier submissions of the same requirement, oldest first.
  ///
  /// The office keeps every one, and so must this: an applicant who resubmits
  /// a rejected title should not lose the record of what was rejected, or why.
  static List<DocumentSubmission> _submissions(dynamic raw) {
    if (raw is! List) return const [];
    final entries = [
      for (final row in raw.whereType<Map<String, dynamic>>())
        DocumentSubmission(
          fileName: _stringOrNull(row, 'fileName') ?? '',
          submittedAt: _dateTime(row, 'submittedAt'),
          status:
              _documentStatus(_stringOrNull(row, 'status')) ??
              DocumentStatus.submitted,
          remarks: _stringOrNull(row, 'remarks'),
        ),
    ];
    entries.sort((a, b) => a.submittedAt.compareTo(b.submittedAt));
    return entries;
  }

  static List<TimelineEntry> _timeline(dynamic raw) {
    if (raw is! List) return const [];
    final entries = [
      for (final row in raw.whereType<Map<String, dynamic>>())
        TimelineEntry(
          status: _lifecycleStatus(_string(row, 'status')),
          occurredAt: _dateTime(row, 'occurredAt'),
          office: _stringOrNull(row, 'office'),
          actor: _stringOrNull(row, 'actor'),
          remarks: _stringOrNull(row, 'remarks'),
        ),
    ];
    // Oldest first, whatever order the server sent, because the timeline
    // renders a sequence and a revision loop depends on chronology.
    entries.sort((a, b) => a.occurredAt.compareTo(b.occurredAt));
    return entries;
  }

  static List<EvaluationRecord> _evaluations(dynamic raw) {
    if (raw is! List) return const [];
    final records = [
      for (final row in raw.whereType<Map<String, dynamic>>())
        EvaluationRecord(
          stage: _stage(_string(row, 'stage')),
          result: _result(_string(row, 'result')),
          evaluator: _stringOrNull(row, 'evaluator'),
          evaluatedAt: _dateTimeOrNull(row, 'evaluatedAt'),
          remarks: _stringOrNull(row, 'remarks'),
        ),
    ];
    records.sort((a, b) => a.stage.index.compareTo(b.stage.index));
    return records;
  }

  static List<LetterOfInstruction> _instructions(dynamic raw) {
    if (raw is! List) return const [];
    final letters = [
      for (final row in raw.whereType<Map<String, dynamic>>())
        LetterOfInstruction(
          id: _string(row, 'id'),
          issuedAt: _dateTime(row, 'issuedAt'),
          issuedBy: _stringOrNull(row, 'issuedBy'),
          items: [
            for (final item
                in (row['items'] as List? ?? const [])
                    .whereType<Map<String, dynamic>>())
              InstructionItem(
                id: _string(item, 'id'),
                subject: _string(item, 'subject'),
                remark: _stringOrNull(item, 'remark') ?? '',
                resolvedAt: _dateTimeOrNull(item, 'resolvedAt'),
              ),
          ],
        ),
    ];
    letters.sort((a, b) => b.issuedAt.compareTo(a.issuedAt));
    return letters;
  }

  static InspectionRecord? _inspection(dynamic raw) {
    if (raw is! Map<String, dynamic>) return null;
    return InspectionRecord(
      scheduledAt: _dateTime(raw, 'scheduledAt'),
      offices: [
        for (final office in (raw['offices'] as List? ?? const []))
          office.toString(),
      ],
      preparationChecklist: [
        for (final item in (raw['checklist'] as List? ?? const []))
          item.toString(),
      ],
      outcome: _stringOrNull(raw, 'outcome'),
      remarks: _stringOrNull(raw, 'remarks'),
    );
  }

  static GeneratedPermit? _permit(dynamic raw) {
    if (raw is! Map<String, dynamic>) return null;
    return GeneratedPermit(
      permitNumber: _string(raw, 'permitNumber'),
      issuedDate: _dateTime(raw, 'issuedDate'),
      scope: _stringOrNull(raw, 'scope'),
      conditions: [
        for (final condition in (raw['conditions'] as List? ?? const []))
          condition.toString(),
      ],
      // Never from the wire: it is a path on this device, set when the
      // applicant downloads.
    );
  }

  static ReleaseRecord? _release(dynamic raw) {
    if (raw is! Map<String, dynamic>) return null;
    return ReleaseRecord(
      status: _releaseStatus(_string(raw, 'status')),
      method: _releaseMethod(_stringOrNull(raw, 'method')),
      claimant: _stringOrNull(raw, 'claimant'),
      releasedAt: _dateTimeOrNull(raw, 'releasedAt'),
      claimLocation: _stringOrNull(raw, 'claimLocation'),
      officeHours: _stringOrNull(raw, 'officeHours'),
      bringWithYou: [
        for (final item in (raw['bringWithYou'] as List? ?? const []))
          item.toString(),
      ],
    );
  }

  static PaymentAssessmentModel? _payment(dynamic raw) {
    if (raw is! Map<String, dynamic>) return null;
    return PaymentAssessmentModel(
      status: _paymentStatus(_string(raw, 'status')),
      orderOfPayment: _orderOfPayment(raw['orderOfPayment']),
      referenceNumber: _stringOrNull(raw, 'referenceNumber'),
      method: _paymentMethod(_stringOrNull(raw, 'method')),
      submittedAt: _dateTimeOrNull(raw, 'submittedAt'),
      officialReceiptNumber: _stringOrNull(raw, 'officialReceiptNumber'),
      verifiedAt: _dateTimeOrNull(raw, 'verifiedAt'),
    );
  }

  static OrderOfPayment? _orderOfPayment(dynamic raw) {
    if (raw is! Map<String, dynamic>) return null;
    final fees = raw['fees'];
    if (fees is! Map<String, dynamic>) {
      throw ApiException(
        ApiFailure.malformed,
        'an Order of Payment arrived without its fee breakdown',
      );
    }
    return OrderOfPayment(
      number: _string(raw, 'number'),
      assessedAt: _dateTime(raw, 'assessedAt'),
      assessedBy: _stringOrNull(raw, 'assessedBy'),
      dueDate: _dateTimeOrNull(raw, 'dueDate'),
      fees: AssessmentFees(
        // Centavos on the wire as well as in the app — the admin stores them
        // as integers, and converting through a float anywhere in the chain
        // is how a total ends up a centavo out at the cashier.
        filing: _centavos(fees, 'filing'),
        processing: _centavos(fees, 'processing'),
        architectural: _centavos(fees, 'architectural'),
        structural: _centavos(fees, 'structural'),
        electrical: _centavos(fees, 'electrical'),
        others: _centavos(fees, 'others'),
      ),
    );
  }

  // -- primitives ----------------------------------------------------------

  static String _string(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is String && value.isNotEmpty) return value;
    throw ApiException(ApiFailure.malformed, 'missing required string "$key"');
  }

  static String? _stringOrNull(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value == null) return null;
    final text = value.toString();
    return text.isEmpty ? null : text;
  }

  static int? _intOrNull(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value == null) return null;
    if (value is int) return value;
    throw ApiException(ApiFailure.malformed, '"$key" is not an integer');
  }

  static int _centavos(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value == null) return 0;
    if (value is int) return value;
    throw ApiException(
      ApiFailure.malformed,
      'fee "$key" must be whole centavos as an integer, got '
      '${value.runtimeType}',
    );
  }

  static DateTime _dateTime(Map<String, dynamic> json, String key) {
    final parsed = _dateTimeOrNull(json, key);
    if (parsed == null) {
      throw ApiException(
        ApiFailure.malformed,
        'missing or unparseable date "$key"',
      );
    }
    return parsed;
  }

  static DateTime? _dateTimeOrNull(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value == null) return null;
    final parsed = DateTime.tryParse(value.toString());
    // Local time throughout: every date the applicant sees is a Philippine
    // office date, and rendering a UTC instant would shift an evening
    // submission onto the previous day.
    return parsed?.toLocal();
  }
}
