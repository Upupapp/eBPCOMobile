import '../models/fsic_permit_model.dart';
import 'draft_snapshot.dart';

/// FSIC for Occupancy Permit (BFP) — FsicPermitDraft, persisted.
///
/// One of the seventeen wizards converted in M-48 part 2, after the mechanism
/// was proven on the Building Permit and Fencing. Every field the draft
/// declares is captured and read back except the 10 attachment slots,
/// which are dropped and named back to the applicant, and whatever
/// `test/architecture/draft_snapshot_completeness_test.dart` exempts with a
/// reason. That gate fails the day this file falls behind the model.
///
/// Written mechanically from the model's own field declarations and then
/// reviewed, which is why it reads uniformly. The alternative — trusting a
/// generator without a gate — is how 28 fields become 28 chances to
/// drop one silently.
class FsicPermitDraftCodec extends DraftCodec<FsicPermitDraft> {
  const FsicPermitDraftCodec();

  @override
  String get permitKey => 'fsic-clearance';

  @override
  String get permitLabel => 'FSIC for Occupancy Permit (BFP)';

  @override
  void capture(FsicPermitDraft draft, SnapshotWriter out) {
    out.scalar('applicant.firstName', draft.applicant.firstName);
    out.scalar('applicant.middleName', draft.applicant.middleName);
    out.scalar('applicant.lastName', draft.applicant.lastName);
    out.scalar('applicant.enterpriseName', draft.applicant.enterpriseName);
    out.scalar('applicant.contactNumber', draft.applicant.contactNumber);
    out.scalar('applicant.emailAddress', draft.applicant.emailAddress);
    out.scalar('applicant.address', draft.applicant.address);
    out.scalar('project.projectName', draft.project.projectName);
    out.scalar('project.projectAddress', draft.project.projectAddress);
    out.scalar('project.occupancyType', draft.project.occupancyType);
    out.scalar('project.totalFloorArea', draft.project.totalFloorArea);
    out.scalar('project.numberOfStoreys', draft.project.numberOfStoreys);
    out.scalar(
      'project.relatedBuildingPermitNumber',
      draft.project.relatedBuildingPermitNumber,
    );
    out.document(
      'requiredDocuments.landTitleUpload',
      draft.requiredDocuments.landTitleUpload,
      'Land Title',
    );
    out.document(
      'requiredDocuments.barangayClearanceUpload',
      draft.requiredDocuments.barangayClearanceUpload,
      'Barangay Clearance',
    );
    out.document(
      'requiredDocuments.locationalClearanceUpload',
      draft.requiredDocuments.locationalClearanceUpload,
      'Locational Clearance',
    );
    out.document(
      'requiredDocuments.validGovernmentIdUpload',
      draft.requiredDocuments.validGovernmentIdUpload,
      'Valid Government ID',
    );
    out.document(
      'requiredDocuments.oboEndorsementUpload',
      draft.requiredDocuments.oboEndorsementUpload,
      'OBO Endorsement',
    );
    out.document(
      'requiredDocuments.completionCertificateUpload',
      draft.requiredDocuments.completionCertificateUpload,
      'Completion Certificate',
    );
    out.document(
      'requiredDocuments.assessmentCopyUpload',
      draft.requiredDocuments.assessmentCopyUpload,
      'Assessment Copy',
    );
    out.document(
      'requiredDocuments.ownerWrittenConsentUpload',
      draft.requiredDocuments.ownerWrittenConsentUpload,
      'Owner Written Consent',
    );
    out.document(
      'requiredDocuments.asBuiltPlanUpload',
      draft.requiredDocuments.asBuiltPlanUpload,
      'As-built plan',
    );
    out.document(
      'requiredDocuments.commissioningReportUpload',
      draft.requiredDocuments.commissioningReportUpload,
      'Commissioning Report',
    );
    out.scalar(
      'certification.submittedByName',
      draft.certification.submittedByName,
    );
    out.scalar(
      'certification.certifiesTrueAndCorrect',
      draft.certification.certifiesTrueAndCorrect,
    );
    out.scalar(
      'certification.acceptsFireSafetyInspection',
      draft.certification.acceptsFireSafetyInspection,
    );
    out.enumValue('status', draft.status);
    out.date('lastSavedAt', draft.lastSavedAt);
  }

  @override
  void restore(FsicPermitDraft draft, SnapshotReader input) {
    draft.applicant.firstName = input.string('applicant.firstName');
    draft.applicant.middleName = input.string('applicant.middleName');
    draft.applicant.lastName = input.string('applicant.lastName');
    draft.applicant.enterpriseName = input.string('applicant.enterpriseName');
    draft.applicant.contactNumber = input.string('applicant.contactNumber');
    draft.applicant.emailAddress = input.string('applicant.emailAddress');
    draft.applicant.address = input.string('applicant.address');
    draft.project.projectName = input.string('project.projectName');
    draft.project.projectAddress = input.string('project.projectAddress');
    draft.project.occupancyType = input.string('project.occupancyType');
    draft.project.totalFloorArea = input.string('project.totalFloorArea');
    draft.project.numberOfStoreys = input.string('project.numberOfStoreys');
    draft.project.relatedBuildingPermitNumber = input.string(
      'project.relatedBuildingPermitNumber',
    );
    draft.certification.submittedByName = input.string(
      'certification.submittedByName',
    );
    draft.certification.certifiesTrueAndCorrect = input.boolean(
      'certification.certifiesTrueAndCorrect',
    );
    draft.certification.acceptsFireSafetyInspection = input.boolean(
      'certification.acceptsFireSafetyInspection',
    );
    // Not read back: a restored draft is always a draft. Honouring a
    // stored `submitted` would resurrect a filed application as editable.
    draft.status = FSICPermitDraftStatus.draft;
    draft.lastSavedAt = input.date('lastSavedAt');
  }
}
