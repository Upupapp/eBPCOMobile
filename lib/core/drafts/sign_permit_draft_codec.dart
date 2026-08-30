import '../models/sign_permit_model.dart';
import 'draft_snapshot.dart';

/// Sign — SignPermitDraft, persisted.
///
/// One of the seventeen wizards converted in M-48 part 2, after the mechanism
/// was proven on the Building Permit and Fencing. Every field the draft
/// declares is captured and read back except the 14 attachment slots,
/// which are dropped and named back to the applicant, and whatever
/// `test/architecture/draft_snapshot_completeness_test.dart` exempts with a
/// reason. That gate fails the day this file falls behind the model.
///
/// Written mechanically from the model's own field declarations and then
/// reviewed, which is why it reads uniformly. The alternative — trusting a
/// generator without a gate — is how 100 fields become 100 chances to
/// drop one silently.
class SignPermitDraftCodec extends DraftCodec<SignPermitDraft> {
  const SignPermitDraftCodec();

  @override
  String get permitKey => 'sign-permit';

  @override
  String get permitLabel => 'Sign';

  @override
  void capture(SignPermitDraft draft, SnapshotWriter out) {
    out.scalar(
      'relatedBuildingPermit.buildingPermitNumber',
      draft.relatedBuildingPermit.buildingPermitNumber,
    );
    out.enumValue(
      'relatedBuildingPermit.status',
      draft.relatedBuildingPermit.status,
    );
    out.scalar('applicant.lastName', draft.applicant.lastName);
    out.scalar('applicant.firstName', draft.applicant.firstName);
    out.scalar('applicant.middleInitial', draft.applicant.middleInitial);
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
    out.scalar('applicant.addressNumber', draft.applicant.addressNumber);
    out.scalar('applicant.street', draft.applicant.street);
    out.scalar('applicant.barangay', draft.applicant.barangay);
    out.scalar('applicant.city', draft.applicant.city);
    out.scalar('applicant.zipCode', draft.applicant.zipCode);
    out.scalar(
      'constructionLocation.lotNumber',
      draft.constructionLocation.lotNumber,
    );
    out.scalar(
      'constructionLocation.blockNumber',
      draft.constructionLocation.blockNumber,
    );
    out.scalar(
      'constructionLocation.tctNumber',
      draft.constructionLocation.tctNumber,
    );
    out.scalar(
      'constructionLocation.taxDeclarationNumber',
      draft.constructionLocation.taxDeclarationNumber,
    );
    out.scalar(
      'constructionLocation.street',
      draft.constructionLocation.street,
    );
    out.scalar(
      'constructionLocation.barangay',
      draft.constructionLocation.barangay,
    );
    out.scalar('constructionLocation.city', draft.constructionLocation.city);
    out.enumSet('scopeOfWork.selectedScopes', draft.scopeOfWork.selectedScopes);
    out.scalar(
      'scopeOfWork.otherScopeDescription',
      draft.scopeOfWork.otherScopeDescription,
    );
    out.enumValue(
      'signInformation.displayFaceType',
      draft.signInformation.displayFaceType,
    );
    out.enumValue(
      'signInformation.displayType',
      draft.signInformation.displayType,
    );
    out.scalar(
      'signInformation.otherDisplayTypeDescription',
      draft.signInformation.otherDisplayTypeDescription,
    );
    out.enumValue(
      'signInformation.installationType',
      draft.signInformation.installationType,
    );
    out.scalar(
      'signInformation.otherInstallationDescription',
      draft.signInformation.otherInstallationDescription,
    );
    out.scalar(
      'signInformation.lengthMeters',
      draft.signInformation.lengthMeters,
    );
    out.scalar(
      'signInformation.widthMeters',
      draft.signInformation.widthMeters,
    );
    out.scalar(
      'requiredDocuments.isApplicantPropertyOwner',
      draft.requiredDocuments.isApplicantPropertyOwner,
    );
    out.document(
      'requiredDocuments.tctOrOctCopyUpload',
      draft.requiredDocuments.tctOrOctCopyUpload,
      'TCT or OCT Copy',
    );
    out.document(
      'requiredDocuments.taxDeclarationUpload',
      draft.requiredDocuments.taxDeclarationUpload,
      'Tax Declaration',
    );
    out.document(
      'requiredDocuments.realtyTaxReceiptUpload',
      draft.requiredDocuments.realtyTaxReceiptUpload,
      'Realty Tax Receipt',
    );
    out.document(
      'requiredDocuments.contractOfLeaseUpload',
      draft.requiredDocuments.contractOfLeaseUpload,
      'Contract of Lease',
    );
    out.document(
      'requiredDocuments.lotPlanUpload',
      draft.requiredDocuments.lotPlanUpload,
      'Lot Plan',
    );
    out.document(
      'requiredDocuments.siteDevelopmentPlanUpload',
      draft.requiredDocuments.siteDevelopmentPlanUpload,
      'Site Development Plan',
    );
    out.document(
      'requiredDocuments.signStructurePlansUpload',
      draft.requiredDocuments.signStructurePlansUpload,
      'Sign Structure Plans',
    );
    out.document(
      'requiredDocuments.structuralDesignAndComputationsUpload',
      draft.requiredDocuments.structuralDesignAndComputationsUpload,
      'Structural Design and Computations',
    );
    out.document(
      'requiredDocuments.specificationsUpload',
      draft.requiredDocuments.specificationsUpload,
      'Specifications',
    );
    out.document(
      'requiredDocuments.costEstimatesUpload',
      draft.requiredDocuments.costEstimatesUpload,
      'Cost Estimates',
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
      'consent.applicant.printedName',
      draft.consent.applicant.printedName,
    );
    out.scalar('consent.applicant.address', draft.consent.applicant.address);
    out.scalar(
      'consent.applicant.ctcNumber',
      draft.consent.applicant.ctcNumber,
    );
    out.date(
      'consent.applicant.ctcDateIssued',
      draft.consent.applicant.ctcDateIssued,
    );
    out.scalar(
      'consent.applicant.ctcPlaceIssued',
      draft.consent.applicant.ctcPlaceIssued,
    );
    out.scalar('consent.applicant.tin', draft.consent.applicant.tin);
    out.date(
      'consent.applicant.dateSigned',
      draft.consent.applicant.dateSigned,
    );
    out.document(
      'consent.applicantSignedDocumentUpload',
      draft.consent.applicantSignedDocumentUpload,
      'Applicant Signed Document',
    );
    out.scalar(
      'consent.isApplicantAlsoBuildingOwner',
      draft.consent.isApplicantAlsoBuildingOwner,
    );
    out.scalar(
      'consent.buildingOwner.printedName',
      draft.consent.buildingOwner.printedName,
    );
    out.scalar(
      'consent.buildingOwner.address',
      draft.consent.buildingOwner.address,
    );
    out.scalar(
      'consent.buildingOwner.ctcNumber',
      draft.consent.buildingOwner.ctcNumber,
    );
    out.date(
      'consent.buildingOwner.ctcDateIssued',
      draft.consent.buildingOwner.ctcDateIssued,
    );
    out.scalar(
      'consent.buildingOwner.ctcPlaceIssued',
      draft.consent.buildingOwner.ctcPlaceIssued,
    );
    out.scalar('consent.buildingOwner.tin', draft.consent.buildingOwner.tin);
    out.date(
      'consent.buildingOwner.dateSigned',
      draft.consent.buildingOwner.dateSigned,
    );
    out.document(
      'consent.buildingOwnerSignedDocumentUpload',
      draft.consent.buildingOwnerSignedDocumentUpload,
      'Building Owner Signed Document',
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
      'useApplicantAddressForConstructionLocation',
      draft.useApplicantAddressForConstructionLocation,
    );
    out.enumValue('status', draft.status);
    out.date('lastSavedAt', draft.lastSavedAt);
  }

  @override
  void restore(SignPermitDraft draft, SnapshotReader input) {
    draft.relatedBuildingPermit.buildingPermitNumber = input.string(
      'relatedBuildingPermit.buildingPermitNumber',
    );
    draft.relatedBuildingPermit.status =
        input.enumValue(
          'relatedBuildingPermit.status',
          RelatedBuildingPermitStatus.values,
        ) ??
        RelatedBuildingPermitStatus.pending;
    draft.applicant.lastName = input.string('applicant.lastName');
    draft.applicant.firstName = input.string('applicant.firstName');
    draft.applicant.middleInitial = input.string('applicant.middleInitial');
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
      SignOccupancyGroup.values,
    );
    draft.applicant.occupancyOtherDescription = input.string(
      'applicant.occupancyOtherDescription',
    );
    draft.applicant.addressNumber = input.string('applicant.addressNumber');
    draft.applicant.street = input.string('applicant.street');
    draft.applicant.barangay = input.string('applicant.barangay');
    draft.applicant.city = input.string('applicant.city');
    draft.applicant.zipCode = input.string('applicant.zipCode');
    draft.constructionLocation.lotNumber = input.string(
      'constructionLocation.lotNumber',
    );
    draft.constructionLocation.blockNumber = input.string(
      'constructionLocation.blockNumber',
    );
    draft.constructionLocation.tctNumber = input.string(
      'constructionLocation.tctNumber',
    );
    draft.constructionLocation.taxDeclarationNumber = input.string(
      'constructionLocation.taxDeclarationNumber',
    );
    draft.constructionLocation.street = input.string(
      'constructionLocation.street',
    );
    draft.constructionLocation.barangay = input.string(
      'constructionLocation.barangay',
    );
    draft.constructionLocation.city = input.string('constructionLocation.city');
    draft.scopeOfWork.selectedScopes
      ..clear()
      ..addAll(
        input.enumSet('scopeOfWork.selectedScopes', SignScopeType.values),
      );
    draft.scopeOfWork.otherScopeDescription = input.string(
      'scopeOfWork.otherScopeDescription',
    );
    draft.signInformation.displayFaceType = input.enumValue(
      'signInformation.displayFaceType',
      SignDisplayFaceType.values,
    );
    draft.signInformation.displayType = input.enumValue(
      'signInformation.displayType',
      SignDisplayType.values,
    );
    draft.signInformation.otherDisplayTypeDescription = input.string(
      'signInformation.otherDisplayTypeDescription',
    );
    draft.signInformation.installationType = input.enumValue(
      'signInformation.installationType',
      SignInstallationType.values,
    );
    draft.signInformation.otherInstallationDescription = input.string(
      'signInformation.otherInstallationDescription',
    );
    draft.signInformation.lengthMeters = input.string(
      'signInformation.lengthMeters',
    );
    draft.signInformation.widthMeters = input.string(
      'signInformation.widthMeters',
    );
    draft.requiredDocuments.isApplicantPropertyOwner = input.nullableBoolean(
      'requiredDocuments.isApplicantPropertyOwner',
    );
    draft.requiredDocuments.tctOrOctCopyUpload = input.document(
      'requiredDocuments.tctOrOctCopyUpload',
    );
    draft.requiredDocuments.taxDeclarationUpload = input.document(
      'requiredDocuments.taxDeclarationUpload',
    );
    draft.requiredDocuments.realtyTaxReceiptUpload = input.document(
      'requiredDocuments.realtyTaxReceiptUpload',
    );
    draft.requiredDocuments.contractOfLeaseUpload = input.document(
      'requiredDocuments.contractOfLeaseUpload',
    );
    draft.requiredDocuments.lotPlanUpload = input.document(
      'requiredDocuments.lotPlanUpload',
    );
    draft.requiredDocuments.siteDevelopmentPlanUpload = input.document(
      'requiredDocuments.siteDevelopmentPlanUpload',
    );
    draft.requiredDocuments.signStructurePlansUpload = input.document(
      'requiredDocuments.signStructurePlansUpload',
    );
    draft.requiredDocuments.structuralDesignAndComputationsUpload = input
        .document('requiredDocuments.structuralDesignAndComputationsUpload');
    draft.requiredDocuments.specificationsUpload = input.document(
      'requiredDocuments.specificationsUpload',
    );
    draft.requiredDocuments.costEstimatesUpload = input.document(
      'requiredDocuments.costEstimatesUpload',
    );
    draft.professionals.designProfessional.fullName = input.string(
      'professionals.designProfessional.fullName',
    );
    draft.professionals.designProfessional.profession = input.enumValue(
      'professionals.designProfessional.profession',
      SignProfessionType.values,
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
    draft.professionals.designSignedDocumentUpload = input.document(
      'professionals.designSignedDocumentUpload',
    );
    draft.professionals.supervisor.fullName = input.string(
      'professionals.supervisor.fullName',
    );
    draft.professionals.supervisor.profession = input.enumValue(
      'professionals.supervisor.profession',
      SignProfessionType.values,
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
    draft.professionals.supervisorSignedDocumentUpload = input.document(
      'professionals.supervisorSignedDocumentUpload',
    );
    draft.consent.applicant.printedName = input.string(
      'consent.applicant.printedName',
    );
    draft.consent.applicant.address = input.string('consent.applicant.address');
    draft.consent.applicant.ctcNumber = input.string(
      'consent.applicant.ctcNumber',
    );
    draft.consent.applicant.ctcDateIssued = input.date(
      'consent.applicant.ctcDateIssued',
    );
    draft.consent.applicant.ctcPlaceIssued = input.string(
      'consent.applicant.ctcPlaceIssued',
    );
    draft.consent.applicant.tin = input.string('consent.applicant.tin');
    draft.consent.applicant.dateSigned = input.date(
      'consent.applicant.dateSigned',
    );
    draft.consent.applicantSignedDocumentUpload = input.document(
      'consent.applicantSignedDocumentUpload',
    );
    draft.consent.isApplicantAlsoBuildingOwner = input.nullableBoolean(
      'consent.isApplicantAlsoBuildingOwner',
    );
    draft.consent.buildingOwner.printedName = input.string(
      'consent.buildingOwner.printedName',
    );
    draft.consent.buildingOwner.address = input.string(
      'consent.buildingOwner.address',
    );
    draft.consent.buildingOwner.ctcNumber = input.string(
      'consent.buildingOwner.ctcNumber',
    );
    draft.consent.buildingOwner.ctcDateIssued = input.date(
      'consent.buildingOwner.ctcDateIssued',
    );
    draft.consent.buildingOwner.ctcPlaceIssued = input.string(
      'consent.buildingOwner.ctcPlaceIssued',
    );
    draft.consent.buildingOwner.tin = input.string('consent.buildingOwner.tin');
    draft.consent.buildingOwner.dateSigned = input.date(
      'consent.buildingOwner.dateSigned',
    );
    draft.consent.buildingOwnerSignedDocumentUpload = input.document(
      'consent.buildingOwnerSignedDocumentUpload',
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
    draft.useApplicantAddressForConstructionLocation = input.boolean(
      'useApplicantAddressForConstructionLocation',
    );
    // Not read back: a restored draft is always a draft. Honouring a
    // stored `submitted` would resurrect a filed application as editable.
    draft.status = SignPermitDraftStatus.draft;
    draft.lastSavedAt = input.date('lastSavedAt');
  }
}
