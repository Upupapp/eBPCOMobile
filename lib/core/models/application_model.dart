import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import 'application_detail.dart';
import 'document_model.dart';
import 'lifecycle_status.dart';
import 'payment_assessment_model.dart';
import 'permit_classification.dart';

/// The kind of permit action an application represents.
enum ApplicationType { newPermit, renewal, amendment }

extension ApplicationTypeX on ApplicationType {
  String get label {
    switch (this) {
      case ApplicationType.newPermit:
        return 'New Business Permit';
      case ApplicationType.renewal:
        return 'Permit Renewal';
      case ApplicationType.amendment:
        return 'Permit Amendment';
    }
  }
}

/// Represents the status of a permit application in the mock dataset.
/// The happy-path demo sequence is: submitted -> underReview ->
/// paymentVerification -> approved -> released. `draft` precedes
/// submission; `rejected` is a terminal branch outside the guided
/// "Simulate Next Update" sequence.
enum ApplicationStatus {
  draft,
  submitted,
  underReview,
  paymentVerification,
  approved,
  released,
  rejected,
}

/// The order status advances through when the user or the "Simulate Next
/// Update" action moves an application forward.
const applicationStatusSequence = [
  ApplicationStatus.submitted,
  ApplicationStatus.underReview,
  ApplicationStatus.paymentVerification,
  ApplicationStatus.approved,
  ApplicationStatus.released,
];

/// The fixed checklist of requirement labels shown in the New Application
/// wizard's document-upload step.
const requiredDocumentLabels = [
  'Valid Government ID',
  'Barangay Clearance',
  'Proof of Business Address',
];

/// Mock assessment fee per application type, shared by the repository
/// (which stamps it onto the payment record) and the payment screen (which
/// needs to display it before the assessment record exists).
const applicationTypeAssessmentAmounts = {
  ApplicationType.newPermit: 5250.0,
  ApplicationType.renewal: 3200.0,
  ApplicationType.amendment: 1500.0,
};

extension ApplicationStatusX on ApplicationStatus {
  String get label {
    switch (this) {
      case ApplicationStatus.draft:
        return 'Draft';
      case ApplicationStatus.submitted:
        return 'Submitted';
      case ApplicationStatus.underReview:
        return 'Under Review';
      case ApplicationStatus.paymentVerification:
        return 'Payment Verification';
      case ApplicationStatus.approved:
        return 'Approved';
      case ApplicationStatus.released:
        return 'Ready for Release';
      case ApplicationStatus.rejected:
        return 'Rejected';
    }
  }

  Color get color {
    switch (this) {
      case ApplicationStatus.draft:
        return AppColors.textMuted;
      case ApplicationStatus.submitted:
        return AppColors.statusInfo;
      case ApplicationStatus.underReview:
      case ApplicationStatus.paymentVerification:
        return AppColors.statusPending;
      case ApplicationStatus.approved:
      case ApplicationStatus.released:
        return AppColors.statusApproved;
      case ApplicationStatus.rejected:
        return AppColors.statusRejected;
    }
  }

  Color get backgroundColor {
    switch (this) {
      case ApplicationStatus.draft:
        return AppColors.surfaceMuted;
      case ApplicationStatus.submitted:
        return AppColors.statusInfoBg;
      case ApplicationStatus.underReview:
      case ApplicationStatus.paymentVerification:
        return AppColors.statusPendingBg;
      case ApplicationStatus.approved:
      case ApplicationStatus.released:
        return AppColors.statusApprovedBg;
      case ApplicationStatus.rejected:
        return AppColors.statusRejectedBg;
    }
  }
}

/// One entry in an application's status timeline.
class StatusHistoryEntry {
  final ApplicationStatus status;
  final DateTime timestamp;

  const StatusHistoryEntry({required this.status, required this.timestamp});
}

/// Mock model describing a permit application.
class ApplicationModel {
  final String id;
  final String applicationNumber;
  final String businessId;
  final String businessName;
  final ApplicationType type;
  final ApplicationStatus status;
  final DateTime submittedDate;
  final List<DocumentModel> documents;
  final PaymentAssessmentModel? payment;
  final String? permitNumber;
  final DateTime? issuedDate;
  final List<StatusHistoryEntry> statusHistory;

  /// The admin's 19-value processing state. Server-authoritative and the more
  /// truthful of the two status fields — [status] is its coarse projection,
  /// kept because older screens bind to it directly.
  final ApplicationLifecycleStatus? lifecycleStatus;

  /// RA 11032 service classification, assigned by the LGU.
  ///
  /// Null means the LGU has not classified the application yet. The app must
  /// then show "Awaiting classification" rather than inventing a countdown:
  /// guessing low would have the app accuse the LGU of breaching a pledge it
  /// never made.
  final PermitClassification? classification;

  /// Specific permit applied for — "New Construction", "Electrical", and so
  /// on. Distinct from [type], which is the action (new/renewal/amendment).
  final String? permitTypeLabel;

  /// Unresolved items on an outstanding Letter of Instruction.
  ///
  /// Kept as a denormalised counter so list rows and the Home action stack do
  /// not have to load full detail. Always set from [instructions] by whatever
  /// builds the record, so the two can never disagree.
  final int openInstructionCount;

  /// Every lifecycle transition, richest form. [statusHistory] is the older,
  /// coarser projection of the same events; screens prefer this when present
  /// and fall back to that when it is empty.
  final List<TimelineEntry> timeline;

  /// Per-stage evaluation results, in stage order.
  final List<EvaluationRecord> evaluations;

  /// Letters of Instruction, newest first.
  final List<LetterOfInstruction> instructions;

  final InspectionRecord? inspection;
  final GeneratedPermit? permit;
  final ReleaseRecord? release;

  const ApplicationModel({
    required this.id,
    required this.applicationNumber,
    required this.businessId,
    required this.businessName,
    required this.type,
    required this.status,
    required this.submittedDate,
    this.documents = const [],
    this.payment,
    this.permitNumber,
    this.issuedDate,
    this.statusHistory = const [],
    this.lifecycleStatus,
    this.classification,
    this.permitTypeLabel,
    this.openInstructionCount = 0,
    this.timeline = const [],
    this.evaluations = const [],
    this.instructions = const [],
    this.inspection,
    this.permit,
    this.release,
  });

  /// The applicant-visible status. Derived from [lifecycleStatus] when the
  /// server has supplied one, so the projection lives in exactly one place.
  ApplicationStatus get applicantStatus =>
      lifecycleStatus?.applicantStatus ?? status;

  /// Plain-language explanation of the current state, or null when the record
  /// predates lifecycle tracking.
  String? get statusSubLine => lifecycleStatus?.applicantSubLine;

  /// True when the application is waiting on the applicant, not the LGU.
  bool get requiresApplicantAction =>
      (lifecycleStatus?.requiresApplicantAction ?? false) ||
      openInstructionCount > 0;

  /// Whether a service-pledge countdown is meaningful for this record.
  bool get isInFlight => lifecycleStatus?.isInFlight ?? false;

  /// The Letter of Instruction the applicant still has to clear, if any.
  LetterOfInstruction? get openInstruction {
    for (final letter in instructions) {
      if (!letter.isFullyResolved) return letter;
    }
    return null;
  }

  /// The evaluation that returned this application, if one did. Its remarks
  /// are the applicant's instructions.
  EvaluationRecord? get returningEvaluation {
    for (final evaluation in evaluations) {
      if (evaluation.result == EvaluationResult.revisionRequired ||
          evaluation.result == EvaluationResult.rejected) {
        return evaluation;
      }
    }
    return null;
  }

  /// Date by which work must commence or the building permit lapses.
  ///
  /// PD 1096 voids a permit where the authorised work is not commenced within
  /// one year of issue, so a released permit always carries this deadline.
  DateTime? get commenceByDate {
    final generated = permit;
    if (generated != null) return generated.commenceByDate;
    final issued = issuedDate;
    if (issued == null || permitNumber == null) return null;
    return DateTime(issued.year + 1, issued.month, issued.day);
  }

  /// Fraction of the happy-path sequence completed, for progress bars.
  double get progress {
    final index = applicationStatusSequence.indexOf(status);
    if (index == -1) return 0;
    return (index + 1) / applicationStatusSequence.length;
  }

  String get nextStep {
    switch (status) {
      case ApplicationStatus.draft:
        return 'Complete and submit your application.';
      case ApplicationStatus.submitted:
        return 'Wait for the initial document evaluation.';
      case ApplicationStatus.underReview:
        return 'An evaluator is reviewing your submitted requirements.';
      case ApplicationStatus.paymentVerification:
        return payment == null
            ? 'Proceed to payment to continue processing.'
            : 'Your payment is being verified by the office.';
      case ApplicationStatus.approved:
        return 'Your permit is being prepared for release.';
      case ApplicationStatus.released:
        return 'Your permit is ready for release.';
      case ApplicationStatus.rejected:
        return 'Review the rejection details before resubmitting.';
    }
  }

  ApplicationModel copyWith({
    ApplicationStatus? status,
    List<DocumentModel>? documents,
    PaymentAssessmentModel? payment,
    String? permitNumber,
    DateTime? issuedDate,
    List<StatusHistoryEntry>? statusHistory,
    ApplicationLifecycleStatus? lifecycleStatus,
    PermitClassification? classification,
    String? permitTypeLabel,
    int? openInstructionCount,
    List<TimelineEntry>? timeline,
    List<EvaluationRecord>? evaluations,
    List<LetterOfInstruction>? instructions,
    InspectionRecord? inspection,
    GeneratedPermit? permit,
    ReleaseRecord? release,
  }) {
    return ApplicationModel(
      id: id,
      applicationNumber: applicationNumber,
      businessId: businessId,
      businessName: businessName,
      type: type,
      status: status ?? this.status,
      submittedDate: submittedDate,
      documents: documents ?? this.documents,
      payment: payment ?? this.payment,
      permitNumber: permitNumber ?? this.permitNumber,
      issuedDate: issuedDate ?? this.issuedDate,
      statusHistory: statusHistory ?? this.statusHistory,
      lifecycleStatus: lifecycleStatus ?? this.lifecycleStatus,
      classification: classification ?? this.classification,
      permitTypeLabel: permitTypeLabel ?? this.permitTypeLabel,
      openInstructionCount: openInstructionCount ?? this.openInstructionCount,
      timeline: timeline ?? this.timeline,
      evaluations: evaluations ?? this.evaluations,
      instructions: instructions ?? this.instructions,
      inspection: inspection ?? this.inspection,
      permit: permit ?? this.permit,
      release: release ?? this.release,
    );
  }
}
