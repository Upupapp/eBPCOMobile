import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import 'lifecycle_status.dart';

// ---------------------------------------------------------------------------
// Evaluation
// ---------------------------------------------------------------------------

/// The OBO's review stages, in the order they are worked.
///
/// Mirrors `EvaluationStage` and `EVALUATION_STAGE_ORDER` in the web admin's
/// `core/domain/status.model.ts`.
enum EvaluationStage { initial, zoning, fireSafety, obo, finalApproval }

extension EvaluationStageX on EvaluationStage {
  String get label {
    switch (this) {
      case EvaluationStage.initial:
        return 'Initial';
      case EvaluationStage.zoning:
        return 'Zoning';
      case EvaluationStage.fireSafety:
        return 'Fire Safety';
      case EvaluationStage.obo:
        return 'OBO';
      case EvaluationStage.finalApproval:
        return 'Final Approval';
    }
  }

  /// Which office performs this stage. Applicants consistently want to know
  /// who is actually holding their application, and the LGU Citizen's Charter
  /// format names the office for every step.
  String get office {
    switch (this) {
      case EvaluationStage.initial:
        return 'Office of the Building Official';
      case EvaluationStage.zoning:
        return 'City / Municipal Planning and Development Office';
      case EvaluationStage.fireSafety:
        return 'Bureau of Fire Protection';
      case EvaluationStage.obo:
        return 'Office of the Building Official';
      case EvaluationStage.finalApproval:
        return 'Building Official';
    }
  }

  /// Plain-language note on what the stage is for, shown on first encounter.
  String get plainDescription {
    switch (this) {
      case EvaluationStage.initial:
        return 'Your submitted documents are checked for completeness.';
      case EvaluationStage.zoning:
        return 'Confirms your project is allowed at this location under the '
            'LGU’s land-use rules.';
      case EvaluationStage.fireSafety:
        return 'The BFP reviews your plans and issues the Fire Safety '
            'Evaluation Clearance (FSEC), which the building permit requires.';
      case EvaluationStage.obo:
        return 'Technical review of your plans against the National Building '
            'Code.';
      case EvaluationStage.finalApproval:
        return 'The Building Official signs off on your permit.';
    }
  }
}

/// Outcome of one evaluation stage. Mirrors `EvaluationResult` in the admin.
enum EvaluationResult { pending, passed, revisionRequired, rejected }

extension EvaluationResultX on EvaluationResult {
  String get label {
    switch (this) {
      case EvaluationResult.pending:
        return 'Pending';
      case EvaluationResult.passed:
        return 'Passed';
      case EvaluationResult.revisionRequired:
        return 'Revision Required';
      case EvaluationResult.rejected:
        return 'Rejected';
    }
  }

  Color get color {
    switch (this) {
      case EvaluationResult.pending:
        return AppColors.textMuted;
      case EvaluationResult.passed:
        return AppColors.statusApproved;
      case EvaluationResult.revisionRequired:
        return AppColors.statusPending;
      case EvaluationResult.rejected:
        return AppColors.statusRejected;
    }
  }

  Color get backgroundColor {
    switch (this) {
      case EvaluationResult.pending:
        return AppColors.surfaceMuted;
      case EvaluationResult.passed:
        return AppColors.statusApprovedBg;
      case EvaluationResult.revisionRequired:
        return AppColors.statusPendingBg;
      case EvaluationResult.rejected:
        return AppColors.statusRejectedBg;
    }
  }

  /// The admin enforces remarks on these two results, so the app can rely on
  /// remarks being present and must render them as the applicant's
  /// instructions rather than as an optional footnote.
  bool get carriesMandatoryRemarks =>
      this == EvaluationResult.revisionRequired ||
      this == EvaluationResult.rejected;
}

/// One evaluator's decision on one stage.
class EvaluationRecord {
  final EvaluationStage stage;
  final EvaluationResult result;
  final String? evaluator;
  final DateTime? evaluatedAt;

  /// Verbatim evaluator remarks. Never summarised, truncated behind a "more"
  /// link, or paraphrased in the UI — for a returned application this text is
  /// the complete set of instructions the applicant has to work from.
  final String? remarks;

  const EvaluationRecord({
    required this.stage,
    required this.result,
    this.evaluator,
    this.evaluatedAt,
    this.remarks,
  });
}

// ---------------------------------------------------------------------------
// Letter of Instruction
// ---------------------------------------------------------------------------

/// One deficiency the applicant has to clear.
class InstructionItem {
  final String id;

  /// The document or field concerned.
  final String subject;

  /// The evaluator's verbatim instruction.
  final String remark;

  final DateTime? resolvedAt;

  const InstructionItem({
    required this.id,
    required this.subject,
    required this.remark,
    this.resolvedAt,
  });

  bool get isResolved => resolvedAt != null;

  InstructionItem copyWith({DateTime? resolvedAt}) => InstructionItem(
    id: id,
    subject: subject,
    remark: remark,
    resolvedAt: resolvedAt ?? this.resolvedAt,
  );
}

/// A Letter of Instruction — the LGU's itemised list of what is wrong with a
/// submission.
///
/// Modelled as a first-class object rather than a status flag because it is
/// the deficiency loop that blocks everything downstream, and because
/// Philippine LGU practice (QC e-Services among others) issues it as a
/// discrete document to both the applicant and their design professional.
class LetterOfInstruction {
  final String id;
  final DateTime issuedAt;
  final String? issuedBy;
  final List<InstructionItem> items;

  const LetterOfInstruction({
    required this.id,
    required this.issuedAt,
    required this.items,
    this.issuedBy,
  });

  int get resolvedCount => items.where((i) => i.isResolved).length;
  int get openCount => items.length - resolvedCount;
  bool get isFullyResolved => items.isNotEmpty && openCount == 0;

  double get progress => items.isEmpty ? 0 : resolvedCount / items.length;

  LetterOfInstruction copyWith({List<InstructionItem>? items}) =>
      LetterOfInstruction(
        id: id,
        issuedAt: issuedAt,
        issuedBy: issuedBy,
        items: items ?? this.items,
      );
}

// ---------------------------------------------------------------------------
// Inspection
// ---------------------------------------------------------------------------

/// A scheduled inspection.
///
/// Deliberately singular with a list of attending offices rather than a queue
/// of one-per-office inspections: Amended JMC 2021-01 requires LGUs to
/// organise joint inspection teams precisely so applicants stop accommodating
/// separate visits.
class InspectionRecord {
  final DateTime scheduledAt;

  /// Every office attending the joint inspection.
  final List<String> offices;

  /// What the applicant must have ready on site.
  final List<String> preparationChecklist;

  final String? outcome;
  final String? remarks;

  const InspectionRecord({
    required this.scheduledAt,
    required this.offices,
    this.preparationChecklist = const [],
    this.outcome,
    this.remarks,
  });

  bool get isCompleted => outcome != null;
}

// ---------------------------------------------------------------------------
// Permit and release
// ---------------------------------------------------------------------------

/// Mirrors `PermitReleaseStatus` in the admin.
enum PermitReleaseStatus { notReady, readyForRelease, released }

extension PermitReleaseStatusX on PermitReleaseStatus {
  String get label {
    switch (this) {
      case PermitReleaseStatus.notReady:
        return 'Not Ready';
      case PermitReleaseStatus.readyForRelease:
        return 'Ready for Release';
      case PermitReleaseStatus.released:
        return 'Released';
    }
  }
}

/// Mirrors `ReleaseMethod` in the admin.
enum ReleaseMethod { physicalClaim, authorizedRepresentative }

extension ReleaseMethodX on ReleaseMethod {
  String get label => this == ReleaseMethod.physicalClaim
      ? 'Physical Claim'
      : 'Authorized Representative';
}

/// The issued permit.
class GeneratedPermit {
  final String permitNumber;
  final DateTime issuedDate;
  final String? scope;
  final List<String> conditions;

  /// Locally cached copy, so the permit is readable with no connection. Null
  /// until the applicant downloads it.
  final String? localFilePath;

  const GeneratedPermit({
    required this.permitNumber,
    required this.issuedDate,
    this.scope,
    this.conditions = const [],
    this.localFilePath,
  });

  /// PD 1096 voids a permit where the authorised work is not commenced within
  /// one year of issue.
  DateTime get commenceByDate =>
      DateTime(issuedDate.year + 1, issuedDate.month, issuedDate.day);

  bool get isAvailableOffline => localFilePath != null;

  GeneratedPermit copyWith({String? localFilePath}) => GeneratedPermit(
    permitNumber: permitNumber,
    issuedDate: issuedDate,
    scope: scope,
    conditions: conditions,
    localFilePath: localFilePath ?? this.localFilePath,
  );
}

/// How and where the permit is claimed.
class ReleaseRecord {
  final PermitReleaseStatus status;
  final ReleaseMethod? method;
  final String? claimant;
  final DateTime? releasedAt;

  /// Where to claim, office hours, and what to bring.
  final String? claimLocation;
  final String? officeHours;
  final List<String> bringWithYou;

  const ReleaseRecord({
    required this.status,
    this.method,
    this.claimant,
    this.releasedAt,
    this.claimLocation,
    this.officeHours,
    this.bringWithYou = const [],
  });
}

// ---------------------------------------------------------------------------
// Timeline
// ---------------------------------------------------------------------------

/// One transition in an application's life, as recorded by the admin's audit
/// trail.
class TimelineEntry {
  final ApplicationLifecycleStatus status;
  final DateTime occurredAt;

  /// The office responsible, so the applicant can tell who has their file.
  final String? office;
  final String? actor;
  final String? remarks;

  const TimelineEntry({
    required this.status,
    required this.occurredAt,
    this.office,
    this.actor,
    this.remarks,
  });
}
