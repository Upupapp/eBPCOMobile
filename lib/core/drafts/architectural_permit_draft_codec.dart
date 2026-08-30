import '../models/architectural_permit_model.dart';
import 'draft_snapshot.dart';

/// Architectural — ArchitecturalPermitDraft, persisted.
///
/// One of the seventeen wizards converted in M-48 part 2, after the mechanism
/// was proven on the Building Permit and Fencing. Every field the draft
/// declares is captured and read back except the 31 attachment slots,
/// which are dropped and named back to the applicant, and whatever
/// `test/architecture/draft_snapshot_completeness_test.dart` exempts with a
/// reason. That gate fails the day this file falls behind the model.
///
/// Written mechanically from the model's own field declarations and then
/// reviewed, which is why it reads uniformly. The alternative — trusting a
/// generator without a gate — is how 122 fields become 122 chances to
/// drop one silently.
class ArchitecturalPermitDraftCodec
    extends DraftCodec<ArchitecturalPermitDraft> {
  const ArchitecturalPermitDraftCodec();

  @override
  String get permitKey => 'architectural-permit';

  @override
  String get permitLabel => 'Architectural';

  @override
  void capture(ArchitecturalPermitDraft draft, SnapshotWriter out) {
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
      'scopeOfWork.descriptionOfWork',
      draft.scopeOfWork.descriptionOfWork,
    );
    out.scalar(
      'scopeOfWork.buildingAreasAffected',
      draft.scopeOfWork.buildingAreasAffected,
    );
    out.scalar(
      'scopeOfWork.existingCondition',
      draft.scopeOfWork.existingCondition,
    );
    out.scalar(
      'scopeOfWork.proposedArchitecturalChanges',
      draft.scopeOfWork.proposedArchitecturalChanges,
    );
    // Fixed size and keyed by AccessibilityFacility.values. The row carries
    // its facility, so a reordered enum cannot shift every answer one place.
    out.rows('complianceDetails.accessibility', [
      for (final entry in draft.complianceDetails.accessibility.entries)
        out.row()
          ..enumValue('facility', entry.key)
          ..enumValue('status', entry.value),
    ]);
    out.scalar(
      'complianceDetails.otherAccessibilityDescription',
      draft.complianceDetails.otherAccessibilityDescription,
    );
    out.scalar(
      'complianceDetails.buildingFootprintPercentage',
      draft.complianceDetails.buildingFootprintPercentage,
    );
    out.scalar(
      'complianceDetails.imperviousSurfaceAreaPercentage',
      draft.complianceDetails.imperviousSurfaceAreaPercentage,
    );
    out.scalar(
      'complianceDetails.unpavedSurfaceAreaPercentage',
      draft.complianceDetails.unpavedSurfaceAreaPercentage,
    );
    out.scalar(
      'complianceDetails.otherSitePercentage',
      draft.complianceDetails.otherSitePercentage,
    );
    out.scalar(
      'complianceDetails.otherSiteDescription',
      draft.complianceDetails.otherSiteDescription,
    );
    out.rows('complianceDetails.fireCode', [
      for (final entry in draft.complianceDetails.fireCode.entries)
        out.row()
          ..enumValue('feature', entry.key)
          ..enumValue('status', entry.value),
    ]);
    out.scalar(
      'complianceDetails.otherFireFeatureDescription',
      draft.complianceDetails.otherFireFeatureDescription,
    );
    out.scalar(
      'complianceDetails.numberOfExitDoors',
      draft.complianceDetails.numberOfExitDoors,
    );
    out.scalar(
      'complianceDetails.totalExitWidth',
      draft.complianceDetails.totalExitWidth,
    );
    out.scalar(
      'complianceDetails.minimumCorridorWidth',
      draft.complianceDetails.minimumCorridorWidth,
    );
    out.scalar(
      'complianceDetails.maximumDistanceToFireExit',
      draft.complianceDetails.maximumDistanceToFireExit,
    );
    out.scalar(
      'complianceDetails.publicStreetAccessDescription',
      draft.complianceDetails.publicStreetAccessDescription,
    );
    out.scalar(
      'complianceDetails.fireWallDescription',
      draft.complianceDetails.fireWallDescription,
    );
    out.scalar(
      'complianceDetails.fireSafetyFacilityDescription',
      draft.complianceDetails.fireSafetyFacilityDescription,
    );
    out.scalar(
      'professionals.designArchitect.fullName',
      draft.professionals.designArchitect.fullName,
    );
    out.scalar(
      'professionals.designArchitect.address',
      draft.professionals.designArchitect.address,
    );
    out.scalar(
      'professionals.designArchitect.prcNumber',
      draft.professionals.designArchitect.prcNumber,
    );
    out.date(
      'professionals.designArchitect.prcValidityDate',
      draft.professionals.designArchitect.prcValidityDate,
    );
    out.scalar(
      'professionals.designArchitect.ptrNumber',
      draft.professionals.designArchitect.ptrNumber,
    );
    out.date(
      'professionals.designArchitect.ptrDateIssued',
      draft.professionals.designArchitect.ptrDateIssued,
    );
    out.scalar(
      'professionals.designArchitect.ptrPlaceIssued',
      draft.professionals.designArchitect.ptrPlaceIssued,
    );
    out.scalar(
      'professionals.designArchitect.tin',
      draft.professionals.designArchitect.tin,
    );
    out.date(
      'professionals.designArchitect.dateSigned',
      draft.professionals.designArchitect.dateSigned,
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
    out.scalar(
      'professionals.isSupervisorSameAsDesignArchitect',
      draft.professionals.isSupervisorSameAsDesignArchitect,
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
      'requiredDocuments.vicinityMapUpload',
      draft.requiredDocuments.vicinityMapUpload,
      'Vicinity Map',
    );
    out.document(
      'requiredDocuments.siteDevelopmentPlanUpload',
      draft.requiredDocuments.siteDevelopmentPlanUpload,
      'Site Development Plan',
    );
    out.document(
      'requiredDocuments.perspectiveUpload',
      draft.requiredDocuments.perspectiveUpload,
      'Perspective',
    );
    out.document(
      'requiredDocuments.floorPlansUpload',
      draft.requiredDocuments.floorPlansUpload,
      'Floor Plans',
    );
    out.document(
      'requiredDocuments.elevationsUpload',
      draft.requiredDocuments.elevationsUpload,
      'Elevations',
    );
    out.document(
      'requiredDocuments.sectionsUpload',
      draft.requiredDocuments.sectionsUpload,
      'Sections',
    );
    out.document(
      'requiredDocuments.ceilingPlansUpload',
      draft.requiredDocuments.ceilingPlansUpload,
      'Ceiling Plans',
    );
    out.document(
      'requiredDocuments.rampDetailsUpload',
      draft.requiredDocuments.rampDetailsUpload,
      'Ramp Details',
    );
    out.document(
      'requiredDocuments.accessibleParkingDetailsUpload',
      draft.requiredDocuments.accessibleParkingDetailsUpload,
      'Accessible Parking Details',
    );
    out.document(
      'requiredDocuments.stairDetailsUpload',
      draft.requiredDocuments.stairDetailsUpload,
      'Stair Details',
    );
    out.document(
      'requiredDocuments.fireEscapeDetailsUpload',
      draft.requiredDocuments.fireEscapeDetailsUpload,
      'Fire Escape Details',
    );
    out.document(
      'requiredDocuments.cabinetPartitionDetailsUpload',
      draft.requiredDocuments.cabinetPartitionDetailsUpload,
      'Cabinet Partition Details',
    );
    out.document(
      'requiredDocuments.doorWindowScheduleUpload',
      draft.requiredDocuments.doorWindowScheduleUpload,
      'Door Window Schedule',
    );
    out.document(
      'requiredDocuments.floorFinishScheduleUpload',
      draft.requiredDocuments.floorFinishScheduleUpload,
      'Floor Finish Schedule',
    );
    out.document(
      'requiredDocuments.ceilingFinishScheduleUpload',
      draft.requiredDocuments.ceilingFinishScheduleUpload,
      'Ceiling Finish Schedule',
    );
    out.document(
      'requiredDocuments.wallFinishScheduleUpload',
      draft.requiredDocuments.wallFinishScheduleUpload,
      'Wall Finish Schedule',
    );
    out.document(
      'requiredDocuments.architecturalInteriorUpload',
      draft.requiredDocuments.architecturalInteriorUpload,
      'Architectural Interior',
    );
    out.document(
      'requiredDocuments.costEstimateUpload',
      draft.requiredDocuments.costEstimateUpload,
      'Cost Estimate',
    );
    out.document(
      'requiredDocuments.otherArchitecturalDocumentsUpload',
      draft.requiredDocuments.otherArchitecturalDocumentsUpload,
      'Other Architectural Documents',
    );
    out.scalar(
      'reviewDeclaration.certifiesTrueAndCorrect',
      draft.reviewDeclaration.certifiesTrueAndCorrect,
    );
    out.scalar(
      'reviewDeclaration.confirmsPlansPreparedByLicensedArchitect',
      draft.reviewDeclaration.confirmsPlansPreparedByLicensedArchitect,
    );
    out.scalar(
      'reviewDeclaration.understandsAccessibilitySubjectToEvaluation',
      draft.reviewDeclaration.understandsAccessibilitySubjectToEvaluation,
    );
    out.scalar(
      'reviewDeclaration.understandsFireSafetySubjectToEvaluation',
      draft.reviewDeclaration.understandsFireSafetySubjectToEvaluation,
    );
    out.scalar(
      'reviewDeclaration.understandsRequiresValidBuildingPermit',
      draft.reviewDeclaration.understandsRequiresValidBuildingPermit,
    );
    out.scalar(
      'reviewDeclaration.understandsMustFollowApprovedPlans',
      draft.reviewDeclaration.understandsMustFollowApprovedPlans,
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
  void restore(ArchitecturalPermitDraft draft, SnapshotReader input) {
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
      ArchitecturalOccupancyGroup.values,
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
        RelatedBuildingPermitStatus.pendingIssuance;
    draft.scopeOfWork.selectedScopes
      ..clear()
      ..addAll(
        input.enumSet(
          'scopeOfWork.selectedScopes',
          ArchitecturalScopeType.values,
        ),
      );
    draft.scopeOfWork.otherScopeDescription = input.string(
      'scopeOfWork.otherScopeDescription',
    );
    draft.scopeOfWork.workTitle = input.string('scopeOfWork.workTitle');
    draft.scopeOfWork.descriptionOfWork = input.string(
      'scopeOfWork.descriptionOfWork',
    );
    draft.scopeOfWork.buildingAreasAffected = input.string(
      'scopeOfWork.buildingAreasAffected',
    );
    draft.scopeOfWork.existingCondition = input.string(
      'scopeOfWork.existingCondition',
    );
    draft.scopeOfWork.proposedArchitecturalChanges = input.string(
      'scopeOfWork.proposedArchitecturalChanges',
    );
    for (final row in input.rows('complianceDetails.accessibility')) {
      final facility = row.enumValue('facility', AccessibilityFacility.values);
      final status = row.enumValue(
        'status',
        AccessibilityFacilityStatus.values,
      );
      if (facility != null && status != null) {
        draft.complianceDetails.accessibility[facility] = status;
      }
    }
    draft.complianceDetails.otherAccessibilityDescription = input.string(
      'complianceDetails.otherAccessibilityDescription',
    );
    draft.complianceDetails.buildingFootprintPercentage = input.string(
      'complianceDetails.buildingFootprintPercentage',
    );
    draft.complianceDetails.imperviousSurfaceAreaPercentage = input.string(
      'complianceDetails.imperviousSurfaceAreaPercentage',
    );
    draft.complianceDetails.unpavedSurfaceAreaPercentage = input.string(
      'complianceDetails.unpavedSurfaceAreaPercentage',
    );
    draft.complianceDetails.otherSitePercentage = input.string(
      'complianceDetails.otherSitePercentage',
    );
    draft.complianceDetails.otherSiteDescription = input.string(
      'complianceDetails.otherSiteDescription',
    );
    for (final row in input.rows('complianceDetails.fireCode')) {
      final feature = row.enumValue('feature', FireCodeFeature.values);
      final status = row.enumValue('status', FireCodeFeatureStatus.values);
      if (feature != null && status != null) {
        draft.complianceDetails.fireCode[feature] = status;
      }
    }
    draft.complianceDetails.otherFireFeatureDescription = input.string(
      'complianceDetails.otherFireFeatureDescription',
    );
    draft.complianceDetails.numberOfExitDoors = input.string(
      'complianceDetails.numberOfExitDoors',
    );
    draft.complianceDetails.totalExitWidth = input.string(
      'complianceDetails.totalExitWidth',
    );
    draft.complianceDetails.minimumCorridorWidth = input.string(
      'complianceDetails.minimumCorridorWidth',
    );
    draft.complianceDetails.maximumDistanceToFireExit = input.string(
      'complianceDetails.maximumDistanceToFireExit',
    );
    draft.complianceDetails.publicStreetAccessDescription = input.string(
      'complianceDetails.publicStreetAccessDescription',
    );
    draft.complianceDetails.fireWallDescription = input.string(
      'complianceDetails.fireWallDescription',
    );
    draft.complianceDetails.fireSafetyFacilityDescription = input.string(
      'complianceDetails.fireSafetyFacilityDescription',
    );
    draft.professionals.designArchitect.fullName = input.string(
      'professionals.designArchitect.fullName',
    );
    draft.professionals.designArchitect.address = input.string(
      'professionals.designArchitect.address',
    );
    draft.professionals.designArchitect.prcNumber = input.string(
      'professionals.designArchitect.prcNumber',
    );
    draft.professionals.designArchitect.prcValidityDate = input.date(
      'professionals.designArchitect.prcValidityDate',
    );
    draft.professionals.designArchitect.ptrNumber = input.string(
      'professionals.designArchitect.ptrNumber',
    );
    draft.professionals.designArchitect.ptrDateIssued = input.date(
      'professionals.designArchitect.ptrDateIssued',
    );
    draft.professionals.designArchitect.ptrPlaceIssued = input.string(
      'professionals.designArchitect.ptrPlaceIssued',
    );
    draft.professionals.designArchitect.tin = input.string(
      'professionals.designArchitect.tin',
    );
    draft.professionals.designArchitect.dateSigned = input.date(
      'professionals.designArchitect.dateSigned',
    );
    draft.professionals.isSupervisorSameAsDesignArchitect = input.boolean(
      'professionals.isSupervisorSameAsDesignArchitect',
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
    draft.reviewDeclaration.confirmsPlansPreparedByLicensedArchitect = input
        .boolean('reviewDeclaration.confirmsPlansPreparedByLicensedArchitect');
    draft.reviewDeclaration.understandsAccessibilitySubjectToEvaluation = input
        .boolean(
          'reviewDeclaration.understandsAccessibilitySubjectToEvaluation',
        );
    draft.reviewDeclaration.understandsFireSafetySubjectToEvaluation = input
        .boolean('reviewDeclaration.understandsFireSafetySubjectToEvaluation');
    draft.reviewDeclaration.understandsRequiresValidBuildingPermit = input
        .boolean('reviewDeclaration.understandsRequiresValidBuildingPermit');
    draft.reviewDeclaration.understandsMustFollowApprovedPlans = input.boolean(
      'reviewDeclaration.understandsMustFollowApprovedPlans',
    );
    draft.reviewDeclaration.agreesToTerms = input.boolean(
      'reviewDeclaration.agreesToTerms',
    );
    draft.useApplicantAddressForProjectLocation = input.boolean(
      'useApplicantAddressForProjectLocation',
    );
    // Not read back: a restored draft is always a draft. Honouring a
    // stored `submitted` would resurrect a filed application as editable.
    draft.status = ArchitecturalPermitDraftStatus.draft;
    draft.lastSavedAt = input.date('lastSavedAt');
  }
}
