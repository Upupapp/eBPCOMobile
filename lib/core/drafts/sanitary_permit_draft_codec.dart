import '../models/sanitary_plumbing_permit_model.dart';
import 'draft_snapshot.dart';

/// Sanitary / Plumbing — SanitaryPermitDraft, persisted.
///
/// One of the seventeen wizards converted in M-48 part 2, after the mechanism
/// was proven on the Building Permit and Fencing. Every field the draft
/// declares is captured and read back except the 64 attachment slots,
/// which are dropped and named back to the applicant, and whatever
/// `test/architecture/draft_snapshot_completeness_test.dart` exempts with a
/// reason. That gate fails the day this file falls behind the model.
///
/// Written mechanically from the model's own field declarations and then
/// reviewed, which is why it reads uniformly. The alternative — trusting a
/// generator without a gate — is how 180 fields become 180 chances to
/// drop one silently.
class SanitaryPermitDraftCodec extends DraftCodec<SanitaryPermitDraft> {
  const SanitaryPermitDraftCodec();

  @override
  String get permitKey => 'sanitary-plumbing-permit';

  @override
  String get permitLabel => 'Sanitary / Plumbing';

  @override
  void capture(SanitaryPermitDraft draft, SnapshotWriter out) {
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
      'relatedBuildingPermit.buildingPermitNumber',
      draft.relatedBuildingPermit.buildingPermitNumber,
    );
    out.enumValue(
      'relatedBuildingPermit.status',
      draft.relatedBuildingPermit.status,
    );
    out.enumSet(
      'scopeOccupancy.selectedScopes',
      draft.scopeOccupancy.selectedScopes,
    );
    out.scalar(
      'scopeOccupancy.otherScopeDescription',
      draft.scopeOccupancy.otherScopeDescription,
    );
    out.scalar('scopeOccupancy.workTitle', draft.scopeOccupancy.workTitle);
    out.scalar(
      'scopeOccupancy.generalDescription',
      draft.scopeOccupancy.generalDescription,
    );
    out.scalar(
      'scopeOccupancy.existingSystemCondition',
      draft.scopeOccupancy.existingSystemCondition,
    );
    out.scalar(
      'scopeOccupancy.proposedChanges',
      draft.scopeOccupancy.proposedChanges,
    );
    out.scalar(
      'scopeOccupancy.areasAffected',
      draft.scopeOccupancy.areasAffected,
    );
    out.enumValue(
      'scopeOccupancy.occupancyType',
      draft.scopeOccupancy.occupancyType,
    );
    out.scalar(
      'scopeOccupancy.occupancyOtherDescription',
      draft.scopeOccupancy.occupancyOtherDescription,
    );
    // One row per SanitaryFixtureType, matched back by type. See the
    // plumbing codec, which carries the identical inventory.
    out.rows('installationDetails.fixtureInventory.fixtures', [
      for (final fixture in draft.installationDetails.fixtureInventory.fixtures)
        out.row()
          ..enumValue('type', fixture.type)
          ..scalar('customName', fixture.customName)
          ..scalar('newQuantity', fixture.newQuantity)
          ..scalar('existingQuantity', fixture.existingQuantity)
          ..scalar('notes', fixture.notes),
    ]);
    out.enumSet(
      'installationDetails.waterSupply.selectedTypes',
      draft.installationDetails.waterSupply.selectedTypes,
    );
    out.scalar(
      'installationDetails.waterSupply.shallowWellDepth',
      draft.installationDetails.waterSupply.shallowWellDepth,
    );
    out.scalar(
      'installationDetails.waterSupply.shallowWellEstimatedYield',
      draft.installationDetails.waterSupply.shallowWellEstimatedYield,
    );
    out.scalar(
      'installationDetails.waterSupply.shallowWellPumpType',
      draft.installationDetails.waterSupply.shallowWellPumpType,
    );
    out.scalar(
      'installationDetails.waterSupply.shallowWellTreatmentMethod',
      draft.installationDetails.waterSupply.shallowWellTreatmentMethod,
    );
    out.scalar(
      'installationDetails.waterSupply.deepWellDepth',
      draft.installationDetails.waterSupply.deepWellDepth,
    );
    out.scalar(
      'installationDetails.waterSupply.deepWellPumpCapacity',
      draft.installationDetails.waterSupply.deepWellPumpCapacity,
    );
    out.scalar(
      'installationDetails.waterSupply.deepWellPumpRating',
      draft.installationDetails.waterSupply.deepWellPumpRating,
    );
    out.scalar(
      'installationDetails.waterSupply.deepWellEstimatedYield',
      draft.installationDetails.waterSupply.deepWellEstimatedYield,
    );
    out.scalar(
      'installationDetails.waterSupply.deepWellTreatmentMethod',
      draft.installationDetails.waterSupply.deepWellTreatmentMethod,
    );
    out.scalar(
      'installationDetails.waterSupply.cityWaterServiceProvider',
      draft.installationDetails.waterSupply.cityWaterServiceProvider,
    );
    out.scalar(
      'installationDetails.waterSupply.cityWaterServiceConnectionNumber',
      draft.installationDetails.waterSupply.cityWaterServiceConnectionNumber,
    );
    out.scalar(
      'installationDetails.waterSupply.cityWaterMeterSize',
      draft.installationDetails.waterSupply.cityWaterMeterSize,
    );
    out.scalar(
      'installationDetails.waterSupply.otherWaterSupplyDescription',
      draft.installationDetails.waterSupply.otherWaterSupplyDescription,
    );
    out.enumSet(
      'installationDetails.disposalSystem.selectedTypes',
      draft.installationDetails.disposalSystem.selectedTypes,
    );
    out.scalar(
      'installationDetails.disposalSystem.wtpTreatmentType',
      draft.installationDetails.disposalSystem.wtpTreatmentType,
    );
    out.scalar(
      'installationDetails.disposalSystem.wtpTreatmentCapacity',
      draft.installationDetails.disposalSystem.wtpTreatmentCapacity,
    );
    out.scalar(
      'installationDetails.disposalSystem.wtpDischargePoint',
      draft.installationDetails.disposalSystem.wtpDischargePoint,
    );
    out.scalar(
      'installationDetails.disposalSystem.wtpOperatorOrResponsibleParty',
      draft.installationDetails.disposalSystem.wtpOperatorOrResponsibleParty,
    );
    out.scalar(
      'installationDetails.disposalSystem.imhoffTankCapacity',
      draft.installationDetails.disposalSystem.imhoffTankCapacity,
    );
    out.scalar(
      'installationDetails.disposalSystem.imhoffTankDimensions',
      draft.installationDetails.disposalSystem.imhoffTankDimensions,
    );
    out.scalar(
      'installationDetails.disposalSystem.imhoffEffluentDestination',
      draft.installationDetails.disposalSystem.imhoffEffluentDestination,
    );
    out.scalar(
      'installationDetails.disposalSystem.sewerProviderOrReceivingSystem',
      draft.installationDetails.disposalSystem.sewerProviderOrReceivingSystem,
    );
    out.scalar(
      'installationDetails.disposalSystem.sewerConnectionReference',
      draft.installationDetails.disposalSystem.sewerConnectionReference,
    );
    out.scalar(
      'installationDetails.disposalSystem.sewerConnectionPoint',
      draft.installationDetails.disposalSystem.sewerConnectionPoint,
    );
    out.scalar(
      'installationDetails.disposalSystem.sandFilterArea',
      draft.installationDetails.disposalSystem.sandFilterArea,
    );
    out.scalar(
      'installationDetails.disposalSystem.sandFilterDescription',
      draft.installationDetails.disposalSystem.sandFilterDescription,
    );
    out.scalar(
      'installationDetails.disposalSystem.sandFilterEffluentDestination',
      draft.installationDetails.disposalSystem.sandFilterEffluentDestination,
    );
    out.scalar(
      'installationDetails.disposalSystem.drainageDischargeLocation',
      draft.installationDetails.disposalSystem.drainageDischargeLocation,
    );
    out.scalar(
      'installationDetails.disposalSystem.drainageDescription',
      draft.installationDetails.disposalSystem.drainageDescription,
    );
    out.scalar(
      'installationDetails.disposalSystem.drainageRequiredClearanceStatus',
      draft.installationDetails.disposalSystem.drainageRequiredClearanceStatus,
    );
    out.scalar(
      'installationDetails.disposalSystem.otherDisposalSystemDescription',
      draft.installationDetails.disposalSystem.otherDisposalSystemDescription,
    );
    out.scalar(
      'installationDetails.buildingProjectDetails.numberOfStoreys',
      draft.installationDetails.buildingProjectDetails.numberOfStoreys,
    );
    out.scalar(
      'installationDetails.buildingProjectDetails.totalBuildingArea',
      draft.installationDetails.buildingProjectDetails.totalBuildingArea,
    );
    out.date(
      'installationDetails.buildingProjectDetails.proposedStartDate',
      draft.installationDetails.buildingProjectDetails.proposedStartDate,
    );
    out.date(
      'installationDetails.buildingProjectDetails.expectedCompletionDate',
      draft.installationDetails.buildingProjectDetails.expectedCompletionDate,
    );
    out.scalar(
      'installationDetails.buildingProjectDetails.totalCostOfInstallation',
      draft.installationDetails.buildingProjectDetails.totalCostOfInstallation,
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
      'requiredDocuments.sanitaryPlansUpload',
      draft.requiredDocuments.sanitaryPlansUpload,
      'Sanitary Plans',
    );
    out.document(
      'requiredDocuments.plumbingPlansUpload',
      draft.requiredDocuments.plumbingPlansUpload,
      'Plumbing Plans',
    );
    out.document(
      'requiredDocuments.sanitaryPlumbingSpecificationsUpload',
      draft.requiredDocuments.sanitaryPlumbingSpecificationsUpload,
      'Sanitary Plumbing Specifications',
    );
    out.document(
      'requiredDocuments.waterSupplyLayoutUpload',
      draft.requiredDocuments.waterSupplyLayoutUpload,
      'Water Supply Layout',
    );
    out.document(
      'requiredDocuments.drainageLayoutUpload',
      draft.requiredDocuments.drainageLayoutUpload,
      'Drainage Layout',
    );
    out.document(
      'requiredDocuments.sewerLayoutUpload',
      draft.requiredDocuments.sewerLayoutUpload,
      'Sewer Layout',
    );
    out.document(
      'requiredDocuments.plumbingRiserDiagramUpload',
      draft.requiredDocuments.plumbingRiserDiagramUpload,
      'Plumbing Riser Diagram',
    );
    out.document(
      'requiredDocuments.fixtureScheduleUpload',
      draft.requiredDocuments.fixtureScheduleUpload,
      'Fixture Schedule',
    );
    out.document(
      'requiredDocuments.generalNotesUpload',
      draft.requiredDocuments.generalNotesUpload,
      'General Notes',
    );
    out.document(
      'requiredDocuments.billOfMaterialsUpload',
      draft.requiredDocuments.billOfMaterialsUpload,
      'Bill of Materials',
    );
    out.document(
      'requiredDocuments.costEstimateUpload',
      draft.requiredDocuments.costEstimateUpload,
      'Cost Estimate',
    );
    out.document(
      'requiredDocuments.quantityTakeoffUpload',
      draft.requiredDocuments.quantityTakeoffUpload,
      'Quantity Takeoff',
    );
    out.document(
      'requiredDocuments.materialSpecificationsUpload',
      draft.requiredDocuments.materialSpecificationsUpload,
      'Material Specifications',
    );
    out.document(
      'requiredDocuments.fixtureEquipmentSpecificationsUpload',
      draft.requiredDocuments.fixtureEquipmentSpecificationsUpload,
      'Fixture Equipment Specifications',
    );
    out.document(
      'requiredDocuments.shallowWellPlanUpload',
      draft.requiredDocuments.shallowWellPlanUpload,
      'Shallow Well Plan',
    );
    out.document(
      'requiredDocuments.shallowWellPumpDetailsUpload',
      draft.requiredDocuments.shallowWellPumpDetailsUpload,
      'Shallow Well Pump Details',
    );
    out.document(
      'requiredDocuments.shallowWellWaterQualityUpload',
      draft.requiredDocuments.shallowWellWaterQualityUpload,
      'Shallow Well Water Quality',
    );
    out.document(
      'requiredDocuments.deepWellPlanUpload',
      draft.requiredDocuments.deepWellPlanUpload,
      'Deep Well Plan',
    );
    out.document(
      'requiredDocuments.deepWellPumpSpecificationsUpload',
      draft.requiredDocuments.deepWellPumpSpecificationsUpload,
      'Deep Well Pump Specifications',
    );
    out.document(
      'requiredDocuments.deepWellDetailsUpload',
      draft.requiredDocuments.deepWellDetailsUpload,
      'Deep Well Details',
    );
    out.document(
      'requiredDocuments.deepWellWaterQualityUpload',
      draft.requiredDocuments.deepWellWaterQualityUpload,
      'Deep Well Water Quality',
    );
    out.document(
      'requiredDocuments.cityWaterServiceConnectionPlanUpload',
      draft.requiredDocuments.cityWaterServiceConnectionPlanUpload,
      'City Water Service Connection Plan',
    );
    out.document(
      'requiredDocuments.cityWaterProviderApprovalUpload',
      draft.requiredDocuments.cityWaterProviderApprovalUpload,
      'City Water Provider Approval',
    );
    out.document(
      'requiredDocuments.cityWaterMeterDetailsUpload',
      draft.requiredDocuments.cityWaterMeterDetailsUpload,
      'City Water Meter Details',
    );
    out.document(
      'requiredDocuments.wtpLayoutUpload',
      draft.requiredDocuments.wtpLayoutUpload,
      'Wtp Layout',
    );
    out.document(
      'requiredDocuments.wtpProcessDescriptionUpload',
      draft.requiredDocuments.wtpProcessDescriptionUpload,
      'Wtp Process Description',
    );
    out.document(
      'requiredDocuments.wtpCapacityCalculationsUpload',
      draft.requiredDocuments.wtpCapacityCalculationsUpload,
      'Wtp Capacity Calculations',
    );
    out.document(
      'requiredDocuments.wtpDischargePlanUpload',
      draft.requiredDocuments.wtpDischargePlanUpload,
      'Wtp Discharge Plan',
    );
    out.document(
      'requiredDocuments.imhoffPlanUpload',
      draft.requiredDocuments.imhoffPlanUpload,
      'Imhoff Plan',
    );
    out.document(
      'requiredDocuments.imhoffTankDetailsUpload',
      draft.requiredDocuments.imhoffTankDetailsUpload,
      'Imhoff Tank Details',
    );
    out.document(
      'requiredDocuments.imhoffEffluentDisposalPlanUpload',
      draft.requiredDocuments.imhoffEffluentDisposalPlanUpload,
      'Imhoff Effluent Disposal Plan',
    );
    out.document(
      'requiredDocuments.sewerConnectionPlanUpload',
      draft.requiredDocuments.sewerConnectionPlanUpload,
      'Sewer Connection Plan',
    );
    out.document(
      'requiredDocuments.sewerReceivingSystemCoordinationUpload',
      draft.requiredDocuments.sewerReceivingSystemCoordinationUpload,
      'Sewer Receiving System Coordination',
    );
    out.document(
      'requiredDocuments.sewerConnectionDetailsUpload',
      draft.requiredDocuments.sewerConnectionDetailsUpload,
      'Sewer Connection Details',
    );
    out.document(
      'requiredDocuments.sandFilterPlanUpload',
      draft.requiredDocuments.sandFilterPlanUpload,
      'Sand Filter Plan',
    );
    out.document(
      'requiredDocuments.sandFilterDetailsUpload',
      draft.requiredDocuments.sandFilterDetailsUpload,
      'Sand Filter Details',
    );
    out.document(
      'requiredDocuments.sandFilterEffluentDisposalPlanUpload',
      draft.requiredDocuments.sandFilterEffluentDisposalPlanUpload,
      'Sand Filter Effluent Disposal Plan',
    );
    out.document(
      'requiredDocuments.drainagePlanUpload',
      draft.requiredDocuments.drainagePlanUpload,
      'Drainage Plan',
    );
    out.document(
      'requiredDocuments.drainageDischargeDetailsUpload',
      draft.requiredDocuments.drainageDischargeDetailsUpload,
      'Drainage Discharge Details',
    );
    out.document(
      'requiredDocuments.drainageClearanceCoordinationUpload',
      draft.requiredDocuments.drainageClearanceCoordinationUpload,
      'Drainage Clearance Coordination',
    );
    out.document(
      'requiredDocuments.swimmingPoolPlumbingPlanUpload',
      draft.requiredDocuments.swimmingPoolPlumbingPlanUpload,
      'Swimming Pool Plumbing Plan',
    );
    out.document(
      'requiredDocuments.greaseTrapDetailsUpload',
      draft.requiredDocuments.greaseTrapDetailsUpload,
      'Grease Trap Details',
    );
    out.document(
      'requiredDocuments.waterTankReservoirDetailsUpload',
      draft.requiredDocuments.waterTankReservoirDetailsUpload,
      'Water Tank Reservoir Details',
    );
    out.document(
      'requiredDocuments.laboratoryPlumbingDetailsUpload',
      draft.requiredDocuments.laboratoryPlumbingDetailsUpload,
      'Laboratory Plumbing Details',
    );
    out.document(
      'requiredDocuments.dentalFacilityPlumbingDetailsUpload',
      draft.requiredDocuments.dentalFacilityPlumbingDetailsUpload,
      'Dental Facility Plumbing Details',
    );
    out.document(
      'requiredDocuments.otherSpecializedFixtureDetailsUpload',
      draft.requiredDocuments.otherSpecializedFixtureDetailsUpload,
      'Other Specialized Fixture Details',
    );
    out.document(
      'requiredDocuments.relatedBuildingPermitUpload',
      draft.requiredDocuments.relatedBuildingPermitUpload,
      'Related Building Permit',
    );
    out.document(
      'requiredDocuments.waterProviderCoordinationUpload',
      draft.requiredDocuments.waterProviderCoordinationUpload,
      'Water Provider Coordination',
    );
    out.document(
      'requiredDocuments.sewerProviderCoordinationUpload',
      draft.requiredDocuments.sewerProviderCoordinationUpload,
      'Sewer Provider Coordination',
    );
    out.document(
      'requiredDocuments.environmentalDischargeClearanceUpload',
      draft.requiredDocuments.environmentalDischargeClearanceUpload,
      'Environmental Discharge Clearance',
    );
    out.document(
      'requiredDocuments.otherSanitaryPlumbingDocumentsUpload',
      draft.requiredDocuments.otherSanitaryPlumbingDocumentsUpload,
      'Other Sanitary Plumbing Documents',
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
  void restore(SanitaryPermitDraft draft, SnapshotReader input) {
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
    draft.relatedBuildingPermit.buildingPermitNumber = input.string(
      'relatedBuildingPermit.buildingPermitNumber',
    );
    draft.relatedBuildingPermit.status =
        input.enumValue(
          'relatedBuildingPermit.status',
          RelatedBuildingPermitStatus.values,
        ) ??
        RelatedBuildingPermitStatus.pending;
    draft.scopeOccupancy.selectedScopes
      ..clear()
      ..addAll(
        input.enumSet(
          'scopeOccupancy.selectedScopes',
          SanitaryScopeType.values,
        ),
      );
    draft.scopeOccupancy.otherScopeDescription = input.string(
      'scopeOccupancy.otherScopeDescription',
    );
    draft.scopeOccupancy.workTitle = input.string('scopeOccupancy.workTitle');
    draft.scopeOccupancy.generalDescription = input.string(
      'scopeOccupancy.generalDescription',
    );
    draft.scopeOccupancy.existingSystemCondition = input.string(
      'scopeOccupancy.existingSystemCondition',
    );
    draft.scopeOccupancy.proposedChanges = input.string(
      'scopeOccupancy.proposedChanges',
    );
    draft.scopeOccupancy.areasAffected = input.string(
      'scopeOccupancy.areasAffected',
    );
    draft.scopeOccupancy.occupancyType = input.enumValue(
      'scopeOccupancy.occupancyType',
      SanitaryOccupancyType.values,
    );
    draft.scopeOccupancy.occupancyOtherDescription = input.string(
      'scopeOccupancy.occupancyOtherDescription',
    );
    for (final row in input.rows(
      'installationDetails.fixtureInventory.fixtures',
    )) {
      final type = row.enumValue('type', SanitaryFixtureType.values);
      if (type == null) continue;
      for (final fixture
          in draft.installationDetails.fixtureInventory.fixtures) {
        if (fixture.type != type) continue;
        fixture.customName = row.string('customName');
        fixture.newQuantity = row.string('newQuantity');
        fixture.existingQuantity = row.string('existingQuantity');
        fixture.notes = row.string('notes');
      }
    }
    draft.installationDetails.waterSupply.selectedTypes
      ..clear()
      ..addAll(
        input.enumSet(
          'installationDetails.waterSupply.selectedTypes',
          WaterSupplyType.values,
        ),
      );
    draft.installationDetails.waterSupply.shallowWellDepth = input.string(
      'installationDetails.waterSupply.shallowWellDepth',
    );
    draft.installationDetails.waterSupply.shallowWellEstimatedYield = input
        .string('installationDetails.waterSupply.shallowWellEstimatedYield');
    draft.installationDetails.waterSupply.shallowWellPumpType = input.string(
      'installationDetails.waterSupply.shallowWellPumpType',
    );
    draft.installationDetails.waterSupply.shallowWellTreatmentMethod = input
        .string('installationDetails.waterSupply.shallowWellTreatmentMethod');
    draft.installationDetails.waterSupply.deepWellDepth = input.string(
      'installationDetails.waterSupply.deepWellDepth',
    );
    draft.installationDetails.waterSupply.deepWellPumpCapacity = input.string(
      'installationDetails.waterSupply.deepWellPumpCapacity',
    );
    draft.installationDetails.waterSupply.deepWellPumpRating = input.string(
      'installationDetails.waterSupply.deepWellPumpRating',
    );
    draft.installationDetails.waterSupply.deepWellEstimatedYield = input.string(
      'installationDetails.waterSupply.deepWellEstimatedYield',
    );
    draft.installationDetails.waterSupply.deepWellTreatmentMethod = input
        .string('installationDetails.waterSupply.deepWellTreatmentMethod');
    draft.installationDetails.waterSupply.cityWaterServiceProvider = input
        .string('installationDetails.waterSupply.cityWaterServiceProvider');
    draft.installationDetails.waterSupply.cityWaterServiceConnectionNumber =
        input.string(
          'installationDetails.waterSupply.cityWaterServiceConnectionNumber',
        );
    draft.installationDetails.waterSupply.cityWaterMeterSize = input.string(
      'installationDetails.waterSupply.cityWaterMeterSize',
    );
    draft.installationDetails.waterSupply.otherWaterSupplyDescription = input
        .string('installationDetails.waterSupply.otherWaterSupplyDescription');
    draft.installationDetails.disposalSystem.selectedTypes
      ..clear()
      ..addAll(
        input.enumSet(
          'installationDetails.disposalSystem.selectedTypes',
          DisposalSystemType.values,
        ),
      );
    draft.installationDetails.disposalSystem.wtpTreatmentType = input.string(
      'installationDetails.disposalSystem.wtpTreatmentType',
    );
    draft.installationDetails.disposalSystem.wtpTreatmentCapacity = input
        .string('installationDetails.disposalSystem.wtpTreatmentCapacity');
    draft.installationDetails.disposalSystem.wtpDischargePoint = input.string(
      'installationDetails.disposalSystem.wtpDischargePoint',
    );
    draft.installationDetails.disposalSystem.wtpOperatorOrResponsibleParty =
        input.string(
          'installationDetails.disposalSystem.wtpOperatorOrResponsibleParty',
        );
    draft.installationDetails.disposalSystem.imhoffTankCapacity = input.string(
      'installationDetails.disposalSystem.imhoffTankCapacity',
    );
    draft.installationDetails.disposalSystem.imhoffTankDimensions = input
        .string('installationDetails.disposalSystem.imhoffTankDimensions');
    draft.installationDetails.disposalSystem.imhoffEffluentDestination = input
        .string('installationDetails.disposalSystem.imhoffEffluentDestination');
    draft.installationDetails.disposalSystem.sewerProviderOrReceivingSystem =
        input.string(
          'installationDetails.disposalSystem.sewerProviderOrReceivingSystem',
        );
    draft.installationDetails.disposalSystem.sewerConnectionReference = input
        .string('installationDetails.disposalSystem.sewerConnectionReference');
    draft.installationDetails.disposalSystem.sewerConnectionPoint = input
        .string('installationDetails.disposalSystem.sewerConnectionPoint');
    draft.installationDetails.disposalSystem.sandFilterArea = input.string(
      'installationDetails.disposalSystem.sandFilterArea',
    );
    draft.installationDetails.disposalSystem.sandFilterDescription = input
        .string('installationDetails.disposalSystem.sandFilterDescription');
    draft.installationDetails.disposalSystem.sandFilterEffluentDestination =
        input.string(
          'installationDetails.disposalSystem.sandFilterEffluentDestination',
        );
    draft.installationDetails.disposalSystem.drainageDischargeLocation = input
        .string('installationDetails.disposalSystem.drainageDischargeLocation');
    draft.installationDetails.disposalSystem.drainageDescription = input.string(
      'installationDetails.disposalSystem.drainageDescription',
    );
    draft.installationDetails.disposalSystem.drainageRequiredClearanceStatus =
        input.string(
          'installationDetails.disposalSystem.drainageRequiredClearanceStatus',
        );
    draft.installationDetails.disposalSystem.otherDisposalSystemDescription =
        input.string(
          'installationDetails.disposalSystem.otherDisposalSystemDescription',
        );
    draft.installationDetails.buildingProjectDetails.numberOfStoreys = input
        .string('installationDetails.buildingProjectDetails.numberOfStoreys');
    draft.installationDetails.buildingProjectDetails.totalBuildingArea = input
        .string('installationDetails.buildingProjectDetails.totalBuildingArea');
    draft.installationDetails.buildingProjectDetails.proposedStartDate = input
        .date('installationDetails.buildingProjectDetails.proposedStartDate');
    draft.installationDetails.buildingProjectDetails.expectedCompletionDate =
        input.date(
          'installationDetails.buildingProjectDetails.expectedCompletionDate',
        );
    draft.installationDetails.buildingProjectDetails.totalCostOfInstallation =
        input.string(
          'installationDetails.buildingProjectDetails.totalCostOfInstallation',
        );
    draft.professionals.designProfessional.fullName = input.string(
      'professionals.designProfessional.fullName',
    );
    draft.professionals.designProfessional.profession = input.enumValue(
      'professionals.designProfessional.profession',
      SanitaryProfessionType.values,
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
    draft.professionals.isSupervisorSameAsDesignProfessional = input.boolean(
      'professionals.isSupervisorSameAsDesignProfessional',
      fallback: true,
    );
    draft.professionals.supervisor.fullName = input.string(
      'professionals.supervisor.fullName',
    );
    draft.professionals.supervisor.profession = input.enumValue(
      'professionals.supervisor.profession',
      SanitaryProfessionType.values,
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
    draft.status = SanitaryPermitDraftStatus.draft;
    draft.lastSavedAt = input.date('lastSavedAt');
  }
}
