import '../models/demolition_permit_model.dart';
import 'draft_snapshot.dart';

/// Demolition — DemolitionPermitDraft, persisted.
///
/// One of the seventeen wizards converted in M-48 part 2, after the mechanism
/// was proven on the Building Permit and Fencing. Every field the draft
/// declares is captured and read back except the 33 attachment slots,
/// which are dropped and named back to the applicant, and whatever
/// `test/architecture/draft_snapshot_completeness_test.dart` exempts with a
/// reason. That gate fails the day this file falls behind the model.
///
/// Written mechanically from the model's own field declarations and then
/// reviewed, which is why it reads uniformly. The alternative — trusting a
/// generator without a gate — is how 131 fields become 131 chances to
/// drop one silently.
class DemolitionPermitDraftCodec extends DraftCodec<DemolitionPermitDraft> {
  const DemolitionPermitDraftCodec();

  @override
  String get permitKey => 'demolition-permit';

  @override
  String get permitLabel => 'Demolition';

  @override
  void capture(DemolitionPermitDraft draft, SnapshotWriter out) {
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
    out.scalar(
      'demolitionLocation.lotNumber',
      draft.demolitionLocation.lotNumber,
    );
    out.scalar(
      'demolitionLocation.blockNumber',
      draft.demolitionLocation.blockNumber,
    );
    out.scalar(
      'demolitionLocation.tctNumber',
      draft.demolitionLocation.tctNumber,
    );
    out.scalar(
      'demolitionLocation.taxDeclarationNumber',
      draft.demolitionLocation.taxDeclarationNumber,
    );
    out.scalar('demolitionLocation.street', draft.demolitionLocation.street);
    out.scalar(
      'demolitionLocation.barangay',
      draft.demolitionLocation.barangay,
    );
    out.scalar('demolitionLocation.city', draft.demolitionLocation.city);
    out.scalar(
      'demolitionLocation.province',
      draft.demolitionLocation.province,
    );
    out.scalar(
      'existingPermitReferences.existingBuildingPermitNumber',
      draft.existingPermitReferences.existingBuildingPermitNumber,
    );
    out.scalar(
      'existingPermitReferences.previousDemolitionPermitNumber',
      draft.existingPermitReferences.previousDemolitionPermitNumber,
    );
    out.enumValue(
      'structureDetails.demolitionExtent',
      draft.structureDetails.demolitionExtent,
    );
    out.scalar(
      'structureDetails.otherExtentDescription',
      draft.structureDetails.otherExtentDescription,
    );
    out.scalar(
      'structureDetails.structureName',
      draft.structureDetails.structureName,
    );
    out.scalar(
      'structureDetails.descriptionOfExistingStructure',
      draft.structureDetails.descriptionOfExistingStructure,
    );
    out.scalar(
      'structureDetails.existingUseOrOccupancy',
      draft.structureDetails.existingUseOrOccupancy,
    );
    out.scalar(
      'structureDetails.numberOfStoreys',
      draft.structureDetails.numberOfStoreys,
    );
    out.scalar(
      'structureDetails.numberOfUnits',
      draft.structureDetails.numberOfUnits,
    );
    out.scalar(
      'structureDetails.approximateFloorArea',
      draft.structureDetails.approximateFloorArea,
    );
    out.scalar(
      'structureDetails.approximateBuildingHeight',
      draft.structureDetails.approximateBuildingHeight,
    );
    out.enumValue(
      'structureDetails.primaryConstructionMaterial',
      draft.structureDetails.primaryConstructionMaterial,
    );
    out.scalar(
      'structureDetails.otherMaterialDescription',
      draft.structureDetails.otherMaterialDescription,
    );
    out.scalar(
      'structureDetails.estimatedAgeOfStructure',
      draft.structureDetails.estimatedAgeOfStructure,
    );
    out.scalar(
      'structureDetails.portionToBeDemolished',
      draft.structureDetails.portionToBeDemolished,
    );
    out.scalar(
      'structureDetails.reasonForDemolition',
      draft.structureDetails.reasonForDemolition,
    );
    out.scalar(
      'structureDetails.proposedDemolitionMethod',
      draft.structureDetails.proposedDemolitionMethod,
    );
    out.scalar(
      'structureDetails.estimatedDemolitionCost',
      draft.structureDetails.estimatedDemolitionCost,
    );
    out.date(
      'structureDetails.proposedStartDate',
      draft.structureDetails.proposedStartDate,
    );
    out.date(
      'structureDetails.expectedCompletionDate',
      draft.structureDetails.expectedCompletionDate,
    );
    out.scalar(
      'safetyAndSitePrep.isBuildingOccupied',
      draft.safetyAndSitePrep.isBuildingOccupied,
    );
    out.date(
      'safetyAndSitePrep.plannedVacationDate',
      draft.safetyAndSitePrep.plannedVacationDate,
    );
    out.scalar(
      'safetyAndSitePrep.occupantRelocationPlan',
      draft.safetyAndSitePrep.occupantRelocationPlan,
    );
    out.scalar(
      'safetyAndSitePrep.personResponsibleForClearing',
      draft.safetyAndSitePrep.personResponsibleForClearing,
    );
    // One record per utility, each with its own disconnection proof. The
    // proof is dropped like every other attachment and named back with the
    // utility it belonged to, or the applicant would be told to re-attach
    // "supporting document" five times over.
    out.rows('safetyAndSitePrep.utilities', [
      for (final entry in draft.safetyAndSitePrep.utilities.entries)
        out.row()
          ..enumValue('utility', entry.key)
          ..enumValue('status', entry.value.status)
          ..scalar('provider', entry.value.provider)
          ..date('disconnectionDate', entry.value.disconnectionDate)
          ..scalar('referenceNumber', entry.value.referenceNumber)
          ..document(
            'supportingDocument',
            entry.value.supportingDocument,
            'Disconnection proof: ${entry.key.label}',
          ),
    ]);
    out.enumSet(
      'safetyAndSitePrep.confirmedSafetyItems',
      draft.safetyAndSitePrep.confirmedSafetyItems,
    );
    out.scalar(
      'safetyAndSitePrep.distanceToNearestStructure',
      draft.safetyAndSitePrep.distanceToNearestStructure,
    );
    out.scalar(
      'safetyAndSitePrep.isPublicSidewalkAffected',
      draft.safetyAndSitePrep.isPublicSidewalkAffected,
    );
    out.scalar(
      'safetyAndSitePrep.sidewalkMitigation',
      draft.safetyAndSitePrep.sidewalkMitigation,
    );
    out.scalar(
      'safetyAndSitePrep.isPublicRoadAffected',
      draft.safetyAndSitePrep.isPublicRoadAffected,
    );
    out.scalar(
      'safetyAndSitePrep.roadMitigation',
      draft.safetyAndSitePrep.roadMitigation,
    );
    out.scalar(
      'safetyAndSitePrep.areNeighboringPropertiesAtRisk',
      draft.safetyAndSitePrep.areNeighboringPropertiesAtRisk,
    );
    out.scalar(
      'safetyAndSitePrep.neighboringPropertiesMitigation',
      draft.safetyAndSitePrep.neighboringPropertiesMitigation,
    );
    out.scalar(
      'safetyAndSitePrep.debrisDisposalLocation',
      draft.safetyAndSitePrep.debrisDisposalLocation,
    );
    out.scalar(
      'safetyAndSitePrep.siteSecurityMethod',
      draft.safetyAndSitePrep.siteSecurityMethod,
    );
    out.scalar(
      'safetyAndSitePrep.dustControlMethod',
      draft.safetyAndSitePrep.dustControlMethod,
    );
    out.scalar(
      'safetyAndSitePrep.noiseControlMethod',
      draft.safetyAndSitePrep.noiseControlMethod,
    );
    out.scalar('professional.fullName', draft.professional.fullName);
    out.enumValue('professional.profession', draft.professional.profession);
    out.scalar(
      'professional.professionalAddress',
      draft.professional.professionalAddress,
    );
    out.scalar('professional.contactNumber', draft.professional.contactNumber);
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
      'professional.demolitionPlanUpload',
      draft.professional.demolitionPlanUpload,
      'Demolition Plan',
    );
    out.document(
      'professional.demolitionMethodologyUpload',
      draft.professional.demolitionMethodologyUpload,
      'Demolition Methodology',
    );
    out.document(
      'professional.safetyProgramUpload',
      draft.professional.safetyProgramUpload,
      'Safety Program',
    );
    out.document(
      'professional.structuralAssessmentUpload',
      draft.professional.structuralAssessmentUpload,
      'Structural Assessment',
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
      'consentAuthorization.lotOwnerConsentUpload',
      draft.consentAuthorization.lotOwnerConsentUpload,
      'Lot Owner Consent',
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
      'requiredDocuments.existingBuildingPermit.upload',
      draft.requiredDocuments.existingBuildingPermit.upload,
      'Upload',
    );
    out.scalar(
      'requiredDocuments.existingBuildingPermit.markedNotAvailable',
      draft.requiredDocuments.existingBuildingPermit.markedNotAvailable,
    );
    out.scalar(
      'requiredDocuments.existingBuildingPermit.notAvailableExplanation',
      draft.requiredDocuments.existingBuildingPermit.notAvailableExplanation,
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
    out.scalar(
      'requiredDocuments.existingCertificateOfOccupancy.notAvailableExplanation',
      draft
          .requiredDocuments
          .existingCertificateOfOccupancy
          .notAvailableExplanation,
    );
    out.document(
      'requiredDocuments.approvedOrAsBuiltPlansUpload',
      draft.requiredDocuments.approvedOrAsBuiltPlansUpload,
      'Approved or as Built Plans',
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
    out.scalar(
      'requiredDocuments.recentPhotographs.notAvailableExplanation',
      draft.requiredDocuments.recentPhotographs.notAvailableExplanation,
    );
    out.document(
      'requiredDocuments.proofOfOwnershipOrAuthorityUpload',
      draft.requiredDocuments.proofOfOwnershipOrAuthorityUpload,
      'Proof of Ownership or Authority',
    );
    out.document(
      'requiredDocuments.debrisManagementPlanUpload',
      draft.requiredDocuments.debrisManagementPlanUpload,
      'Debris Management Plan',
    );
    out.document(
      'requiredDocuments.dustNoiseControlPlanUpload',
      draft.requiredDocuments.dustNoiseControlPlanUpload,
      'Dust Noise Control Plan',
    );
    out.document(
      'requiredDocuments.projectScheduleUpload',
      draft.requiredDocuments.projectScheduleUpload,
      'Project Schedule',
    );
    out.document(
      'requiredDocuments.costEstimateUpload',
      draft.requiredDocuments.costEstimateUpload,
      'Cost Estimate',
    );
    out.document(
      'requiredDocuments.shoringPlanUpload',
      draft.requiredDocuments.shoringPlanUpload,
      'Shoring Plan',
    );
    out.document(
      'requiredDocuments.adjacentPropertyProtectionPlanUpload',
      draft.requiredDocuments.adjacentPropertyProtectionPlanUpload,
      'Adjacent Property Protection Plan',
    );
    out.document(
      'requiredDocuments.trafficOrPedestrianManagementPlanUpload',
      draft.requiredDocuments.trafficOrPedestrianManagementPlanUpload,
      'Traffic or Pedestrian Management Plan',
    );
    out.document(
      'requiredDocuments.barangayClearanceUpload',
      draft.requiredDocuments.barangayClearanceUpload,
      'Barangay Clearance',
    );
    out.document(
      'requiredDocuments.oboRequirementsUpload',
      draft.requiredDocuments.oboRequirementsUpload,
      'OBO Requirements',
    );
    out.document(
      'requiredDocuments.environmentalClearanceUpload',
      draft.requiredDocuments.environmentalClearanceUpload,
      'Environmental Clearance',
    );
    out.document(
      'requiredDocuments.roadSidewalkUseClearanceUpload',
      draft.requiredDocuments.roadSidewalkUseClearanceUpload,
      'Road Sidewalk Use Clearance',
    );
    out.document(
      'requiredDocuments.fireClearanceUpload',
      draft.requiredDocuments.fireClearanceUpload,
      'Fire Clearance',
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
      'reviewDeclaration.confirmsStructureWillBeVacated',
      draft.reviewDeclaration.confirmsStructureWillBeVacated,
    );
    out.scalar(
      'reviewDeclaration.confirmsUtilitiesWillBeDisconnectedOrControlled',
      draft.reviewDeclaration.confirmsUtilitiesWillBeDisconnectedOrControlled,
    );
    out.scalar(
      'reviewDeclaration.understandsSupervisionRequired',
      draft.reviewDeclaration.understandsSupervisionRequired,
    );
    out.scalar(
      'reviewDeclaration.agreesToSafetyMeasures',
      draft.reviewDeclaration.agreesToSafetyMeasures,
    );
    out.scalar(
      'reviewDeclaration.understandsAdvanceNoticeRequired',
      draft.reviewDeclaration.understandsAdvanceNoticeRequired,
    );
    out.scalar(
      'reviewDeclaration.understandsPermitMustBeIssuedFirst',
      draft.reviewDeclaration.understandsPermitMustBeIssuedFirst,
    );
    out.scalar(
      'reviewDeclaration.agreesToTerms',
      draft.reviewDeclaration.agreesToTerms,
    );
    out.enumValue(
      'evaluationPermitStatus.selectedPaymentMethod',
      draft.evaluationPermitStatus.selectedPaymentMethod,
    );
    out.scalar(
      'useApplicantAddressForDemolitionLocation',
      draft.useApplicantAddressForDemolitionLocation,
    );
    out.enumValue('status', draft.status);
    out.date('lastSavedAt', draft.lastSavedAt);
  }

  @override
  void restore(DemolitionPermitDraft draft, SnapshotReader input) {
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
    draft.applicant.occupancyGroup = input.enumValue(
      'applicant.occupancyGroup',
      DemolitionOccupancyGroup.values,
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
    draft.demolitionLocation.lotNumber = input.string(
      'demolitionLocation.lotNumber',
    );
    draft.demolitionLocation.blockNumber = input.string(
      'demolitionLocation.blockNumber',
    );
    draft.demolitionLocation.tctNumber = input.string(
      'demolitionLocation.tctNumber',
    );
    draft.demolitionLocation.taxDeclarationNumber = input.string(
      'demolitionLocation.taxDeclarationNumber',
    );
    draft.demolitionLocation.street = input.string('demolitionLocation.street');
    draft.demolitionLocation.barangay = input.string(
      'demolitionLocation.barangay',
    );
    draft.demolitionLocation.city = input.string('demolitionLocation.city');
    draft.demolitionLocation.province = input.string(
      'demolitionLocation.province',
    );
    draft.existingPermitReferences.existingBuildingPermitNumber = input.string(
      'existingPermitReferences.existingBuildingPermitNumber',
    );
    draft.existingPermitReferences.previousDemolitionPermitNumber = input
        .string('existingPermitReferences.previousDemolitionPermitNumber');
    draft.structureDetails.demolitionExtent = input.enumValue(
      'structureDetails.demolitionExtent',
      DemolitionExtent.values,
    );
    draft.structureDetails.otherExtentDescription = input.string(
      'structureDetails.otherExtentDescription',
    );
    draft.structureDetails.structureName = input.string(
      'structureDetails.structureName',
    );
    draft.structureDetails.descriptionOfExistingStructure = input.string(
      'structureDetails.descriptionOfExistingStructure',
    );
    draft.structureDetails.existingUseOrOccupancy = input.string(
      'structureDetails.existingUseOrOccupancy',
    );
    draft.structureDetails.numberOfStoreys = input.string(
      'structureDetails.numberOfStoreys',
    );
    draft.structureDetails.numberOfUnits = input.string(
      'structureDetails.numberOfUnits',
    );
    draft.structureDetails.approximateFloorArea = input.string(
      'structureDetails.approximateFloorArea',
    );
    draft.structureDetails.approximateBuildingHeight = input.string(
      'structureDetails.approximateBuildingHeight',
    );
    draft.structureDetails.primaryConstructionMaterial = input.enumValue(
      'structureDetails.primaryConstructionMaterial',
      ConstructionMaterial.values,
    );
    draft.structureDetails.otherMaterialDescription = input.string(
      'structureDetails.otherMaterialDescription',
    );
    draft.structureDetails.estimatedAgeOfStructure = input.string(
      'structureDetails.estimatedAgeOfStructure',
    );
    draft.structureDetails.portionToBeDemolished = input.string(
      'structureDetails.portionToBeDemolished',
    );
    draft.structureDetails.reasonForDemolition = input.string(
      'structureDetails.reasonForDemolition',
    );
    draft.structureDetails.proposedDemolitionMethod = input.string(
      'structureDetails.proposedDemolitionMethod',
    );
    draft.structureDetails.estimatedDemolitionCost = input.string(
      'structureDetails.estimatedDemolitionCost',
    );
    draft.structureDetails.proposedStartDate = input.date(
      'structureDetails.proposedStartDate',
    );
    draft.structureDetails.expectedCompletionDate = input.date(
      'structureDetails.expectedCompletionDate',
    );
    draft.safetyAndSitePrep.isBuildingOccupied = input.nullableBoolean(
      'safetyAndSitePrep.isBuildingOccupied',
    );
    draft.safetyAndSitePrep.plannedVacationDate = input.date(
      'safetyAndSitePrep.plannedVacationDate',
    );
    draft.safetyAndSitePrep.occupantRelocationPlan = input.string(
      'safetyAndSitePrep.occupantRelocationPlan',
    );
    draft.safetyAndSitePrep.personResponsibleForClearing = input.string(
      'safetyAndSitePrep.personResponsibleForClearing',
    );
    for (final row in input.rows('safetyAndSitePrep.utilities')) {
      final utility = row.enumValue('utility', UtilityType.values);
      final info = utility == null
          ? null
          : draft.safetyAndSitePrep.utilities[utility];
      if (info == null) continue;
      info.status =
          row.enumValue('status', UtilityDisconnectionStatus.values) ??
          UtilityDisconnectionStatus.notApplicable;
      info.provider = row.string('provider');
      info.disconnectionDate = row.date('disconnectionDate');
      info.referenceNumber = row.string('referenceNumber');
    }
    draft.safetyAndSitePrep.confirmedSafetyItems
      ..clear()
      ..addAll(
        input.enumSet(
          'safetyAndSitePrep.confirmedSafetyItems',
          SafetyConfirmationItem.values,
        ),
      );
    draft.safetyAndSitePrep.distanceToNearestStructure = input.string(
      'safetyAndSitePrep.distanceToNearestStructure',
    );
    draft.safetyAndSitePrep.isPublicSidewalkAffected = input.nullableBoolean(
      'safetyAndSitePrep.isPublicSidewalkAffected',
    );
    draft.safetyAndSitePrep.sidewalkMitigation = input.string(
      'safetyAndSitePrep.sidewalkMitigation',
    );
    draft.safetyAndSitePrep.isPublicRoadAffected = input.nullableBoolean(
      'safetyAndSitePrep.isPublicRoadAffected',
    );
    draft.safetyAndSitePrep.roadMitigation = input.string(
      'safetyAndSitePrep.roadMitigation',
    );
    draft.safetyAndSitePrep.areNeighboringPropertiesAtRisk = input
        .nullableBoolean('safetyAndSitePrep.areNeighboringPropertiesAtRisk');
    draft.safetyAndSitePrep.neighboringPropertiesMitigation = input.string(
      'safetyAndSitePrep.neighboringPropertiesMitigation',
    );
    draft.safetyAndSitePrep.debrisDisposalLocation = input.string(
      'safetyAndSitePrep.debrisDisposalLocation',
    );
    draft.safetyAndSitePrep.siteSecurityMethod = input.string(
      'safetyAndSitePrep.siteSecurityMethod',
    );
    draft.safetyAndSitePrep.dustControlMethod = input.string(
      'safetyAndSitePrep.dustControlMethod',
    );
    draft.safetyAndSitePrep.noiseControlMethod = input.string(
      'safetyAndSitePrep.noiseControlMethod',
    );
    draft.professional.fullName = input.string('professional.fullName');
    draft.professional.profession = input.enumValue(
      'professional.profession',
      DemolitionProfessionType.values,
    );
    draft.professional.professionalAddress = input.string(
      'professional.professionalAddress',
    );
    draft.professional.contactNumber = input.string(
      'professional.contactNumber',
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
    draft.requiredDocuments.existingBuildingPermit.notAvailableExplanation =
        input.string(
          'requiredDocuments.existingBuildingPermit.notAvailableExplanation',
        );
    draft.requiredDocuments.existingCertificateOfOccupancy.markedNotAvailable =
        input.boolean(
          'requiredDocuments.existingCertificateOfOccupancy.markedNotAvailable',
        );
    draft
        .requiredDocuments
        .existingCertificateOfOccupancy
        .notAvailableExplanation = input.string(
      'requiredDocuments.existingCertificateOfOccupancy.notAvailableExplanation',
    );
    draft.requiredDocuments.recentPhotographs.markedNotAvailable = input
        .boolean('requiredDocuments.recentPhotographs.markedNotAvailable');
    draft.requiredDocuments.recentPhotographs.notAvailableExplanation = input
        .string('requiredDocuments.recentPhotographs.notAvailableExplanation');
    draft.reviewDeclaration.certifiesTrueAndCorrect = input.boolean(
      'reviewDeclaration.certifiesTrueAndCorrect',
    );
    draft.reviewDeclaration.confirmsStructureWillBeVacated = input.boolean(
      'reviewDeclaration.confirmsStructureWillBeVacated',
    );
    draft.reviewDeclaration.confirmsUtilitiesWillBeDisconnectedOrControlled =
        input.boolean(
          'reviewDeclaration.confirmsUtilitiesWillBeDisconnectedOrControlled',
        );
    draft.reviewDeclaration.understandsSupervisionRequired = input.boolean(
      'reviewDeclaration.understandsSupervisionRequired',
    );
    draft.reviewDeclaration.agreesToSafetyMeasures = input.boolean(
      'reviewDeclaration.agreesToSafetyMeasures',
    );
    draft.reviewDeclaration.understandsAdvanceNoticeRequired = input.boolean(
      'reviewDeclaration.understandsAdvanceNoticeRequired',
    );
    draft.reviewDeclaration.understandsPermitMustBeIssuedFirst = input.boolean(
      'reviewDeclaration.understandsPermitMustBeIssuedFirst',
    );
    draft.reviewDeclaration.agreesToTerms = input.boolean(
      'reviewDeclaration.agreesToTerms',
    );
    draft.evaluationPermitStatus.selectedPaymentMethod = input.enumValue(
      'evaluationPermitStatus.selectedPaymentMethod',
      DemolitionPaymentMethod.values,
    );
    draft.useApplicantAddressForDemolitionLocation = input.boolean(
      'useApplicantAddressForDemolitionLocation',
    );
    // Not read back: a restored draft is always a draft. Honouring a
    // stored `submitted` would resurrect a filed application as editable.
    draft.status = DemolitionPermitDraftStatus.draft;
    draft.lastSavedAt = input.date('lastSavedAt');
  }
}
