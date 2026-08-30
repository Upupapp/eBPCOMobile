import '../models/electronics_permit_model.dart';
import 'draft_snapshot.dart';

/// Electronics — ElectronicsPermitDraft, persisted.
///
/// One of the seventeen wizards converted in M-48 part 2, after the mechanism
/// was proven on the Building Permit and Fencing. Every field the draft
/// declares is captured and read back except the 17 attachment slots,
/// which are dropped and named back to the applicant, and whatever
/// `test/architecture/draft_snapshot_completeness_test.dart` exempts with a
/// reason. That gate fails the day this file falls behind the model.
///
/// Written mechanically from the model's own field declarations and then
/// reviewed, which is why it reads uniformly. The alternative — trusting a
/// generator without a gate — is how 101 fields become 101 chances to
/// drop one silently.
class ElectronicsPermitDraftCodec extends DraftCodec<ElectronicsPermitDraft> {
  const ElectronicsPermitDraftCodec();

  @override
  String get permitKey => 'electronics-permit';

  @override
  String get permitLabel => 'Electronics';

  @override
  void capture(ElectronicsPermitDraft draft, SnapshotWriter out) {
    out.scalar('applicant.firstName', draft.applicant.firstName);
    out.scalar('applicant.middleInitial', draft.applicant.middleInitial);
    out.scalar('applicant.lastName', draft.applicant.lastName);
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
    out.scalar(
      'applicantAddress.houseNumber',
      draft.applicantAddress.houseNumber,
    );
    out.scalar('applicantAddress.street', draft.applicantAddress.street);
    out.scalar('applicantAddress.barangay', draft.applicantAddress.barangay);
    out.scalar('applicantAddress.city', draft.applicantAddress.city);
    out.scalar('applicantAddress.province', draft.applicantAddress.province);
    out.scalar('applicantAddress.zipCode', draft.applicantAddress.zipCode);
    out.scalar('projectLocation.lotNumber', draft.projectLocation.lotNumber);
    out.scalar(
      'projectLocation.blockNumber',
      draft.projectLocation.blockNumber,
    );
    out.scalar('projectLocation.tctNumber', draft.projectLocation.tctNumber);
    out.scalar(
      'projectLocation.taxDeclarationNumber',
      draft.projectLocation.taxDeclarationNumber,
    );
    out.scalar('projectLocation.street', draft.projectLocation.street);
    out.scalar('projectLocation.barangay', draft.projectLocation.barangay);
    out.scalar('projectLocation.city', draft.projectLocation.city);
    out.scalar('projectLocation.province', draft.projectLocation.province);
    out.scalar(
      'relatedBuildingPermit.buildingPermitNumber',
      draft.relatedBuildingPermit.buildingPermitNumber,
    );
    out.enumValue(
      'relatedBuildingPermit.status',
      draft.relatedBuildingPermit.status,
    );
    out.enumSet('scopeOfWork.selectedScopes', draft.scopeOfWork.selectedScopes);
    out.scalar(
      'scopeOfWork.otherScopeDescription',
      draft.scopeOfWork.otherScopeDescription,
    );
    out.enumSet(
      'installationNature.selectedSystems',
      draft.installationNature.selectedSystems,
    );
    out.scalar(
      'installationNature.otherSystemSpecification',
      draft.installationNature.otherSystemSpecification,
    );
    out.scalar(
      'professionals.designProfessional.fullName',
      draft.professionals.designProfessional.fullName,
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
      'professionals.designPrcIdUpload',
      draft.professionals.designPrcIdUpload,
      'Design PRC ID',
    );
    out.document(
      'professionals.designPtrDocumentUpload',
      draft.professionals.designPtrDocumentUpload,
      'Design PTR Document',
    );
    out.document(
      'professionals.signedSealedPlansUpload',
      draft.professionals.signedSealedPlansUpload,
      'Signed Sealed Plans',
    );
    out.document(
      'professionals.signedSealedSpecificationsUpload',
      draft.professionals.signedSealedSpecificationsUpload,
      'Signed Sealed Specifications',
    );
    out.document(
      'professionals.signedDesignCalculationsUpload',
      draft.professionals.signedDesignCalculationsUpload,
      'Signed Design Calculations',
    );
    out.scalar(
      'professionals.isSupervisorSameAsDesignProfessional',
      draft.professionals.isSupervisorSameAsDesignProfessional,
    );
    out.scalar(
      'professionals.supervisor.fullName',
      draft.professionals.supervisor.fullName,
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
      'professionals.supervisorPrcIdUpload',
      draft.professionals.supervisorPrcIdUpload,
      'Supervisor PRC ID',
    );
    out.document(
      'professionals.supervisorPtrUpload',
      draft.professionals.supervisorPtrUpload,
      'Supervisor PTR',
    );
    out.document(
      'professionals.signedSupervisorConfirmationUpload',
      draft.professionals.signedSupervisorConfirmationUpload,
      'Signed Supervisor Confirmation',
    );
    out.scalar(
      'ownershipConsent.isApplicantBuildingOwner',
      draft.ownershipConsent.isApplicantBuildingOwner,
    );
    out.scalar(
      'ownershipConsent.buildingOwner.fullName',
      draft.ownershipConsent.buildingOwner.fullName,
    );
    out.scalar(
      'ownershipConsent.buildingOwner.address',
      draft.ownershipConsent.buildingOwner.address,
    );
    out.scalar(
      'ownershipConsent.buildingOwner.ctcNumber',
      draft.ownershipConsent.buildingOwner.ctcNumber,
    );
    out.date(
      'ownershipConsent.buildingOwner.ctcDateIssued',
      draft.ownershipConsent.buildingOwner.ctcDateIssued,
    );
    out.scalar(
      'ownershipConsent.buildingOwner.ctcPlaceIssued',
      draft.ownershipConsent.buildingOwner.ctcPlaceIssued,
    );
    out.scalar(
      'ownershipConsent.isBuildingOwnerAlsoLotOwner',
      draft.ownershipConsent.isBuildingOwnerAlsoLotOwner,
    );
    out.scalar(
      'ownershipConsent.lotOwner.fullName',
      draft.ownershipConsent.lotOwner.fullName,
    );
    out.scalar(
      'ownershipConsent.lotOwner.address',
      draft.ownershipConsent.lotOwner.address,
    );
    out.scalar(
      'ownershipConsent.lotOwner.ctcNumber',
      draft.ownershipConsent.lotOwner.ctcNumber,
    );
    out.date(
      'ownershipConsent.lotOwner.ctcDateIssued',
      draft.ownershipConsent.lotOwner.ctcDateIssued,
    );
    out.scalar(
      'ownershipConsent.lotOwner.ctcPlaceIssued',
      draft.ownershipConsent.lotOwner.ctcPlaceIssued,
    );
    out.document(
      'ownershipConsent.buildingOwnerValidIdUpload',
      draft.ownershipConsent.buildingOwnerValidIdUpload,
      'Building Owner Valid ID',
    );
    out.document(
      'ownershipConsent.lotOwnerValidIdUpload',
      draft.ownershipConsent.lotOwnerValidIdUpload,
      'Lot Owner Valid ID',
    );
    out.document(
      'ownershipConsent.proofOfOwnershipUpload',
      draft.ownershipConsent.proofOfOwnershipUpload,
      'Proof of Ownership',
    );
    out.document(
      'ownershipConsent.lotOwnerConsentUpload',
      draft.ownershipConsent.lotOwnerConsentUpload,
      'Lot Owner Consent',
    );
    out.document(
      'ownershipConsent.authorizationLetterUpload',
      draft.ownershipConsent.authorizationLetterUpload,
      'Authorization Letter',
    );
    out.document(
      'requiredDocuments.billOfMaterialsUpload',
      draft.requiredDocuments.billOfMaterialsUpload,
      'Bill of Materials',
    );
    out.document(
      'requiredDocuments.costEstimatesUpload',
      draft.requiredDocuments.costEstimatesUpload,
      'Cost Estimates',
    );
    out.document(
      'requiredDocuments.relatedBuildingPermitUpload',
      draft.requiredDocuments.relatedBuildingPermitUpload,
      'Related Building Permit',
    );
    out.document(
      'requiredDocuments.otherSupportingDocumentsUpload',
      draft.requiredDocuments.otherSupportingDocumentsUpload,
      'Other Supporting Documents',
    );
    out.scalar(
      'reviewDeclaration.certifiesTrueAndCorrect',
      draft.reviewDeclaration.certifiesTrueAndCorrect,
    );
    out.scalar(
      'reviewDeclaration.confirmsPlansPreparedByLicensedProfessional',
      draft.reviewDeclaration.confirmsPlansPreparedByLicensedProfessional,
    );
    out.scalar(
      'reviewDeclaration.understandsMustFollowApprovedPlansAndCodes',
      draft.reviewDeclaration.understandsMustFollowApprovedPlansAndCodes,
    );
    out.scalar(
      'reviewDeclaration.understandsRequiresLicensedSupervisor',
      draft.reviewDeclaration.understandsRequiresLicensedSupervisor,
    );
    out.scalar(
      'reviewDeclaration.understandsNoticeOfConstructionMayBeRequired',
      draft.reviewDeclaration.understandsNoticeOfConstructionMayBeRequired,
    );
    out.scalar(
      'reviewDeclaration.understandsCompletionDocumentsMayBeRequired',
      draft.reviewDeclaration.understandsCompletionDocumentsMayBeRequired,
    );
    out.scalar(
      'reviewDeclaration.understandsRequiresValidBuildingPermit',
      draft.reviewDeclaration.understandsRequiresValidBuildingPermit,
    );
    out.scalar(
      'reviewDeclaration.agreesToTerms',
      draft.reviewDeclaration.agreesToTerms,
    );
    out.scalar(
      'useApplicantAddressForProjectLocation',
      draft.useApplicantAddressForProjectLocation,
    );
    out.enumValue('status', draft.status);
    out.date('lastSavedAt', draft.lastSavedAt);
  }

  @override
  void restore(ElectronicsPermitDraft draft, SnapshotReader input) {
    draft.applicant.firstName = input.string('applicant.firstName');
    draft.applicant.middleInitial = input.string('applicant.middleInitial');
    draft.applicant.lastName = input.string('applicant.lastName');
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
      ElectronicsOccupancyGroup.values,
    );
    draft.applicant.occupancyOtherDescription = input.string(
      'applicant.occupancyOtherDescription',
    );
    draft.applicantAddress.houseNumber = input.string(
      'applicantAddress.houseNumber',
    );
    draft.applicantAddress.street = input.string('applicantAddress.street');
    draft.applicantAddress.barangay = input.string('applicantAddress.barangay');
    draft.applicantAddress.city = input.string('applicantAddress.city');
    draft.applicantAddress.province = input.string('applicantAddress.province');
    draft.applicantAddress.zipCode = input.string('applicantAddress.zipCode');
    draft.projectLocation.lotNumber = input.string('projectLocation.lotNumber');
    draft.projectLocation.blockNumber = input.string(
      'projectLocation.blockNumber',
    );
    draft.projectLocation.tctNumber = input.string('projectLocation.tctNumber');
    draft.projectLocation.taxDeclarationNumber = input.string(
      'projectLocation.taxDeclarationNumber',
    );
    draft.projectLocation.street = input.string('projectLocation.street');
    draft.projectLocation.barangay = input.string('projectLocation.barangay');
    draft.projectLocation.city = input.string('projectLocation.city');
    draft.projectLocation.province = input.string('projectLocation.province');
    draft.relatedBuildingPermit.buildingPermitNumber = input.string(
      'relatedBuildingPermit.buildingPermitNumber',
    );
    draft.relatedBuildingPermit.status =
        input.enumValue(
          'relatedBuildingPermit.status',
          RelatedBuildingPermitStatus.values,
        ) ??
        RelatedBuildingPermitStatus.pending;
    draft.scopeOfWork.selectedScopes
      ..clear()
      ..addAll(
        input.enumSet(
          'scopeOfWork.selectedScopes',
          ElectronicsScopeType.values,
        ),
      );
    draft.scopeOfWork.otherScopeDescription = input.string(
      'scopeOfWork.otherScopeDescription',
    );
    draft.installationNature.selectedSystems
      ..clear()
      ..addAll(
        input.enumSet(
          'installationNature.selectedSystems',
          ElectronicsSystemType.values,
        ),
      );
    draft.installationNature.otherSystemSpecification = input.string(
      'installationNature.otherSystemSpecification',
    );
    draft.professionals.designProfessional.fullName = input.string(
      'professionals.designProfessional.fullName',
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
    draft.professionals.designPrcIdUpload = input.document(
      'professionals.designPrcIdUpload',
    );
    draft.professionals.designPtrDocumentUpload = input.document(
      'professionals.designPtrDocumentUpload',
    );
    draft.professionals.signedSealedPlansUpload = input.document(
      'professionals.signedSealedPlansUpload',
    );
    draft.professionals.signedSealedSpecificationsUpload = input.document(
      'professionals.signedSealedSpecificationsUpload',
    );
    draft.professionals.signedDesignCalculationsUpload = input.document(
      'professionals.signedDesignCalculationsUpload',
    );
    draft.professionals.isSupervisorSameAsDesignProfessional = input.boolean(
      'professionals.isSupervisorSameAsDesignProfessional',
      fallback: true,
    );
    draft.professionals.supervisor.fullName = input.string(
      'professionals.supervisor.fullName',
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
    draft.professionals.supervisorPrcIdUpload = input.document(
      'professionals.supervisorPrcIdUpload',
    );
    draft.professionals.supervisorPtrUpload = input.document(
      'professionals.supervisorPtrUpload',
    );
    draft.professionals.signedSupervisorConfirmationUpload = input.document(
      'professionals.signedSupervisorConfirmationUpload',
    );
    draft.ownershipConsent.isApplicantBuildingOwner = input.nullableBoolean(
      'ownershipConsent.isApplicantBuildingOwner',
    );
    draft.ownershipConsent.buildingOwner.fullName = input.string(
      'ownershipConsent.buildingOwner.fullName',
    );
    draft.ownershipConsent.buildingOwner.address = input.string(
      'ownershipConsent.buildingOwner.address',
    );
    draft.ownershipConsent.buildingOwner.ctcNumber = input.string(
      'ownershipConsent.buildingOwner.ctcNumber',
    );
    draft.ownershipConsent.buildingOwner.ctcDateIssued = input.date(
      'ownershipConsent.buildingOwner.ctcDateIssued',
    );
    draft.ownershipConsent.buildingOwner.ctcPlaceIssued = input.string(
      'ownershipConsent.buildingOwner.ctcPlaceIssued',
    );
    draft.ownershipConsent.isBuildingOwnerAlsoLotOwner = input.nullableBoolean(
      'ownershipConsent.isBuildingOwnerAlsoLotOwner',
    );
    draft.ownershipConsent.lotOwner.fullName = input.string(
      'ownershipConsent.lotOwner.fullName',
    );
    draft.ownershipConsent.lotOwner.address = input.string(
      'ownershipConsent.lotOwner.address',
    );
    draft.ownershipConsent.lotOwner.ctcNumber = input.string(
      'ownershipConsent.lotOwner.ctcNumber',
    );
    draft.ownershipConsent.lotOwner.ctcDateIssued = input.date(
      'ownershipConsent.lotOwner.ctcDateIssued',
    );
    draft.ownershipConsent.lotOwner.ctcPlaceIssued = input.string(
      'ownershipConsent.lotOwner.ctcPlaceIssued',
    );
    draft.ownershipConsent.buildingOwnerValidIdUpload = input.document(
      'ownershipConsent.buildingOwnerValidIdUpload',
    );
    draft.ownershipConsent.lotOwnerValidIdUpload = input.document(
      'ownershipConsent.lotOwnerValidIdUpload',
    );
    draft.ownershipConsent.proofOfOwnershipUpload = input.document(
      'ownershipConsent.proofOfOwnershipUpload',
    );
    draft.ownershipConsent.lotOwnerConsentUpload = input.document(
      'ownershipConsent.lotOwnerConsentUpload',
    );
    draft.ownershipConsent.authorizationLetterUpload = input.document(
      'ownershipConsent.authorizationLetterUpload',
    );
    draft.requiredDocuments.billOfMaterialsUpload = input.document(
      'requiredDocuments.billOfMaterialsUpload',
    );
    draft.requiredDocuments.costEstimatesUpload = input.document(
      'requiredDocuments.costEstimatesUpload',
    );
    draft.requiredDocuments.relatedBuildingPermitUpload = input.document(
      'requiredDocuments.relatedBuildingPermitUpload',
    );
    draft.requiredDocuments.otherSupportingDocumentsUpload = input.document(
      'requiredDocuments.otherSupportingDocumentsUpload',
    );
    draft.reviewDeclaration.certifiesTrueAndCorrect = input.boolean(
      'reviewDeclaration.certifiesTrueAndCorrect',
    );
    draft.reviewDeclaration.confirmsPlansPreparedByLicensedProfessional = input
        .boolean(
          'reviewDeclaration.confirmsPlansPreparedByLicensedProfessional',
        );
    draft.reviewDeclaration.understandsMustFollowApprovedPlansAndCodes = input
        .boolean(
          'reviewDeclaration.understandsMustFollowApprovedPlansAndCodes',
        );
    draft.reviewDeclaration.understandsRequiresLicensedSupervisor = input
        .boolean('reviewDeclaration.understandsRequiresLicensedSupervisor');
    draft.reviewDeclaration.understandsNoticeOfConstructionMayBeRequired = input
        .boolean(
          'reviewDeclaration.understandsNoticeOfConstructionMayBeRequired',
        );
    draft.reviewDeclaration.understandsCompletionDocumentsMayBeRequired = input
        .boolean(
          'reviewDeclaration.understandsCompletionDocumentsMayBeRequired',
        );
    draft.reviewDeclaration.understandsRequiresValidBuildingPermit = input
        .boolean('reviewDeclaration.understandsRequiresValidBuildingPermit');
    draft.reviewDeclaration.agreesToTerms = input.boolean(
      'reviewDeclaration.agreesToTerms',
    );
    draft.useApplicantAddressForProjectLocation = input.boolean(
      'useApplicantAddressForProjectLocation',
    );
    // Not read back: a restored draft is always a draft. Honouring a
    // stored `submitted` would resurrect a filed application as editable.
    draft.status = ElectronicsPermitDraftStatus.draft;
    draft.lastSavedAt = input.date('lastSavedAt');
  }
}
