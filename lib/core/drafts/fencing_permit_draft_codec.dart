import '../models/fencing_permit_model.dart';
import 'draft_snapshot.dart';

/// Fencing Permit — the second wizard to survive a restart.
///
/// Second on purpose. The Building Permit is the app's largest and least
/// typical wizard; Fencing is the shape the other seventeen ancillary permits
/// share — a related-Building-Permit reference, an applicant, a site, a scope,
/// one or two professionals, a consent pair, specifications and a declaration.
/// Proving the mechanism on both means the remaining seventeen are repetition
/// rather than design, which is exactly what the scoping note claimed and what
/// this pair had to establish before anyone commits to it.
///
/// Two classes are deliberately not captured — see the completeness gate's
/// exemptions, which name them and say why.
class FencingPermitDraftCodec extends DraftCodec<FencingPermitDraft> {
  const FencingPermitDraftCodec();

  @override
  String get permitKey => 'fencing-permit';

  @override
  String get permitLabel => 'Fencing';

  /// Both the design professional and the supervisor, and both consent
  /// parties, share a shape. Captured through one helper each so the second
  /// role cannot drift from the first — which is how a copied block loses a
  /// field.
  void _captureProfessional(
    String prefix,
    FencingProfessionalInfo info,
    SnapshotWriter out,
  ) {
    out.scalar('$prefix.fullName', info.fullName);
    out.enumValue('$prefix.profession', info.profession);
    out.scalar('$prefix.address', info.address);
    out.scalar('$prefix.prcNumber', info.prcNumber);
    out.date('$prefix.prcValidityDate', info.prcValidityDate);
    out.scalar('$prefix.ptrNumber', info.ptrNumber);
    out.date('$prefix.ptrDateIssued', info.ptrDateIssued);
    out.scalar('$prefix.ptrPlaceIssued', info.ptrPlaceIssued);
    out.scalar('$prefix.tin', info.tin);
    out.date('$prefix.dateSigned', info.dateSigned);
  }

  void _restoreProfessional(
    String prefix,
    FencingProfessionalInfo info,
    SnapshotReader input,
  ) {
    info
      ..fullName = input.string('$prefix.fullName')
      ..profession = input.enumValue(
        '$prefix.profession',
        FencingProfessionType.values,
      )
      ..address = input.string('$prefix.address')
      ..prcNumber = input.string('$prefix.prcNumber')
      ..prcValidityDate = input.date('$prefix.prcValidityDate')
      ..ptrNumber = input.string('$prefix.ptrNumber')
      ..ptrDateIssued = input.date('$prefix.ptrDateIssued')
      ..ptrPlaceIssued = input.string('$prefix.ptrPlaceIssued')
      ..tin = input.string('$prefix.tin')
      ..dateSigned = input.date('$prefix.dateSigned');
  }

  void _capturePerson(
    String prefix,
    FencingConsentPerson person,
    SnapshotWriter out,
  ) {
    out.scalar('$prefix.printedName', person.printedName);
    out.scalar('$prefix.address', person.address);
    out.scalar('$prefix.ctcNumber', person.ctcNumber);
    out.date('$prefix.ctcDateIssued', person.ctcDateIssued);
    out.scalar('$prefix.ctcPlaceIssued', person.ctcPlaceIssued);
    out.date('$prefix.dateSigned', person.dateSigned);
  }

  void _restorePerson(
    String prefix,
    FencingConsentPerson person,
    SnapshotReader input,
  ) {
    person
      ..printedName = input.string('$prefix.printedName')
      ..address = input.string('$prefix.address')
      ..ctcNumber = input.string('$prefix.ctcNumber')
      ..ctcDateIssued = input.date('$prefix.ctcDateIssued')
      ..ctcPlaceIssued = input.string('$prefix.ctcPlaceIssued')
      ..dateSigned = input.date('$prefix.dateSigned');
  }

  @override
  void capture(FencingPermitDraft draft, SnapshotWriter out) {
    final related = draft.relatedBuildingPermit;
    out.scalar(
      'relatedBuildingPermit.buildingPermitNumber',
      related.buildingPermitNumber,
    );
    out.enumValue('relatedBuildingPermit.status', related.status);

    final applicant = draft.applicant;
    out.scalar('applicant.lastName', applicant.lastName);
    out.scalar('applicant.firstName', applicant.firstName);
    out.scalar('applicant.middleInitial', applicant.middleInitial);
    out.scalar('applicant.tin', applicant.tin);
    out.scalar('applicant.isOwnedByEnterprise', applicant.isOwnedByEnterprise);
    out.scalar('applicant.enterpriseName', applicant.enterpriseName);
    out.scalar('applicant.formOfOwnership', applicant.formOfOwnership);
    out.scalar('applicant.addressNumber', applicant.addressNumber);
    out.scalar('applicant.street', applicant.street);
    out.scalar('applicant.barangay', applicant.barangay);
    out.scalar('applicant.city', applicant.city);
    out.scalar('applicant.zipCode', applicant.zipCode);

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
    out.document(
      'constructionLocation.landTitleOrTaxDeclarationUpload',
      site.landTitleOrTaxDeclarationUpload,
      'Land Title or Tax Declaration',
    );
    out.document(
      'constructionLocation.barangayClearanceUpload',
      site.barangayClearanceUpload,
      'Barangay Clearance',
    );
    out.document(
      'constructionLocation.locationalClearanceUpload',
      site.locationalClearanceUpload,
      'Locational Clearance',
    );
    out.document(
      'constructionLocation.validGovernmentIdUpload',
      site.validGovernmentIdUpload,
      'Valid government ID',
    );

    out.enumSet('scopeOfWork.selectedScopes', draft.scopeOfWork.selectedScopes);
    out.scalar(
      'scopeOfWork.otherScopeDescription',
      draft.scopeOfWork.otherScopeDescription,
    );

    final professionals = draft.professionals;
    _captureProfessional(
      'professionals.designProfessional',
      professionals.designProfessional,
      out,
    );
    out.document(
      'professionals.designSignedDocumentUpload',
      professionals.designSignedDocumentUpload,
      "Design professional's signed and sealed document",
    );
    _captureProfessional(
      'professionals.supervisor',
      professionals.supervisor,
      out,
    );
    out.document(
      'professionals.supervisorSignedDocumentUpload',
      professionals.supervisorSignedDocumentUpload,
      "Supervisor's signed and sealed document",
    );

    final consent = draft.consent;
    _capturePerson('consent.applicant', consent.applicant, out);
    out.document(
      'consent.applicantSignedDocumentUpload',
      consent.applicantSignedDocumentUpload,
      "Applicant's signed consent",
    );
    out.scalar(
      'consent.isApplicantAlsoLotOwner',
      consent.isApplicantAlsoLotOwner,
    );
    _capturePerson('consent.lotOwner', consent.lotOwner, out);
    out.document(
      'consent.lotOwnerSignedDocumentUpload',
      consent.lotOwnerSignedDocumentUpload,
      "Lot owner's signed consent",
    );

    final specifications = draft.specifications;
    out.scalar(
      'specifications.fenceLengthMeters',
      specifications.fenceLengthMeters,
    );
    out.scalar(
      'specifications.fenceHeightMeters',
      specifications.fenceHeightMeters,
    );
    out.enumSet('specifications.selectedTypes', specifications.selectedTypes);
    out.scalar(
      'specifications.otherTypeDescription',
      specifications.otherTypeDescription,
    );

    final declaration = draft.reviewDeclaration;
    out.scalar(
      'reviewDeclaration.certifiesInformationIsAccurate',
      declaration.certifiesInformationIsAccurate,
    );
    out.scalar(
      'reviewDeclaration.understandsMustFollowApprovedPlansAndRegulations',
      declaration.understandsMustFollowApprovedPlansAndRegulations,
    );
    out.scalar(
      'reviewDeclaration.understandsDependsOnRelatedBuildingPermit',
      declaration.understandsDependsOnRelatedBuildingPermit,
    );
    out.scalar(
      'reviewDeclaration.understandsProfessionalDocumentsMustBeAuthentic',
      declaration.understandsProfessionalDocumentsMustBeAuthentic,
    );

    out.scalar(
      'useApplicantAddressForConstructionLocation',
      draft.useApplicantAddressForConstructionLocation,
    );
    out.enumValue('status', draft.status);
    out.date('lastSavedAt', draft.lastSavedAt);
  }

  @override
  void restore(FencingPermitDraft draft, SnapshotReader input) {
    draft.relatedBuildingPermit
      ..buildingPermitNumber = input.string(
        'relatedBuildingPermit.buildingPermitNumber',
      )
      ..status =
          input.enumValue(
            'relatedBuildingPermit.status',
            RelatedBuildingPermitStatus.values,
          ) ??
          RelatedBuildingPermitStatus.pending;

    draft.applicant
      ..lastName = input.string('applicant.lastName')
      ..firstName = input.string('applicant.firstName')
      ..middleInitial = input.string('applicant.middleInitial')
      ..tin = input.string('applicant.tin')
      ..isOwnedByEnterprise = input.boolean('applicant.isOwnedByEnterprise')
      ..enterpriseName = input.string('applicant.enterpriseName')
      ..formOfOwnership = input.nullableString('applicant.formOfOwnership')
      ..addressNumber = input.string('applicant.addressNumber')
      ..street = input.string('applicant.street')
      ..barangay = input.string('applicant.barangay')
      ..city = input.string('applicant.city')
      ..zipCode = input.string('applicant.zipCode');

    draft.constructionLocation
      ..lotNumber = input.string('constructionLocation.lotNumber')
      ..blockNumber = input.string('constructionLocation.blockNumber')
      ..tctNumber = input.string('constructionLocation.tctNumber')
      ..taxDeclarationNumber = input.string(
        'constructionLocation.taxDeclarationNumber',
      )
      ..street = input.string('constructionLocation.street')
      ..barangay = input.string('constructionLocation.barangay')
      ..city = input.string('constructionLocation.city');

    // `selectedScopes` and `selectedTypes` are `final` sets with initialisers,
    // so they are emptied and refilled rather than replaced.
    draft.scopeOfWork.selectedScopes
      ..clear()
      ..addAll(
        input.enumSet('scopeOfWork.selectedScopes', FencingScopeType.values),
      );
    draft.scopeOfWork.otherScopeDescription = input.string(
      'scopeOfWork.otherScopeDescription',
    );

    _restoreProfessional(
      'professionals.designProfessional',
      draft.professionals.designProfessional,
      input,
    );
    _restoreProfessional(
      'professionals.supervisor',
      draft.professionals.supervisor,
      input,
    );

    _restorePerson('consent.applicant', draft.consent.applicant, input);
    _restorePerson('consent.lotOwner', draft.consent.lotOwner, input);
    draft.consent.isApplicantAlsoLotOwner = input.nullableBoolean(
      'consent.isApplicantAlsoLotOwner',
    );

    draft.specifications
      ..fenceLengthMeters = input.string('specifications.fenceLengthMeters')
      ..fenceHeightMeters = input.string('specifications.fenceHeightMeters')
      ..otherTypeDescription = input.string(
        'specifications.otherTypeDescription',
      );
    draft.specifications.selectedTypes
      ..clear()
      ..addAll(
        input.enumSet('specifications.selectedTypes', FencingType.values),
      );

    draft.reviewDeclaration
      ..certifiesInformationIsAccurate = input.boolean(
        'reviewDeclaration.certifiesInformationIsAccurate',
      )
      ..understandsMustFollowApprovedPlansAndRegulations = input.boolean(
        'reviewDeclaration.understandsMustFollowApprovedPlansAndRegulations',
      )
      ..understandsDependsOnRelatedBuildingPermit = input.boolean(
        'reviewDeclaration.understandsDependsOnRelatedBuildingPermit',
      )
      ..understandsProfessionalDocumentsMustBeAuthentic = input.boolean(
        'reviewDeclaration.understandsProfessionalDocumentsMustBeAuthentic',
      );

    draft.useApplicantAddressForConstructionLocation = input.boolean(
      'useApplicantAddressForConstructionLocation',
    );
    // Not read back from the snapshot — see the Building Permit codec for why
    // a restored draft is always a draft.
    draft.status = FencingPermitDraftStatus.draft;
    draft.lastSavedAt = input.date('lastSavedAt');

    // Attachments, kept since 30 August 2026. Null when the file has gone —
    // the reader names it for the applicant in that case, so a document
    // cleared between saving and resuming is not silently missing.
    draft.constructionLocation.landTitleOrTaxDeclarationUpload = input.document(
      'constructionLocation.landTitleOrTaxDeclarationUpload',
    );
    draft.constructionLocation.barangayClearanceUpload = input.document(
      'constructionLocation.barangayClearanceUpload',
    );
    draft.constructionLocation.locationalClearanceUpload = input.document(
      'constructionLocation.locationalClearanceUpload',
    );
    draft.constructionLocation.validGovernmentIdUpload = input.document(
      'constructionLocation.validGovernmentIdUpload',
    );
    draft.professionals.designSignedDocumentUpload = input.document(
      'professionals.designSignedDocumentUpload',
    );
    draft.professionals.supervisorSignedDocumentUpload = input.document(
      'professionals.supervisorSignedDocumentUpload',
    );
    draft.consent.applicantSignedDocumentUpload = input.document(
      'consent.applicantSignedDocumentUpload',
    );
    draft.consent.lotOwnerSignedDocumentUpload = input.document(
      'consent.lotOwnerSignedDocumentUpload',
    );
  }
}
