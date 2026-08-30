import '../models/zoning_permit_model.dart';
import 'draft_snapshot.dart';

/// Zoning / Locational Clearance — ZoningPermitDraft, persisted.
///
/// One of the seventeen wizards converted in M-48 part 2, after the mechanism
/// was proven on the Building Permit and Fencing. Every field the draft
/// declares is captured and read back except the 16 attachment slots,
/// which are dropped and named back to the applicant, and whatever
/// `test/architecture/draft_snapshot_completeness_test.dart` exempts with a
/// reason. That gate fails the day this file falls behind the model.
///
/// Written mechanically from the model's own field declarations and then
/// reviewed, which is why it reads uniformly. The alternative — trusting a
/// generator without a gate — is how 41 fields become 41 chances to
/// drop one silently.
class ZoningPermitDraftCodec extends DraftCodec<ZoningPermitDraft> {
  const ZoningPermitDraftCodec();

  @override
  String get permitKey => 'zoning-clearance';

  @override
  String get permitLabel => 'Zoning / Locational Clearance';

  @override
  void capture(ZoningPermitDraft draft, SnapshotWriter out) {
    out.scalar('applicant.firstName', draft.applicant.firstName);
    out.scalar('applicant.middleName', draft.applicant.middleName);
    out.scalar('applicant.lastName', draft.applicant.lastName);
    out.scalar('applicant.enterpriseName', draft.applicant.enterpriseName);
    out.scalar('applicant.contactNumber', draft.applicant.contactNumber);
    out.scalar('applicant.emailAddress', draft.applicant.emailAddress);
    out.scalar('applicant.address', draft.applicant.address);
    out.scalar('siteLocation.lotNumber', draft.siteLocation.lotNumber);
    out.scalar('siteLocation.blockNumber', draft.siteLocation.blockNumber);
    out.scalar('siteLocation.tctNumber', draft.siteLocation.tctNumber);
    out.scalar(
      'siteLocation.taxDeclarationNumber',
      draft.siteLocation.taxDeclarationNumber,
    );
    out.scalar('siteLocation.street', draft.siteLocation.street);
    out.scalar('siteLocation.barangay', draft.siteLocation.barangay);
    out.scalar('siteLocation.city', draft.siteLocation.city);
    out.scalar('siteLocation.lotArea', draft.siteLocation.lotArea);
    out.scalar('proposedUse.proposedUse', draft.proposedUse.proposedUse);
    out.scalar(
      'proposedUse.projectDescription',
      draft.proposedUse.projectDescription,
    );
    out.scalar('proposedUse.floorArea', draft.proposedUse.floorArea);
    out.scalar(
      'proposedUse.estimatedProjectCost',
      draft.proposedUse.estimatedProjectCost,
    );
    out.scalar('proposedUse.existingUse', draft.proposedUse.existingUse);
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
      'requiredDocuments.validGovernmentIdUpload',
      draft.requiredDocuments.validGovernmentIdUpload,
      'Valid Government ID',
    );
    out.document(
      'requiredDocuments.letterRequestUpload',
      draft.requiredDocuments.letterRequestUpload,
      'Letter Request',
    );
    out.document(
      'requiredDocuments.siteDevelopmentPlanUpload',
      draft.requiredDocuments.siteDevelopmentPlanUpload,
      'Site Development Plan',
    );
    out.document(
      'requiredDocuments.vicinityMapUpload',
      draft.requiredDocuments.vicinityMapUpload,
      'Vicinity Map',
    );
    out.document(
      'requiredDocuments.sketchPlanUpload',
      draft.requiredDocuments.sketchPlanUpload,
      'Sketch Plan',
    );
    out.document(
      'requiredDocuments.billOfMaterialsUpload',
      draft.requiredDocuments.billOfMaterialsUpload,
      'Bill of Materials',
    );
    out.document(
      'requiredDocuments.proofOfOwnershipUpload',
      draft.requiredDocuments.proofOfOwnershipUpload,
      'Proof of Ownership',
    );
    out.document(
      'requiredDocuments.taxDeclarationUpload',
      draft.requiredDocuments.taxDeclarationUpload,
      'Tax Declaration',
    );
    out.document(
      'requiredDocuments.landTaxReceiptUpload',
      draft.requiredDocuments.landTaxReceiptUpload,
      'Land Tax Receipt',
    );
    out.document(
      'requiredDocuments.barangayBuildingClearanceUpload',
      draft.requiredDocuments.barangayBuildingClearanceUpload,
      'Barangay Building Clearance',
    );
    out.document(
      'requiredDocuments.cedulaUpload',
      draft.requiredDocuments.cedulaUpload,
      'Cedula',
    );
    out.document(
      'requiredDocuments.ownerWrittenConsentUpload',
      draft.requiredDocuments.ownerWrittenConsentUpload,
      'Owner Written Consent',
    );
    out.document(
      'requiredDocuments.dpwhClearanceUpload',
      draft.requiredDocuments.dpwhClearanceUpload,
      'DPWH Clearance',
    );
    out.document(
      'requiredDocuments.environmentalComplianceCertificateUpload',
      draft.requiredDocuments.environmentalComplianceCertificateUpload,
      'Environmental Compliance Certificate',
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
      'certification.acceptsOcularInspection',
      draft.certification.acceptsOcularInspection,
    );
    out.enumValue('status', draft.status);
    out.date('lastSavedAt', draft.lastSavedAt);
  }

  @override
  void restore(ZoningPermitDraft draft, SnapshotReader input) {
    draft.applicant.firstName = input.string('applicant.firstName');
    draft.applicant.middleName = input.string('applicant.middleName');
    draft.applicant.lastName = input.string('applicant.lastName');
    draft.applicant.enterpriseName = input.string('applicant.enterpriseName');
    draft.applicant.contactNumber = input.string('applicant.contactNumber');
    draft.applicant.emailAddress = input.string('applicant.emailAddress');
    draft.applicant.address = input.string('applicant.address');
    draft.siteLocation.lotNumber = input.string('siteLocation.lotNumber');
    draft.siteLocation.blockNumber = input.string('siteLocation.blockNumber');
    draft.siteLocation.tctNumber = input.string('siteLocation.tctNumber');
    draft.siteLocation.taxDeclarationNumber = input.string(
      'siteLocation.taxDeclarationNumber',
    );
    draft.siteLocation.street = input.string('siteLocation.street');
    draft.siteLocation.barangay = input.string('siteLocation.barangay');
    draft.siteLocation.city = input.string('siteLocation.city');
    draft.siteLocation.lotArea = input.string('siteLocation.lotArea');
    draft.proposedUse.proposedUse = input.string('proposedUse.proposedUse');
    draft.proposedUse.projectDescription = input.string(
      'proposedUse.projectDescription',
    );
    draft.proposedUse.floorArea = input.string('proposedUse.floorArea');
    draft.proposedUse.estimatedProjectCost = input.string(
      'proposedUse.estimatedProjectCost',
    );
    draft.proposedUse.existingUse = input.string('proposedUse.existingUse');
    draft.certification.submittedByName = input.string(
      'certification.submittedByName',
    );
    draft.certification.certifiesTrueAndCorrect = input.boolean(
      'certification.certifiesTrueAndCorrect',
    );
    draft.certification.acceptsOcularInspection = input.boolean(
      'certification.acceptsOcularInspection',
    );
    // Not read back: a restored draft is always a draft. Honouring a
    // stored `submitted` would resurrect a filed application as editable.
    draft.status = ZoningPermitDraftStatus.draft;
    draft.lastSavedAt = input.date('lastSavedAt');
  }
}
