import '../models/plumbing_permit_model.dart';
import 'draft_snapshot.dart';

/// Plumbing — PlumbingPermitDraft, persisted.
///
/// One of the seventeen wizards converted in M-48 part 2, after the mechanism
/// was proven on the Building Permit and Fencing. Every field the draft
/// declares is captured and read back except the 63 attachment slots,
/// which are dropped and named back to the applicant, and whatever
/// `test/architecture/draft_snapshot_completeness_test.dart` exempts with a
/// reason. That gate fails the day this file falls behind the model.
///
/// Written mechanically from the model's own field declarations and then
/// reviewed, which is why it reads uniformly. The alternative — trusting a
/// generator without a gate — is how 176 fields become 176 chances to
/// drop one silently.
class PlumbingPermitDraftCodec extends DraftCodec<PlumbingPermitDraft> {
  const PlumbingPermitDraftCodec();

  @override
  String get permitKey => 'plumbing-permit';

  @override
  String get permitLabel => 'Plumbing';

  @override
  void capture(PlumbingPermitDraft draft, SnapshotWriter out) {
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
    out.scalar('scopeOfWork.workTitle', draft.scopeOfWork.workTitle);
    out.scalar(
      'scopeOfWork.generalDescription',
      draft.scopeOfWork.generalDescription,
    );
    out.scalar(
      'scopeOfWork.existingPlumbingCondition',
      draft.scopeOfWork.existingPlumbingCondition,
    );
    out.scalar(
      'scopeOfWork.proposedPlumbingChanges',
      draft.scopeOfWork.proposedPlumbingChanges,
    );
    out.scalar('scopeOfWork.areasAffected', draft.scopeOfWork.areasAffected);
    out.enumSet(
      'installationDetails.selectedSystems',
      draft.installationDetails.selectedSystems,
    );
    // One row per PlumbingFixtureType, pre-populated by the model. Matched
    // back by type rather than by index: a list position is not an identity.
    out.rows('installationDetails.fixtureInventory.fixtures', [
      for (final fixture in draft.installationDetails.fixtureInventory.fixtures)
        out.row()
          ..enumValue('type', fixture.type)
          ..scalar('customName', fixture.customName)
          ..scalar('newQuantity', fixture.newQuantity)
          ..scalar('existingQuantity', fixture.existingQuantity)
          ..scalar('notes', fixture.notes),
    ]);
    out.enumValue(
      'installationDetails.waterDistribution.waterSource',
      draft.installationDetails.waterDistribution.waterSource,
    );
    out.scalar(
      'installationDetails.waterDistribution.otherWaterSourceDescription',
      draft.installationDetails.waterDistribution.otherWaterSourceDescription,
    );
    out.scalar(
      'installationDetails.waterDistribution.waterServiceProvider',
      draft.installationDetails.waterDistribution.waterServiceProvider,
    );
    out.scalar(
      'installationDetails.waterDistribution.mainPipeMaterial',
      draft.installationDetails.waterDistribution.mainPipeMaterial,
    );
    out.scalar(
      'installationDetails.waterDistribution.mainPipeDiameter',
      draft.installationDetails.waterDistribution.mainPipeDiameter,
    );
    out.scalar(
      'installationDetails.waterDistribution.waterMeterSize',
      draft.installationDetails.waterDistribution.waterMeterSize,
    );
    out.scalar(
      'installationDetails.waterDistribution.storageTankCapacity',
      draft.installationDetails.waterDistribution.storageTankCapacity,
    );
    out.scalar(
      'installationDetails.waterDistribution.pumpCapacity',
      draft.installationDetails.waterDistribution.pumpCapacity,
    );
    out.scalar(
      'installationDetails.waterDistribution.distributionSystemDescription',
      draft.installationDetails.waterDistribution.distributionSystemDescription,
    );
    out.scalar(
      'installationDetails.waterDistribution.estimatedDemandOrFlowRate',
      draft.installationDetails.waterDistribution.estimatedDemandOrFlowRate,
    );
    out.enumValue(
      'installationDetails.sewageSystem.disposalMethod',
      draft.installationDetails.sewageSystem.disposalMethod,
    );
    out.scalar(
      'installationDetails.sewageSystem.otherDisposalMethodDescription',
      draft.installationDetails.sewageSystem.otherDisposalMethodDescription,
    );
    out.scalar(
      'installationDetails.sewageSystem.receivingSewerOrDisposalPoint',
      draft.installationDetails.sewageSystem.receivingSewerOrDisposalPoint,
    );
    out.scalar(
      'installationDetails.sewageSystem.mainSewerPipeMaterial',
      draft.installationDetails.sewageSystem.mainSewerPipeMaterial,
    );
    out.scalar(
      'installationDetails.sewageSystem.mainSewerPipeDiameter',
      draft.installationDetails.sewageSystem.mainSewerPipeDiameter,
    );
    out.scalar(
      'installationDetails.sewageSystem.connectionReference',
      draft.installationDetails.sewageSystem.connectionReference,
    );
    out.scalar(
      'installationDetails.sewageSystem.sewageSystemDescription',
      draft.installationDetails.sewageSystem.sewageSystemDescription,
    );
    out.scalar(
      'installationDetails.sewageSystem.estimatedWastewaterFlow',
      draft.installationDetails.sewageSystem.estimatedWastewaterFlow,
    );
    out.scalar(
      'installationDetails.septicTank.tankType',
      draft.installationDetails.septicTank.tankType,
    );
    out.scalar(
      'installationDetails.septicTank.tankCapacity',
      draft.installationDetails.septicTank.tankCapacity,
    );
    out.scalar(
      'installationDetails.septicTank.numberOfChambers',
      draft.installationDetails.septicTank.numberOfChambers,
    );
    out.scalar(
      'installationDetails.septicTank.tankDimensions',
      draft.installationDetails.septicTank.tankDimensions,
    );
    out.scalar(
      'installationDetails.septicTank.tankMaterial',
      draft.installationDetails.septicTank.tankMaterial,
    );
    out.scalar(
      'installationDetails.septicTank.effluentDisposalMethod',
      draft.installationDetails.septicTank.effluentDisposalMethod,
    );
    out.scalar(
      'installationDetails.septicTank.locationDescription',
      draft.installationDetails.septicTank.locationDescription,
    );
    out.scalar(
      'installationDetails.septicTank.accessAndMaintenanceDescription',
      draft.installationDetails.septicTank.accessAndMaintenanceDescription,
    );
    out.enumValue(
      'installationDetails.stormDrainage.drainageType',
      draft.installationDetails.stormDrainage.drainageType,
    );
    out.scalar(
      'installationDetails.stormDrainage.otherDrainageTypeDescription',
      draft.installationDetails.stormDrainage.otherDrainageTypeDescription,
    );
    out.scalar(
      'installationDetails.stormDrainage.dischargePoint',
      draft.installationDetails.stormDrainage.dischargePoint,
    );
    out.scalar(
      'installationDetails.stormDrainage.mainDrainPipeMaterial',
      draft.installationDetails.stormDrainage.mainDrainPipeMaterial,
    );
    out.scalar(
      'installationDetails.stormDrainage.mainDrainPipeDiameter',
      draft.installationDetails.stormDrainage.mainDrainPipeDiameter,
    );
    out.scalar(
      'installationDetails.stormDrainage.catchBasinCount',
      draft.installationDetails.stormDrainage.catchBasinCount,
    );
    out.scalar(
      'installationDetails.stormDrainage.roofDrainCount',
      draft.installationDetails.stormDrainage.roofDrainCount,
    );
    out.scalar(
      'installationDetails.stormDrainage.drainageSystemDescription',
      draft.installationDetails.stormDrainage.drainageSystemDescription,
    );
    out.scalar(
      'installationDetails.stormDrainage.applicableClearanceStatus',
      draft.installationDetails.stormDrainage.applicableClearanceStatus,
    );
    out.scalar(
      'professionals.designMasterPlumber.fullName',
      draft.professionals.designMasterPlumber.fullName,
    );
    out.scalar(
      'professionals.designMasterPlumber.address',
      draft.professionals.designMasterPlumber.address,
    );
    out.scalar(
      'professionals.designMasterPlumber.prcNumber',
      draft.professionals.designMasterPlumber.prcNumber,
    );
    out.date(
      'professionals.designMasterPlumber.prcValidityDate',
      draft.professionals.designMasterPlumber.prcValidityDate,
    );
    out.scalar(
      'professionals.designMasterPlumber.ptrNumber',
      draft.professionals.designMasterPlumber.ptrNumber,
    );
    out.date(
      'professionals.designMasterPlumber.ptrDateIssued',
      draft.professionals.designMasterPlumber.ptrDateIssued,
    );
    out.scalar(
      'professionals.designMasterPlumber.ptrPlaceIssued',
      draft.professionals.designMasterPlumber.ptrPlaceIssued,
    );
    out.scalar(
      'professionals.designMasterPlumber.tin',
      draft.professionals.designMasterPlumber.tin,
    );
    out.date(
      'professionals.designMasterPlumber.dateSigned',
      draft.professionals.designMasterPlumber.dateSigned,
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
      'professionals.signedPlumbingCalculationsUpload',
      draft.professionals.signedPlumbingCalculationsUpload,
      'Signed Plumbing Calculations',
    );
    out.scalar(
      'professionals.isSupervisorSameAsDesignMasterPlumber',
      draft.professionals.isSupervisorSameAsDesignMasterPlumber,
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
      'requiredDocuments.plumbingPlansUpload',
      draft.requiredDocuments.plumbingPlansUpload,
      'Plumbing Plans',
    );
    out.document(
      'requiredDocuments.plumbingSpecificationsUpload',
      draft.requiredDocuments.plumbingSpecificationsUpload,
      'Plumbing Specifications',
    );
    out.document(
      'requiredDocuments.waterDistributionLayoutUpload',
      draft.requiredDocuments.waterDistributionLayoutUpload,
      'Water Distribution Layout',
    );
    out.document(
      'requiredDocuments.sewageLayoutCoreUpload',
      draft.requiredDocuments.sewageLayoutCoreUpload,
      'Sewage Layout Core',
    );
    out.document(
      'requiredDocuments.stormDrainageLayoutUpload',
      draft.requiredDocuments.stormDrainageLayoutUpload,
      'Storm Drainage Layout',
    );
    out.document(
      'requiredDocuments.plumbingRiserDiagramUpload',
      draft.requiredDocuments.plumbingRiserDiagramUpload,
      'Plumbing Riser Diagram',
    );
    out.document(
      'requiredDocuments.isometricDiagramUpload',
      draft.requiredDocuments.isometricDiagramUpload,
      'Isometric Diagram',
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
      'requiredDocuments.plumbingCalculationsUpload',
      draft.requiredDocuments.plumbingCalculationsUpload,
      'Plumbing Calculations',
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
      'requiredDocuments.pipeAndMaterialSpecificationsUpload',
      draft.requiredDocuments.pipeAndMaterialSpecificationsUpload,
      'Pipe and Material Specifications',
    );
    out.document(
      'requiredDocuments.fixtureEquipmentSpecificationsUpload',
      draft.requiredDocuments.fixtureEquipmentSpecificationsUpload,
      'Fixture Equipment Specifications',
    );
    out.document(
      'requiredDocuments.waterDistributionPlanUpload',
      draft.requiredDocuments.waterDistributionPlanUpload,
      'Water Distribution Plan',
    );
    out.document(
      'requiredDocuments.waterDemandCalculationUpload',
      draft.requiredDocuments.waterDemandCalculationUpload,
      'Water Demand Calculation',
    );
    out.document(
      'requiredDocuments.pipeSizingCalculationUpload',
      draft.requiredDocuments.pipeSizingCalculationUpload,
      'Pipe Sizing Calculation',
    );
    out.document(
      'requiredDocuments.waterMeterDetailsUpload',
      draft.requiredDocuments.waterMeterDetailsUpload,
      'Water Meter Details',
    );
    out.document(
      'requiredDocuments.pumpDetailsUpload',
      draft.requiredDocuments.pumpDetailsUpload,
      'Pump Details',
    );
    out.document(
      'requiredDocuments.waterStorageDetailsUpload',
      draft.requiredDocuments.waterStorageDetailsUpload,
      'Water Storage Details',
    );
    out.document(
      'requiredDocuments.providerCoordinationUpload',
      draft.requiredDocuments.providerCoordinationUpload,
      'Provider Coordination',
    );
    out.document(
      'requiredDocuments.sewageLayoutUpload',
      draft.requiredDocuments.sewageLayoutUpload,
      'Sewage Layout',
    );
    out.document(
      'requiredDocuments.wastewaterFlowCalculationUpload',
      draft.requiredDocuments.wastewaterFlowCalculationUpload,
      'Wastewater Flow Calculation',
    );
    out.document(
      'requiredDocuments.sewerPipeSizingCalculationUpload',
      draft.requiredDocuments.sewerPipeSizingCalculationUpload,
      'Sewer Pipe Sizing Calculation',
    );
    out.document(
      'requiredDocuments.sewerConnectionDetailsUpload',
      draft.requiredDocuments.sewerConnectionDetailsUpload,
      'Sewer Connection Details',
    );
    out.document(
      'requiredDocuments.receivingSystemCoordinationUpload',
      draft.requiredDocuments.receivingSystemCoordinationUpload,
      'Receiving System Coordination',
    );
    out.document(
      'requiredDocuments.septicTankPlanUpload',
      draft.requiredDocuments.septicTankPlanUpload,
      'Septic Tank Plan',
    );
    out.document(
      'requiredDocuments.septicTankDetailsUpload',
      draft.requiredDocuments.septicTankDetailsUpload,
      'Septic Tank Details',
    );
    out.document(
      'requiredDocuments.septicCapacityCalculationUpload',
      draft.requiredDocuments.septicCapacityCalculationUpload,
      'Septic Capacity Calculation',
    );
    out.document(
      'requiredDocuments.septicEffluentDisposalPlanUpload',
      draft.requiredDocuments.septicEffluentDisposalPlanUpload,
      'Septic Effluent Disposal Plan',
    );
    out.document(
      'requiredDocuments.septicMaintenanceAccessDetailsUpload',
      draft.requiredDocuments.septicMaintenanceAccessDetailsUpload,
      'Septic Maintenance Access Details',
    );
    out.document(
      'requiredDocuments.stormDrainagePlanUpload',
      draft.requiredDocuments.stormDrainagePlanUpload,
      'Storm Drainage Plan',
    );
    out.document(
      'requiredDocuments.drainageCalculationUpload',
      draft.requiredDocuments.drainageCalculationUpload,
      'Drainage Calculation',
    );
    out.document(
      'requiredDocuments.roofDrainDownspoutLayoutUpload',
      draft.requiredDocuments.roofDrainDownspoutLayoutUpload,
      'Roof Drain Downspout Layout',
    );
    out.document(
      'requiredDocuments.catchBasinDetailsUpload',
      draft.requiredDocuments.catchBasinDetailsUpload,
      'Catch Basin Details',
    );
    out.document(
      'requiredDocuments.stormDischargeDetailsUpload',
      draft.requiredDocuments.stormDischargeDetailsUpload,
      'Storm Discharge Details',
    );
    out.document(
      'requiredDocuments.stormClearanceCoordinationUpload',
      draft.requiredDocuments.stormClearanceCoordinationUpload,
      'Storm Clearance Coordination',
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
      'requiredDocuments.dentalPlumbingDetailsUpload',
      draft.requiredDocuments.dentalPlumbingDetailsUpload,
      'Dental Plumbing Details',
    );
    out.document(
      'requiredDocuments.specializedFixtureDetailsUpload',
      draft.requiredDocuments.specializedFixtureDetailsUpload,
      'Specialized Fixture Details',
    );
    out.document(
      'requiredDocuments.relatedBuildingPermitUpload',
      draft.requiredDocuments.relatedBuildingPermitUpload,
      'Related Building Permit',
    );
    out.document(
      'requiredDocuments.existingPlumbingPermitUpload',
      draft.requiredDocuments.existingPlumbingPermitUpload,
      'Existing Plumbing Permit',
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
      'requiredDocuments.siteOrUtilityPlanUpload',
      draft.requiredDocuments.siteOrUtilityPlanUpload,
      'Site or Utility Plan',
    );
    out.document(
      'requiredDocuments.otherPlumbingDocumentsUpload',
      draft.requiredDocuments.otherPlumbingDocumentsUpload,
      'Other Plumbing Documents',
    );
    out.scalar(
      'reviewDeclaration.certifiesTrueAndCorrect',
      draft.reviewDeclaration.certifiesTrueAndCorrect,
    );
    out.scalar(
      'reviewDeclaration.confirmsPlansPreparedByLicensedMasterPlumber',
      draft.reviewDeclaration.confirmsPlansPreparedByLicensedMasterPlumber,
    );
    out.scalar(
      'reviewDeclaration.understandsMustFollowApprovedPlansAndCodes',
      draft.reviewDeclaration.understandsMustFollowApprovedPlansAndCodes,
    );
    out.scalar(
      'reviewDeclaration.understandsRequiresLicensedMasterPlumberSupervisor',
      draft
          .reviewDeclaration
          .understandsRequiresLicensedMasterPlumberSupervisor,
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
  void restore(PlumbingPermitDraft draft, SnapshotReader input) {
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
      PlumbingOccupancyGroup.values,
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
        input.enumSet('scopeOfWork.selectedScopes', PlumbingScopeType.values),
      );
    draft.scopeOfWork.otherScopeDescription = input.string(
      'scopeOfWork.otherScopeDescription',
    );
    draft.scopeOfWork.workTitle = input.string('scopeOfWork.workTitle');
    draft.scopeOfWork.generalDescription = input.string(
      'scopeOfWork.generalDescription',
    );
    draft.scopeOfWork.existingPlumbingCondition = input.string(
      'scopeOfWork.existingPlumbingCondition',
    );
    draft.scopeOfWork.proposedPlumbingChanges = input.string(
      'scopeOfWork.proposedPlumbingChanges',
    );
    draft.scopeOfWork.areasAffected = input.string('scopeOfWork.areasAffected');
    draft.installationDetails.selectedSystems
      ..clear()
      ..addAll(
        input.enumSet(
          'installationDetails.selectedSystems',
          PlumbingSystemType.values,
        ),
      );
    for (final row in input.rows(
      'installationDetails.fixtureInventory.fixtures',
    )) {
      final type = row.enumValue('type', PlumbingFixtureType.values);
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
    draft.installationDetails.waterDistribution.waterSource = input.enumValue(
      'installationDetails.waterDistribution.waterSource',
      WaterSourceType.values,
    );
    draft.installationDetails.waterDistribution.otherWaterSourceDescription =
        input.string(
          'installationDetails.waterDistribution.otherWaterSourceDescription',
        );
    draft.installationDetails.waterDistribution.waterServiceProvider = input
        .string('installationDetails.waterDistribution.waterServiceProvider');
    draft.installationDetails.waterDistribution.mainPipeMaterial = input.string(
      'installationDetails.waterDistribution.mainPipeMaterial',
    );
    draft.installationDetails.waterDistribution.mainPipeDiameter = input.string(
      'installationDetails.waterDistribution.mainPipeDiameter',
    );
    draft.installationDetails.waterDistribution.waterMeterSize = input.string(
      'installationDetails.waterDistribution.waterMeterSize',
    );
    draft.installationDetails.waterDistribution.storageTankCapacity = input
        .string('installationDetails.waterDistribution.storageTankCapacity');
    draft.installationDetails.waterDistribution.pumpCapacity = input.string(
      'installationDetails.waterDistribution.pumpCapacity',
    );
    draft.installationDetails.waterDistribution.distributionSystemDescription =
        input.string(
          'installationDetails.waterDistribution.distributionSystemDescription',
        );
    draft.installationDetails.waterDistribution.estimatedDemandOrFlowRate =
        input.string(
          'installationDetails.waterDistribution.estimatedDemandOrFlowRate',
        );
    draft.installationDetails.sewageSystem.disposalMethod = input.enumValue(
      'installationDetails.sewageSystem.disposalMethod',
      SewageDisposalMethod.values,
    );
    draft.installationDetails.sewageSystem.otherDisposalMethodDescription =
        input.string(
          'installationDetails.sewageSystem.otherDisposalMethodDescription',
        );
    draft.installationDetails.sewageSystem.receivingSewerOrDisposalPoint = input
        .string(
          'installationDetails.sewageSystem.receivingSewerOrDisposalPoint',
        );
    draft.installationDetails.sewageSystem.mainSewerPipeMaterial = input.string(
      'installationDetails.sewageSystem.mainSewerPipeMaterial',
    );
    draft.installationDetails.sewageSystem.mainSewerPipeDiameter = input.string(
      'installationDetails.sewageSystem.mainSewerPipeDiameter',
    );
    draft.installationDetails.sewageSystem.connectionReference = input.string(
      'installationDetails.sewageSystem.connectionReference',
    );
    draft.installationDetails.sewageSystem.sewageSystemDescription = input
        .string('installationDetails.sewageSystem.sewageSystemDescription');
    draft.installationDetails.sewageSystem.estimatedWastewaterFlow = input
        .string('installationDetails.sewageSystem.estimatedWastewaterFlow');
    draft.installationDetails.septicTank.tankType = input.string(
      'installationDetails.septicTank.tankType',
    );
    draft.installationDetails.septicTank.tankCapacity = input.string(
      'installationDetails.septicTank.tankCapacity',
    );
    draft.installationDetails.septicTank.numberOfChambers = input.string(
      'installationDetails.septicTank.numberOfChambers',
    );
    draft.installationDetails.septicTank.tankDimensions = input.string(
      'installationDetails.septicTank.tankDimensions',
    );
    draft.installationDetails.septicTank.tankMaterial = input.string(
      'installationDetails.septicTank.tankMaterial',
    );
    draft.installationDetails.septicTank.effluentDisposalMethod = input.string(
      'installationDetails.septicTank.effluentDisposalMethod',
    );
    draft.installationDetails.septicTank.locationDescription = input.string(
      'installationDetails.septicTank.locationDescription',
    );
    draft.installationDetails.septicTank.accessAndMaintenanceDescription = input
        .string(
          'installationDetails.septicTank.accessAndMaintenanceDescription',
        );
    draft.installationDetails.stormDrainage.drainageType = input.enumValue(
      'installationDetails.stormDrainage.drainageType',
      StormDrainageType.values,
    );
    draft.installationDetails.stormDrainage.otherDrainageTypeDescription = input
        .string(
          'installationDetails.stormDrainage.otherDrainageTypeDescription',
        );
    draft.installationDetails.stormDrainage.dischargePoint = input.string(
      'installationDetails.stormDrainage.dischargePoint',
    );
    draft.installationDetails.stormDrainage.mainDrainPipeMaterial = input
        .string('installationDetails.stormDrainage.mainDrainPipeMaterial');
    draft.installationDetails.stormDrainage.mainDrainPipeDiameter = input
        .string('installationDetails.stormDrainage.mainDrainPipeDiameter');
    draft.installationDetails.stormDrainage.catchBasinCount = input.string(
      'installationDetails.stormDrainage.catchBasinCount',
    );
    draft.installationDetails.stormDrainage.roofDrainCount = input.string(
      'installationDetails.stormDrainage.roofDrainCount',
    );
    draft.installationDetails.stormDrainage.drainageSystemDescription = input
        .string('installationDetails.stormDrainage.drainageSystemDescription');
    draft.installationDetails.stormDrainage.applicableClearanceStatus = input
        .string('installationDetails.stormDrainage.applicableClearanceStatus');
    draft.professionals.designMasterPlumber.fullName = input.string(
      'professionals.designMasterPlumber.fullName',
    );
    draft.professionals.designMasterPlumber.address = input.string(
      'professionals.designMasterPlumber.address',
    );
    draft.professionals.designMasterPlumber.prcNumber = input.string(
      'professionals.designMasterPlumber.prcNumber',
    );
    draft.professionals.designMasterPlumber.prcValidityDate = input.date(
      'professionals.designMasterPlumber.prcValidityDate',
    );
    draft.professionals.designMasterPlumber.ptrNumber = input.string(
      'professionals.designMasterPlumber.ptrNumber',
    );
    draft.professionals.designMasterPlumber.ptrDateIssued = input.date(
      'professionals.designMasterPlumber.ptrDateIssued',
    );
    draft.professionals.designMasterPlumber.ptrPlaceIssued = input.string(
      'professionals.designMasterPlumber.ptrPlaceIssued',
    );
    draft.professionals.designMasterPlumber.tin = input.string(
      'professionals.designMasterPlumber.tin',
    );
    draft.professionals.designMasterPlumber.dateSigned = input.date(
      'professionals.designMasterPlumber.dateSigned',
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
    draft.professionals.signedPlumbingCalculationsUpload = input.document(
      'professionals.signedPlumbingCalculationsUpload',
    );
    draft.professionals.isSupervisorSameAsDesignMasterPlumber = input.boolean(
      'professionals.isSupervisorSameAsDesignMasterPlumber',
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
    draft.requiredDocuments.plumbingPlansUpload = input.document(
      'requiredDocuments.plumbingPlansUpload',
    );
    draft.requiredDocuments.plumbingSpecificationsUpload = input.document(
      'requiredDocuments.plumbingSpecificationsUpload',
    );
    draft.requiredDocuments.waterDistributionLayoutUpload = input.document(
      'requiredDocuments.waterDistributionLayoutUpload',
    );
    draft.requiredDocuments.sewageLayoutCoreUpload = input.document(
      'requiredDocuments.sewageLayoutCoreUpload',
    );
    draft.requiredDocuments.stormDrainageLayoutUpload = input.document(
      'requiredDocuments.stormDrainageLayoutUpload',
    );
    draft.requiredDocuments.plumbingRiserDiagramUpload = input.document(
      'requiredDocuments.plumbingRiserDiagramUpload',
    );
    draft.requiredDocuments.isometricDiagramUpload = input.document(
      'requiredDocuments.isometricDiagramUpload',
    );
    draft.requiredDocuments.fixtureScheduleUpload = input.document(
      'requiredDocuments.fixtureScheduleUpload',
    );
    draft.requiredDocuments.generalNotesUpload = input.document(
      'requiredDocuments.generalNotesUpload',
    );
    draft.requiredDocuments.plumbingCalculationsUpload = input.document(
      'requiredDocuments.plumbingCalculationsUpload',
    );
    draft.requiredDocuments.billOfMaterialsUpload = input.document(
      'requiredDocuments.billOfMaterialsUpload',
    );
    draft.requiredDocuments.costEstimateUpload = input.document(
      'requiredDocuments.costEstimateUpload',
    );
    draft.requiredDocuments.quantityTakeoffUpload = input.document(
      'requiredDocuments.quantityTakeoffUpload',
    );
    draft.requiredDocuments.pipeAndMaterialSpecificationsUpload = input
        .document('requiredDocuments.pipeAndMaterialSpecificationsUpload');
    draft.requiredDocuments.fixtureEquipmentSpecificationsUpload = input
        .document('requiredDocuments.fixtureEquipmentSpecificationsUpload');
    draft.requiredDocuments.waterDistributionPlanUpload = input.document(
      'requiredDocuments.waterDistributionPlanUpload',
    );
    draft.requiredDocuments.waterDemandCalculationUpload = input.document(
      'requiredDocuments.waterDemandCalculationUpload',
    );
    draft.requiredDocuments.pipeSizingCalculationUpload = input.document(
      'requiredDocuments.pipeSizingCalculationUpload',
    );
    draft.requiredDocuments.waterMeterDetailsUpload = input.document(
      'requiredDocuments.waterMeterDetailsUpload',
    );
    draft.requiredDocuments.pumpDetailsUpload = input.document(
      'requiredDocuments.pumpDetailsUpload',
    );
    draft.requiredDocuments.waterStorageDetailsUpload = input.document(
      'requiredDocuments.waterStorageDetailsUpload',
    );
    draft.requiredDocuments.providerCoordinationUpload = input.document(
      'requiredDocuments.providerCoordinationUpload',
    );
    draft.requiredDocuments.sewageLayoutUpload = input.document(
      'requiredDocuments.sewageLayoutUpload',
    );
    draft.requiredDocuments.wastewaterFlowCalculationUpload = input.document(
      'requiredDocuments.wastewaterFlowCalculationUpload',
    );
    draft.requiredDocuments.sewerPipeSizingCalculationUpload = input.document(
      'requiredDocuments.sewerPipeSizingCalculationUpload',
    );
    draft.requiredDocuments.sewerConnectionDetailsUpload = input.document(
      'requiredDocuments.sewerConnectionDetailsUpload',
    );
    draft.requiredDocuments.receivingSystemCoordinationUpload = input.document(
      'requiredDocuments.receivingSystemCoordinationUpload',
    );
    draft.requiredDocuments.septicTankPlanUpload = input.document(
      'requiredDocuments.septicTankPlanUpload',
    );
    draft.requiredDocuments.septicTankDetailsUpload = input.document(
      'requiredDocuments.septicTankDetailsUpload',
    );
    draft.requiredDocuments.septicCapacityCalculationUpload = input.document(
      'requiredDocuments.septicCapacityCalculationUpload',
    );
    draft.requiredDocuments.septicEffluentDisposalPlanUpload = input.document(
      'requiredDocuments.septicEffluentDisposalPlanUpload',
    );
    draft.requiredDocuments.septicMaintenanceAccessDetailsUpload = input
        .document('requiredDocuments.septicMaintenanceAccessDetailsUpload');
    draft.requiredDocuments.stormDrainagePlanUpload = input.document(
      'requiredDocuments.stormDrainagePlanUpload',
    );
    draft.requiredDocuments.drainageCalculationUpload = input.document(
      'requiredDocuments.drainageCalculationUpload',
    );
    draft.requiredDocuments.roofDrainDownspoutLayoutUpload = input.document(
      'requiredDocuments.roofDrainDownspoutLayoutUpload',
    );
    draft.requiredDocuments.catchBasinDetailsUpload = input.document(
      'requiredDocuments.catchBasinDetailsUpload',
    );
    draft.requiredDocuments.stormDischargeDetailsUpload = input.document(
      'requiredDocuments.stormDischargeDetailsUpload',
    );
    draft.requiredDocuments.stormClearanceCoordinationUpload = input.document(
      'requiredDocuments.stormClearanceCoordinationUpload',
    );
    draft.requiredDocuments.swimmingPoolPlumbingPlanUpload = input.document(
      'requiredDocuments.swimmingPoolPlumbingPlanUpload',
    );
    draft.requiredDocuments.greaseTrapDetailsUpload = input.document(
      'requiredDocuments.greaseTrapDetailsUpload',
    );
    draft.requiredDocuments.waterTankReservoirDetailsUpload = input.document(
      'requiredDocuments.waterTankReservoirDetailsUpload',
    );
    draft.requiredDocuments.laboratoryPlumbingDetailsUpload = input.document(
      'requiredDocuments.laboratoryPlumbingDetailsUpload',
    );
    draft.requiredDocuments.dentalPlumbingDetailsUpload = input.document(
      'requiredDocuments.dentalPlumbingDetailsUpload',
    );
    draft.requiredDocuments.specializedFixtureDetailsUpload = input.document(
      'requiredDocuments.specializedFixtureDetailsUpload',
    );
    draft.requiredDocuments.relatedBuildingPermitUpload = input.document(
      'requiredDocuments.relatedBuildingPermitUpload',
    );
    draft.requiredDocuments.existingPlumbingPermitUpload = input.document(
      'requiredDocuments.existingPlumbingPermitUpload',
    );
    draft.requiredDocuments.waterProviderCoordinationUpload = input.document(
      'requiredDocuments.waterProviderCoordinationUpload',
    );
    draft.requiredDocuments.sewerProviderCoordinationUpload = input.document(
      'requiredDocuments.sewerProviderCoordinationUpload',
    );
    draft.requiredDocuments.siteOrUtilityPlanUpload = input.document(
      'requiredDocuments.siteOrUtilityPlanUpload',
    );
    draft.requiredDocuments.otherPlumbingDocumentsUpload = input.document(
      'requiredDocuments.otherPlumbingDocumentsUpload',
    );
    draft.reviewDeclaration.certifiesTrueAndCorrect = input.boolean(
      'reviewDeclaration.certifiesTrueAndCorrect',
    );
    draft.reviewDeclaration.confirmsPlansPreparedByLicensedMasterPlumber = input
        .boolean(
          'reviewDeclaration.confirmsPlansPreparedByLicensedMasterPlumber',
        );
    draft.reviewDeclaration.understandsMustFollowApprovedPlansAndCodes = input
        .boolean(
          'reviewDeclaration.understandsMustFollowApprovedPlansAndCodes',
        );
    draft
        .reviewDeclaration
        .understandsRequiresLicensedMasterPlumberSupervisor = input.boolean(
      'reviewDeclaration.understandsRequiresLicensedMasterPlumberSupervisor',
    );
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
    draft.status = PlumbingPermitDraftStatus.draft;
    draft.lastSavedAt = input.date('lastSavedAt');
  }
}
