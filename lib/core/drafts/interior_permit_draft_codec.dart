import '../models/interior_design_permit_model.dart';
import 'draft_snapshot.dart';

/// Interior Design — InteriorPermitDraft, persisted.
///
/// One of the seventeen wizards converted in M-48 part 2, after the mechanism
/// was proven on the Building Permit and Fencing. Every field the draft
/// declares is captured and read back except the 26 attachment slots,
/// which are dropped and named back to the applicant, and whatever
/// `test/architecture/draft_snapshot_completeness_test.dart` exempts with a
/// reason. That gate fails the day this file falls behind the model.
///
/// Written mechanically from the model's own field declarations and then
/// reviewed, which is why it reads uniformly. The alternative — trusting a
/// generator without a gate — is how 108 fields become 108 chances to
/// drop one silently.
class InteriorPermitDraftCodec extends DraftCodec<InteriorPermitDraft> {
  const InteriorPermitDraftCodec();

  @override
  String get permitKey => 'interior-design-permit';

  @override
  String get permitLabel => 'Interior Design';

  @override
  void capture(InteriorPermitDraft draft, SnapshotWriter out) {
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
    out.enumSet('workNature.selectedNatures', draft.workNature.selectedNatures);
    out.scalar(
      'workNature.projectDescription',
      draft.workNature.projectDescription,
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
      'professionals.designSignedDocumentUpload',
      draft.professionals.designSignedDocumentUpload,
      'Design Signed Document',
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
      'professionals.supervisorSignedDocumentUpload',
      draft.professionals.supervisorSignedDocumentUpload,
      'Supervisor Signed Document',
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
    out.date(
      'ownershipConsent.buildingOwner.dateSigned',
      draft.ownershipConsent.buildingOwner.dateSigned,
    );
    out.document(
      'ownershipConsent.buildingOwnerSignedDocumentUpload',
      draft.ownershipConsent.buildingOwnerSignedDocumentUpload,
      'Building Owner Signed Document',
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
    out.date(
      'ownershipConsent.lotOwner.dateSigned',
      draft.ownershipConsent.lotOwner.dateSigned,
    );
    out.document(
      'ownershipConsent.lotOwnerConsentUpload',
      draft.ownershipConsent.lotOwnerConsentUpload,
      'Lot Owner Consent',
    );
    out.document(
      'requiredDocuments.interiorPlanAndLayoutUpload',
      draft.requiredDocuments.interiorPlanAndLayoutUpload,
      'Interior Plan and Layout',
    );
    out.document(
      'requiredDocuments.wallPartitionsUpload',
      draft.requiredDocuments.wallPartitionsUpload,
      'Wall Partitions',
    );
    out.document(
      'requiredDocuments.furnitureLayoutUpload',
      draft.requiredDocuments.furnitureLayoutUpload,
      'Furniture Layout',
    );
    out.document(
      'requiredDocuments.equipmentAndApplianceLayoutUpload',
      draft.requiredDocuments.equipmentAndApplianceLayoutUpload,
      'Equipment and Appliance Layout',
    );
    out.document(
      'requiredDocuments.interiorWallElevationsUpload',
      draft.requiredDocuments.interiorWallElevationsUpload,
      'Interior Wall Elevations',
    );
    out.document(
      'requiredDocuments.crossWindowSectionsUpload',
      draft.requiredDocuments.crossWindowSectionsUpload,
      'Cross Window Sections',
    );
    out.document(
      'requiredDocuments.interiorPerspectiveFromMainEntrancesUpload',
      draft.requiredDocuments.interiorPerspectiveFromMainEntrancesUpload,
      'Interior Perspective from Main Entrances',
    );
    out.document(
      'requiredDocuments.finishesUpload',
      draft.requiredDocuments.finishesUpload,
      'Finishes',
    );
    out.document(
      'requiredDocuments.switchesUpload',
      draft.requiredDocuments.switchesUpload,
      'Switches',
    );
    out.document(
      'requiredDocuments.doorsUpload',
      draft.requiredDocuments.doorsUpload,
      'Doors',
    );
    out.document(
      'requiredDocuments.convenienceOutletsUpload',
      draft.requiredDocuments.convenienceOutletsUpload,
      'Convenience Outlets',
    );
    out.document(
      'requiredDocuments.decorationsUpload',
      draft.requiredDocuments.decorationsUpload,
      'Decorations',
    );
    out.document(
      'requiredDocuments.reflectedCeilingPlanUpload',
      draft.requiredDocuments.reflectedCeilingPlanUpload,
      'Reflected Ceiling Plan',
    );
    out.document(
      'requiredDocuments.lightingFixtureSpecificationsUpload',
      draft.requiredDocuments.lightingFixtureSpecificationsUpload,
      'Lighting Fixture Specifications',
    );
    out.document(
      'requiredDocuments.airConditioningExhaustAndReturnGrillesUpload',
      draft.requiredDocuments.airConditioningExhaustAndReturnGrillesUpload,
      'Air Conditioning Exhaust and Return Grilles',
    );
    out.document(
      'requiredDocuments.sprinklerNozzleLocationsUpload',
      draft.requiredDocuments.sprinklerNozzleLocationsUpload,
      'Sprinkler Nozzle Locations',
    );
    out.document(
      'requiredDocuments.fireResistivityRatingsUpload',
      draft.requiredDocuments.fireResistivityRatingsUpload,
      'Fire Resistivity Ratings',
    );
    out.document(
      'requiredDocuments.toxicityRatingsUpload',
      draft.requiredDocuments.toxicityRatingsUpload,
      'Toxicity Ratings',
    );
    out.document(
      'requiredDocuments.listOfMaterialsUpload',
      draft.requiredDocuments.listOfMaterialsUpload,
      'List of Materials',
    );
    out.document(
      'requiredDocuments.detailedCostEstimatesUpload',
      draft.requiredDocuments.detailedCostEstimatesUpload,
      'Detailed Cost Estimates',
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
      'reviewDeclaration.certifiesInformationIsAccurate',
      draft.reviewDeclaration.certifiesInformationIsAccurate,
    );
    out.scalar(
      'reviewDeclaration.understandsMustFollowApprovedPlansAndRegulations',
      draft.reviewDeclaration.understandsMustFollowApprovedPlansAndRegulations,
    );
    out.scalar(
      'reviewDeclaration.understandsDependsOnRelatedBuildingPermit',
      draft.reviewDeclaration.understandsDependsOnRelatedBuildingPermit,
    );
    out.scalar(
      'reviewDeclaration.understandsProfessionalDocumentsMustBeAuthentic',
      draft.reviewDeclaration.understandsProfessionalDocumentsMustBeAuthentic,
    );
    out.scalar(
      'useApplicantAddressForProjectLocation',
      draft.useApplicantAddressForProjectLocation,
    );
    out.enumValue('status', draft.status);
    out.date('lastSavedAt', draft.lastSavedAt);
  }

  @override
  void restore(InteriorPermitDraft draft, SnapshotReader input) {
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
      InteriorOccupancyGroup.values,
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
        input.enumSet('scopeOfWork.selectedScopes', InteriorScopeType.values),
      );
    draft.scopeOfWork.otherScopeDescription = input.string(
      'scopeOfWork.otherScopeDescription',
    );
    draft.workNature.selectedNatures
      ..clear()
      ..addAll(
        input.enumSet(
          'workNature.selectedNatures',
          InteriorWorkNatureType.values,
        ),
      );
    draft.workNature.projectDescription = input.string(
      'workNature.projectDescription',
    );
    draft.professionals.designProfessional.fullName = input.string(
      'professionals.designProfessional.fullName',
    );
    draft.professionals.designProfessional.profession = input.enumValue(
      'professionals.designProfessional.profession',
      InteriorProfessionType.values,
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
    draft.professionals.supervisor.fullName = input.string(
      'professionals.supervisor.fullName',
    );
    draft.professionals.supervisor.profession = input.enumValue(
      'professionals.supervisor.profession',
      InteriorProfessionType.values,
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
    draft.ownershipConsent.buildingOwner.dateSigned = input.date(
      'ownershipConsent.buildingOwner.dateSigned',
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
    draft.ownershipConsent.lotOwner.dateSigned = input.date(
      'ownershipConsent.lotOwner.dateSigned',
    );
    draft.reviewDeclaration.certifiesInformationIsAccurate = input.boolean(
      'reviewDeclaration.certifiesInformationIsAccurate',
    );
    draft.reviewDeclaration.understandsMustFollowApprovedPlansAndRegulations =
        input.boolean(
          'reviewDeclaration.understandsMustFollowApprovedPlansAndRegulations',
        );
    draft.reviewDeclaration.understandsDependsOnRelatedBuildingPermit = input
        .boolean('reviewDeclaration.understandsDependsOnRelatedBuildingPermit');
    draft.reviewDeclaration.understandsProfessionalDocumentsMustBeAuthentic =
        input.boolean(
          'reviewDeclaration.understandsProfessionalDocumentsMustBeAuthentic',
        );
    draft.useApplicantAddressForProjectLocation = input.boolean(
      'useApplicantAddressForProjectLocation',
    );
    // Not read back: a restored draft is always a draft. Honouring a
    // stored `submitted` would resurrect a filed application as editable.
    draft.status = InteriorPermitDraftStatus.draft;
    draft.lastSavedAt = input.date('lastSavedAt');
  }
}
