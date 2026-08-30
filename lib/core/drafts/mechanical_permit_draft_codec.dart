import '../models/mechanical_permit_model.dart';
import 'draft_snapshot.dart';

/// Mechanical — MechanicalPermitDraft, persisted.
///
/// One of the seventeen wizards converted in M-48 part 2, after the mechanism
/// was proven on the Building Permit and Fencing. Every field the draft
/// declares is captured and read back except the 77 attachment slots,
/// which are dropped and named back to the applicant, and whatever
/// `test/architecture/draft_snapshot_completeness_test.dart` exempts with a
/// reason. That gate fails the day this file falls behind the model.
///
/// Written mechanically from the model's own field declarations and then
/// reviewed, which is why it reads uniformly. The alternative — trusting a
/// generator without a gate — is how 239 fields become 239 chances to
/// drop one silently.
class MechanicalPermitDraftCodec extends DraftCodec<MechanicalPermitDraft> {
  const MechanicalPermitDraftCodec();

  @override
  String get permitKey => 'mechanical-permit';

  @override
  String get permitLabel => 'Mechanical';

  @override
  void capture(MechanicalPermitDraft draft, SnapshotWriter out) {
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
      'scopeOfWork.existingMechanicalCondition',
      draft.scopeOfWork.existingMechanicalCondition,
    );
    out.scalar(
      'scopeOfWork.proposedMechanicalChanges',
      draft.scopeOfWork.proposedMechanicalChanges,
    );
    out.scalar('scopeOfWork.areasAffected', draft.scopeOfWork.areasAffected);
    out.enumSet(
      'installationDetails.selectedEquipment',
      draft.installationDetails.selectedEquipment,
    );
    out.scalar(
      'installationDetails.otherEquipmentDescription',
      draft.installationDetails.otherEquipmentDescription,
    );
    out.scalar(
      'installationDetails.totalEstimatedProjectCost',
      draft.installationDetails.totalEstimatedProjectCost,
    );
    out.date(
      'installationDetails.proposedStartDate',
      draft.installationDetails.proposedStartDate,
    );
    out.date(
      'installationDetails.expectedCompletionDate',
      draft.installationDetails.expectedCompletionDate,
    );
    out.scalar(
      'installationDetails.existingSystemDescription',
      draft.installationDetails.existingSystemDescription,
    );
    out.scalar(
      'installationDetails.proposedSystemDescription',
      draft.installationDetails.proposedSystemDescription,
    );
    out.scalar(
      'installationDetails.intendedUse',
      draft.installationDetails.intendedUse,
    );
    out.scalar(
      'installationDetails.equipmentLocation',
      draft.installationDetails.equipmentLocation,
    );
    out.scalar(
      'installationDetails.numberOfEquipmentUnits',
      draft.installationDetails.numberOfEquipmentUnits,
    );
    out.scalar(
      'installationDetails.fsNumberOfSprinklerHeads',
      draft.installationDetails.fsNumberOfSprinklerHeads,
    );
    out.scalar(
      'installationDetails.fsDesignCoverageArea',
      draft.installationDetails.fsDesignCoverageArea,
    );
    out.scalar(
      'installationDetails.fsWaterSource',
      draft.installationDetails.fsWaterSource,
    );
    out.scalar(
      'installationDetails.fsPumpCapacity',
      draft.installationDetails.fsPumpCapacity,
    );
    out.scalar(
      'installationDetails.fsSystemType',
      draft.installationDetails.fsSystemType,
    );
    out.scalar(
      'installationDetails.boilerType',
      draft.installationDetails.boilerType,
    );
    out.scalar(
      'installationDetails.boilerRatedCapacity',
      draft.installationDetails.boilerRatedCapacity,
    );
    out.scalar(
      'installationDetails.boilerOperatingPressure',
      draft.installationDetails.boilerOperatingPressure,
    );
    out.scalar(
      'installationDetails.boilerFuelType',
      draft.installationDetails.boilerFuelType,
    );
    out.scalar(
      'installationDetails.boilerNumberOfUnits',
      draft.installationDetails.boilerNumberOfUnits,
    );
    out.scalar(
      'installationDetails.pvVesselType',
      draft.installationDetails.pvVesselType,
    );
    out.scalar(
      'installationDetails.pvVolumeOrCapacity',
      draft.installationDetails.pvVolumeOrCapacity,
    );
    out.scalar(
      'installationDetails.pvMaxAllowableWorkingPressure',
      draft.installationDetails.pvMaxAllowableWorkingPressure,
    );
    out.scalar(
      'installationDetails.pvOperatingTemperature',
      draft.installationDetails.pvOperatingTemperature,
    );
    out.scalar(
      'installationDetails.pvNumberOfUnits',
      draft.installationDetails.pvNumberOfUnits,
    );
    out.scalar(
      'installationDetails.iceEngineType',
      draft.installationDetails.iceEngineType,
    );
    out.scalar(
      'installationDetails.iceRatedPower',
      draft.installationDetails.iceRatedPower,
    );
    out.scalar(
      'installationDetails.iceFuelType',
      draft.installationDetails.iceFuelType,
    );
    out.scalar(
      'installationDetails.iceNumberOfUnits',
      draft.installationDetails.iceNumberOfUnits,
    );
    out.scalar(
      'installationDetails.iceIntendedUse',
      draft.installationDetails.iceIntendedUse,
    );
    out.scalar(
      'installationDetails.refrigSystemType',
      draft.installationDetails.refrigSystemType,
    );
    out.scalar(
      'installationDetails.refrigRefrigerantType',
      draft.installationDetails.refrigRefrigerantType,
    );
    out.scalar(
      'installationDetails.refrigCoolingCapacity',
      draft.installationDetails.refrigCoolingCapacity,
    );
    out.scalar(
      'installationDetails.refrigStorageVolume',
      draft.installationDetails.refrigStorageVolume,
    );
    out.scalar(
      'installationDetails.refrigNumberOfUnits',
      draft.installationDetails.refrigNumberOfUnits,
    );
    out.scalar('installationDetails.acType', draft.installationDetails.acType);
    out.scalar(
      'installationDetails.acNumberOfUnits',
      draft.installationDetails.acNumberOfUnits,
    );
    out.scalar(
      'installationDetails.acCoolingCapacityPerUnit',
      draft.installationDetails.acCoolingCapacityPerUnit,
    );
    out.scalar(
      'installationDetails.acTotalCoolingCapacity',
      draft.installationDetails.acTotalCoolingCapacity,
    );
    out.scalar(
      'installationDetails.acRefrigerantType',
      draft.installationDetails.acRefrigerantType,
    );
    out.scalar(
      'installationDetails.acServedArea',
      draft.installationDetails.acServedArea,
    );
    out.scalar(
      'installationDetails.ventType',
      draft.installationDetails.ventType,
    );
    out.scalar(
      'installationDetails.ventAirflowCapacity',
      draft.installationDetails.ventAirflowCapacity,
    );
    out.scalar(
      'installationDetails.ventNumberOfFans',
      draft.installationDetails.ventNumberOfFans,
    );
    out.scalar(
      'installationDetails.ventServedArea',
      draft.installationDetails.ventServedArea,
    );
    out.scalar(
      'installationDetails.ventExhaustLocation',
      draft.installationDetails.ventExhaustLocation,
    );
    out.enumValue(
      'installationDetails.pipingServiceType',
      draft.installationDetails.pipingServiceType,
    );
    out.scalar(
      'installationDetails.pipingPipeMaterial',
      draft.installationDetails.pipingPipeMaterial,
    );
    out.scalar(
      'installationDetails.pipingDesignPressure',
      draft.installationDetails.pipingDesignPressure,
    );
    out.scalar(
      'installationDetails.pipingPipeDiameter',
      draft.installationDetails.pipingPipeDiameter,
    );
    out.scalar(
      'installationDetails.pipingApproximateLength',
      draft.installationDetails.pipingApproximateLength,
    );
    out.scalar(
      'installationDetails.elevEquipmentType',
      draft.installationDetails.elevEquipmentType,
    );
    out.scalar(
      'installationDetails.elevRatedCapacity',
      draft.installationDetails.elevRatedCapacity,
    );
    out.scalar(
      'installationDetails.elevRatedSpeed',
      draft.installationDetails.elevRatedSpeed,
    );
    out.scalar(
      'installationDetails.elevNumberOfStops',
      draft.installationDetails.elevNumberOfStops,
    );
    out.scalar(
      'installationDetails.elevTravelDistance',
      draft.installationDetails.elevTravelDistance,
    );
    out.scalar(
      'installationDetails.elevNumberOfUnits',
      draft.installationDetails.elevNumberOfUnits,
    );
    out.scalar(
      'installationDetails.elevManufacturer',
      draft.installationDetails.elevManufacturer,
    );
    out.scalar(
      'installationDetails.pumpsType',
      draft.installationDetails.pumpsType,
    );
    out.scalar(
      'installationDetails.pumpsCapacity',
      draft.installationDetails.pumpsCapacity,
    );
    out.scalar(
      'installationDetails.pumpsTotalHead',
      draft.installationDetails.pumpsTotalHead,
    );
    out.scalar(
      'installationDetails.pumpsMotorRating',
      draft.installationDetails.pumpsMotorRating,
    );
    out.scalar(
      'installationDetails.pumpsNumberOfUnits',
      draft.installationDetails.pumpsNumberOfUnits,
    );
    out.scalar(
      'installationDetails.pwhHeaterType',
      draft.installationDetails.pwhHeaterType,
    );
    out.scalar(
      'installationDetails.pwhTankCapacity',
      draft.installationDetails.pwhTankCapacity,
    );
    out.scalar(
      'installationDetails.pwhPressureRating',
      draft.installationDetails.pwhPressureRating,
    );
    out.scalar(
      'installationDetails.pwhHeatingCapacity',
      draft.installationDetails.pwhHeatingCapacity,
    );
    out.scalar(
      'installationDetails.pwhNumberOfUnits',
      draft.installationDetails.pwhNumberOfUnits,
    );
    out.scalar(
      'installationDetails.cavSystemType',
      draft.installationDetails.cavSystemType,
    );
    out.scalar(
      'installationDetails.cavOperatingPressure',
      draft.installationDetails.cavOperatingPressure,
    );
    out.scalar(
      'installationDetails.cavCapacity',
      draft.installationDetails.cavCapacity,
    );
    out.scalar(
      'installationDetails.cavNumberOfEquipmentUnits',
      draft.installationDetails.cavNumberOfEquipmentUnits,
    );
    out.scalar(
      'installationDetails.cavServedArea',
      draft.installationDetails.cavServedArea,
    );
    out.scalar(
      'installationDetails.gasType',
      draft.installationDetails.gasType,
    );
    out.scalar(
      'installationDetails.gasStorageCapacity',
      draft.installationDetails.gasStorageCapacity,
    );
    out.scalar(
      'installationDetails.gasOperatingPressure',
      draft.installationDetails.gasOperatingPressure,
    );
    out.scalar(
      'installationDetails.gasServedArea',
      draft.installationDetails.gasServedArea,
    );
    out.scalar(
      'installationDetails.gasSafetyControlDescription',
      draft.installationDetails.gasSafetyControlDescription,
    );
    out.scalar(
      'installationDetails.convSystemType',
      draft.installationDetails.convSystemType,
    );
    out.scalar(
      'installationDetails.convRatedCapacity',
      draft.installationDetails.convRatedCapacity,
    );
    out.scalar(
      'installationDetails.convTravelLength',
      draft.installationDetails.convTravelLength,
    );
    out.scalar(
      'installationDetails.convSpeed',
      draft.installationDetails.convSpeed,
    );
    out.scalar(
      'installationDetails.convNumberOfStations',
      draft.installationDetails.convNumberOfStations,
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
      'requiredDocuments.equipmentLayoutUpload',
      draft.requiredDocuments.equipmentLayoutUpload,
      'Equipment Layout',
    );
    out.document(
      'requiredDocuments.schematicDiagramsUpload',
      draft.requiredDocuments.schematicDiagramsUpload,
      'Schematic Diagrams',
    );
    out.document(
      'requiredDocuments.equipmentSchedulesUpload',
      draft.requiredDocuments.equipmentSchedulesUpload,
      'Equipment Schedules',
    );
    out.document(
      'requiredDocuments.controlDiagramsUpload',
      draft.requiredDocuments.controlDiagramsUpload,
      'Control Diagrams',
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
      'requiredDocuments.equipmentSpecificationsUpload',
      draft.requiredDocuments.equipmentSpecificationsUpload,
      'Equipment Specifications',
    );
    out.document(
      'requiredDocuments.manufacturerDataSheetsUpload',
      draft.requiredDocuments.manufacturerDataSheetsUpload,
      'Manufacturer Data Sheets',
    );
    out.document(
      'requiredDocuments.sprinklerLayoutUpload',
      draft.requiredDocuments.sprinklerLayoutUpload,
      'Sprinkler Layout',
    );
    out.document(
      'requiredDocuments.hydraulicCalculationsUpload',
      draft.requiredDocuments.hydraulicCalculationsUpload,
      'Hydraulic Calculations',
    );
    out.document(
      'requiredDocuments.pumpDetailsUpload',
      draft.requiredDocuments.pumpDetailsUpload,
      'Pump Details',
    );
    out.document(
      'requiredDocuments.waterSupplyDetailsUpload',
      draft.requiredDocuments.waterSupplyDetailsUpload,
      'Water Supply Details',
    );
    out.document(
      'requiredDocuments.boilerLayoutUpload',
      draft.requiredDocuments.boilerLayoutUpload,
      'Boiler Layout',
    );
    out.document(
      'requiredDocuments.boilerSpecificationsUpload',
      draft.requiredDocuments.boilerSpecificationsUpload,
      'Boiler Specifications',
    );
    out.document(
      'requiredDocuments.pressureCapacityCalculationsUpload',
      draft.requiredDocuments.pressureCapacityCalculationsUpload,
      'Pressure Capacity Calculations',
    );
    out.document(
      'requiredDocuments.safetyControlDetailsUpload',
      draft.requiredDocuments.safetyControlDetailsUpload,
      'Safety Control Details',
    );
    out.document(
      'requiredDocuments.vesselDrawingsUpload',
      draft.requiredDocuments.vesselDrawingsUpload,
      'Vessel Drawings',
    );
    out.document(
      'requiredDocuments.pressureCalculationsUpload',
      draft.requiredDocuments.pressureCalculationsUpload,
      'Pressure Calculations',
    );
    out.document(
      'requiredDocuments.safetyValveDetailsUpload',
      draft.requiredDocuments.safetyValveDetailsUpload,
      'Safety Valve Details',
    );
    out.document(
      'requiredDocuments.manufacturerCertificationUpload',
      draft.requiredDocuments.manufacturerCertificationUpload,
      'Manufacturer Certification',
    );
    out.document(
      'requiredDocuments.refrigerationLayoutUpload',
      draft.requiredDocuments.refrigerationLayoutUpload,
      'Refrigeration Layout',
    );
    out.document(
      'requiredDocuments.refrigerantPipingDiagramUpload',
      draft.requiredDocuments.refrigerantPipingDiagramUpload,
      'Refrigerant Piping Diagram',
    );
    out.document(
      'requiredDocuments.coolingLoadCalculationsUpload',
      draft.requiredDocuments.coolingLoadCalculationsUpload,
      'Cooling Load Calculations',
    );
    out.document(
      'requiredDocuments.refrigerationEquipmentSpecificationsUpload',
      draft.requiredDocuments.refrigerationEquipmentSpecificationsUpload,
      'Refrigeration Equipment Specifications',
    );
    out.document(
      'requiredDocuments.airConditioningLayoutUpload',
      draft.requiredDocuments.airConditioningLayoutUpload,
      'Air Conditioning Layout',
    );
    out.document(
      'requiredDocuments.acCoolingLoadCalculationsUpload',
      draft.requiredDocuments.acCoolingLoadCalculationsUpload,
      'AC Cooling Load Calculations',
    );
    out.document(
      'requiredDocuments.ductLayoutUpload',
      draft.requiredDocuments.ductLayoutUpload,
      'Duct Layout',
    );
    out.document(
      'requiredDocuments.acRefrigerantPipingLayoutUpload',
      draft.requiredDocuments.acRefrigerantPipingLayoutUpload,
      'AC Refrigerant Piping Layout',
    );
    out.document(
      'requiredDocuments.acEquipmentScheduleUpload',
      draft.requiredDocuments.acEquipmentScheduleUpload,
      'AC Equipment Schedule',
    );
    out.document(
      'requiredDocuments.ventilationLayoutUpload',
      draft.requiredDocuments.ventilationLayoutUpload,
      'Ventilation Layout',
    );
    out.document(
      'requiredDocuments.airflowCalculationsUpload',
      draft.requiredDocuments.airflowCalculationsUpload,
      'Airflow Calculations',
    );
    out.document(
      'requiredDocuments.fanScheduleUpload',
      draft.requiredDocuments.fanScheduleUpload,
      'Fan Schedule',
    );
    out.document(
      'requiredDocuments.exhaustDetailsUpload',
      draft.requiredDocuments.exhaustDetailsUpload,
      'Exhaust Details',
    );
    out.document(
      'requiredDocuments.pipingLayoutUpload',
      draft.requiredDocuments.pipingLayoutUpload,
      'Piping Layout',
    );
    out.document(
      'requiredDocuments.isometricDiagramUpload',
      draft.requiredDocuments.isometricDiagramUpload,
      'Isometric Diagram',
    );
    out.document(
      'requiredDocuments.pipingPressureCalculationsUpload',
      draft.requiredDocuments.pipingPressureCalculationsUpload,
      'Piping Pressure Calculations',
    );
    out.document(
      'requiredDocuments.pipeSpecificationsUpload',
      draft.requiredDocuments.pipeSpecificationsUpload,
      'Pipe Specifications',
    );
    out.document(
      'requiredDocuments.pipingSafetyControlDetailsUpload',
      draft.requiredDocuments.pipingSafetyControlDetailsUpload,
      'Piping Safety Control Details',
    );
    out.document(
      'requiredDocuments.verticalTransportEquipmentLayoutUpload',
      draft.requiredDocuments.verticalTransportEquipmentLayoutUpload,
      'Vertical Transport Equipment Layout',
    );
    out.document(
      'requiredDocuments.shaftOrTravelDetailsUpload',
      draft.requiredDocuments.shaftOrTravelDetailsUpload,
      'Shaft or Travel Details',
    );
    out.document(
      'requiredDocuments.manufacturerSpecificationsUpload',
      draft.requiredDocuments.manufacturerSpecificationsUpload,
      'Manufacturer Specifications',
    );
    out.document(
      'requiredDocuments.structuralInterfaceDetailsUpload',
      draft.requiredDocuments.structuralInterfaceDetailsUpload,
      'Structural Interface Details',
    );
    out.document(
      'requiredDocuments.verticalTransportSafetyDetailsUpload',
      draft.requiredDocuments.verticalTransportSafetyDetailsUpload,
      'Vertical Transport Safety Details',
    );
    out.document(
      'requiredDocuments.pumpLayoutUpload',
      draft.requiredDocuments.pumpLayoutUpload,
      'Pump Layout',
    );
    out.document(
      'requiredDocuments.pumpScheduleUpload',
      draft.requiredDocuments.pumpScheduleUpload,
      'Pump Schedule',
    );
    out.document(
      'requiredDocuments.capacityHeadCalculationsUpload',
      draft.requiredDocuments.capacityHeadCalculationsUpload,
      'Capacity Head Calculations',
    );
    out.document(
      'requiredDocuments.motorSpecificationsUpload',
      draft.requiredDocuments.motorSpecificationsUpload,
      'Motor Specifications',
    );
    out.document(
      'requiredDocuments.cavSystemLayoutUpload',
      draft.requiredDocuments.cavSystemLayoutUpload,
      'CAV System Layout',
    );
    out.document(
      'requiredDocuments.cavPipingDiagramUpload',
      draft.requiredDocuments.cavPipingDiagramUpload,
      'CAV Piping Diagram',
    );
    out.document(
      'requiredDocuments.cavPressureCalculationsUpload',
      draft.requiredDocuments.cavPressureCalculationsUpload,
      'CAV Pressure Calculations',
    );
    out.document(
      'requiredDocuments.cavStorageEquipmentDetailsUpload',
      draft.requiredDocuments.cavStorageEquipmentDetailsUpload,
      'CAV Storage Equipment Details',
    );
    out.document(
      'requiredDocuments.cavSafetyControlDetailsUpload',
      draft.requiredDocuments.cavSafetyControlDetailsUpload,
      'CAV Safety Control Details',
    );
    out.document(
      'requiredDocuments.conveyorSystemLayoutUpload',
      draft.requiredDocuments.conveyorSystemLayoutUpload,
      'Conveyor System Layout',
    );
    out.document(
      'requiredDocuments.conveyorEquipmentSpecificationsUpload',
      draft.requiredDocuments.conveyorEquipmentSpecificationsUpload,
      'Conveyor Equipment Specifications',
    );
    out.document(
      'requiredDocuments.conveyorCapacityCalculationsUpload',
      draft.requiredDocuments.conveyorCapacityCalculationsUpload,
      'Conveyor Capacity Calculations',
    );
    out.document(
      'requiredDocuments.conveyorControlSafetyDetailsUpload',
      draft.requiredDocuments.conveyorControlSafetyDetailsUpload,
      'Conveyor Control Safety Details',
    );
    out.document(
      'requiredDocuments.relatedBuildingPermitUpload',
      draft.requiredDocuments.relatedBuildingPermitUpload,
      'Related Building Permit',
    );
    out.document(
      'requiredDocuments.equipmentCertificationsUpload',
      draft.requiredDocuments.equipmentCertificationsUpload,
      'Equipment Certifications',
    );
    out.document(
      'requiredDocuments.manufacturerCertificationsUpload',
      draft.requiredDocuments.manufacturerCertificationsUpload,
      'Manufacturer Certifications',
    );
    out.document(
      'requiredDocuments.testingCommissioningPlanUpload',
      draft.requiredDocuments.testingCommissioningPlanUpload,
      'Testing Commissioning Plan',
    );
    out.document(
      'requiredDocuments.installationScheduleUpload',
      draft.requiredDocuments.installationScheduleUpload,
      'Installation Schedule',
    );
    out.document(
      'requiredDocuments.otherMechanicalDocumentsUpload',
      draft.requiredDocuments.otherMechanicalDocumentsUpload,
      'Other Mechanical Documents',
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
      'reviewDeclaration.understandsCertificateOfOperationRequired',
      draft.reviewDeclaration.understandsCertificateOfOperationRequired,
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
  void restore(MechanicalPermitDraft draft, SnapshotReader input) {
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
      MechanicalOccupancyGroup.values,
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
        input.enumSet('scopeOfWork.selectedScopes', MechanicalScopeType.values),
      );
    draft.scopeOfWork.otherScopeDescription = input.string(
      'scopeOfWork.otherScopeDescription',
    );
    draft.scopeOfWork.workTitle = input.string('scopeOfWork.workTitle');
    draft.scopeOfWork.generalDescription = input.string(
      'scopeOfWork.generalDescription',
    );
    draft.scopeOfWork.existingMechanicalCondition = input.string(
      'scopeOfWork.existingMechanicalCondition',
    );
    draft.scopeOfWork.proposedMechanicalChanges = input.string(
      'scopeOfWork.proposedMechanicalChanges',
    );
    draft.scopeOfWork.areasAffected = input.string('scopeOfWork.areasAffected');
    draft.installationDetails.selectedEquipment
      ..clear()
      ..addAll(
        input.enumSet(
          'installationDetails.selectedEquipment',
          MechanicalEquipmentType.values,
        ),
      );
    draft.installationDetails.otherEquipmentDescription = input.string(
      'installationDetails.otherEquipmentDescription',
    );
    draft.installationDetails.totalEstimatedProjectCost = input.string(
      'installationDetails.totalEstimatedProjectCost',
    );
    draft.installationDetails.proposedStartDate = input.date(
      'installationDetails.proposedStartDate',
    );
    draft.installationDetails.expectedCompletionDate = input.date(
      'installationDetails.expectedCompletionDate',
    );
    draft.installationDetails.existingSystemDescription = input.string(
      'installationDetails.existingSystemDescription',
    );
    draft.installationDetails.proposedSystemDescription = input.string(
      'installationDetails.proposedSystemDescription',
    );
    draft.installationDetails.intendedUse = input.string(
      'installationDetails.intendedUse',
    );
    draft.installationDetails.equipmentLocation = input.string(
      'installationDetails.equipmentLocation',
    );
    draft.installationDetails.numberOfEquipmentUnits = input.string(
      'installationDetails.numberOfEquipmentUnits',
    );
    draft.installationDetails.fsNumberOfSprinklerHeads = input.string(
      'installationDetails.fsNumberOfSprinklerHeads',
    );
    draft.installationDetails.fsDesignCoverageArea = input.string(
      'installationDetails.fsDesignCoverageArea',
    );
    draft.installationDetails.fsWaterSource = input.string(
      'installationDetails.fsWaterSource',
    );
    draft.installationDetails.fsPumpCapacity = input.string(
      'installationDetails.fsPumpCapacity',
    );
    draft.installationDetails.fsSystemType = input.string(
      'installationDetails.fsSystemType',
    );
    draft.installationDetails.boilerType = input.string(
      'installationDetails.boilerType',
    );
    draft.installationDetails.boilerRatedCapacity = input.string(
      'installationDetails.boilerRatedCapacity',
    );
    draft.installationDetails.boilerOperatingPressure = input.string(
      'installationDetails.boilerOperatingPressure',
    );
    draft.installationDetails.boilerFuelType = input.string(
      'installationDetails.boilerFuelType',
    );
    draft.installationDetails.boilerNumberOfUnits = input.string(
      'installationDetails.boilerNumberOfUnits',
    );
    draft.installationDetails.pvVesselType = input.string(
      'installationDetails.pvVesselType',
    );
    draft.installationDetails.pvVolumeOrCapacity = input.string(
      'installationDetails.pvVolumeOrCapacity',
    );
    draft.installationDetails.pvMaxAllowableWorkingPressure = input.string(
      'installationDetails.pvMaxAllowableWorkingPressure',
    );
    draft.installationDetails.pvOperatingTemperature = input.string(
      'installationDetails.pvOperatingTemperature',
    );
    draft.installationDetails.pvNumberOfUnits = input.string(
      'installationDetails.pvNumberOfUnits',
    );
    draft.installationDetails.iceEngineType = input.string(
      'installationDetails.iceEngineType',
    );
    draft.installationDetails.iceRatedPower = input.string(
      'installationDetails.iceRatedPower',
    );
    draft.installationDetails.iceFuelType = input.string(
      'installationDetails.iceFuelType',
    );
    draft.installationDetails.iceNumberOfUnits = input.string(
      'installationDetails.iceNumberOfUnits',
    );
    draft.installationDetails.iceIntendedUse = input.string(
      'installationDetails.iceIntendedUse',
    );
    draft.installationDetails.refrigSystemType = input.string(
      'installationDetails.refrigSystemType',
    );
    draft.installationDetails.refrigRefrigerantType = input.string(
      'installationDetails.refrigRefrigerantType',
    );
    draft.installationDetails.refrigCoolingCapacity = input.string(
      'installationDetails.refrigCoolingCapacity',
    );
    draft.installationDetails.refrigStorageVolume = input.string(
      'installationDetails.refrigStorageVolume',
    );
    draft.installationDetails.refrigNumberOfUnits = input.string(
      'installationDetails.refrigNumberOfUnits',
    );
    draft.installationDetails.acType = input.string(
      'installationDetails.acType',
    );
    draft.installationDetails.acNumberOfUnits = input.string(
      'installationDetails.acNumberOfUnits',
    );
    draft.installationDetails.acCoolingCapacityPerUnit = input.string(
      'installationDetails.acCoolingCapacityPerUnit',
    );
    draft.installationDetails.acTotalCoolingCapacity = input.string(
      'installationDetails.acTotalCoolingCapacity',
    );
    draft.installationDetails.acRefrigerantType = input.string(
      'installationDetails.acRefrigerantType',
    );
    draft.installationDetails.acServedArea = input.string(
      'installationDetails.acServedArea',
    );
    draft.installationDetails.ventType = input.string(
      'installationDetails.ventType',
    );
    draft.installationDetails.ventAirflowCapacity = input.string(
      'installationDetails.ventAirflowCapacity',
    );
    draft.installationDetails.ventNumberOfFans = input.string(
      'installationDetails.ventNumberOfFans',
    );
    draft.installationDetails.ventServedArea = input.string(
      'installationDetails.ventServedArea',
    );
    draft.installationDetails.ventExhaustLocation = input.string(
      'installationDetails.ventExhaustLocation',
    );
    draft.installationDetails.pipingServiceType = input.enumValue(
      'installationDetails.pipingServiceType',
      PowerPipingServiceType.values,
    );
    draft.installationDetails.pipingPipeMaterial = input.string(
      'installationDetails.pipingPipeMaterial',
    );
    draft.installationDetails.pipingDesignPressure = input.string(
      'installationDetails.pipingDesignPressure',
    );
    draft.installationDetails.pipingPipeDiameter = input.string(
      'installationDetails.pipingPipeDiameter',
    );
    draft.installationDetails.pipingApproximateLength = input.string(
      'installationDetails.pipingApproximateLength',
    );
    draft.installationDetails.elevEquipmentType = input.string(
      'installationDetails.elevEquipmentType',
    );
    draft.installationDetails.elevRatedCapacity = input.string(
      'installationDetails.elevRatedCapacity',
    );
    draft.installationDetails.elevRatedSpeed = input.string(
      'installationDetails.elevRatedSpeed',
    );
    draft.installationDetails.elevNumberOfStops = input.string(
      'installationDetails.elevNumberOfStops',
    );
    draft.installationDetails.elevTravelDistance = input.string(
      'installationDetails.elevTravelDistance',
    );
    draft.installationDetails.elevNumberOfUnits = input.string(
      'installationDetails.elevNumberOfUnits',
    );
    draft.installationDetails.elevManufacturer = input.string(
      'installationDetails.elevManufacturer',
    );
    draft.installationDetails.pumpsType = input.string(
      'installationDetails.pumpsType',
    );
    draft.installationDetails.pumpsCapacity = input.string(
      'installationDetails.pumpsCapacity',
    );
    draft.installationDetails.pumpsTotalHead = input.string(
      'installationDetails.pumpsTotalHead',
    );
    draft.installationDetails.pumpsMotorRating = input.string(
      'installationDetails.pumpsMotorRating',
    );
    draft.installationDetails.pumpsNumberOfUnits = input.string(
      'installationDetails.pumpsNumberOfUnits',
    );
    draft.installationDetails.pwhHeaterType = input.string(
      'installationDetails.pwhHeaterType',
    );
    draft.installationDetails.pwhTankCapacity = input.string(
      'installationDetails.pwhTankCapacity',
    );
    draft.installationDetails.pwhPressureRating = input.string(
      'installationDetails.pwhPressureRating',
    );
    draft.installationDetails.pwhHeatingCapacity = input.string(
      'installationDetails.pwhHeatingCapacity',
    );
    draft.installationDetails.pwhNumberOfUnits = input.string(
      'installationDetails.pwhNumberOfUnits',
    );
    draft.installationDetails.cavSystemType = input.string(
      'installationDetails.cavSystemType',
    );
    draft.installationDetails.cavOperatingPressure = input.string(
      'installationDetails.cavOperatingPressure',
    );
    draft.installationDetails.cavCapacity = input.string(
      'installationDetails.cavCapacity',
    );
    draft.installationDetails.cavNumberOfEquipmentUnits = input.string(
      'installationDetails.cavNumberOfEquipmentUnits',
    );
    draft.installationDetails.cavServedArea = input.string(
      'installationDetails.cavServedArea',
    );
    draft.installationDetails.gasType = input.string(
      'installationDetails.gasType',
    );
    draft.installationDetails.gasStorageCapacity = input.string(
      'installationDetails.gasStorageCapacity',
    );
    draft.installationDetails.gasOperatingPressure = input.string(
      'installationDetails.gasOperatingPressure',
    );
    draft.installationDetails.gasServedArea = input.string(
      'installationDetails.gasServedArea',
    );
    draft.installationDetails.gasSafetyControlDescription = input.string(
      'installationDetails.gasSafetyControlDescription',
    );
    draft.installationDetails.convSystemType = input.string(
      'installationDetails.convSystemType',
    );
    draft.installationDetails.convRatedCapacity = input.string(
      'installationDetails.convRatedCapacity',
    );
    draft.installationDetails.convTravelLength = input.string(
      'installationDetails.convTravelLength',
    );
    draft.installationDetails.convSpeed = input.string(
      'installationDetails.convSpeed',
    );
    draft.installationDetails.convNumberOfStations = input.string(
      'installationDetails.convNumberOfStations',
    );
    draft.professionals.designProfessional.fullName = input.string(
      'professionals.designProfessional.fullName',
    );
    draft.professionals.designProfessional.profession = input.enumValue(
      'professionals.designProfessional.profession',
      MechanicalProfessionType.values,
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
    draft.professionals.supervisor.profession = input.enumValue(
      'professionals.supervisor.profession',
      MechanicalProfessionType.values,
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
    draft.requiredDocuments.equipmentLayoutUpload = input.document(
      'requiredDocuments.equipmentLayoutUpload',
    );
    draft.requiredDocuments.schematicDiagramsUpload = input.document(
      'requiredDocuments.schematicDiagramsUpload',
    );
    draft.requiredDocuments.equipmentSchedulesUpload = input.document(
      'requiredDocuments.equipmentSchedulesUpload',
    );
    draft.requiredDocuments.controlDiagramsUpload = input.document(
      'requiredDocuments.controlDiagramsUpload',
    );
    draft.requiredDocuments.generalNotesUpload = input.document(
      'requiredDocuments.generalNotesUpload',
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
    draft.requiredDocuments.equipmentSpecificationsUpload = input.document(
      'requiredDocuments.equipmentSpecificationsUpload',
    );
    draft.requiredDocuments.manufacturerDataSheetsUpload = input.document(
      'requiredDocuments.manufacturerDataSheetsUpload',
    );
    draft.requiredDocuments.sprinklerLayoutUpload = input.document(
      'requiredDocuments.sprinklerLayoutUpload',
    );
    draft.requiredDocuments.hydraulicCalculationsUpload = input.document(
      'requiredDocuments.hydraulicCalculationsUpload',
    );
    draft.requiredDocuments.pumpDetailsUpload = input.document(
      'requiredDocuments.pumpDetailsUpload',
    );
    draft.requiredDocuments.waterSupplyDetailsUpload = input.document(
      'requiredDocuments.waterSupplyDetailsUpload',
    );
    draft.requiredDocuments.boilerLayoutUpload = input.document(
      'requiredDocuments.boilerLayoutUpload',
    );
    draft.requiredDocuments.boilerSpecificationsUpload = input.document(
      'requiredDocuments.boilerSpecificationsUpload',
    );
    draft.requiredDocuments.pressureCapacityCalculationsUpload = input.document(
      'requiredDocuments.pressureCapacityCalculationsUpload',
    );
    draft.requiredDocuments.safetyControlDetailsUpload = input.document(
      'requiredDocuments.safetyControlDetailsUpload',
    );
    draft.requiredDocuments.vesselDrawingsUpload = input.document(
      'requiredDocuments.vesselDrawingsUpload',
    );
    draft.requiredDocuments.pressureCalculationsUpload = input.document(
      'requiredDocuments.pressureCalculationsUpload',
    );
    draft.requiredDocuments.safetyValveDetailsUpload = input.document(
      'requiredDocuments.safetyValveDetailsUpload',
    );
    draft.requiredDocuments.manufacturerCertificationUpload = input.document(
      'requiredDocuments.manufacturerCertificationUpload',
    );
    draft.requiredDocuments.refrigerationLayoutUpload = input.document(
      'requiredDocuments.refrigerationLayoutUpload',
    );
    draft.requiredDocuments.refrigerantPipingDiagramUpload = input.document(
      'requiredDocuments.refrigerantPipingDiagramUpload',
    );
    draft.requiredDocuments.coolingLoadCalculationsUpload = input.document(
      'requiredDocuments.coolingLoadCalculationsUpload',
    );
    draft.requiredDocuments.refrigerationEquipmentSpecificationsUpload = input
        .document(
          'requiredDocuments.refrigerationEquipmentSpecificationsUpload',
        );
    draft.requiredDocuments.airConditioningLayoutUpload = input.document(
      'requiredDocuments.airConditioningLayoutUpload',
    );
    draft.requiredDocuments.acCoolingLoadCalculationsUpload = input.document(
      'requiredDocuments.acCoolingLoadCalculationsUpload',
    );
    draft.requiredDocuments.ductLayoutUpload = input.document(
      'requiredDocuments.ductLayoutUpload',
    );
    draft.requiredDocuments.acRefrigerantPipingLayoutUpload = input.document(
      'requiredDocuments.acRefrigerantPipingLayoutUpload',
    );
    draft.requiredDocuments.acEquipmentScheduleUpload = input.document(
      'requiredDocuments.acEquipmentScheduleUpload',
    );
    draft.requiredDocuments.ventilationLayoutUpload = input.document(
      'requiredDocuments.ventilationLayoutUpload',
    );
    draft.requiredDocuments.airflowCalculationsUpload = input.document(
      'requiredDocuments.airflowCalculationsUpload',
    );
    draft.requiredDocuments.fanScheduleUpload = input.document(
      'requiredDocuments.fanScheduleUpload',
    );
    draft.requiredDocuments.exhaustDetailsUpload = input.document(
      'requiredDocuments.exhaustDetailsUpload',
    );
    draft.requiredDocuments.pipingLayoutUpload = input.document(
      'requiredDocuments.pipingLayoutUpload',
    );
    draft.requiredDocuments.isometricDiagramUpload = input.document(
      'requiredDocuments.isometricDiagramUpload',
    );
    draft.requiredDocuments.pipingPressureCalculationsUpload = input.document(
      'requiredDocuments.pipingPressureCalculationsUpload',
    );
    draft.requiredDocuments.pipeSpecificationsUpload = input.document(
      'requiredDocuments.pipeSpecificationsUpload',
    );
    draft.requiredDocuments.pipingSafetyControlDetailsUpload = input.document(
      'requiredDocuments.pipingSafetyControlDetailsUpload',
    );
    draft.requiredDocuments.verticalTransportEquipmentLayoutUpload = input
        .document('requiredDocuments.verticalTransportEquipmentLayoutUpload');
    draft.requiredDocuments.shaftOrTravelDetailsUpload = input.document(
      'requiredDocuments.shaftOrTravelDetailsUpload',
    );
    draft.requiredDocuments.manufacturerSpecificationsUpload = input.document(
      'requiredDocuments.manufacturerSpecificationsUpload',
    );
    draft.requiredDocuments.structuralInterfaceDetailsUpload = input.document(
      'requiredDocuments.structuralInterfaceDetailsUpload',
    );
    draft.requiredDocuments.verticalTransportSafetyDetailsUpload = input
        .document('requiredDocuments.verticalTransportSafetyDetailsUpload');
    draft.requiredDocuments.pumpLayoutUpload = input.document(
      'requiredDocuments.pumpLayoutUpload',
    );
    draft.requiredDocuments.pumpScheduleUpload = input.document(
      'requiredDocuments.pumpScheduleUpload',
    );
    draft.requiredDocuments.capacityHeadCalculationsUpload = input.document(
      'requiredDocuments.capacityHeadCalculationsUpload',
    );
    draft.requiredDocuments.motorSpecificationsUpload = input.document(
      'requiredDocuments.motorSpecificationsUpload',
    );
    draft.requiredDocuments.cavSystemLayoutUpload = input.document(
      'requiredDocuments.cavSystemLayoutUpload',
    );
    draft.requiredDocuments.cavPipingDiagramUpload = input.document(
      'requiredDocuments.cavPipingDiagramUpload',
    );
    draft.requiredDocuments.cavPressureCalculationsUpload = input.document(
      'requiredDocuments.cavPressureCalculationsUpload',
    );
    draft.requiredDocuments.cavStorageEquipmentDetailsUpload = input.document(
      'requiredDocuments.cavStorageEquipmentDetailsUpload',
    );
    draft.requiredDocuments.cavSafetyControlDetailsUpload = input.document(
      'requiredDocuments.cavSafetyControlDetailsUpload',
    );
    draft.requiredDocuments.conveyorSystemLayoutUpload = input.document(
      'requiredDocuments.conveyorSystemLayoutUpload',
    );
    draft.requiredDocuments.conveyorEquipmentSpecificationsUpload = input
        .document('requiredDocuments.conveyorEquipmentSpecificationsUpload');
    draft.requiredDocuments.conveyorCapacityCalculationsUpload = input.document(
      'requiredDocuments.conveyorCapacityCalculationsUpload',
    );
    draft.requiredDocuments.conveyorControlSafetyDetailsUpload = input.document(
      'requiredDocuments.conveyorControlSafetyDetailsUpload',
    );
    draft.requiredDocuments.relatedBuildingPermitUpload = input.document(
      'requiredDocuments.relatedBuildingPermitUpload',
    );
    draft.requiredDocuments.equipmentCertificationsUpload = input.document(
      'requiredDocuments.equipmentCertificationsUpload',
    );
    draft.requiredDocuments.manufacturerCertificationsUpload = input.document(
      'requiredDocuments.manufacturerCertificationsUpload',
    );
    draft.requiredDocuments.testingCommissioningPlanUpload = input.document(
      'requiredDocuments.testingCommissioningPlanUpload',
    );
    draft.requiredDocuments.installationScheduleUpload = input.document(
      'requiredDocuments.installationScheduleUpload',
    );
    draft.requiredDocuments.otherMechanicalDocumentsUpload = input.document(
      'requiredDocuments.otherMechanicalDocumentsUpload',
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
    draft.reviewDeclaration.understandsCertificateOfOperationRequired = input
        .boolean('reviewDeclaration.understandsCertificateOfOperationRequired');
    draft.reviewDeclaration.agreesToTerms = input.boolean(
      'reviewDeclaration.agreesToTerms',
    );
    draft.useApplicantAddressForProjectLocation = input.boolean(
      'useApplicantAddressForProjectLocation',
    );
    // Not read back: a restored draft is always a draft. Honouring a
    // stored `submitted` would resurrect a filed application as editable.
    draft.status = MechanicalPermitDraftStatus.draft;
    draft.lastSavedAt = input.date('lastSavedAt');
  }
}
