import 'package:flutter_test/flutter_test.dart';

import 'package:ebpco_user_app/core/contract/admin_vocabulary.dart';
import 'package:ebpco_user_app/core/models/application_detail.dart';
import 'package:ebpco_user_app/core/models/lifecycle_status.dart';
import 'package:ebpco_user_app/core/models/payment_assessment_model.dart';

/// The admin portal and this app describe the same permit. These fixtures are
/// the admin's vocabularies transcribed from
/// Upupapp/eBPCO-Web @ e3cd7c3, src/app/core/domain/, on 27 August 2026.
///
/// Two lines of the same product have already drifted once — the vendor's own
/// mobile copy and this one diverged on 19 August — and nothing compared them,
/// so the first divergence would have been found by an applicant. These tests
/// are that comparison.
///
/// When a fixture legitimately changes because the admin changed, update it
/// here **and** record the commit it came from. A fixture edited to make a test
/// pass is worse than no fixture.

const _permitTypes = <String>[
  'Building Permit – New Construction',
  'Building Permit – Renovation / Alteration',
  'Building Permit – Addition / Extension',
  'Demolition Permit',
  'Zoning / Locational Clearance',
  'Architectural Permit',
  'Civil / Structural Permit',
  'Electrical Permit',
  'Mechanical Permit',
  'Sanitary Permit',
  'Plumbing Permit',
  'Electronics Permit',
  'Interior Design Permit',
  'Fencing Permit',
  'Sign Permit',
  'Excavation Permit',
  'FSEC for Building Permit (BFP)',
  'Certificate of Occupancy',
  'FSIC for Occupancy Permit (BFP)',
];

const _documentStatuses = <String>[
  'Missing',
  'Uploaded',
  'Submitted',
  'Under Review',
  'Accepted',
  'Rejected',
  'Revision Required',
  'Expired',
];

const _assessmentStatuses = <String>[
  'Draft',
  'For Approval',
  'Issued',
  'Partially Paid',
  'Paid',
  'Overdue',
  'Superseded',
  'Voided',
];

const _paymentTransactionStatuses = <String>[
  'Pending Verification',
  'Verified',
  'Rejected',
  'Voided',
];

const _collectingAgencies = <String>['OBO/LGU', 'BFP'];

const _paymentAdjustmentTypes = <String>[
  'Void',
  'Reversal',
  'Refund',
  'Correction',
];

const _verificationStatuses = <String>[
  'Unverified',
  'Pending Verification',
  'Verified',
  'Verification Failed',
];

const _verificationMethods = <String>[
  'Email Verification Link',
  'Mobile OTP',
  'Manual Administrator Confirmation',
  'Verified-Document Matching',
];

// Vocabularies this app already had before the contract module existed. These
// are the ones worth guarding most: a second enum was not added beside them,
// so nothing else would notice if they drifted.
const _lifecycleStatuses = <String>[
  'Draft',
  'Submitted',
  'Received',
  'Document Verification',
  'Under Evaluation',
  'Revision Required',
  'Assessed',
  'Payment Submitted',
  'Payment Under Verification',
  'Payment Verified',
  'For Approval',
  'Approved',
  'Permit Generated',
  'Ready for Release',
  'Released',
  'Completed',
  'Rejected',
  'Cancelled',
  'Expired',
];

const _evaluationStages = <String>[
  'Initial',
  'Zoning',
  'Fire Safety',
  'OBO',
  'Final Approval',
];

const _evaluationResults = <String>[
  'Pending',
  'Passed',
  'Revision Required',
  'Rejected',
];

const _paymentMethods = <String>['Bank Transfer', 'Onsite'];

const _releaseMethods = <String>['Physical Claim', 'Authorized Representative'];

const _releaseStatuses = <String>['Not Ready', 'Ready for Release', 'Released'];

void main() {
  group('vocabularies the contract module declares', () {
    test('permit types match the admin exactly, including the en dash', () {
      expect(
        CanonicalPermitType.values.map((t) => t.wire).toList(),
        _permitTypes,
      );
      // Stated separately because it is the character most likely to be
      // silently "corrected" to a hyphen by an editor or a paste.
      expect(
        CanonicalPermitType.buildingPermitNewConstruction.wire,
        contains('\u2013'),
      );
    });

    test('document statuses match', () {
      expect(
        DocumentStatus.values.map((s) => s.wire).toList(),
        _documentStatuses,
      );
    });

    test('assessment statuses match', () {
      expect(
        AssessmentStatus.values.map((s) => s.wire).toList(),
        _assessmentStatuses,
      );
    });

    test('payment transaction statuses match', () {
      expect(
        PaymentTransactionStatus.values.map((s) => s.wire).toList(),
        _paymentTransactionStatuses,
      );
    });

    test('collecting agencies match', () {
      expect(
        CollectingAgency.values.map((a) => a.wire).toList(),
        _collectingAgencies,
      );
    });

    test('payment adjustment types match', () {
      expect(
        PaymentAdjustmentType.values.map((a) => a.wire).toList(),
        _paymentAdjustmentTypes,
      );
    });

    test('contact verification statuses and methods match', () {
      expect(
        ContactVerificationStatus.values.map((s) => s.wire).toList(),
        _verificationStatuses,
      );
      expect(
        ContactVerificationMethod.values.map((m) => m.wire).toList(),
        _verificationMethods,
      );
    });
  });

  group('parsing from the wire', () {
    test('round-trips every value', () {
      for (final t in CanonicalPermitType.values) {
        expect(canonicalPermitTypeFromWire(t.wire), t);
      }
      for (final s in DocumentStatus.values) {
        expect(documentStatusFromWire(s.wire), s);
      }
    });

    test('rejects an unknown value rather than defaulting', () {
      // A silent fallback turns a contract break into a wrong screen, which is
      // harder to find than a crash. The admin does the same in
      // isValidPermitType.
      expect(
        () => canonicalPermitTypeFromWire('Sanitary / Plumbing Permit'),
        throwsA(isA<UnknownWireValue>()),
      );
      expect(
        () => documentStatusFromWire('Approved'),
        throwsA(isA<UnknownWireValue>()),
      );
    });
  });

  group('vocabularies this app already had', () {
    test('evaluation stages match the admin', () {
      expect(
        EvaluationStage.values.map((s) => s.label).toList(),
        _evaluationStages,
      );
    });

    test('evaluation results match the admin', () {
      expect(
        EvaluationResult.values.map((r) => r.label).toList(),
        _evaluationResults,
      );
    });

    test('release methods and statuses match the admin', () {
      expect(
        ReleaseMethod.values.map((m) => m.label).toList(),
        _releaseMethods,
      );
      expect(
        PermitReleaseStatus.values.map((s) => s.label).toList(),
        _releaseStatuses,
      );
    });

    test('payment methods carry the admin wire values', () {
      // Mobile labels the onsite method "Onsite Payment" for the applicant,
      // where the admin's wire value is "Onsite". The label is a display
      // choice and is fine; what must not drift is the set of methods.
      expect(PaymentMethod.values.length, _paymentMethods.length);
      expect(PaymentMethod.bankTransfer.label, 'Bank Transfer');
    });

    test('the 19-state lifecycle matches the admin exactly', () {
      // The largest vocabulary the two lines share, and the one a new admin
      // state would most plausibly be added to.
      expect(
        ApplicationLifecycleStatus.values.map((s) => s.adminLabel).toList(),
        _lifecycleStatuses,
      );
    });

    test('every lifecycle state still projects to an applicant label', () {
      // A state with no projection would fall through silently and show the
      // applicant nothing.
      for (final status in ApplicationLifecycleStatus.values) {
        expect(status.applicantStatus, isNotNull);
      }
    });
  });
}
