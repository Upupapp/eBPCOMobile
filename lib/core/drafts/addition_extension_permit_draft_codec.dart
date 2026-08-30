import '../models/addition_extension_permit_model.dart';
import 'draft_snapshot.dart';

/// Addition / Extension — AdditionExtensionPermitDraft, persisted.
///
/// One of the seventeen wizards converted in M-48 part 2, after the mechanism
/// was proven on the Building Permit and Fencing. Every field the draft
/// declares is captured and read back except the 35 attachment slots,
/// which are dropped and named back to the applicant, and whatever
/// `test/architecture/draft_snapshot_completeness_test.dart` exempts with a
/// reason. That gate fails the day this file falls behind the model.
///
/// Written mechanically from the model's own field declarations and then
/// reviewed, which is why it reads uniformly. The alternative — trusting a
/// generator without a gate — is how 113 fields become 113 chances to
/// drop one silently.
class AdditionExtensionPermitDraftCodec
    extends DraftCodec<AdditionExtensionPermitDraft> {
  const AdditionExtensionPermitDraftCodec();

  @override
  String get permitKey => 'addition-extension-permit';

  @override
  String get permitLabel => 'Addition / Extension';

  @override
  void capture(AdditionExtensionPermitDraft draft, SnapshotWriter out) {
    out.enumValue('applicant.applicationType', draft.applicant.applicationType);
    out.scalar('applicant.firstName', draft.applicant.firstName);
    out.scalar('applicant.middleName', draft.applicant.middleName);
    out.scalar('applicant.lastName', draft.applicant.lastName);
    out.scalar('applicant.tin', draft.applicant.tin);
    out.scalar('applicant.contactNumber', draft.applicant.contactNumber);
    out.scalar(
      'applicant.isOwnedByEnterprise',
      draft.applicant.isOwnedByEnterprise,
    );
    out.scalar('applicant.enterpriseName', draft.applicant.enterpriseName);
    out.scalar('applicant.formOfOwnership', draft.applicant.formOfOwnership);
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
      'projectInformation.projectTitle',
      draft.projectInformation.projectTitle,
    );
    out.scalar(
      'projectInformation.generalDescription',
      draft.projectInformation.generalDescription,
    );
    out.scalar(
      'projectInformation.existingBuildingDescription',
      draft.projectInformation.existingBuildingDescription,
    );
    out.scalar(
      'projectInformation.purposeOfProposedAddition',
      draft.projectInformation.purposeOfProposedAddition,
    );
    out.scalar(
      'projectInformation.connectionToExistingBuilding',
      draft.projectInformation.connectionToExistingBuilding,
    );
    out.scalar(
      'projectInformation.otherProjectDetails',
      draft.projectInformation.otherProjectDetails,
    );
    out.enumValue(
      'projectInformation.additionType',
      draft.projectInformation.additionType,
    );
    out.scalar(
      'projectInformation.otherAdditionTypeDescription',
      draft.projectInformation.otherAdditionTypeDescription,
    );
    out.enumSet(
      'projectInformation.affectedAreas',
      draft.projectInformation.affectedAreas,
    );
    out.scalar(
      'projectInformation.otherAffectedAreaDescription',
      draft.projectInformation.otherAffectedAreaDescription,
    );
    out.enumValue(
      'buildingDetails.occupancyGroup',
      draft.buildingDetails.occupancyGroup,
    );
    out.scalar(
      'buildingDetails.occupancyOtherDescription',
      draft.buildingDetails.occupancyOtherDescription,
    );
    out.scalar(
      'buildingDetails.existingOccupancyClassification',
      draft.buildingDetails.existingOccupancyClassification,
    );
    out.scalar(
      'buildingDetails.existingNumberOfUnits',
      draft.buildingDetails.existingNumberOfUnits,
    );
    out.scalar(
      'buildingDetails.existingNumberOfStoreys',
      draft.buildingDetails.existingNumberOfStoreys,
    );
    out.scalar(
      'buildingDetails.existingFloorArea',
      draft.buildingDetails.existingFloorArea,
    );
    out.scalar(
      'buildingDetails.proposedAddedNumberOfUnits',
      draft.buildingDetails.proposedAddedNumberOfUnits,
    );
    out.scalar(
      'buildingDetails.proposedAdditionalStoreys',
      draft.buildingDetails.proposedAdditionalStoreys,
    );
    out.scalar(
      'buildingDetails.proposedAddedFloorArea',
      draft.buildingDetails.proposedAddedFloorArea,
    );
    out.scalar('buildingDetails.lotArea', draft.buildingDetails.lotArea);
    out.scalar(
      'buildingDetails.estimatedCost',
      draft.buildingDetails.estimatedCost,
    );
    out.date(
      'buildingDetails.proposedStartDate',
      draft.buildingDetails.proposedStartDate,
    );
    out.date(
      'buildingDetails.expectedCompletionDate',
      draft.buildingDetails.expectedCompletionDate,
    );
    out.scalar('professional.fullName', draft.professional.fullName);
    out.enumValue('professional.profession', draft.professional.profession);
    out.scalar(
      'professional.professionalAddress',
      draft.professional.professionalAddress,
    );
    out.scalar('professional.prcNumber', draft.professional.prcNumber);
    out.date(
      'professional.prcValidityDate',
      draft.professional.prcValidityDate,
    );
    out.scalar('professional.ptrNumber', draft.professional.ptrNumber);
    out.date('professional.ptrDateIssued', draft.professional.ptrDateIssued);
    out.scalar(
      'professional.ptrPlaceIssued',
      draft.professional.ptrPlaceIssued,
    );
    out.scalar('professional.tin', draft.professional.tin);
    out.date('professional.dateSigned', draft.professional.dateSigned);
    out.document(
      'professional.prcIdUpload',
      draft.professional.prcIdUpload,
      'PRC ID',
    );
    out.document(
      'professional.ptrDocumentUpload',
      draft.professional.ptrDocumentUpload,
      'PTR Document',
    );
    out.document(
      'professional.signedSealedFormUpload',
      draft.professional.signedSealedFormUpload,
      'Signed Sealed Form',
    );
    out.document(
      'professional.signedSealedPlansUpload',
      draft.professional.signedSealedPlansUpload,
      'Signed Sealed Plans',
    );
    out.document(
      'professional.structuralAnalysisUpload',
      draft.professional.structuralAnalysisUpload,
      'Structural Analysis',
    );
    out.scalar(
      'consentAuthorization.isRegisteredOwner',
      draft.consentAuthorization.isRegisteredOwner,
    );
    out.scalar(
      'consentAuthorization.registeredOwnerFullName',
      draft.consentAuthorization.registeredOwnerFullName,
    );
    out.scalar(
      'consentAuthorization.representativeFullName',
      draft.consentAuthorization.representativeFullName,
    );
    out.scalar(
      'consentAuthorization.representativeAddress',
      draft.consentAuthorization.representativeAddress,
    );
    out.scalar(
      'consentAuthorization.ctcNumber',
      draft.consentAuthorization.ctcNumber,
    );
    out.date(
      'consentAuthorization.ctcDateIssued',
      draft.consentAuthorization.ctcDateIssued,
    );
    out.scalar(
      'consentAuthorization.ctcPlaceIssued',
      draft.consentAuthorization.ctcPlaceIssued,
    );
    out.document(
      'consentAuthorization.authorizationLetterUpload',
      draft.consentAuthorization.authorizationLetterUpload,
      'Authorization Letter',
    );
    out.document(
      'consentAuthorization.ownerValidIdUpload',
      draft.consentAuthorization.ownerValidIdUpload,
      'Owner Valid ID',
    );
    out.document(
      'consentAuthorization.representativeValidIdUpload',
      draft.consentAuthorization.representativeValidIdUpload,
      'Representative Valid ID',
    );
    out.document(
      'consentAuthorization.proofOfOwnershipUpload',
      draft.consentAuthorization.proofOfOwnershipUpload,
      'Proof of Ownership',
    );
    out.document(
      'requiredDocuments.landTitleUpload',
      draft.requiredDocuments.landTitleUpload,
      'Land Title',
    );
    out.document(
      'requiredDocuments.taxDeclarationUpload',
      draft.requiredDocuments.taxDeclarationUpload,
      'Tax Declaration',
    );
    out.document(
      'requiredDocuments.realPropertyTaxReceiptUpload',
      draft.requiredDocuments.realPropertyTaxReceiptUpload,
      'Real Property Tax Receipt',
    );
    out.document(
      'requiredDocuments.proofOfOwnershipOrAuthorityUpload',
      draft.requiredDocuments.proofOfOwnershipOrAuthorityUpload,
      'Proof of Ownership or Authority',
    );
    out.document(
      'requiredDocuments.existingBuildingPermit.upload',
      draft.requiredDocuments.existingBuildingPermit.upload,
      'Upload',
    );
    out.scalar(
      'requiredDocuments.existingBuildingPermit.markedNotAvailable',
      draft.requiredDocuments.existingBuildingPermit.markedNotAvailable,
    );
    out.document(
      'requiredDocuments.existingCertificateOfOccupancy.upload',
      draft.requiredDocuments.existingCertificateOfOccupancy.upload,
      'Upload',
    );
    out.scalar(
      'requiredDocuments.existingCertificateOfOccupancy.markedNotAvailable',
      draft.requiredDocuments.existingCertificateOfOccupancy.markedNotAvailable,
    );
    out.document(
      'requiredDocuments.existingApprovedBuildingPlans.upload',
      draft.requiredDocuments.existingApprovedBuildingPlans.upload,
      'Upload',
    );
    out.scalar(
      'requiredDocuments.existingApprovedBuildingPlans.markedNotAvailable',
      draft.requiredDocuments.existingApprovedBuildingPlans.markedNotAvailable,
    );
    out.document(
      'requiredDocuments.recentPhotographs.upload',
      draft.requiredDocuments.recentPhotographs.upload,
      'Upload',
    );
    out.scalar(
      'requiredDocuments.recentPhotographs.markedNotAvailable',
      draft.requiredDocuments.recentPhotographs.markedNotAvailable,
    );
    out.document(
      'requiredDocuments.asBuiltPlansUpload',
      draft.requiredDocuments.asBuiltPlansUpload,
      'As-built plans',
    );
    out.document(
      'requiredDocuments.additionExtensionPlansUpload',
      draft.requiredDocuments.additionExtensionPlansUpload,
      'Addition Extension Plans',
    );
    out.document(
      'requiredDocuments.architecturalPlansUpload',
      draft.requiredDocuments.architecturalPlansUpload,
      'Architectural Plans',
    );
    out.document(
      'requiredDocuments.technicalSpecificationsUpload',
      draft.requiredDocuments.technicalSpecificationsUpload,
      'Technical Specifications',
    );
    out.document(
      'requiredDocuments.billOfMaterialsUpload',
      draft.requiredDocuments.billOfMaterialsUpload,
      'Bill of Materials',
    );
    out.document(
      'requiredDocuments.detailedCostEstimateUpload',
      draft.requiredDocuments.detailedCostEstimateUpload,
      'Detailed Cost Estimate',
    );
    out.document(
      'requiredDocuments.siteDevelopmentPlanUpload',
      draft.requiredDocuments.siteDevelopmentPlanUpload,
      'Site Development Plan',
    );
    out.document(
      'requiredDocuments.civilStructuralPlansUpload',
      draft.requiredDocuments.civilStructuralPlansUpload,
      'Civil Structural Plans',
    );
    out.document(
      'requiredDocuments.electricalPlansUpload',
      draft.requiredDocuments.electricalPlansUpload,
      'Electrical Plans',
    );
    out.document(
      'requiredDocuments.mechanicalPlansUpload',
      draft.requiredDocuments.mechanicalPlansUpload,
      'Mechanical Plans',
    );
    out.document(
      'requiredDocuments.plumbingPlansUpload',
      draft.requiredDocuments.plumbingPlansUpload,
      'Plumbing Plans',
    );
    out.document(
      'requiredDocuments.sanitaryPlansUpload',
      draft.requiredDocuments.sanitaryPlansUpload,
      'Sanitary Plans',
    );
    out.document(
      'requiredDocuments.electronicsPlansUpload',
      draft.requiredDocuments.electronicsPlansUpload,
      'Electronics Plans',
    );
    out.document(
      'requiredDocuments.fireSafetyPlansUpload',
      draft.requiredDocuments.fireSafetyPlansUpload,
      'Fire Safety Plans',
    );
    out.document(
      'requiredDocuments.barangayClearanceUpload',
      draft.requiredDocuments.barangayClearanceUpload,
      'Barangay Clearance',
    );
    out.document(
      'requiredDocuments.zoningClearanceUpload',
      draft.requiredDocuments.zoningClearanceUpload,
      'Zoning Clearance',
    );
    out.document(
      'requiredDocuments.fireSafetyEvaluationUpload',
      draft.requiredDocuments.fireSafetyEvaluationUpload,
      'Fire Safety Evaluation',
    );
    out.document(
      'requiredDocuments.otherLguClearanceUpload',
      draft.requiredDocuments.otherLguClearanceUpload,
      'Other LGU Clearance',
    );
    out.scalar(
      'reviewDeclaration.certifiesTrueAndCorrect',
      draft.reviewDeclaration.certifiesTrueAndCorrect,
    );
    out.scalar(
      'reviewDeclaration.confirmsAdditionOrExtensionOfExistingBuilding',
      draft.reviewDeclaration.confirmsAdditionOrExtensionOfExistingBuilding,
    );
    out.scalar(
      'reviewDeclaration.understandsAncillaryPermitsMayBeRequired',
      draft.reviewDeclaration.understandsAncillaryPermitsMayBeRequired,
    );
    out.scalar(
      'reviewDeclaration.understandsPlansMustBeSignedAndSealed',
      draft.reviewDeclaration.understandsPlansMustBeSignedAndSealed,
    );
    out.scalar(
      'reviewDeclaration.confirmsAdditionAccuratelyRepresented',
      draft.reviewDeclaration.confirmsAdditionAccuratelyRepresented,
    );
    out.scalar(
      'reviewDeclaration.agreesToTerms',
      draft.reviewDeclaration.agreesToTerms,
    );
    out.enumValue(
      'assessmentPayment.selectedPaymentMethod',
      draft.assessmentPayment.selectedPaymentMethod,
    );
    out.scalar(
      'useApplicantAddressForProjectLocation',
      draft.useApplicantAddressForProjectLocation,
    );
    out.enumValue('status', draft.status);
    out.date('lastSavedAt', draft.lastSavedAt);
  }

  @override
  void restore(AdditionExtensionPermitDraft draft, SnapshotReader input) {
    draft.applicant.applicationType =
        input.enumValue(
          'applicant.applicationType',
          AdditionExtensionApplicationType.values,
        ) ??
        AdditionExtensionApplicationType.newApplication;
    draft.applicant.firstName = input.string('applicant.firstName');
    draft.applicant.middleName = input.string('applicant.middleName');
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
    draft.projectInformation.projectTitle = input.string(
      'projectInformation.projectTitle',
    );
    draft.projectInformation.generalDescription = input.string(
      'projectInformation.generalDescription',
    );
    draft.projectInformation.existingBuildingDescription = input.string(
      'projectInformation.existingBuildingDescription',
    );
    draft.projectInformation.purposeOfProposedAddition = input.string(
      'projectInformation.purposeOfProposedAddition',
    );
    draft.projectInformation.connectionToExistingBuilding = input.string(
      'projectInformation.connectionToExistingBuilding',
    );
    draft.projectInformation.otherProjectDetails = input.string(
      'projectInformation.otherProjectDetails',
    );
    draft.projectInformation.additionType = input.enumValue(
      'projectInformation.additionType',
      AdditionType.values,
    );
    draft.projectInformation.otherAdditionTypeDescription = input.string(
      'projectInformation.otherAdditionTypeDescription',
    );
    draft.projectInformation.affectedAreas = input.enumSet(
      'projectInformation.affectedAreas',
      AffectedBuildingArea.values,
    );
    draft.projectInformation.otherAffectedAreaDescription = input.string(
      'projectInformation.otherAffectedAreaDescription',
    );
    draft.buildingDetails.occupancyGroup = input.enumValue(
      'buildingDetails.occupancyGroup',
      AdditionExtensionOccupancyGroup.values,
    );
    draft.buildingDetails.occupancyOtherDescription = input.string(
      'buildingDetails.occupancyOtherDescription',
    );
    draft.buildingDetails.existingOccupancyClassification = input.string(
      'buildingDetails.existingOccupancyClassification',
    );
    draft.buildingDetails.existingNumberOfUnits = input.string(
      'buildingDetails.existingNumberOfUnits',
    );
    draft.buildingDetails.existingNumberOfStoreys = input.string(
      'buildingDetails.existingNumberOfStoreys',
    );
    draft.buildingDetails.existingFloorArea = input.string(
      'buildingDetails.existingFloorArea',
    );
    draft.buildingDetails.proposedAddedNumberOfUnits = input.string(
      'buildingDetails.proposedAddedNumberOfUnits',
    );
    draft.buildingDetails.proposedAdditionalStoreys = input.string(
      'buildingDetails.proposedAdditionalStoreys',
    );
    draft.buildingDetails.proposedAddedFloorArea = input.string(
      'buildingDetails.proposedAddedFloorArea',
    );
    draft.buildingDetails.lotArea = input.string('buildingDetails.lotArea');
    draft.buildingDetails.estimatedCost = input.string(
      'buildingDetails.estimatedCost',
    );
    draft.buildingDetails.proposedStartDate = input.date(
      'buildingDetails.proposedStartDate',
    );
    draft.buildingDetails.expectedCompletionDate = input.date(
      'buildingDetails.expectedCompletionDate',
    );
    draft.professional.fullName = input.string('professional.fullName');
    draft.professional.profession = input.enumValue(
      'professional.profession',
      AdditionExtensionProfessionType.values,
    );
    draft.professional.professionalAddress = input.string(
      'professional.professionalAddress',
    );
    draft.professional.prcNumber = input.string('professional.prcNumber');
    draft.professional.prcValidityDate = input.date(
      'professional.prcValidityDate',
    );
    draft.professional.ptrNumber = input.string('professional.ptrNumber');
    draft.professional.ptrDateIssued = input.date('professional.ptrDateIssued');
    draft.professional.ptrPlaceIssued = input.string(
      'professional.ptrPlaceIssued',
    );
    draft.professional.tin = input.string('professional.tin');
    draft.professional.dateSigned = input.date('professional.dateSigned');
    draft.consentAuthorization.isRegisteredOwner = input.nullableBoolean(
      'consentAuthorization.isRegisteredOwner',
    );
    draft.consentAuthorization.registeredOwnerFullName = input.string(
      'consentAuthorization.registeredOwnerFullName',
    );
    draft.consentAuthorization.representativeFullName = input.string(
      'consentAuthorization.representativeFullName',
    );
    draft.consentAuthorization.representativeAddress = input.string(
      'consentAuthorization.representativeAddress',
    );
    draft.consentAuthorization.ctcNumber = input.string(
      'consentAuthorization.ctcNumber',
    );
    draft.consentAuthorization.ctcDateIssued = input.date(
      'consentAuthorization.ctcDateIssued',
    );
    draft.consentAuthorization.ctcPlaceIssued = input.string(
      'consentAuthorization.ctcPlaceIssued',
    );
    draft.requiredDocuments.existingBuildingPermit.markedNotAvailable = input
        .boolean('requiredDocuments.existingBuildingPermit.markedNotAvailable');
    draft.requiredDocuments.existingCertificateOfOccupancy.markedNotAvailable =
        input.boolean(
          'requiredDocuments.existingCertificateOfOccupancy.markedNotAvailable',
        );
    draft.requiredDocuments.existingApprovedBuildingPlans.markedNotAvailable =
        input.boolean(
          'requiredDocuments.existingApprovedBuildingPlans.markedNotAvailable',
        );
    draft.requiredDocuments.recentPhotographs.markedNotAvailable = input
        .boolean('requiredDocuments.recentPhotographs.markedNotAvailable');
    draft.reviewDeclaration.certifiesTrueAndCorrect = input.boolean(
      'reviewDeclaration.certifiesTrueAndCorrect',
    );
    draft.reviewDeclaration.confirmsAdditionOrExtensionOfExistingBuilding =
        input.boolean(
          'reviewDeclaration.confirmsAdditionOrExtensionOfExistingBuilding',
        );
    draft.reviewDeclaration.understandsAncillaryPermitsMayBeRequired = input
        .boolean('reviewDeclaration.understandsAncillaryPermitsMayBeRequired');
    draft.reviewDeclaration.understandsPlansMustBeSignedAndSealed = input
        .boolean('reviewDeclaration.understandsPlansMustBeSignedAndSealed');
    draft.reviewDeclaration.confirmsAdditionAccuratelyRepresented = input
        .boolean('reviewDeclaration.confirmsAdditionAccuratelyRepresented');
    draft.reviewDeclaration.agreesToTerms = input.boolean(
      'reviewDeclaration.agreesToTerms',
    );
    draft.assessmentPayment.selectedPaymentMethod = input.enumValue(
      'assessmentPayment.selectedPaymentMethod',
      AdditionExtensionPaymentMethod.values,
    );
    draft.useApplicantAddressForProjectLocation = input.boolean(
      'useApplicantAddressForProjectLocation',
    );
    // Not read back: a restored draft is always a draft. Honouring a
    // stored `submitted` would resurrect a filed application as editable.
    draft.status = AdditionExtensionPermitDraftStatus.draft;
    draft.lastSavedAt = input.date('lastSavedAt');
  }
}
