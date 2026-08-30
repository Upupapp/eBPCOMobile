import '../models/renovation_permit_model.dart';
import 'draft_snapshot.dart';

/// Renovation — RenovationPermitDraft, persisted.
///
/// One of the seventeen wizards converted in M-48 part 2, after the mechanism
/// was proven on the Building Permit and Fencing. Every field the draft
/// declares is captured and read back except the 30 attachment slots,
/// which are dropped and named back to the applicant, and whatever
/// `test/architecture/draft_snapshot_completeness_test.dart` exempts with a
/// reason. That gate fails the day this file falls behind the model.
///
/// Written mechanically from the model's own field declarations and then
/// reviewed, which is why it reads uniformly. The alternative — trusting a
/// generator without a gate — is how 98 fields become 98 chances to
/// drop one silently.
class RenovationPermitDraftCodec extends DraftCodec<RenovationPermitDraft> {
  const RenovationPermitDraftCodec();

  @override
  String get permitKey => 'renovation-permit';

  @override
  String get permitLabel => 'Renovation';

  @override
  void capture(RenovationPermitDraft draft, SnapshotWriter out) {
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
    out.scalar(
      'renovationLocation.lotNumber',
      draft.renovationLocation.lotNumber,
    );
    out.scalar(
      'renovationLocation.blockNumber',
      draft.renovationLocation.blockNumber,
    );
    out.scalar(
      'renovationLocation.tctNumber',
      draft.renovationLocation.tctNumber,
    );
    out.scalar(
      'renovationLocation.taxDeclarationNumber',
      draft.renovationLocation.taxDeclarationNumber,
    );
    out.scalar('renovationLocation.street', draft.renovationLocation.street);
    out.scalar(
      'renovationLocation.barangay',
      draft.renovationLocation.barangay,
    );
    out.scalar('renovationLocation.city', draft.renovationLocation.city);
    out.scalar(
      'renovationLocation.province',
      draft.renovationLocation.province,
    );
    out.scalar(
      'projectInformation.projectTitle',
      draft.projectInformation.projectTitle,
    );
    out.scalar(
      'projectInformation.generalDescription',
      draft.projectInformation.generalDescription,
    );
    out.enumSet(
      'projectInformation.affectedAreas',
      draft.projectInformation.affectedAreas,
    );
    out.scalar(
      'projectInformation.otherAffectedAreaDescription',
      draft.projectInformation.otherAffectedAreaDescription,
    );
    out.scalar(
      'projectInformation.otherRenovationDetails',
      draft.projectInformation.otherRenovationDetails,
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
      'buildingDetails.occupancyClassification',
      draft.buildingDetails.occupancyClassification,
    );
    out.scalar(
      'buildingDetails.numberOfUnits',
      draft.buildingDetails.numberOfUnits,
    );
    out.scalar(
      'buildingDetails.totalExistingFloorArea',
      draft.buildingDetails.totalExistingFloorArea,
    );
    out.scalar(
      'buildingDetails.areaAffectedByRenovation',
      draft.buildingDetails.areaAffectedByRenovation,
    );
    out.scalar('buildingDetails.lotArea', draft.buildingDetails.lotArea);
    out.scalar(
      'buildingDetails.estimatedRenovationCost',
      draft.buildingDetails.estimatedRenovationCost,
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
      'requiredDocuments.renovationPlansUpload',
      draft.requiredDocuments.renovationPlansUpload,
      'Renovation Plans',
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
      'reviewDeclaration.confirmsRenovationOfExistingStructure',
      draft.reviewDeclaration.confirmsRenovationOfExistingStructure,
    );
    out.scalar(
      'reviewDeclaration.understandsAdditionalPermitsMayBeRequired',
      draft.reviewDeclaration.understandsAdditionalPermitsMayBeRequired,
    );
    out.scalar(
      'reviewDeclaration.understandsPlansMustBeSignedAndSealed',
      draft.reviewDeclaration.understandsPlansMustBeSignedAndSealed,
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
      'useApplicantAddressForRenovationLocation',
      draft.useApplicantAddressForRenovationLocation,
    );
    out.enumValue('status', draft.status);
    out.date('lastSavedAt', draft.lastSavedAt);
  }

  @override
  void restore(RenovationPermitDraft draft, SnapshotReader input) {
    draft.applicant.applicationType =
        input.enumValue(
          'applicant.applicationType',
          RenovationApplicationType.values,
        ) ??
        RenovationApplicationType.newApplication;
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
    draft.renovationLocation.lotNumber = input.string(
      'renovationLocation.lotNumber',
    );
    draft.renovationLocation.blockNumber = input.string(
      'renovationLocation.blockNumber',
    );
    draft.renovationLocation.tctNumber = input.string(
      'renovationLocation.tctNumber',
    );
    draft.renovationLocation.taxDeclarationNumber = input.string(
      'renovationLocation.taxDeclarationNumber',
    );
    draft.renovationLocation.street = input.string('renovationLocation.street');
    draft.renovationLocation.barangay = input.string(
      'renovationLocation.barangay',
    );
    draft.renovationLocation.city = input.string('renovationLocation.city');
    draft.renovationLocation.province = input.string(
      'renovationLocation.province',
    );
    draft.projectInformation.projectTitle = input.string(
      'projectInformation.projectTitle',
    );
    draft.projectInformation.generalDescription = input.string(
      'projectInformation.generalDescription',
    );
    draft.projectInformation.affectedAreas = input.enumSet(
      'projectInformation.affectedAreas',
      RenovationAffectedArea.values,
    );
    draft.projectInformation.otherAffectedAreaDescription = input.string(
      'projectInformation.otherAffectedAreaDescription',
    );
    draft.projectInformation.otherRenovationDetails = input.string(
      'projectInformation.otherRenovationDetails',
    );
    draft.buildingDetails.occupancyGroup = input.enumValue(
      'buildingDetails.occupancyGroup',
      RenovationOccupancyGroup.values,
    );
    draft.buildingDetails.occupancyOtherDescription = input.string(
      'buildingDetails.occupancyOtherDescription',
    );
    draft.buildingDetails.occupancyClassification = input.string(
      'buildingDetails.occupancyClassification',
    );
    draft.buildingDetails.numberOfUnits = input.string(
      'buildingDetails.numberOfUnits',
    );
    draft.buildingDetails.totalExistingFloorArea = input.string(
      'buildingDetails.totalExistingFloorArea',
    );
    draft.buildingDetails.areaAffectedByRenovation = input.string(
      'buildingDetails.areaAffectedByRenovation',
    );
    draft.buildingDetails.lotArea = input.string('buildingDetails.lotArea');
    draft.buildingDetails.estimatedRenovationCost = input.string(
      'buildingDetails.estimatedRenovationCost',
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
      RenovationProfessionType.values,
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
    draft.professional.prcIdUpload = input.document('professional.prcIdUpload');
    draft.professional.ptrDocumentUpload = input.document(
      'professional.ptrDocumentUpload',
    );
    draft.professional.signedSealedFormUpload = input.document(
      'professional.signedSealedFormUpload',
    );
    draft.professional.signedSealedPlansUpload = input.document(
      'professional.signedSealedPlansUpload',
    );
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
    draft.consentAuthorization.authorizationLetterUpload = input.document(
      'consentAuthorization.authorizationLetterUpload',
    );
    draft.consentAuthorization.ownerValidIdUpload = input.document(
      'consentAuthorization.ownerValidIdUpload',
    );
    draft.consentAuthorization.representativeValidIdUpload = input.document(
      'consentAuthorization.representativeValidIdUpload',
    );
    draft.consentAuthorization.proofOfOwnershipUpload = input.document(
      'consentAuthorization.proofOfOwnershipUpload',
    );
    draft.requiredDocuments.landTitleUpload = input.document(
      'requiredDocuments.landTitleUpload',
    );
    draft.requiredDocuments.taxDeclarationUpload = input.document(
      'requiredDocuments.taxDeclarationUpload',
    );
    draft.requiredDocuments.realPropertyTaxReceiptUpload = input.document(
      'requiredDocuments.realPropertyTaxReceiptUpload',
    );
    draft.requiredDocuments.proofOfOwnershipOrAuthorityUpload = input.document(
      'requiredDocuments.proofOfOwnershipOrAuthorityUpload',
    );
    draft.requiredDocuments.existingBuildingPermit.upload = input.document(
      'requiredDocuments.existingBuildingPermit.upload',
    );
    draft.requiredDocuments.existingBuildingPermit.markedNotAvailable = input
        .boolean('requiredDocuments.existingBuildingPermit.markedNotAvailable');
    draft.requiredDocuments.existingCertificateOfOccupancy.upload = input
        .document('requiredDocuments.existingCertificateOfOccupancy.upload');
    draft.requiredDocuments.existingCertificateOfOccupancy.markedNotAvailable =
        input.boolean(
          'requiredDocuments.existingCertificateOfOccupancy.markedNotAvailable',
        );
    draft.requiredDocuments.existingApprovedBuildingPlans.upload = input
        .document('requiredDocuments.existingApprovedBuildingPlans.upload');
    draft.requiredDocuments.existingApprovedBuildingPlans.markedNotAvailable =
        input.boolean(
          'requiredDocuments.existingApprovedBuildingPlans.markedNotAvailable',
        );
    draft.requiredDocuments.recentPhotographs.upload = input.document(
      'requiredDocuments.recentPhotographs.upload',
    );
    draft.requiredDocuments.recentPhotographs.markedNotAvailable = input
        .boolean('requiredDocuments.recentPhotographs.markedNotAvailable');
    draft.requiredDocuments.renovationPlansUpload = input.document(
      'requiredDocuments.renovationPlansUpload',
    );
    draft.requiredDocuments.architecturalPlansUpload = input.document(
      'requiredDocuments.architecturalPlansUpload',
    );
    draft.requiredDocuments.technicalSpecificationsUpload = input.document(
      'requiredDocuments.technicalSpecificationsUpload',
    );
    draft.requiredDocuments.billOfMaterialsUpload = input.document(
      'requiredDocuments.billOfMaterialsUpload',
    );
    draft.requiredDocuments.civilStructuralPlansUpload = input.document(
      'requiredDocuments.civilStructuralPlansUpload',
    );
    draft.requiredDocuments.electricalPlansUpload = input.document(
      'requiredDocuments.electricalPlansUpload',
    );
    draft.requiredDocuments.mechanicalPlansUpload = input.document(
      'requiredDocuments.mechanicalPlansUpload',
    );
    draft.requiredDocuments.plumbingPlansUpload = input.document(
      'requiredDocuments.plumbingPlansUpload',
    );
    draft.requiredDocuments.sanitaryPlansUpload = input.document(
      'requiredDocuments.sanitaryPlansUpload',
    );
    draft.requiredDocuments.electronicsPlansUpload = input.document(
      'requiredDocuments.electronicsPlansUpload',
    );
    draft.requiredDocuments.barangayClearanceUpload = input.document(
      'requiredDocuments.barangayClearanceUpload',
    );
    draft.requiredDocuments.zoningClearanceUpload = input.document(
      'requiredDocuments.zoningClearanceUpload',
    );
    draft.requiredDocuments.fireSafetyEvaluationUpload = input.document(
      'requiredDocuments.fireSafetyEvaluationUpload',
    );
    draft.requiredDocuments.otherLguClearanceUpload = input.document(
      'requiredDocuments.otherLguClearanceUpload',
    );
    draft.reviewDeclaration.certifiesTrueAndCorrect = input.boolean(
      'reviewDeclaration.certifiesTrueAndCorrect',
    );
    draft.reviewDeclaration.confirmsRenovationOfExistingStructure = input
        .boolean('reviewDeclaration.confirmsRenovationOfExistingStructure');
    draft.reviewDeclaration.understandsAdditionalPermitsMayBeRequired = input
        .boolean('reviewDeclaration.understandsAdditionalPermitsMayBeRequired');
    draft.reviewDeclaration.understandsPlansMustBeSignedAndSealed = input
        .boolean('reviewDeclaration.understandsPlansMustBeSignedAndSealed');
    draft.reviewDeclaration.agreesToTerms = input.boolean(
      'reviewDeclaration.agreesToTerms',
    );
    draft.assessmentPayment.selectedPaymentMethod = input.enumValue(
      'assessmentPayment.selectedPaymentMethod',
      RenovationPaymentMethod.values,
    );
    draft.useApplicantAddressForRenovationLocation = input.boolean(
      'useApplicantAddressForRenovationLocation',
    );
    // Not read back: a restored draft is always a draft. Honouring a
    // stored `submitted` would resurrect a filed application as editable.
    draft.status = RenovationPermitDraftStatus.draft;
    draft.lastSavedAt = input.date('lastSavedAt');
  }
}
