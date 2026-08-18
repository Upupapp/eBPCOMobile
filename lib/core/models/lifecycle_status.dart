import 'application_model.dart';

/// The application's position in the eBPCO Web Admin's processing pipeline.
///
/// These 19 values, their spelling, and their order mirror
/// `ApplicationLifecycleStatus` in the web admin's
/// `core/domain/status.model.ts`. Mobile does not define its own processing
/// vocabulary — it reads the admin's and projects it, so the two apps can
/// never describe the same record in two incompatible ways.
enum ApplicationLifecycleStatus {
  draft,
  submitted,
  received,
  documentVerification,
  underEvaluation,
  revisionRequired,
  assessed,
  paymentSubmitted,
  paymentUnderVerification,
  paymentVerified,
  forApproval,
  approved,
  permitGenerated,
  readyForRelease,
  released,
  completed,
  rejected,
  cancelled,
  expired,
}

/// The ordered happy path, for rendering a timeline. `Revision Required` is
/// omitted deliberately: it is a loop back into evaluation rather than a fixed
/// position, and `Rejected`/`Cancelled`/`Expired` are terminal exits reachable
/// from most non-terminal states.
const lifecycleSequence = <ApplicationLifecycleStatus>[
  ApplicationLifecycleStatus.draft,
  ApplicationLifecycleStatus.submitted,
  ApplicationLifecycleStatus.received,
  ApplicationLifecycleStatus.documentVerification,
  ApplicationLifecycleStatus.underEvaluation,
  ApplicationLifecycleStatus.assessed,
  ApplicationLifecycleStatus.paymentSubmitted,
  ApplicationLifecycleStatus.paymentUnderVerification,
  ApplicationLifecycleStatus.paymentVerified,
  ApplicationLifecycleStatus.forApproval,
  ApplicationLifecycleStatus.approved,
  ApplicationLifecycleStatus.permitGenerated,
  ApplicationLifecycleStatus.readyForRelease,
  ApplicationLifecycleStatus.released,
  ApplicationLifecycleStatus.completed,
];

extension ApplicationLifecycleStatusX on ApplicationLifecycleStatus {
  /// The admin's own label, verbatim. Shown as the sub-line so the applicant
  /// keeps the detail the coarser applicant status throws away.
  String get adminLabel {
    switch (this) {
      case ApplicationLifecycleStatus.draft:
        return 'Draft';
      case ApplicationLifecycleStatus.submitted:
        return 'Submitted';
      case ApplicationLifecycleStatus.received:
        return 'Received';
      case ApplicationLifecycleStatus.documentVerification:
        return 'Document Verification';
      case ApplicationLifecycleStatus.underEvaluation:
        return 'Under Evaluation';
      case ApplicationLifecycleStatus.revisionRequired:
        return 'Revision Required';
      case ApplicationLifecycleStatus.assessed:
        return 'Assessed';
      case ApplicationLifecycleStatus.paymentSubmitted:
        return 'Payment Submitted';
      case ApplicationLifecycleStatus.paymentUnderVerification:
        return 'Payment Under Verification';
      case ApplicationLifecycleStatus.paymentVerified:
        return 'Payment Verified';
      case ApplicationLifecycleStatus.forApproval:
        return 'For Approval';
      case ApplicationLifecycleStatus.approved:
        return 'Approved';
      case ApplicationLifecycleStatus.permitGenerated:
        return 'Permit Generated';
      case ApplicationLifecycleStatus.readyForRelease:
        return 'Ready for Release';
      case ApplicationLifecycleStatus.released:
        return 'Released';
      case ApplicationLifecycleStatus.completed:
        return 'Completed';
      case ApplicationLifecycleStatus.rejected:
        return 'Rejected';
      case ApplicationLifecycleStatus.cancelled:
        return 'Cancelled';
      case ApplicationLifecycleStatus.expired:
        return 'Expired';
    }
  }

  /// Projection onto the 7 applicant-visible statuses. Mirrors the admin's
  /// `LIFECYCLE_TO_MOBILE_LABEL` exactly.
  ApplicationStatus get applicantStatus {
    switch (this) {
      case ApplicationLifecycleStatus.draft:
        return ApplicationStatus.draft;
      case ApplicationLifecycleStatus.submitted:
      case ApplicationLifecycleStatus.received:
        return ApplicationStatus.submitted;
      case ApplicationLifecycleStatus.documentVerification:
      case ApplicationLifecycleStatus.underEvaluation:
      case ApplicationLifecycleStatus.revisionRequired:
        return ApplicationStatus.underReview;
      case ApplicationLifecycleStatus.assessed:
      case ApplicationLifecycleStatus.paymentSubmitted:
      case ApplicationLifecycleStatus.paymentUnderVerification:
      case ApplicationLifecycleStatus.paymentVerified:
      case ApplicationLifecycleStatus.forApproval:
        return ApplicationStatus.paymentVerification;
      case ApplicationLifecycleStatus.approved:
      case ApplicationLifecycleStatus.permitGenerated:
        return ApplicationStatus.approved;
      case ApplicationLifecycleStatus.readyForRelease:
      case ApplicationLifecycleStatus.released:
      case ApplicationLifecycleStatus.completed:
        return ApplicationStatus.released;
      case ApplicationLifecycleStatus.rejected:
      case ApplicationLifecycleStatus.cancelled:
      case ApplicationLifecycleStatus.expired:
        return ApplicationStatus.rejected;
    }
  }

  /// Plain-language explanation shown beneath the applicant status.
  String get applicantSubLine {
    switch (this) {
      case ApplicationLifecycleStatus.draft:
        return 'Not yet filed. Continue where you left off.';
      case ApplicationLifecycleStatus.submitted:
        return 'Filed and awaiting receipt by the Office of the Building Official.';
      case ApplicationLifecycleStatus.received:
        return 'Received by the OBO. Processing has started.';
      case ApplicationLifecycleStatus.documentVerification:
        return 'Your documents are being checked for completeness.';
      case ApplicationLifecycleStatus.underEvaluation:
        return 'Technical evaluation in progress.';
      case ApplicationLifecycleStatus.revisionRequired:
        return 'Action needed from you. See the evaluator’s instructions.';
      case ApplicationLifecycleStatus.assessed:
        return 'Your Order of Payment is ready. Fees are now due.';
      case ApplicationLifecycleStatus.paymentSubmitted:
        return 'We have your payment details and are checking them.';
      case ApplicationLifecycleStatus.paymentUnderVerification:
        return 'The Treasurer’s Office is verifying your payment.';
      case ApplicationLifecycleStatus.paymentVerified:
        return 'Payment confirmed. Awaiting final approval.';
      case ApplicationLifecycleStatus.forApproval:
        return 'With the Building Official for signature.';
      case ApplicationLifecycleStatus.approved:
        return 'Approved. Your permit is being generated.';
      case ApplicationLifecycleStatus.permitGenerated:
        return 'Permit generated. Preparing for release.';
      case ApplicationLifecycleStatus.readyForRelease:
        return 'Ready to claim. See claim instructions.';
      case ApplicationLifecycleStatus.released:
        return 'Released. Download your copy.';
      case ApplicationLifecycleStatus.completed:
        return 'Complete.';
      case ApplicationLifecycleStatus.rejected:
        return 'Not approved. Reason and next options below.';
      case ApplicationLifecycleStatus.cancelled:
        return 'Cancelled.';
      case ApplicationLifecycleStatus.expired:
        return 'Lapsed for inaction. You may refile.';
    }
  }

  /// Whether this state is waiting on the applicant rather than on the LGU.
  ///
  /// Deliberately independent of [applicantStatus]: `Revision Required` and
  /// `Assessed` both project onto passive-sounding headlines ("Under Review",
  /// "Payment Verification") that give the applicant no hint they are the one
  /// holding the application up. This flag is what drives the Home action
  /// stack, the tab badge, and push priority.
  bool get requiresApplicantAction {
    switch (this) {
      case ApplicationLifecycleStatus.revisionRequired:
      case ApplicationLifecycleStatus.assessed:
      case ApplicationLifecycleStatus.readyForRelease:
        return true;
      default:
        return false;
    }
  }

  /// True once no further processing will happen on this record.
  bool get isTerminal {
    switch (this) {
      case ApplicationLifecycleStatus.completed:
      case ApplicationLifecycleStatus.rejected:
      case ApplicationLifecycleStatus.cancelled:
      case ApplicationLifecycleStatus.expired:
        return true;
      default:
        return false;
    }
  }

  /// True while the LGU still owes the applicant an act, so a service pledge
  /// countdown is meaningful.
  bool get isInFlight =>
      this != ApplicationLifecycleStatus.draft && !isTerminal;
}
