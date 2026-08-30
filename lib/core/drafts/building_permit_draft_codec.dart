import '../models/building_permit_model.dart';
import 'draft_snapshot.dart';

/// Building Permit — the first of the nineteen wizards to survive a restart.
///
/// First because it is the permit most applicants file, the longest wizard in
/// the app, and the one carrying the most documents: nineteen slots on the
/// Required Documents step alone, plus three professional uploads and two
/// consent uploads. It is therefore also the wizard where the honesty this
/// design rests on matters most — twenty-four attachments are dropped on save
/// and every one of them is named back to the applicant.
///
/// Every field the draft declares is captured below except the twenty-four
/// [DocumentModel] slots, which are recorded as detachments. The completeness
/// gate fails if that stops being true.
class BuildingPermitDraftCodec extends DraftCodec<BuildingPermitDraft> {
  const BuildingPermitDraftCodec();

  @override
  String get permitKey => 'building-permit';

  @override
  String get permitLabel => 'New Construction';

  @override
  void capture(BuildingPermitDraft draft, SnapshotWriter out) {
    final applicant = draft.applicant;
    out.scalar('applicant.firstName', applicant.firstName);
    out.scalar('applicant.middleName', applicant.middleName);
    out.scalar('applicant.lastName', applicant.lastName);
    out.scalar('applicant.tin', applicant.tin);
    out.scalar('applicant.mobileNumber', applicant.mobileNumber);
    out.scalar('applicant.email', applicant.email);
    out.scalar('applicant.isOwnedByEnterprise', applicant.isOwnedByEnterprise);
    out.scalar('applicant.enterpriseName', applicant.enterpriseName);
    out.scalar('applicant.formOfOwnership', applicant.formOfOwnership);

    final address = draft.applicantAddress;
    out.scalar('applicantAddress.houseNumber', address.houseNumber);
    out.scalar('applicantAddress.street', address.street);
    out.scalar('applicantAddress.barangay', address.barangay);
    out.scalar('applicantAddress.city', address.city);
    out.scalar('applicantAddress.province', address.province);
    out.scalar('applicantAddress.zipCode', address.zipCode);

    final site = draft.constructionLocation;
    out.scalar('constructionLocation.lotNumber', site.lotNumber);
    out.scalar('constructionLocation.blockNumber', site.blockNumber);
    out.scalar('constructionLocation.tctNumber', site.tctNumber);
    out.scalar(
      'constructionLocation.taxDeclarationNumber',
      site.taxDeclarationNumber,
    );
    out.scalar('constructionLocation.street', site.street);
    out.scalar('constructionLocation.barangay', site.barangay);
    out.scalar('constructionLocation.city', site.city);
    out.scalar('constructionLocation.province', site.province);
    out.scalar('constructionLocation.zipCode', site.zipCode);

    final project = draft.projectInformation;
    out.enumSet('projectInformation.scopeOfWork', project.scopeOfWork);
    out.scalar(
      'projectInformation.scopeOfWorkOtherDescription',
      project.scopeOfWorkOtherDescription,
    );
    out.enumValue('projectInformation.occupancyGroup', project.occupancyGroup);
    out.scalar(
      'projectInformation.occupancyOtherDescription',
      project.occupancyOtherDescription,
    );

    final building = draft.buildingDetails;
    out.scalar(
      'buildingDetails.occupancyClassification',
      building.occupancyClassification,
    );
    out.scalar('buildingDetails.numberOfUnits', building.numberOfUnits);
    out.scalar('buildingDetails.numberOfStorey', building.numberOfStorey);
    out.scalar('buildingDetails.totalFloorArea', building.totalFloorArea);
    out.scalar('buildingDetails.lotArea', building.lotArea);
    out.scalar(
      'buildingDetails.estimatedConstructionCost',
      building.estimatedConstructionCost,
    );
    out.scalar(
      'buildingDetails.estimatedCostBuilding',
      building.estimatedCostBuilding,
    );
    out.scalar(
      'buildingDetails.estimatedCostElectrical',
      building.estimatedCostElectrical,
    );
    out.scalar(
      'buildingDetails.estimatedCostMechanical',
      building.estimatedCostMechanical,
    );
    out.scalar(
      'buildingDetails.estimatedCostElectronics',
      building.estimatedCostElectronics,
    );
    out.scalar(
      'buildingDetails.estimatedCostPlumbing',
      building.estimatedCostPlumbing,
    );
    out.scalar(
      'buildingDetails.costOfEquipmentInstalled',
      building.costOfEquipmentInstalled,
    );
    out.date(
      'buildingDetails.proposedConstructionDate',
      building.proposedConstructionDate,
    );
    out.date(
      'buildingDetails.expectedCompletionDate',
      building.expectedCompletionDate,
    );

    final professional = draft.professional;
    out.scalar('professional.fullName', professional.fullName);
    out.enumValue('professional.profession', professional.profession);
    out.scalar('professional.address', professional.address);
    out.scalar('professional.contactNumber', professional.contactNumber);
    out.scalar('professional.tin', professional.tin);
    out.scalar('professional.prcNumber', professional.prcNumber);
    out.date('professional.prcValidityDate', professional.prcValidityDate);
    out.scalar('professional.ptrNumber', professional.ptrNumber);
    out.date('professional.ptrDateIssued', professional.ptrDateIssued);
    out.scalar('professional.ptrPlaceIssued', professional.ptrPlaceIssued);
    out.date('professional.dateSigned', professional.dateSigned);
    out.document(
      'professional.prcIdUpload',
      professional.prcIdUpload,
      'PRC ID of the professional in charge',
    );
    out.document(
      'professional.ptrUpload',
      professional.ptrUpload,
      'PTR of the professional in charge',
    );
    out.document(
      'professional.signedSealedUpload',
      professional.signedSealedUpload,
      'Signed and sealed documents',
    );

    final consent = draft.consentAuthorization;
    out.scalar(
      'consentAuthorization.isRegisteredOwner',
      consent.isRegisteredOwner,
    );
    out.scalar(
      'consentAuthorization.representativeName',
      consent.representativeName,
    );
    out.scalar(
      'consentAuthorization.representativeAddress',
      consent.representativeAddress,
    );
    // Renamed on the model, NOT in storage. The key is a compatibility
    // surface: a draft saved before 31 August 2026 holds these under the old
    // names, and changing the key would silently lose them on restore.
    out.scalar(
      'consentAuthorization.governmentIdNumber',
      consent.governmentIdNumber,
    );
    out.date(
      'consentAuthorization.governmentIdDateIssued',
      consent.governmentIdDateIssued,
    );
    out.scalar(
      'consentAuthorization.governmentIdPlaceIssued',
      consent.governmentIdPlaceIssued,
    );
    out.document(
      'consentAuthorization.authorizationLetterUpload',
      consent.authorizationLetterUpload,
      'Authorization letter',
    );
    out.document(
      'consentAuthorization.ownerValidIdUpload',
      consent.ownerValidIdUpload,
      "Lot owner's valid ID",
    );

    final documents = draft.requiredDocuments;
    out.document(
      'requiredDocuments.landTitleUpload',
      documents.landTitleUpload,
      'Proof of ownership',
    );
    out.document(
      'requiredDocuments.validIdOfApplicantAndOwnerUpload',
      documents.validIdOfApplicantAndOwnerUpload,
      'Valid ID of Applicant and Owner of Lot',
    );
    out.document(
      'requiredDocuments.taxDeclarationUpload',
      documents.taxDeclarationUpload,
      'Tax Declaration',
    );
    out.document(
      'requiredDocuments.realPropertyTaxReceiptUpload',
      documents.realPropertyTaxReceiptUpload,
      'Real Property Tax Receipt',
    );
    out.document(
      'requiredDocuments.plansUpload',
      documents.plansUpload,
      'Plans',
    );
    out.document(
      'requiredDocuments.specificationsUpload',
      documents.specificationsUpload,
      'Specifications',
    );
    out.document(
      'requiredDocuments.billOfMaterialsUpload',
      documents.billOfMaterialsUpload,
      'Bill of Materials',
    );
    out.document(
      'requiredDocuments.surveyPlanUpload',
      documents.surveyPlanUpload,
      'Survey Plan',
    );
    out.document(
      'requiredDocuments.costEstimateUpload',
      documents.costEstimateUpload,
      'Cost Estimate',
    );
    out.document(
      'requiredDocuments.structuralDesignAndAnalysisUpload',
      documents.structuralDesignAndAnalysisUpload,
      'Structural Design and Analysis',
    );
    out.document(
      'requiredDocuments.soilAnalysisUpload',
      documents.soilAnalysisUpload,
      'Soil Analysis',
    );
    out.document(
      'requiredDocuments.prcIdChecklistUpload',
      documents.prcIdChecklistUpload,
      'PRC ID (documentary checklist)',
    );
    out.document(
      'requiredDocuments.ptrChecklistUpload',
      documents.ptrChecklistUpload,
      'PTR (documentary checklist)',
    );
    out.document(
      'requiredDocuments.signedFormsUpload',
      documents.signedFormsUpload,
      'Signed forms',
    );
    out.document(
      'requiredDocuments.barangayClearanceUpload',
      documents.barangayClearanceUpload,
      'Barangay Clearance',
    );
    out.document(
      'requiredDocuments.zoningClearanceUpload',
      documents.zoningClearanceUpload,
      'Zoning Clearance',
    );
    out.document(
      'requiredDocuments.fireRelatedRequirementsUpload',
      documents.fireRelatedRequirementsUpload,
      'Fire-related requirements',
    );
    out.document(
      'requiredDocuments.constructionSafetyProgramUpload',
      documents.constructionSafetyProgramUpload,
      'Construction Safety and Health Program',
    );
    out.document(
      'requiredDocuments.roadClearanceUpload',
      documents.roadClearanceUpload,
      'Road Clearance',
    );
    out.document(
      'requiredDocuments.unifiedApplicationFormUpload',
      documents.unifiedApplicationFormUpload,
      'Unified Application Form, signed',
    );

    final declaration = draft.reviewDeclaration;
    out.scalar(
      'reviewDeclaration.certifiesTrueAndCorrect',
      declaration.certifiesTrueAndCorrect,
    );
    out.scalar(
      'reviewDeclaration.understandsRequirements',
      declaration.understandsRequirements,
    );
    out.scalar('reviewDeclaration.agreesToTerms', declaration.agreesToTerms);

    out.enumValue(
      'assessmentPayment.selectedPaymentMethod',
      draft.assessmentPayment.selectedPaymentMethod,
    );

    out.scalar(
      'useApplicantAddressForConstruction',
      draft.useApplicantAddressForConstruction,
    );
    out.enumValue('status', draft.status);
    out.date('lastSavedAt', draft.lastSavedAt);
  }

  @override
  void restore(BuildingPermitDraft draft, SnapshotReader input) {
    draft.applicant
      ..firstName = input.string('applicant.firstName')
      ..middleName = input.string('applicant.middleName')
      ..lastName = input.string('applicant.lastName')
      ..tin = input.string('applicant.tin')
      ..mobileNumber = input.string('applicant.mobileNumber')
      ..email = input.string('applicant.email')
      ..isOwnedByEnterprise = input.boolean('applicant.isOwnedByEnterprise')
      ..enterpriseName = input.string('applicant.enterpriseName')
      ..formOfOwnership = input.nullableString('applicant.formOfOwnership');

    draft.applicantAddress
      ..houseNumber = input.string('applicantAddress.houseNumber')
      ..street = input.string('applicantAddress.street')
      ..barangay = input.string('applicantAddress.barangay')
      ..city = input.string('applicantAddress.city')
      ..province = input.string('applicantAddress.province')
      ..zipCode = input.string('applicantAddress.zipCode');

    draft.constructionLocation
      ..lotNumber = input.string('constructionLocation.lotNumber')
      ..blockNumber = input.string('constructionLocation.blockNumber')
      ..tctNumber = input.string('constructionLocation.tctNumber')
      ..taxDeclarationNumber = input.string(
        'constructionLocation.taxDeclarationNumber',
      )
      ..street = input.string('constructionLocation.street')
      ..barangay = input.string('constructionLocation.barangay')
      ..city = input.string('constructionLocation.city')
      ..province = input.string('constructionLocation.province')
      ..zipCode = input.string('constructionLocation.zipCode');

    draft.projectInformation
      ..scopeOfWork = input.enumSet(
        'projectInformation.scopeOfWork',
        ScopeOfWorkOption.values,
        // The field's own initialiser. A wizard opened on a draft whose scope
        // could not be read must not show an empty Step 3 that the applicant
        // has to notice is empty.
        fallback: const {ScopeOfWorkOption.newConstruction},
      )
      ..scopeOfWorkOtherDescription = input.string(
        'projectInformation.scopeOfWorkOtherDescription',
      )
      ..occupancyGroup = input.enumValue(
        'projectInformation.occupancyGroup',
        OccupancyGroup.values,
      )
      ..occupancyOtherDescription = input.string(
        'projectInformation.occupancyOtherDescription',
      );

    draft.buildingDetails
      ..occupancyClassification = input.string(
        'buildingDetails.occupancyClassification',
      )
      ..numberOfUnits = input.string('buildingDetails.numberOfUnits')
      ..numberOfStorey = input.string('buildingDetails.numberOfStorey')
      ..totalFloorArea = input.string('buildingDetails.totalFloorArea')
      ..lotArea = input.string('buildingDetails.lotArea')
      ..estimatedConstructionCost = input.string(
        'buildingDetails.estimatedConstructionCost',
      )
      ..estimatedCostBuilding = input.string(
        'buildingDetails.estimatedCostBuilding',
      )
      ..estimatedCostElectrical = input.string(
        'buildingDetails.estimatedCostElectrical',
      )
      ..estimatedCostMechanical = input.string(
        'buildingDetails.estimatedCostMechanical',
      )
      ..estimatedCostElectronics = input.string(
        'buildingDetails.estimatedCostElectronics',
      )
      ..estimatedCostPlumbing = input.string(
        'buildingDetails.estimatedCostPlumbing',
      )
      ..costOfEquipmentInstalled = input.string(
        'buildingDetails.costOfEquipmentInstalled',
      )
      ..proposedConstructionDate = input.date(
        'buildingDetails.proposedConstructionDate',
      )
      ..expectedCompletionDate = input.date(
        'buildingDetails.expectedCompletionDate',
      );

    draft.professional
      ..fullName = input.string('professional.fullName')
      ..profession = input.enumValue(
        'professional.profession',
        ProfessionType.values,
      )
      ..address = input.string('professional.address')
      ..contactNumber = input.string('professional.contactNumber')
      ..tin = input.string('professional.tin')
      ..prcNumber = input.string('professional.prcNumber')
      ..prcValidityDate = input.date('professional.prcValidityDate')
      ..ptrNumber = input.string('professional.ptrNumber')
      ..ptrDateIssued = input.date('professional.ptrDateIssued')
      ..ptrPlaceIssued = input.string('professional.ptrPlaceIssued')
      ..dateSigned = input.date('professional.dateSigned');

    draft.consentAuthorization
      ..isRegisteredOwner = input.nullableBoolean(
        'consentAuthorization.isRegisteredOwner',
      )
      ..representativeName = input.string(
        'consentAuthorization.representativeName',
      )
      ..representativeAddress = input.string(
        'consentAuthorization.representativeAddress',
      )
      // Read under the new key, falling back to the old one so a draft
      // saved before the rename still gives its answers back.
      ..governmentIdNumber =
          input.has('consentAuthorization.governmentIdNumber')
          ? input.string('consentAuthorization.governmentIdNumber')
          : input.string('consentAuthorization.ctcNumber')
      ..governmentIdDateIssued =
          input.date('consentAuthorization.governmentIdDateIssued') ??
          input.date('consentAuthorization.ctcDateIssued')
      ..governmentIdPlaceIssued =
          input.has('consentAuthorization.governmentIdPlaceIssued')
          ? input.string('consentAuthorization.governmentIdPlaceIssued')
          : input.string('consentAuthorization.ctcPlaceIssued');

    draft.reviewDeclaration
      ..certifiesTrueAndCorrect = input.boolean(
        'reviewDeclaration.certifiesTrueAndCorrect',
      )
      ..understandsRequirements = input.boolean(
        'reviewDeclaration.understandsRequirements',
      )
      ..agreesToTerms = input.boolean('reviewDeclaration.agreesToTerms');

    draft.assessmentPayment.selectedPaymentMethod = input.enumValue(
      'assessmentPayment.selectedPaymentMethod',
      PaymentMethod.values,
    );

    draft.useApplicantAddressForConstruction = input.boolean(
      'useApplicantAddressForConstruction',
    );
    // Deliberately NOT restored from the snapshot: a restored draft is a
    // draft. Only `submitApplication` sets `submitted`, and a stored value
    // saying otherwise would resurrect a filed application as editable.
    draft.status = BuildingPermitDraftStatus.draft;
    draft.lastSavedAt = input.date('lastSavedAt');

    // Attachments, kept since 30 August 2026. Null when the file has gone —
    // the reader names it for the applicant in that case, so a document
    // cleared between saving and resuming is not silently missing.
    draft.professional.prcIdUpload = input.document('professional.prcIdUpload');
    draft.professional.ptrUpload = input.document('professional.ptrUpload');
    draft.professional.signedSealedUpload = input.document(
      'professional.signedSealedUpload',
    );
    draft.consentAuthorization.authorizationLetterUpload = input.document(
      'consentAuthorization.authorizationLetterUpload',
    );
    draft.consentAuthorization.ownerValidIdUpload = input.document(
      'consentAuthorization.ownerValidIdUpload',
    );
    draft.requiredDocuments.landTitleUpload = input.document(
      'requiredDocuments.landTitleUpload',
    );
    draft.requiredDocuments.validIdOfApplicantAndOwnerUpload = input.document(
      'requiredDocuments.validIdOfApplicantAndOwnerUpload',
    );
    draft.requiredDocuments.taxDeclarationUpload = input.document(
      'requiredDocuments.taxDeclarationUpload',
    );
    draft.requiredDocuments.realPropertyTaxReceiptUpload = input.document(
      'requiredDocuments.realPropertyTaxReceiptUpload',
    );
    draft.requiredDocuments.plansUpload = input.document(
      'requiredDocuments.plansUpload',
    );
    draft.requiredDocuments.specificationsUpload = input.document(
      'requiredDocuments.specificationsUpload',
    );
    draft.requiredDocuments.billOfMaterialsUpload = input.document(
      'requiredDocuments.billOfMaterialsUpload',
    );
    draft.requiredDocuments.surveyPlanUpload = input.document(
      'requiredDocuments.surveyPlanUpload',
    );
    draft.requiredDocuments.costEstimateUpload = input.document(
      'requiredDocuments.costEstimateUpload',
    );
    draft.requiredDocuments.structuralDesignAndAnalysisUpload = input.document(
      'requiredDocuments.structuralDesignAndAnalysisUpload',
    );
    draft.requiredDocuments.soilAnalysisUpload = input.document(
      'requiredDocuments.soilAnalysisUpload',
    );
    draft.requiredDocuments.prcIdChecklistUpload = input.document(
      'requiredDocuments.prcIdChecklistUpload',
    );
    draft.requiredDocuments.ptrChecklistUpload = input.document(
      'requiredDocuments.ptrChecklistUpload',
    );
    draft.requiredDocuments.signedFormsUpload = input.document(
      'requiredDocuments.signedFormsUpload',
    );
    draft.requiredDocuments.barangayClearanceUpload = input.document(
      'requiredDocuments.barangayClearanceUpload',
    );
    draft.requiredDocuments.zoningClearanceUpload = input.document(
      'requiredDocuments.zoningClearanceUpload',
    );
    draft.requiredDocuments.fireRelatedRequirementsUpload = input.document(
      'requiredDocuments.fireRelatedRequirementsUpload',
    );
    draft.requiredDocuments.constructionSafetyProgramUpload = input.document(
      'requiredDocuments.constructionSafetyProgramUpload',
    );
    draft.requiredDocuments.roadClearanceUpload = input.document(
      'requiredDocuments.roadClearanceUpload',
    );
    draft.requiredDocuments.unifiedApplicationFormUpload = input.document(
      'requiredDocuments.unifiedApplicationFormUpload',
    );
  }
}
