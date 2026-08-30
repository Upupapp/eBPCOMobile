import '../models/electrical_permit_model.dart';
import 'draft_snapshot.dart';

/// Electrical — ElectricalPermitDraft, persisted.
///
/// One of the seventeen wizards converted in M-48 part 2, after the mechanism
/// was proven on the Building Permit and Fencing. Every field the draft
/// declares is captured and read back except the 53 attachment slots,
/// which are dropped and named back to the applicant, and whatever
/// `test/architecture/draft_snapshot_completeness_test.dart` exempts with a
/// reason. That gate fails the day this file falls behind the model.
///
/// Written mechanically from the model's own field declarations and then
/// reviewed, which is why it reads uniformly. The alternative — trusting a
/// generator without a gate — is how 172 fields become 172 chances to
/// drop one silently.
class ElectricalPermitDraftCodec extends DraftCodec<ElectricalPermitDraft> {
  const ElectricalPermitDraftCodec();

  @override
  String get permitKey => 'electrical-permit';

  @override
  String get permitLabel => 'Electrical';

  @override
  void capture(ElectricalPermitDraft draft, SnapshotWriter out) {
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
    out.scalar(
      'relatedBuildingPermit.isPurelyElectricalOnExistingBuilding',
      draft.relatedBuildingPermit.isPurelyElectricalOnExistingBuilding,
    );
    out.enumSet('scopeOfWork.selectedScopes', draft.scopeOfWork.selectedScopes);
    out.enumValue('scopeOfWork.primaryScope', draft.scopeOfWork.primaryScope);
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
      'scopeOfWork.existingElectricalCondition',
      draft.scopeOfWork.existingElectricalCondition,
    );
    out.scalar(
      'scopeOfWork.proposedElectricalChanges',
      draft.scopeOfWork.proposedElectricalChanges,
    );
    out.scalar(
      'scopeOfWork.previousServiceDetails',
      draft.scopeOfWork.previousServiceDetails,
    );
    out.scalar(
      'scopeOfWork.reasonForChange',
      draft.scopeOfWork.reasonForChange,
    );
    out.scalar(
      'scopeOfWork.separationServicesDescription',
      draft.scopeOfWork.separationServicesDescription,
    );
    out.scalar(
      'scopeOfWork.existingServiceCapacity',
      draft.scopeOfWork.existingServiceCapacity,
    );
    out.scalar(
      'scopeOfWork.proposedServiceCapacity',
      draft.scopeOfWork.proposedServiceCapacity,
    );
    out.scalar(
      'scopeOfWork.existingServiceEntranceLocation',
      draft.scopeOfWork.existingServiceEntranceLocation,
    );
    out.scalar(
      'scopeOfWork.proposedServiceEntranceLocation',
      draft.scopeOfWork.proposedServiceEntranceLocation,
    );
    out.date(
      'scopeOfWork.expectedRemovalDate',
      draft.scopeOfWork.expectedRemovalDate,
    );
    out.scalar(
      'scopeOfWork.previousInspectionReference',
      draft.scopeOfWork.previousInspectionReference,
    );
    out.enumValue(
      'installationDetails.occupancyGroup',
      draft.installationDetails.occupancyGroup,
    );
    out.scalar(
      'installationDetails.occupancyOtherDescription',
      draft.installationDetails.occupancyOtherDescription,
    );
    out.scalar(
      'installationDetails.lightingOutlets',
      draft.installationDetails.lightingOutlets,
    );
    out.scalar(
      'installationDetails.convenienceOutlets',
      draft.installationDetails.convenienceOutlets,
    );
    out.scalar(
      'installationDetails.specialPurposeAirConditioningOutlets',
      draft.installationDetails.specialPurposeAirConditioningOutlets,
    );
    out.scalar(
      'installationDetails.specialPurposeCookingUnitOutlets',
      draft.installationDetails.specialPurposeCookingUnitOutlets,
    );
    out.scalar(
      'installationDetails.specialPurposeWaterHeaterOutlets',
      draft.installationDetails.specialPurposeWaterHeaterOutlets,
    );
    out.scalar(
      'installationDetails.specialPurposeWaterPumpOutlets',
      draft.installationDetails.specialPurposeWaterPumpOutlets,
    );
    out.scalar(
      'installationDetails.toggleSwitches',
      draft.installationDetails.toggleSwitches,
    );
    out.scalar(
      'installationDetails.bellBuzzers',
      draft.installationDetails.bellBuzzers,
    );
    out.scalar(
      'installationDetails.pushButtons',
      draft.installationDetails.pushButtons,
    );
    out.scalar(
      'installationDetails.fireAlarmDetectors',
      draft.installationDetails.fireAlarmDetectors,
    );
    out.scalar(
      'installationDetails.otherOutlets',
      draft.installationDetails.otherOutlets,
    );
    out.scalar(
      'installationDetails.otherOutletDescription',
      draft.installationDetails.otherOutletDescription,
    );
    out.scalar(
      'installationDetails.totalConnectedLoadKva',
      draft.installationDetails.totalConnectedLoadKva,
    );
    out.scalar(
      'installationDetails.totalTransformerCapacityKva',
      draft.installationDetails.totalTransformerCapacityKva,
    );
    out.scalar(
      'installationDetails.generatorCapacityKva',
      draft.installationDetails.generatorCapacityKva,
    );
    out.scalar(
      'installationDetails.upsCapacityKva',
      draft.installationDetails.upsCapacityKva,
    );
    out.scalar(
      'installationDetails.mainServiceVoltage',
      draft.installationDetails.mainServiceVoltage,
    );
    out.scalar(
      'installationDetails.mainServiceCurrentAmperes',
      draft.installationDetails.mainServiceCurrentAmperes,
    );
    out.scalar(
      'installationDetails.numberOfPhases',
      draft.installationDetails.numberOfPhases,
    );
    out.scalar(
      'installationDetails.frequency',
      draft.installationDetails.frequency,
    );
    out.scalar(
      'installationDetails.powerFactor',
      draft.installationDetails.powerFactor,
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
      'professionals.signedLoadCalculationsUpload',
      draft.professionals.signedLoadCalculationsUpload,
      'Signed Load Calculations',
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
      'professionals.contractorVoluntarilyIndicated',
      draft.professionals.contractorVoluntarilyIndicated,
    );
    out.scalar(
      'professionals.contractor.contractorName',
      draft.professionals.contractor.contractorName,
    );
    out.scalar(
      'professionals.contractor.contractorAddress',
      draft.professionals.contractor.contractorAddress,
    );
    out.scalar(
      'professionals.contractor.pcabLicenseNumber',
      draft.professionals.contractor.pcabLicenseNumber,
    );
    out.date(
      'professionals.contractor.pcabLicenseValidityDate',
      draft.professionals.contractor.pcabLicenseValidityDate,
    );
    out.scalar(
      'professionals.contractor.electricalWorksClassification',
      draft.professionals.contractor.electricalWorksClassification,
    );
    out.scalar(
      'professionals.contractor.contactNumber',
      draft.professionals.contractor.contactNumber,
    );
    out.document(
      'professionals.contractor.pcabLicenseUpload',
      draft.professionals.contractor.pcabLicenseUpload,
      'PCAB License',
    );
    out.document(
      'professionals.contractor.contractorAccreditationUpload',
      draft.professionals.contractor.contractorAccreditationUpload,
      'Contractor Accreditation',
    );
    out.document(
      'professionals.contractor.contractorAuthorizationUpload',
      draft.professionals.contractor.contractorAuthorizationUpload,
      'Contractor Authorization',
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
      'requiredDocuments.singleLineDiagramUpload',
      draft.requiredDocuments.singleLineDiagramUpload,
      'Single Line Diagram',
    );
    out.document(
      'requiredDocuments.loadScheduleUpload',
      draft.requiredDocuments.loadScheduleUpload,
      'Load Schedule',
    );
    out.document(
      'requiredDocuments.panelboardScheduleUpload',
      draft.requiredDocuments.panelboardScheduleUpload,
      'Panelboard Schedule',
    );
    out.document(
      'requiredDocuments.serviceEntranceDetailsUpload',
      draft.requiredDocuments.serviceEntranceDetailsUpload,
      'Service Entrance Details',
    );
    out.document(
      'requiredDocuments.groundingDetailsUpload',
      draft.requiredDocuments.groundingDetailsUpload,
      'Grounding Details',
    );
    out.document(
      'requiredDocuments.electricalLayoutPlansUpload',
      draft.requiredDocuments.electricalLayoutPlansUpload,
      'Electrical Layout Plans',
    );
    out.document(
      'requiredDocuments.lightingLayoutUpload',
      draft.requiredDocuments.lightingLayoutUpload,
      'Lighting Layout',
    );
    out.document(
      'requiredDocuments.powerLayoutUpload',
      draft.requiredDocuments.powerLayoutUpload,
      'Power Layout',
    );
    out.document(
      'requiredDocuments.fireAlarmLayoutUpload',
      draft.requiredDocuments.fireAlarmLayoutUpload,
      'Fire Alarm Layout',
    );
    out.document(
      'requiredDocuments.transformerCapacityDetailsUpload',
      draft.requiredDocuments.transformerCapacityDetailsUpload,
      'Transformer Capacity Details',
    );
    out.document(
      'requiredDocuments.shortCircuitCalculationUpload',
      draft.requiredDocuments.shortCircuitCalculationUpload,
      'Short Circuit Calculation',
    );
    out.document(
      'requiredDocuments.voltageDropCalculationUpload',
      draft.requiredDocuments.voltageDropCalculationUpload,
      'Voltage Drop Calculation',
    );
    out.document(
      'requiredDocuments.specialFixturesScheduleUpload',
      draft.requiredDocuments.specialFixturesScheduleUpload,
      'Special Fixtures Schedule',
    );
    out.document(
      'requiredDocuments.equipmentSpecificationsUpload',
      draft.requiredDocuments.equipmentSpecificationsUpload,
      'Equipment Specifications',
    );
    out.document(
      'requiredDocuments.airConditioningEquipmentScheduleUpload',
      draft.requiredDocuments.airConditioningEquipmentScheduleUpload,
      'Air Conditioning Equipment Schedule',
    );
    out.document(
      'requiredDocuments.cookingEquipmentScheduleUpload',
      draft.requiredDocuments.cookingEquipmentScheduleUpload,
      'Cooking Equipment Schedule',
    );
    out.document(
      'requiredDocuments.waterHeaterScheduleUpload',
      draft.requiredDocuments.waterHeaterScheduleUpload,
      'Water Heater Schedule',
    );
    out.document(
      'requiredDocuments.waterPumpScheduleUpload',
      draft.requiredDocuments.waterPumpScheduleUpload,
      'Water Pump Schedule',
    );
    out.document(
      'requiredDocuments.generatorDetailsUpload',
      draft.requiredDocuments.generatorDetailsUpload,
      'Generator Details',
    );
    out.document(
      'requiredDocuments.upsDetailsUpload',
      draft.requiredDocuments.upsDetailsUpload,
      'Ups Details',
    );
    out.document(
      'requiredDocuments.fireAlarmDetectorScheduleUpload',
      draft.requiredDocuments.fireAlarmDetectorScheduleUpload,
      'Fire Alarm Detector Schedule',
    );
    out.document(
      'requiredDocuments.otherEquipmentDocumentsUpload',
      draft.requiredDocuments.otherEquipmentDocumentsUpload,
      'Other Equipment Documents',
    );
    out.document(
      'requiredDocuments.existingServiceRecordUpload',
      draft.requiredDocuments.existingServiceRecordUpload,
      'Existing Service Record',
    );
    out.document(
      'requiredDocuments.utilityCoordinationUpload',
      draft.requiredDocuments.utilityCoordinationUpload,
      'Utility Coordination',
    );
    out.document(
      'requiredDocuments.separateServiceDiagramUpload',
      draft.requiredDocuments.separateServiceDiagramUpload,
      'Separate Service Diagram',
    );
    out.document(
      'requiredDocuments.existingLoadCalculationUpload',
      draft.requiredDocuments.existingLoadCalculationUpload,
      'Existing Load Calculation',
    );
    out.document(
      'requiredDocuments.proposedLoadCalculationUpload',
      draft.requiredDocuments.proposedLoadCalculationUpload,
      'Proposed Load Calculation',
    );
    out.document(
      'requiredDocuments.existingServiceEntrancePlanUpload',
      draft.requiredDocuments.existingServiceEntrancePlanUpload,
      'Existing Service Entrance Plan',
    );
    out.document(
      'requiredDocuments.proposedServiceEntrancePlanUpload',
      draft.requiredDocuments.proposedServiceEntrancePlanUpload,
      'Proposed Service Entrance Plan',
    );
    out.document(
      'requiredDocuments.temporaryElectricalLayoutUpload',
      draft.requiredDocuments.temporaryElectricalLayoutUpload,
      'Temporary Electrical Layout',
    );
    out.document(
      'requiredDocuments.removalScheduleUpload',
      draft.requiredDocuments.removalScheduleUpload,
      'Removal Schedule',
    );
    out.document(
      'requiredDocuments.workScheduleUpload',
      draft.requiredDocuments.workScheduleUpload,
      'Work Schedule',
    );
    out.document(
      'requiredDocuments.relatedBuildingPermitUpload',
      draft.requiredDocuments.relatedBuildingPermitUpload,
      'Related Building Permit',
    );
    out.document(
      'requiredDocuments.previousElectricalPermitUpload',
      draft.requiredDocuments.previousElectricalPermitUpload,
      'Previous Electrical Permit',
    );
    out.document(
      'requiredDocuments.existingServiceRecordsUpload',
      draft.requiredDocuments.existingServiceRecordsUpload,
      'Existing Service Records',
    );
    out.document(
      'requiredDocuments.utilityProviderApprovalUpload',
      draft.requiredDocuments.utilityProviderApprovalUpload,
      'Utility Provider Approval',
    );
    out.document(
      'requiredDocuments.otherElectricalDocumentsUpload',
      draft.requiredDocuments.otherElectricalDocumentsUpload,
      'Other Electrical Documents',
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
      'reviewDeclaration.understandsContractorRequiredAtThreshold',
      draft.reviewDeclaration.understandsContractorRequiredAtThreshold,
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
      'reviewDeclaration.understandsFinalInspectionRequiredBeforeOccupancy',
      draft.reviewDeclaration.understandsFinalInspectionRequiredBeforeOccupancy,
    );
    out.scalar(
      'reviewDeclaration.understandsRequiresValidBuildingPermit',
      draft.reviewDeclaration.understandsRequiresValidBuildingPermit,
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
      'useApplicantAddressForProjectLocation',
      draft.useApplicantAddressForProjectLocation,
    );
    out.enumValue('status', draft.status);
    out.date('lastSavedAt', draft.lastSavedAt);
  }

  @override
  void restore(ElectricalPermitDraft draft, SnapshotReader input) {
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
    draft.relatedBuildingPermit.isPurelyElectricalOnExistingBuilding = input
        .boolean('relatedBuildingPermit.isPurelyElectricalOnExistingBuilding');
    draft.scopeOfWork.selectedScopes
      ..clear()
      ..addAll(
        input.enumSet('scopeOfWork.selectedScopes', ElectricalScopeType.values),
      );
    draft.scopeOfWork.primaryScope = input.enumValue(
      'scopeOfWork.primaryScope',
      ElectricalScopeType.values,
    );
    draft.scopeOfWork.otherScopeDescription = input.string(
      'scopeOfWork.otherScopeDescription',
    );
    draft.scopeOfWork.workTitle = input.string('scopeOfWork.workTitle');
    draft.scopeOfWork.generalDescription = input.string(
      'scopeOfWork.generalDescription',
    );
    draft.scopeOfWork.existingElectricalCondition = input.string(
      'scopeOfWork.existingElectricalCondition',
    );
    draft.scopeOfWork.proposedElectricalChanges = input.string(
      'scopeOfWork.proposedElectricalChanges',
    );
    draft.scopeOfWork.previousServiceDetails = input.string(
      'scopeOfWork.previousServiceDetails',
    );
    draft.scopeOfWork.reasonForChange = input.string(
      'scopeOfWork.reasonForChange',
    );
    draft.scopeOfWork.separationServicesDescription = input.string(
      'scopeOfWork.separationServicesDescription',
    );
    draft.scopeOfWork.existingServiceCapacity = input.string(
      'scopeOfWork.existingServiceCapacity',
    );
    draft.scopeOfWork.proposedServiceCapacity = input.string(
      'scopeOfWork.proposedServiceCapacity',
    );
    draft.scopeOfWork.existingServiceEntranceLocation = input.string(
      'scopeOfWork.existingServiceEntranceLocation',
    );
    draft.scopeOfWork.proposedServiceEntranceLocation = input.string(
      'scopeOfWork.proposedServiceEntranceLocation',
    );
    draft.scopeOfWork.expectedRemovalDate = input.date(
      'scopeOfWork.expectedRemovalDate',
    );
    draft.scopeOfWork.previousInspectionReference = input.string(
      'scopeOfWork.previousInspectionReference',
    );
    draft.installationDetails.occupancyGroup = input.enumValue(
      'installationDetails.occupancyGroup',
      ElectricalOccupancyGroup.values,
    );
    draft.installationDetails.occupancyOtherDescription = input.string(
      'installationDetails.occupancyOtherDescription',
    );
    draft.installationDetails.lightingOutlets = input.string(
      'installationDetails.lightingOutlets',
    );
    draft.installationDetails.convenienceOutlets = input.string(
      'installationDetails.convenienceOutlets',
    );
    draft.installationDetails.specialPurposeAirConditioningOutlets = input
        .string('installationDetails.specialPurposeAirConditioningOutlets');
    draft.installationDetails.specialPurposeCookingUnitOutlets = input.string(
      'installationDetails.specialPurposeCookingUnitOutlets',
    );
    draft.installationDetails.specialPurposeWaterHeaterOutlets = input.string(
      'installationDetails.specialPurposeWaterHeaterOutlets',
    );
    draft.installationDetails.specialPurposeWaterPumpOutlets = input.string(
      'installationDetails.specialPurposeWaterPumpOutlets',
    );
    draft.installationDetails.toggleSwitches = input.string(
      'installationDetails.toggleSwitches',
    );
    draft.installationDetails.bellBuzzers = input.string(
      'installationDetails.bellBuzzers',
    );
    draft.installationDetails.pushButtons = input.string(
      'installationDetails.pushButtons',
    );
    draft.installationDetails.fireAlarmDetectors = input.string(
      'installationDetails.fireAlarmDetectors',
    );
    draft.installationDetails.otherOutlets = input.string(
      'installationDetails.otherOutlets',
    );
    draft.installationDetails.otherOutletDescription = input.string(
      'installationDetails.otherOutletDescription',
    );
    draft.installationDetails.totalConnectedLoadKva = input.string(
      'installationDetails.totalConnectedLoadKva',
    );
    draft.installationDetails.totalTransformerCapacityKva = input.string(
      'installationDetails.totalTransformerCapacityKva',
    );
    draft.installationDetails.generatorCapacityKva = input.string(
      'installationDetails.generatorCapacityKva',
    );
    draft.installationDetails.upsCapacityKva = input.string(
      'installationDetails.upsCapacityKva',
    );
    draft.installationDetails.mainServiceVoltage = input.string(
      'installationDetails.mainServiceVoltage',
    );
    draft.installationDetails.mainServiceCurrentAmperes = input.string(
      'installationDetails.mainServiceCurrentAmperes',
    );
    draft.installationDetails.numberOfPhases = input.string(
      'installationDetails.numberOfPhases',
    );
    draft.installationDetails.frequency = input.string(
      'installationDetails.frequency',
    );
    draft.installationDetails.powerFactor = input.string(
      'installationDetails.powerFactor',
    );
    draft.professionals.designProfessional.fullName = input.string(
      'professionals.designProfessional.fullName',
    );
    draft.professionals.designProfessional.profession = input.enumValue(
      'professionals.designProfessional.profession',
      ElectricalProfessionType.values,
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
      ElectricalProfessionType.values,
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
    draft.professionals.contractorVoluntarilyIndicated = input.boolean(
      'professionals.contractorVoluntarilyIndicated',
    );
    draft.professionals.contractor.contractorName = input.string(
      'professionals.contractor.contractorName',
    );
    draft.professionals.contractor.contractorAddress = input.string(
      'professionals.contractor.contractorAddress',
    );
    draft.professionals.contractor.pcabLicenseNumber = input.string(
      'professionals.contractor.pcabLicenseNumber',
    );
    draft.professionals.contractor.pcabLicenseValidityDate = input.date(
      'professionals.contractor.pcabLicenseValidityDate',
    );
    draft.professionals.contractor.electricalWorksClassification = input.string(
      'professionals.contractor.electricalWorksClassification',
    );
    draft.professionals.contractor.contactNumber = input.string(
      'professionals.contractor.contactNumber',
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
    draft.reviewDeclaration.understandsContractorRequiredAtThreshold = input
        .boolean('reviewDeclaration.understandsContractorRequiredAtThreshold');
    draft.reviewDeclaration.understandsNoticeOfConstructionMayBeRequired = input
        .boolean(
          'reviewDeclaration.understandsNoticeOfConstructionMayBeRequired',
        );
    draft.reviewDeclaration.understandsCompletionDocumentsMayBeRequired = input
        .boolean(
          'reviewDeclaration.understandsCompletionDocumentsMayBeRequired',
        );
    draft.reviewDeclaration.understandsFinalInspectionRequiredBeforeOccupancy =
        input.boolean(
          'reviewDeclaration.understandsFinalInspectionRequiredBeforeOccupancy',
        );
    draft.reviewDeclaration.understandsRequiresValidBuildingPermit = input
        .boolean('reviewDeclaration.understandsRequiresValidBuildingPermit');
    draft.reviewDeclaration.agreesToTerms = input.boolean(
      'reviewDeclaration.agreesToTerms',
    );
    draft.evaluationPermitStatus.selectedPaymentMethod = input.enumValue(
      'evaluationPermitStatus.selectedPaymentMethod',
      ElectricalPaymentMethod.values,
    );
    draft.useApplicantAddressForProjectLocation = input.boolean(
      'useApplicantAddressForProjectLocation',
    );
    // Not read back: a restored draft is always a draft. Honouring a
    // stored `submitted` would resurrect a filed application as editable.
    draft.status = ElectricalPermitDraftStatus.draft;
    draft.lastSavedAt = input.date('lastSavedAt');
  }
}
