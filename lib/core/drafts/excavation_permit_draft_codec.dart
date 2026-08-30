import '../models/excavation_permit_model.dart';
import 'draft_snapshot.dart';

/// Excavation — ExcavationPermitDraft, persisted.
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
/// generator without a gate — is how 91 fields become 91 chances to
/// drop one silently.
class ExcavationPermitDraftCodec extends DraftCodec<ExcavationPermitDraft> {
  const ExcavationPermitDraftCodec();

  @override
  String get permitKey => 'excavation-permit';

  @override
  String get permitLabel => 'Excavation';

  @override
  void capture(ExcavationPermitDraft draft, SnapshotWriter out) {
    out.scalar(
      'relatedBuildingPermit.buildingPermitNumber',
      draft.relatedBuildingPermit.buildingPermitNumber,
    );
    out.enumValue(
      'relatedBuildingPermit.status',
      draft.relatedBuildingPermit.status,
    );
    out.scalar('applicant.lastName', draft.applicant.lastName);
    out.scalar('applicant.firstName', draft.applicant.firstName);
    out.scalar('applicant.middleInitial', draft.applicant.middleInitial);
    out.scalar('applicant.tin', draft.applicant.tin);
    out.scalar('applicant.contactNumber', draft.applicant.contactNumber);
    out.scalar(
      'applicant.isOwnedByEnterprise',
      draft.applicant.isOwnedByEnterprise,
    );
    out.scalar('applicant.enterpriseName', draft.applicant.enterpriseName);
    out.scalar('applicant.formOfOwnership', draft.applicant.formOfOwnership);
    out.enumValue('applicant.occupancyGroup', draft.applicant.occupancyGroup);
    out.scalar(
      'applicant.occupancyOtherDescription',
      draft.applicant.occupancyOtherDescription,
    );
    out.scalar('applicant.addressNumber', draft.applicant.addressNumber);
    out.scalar('applicant.street', draft.applicant.street);
    out.scalar('applicant.barangay', draft.applicant.barangay);
    out.scalar('applicant.city', draft.applicant.city);
    out.scalar('applicant.zipCode', draft.applicant.zipCode);
    out.document(
      'constructionLocation.landTitleOrTaxDeclarationUpload',
      draft.constructionLocation.landTitleOrTaxDeclarationUpload,
      'Land Title or Tax Declaration',
    );
    out.document(
      'constructionLocation.barangayClearanceUpload',
      draft.constructionLocation.barangayClearanceUpload,
      'Barangay Clearance',
    );
    out.document(
      'constructionLocation.locationalClearanceUpload',
      draft.constructionLocation.locationalClearanceUpload,
      'Locational Clearance',
    );
    out.document(
      'constructionLocation.validGovernmentIdUpload',
      draft.constructionLocation.validGovernmentIdUpload,
      'Valid Government ID',
    );
    out.scalar(
      'constructionLocation.lotNumber',
      draft.constructionLocation.lotNumber,
    );
    out.scalar(
      'constructionLocation.blockNumber',
      draft.constructionLocation.blockNumber,
    );
    out.scalar(
      'constructionLocation.tctNumber',
      draft.constructionLocation.tctNumber,
    );
    out.scalar(
      'constructionLocation.taxDeclarationNumber',
      draft.constructionLocation.taxDeclarationNumber,
    );
    out.scalar(
      'constructionLocation.street',
      draft.constructionLocation.street,
    );
    out.scalar(
      'constructionLocation.barangay',
      draft.constructionLocation.barangay,
    );
    out.scalar('constructionLocation.city', draft.constructionLocation.city);
    out.enumSet('scopeOfWork.selectedScopes', draft.scopeOfWork.selectedScopes);
    out.scalar(
      'scopeOfWork.otherScopeDescription',
      draft.scopeOfWork.otherScopeDescription,
    );
    out.enumSet(
      'excavationDetails.selectedWorkTypes',
      draft.excavationDetails.selectedWorkTypes,
    );
    out.scalar(
      'excavationDetails.otherWorkTypeDescription',
      draft.excavationDetails.otherWorkTypeDescription,
    );
    out.scalar(
      'excavationDetails.excavationDepthMeters',
      draft.excavationDetails.excavationDepthMeters,
    );
    out.scalar(
      'excavationDetails.excavationVolumeCubicMeters',
      draft.excavationDetails.excavationVolumeCubicMeters,
    );
    out.scalar(
      'professionals.designProfessional.fullName',
      draft.professionals.designProfessional.fullName,
    );
    out.enumValue(
      'professionals.designProfessional.profession',
      draft.professionals.designProfessional.profession,
    );
    out.scalar(
      'professionals.designProfessional.address',
      draft.professionals.designProfessional.address,
    );
    out.scalar(
      'professionals.designProfessional.prcNumber',
      draft.professionals.designProfessional.prcNumber,
    );
    out.date(
      'professionals.designProfessional.prcValidityDate',
      draft.professionals.designProfessional.prcValidityDate,
    );
    out.scalar(
      'professionals.designProfessional.ptrNumber',
      draft.professionals.designProfessional.ptrNumber,
    );
    out.date(
      'professionals.designProfessional.ptrDateIssued',
      draft.professionals.designProfessional.ptrDateIssued,
    );
    out.scalar(
      'professionals.designProfessional.ptrPlaceIssued',
      draft.professionals.designProfessional.ptrPlaceIssued,
    );
    out.scalar(
      'professionals.designProfessional.tin',
      draft.professionals.designProfessional.tin,
    );
    out.date(
      'professionals.designProfessional.dateSigned',
      draft.professionals.designProfessional.dateSigned,
    );
    out.document(
      'professionals.designSignedDocumentUpload',
      draft.professionals.designSignedDocumentUpload,
      'Design Signed Document',
    );
    out.document(
      'professionals.designPrcAndPtrUpload',
      draft.professionals.designPrcAndPtrUpload,
      'Design PRC and PTR',
    );
    out.scalar(
      'professionals.supervisor.fullName',
      draft.professionals.supervisor.fullName,
    );
    out.enumValue(
      'professionals.supervisor.profession',
      draft.professionals.supervisor.profession,
    );
    out.scalar(
      'professionals.supervisor.address',
      draft.professionals.supervisor.address,
    );
    out.scalar(
      'professionals.supervisor.prcNumber',
      draft.professionals.supervisor.prcNumber,
    );
    out.date(
      'professionals.supervisor.prcValidityDate',
      draft.professionals.supervisor.prcValidityDate,
    );
    out.scalar(
      'professionals.supervisor.ptrNumber',
      draft.professionals.supervisor.ptrNumber,
    );
    out.date(
      'professionals.supervisor.ptrDateIssued',
      draft.professionals.supervisor.ptrDateIssued,
    );
    out.scalar(
      'professionals.supervisor.ptrPlaceIssued',
      draft.professionals.supervisor.ptrPlaceIssued,
    );
    out.scalar(
      'professionals.supervisor.tin',
      draft.professionals.supervisor.tin,
    );
    out.date(
      'professionals.supervisor.dateSigned',
      draft.professionals.supervisor.dateSigned,
    );
    out.document(
      'professionals.supervisorSignedDocumentUpload',
      draft.professionals.supervisorSignedDocumentUpload,
      'Supervisor Signed Document',
    );
    out.scalar(
      'ownerConsent.owner.printedName',
      draft.ownerConsent.owner.printedName,
    );
    out.scalar('ownerConsent.owner.address', draft.ownerConsent.owner.address);
    out.scalar(
      'ownerConsent.owner.ctcNumber',
      draft.ownerConsent.owner.ctcNumber,
    );
    out.date(
      'ownerConsent.owner.ctcDateIssued',
      draft.ownerConsent.owner.ctcDateIssued,
    );
    out.scalar(
      'ownerConsent.owner.ctcPlaceIssued',
      draft.ownerConsent.owner.ctcPlaceIssued,
    );
    out.date(
      'ownerConsent.owner.dateSigned',
      draft.ownerConsent.owner.dateSigned,
    );
    out.document(
      'ownerConsent.ownerSignedDocumentUpload',
      draft.ownerConsent.ownerSignedDocumentUpload,
      'Owner Signed Document',
    );
    out.scalar(
      'ownerConsent.isOwnerAlsoLotOwner',
      draft.ownerConsent.isOwnerAlsoLotOwner,
    );
    out.scalar(
      'ownerConsent.lotOwner.printedName',
      draft.ownerConsent.lotOwner.printedName,
    );
    out.scalar(
      'ownerConsent.lotOwner.address',
      draft.ownerConsent.lotOwner.address,
    );
    out.scalar(
      'ownerConsent.lotOwner.ctcNumber',
      draft.ownerConsent.lotOwner.ctcNumber,
    );
    out.date(
      'ownerConsent.lotOwner.ctcDateIssued',
      draft.ownerConsent.lotOwner.ctcDateIssued,
    );
    out.scalar(
      'ownerConsent.lotOwner.ctcPlaceIssued',
      draft.ownerConsent.lotOwner.ctcPlaceIssued,
    );
    out.date(
      'ownerConsent.lotOwner.dateSigned',
      draft.ownerConsent.lotOwner.dateSigned,
    );
    out.document(
      'ownerConsent.lotOwnerSignedDocumentUpload',
      draft.ownerConsent.lotOwnerSignedDocumentUpload,
      'Lot Owner Signed Document',
    );
    out.scalar(
      'reviewDeclaration.certifiesInformationIsAccurate',
      draft.reviewDeclaration.certifiesInformationIsAccurate,
    );
    out.scalar(
      'reviewDeclaration.understandsMustFollowApprovedPlansAndRegulations',
      draft.reviewDeclaration.understandsMustFollowApprovedPlansAndRegulations,
    );
    out.scalar(
      'reviewDeclaration.understandsDependsOnRelatedBuildingPermit',
      draft.reviewDeclaration.understandsDependsOnRelatedBuildingPermit,
    );
    out.scalar(
      'reviewDeclaration.understandsProfessionalDocumentsMustBeAuthentic',
      draft.reviewDeclaration.understandsProfessionalDocumentsMustBeAuthentic,
    );
    out.scalar(
      'useApplicantAddressForConstructionLocation',
      draft.useApplicantAddressForConstructionLocation,
    );
    out.enumValue('status', draft.status);
    out.date('lastSavedAt', draft.lastSavedAt);
  }

  @override
  void restore(ExcavationPermitDraft draft, SnapshotReader input) {
    draft.relatedBuildingPermit.buildingPermitNumber = input.string(
      'relatedBuildingPermit.buildingPermitNumber',
    );
    draft.relatedBuildingPermit.status =
        input.enumValue(
          'relatedBuildingPermit.status',
          RelatedBuildingPermitStatus.values,
        ) ??
        RelatedBuildingPermitStatus.pending;
    draft.applicant.lastName = input.string('applicant.lastName');
    draft.applicant.firstName = input.string('applicant.firstName');
    draft.applicant.middleInitial = input.string('applicant.middleInitial');
    draft.applicant.tin = input.string('applicant.tin');
    draft.applicant.contactNumber = input.string('applicant.contactNumber');
    draft.applicant.isOwnedByEnterprise = input.boolean(
      'applicant.isOwnedByEnterprise',
    );
    draft.applicant.enterpriseName = input.string('applicant.enterpriseName');
    draft.applicant.formOfOwnership = input.nullableString(
      'applicant.formOfOwnership',
    );
    draft.applicant.occupancyGroup = input.enumValue(
      'applicant.occupancyGroup',
      ExcavationOccupancyGroup.values,
    );
    draft.applicant.occupancyOtherDescription = input.string(
      'applicant.occupancyOtherDescription',
    );
    draft.applicant.addressNumber = input.string('applicant.addressNumber');
    draft.applicant.street = input.string('applicant.street');
    draft.applicant.barangay = input.string('applicant.barangay');
    draft.applicant.city = input.string('applicant.city');
    draft.applicant.zipCode = input.string('applicant.zipCode');
    draft.constructionLocation.landTitleOrTaxDeclarationUpload = input.document(
      'constructionLocation.landTitleOrTaxDeclarationUpload',
    );
    draft.constructionLocation.barangayClearanceUpload = input.document(
      'constructionLocation.barangayClearanceUpload',
    );
    draft.constructionLocation.locationalClearanceUpload = input.document(
      'constructionLocation.locationalClearanceUpload',
    );
    draft.constructionLocation.validGovernmentIdUpload = input.document(
      'constructionLocation.validGovernmentIdUpload',
    );
    draft.constructionLocation.lotNumber = input.string(
      'constructionLocation.lotNumber',
    );
    draft.constructionLocation.blockNumber = input.string(
      'constructionLocation.blockNumber',
    );
    draft.constructionLocation.tctNumber = input.string(
      'constructionLocation.tctNumber',
    );
    draft.constructionLocation.taxDeclarationNumber = input.string(
      'constructionLocation.taxDeclarationNumber',
    );
    draft.constructionLocation.street = input.string(
      'constructionLocation.street',
    );
    draft.constructionLocation.barangay = input.string(
      'constructionLocation.barangay',
    );
    draft.constructionLocation.city = input.string('constructionLocation.city');
    draft.scopeOfWork.selectedScopes
      ..clear()
      ..addAll(
        input.enumSet('scopeOfWork.selectedScopes', ExcavationScopeType.values),
      );
    draft.scopeOfWork.otherScopeDescription = input.string(
      'scopeOfWork.otherScopeDescription',
    );
    draft.excavationDetails.selectedWorkTypes
      ..clear()
      ..addAll(
        input.enumSet(
          'excavationDetails.selectedWorkTypes',
          ExcavationWorkType.values,
        ),
      );
    draft.excavationDetails.otherWorkTypeDescription = input.string(
      'excavationDetails.otherWorkTypeDescription',
    );
    draft.excavationDetails.excavationDepthMeters = input.string(
      'excavationDetails.excavationDepthMeters',
    );
    draft.excavationDetails.excavationVolumeCubicMeters = input.string(
      'excavationDetails.excavationVolumeCubicMeters',
    );
    draft.professionals.designProfessional.fullName = input.string(
      'professionals.designProfessional.fullName',
    );
    draft.professionals.designProfessional.profession = input.enumValue(
      'professionals.designProfessional.profession',
      ExcavationProfessionType.values,
    );
    draft.professionals.designProfessional.address = input.string(
      'professionals.designProfessional.address',
    );
    draft.professionals.designProfessional.prcNumber = input.string(
      'professionals.designProfessional.prcNumber',
    );
    draft.professionals.designProfessional.prcValidityDate = input.date(
      'professionals.designProfessional.prcValidityDate',
    );
    draft.professionals.designProfessional.ptrNumber = input.string(
      'professionals.designProfessional.ptrNumber',
    );
    draft.professionals.designProfessional.ptrDateIssued = input.date(
      'professionals.designProfessional.ptrDateIssued',
    );
    draft.professionals.designProfessional.ptrPlaceIssued = input.string(
      'professionals.designProfessional.ptrPlaceIssued',
    );
    draft.professionals.designProfessional.tin = input.string(
      'professionals.designProfessional.tin',
    );
    draft.professionals.designProfessional.dateSigned = input.date(
      'professionals.designProfessional.dateSigned',
    );
    draft.professionals.designSignedDocumentUpload = input.document(
      'professionals.designSignedDocumentUpload',
    );
    draft.professionals.designPrcAndPtrUpload = input.document(
      'professionals.designPrcAndPtrUpload',
    );
    draft.professionals.supervisor.fullName = input.string(
      'professionals.supervisor.fullName',
    );
    draft.professionals.supervisor.profession = input.enumValue(
      'professionals.supervisor.profession',
      ExcavationProfessionType.values,
    );
    draft.professionals.supervisor.address = input.string(
      'professionals.supervisor.address',
    );
    draft.professionals.supervisor.prcNumber = input.string(
      'professionals.supervisor.prcNumber',
    );
    draft.professionals.supervisor.prcValidityDate = input.date(
      'professionals.supervisor.prcValidityDate',
    );
    draft.professionals.supervisor.ptrNumber = input.string(
      'professionals.supervisor.ptrNumber',
    );
    draft.professionals.supervisor.ptrDateIssued = input.date(
      'professionals.supervisor.ptrDateIssued',
    );
    draft.professionals.supervisor.ptrPlaceIssued = input.string(
      'professionals.supervisor.ptrPlaceIssued',
    );
    draft.professionals.supervisor.tin = input.string(
      'professionals.supervisor.tin',
    );
    draft.professionals.supervisor.dateSigned = input.date(
      'professionals.supervisor.dateSigned',
    );
    draft.professionals.supervisorSignedDocumentUpload = input.document(
      'professionals.supervisorSignedDocumentUpload',
    );
    draft.ownerConsent.owner.printedName = input.string(
      'ownerConsent.owner.printedName',
    );
    draft.ownerConsent.owner.address = input.string(
      'ownerConsent.owner.address',
    );
    draft.ownerConsent.owner.ctcNumber = input.string(
      'ownerConsent.owner.ctcNumber',
    );
    draft.ownerConsent.owner.ctcDateIssued = input.date(
      'ownerConsent.owner.ctcDateIssued',
    );
    draft.ownerConsent.owner.ctcPlaceIssued = input.string(
      'ownerConsent.owner.ctcPlaceIssued',
    );
    draft.ownerConsent.owner.dateSigned = input.date(
      'ownerConsent.owner.dateSigned',
    );
    draft.ownerConsent.ownerSignedDocumentUpload = input.document(
      'ownerConsent.ownerSignedDocumentUpload',
    );
    draft.ownerConsent.isOwnerAlsoLotOwner = input.nullableBoolean(
      'ownerConsent.isOwnerAlsoLotOwner',
    );
    draft.ownerConsent.lotOwner.printedName = input.string(
      'ownerConsent.lotOwner.printedName',
    );
    draft.ownerConsent.lotOwner.address = input.string(
      'ownerConsent.lotOwner.address',
    );
    draft.ownerConsent.lotOwner.ctcNumber = input.string(
      'ownerConsent.lotOwner.ctcNumber',
    );
    draft.ownerConsent.lotOwner.ctcDateIssued = input.date(
      'ownerConsent.lotOwner.ctcDateIssued',
    );
    draft.ownerConsent.lotOwner.ctcPlaceIssued = input.string(
      'ownerConsent.lotOwner.ctcPlaceIssued',
    );
    draft.ownerConsent.lotOwner.dateSigned = input.date(
      'ownerConsent.lotOwner.dateSigned',
    );
    draft.ownerConsent.lotOwnerSignedDocumentUpload = input.document(
      'ownerConsent.lotOwnerSignedDocumentUpload',
    );
    draft.reviewDeclaration.certifiesInformationIsAccurate = input.boolean(
      'reviewDeclaration.certifiesInformationIsAccurate',
    );
    draft.reviewDeclaration.understandsMustFollowApprovedPlansAndRegulations =
        input.boolean(
          'reviewDeclaration.understandsMustFollowApprovedPlansAndRegulations',
        );
    draft.reviewDeclaration.understandsDependsOnRelatedBuildingPermit = input
        .boolean('reviewDeclaration.understandsDependsOnRelatedBuildingPermit');
    draft.reviewDeclaration.understandsProfessionalDocumentsMustBeAuthentic =
        input.boolean(
          'reviewDeclaration.understandsProfessionalDocumentsMustBeAuthentic',
        );
    draft.useApplicantAddressForConstructionLocation = input.boolean(
      'useApplicantAddressForConstructionLocation',
    );
    // Not read back: a restored draft is always a draft. Honouring a
    // stored `submitted` would resurrect a filed application as editable.
    draft.status = ExcavationPermitDraftStatus.draft;
    draft.lastSavedAt = input.date('lastSavedAt');
  }
}
