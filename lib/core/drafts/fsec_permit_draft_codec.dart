import '../models/fsec_permit_model.dart';
import 'draft_snapshot.dart';

/// FSEC for Building Permit (BFP) — FsecPermitDraft, persisted.
///
/// One of the seventeen wizards converted in M-48 part 2, after the mechanism
/// was proven on the Building Permit and Fencing. Every field the draft
/// declares is captured and read back except the 9 attachment slots,
/// which are dropped and named back to the applicant, and whatever
/// `test/architecture/draft_snapshot_completeness_test.dart` exempts with a
/// reason. That gate fails the day this file falls behind the model.
///
/// Written mechanically from the model's own field declarations and then
/// reviewed, which is why it reads uniformly. The alternative — trusting a
/// generator without a gate — is how 27 fields become 27 chances to
/// drop one silently.
class FsecPermitDraftCodec extends DraftCodec<FsecPermitDraft> {
  const FsecPermitDraftCodec();

  @override
  String get permitKey => 'fsec-clearance';

  @override
  String get permitLabel => 'FSEC for Building Permit (BFP)';

  @override
  void capture(FsecPermitDraft draft, SnapshotWriter out) {
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
      'requiredDocuments.planSetUpload',
      draft.requiredDocuments.planSetUpload,
      'Plan Set',
    );
    out.document(
      'requiredDocuments.costEstimateUpload',
      draft.requiredDocuments.costEstimateUpload,
      'Cost Estimate',
    );
    out.document(
      'requiredDocuments.ownerWrittenConsentUpload',
      draft.requiredDocuments.ownerWrittenConsentUpload,
      'Owner Written Consent',
    );
    out.document(
      'requiredDocuments.fireSafetyComplianceReportUpload',
      draft.requiredDocuments.fireSafetyComplianceReportUpload,
      'Fire Safety Compliance Report',
    );
    out.document(
      'requiredDocuments.hotWorksClearanceUpload',
      draft.requiredDocuments.hotWorksClearanceUpload,
      'Hot Works Clearance',
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
  void restore(FsecPermitDraft draft, SnapshotReader input) {
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
    draft.requiredDocuments.landTitleUpload = input.document(
      'requiredDocuments.landTitleUpload',
    );
    draft.requiredDocuments.barangayClearanceUpload = input.document(
      'requiredDocuments.barangayClearanceUpload',
    );
    draft.requiredDocuments.locationalClearanceUpload = input.document(
      'requiredDocuments.locationalClearanceUpload',
    );
    draft.requiredDocuments.validGovernmentIdUpload = input.document(
      'requiredDocuments.validGovernmentIdUpload',
    );
    draft.requiredDocuments.planSetUpload = input.document(
      'requiredDocuments.planSetUpload',
    );
    draft.requiredDocuments.costEstimateUpload = input.document(
      'requiredDocuments.costEstimateUpload',
    );
    draft.requiredDocuments.ownerWrittenConsentUpload = input.document(
      'requiredDocuments.ownerWrittenConsentUpload',
    );
    draft.requiredDocuments.fireSafetyComplianceReportUpload = input.document(
      'requiredDocuments.fireSafetyComplianceReportUpload',
    );
    draft.requiredDocuments.hotWorksClearanceUpload = input.document(
      'requiredDocuments.hotWorksClearanceUpload',
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
    draft.status = FSECPermitDraftStatus.draft;
    draft.lastSavedAt = input.date('lastSavedAt');
  }
}
