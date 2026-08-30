import '../models/certificate_of_occupancy_model.dart';
import 'draft_snapshot.dart';

/// Certificate of Occupancy — CertificateOfOccupancyDraft, persisted.
///
/// One of the seventeen wizards converted in M-48 part 2, after the mechanism
/// was proven on the Building Permit and Fencing. Every field the draft
/// declares is captured and read back except the 13 attachment slots,
/// which are dropped and named back to the applicant, and whatever
/// `test/architecture/draft_snapshot_completeness_test.dart` exempts with a
/// reason. That gate fails the day this file falls behind the model.
///
/// Written mechanically from the model's own field declarations and then
/// reviewed, which is why it reads uniformly. The alternative — trusting a
/// generator without a gate — is how 47 fields become 47 chances to
/// drop one silently.
class CertificateOfOccupancyDraftCodec
    extends DraftCodec<CertificateOfOccupancyDraft> {
  const CertificateOfOccupancyDraftCodec();

  @override
  String get permitKey => 'certificate-of-occupancy';

  @override
  String get permitLabel => 'Certificate of Occupancy';

  @override
  void capture(CertificateOfOccupancyDraft draft, SnapshotWriter out) {
    out.scalar(
      'permitInfo.buildingPermitNumber',
      draft.permitInfo.buildingPermitNumber,
    );
    out.date(
      'permitInfo.buildingPermitDateIssued',
      draft.permitInfo.buildingPermitDateIssued,
    );
    out.enumValue(
      'permitInfo.certificateType',
      draft.permitInfo.certificateType,
    );
    out.scalar(
      'permitInfo.partialDescription',
      draft.permitInfo.partialDescription,
    );
    out.date('permitInfo.applicationDate', draft.permitInfo.applicationDate);
    out.scalar('owner.lastName', draft.owner.lastName);
    out.scalar('owner.firstName', draft.owner.firstName);
    out.scalar('owner.middleInitial', draft.owner.middleInitial);
    out.scalar('owner.address', draft.owner.address);
    out.scalar('owner.zipCode', draft.owner.zipCode);
    out.scalar('owner.contactNumber', draft.owner.contactNumber);
    out.scalar('owner.projectName', draft.owner.projectName);
    out.scalar('projectDetails.lotNumber', draft.projectDetails.lotNumber);
    out.scalar('projectDetails.blockNumber', draft.projectDetails.blockNumber);
    out.scalar('projectDetails.street', draft.projectDetails.street);
    out.scalar('projectDetails.barangay', draft.projectDetails.barangay);
    out.scalar('projectDetails.city', draft.projectDetails.city);
    out.enumValue(
      'projectDetails.occupancyGroup',
      draft.projectDetails.occupancyGroup,
    );
    out.scalar(
      'projectDetails.occupancyOtherDescription',
      draft.projectDetails.occupancyOtherDescription,
    );
    out.scalar(
      'projectDetails.numberOfStoreys',
      draft.projectDetails.numberOfStoreys,
    );
    out.scalar(
      'projectDetails.numberOfUnits',
      draft.projectDetails.numberOfUnits,
    );
    out.scalar(
      'projectDetails.totalFloorAreaSquareMeters',
      draft.projectDetails.totalFloorAreaSquareMeters,
    );
    out.date(
      'projectDetails.dateOfCompletion',
      draft.projectDetails.dateOfCompletion,
    );
    out.document(
      'requiredDocuments.asBuiltPlansUpload',
      draft.requiredDocuments.asBuiltPlansUpload,
      'As-built plans',
    );
    out.document(
      'requiredDocuments.constructionLogbookUpload',
      draft.requiredDocuments.constructionLogbookUpload,
      'Construction Logbook',
    );
    out.document(
      'requiredDocuments.civilWorksCertificateUpload',
      draft.requiredDocuments.civilWorksCertificateUpload,
      'Civil Works Certificate',
    );
    out.document(
      'requiredDocuments.electricalCertificateUpload',
      draft.requiredDocuments.electricalCertificateUpload,
      'Electrical Certificate',
    );
    out.document(
      'requiredDocuments.landTitleOrTaxDeclarationUpload',
      draft.requiredDocuments.landTitleOrTaxDeclarationUpload,
      'Land Title or Tax Declaration',
    );
    out.document(
      'requiredDocuments.barangayClearanceUpload',
      draft.requiredDocuments.barangayClearanceUpload,
      'Barangay Clearance',
    );
    out.document(
      'requiredDocuments.locationalClearanceUpload',
      draft.requiredDocuments.locationalClearanceUpload,
      'Locational Clearance',
    );
    out.document(
      'requiredDocuments.validGovernmentIdUpload',
      draft.requiredDocuments.validGovernmentIdUpload,
      'Valid Government ID',
    );
    out.document(
      'requiredDocuments.fireSafetyInspectionCertificateUpload',
      draft.requiredDocuments.fireSafetyInspectionCertificateUpload,
      'Fire Safety Inspection Certificate',
    );
    out.document(
      'requiredDocuments.otherDisciplineCertificatesUpload',
      draft.requiredDocuments.otherDisciplineCertificatesUpload,
      'Other Discipline Certificates',
    );
    out.document(
      'requiredDocuments.notarizedDocumentsUpload',
      draft.requiredDocuments.notarizedDocumentsUpload,
      'Notarized Documents',
    );
    out.document(
      'requiredDocuments.otherSupportingRequirementsUpload',
      draft.requiredDocuments.otherSupportingRequirementsUpload,
      'Other Supporting Requirements',
    );
    // The one growable collection in any of the nineteen drafts: documents
    // the applicant adds themselves. The name and description survive; the
    // file is dropped and named back by the applicant's own name for it,
    // which is more use than "other supporting document".
    out.rows('requiredDocuments.otherDocuments', [
      for (final other in draft.requiredDocuments.otherDocuments)
        out.row()
          ..scalar('name', other.name)
          ..scalar('description', other.description)
          ..document(
            'file',
            other.file,
            other.name.trim().isEmpty
                ? 'Other supporting document'
                : other.name.trim(),
          ),
    ]);
    out.scalar(
      'certification.submittedByName',
      draft.certification.submittedByName,
    );
    out.scalar('certification.ctcNumber', draft.certification.ctcNumber);
    out.date('certification.ctcDateIssued', draft.certification.ctcDateIssued);
    out.scalar(
      'certification.ctcPlaceIssued',
      draft.certification.ctcPlaceIssued,
    );
    out.document(
      'certification.signedDocumentUpload',
      draft.certification.signedDocumentUpload,
      'Signed Document',
    );
    out.scalar(
      'declaration.certifiesInformationIsAccurate',
      draft.declaration.certifiesInformationIsAccurate,
    );
    out.scalar(
      'declaration.certifiesConstructionMatchesApprovedPlans',
      draft.declaration.certifiesConstructionMatchesApprovedPlans,
    );
    out.scalar(
      'declaration.certifiesDocumentsAreAuthentic',
      draft.declaration.certifiesDocumentsAreAuthentic,
    );
    out.scalar(
      'declaration.understandsSubjectToInspectionAndEvaluation',
      draft.declaration.understandsSubjectToInspectionAndEvaluation,
    );
    out.enumValue('status', draft.status);
    out.date('lastSavedAt', draft.lastSavedAt);
  }

  @override
  void restore(CertificateOfOccupancyDraft draft, SnapshotReader input) {
    draft.permitInfo.buildingPermitNumber = input.string(
      'permitInfo.buildingPermitNumber',
    );
    draft.permitInfo.buildingPermitDateIssued = input.date(
      'permitInfo.buildingPermitDateIssued',
    );
    draft.permitInfo.certificateType = input.enumValue(
      'permitInfo.certificateType',
      CertificateType.values,
    );
    draft.permitInfo.partialDescription = input.string(
      'permitInfo.partialDescription',
    );
    draft.permitInfo.applicationDate =
        input.date('permitInfo.applicationDate') ?? DateTime.now();
    draft.owner.lastName = input.string('owner.lastName');
    draft.owner.firstName = input.string('owner.firstName');
    draft.owner.middleInitial = input.string('owner.middleInitial');
    draft.owner.address = input.string('owner.address');
    draft.owner.zipCode = input.string('owner.zipCode');
    draft.owner.contactNumber = input.string('owner.contactNumber');
    draft.owner.projectName = input.string('owner.projectName');
    draft.projectDetails.lotNumber = input.string('projectDetails.lotNumber');
    draft.projectDetails.blockNumber = input.string(
      'projectDetails.blockNumber',
    );
    draft.projectDetails.street = input.string('projectDetails.street');
    draft.projectDetails.barangay = input.string('projectDetails.barangay');
    draft.projectDetails.city = input.string('projectDetails.city');
    draft.projectDetails.occupancyGroup = input.enumValue(
      'projectDetails.occupancyGroup',
      OccupancyGroup.values,
    );
    draft.projectDetails.occupancyOtherDescription = input.string(
      'projectDetails.occupancyOtherDescription',
    );
    draft.projectDetails.numberOfStoreys = input.string(
      'projectDetails.numberOfStoreys',
    );
    draft.projectDetails.numberOfUnits = input.string(
      'projectDetails.numberOfUnits',
    );
    draft.projectDetails.totalFloorAreaSquareMeters = input.string(
      'projectDetails.totalFloorAreaSquareMeters',
    );
    draft.projectDetails.dateOfCompletion = input.date(
      'projectDetails.dateOfCompletion',
    );
    draft.requiredDocuments.asBuiltPlansUpload = input.document(
      'requiredDocuments.asBuiltPlansUpload',
    );
    draft.requiredDocuments.constructionLogbookUpload = input.document(
      'requiredDocuments.constructionLogbookUpload',
    );
    draft.requiredDocuments.civilWorksCertificateUpload = input.document(
      'requiredDocuments.civilWorksCertificateUpload',
    );
    draft.requiredDocuments.electricalCertificateUpload = input.document(
      'requiredDocuments.electricalCertificateUpload',
    );
    draft.requiredDocuments.landTitleOrTaxDeclarationUpload = input.document(
      'requiredDocuments.landTitleOrTaxDeclarationUpload',
    );
    draft.requiredDocuments.barangayClearanceUpload = input.document(
      'requiredDocuments.barangayClearanceUpload',
    );
    draft.requiredDocuments.locationalClearanceUpload = input.document(
      'requiredDocuments.locationalClearanceUpload',
    );
    draft.requiredDocuments.validGovernmentIdUpload = input.document(
      'requiredDocuments.validGovernmentIdUpload',
    );
    draft.requiredDocuments.fireSafetyInspectionCertificateUpload = input
        .document('requiredDocuments.fireSafetyInspectionCertificateUpload');
    draft.requiredDocuments.otherDisciplineCertificatesUpload = input.document(
      'requiredDocuments.otherDisciplineCertificatesUpload',
    );
    draft.requiredDocuments.notarizedDocumentsUpload = input.document(
      'requiredDocuments.notarizedDocumentsUpload',
    );
    draft.requiredDocuments.otherSupportingRequirementsUpload = input.document(
      'requiredDocuments.otherSupportingRequirementsUpload',
    );
    draft.requiredDocuments.otherDocuments
      ..clear()
      ..addAll([
        for (final row in input.rows('requiredDocuments.otherDocuments'))
          OccupancyOtherDocument(
            name: row.string('name'),
            description: row.string('description'),
          )..file = row.document('file'),
      ]);
    draft.certification.submittedByName = input.string(
      'certification.submittedByName',
    );
    draft.certification.ctcNumber = input.string('certification.ctcNumber');
    draft.certification.ctcDateIssued = input.date(
      'certification.ctcDateIssued',
    );
    draft.certification.ctcPlaceIssued = input.string(
      'certification.ctcPlaceIssued',
    );
    draft.certification.signedDocumentUpload = input.document(
      'certification.signedDocumentUpload',
    );
    draft.declaration.certifiesInformationIsAccurate = input.boolean(
      'declaration.certifiesInformationIsAccurate',
    );
    draft.declaration.certifiesConstructionMatchesApprovedPlans = input.boolean(
      'declaration.certifiesConstructionMatchesApprovedPlans',
    );
    draft.declaration.certifiesDocumentsAreAuthentic = input.boolean(
      'declaration.certifiesDocumentsAreAuthentic',
    );
    draft.declaration.understandsSubjectToInspectionAndEvaluation = input
        .boolean('declaration.understandsSubjectToInspectionAndEvaluation');
    // Not read back: a restored draft is always a draft. Honouring a
    // stored `submitted` would resurrect a filed application as editable.
    draft.status = CertificateOfOccupancyDraftStatus.draft;
    draft.lastSavedAt = input.date('lastSavedAt');
  }
}
