import '../models/civil_structural_permit_model.dart';
import 'draft_snapshot.dart';

/// Civil / Structural — CivilStructuralPermitDraft, persisted.
///
/// One of the seventeen wizards converted in M-48 part 2, after the mechanism
/// was proven on the Building Permit and Fencing. Every field the draft
/// declares is captured and read back except the 60 attachment slots,
/// which are dropped and named back to the applicant, and whatever
/// `test/architecture/draft_snapshot_completeness_test.dart` exempts with a
/// reason. That gate fails the day this file falls behind the model.
///
/// Written mechanically from the model's own field declarations and then
/// reviewed, which is why it reads uniformly. The alternative — trusting a
/// generator without a gate — is how 173 fields become 173 chances to
/// drop one silently.
class CivilStructuralPermitDraftCodec
    extends DraftCodec<CivilStructuralPermitDraft> {
  const CivilStructuralPermitDraftCodec();

  @override
  String get permitKey => 'civil-structural-permit';

  @override
  String get permitLabel => 'Civil / Structural';

  @override
  void capture(CivilStructuralPermitDraft draft, SnapshotWriter out) {
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
      'scopeOfWork.existingStructuralCondition',
      draft.scopeOfWork.existingStructuralCondition,
    );
    out.scalar(
      'scopeOfWork.proposedStructuralChanges',
      draft.scopeOfWork.proposedStructuralChanges,
    );
    out.scalar('scopeOfWork.areasAffected', draft.scopeOfWork.areasAffected);
    out.enumSet('workDetails.selectedWorks', draft.workDetails.selectedWorks);
    out.scalar(
      'workDetails.otherWorkDescription',
      draft.workDetails.otherWorkDescription,
    );
    out.scalar(
      'workDetails.numberOfStoreys',
      draft.workDetails.numberOfStoreys,
    );
    out.scalar(
      'workDetails.totalStructuralFloorArea',
      draft.workDetails.totalStructuralFloorArea,
    );
    out.scalar(
      'workDetails.buildingOrStructureHeight',
      draft.workDetails.buildingOrStructureHeight,
    );
    out.scalar(
      'workDetails.estimatedStructuralCost',
      draft.workDetails.estimatedStructuralCost,
    );
    out.date(
      'workDetails.proposedStartDate',
      draft.workDetails.proposedStartDate,
    );
    out.date(
      'workDetails.expectedCompletionDate',
      draft.workDetails.expectedCompletionDate,
    );
    out.scalar(
      'workDetails.excavationDepth',
      draft.workDetails.excavationDepth,
    );
    out.scalar('workDetails.numberOfPiles', draft.workDetails.numberOfPiles);
    out.scalar('workDetails.pileType', draft.workDetails.pileType);
    out.scalar(
      'workDetails.averagePileDepth',
      draft.workDetails.averagePileDepth,
    );
    out.scalar('workDetails.pileCapacity', draft.workDetails.pileCapacity);
    out.scalar('workDetails.foundationType', draft.workDetails.foundationType);
    out.scalar(
      'workDetails.foundationDepth',
      draft.workDetails.foundationDepth,
    );
    out.scalar(
      'workDetails.foundationDescription',
      draft.workDetails.foundationDescription,
    );
    out.scalar(
      'workDetails.concreteStrength',
      draft.workDetails.concreteStrength,
    );
    out.scalar(
      'workDetails.concreteFramingSystemDescription',
      draft.workDetails.concreteFramingSystemDescription,
    );
    out.scalar('workDetails.steelGrade', draft.workDetails.steelGrade);
    out.scalar(
      'workDetails.steelFramingSystemDescription',
      draft.workDetails.steelFramingSystemDescription,
    );
    out.scalar('workDetails.slabType', draft.workDetails.slabType);
    out.scalar(
      'workDetails.typicalSlabThickness',
      draft.workDetails.typicalSlabThickness,
    );
    out.scalar(
      'workDetails.structuralWallType',
      draft.workDetails.structuralWallType,
    );
    out.scalar('workDetails.wallMaterial', draft.workDetails.wallMaterial);
    out.scalar(
      'workDetails.typicalWallThickness',
      draft.workDetails.typicalWallThickness,
    );
    out.scalar(
      'workDetails.prestressingSystemDescription',
      draft.workDetails.prestressingSystemDescription,
    );
    out.scalar(
      'workDetails.testingLaboratory',
      draft.workDetails.testingLaboratory,
    );
    out.scalar('workDetails.plannedTests', draft.workDetails.plannedTests);
    out.scalar('workDetails.testSchedule', draft.workDetails.testSchedule);
    out.scalar('workDetails.towerType', draft.workDetails.towerType);
    out.scalar('workDetails.towerHeight', draft.workDetails.towerHeight);
    out.scalar('workDetails.intendedUse', draft.workDetails.intendedUse);
    out.scalar('workDetails.tankType', draft.workDetails.tankType);
    out.scalar('workDetails.tankCapacity', draft.workDetails.tankCapacity);
    out.scalar('workDetails.tankMaterial', draft.workDetails.tankMaterial);
    out.scalar(
      'professionals.designEngineer.fullName',
      draft.professionals.designEngineer.fullName,
    );
    out.enumValue(
      'professionals.designEngineer.profession',
      draft.professionals.designEngineer.profession,
    );
    out.scalar(
      'professionals.designEngineer.address',
      draft.professionals.designEngineer.address,
    );
    out.scalar(
      'professionals.designEngineer.prcNumber',
      draft.professionals.designEngineer.prcNumber,
    );
    out.date(
      'professionals.designEngineer.prcValidityDate',
      draft.professionals.designEngineer.prcValidityDate,
    );
    out.scalar(
      'professionals.designEngineer.ptrNumber',
      draft.professionals.designEngineer.ptrNumber,
    );
    out.date(
      'professionals.designEngineer.ptrDateIssued',
      draft.professionals.designEngineer.ptrDateIssued,
    );
    out.scalar(
      'professionals.designEngineer.ptrPlaceIssued',
      draft.professionals.designEngineer.ptrPlaceIssued,
    );
    out.scalar(
      'professionals.designEngineer.tin',
      draft.professionals.designEngineer.tin,
    );
    out.date(
      'professionals.designEngineer.dateSigned',
      draft.professionals.designEngineer.dateSigned,
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
      'professionals.signedSealedComputationsUpload',
      draft.professionals.signedSealedComputationsUpload,
      'Signed Sealed Computations',
    );
    out.document(
      'professionals.signedSealedSpecificationsUpload',
      draft.professionals.signedSealedSpecificationsUpload,
      'Signed Sealed Specifications',
    );
    out.scalar(
      'professionals.isSupervisorSameAsDesignEngineer',
      draft.professionals.isSupervisorSameAsDesignEngineer,
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
      'requiredDocuments.structuralAnalysisUpload',
      draft.requiredDocuments.structuralAnalysisUpload,
      'Structural Analysis',
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
      'requiredDocuments.stakingPlanUpload',
      draft.requiredDocuments.stakingPlanUpload,
      'Staking Plan',
    );
    out.document(
      'requiredDocuments.surveyReferenceUpload',
      draft.requiredDocuments.surveyReferenceUpload,
      'Survey Reference',
    );
    out.document(
      'requiredDocuments.excavationPlanUpload',
      draft.requiredDocuments.excavationPlanUpload,
      'Excavation Plan',
    );
    out.document(
      'requiredDocuments.excavationSafetyPlanUpload',
      draft.requiredDocuments.excavationSafetyPlanUpload,
      'Excavation Safety Plan',
    );
    out.document(
      'requiredDocuments.soilStabilizationPlanUpload',
      draft.requiredDocuments.soilStabilizationPlanUpload,
      'Soil Stabilization Plan',
    );
    out.document(
      'requiredDocuments.geotechnicalRecommendationUpload',
      draft.requiredDocuments.geotechnicalRecommendationUpload,
      'Geotechnical Recommendation',
    );
    out.document(
      'requiredDocuments.pilingLayoutUpload',
      draft.requiredDocuments.pilingLayoutUpload,
      'Piling Layout',
    );
    out.document(
      'requiredDocuments.pileDesignCalculationsUpload',
      draft.requiredDocuments.pileDesignCalculationsUpload,
      'Pile Design Calculations',
    );
    out.document(
      'requiredDocuments.pileTestingProgramUpload',
      draft.requiredDocuments.pileTestingProgramUpload,
      'Pile Testing Program',
    );
    out.document(
      'requiredDocuments.foundationPlanUpload',
      draft.requiredDocuments.foundationPlanUpload,
      'Foundation Plan',
    );
    out.document(
      'requiredDocuments.foundationDesignCalculationsUpload',
      draft.requiredDocuments.foundationDesignCalculationsUpload,
      'Foundation Design Calculations',
    );
    out.document(
      'requiredDocuments.erectionPlanUpload',
      draft.requiredDocuments.erectionPlanUpload,
      'Erection Plan',
    );
    out.document(
      'requiredDocuments.liftingPlanUpload',
      draft.requiredDocuments.liftingPlanUpload,
      'Lifting Plan',
    );
    out.document(
      'requiredDocuments.temporarySupportPlanUpload',
      draft.requiredDocuments.temporarySupportPlanUpload,
      'Temporary Support Plan',
    );
    out.document(
      'requiredDocuments.concreteFramingPlansUpload',
      draft.requiredDocuments.concreteFramingPlansUpload,
      'Concrete Framing Plans',
    );
    out.document(
      'requiredDocuments.concreteDesignCalculationsUpload',
      draft.requiredDocuments.concreteDesignCalculationsUpload,
      'Concrete Design Calculations',
    );
    out.document(
      'requiredDocuments.concreteMaterialSpecificationsUpload',
      draft.requiredDocuments.concreteMaterialSpecificationsUpload,
      'Concrete Material Specifications',
    );
    out.document(
      'requiredDocuments.structuralSteelPlansUpload',
      draft.requiredDocuments.structuralSteelPlansUpload,
      'Structural Steel Plans',
    );
    out.document(
      'requiredDocuments.connectionDetailsUpload',
      draft.requiredDocuments.connectionDetailsUpload,
      'Connection Details',
    );
    out.document(
      'requiredDocuments.steelDesignCalculationsUpload',
      draft.requiredDocuments.steelDesignCalculationsUpload,
      'Steel Design Calculations',
    );
    out.document(
      'requiredDocuments.slabPlansUpload',
      draft.requiredDocuments.slabPlansUpload,
      'Slab Plans',
    );
    out.document(
      'requiredDocuments.slabReinforcementDetailsUpload',
      draft.requiredDocuments.slabReinforcementDetailsUpload,
      'Slab Reinforcement Details',
    );
    out.document(
      'requiredDocuments.structuralWallPlansUpload',
      draft.requiredDocuments.structuralWallPlansUpload,
      'Structural Wall Plans',
    );
    out.document(
      'requiredDocuments.wallReinforcementDetailsUpload',
      draft.requiredDocuments.wallReinforcementDetailsUpload,
      'Wall Reinforcement Details',
    );
    out.document(
      'requiredDocuments.prestressingDesignUpload',
      draft.requiredDocuments.prestressingDesignUpload,
      'Prestressing Design',
    );
    out.document(
      'requiredDocuments.prestressingProcedureUpload',
      draft.requiredDocuments.prestressingProcedureUpload,
      'Prestressing Procedure',
    );
    out.document(
      'requiredDocuments.tendonLayoutUpload',
      draft.requiredDocuments.tendonLayoutUpload,
      'Tendon Layout',
    );
    out.document(
      'requiredDocuments.materialTestingProgramUpload',
      draft.requiredDocuments.materialTestingProgramUpload,
      'Material Testing Program',
    );
    out.document(
      'requiredDocuments.testingLaboratoryCredentialsUpload',
      draft.requiredDocuments.testingLaboratoryCredentialsUpload,
      'Testing Laboratory Credentials',
    );
    out.document(
      'requiredDocuments.testReportsUpload',
      draft.requiredDocuments.testReportsUpload,
      'Test Reports',
    );
    out.document(
      'requiredDocuments.towerPlansUpload',
      draft.requiredDocuments.towerPlansUpload,
      'Tower Plans',
    );
    out.document(
      'requiredDocuments.towerDesignCalculationsUpload',
      draft.requiredDocuments.towerDesignCalculationsUpload,
      'Tower Design Calculations',
    );
    out.document(
      'requiredDocuments.towerFoundationDetailsUpload',
      draft.requiredDocuments.towerFoundationDetailsUpload,
      'Tower Foundation Details',
    );
    out.document(
      'requiredDocuments.tankStructuralPlansUpload',
      draft.requiredDocuments.tankStructuralPlansUpload,
      'Tank Structural Plans',
    );
    out.document(
      'requiredDocuments.tankDesignCalculationsUpload',
      draft.requiredDocuments.tankDesignCalculationsUpload,
      'Tank Design Calculations',
    );
    out.document(
      'requiredDocuments.tankFoundationDetailsUpload',
      draft.requiredDocuments.tankFoundationDetailsUpload,
      'Tank Foundation Details',
    );
    out.document(
      'requiredDocuments.relatedBuildingPermitUpload',
      draft.requiredDocuments.relatedBuildingPermitUpload,
      'Related Building Permit',
    );
    out.document(
      'requiredDocuments.geotechnicalOrSoilInvestigationUpload',
      draft.requiredDocuments.geotechnicalOrSoilInvestigationUpload,
      'Geotechnical or Soil Investigation',
    );
    out.document(
      'requiredDocuments.siteSurveyUpload',
      draft.requiredDocuments.siteSurveyUpload,
      'Site Survey',
    );
    out.document(
      'requiredDocuments.materialTestResultsUpload',
      draft.requiredDocuments.materialTestResultsUpload,
      'Material Test Results',
    );
    out.document(
      'requiredDocuments.otherCivilStructuralDocumentsUpload',
      draft.requiredDocuments.otherCivilStructuralDocumentsUpload,
      'Other Civil Structural Documents',
    );
    out.scalar(
      'reviewDeclaration.certifiesTrueAndCorrect',
      draft.reviewDeclaration.certifiesTrueAndCorrect,
    );
    out.scalar(
      'reviewDeclaration.confirmsPlansPreparedByLicensedEngineer',
      draft.reviewDeclaration.confirmsPlansPreparedByLicensedEngineer,
    );
    out.scalar(
      'reviewDeclaration.understandsSubjectToTechnicalEvaluation',
      draft.reviewDeclaration.understandsSubjectToTechnicalEvaluation,
    );
    out.scalar(
      'reviewDeclaration.understandsMustFollowApprovedPlans',
      draft.reviewDeclaration.understandsMustFollowApprovedPlans,
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
  void restore(CivilStructuralPermitDraft draft, SnapshotReader input) {
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
      CivilStructuralOccupancyGroup.values,
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
          CivilStructuralScopeType.values,
        ),
      );
    draft.scopeOfWork.otherScopeDescription = input.string(
      'scopeOfWork.otherScopeDescription',
    );
    draft.scopeOfWork.workTitle = input.string('scopeOfWork.workTitle');
    draft.scopeOfWork.generalDescription = input.string(
      'scopeOfWork.generalDescription',
    );
    draft.scopeOfWork.existingStructuralCondition = input.string(
      'scopeOfWork.existingStructuralCondition',
    );
    draft.scopeOfWork.proposedStructuralChanges = input.string(
      'scopeOfWork.proposedStructuralChanges',
    );
    draft.scopeOfWork.areasAffected = input.string('scopeOfWork.areasAffected');
    draft.workDetails.selectedWorks
      ..clear()
      ..addAll(input.enumSet('workDetails.selectedWorks', NatureOfWork.values));
    draft.workDetails.otherWorkDescription = input.string(
      'workDetails.otherWorkDescription',
    );
    draft.workDetails.numberOfStoreys = input.string(
      'workDetails.numberOfStoreys',
    );
    draft.workDetails.totalStructuralFloorArea = input.string(
      'workDetails.totalStructuralFloorArea',
    );
    draft.workDetails.buildingOrStructureHeight = input.string(
      'workDetails.buildingOrStructureHeight',
    );
    draft.workDetails.estimatedStructuralCost = input.string(
      'workDetails.estimatedStructuralCost',
    );
    draft.workDetails.proposedStartDate = input.date(
      'workDetails.proposedStartDate',
    );
    draft.workDetails.expectedCompletionDate = input.date(
      'workDetails.expectedCompletionDate',
    );
    draft.workDetails.excavationDepth = input.string(
      'workDetails.excavationDepth',
    );
    draft.workDetails.numberOfPiles = input.string('workDetails.numberOfPiles');
    draft.workDetails.pileType = input.string('workDetails.pileType');
    draft.workDetails.averagePileDepth = input.string(
      'workDetails.averagePileDepth',
    );
    draft.workDetails.pileCapacity = input.string('workDetails.pileCapacity');
    draft.workDetails.foundationType = input.string(
      'workDetails.foundationType',
    );
    draft.workDetails.foundationDepth = input.string(
      'workDetails.foundationDepth',
    );
    draft.workDetails.foundationDescription = input.string(
      'workDetails.foundationDescription',
    );
    draft.workDetails.concreteStrength = input.string(
      'workDetails.concreteStrength',
    );
    draft.workDetails.concreteFramingSystemDescription = input.string(
      'workDetails.concreteFramingSystemDescription',
    );
    draft.workDetails.steelGrade = input.string('workDetails.steelGrade');
    draft.workDetails.steelFramingSystemDescription = input.string(
      'workDetails.steelFramingSystemDescription',
    );
    draft.workDetails.slabType = input.string('workDetails.slabType');
    draft.workDetails.typicalSlabThickness = input.string(
      'workDetails.typicalSlabThickness',
    );
    draft.workDetails.structuralWallType = input.string(
      'workDetails.structuralWallType',
    );
    draft.workDetails.wallMaterial = input.string('workDetails.wallMaterial');
    draft.workDetails.typicalWallThickness = input.string(
      'workDetails.typicalWallThickness',
    );
    draft.workDetails.prestressingSystemDescription = input.string(
      'workDetails.prestressingSystemDescription',
    );
    draft.workDetails.testingLaboratory = input.string(
      'workDetails.testingLaboratory',
    );
    draft.workDetails.plannedTests = input.string('workDetails.plannedTests');
    draft.workDetails.testSchedule = input.string('workDetails.testSchedule');
    draft.workDetails.towerType = input.string('workDetails.towerType');
    draft.workDetails.towerHeight = input.string('workDetails.towerHeight');
    draft.workDetails.intendedUse = input.string('workDetails.intendedUse');
    draft.workDetails.tankType = input.string('workDetails.tankType');
    draft.workDetails.tankCapacity = input.string('workDetails.tankCapacity');
    draft.workDetails.tankMaterial = input.string('workDetails.tankMaterial');
    draft.professionals.designEngineer.fullName = input.string(
      'professionals.designEngineer.fullName',
    );
    draft.professionals.designEngineer.profession = input.enumValue(
      'professionals.designEngineer.profession',
      CivilStructuralProfessionType.values,
    );
    draft.professionals.designEngineer.address = input.string(
      'professionals.designEngineer.address',
    );
    draft.professionals.designEngineer.prcNumber = input.string(
      'professionals.designEngineer.prcNumber',
    );
    draft.professionals.designEngineer.prcValidityDate = input.date(
      'professionals.designEngineer.prcValidityDate',
    );
    draft.professionals.designEngineer.ptrNumber = input.string(
      'professionals.designEngineer.ptrNumber',
    );
    draft.professionals.designEngineer.ptrDateIssued = input.date(
      'professionals.designEngineer.ptrDateIssued',
    );
    draft.professionals.designEngineer.ptrPlaceIssued = input.string(
      'professionals.designEngineer.ptrPlaceIssued',
    );
    draft.professionals.designEngineer.tin = input.string(
      'professionals.designEngineer.tin',
    );
    draft.professionals.designEngineer.dateSigned = input.date(
      'professionals.designEngineer.dateSigned',
    );
    draft.professionals.isSupervisorSameAsDesignEngineer = input.boolean(
      'professionals.isSupervisorSameAsDesignEngineer',
      fallback: true,
    );
    draft.professionals.supervisor.fullName = input.string(
      'professionals.supervisor.fullName',
    );
    draft.professionals.supervisor.profession = input.enumValue(
      'professionals.supervisor.profession',
      CivilStructuralProfessionType.values,
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
    draft.reviewDeclaration.confirmsPlansPreparedByLicensedEngineer = input
        .boolean('reviewDeclaration.confirmsPlansPreparedByLicensedEngineer');
    draft.reviewDeclaration.understandsSubjectToTechnicalEvaluation = input
        .boolean('reviewDeclaration.understandsSubjectToTechnicalEvaluation');
    draft.reviewDeclaration.understandsMustFollowApprovedPlans = input.boolean(
      'reviewDeclaration.understandsMustFollowApprovedPlans',
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
    draft.status = CivilStructuralPermitDraftStatus.draft;
    draft.lastSavedAt = input.date('lastSavedAt');
  }
}
