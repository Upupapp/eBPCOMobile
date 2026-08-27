// GENERATED FROM THE ADMIN PORTAL — DO NOT HAND-EDIT THE STRINGS.
//
// Source: Upupapp/eBPCO-Web @ e3cd7c3, EBPCO WEB ADMIN/E-BPCO-Software-main,
// src/app/core/domain/. Extracted 27 August 2026.
//
// These are the admin's vocabularies, byte for byte, including the EN DASH in
// "Building Permit – New Construction" — which is U+2013, not a hyphen, and is
// the kind of thing hand-copying gets wrong once and then nobody can find.
//
// Only vocabularies mobile did not already have are declared here. Where an
// equivalent enum already exists (the application lifecycle, evaluation stage
// and result, payment method, release method and status), it is asserted
// against the admin in test/contract/admin_vocabulary_test.dart rather than
// duplicated — a second enum beside the first is the failure this file exists
// to prevent, not one to commit while preventing it.

/// Thrown when a value arrives that the admin's vocabulary does not contain.
///
/// Rejecting rather than defaulting is deliberate, and mirrors the admin's own
/// `isValidPermitType`. A silent fallback turns a contract break into a wrong
/// screen, which is harder to find than a crash.
class UnknownWireValue implements Exception {
  final String vocabulary;
  final String value;

  const UnknownWireValue(this.vocabulary, this.value);

  @override
  String toString() =>
      'UnknownWireValue: "$value" is not a $vocabulary the admin defines';
}

/// Every permit type the Castilla admin recognises, in its own order.
///
/// Named `CanonicalPermitType` rather than `PermitType` on purpose:
/// `mechanical_permit_model.dart` already declares a local
/// `enum PermitType { mechanical }`, and two same-named enums meaning
/// different things is the exact shape that has already caused a near-miss
/// in this codebase.
enum CanonicalPermitType {
  buildingPermitNewConstruction,
  buildingPermitRenovationAlteration,
  buildingPermitAdditionExtension,
  demolitionPermit,
  zoningLocationalClearance,
  architecturalPermit,
  civilStructuralPermit,
  electricalPermit,
  mechanicalPermit,
  sanitaryPermit,
  plumbingPermit,
  electronicsPermit,
  interiorDesignPermit,
  fencingPermit,
  signPermit,
  excavationPermit,
  fsecForBuildingPermitBfp,
  certificateOfOccupancy,
  fsicForOccupancyPermitBfp,
}

extension CanonicalPermitTypeWire on CanonicalPermitType {
  /// The exact string the admin uses on the wire.
  String get wire => switch (this) {
    CanonicalPermitType.buildingPermitNewConstruction =>
      'Building Permit – New Construction',
    CanonicalPermitType.buildingPermitRenovationAlteration =>
      'Building Permit – Renovation / Alteration',
    CanonicalPermitType.buildingPermitAdditionExtension =>
      'Building Permit – Addition / Extension',
    CanonicalPermitType.demolitionPermit => 'Demolition Permit',
    CanonicalPermitType.zoningLocationalClearance =>
      'Zoning / Locational Clearance',
    CanonicalPermitType.architecturalPermit => 'Architectural Permit',
    CanonicalPermitType.civilStructuralPermit => 'Civil / Structural Permit',
    CanonicalPermitType.electricalPermit => 'Electrical Permit',
    CanonicalPermitType.mechanicalPermit => 'Mechanical Permit',
    CanonicalPermitType.sanitaryPermit => 'Sanitary Permit',
    CanonicalPermitType.plumbingPermit => 'Plumbing Permit',
    CanonicalPermitType.electronicsPermit => 'Electronics Permit',
    CanonicalPermitType.interiorDesignPermit => 'Interior Design Permit',
    CanonicalPermitType.fencingPermit => 'Fencing Permit',
    CanonicalPermitType.signPermit => 'Sign Permit',
    CanonicalPermitType.excavationPermit => 'Excavation Permit',
    CanonicalPermitType.fsecForBuildingPermitBfp =>
      'FSEC for Building Permit (BFP)',
    CanonicalPermitType.certificateOfOccupancy => 'Certificate of Occupancy',
    CanonicalPermitType.fsicForOccupancyPermitBfp =>
      'FSIC for Occupancy Permit (BFP)',
  };
}

/// Parses [wire], or throws [UnknownWireValue].
CanonicalPermitType canonicalPermitTypeFromWire(String wire) => switch (wire) {
  'Building Permit – New Construction' =>
    CanonicalPermitType.buildingPermitNewConstruction,
  'Building Permit – Renovation / Alteration' =>
    CanonicalPermitType.buildingPermitRenovationAlteration,
  'Building Permit – Addition / Extension' =>
    CanonicalPermitType.buildingPermitAdditionExtension,
  'Demolition Permit' => CanonicalPermitType.demolitionPermit,
  'Zoning / Locational Clearance' =>
    CanonicalPermitType.zoningLocationalClearance,
  'Architectural Permit' => CanonicalPermitType.architecturalPermit,
  'Civil / Structural Permit' => CanonicalPermitType.civilStructuralPermit,
  'Electrical Permit' => CanonicalPermitType.electricalPermit,
  'Mechanical Permit' => CanonicalPermitType.mechanicalPermit,
  'Sanitary Permit' => CanonicalPermitType.sanitaryPermit,
  'Plumbing Permit' => CanonicalPermitType.plumbingPermit,
  'Electronics Permit' => CanonicalPermitType.electronicsPermit,
  'Interior Design Permit' => CanonicalPermitType.interiorDesignPermit,
  'Fencing Permit' => CanonicalPermitType.fencingPermit,
  'Sign Permit' => CanonicalPermitType.signPermit,
  'Excavation Permit' => CanonicalPermitType.excavationPermit,
  'FSEC for Building Permit (BFP)' =>
    CanonicalPermitType.fsecForBuildingPermitBfp,
  'Certificate of Occupancy' => CanonicalPermitType.certificateOfOccupancy,
  'FSIC for Occupancy Permit (BFP)' =>
    CanonicalPermitType.fsicForOccupancyPermitBfp,
  _ => throw UnknownWireValue('CanonicalPermitType', wire),
};

/// How far a single submitted document has got through review.
///
/// The admin requires remarks whenever a document lands on `rejected` or
/// `revisionRequired`. Mobile's own `DocumentModel` carries no status at
/// all yet — see TAB 02.
enum DocumentStatus {
  missing,
  uploaded,
  submitted,
  underReview,
  accepted,
  rejected,
  revisionRequired,
  expired,
}

extension DocumentStatusWire on DocumentStatus {
  /// The exact string the admin uses on the wire.
  String get wire => switch (this) {
    DocumentStatus.missing => 'Missing',
    DocumentStatus.uploaded => 'Uploaded',
    DocumentStatus.submitted => 'Submitted',
    DocumentStatus.underReview => 'Under Review',
    DocumentStatus.accepted => 'Accepted',
    DocumentStatus.rejected => 'Rejected',
    DocumentStatus.revisionRequired => 'Revision Required',
    DocumentStatus.expired => 'Expired',
  };
}

/// Parses [wire], or throws [UnknownWireValue].
DocumentStatus documentStatusFromWire(String wire) => switch (wire) {
  'Missing' => DocumentStatus.missing,
  'Uploaded' => DocumentStatus.uploaded,
  'Submitted' => DocumentStatus.submitted,
  'Under Review' => DocumentStatus.underReview,
  'Accepted' => DocumentStatus.accepted,
  'Rejected' => DocumentStatus.rejected,
  'Revision Required' => DocumentStatus.revisionRequired,
  'Expired' => DocumentStatus.expired,
  _ => throw UnknownWireValue('DocumentStatus', wire),
};

/// The state of one version of an assessment.
///
/// `superseded` matters to an applicant: a reassessment after a revision
/// replaces the assessment rather than editing it, and the old one stays.
enum AssessmentStatus {
  draft,
  forApproval,
  issued,
  partiallyPaid,
  paid,
  overdue,
  superseded,
  voided,
}

extension AssessmentStatusWire on AssessmentStatus {
  /// The exact string the admin uses on the wire.
  String get wire => switch (this) {
    AssessmentStatus.draft => 'Draft',
    AssessmentStatus.forApproval => 'For Approval',
    AssessmentStatus.issued => 'Issued',
    AssessmentStatus.partiallyPaid => 'Partially Paid',
    AssessmentStatus.paid => 'Paid',
    AssessmentStatus.overdue => 'Overdue',
    AssessmentStatus.superseded => 'Superseded',
    AssessmentStatus.voided => 'Voided',
  };
}

/// Parses [wire], or throws [UnknownWireValue].
AssessmentStatus assessmentStatusFromWire(String wire) => switch (wire) {
  'Draft' => AssessmentStatus.draft,
  'For Approval' => AssessmentStatus.forApproval,
  'Issued' => AssessmentStatus.issued,
  'Partially Paid' => AssessmentStatus.partiallyPaid,
  'Paid' => AssessmentStatus.paid,
  'Overdue' => AssessmentStatus.overdue,
  'Superseded' => AssessmentStatus.superseded,
  'Voided' => AssessmentStatus.voided,
  _ => throw UnknownWireValue('AssessmentStatus', wire),
};

/// The state of a single payment the applicant made.
///
/// Distinct from the assessment's own status: an assessment can be
/// partially paid while one transaction against it was rejected.
enum PaymentTransactionStatus {
  pendingVerification,
  verified,
  rejected,
  voided,
}

extension PaymentTransactionStatusWire on PaymentTransactionStatus {
  /// The exact string the admin uses on the wire.
  String get wire => switch (this) {
    PaymentTransactionStatus.pendingVerification => 'Pending Verification',
    PaymentTransactionStatus.verified => 'Verified',
    PaymentTransactionStatus.rejected => 'Rejected',
    PaymentTransactionStatus.voided => 'Voided',
  };
}

/// Parses [wire], or throws [UnknownWireValue].
PaymentTransactionStatus paymentTransactionStatusFromWire(String wire) =>
    switch (wire) {
      'Pending Verification' => PaymentTransactionStatus.pendingVerification,
      'Verified' => PaymentTransactionStatus.verified,
      'Rejected' => PaymentTransactionStatus.rejected,
      'Voided' => PaymentTransactionStatus.voided,
      _ => throw UnknownWireValue('PaymentTransactionStatus', wire),
    };

/// Who collects a fee.
///
/// FSEC and FSIC fees go to the Bureau of Fire Protection, not the LGU —
/// a different office and a different counter.
enum CollectingAgency { oboLgu, bfp }

extension CollectingAgencyWire on CollectingAgency {
  /// The exact string the admin uses on the wire.
  String get wire => switch (this) {
    CollectingAgency.oboLgu => 'OBO/LGU',
    CollectingAgency.bfp => 'BFP',
  };
}

/// Parses [wire], or throws [UnknownWireValue].
CollectingAgency collectingAgencyFromWire(String wire) => switch (wire) {
  'OBO/LGU' => CollectingAgency.oboLgu,
  'BFP' => CollectingAgency.bfp,
  _ => throw UnknownWireValue('CollectingAgency', wire),
};

/// A correction applied to a recorded payment.
enum PaymentAdjustmentType { voidAdjustment, reversal, refund, correction }

extension PaymentAdjustmentTypeWire on PaymentAdjustmentType {
  /// The exact string the admin uses on the wire.
  String get wire => switch (this) {
    PaymentAdjustmentType.voidAdjustment => 'Void',
    PaymentAdjustmentType.reversal => 'Reversal',
    PaymentAdjustmentType.refund => 'Refund',
    PaymentAdjustmentType.correction => 'Correction',
  };
}

/// Parses [wire], or throws [UnknownWireValue].
PaymentAdjustmentType paymentAdjustmentTypeFromWire(String wire) =>
    switch (wire) {
      'Void' => PaymentAdjustmentType.voidAdjustment,
      'Reversal' => PaymentAdjustmentType.reversal,
      'Refund' => PaymentAdjustmentType.refund,
      'Correction' => PaymentAdjustmentType.correction,
      _ => throw UnknownWireValue('PaymentAdjustmentType', wire),
    };

/// Whether a contact channel has been verified.
///
/// `verificationFailed` is deliberately distinct from `unverified`: one
/// means nobody tried, the other means it was tried and did not work.
enum ContactVerificationStatus {
  unverified,
  pendingVerification,
  verified,
  verificationFailed,
}

extension ContactVerificationStatusWire on ContactVerificationStatus {
  /// The exact string the admin uses on the wire.
  String get wire => switch (this) {
    ContactVerificationStatus.unverified => 'Unverified',
    ContactVerificationStatus.pendingVerification => 'Pending Verification',
    ContactVerificationStatus.verified => 'Verified',
    ContactVerificationStatus.verificationFailed => 'Verification Failed',
  };
}

/// Parses [wire], or throws [UnknownWireValue].
ContactVerificationStatus contactVerificationStatusFromWire(String wire) =>
    switch (wire) {
      'Unverified' => ContactVerificationStatus.unverified,
      'Pending Verification' => ContactVerificationStatus.pendingVerification,
      'Verified' => ContactVerificationStatus.verified,
      'Verification Failed' => ContactVerificationStatus.verificationFailed,
      _ => throw UnknownWireValue('ContactVerificationStatus', wire),
    };

/// How a contact channel was verified.
enum ContactVerificationMethod {
  emailVerificationLink,
  mobileOtp,
  manualAdministratorConfirmation,
  verifiedDocumentMatching,
}

extension ContactVerificationMethodWire on ContactVerificationMethod {
  /// The exact string the admin uses on the wire.
  String get wire => switch (this) {
    ContactVerificationMethod.emailVerificationLink =>
      'Email Verification Link',
    ContactVerificationMethod.mobileOtp => 'Mobile OTP',
    ContactVerificationMethod.manualAdministratorConfirmation =>
      'Manual Administrator Confirmation',
    ContactVerificationMethod.verifiedDocumentMatching =>
      'Verified-Document Matching',
  };
}

/// Parses [wire], or throws [UnknownWireValue].
ContactVerificationMethod contactVerificationMethodFromWire(String wire) =>
    switch (wire) {
      'Email Verification Link' =>
        ContactVerificationMethod.emailVerificationLink,
      'Mobile OTP' => ContactVerificationMethod.mobileOtp,
      'Manual Administrator Confirmation' =>
        ContactVerificationMethod.manualAdministratorConfirmation,
      'Verified-Document Matching' =>
        ContactVerificationMethod.verifiedDocumentMatching,
      _ => throw UnknownWireValue('ContactVerificationMethod', wire),
    };
