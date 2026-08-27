import '../utils/validators.dart';
import 'document_model.dart';

/// Mock, frontend-only data model for the Zoning / Locational Clearance
/// application wizard.
///
/// Based on the Municipality of Castilla MPDO's own **Application for
/// Locational Clearance / Certificate of Zoning Compliance (Form FM-MPD-12)**,
/// as transcribed in the requirements catalog. Its sixteen documentary
/// requirements map onto Step 4 here.
///
/// Two things set this permit apart from every other wizard in the app, and
/// both are deliberate:
///
/// **It is not the Office of the Building Official's.** Locational clearance
/// is issued by the Municipal Planning and Development Office, and its fee is
/// assessed under the zoning ordinance rather than the National Building Code.
/// Any office-facing copy must say MPDO.
///
/// **It is an input to other permits, not an ancillary of one.** Most permit
/// types in the catalog list a Locational Clearance among the documents the
/// applicant must already hold. Until this wizard existed the app asked for a
/// clearance it gave no way to obtain — which is why this is the first of the
/// three missing permit types to be built.
///
/// Kept fully decoupled from the other permits, as they are from each other:
/// its own draft, its own provider, its own steps.

/// Whether the applicant owns the lot, and who consents if not.
class ZoningApplicantInfo {
  String firstName = '';
  String middleName = '';
  String lastName = '';

  /// The firm, when the application is filed under one.
  String enterpriseName = '';

  String contactNumber = '';
  String emailAddress = '';
  String address = '';

  bool get isValid =>
      Validators.required(firstName) == null &&
      Validators.required(lastName) == null &&
      Validators.required(contactNumber) == null &&
      Validators.required(address) == null;
}

/// The lot the clearance is sought for.
class ZoningSiteLocation {
  String lotNumber = '';
  String blockNumber = '';
  String tctNumber = '';
  String taxDeclarationNumber = '';
  String street = '';
  String barangay = '';
  String city = '';

  /// Lot area in square metres, as written on the title.
  String lotArea = '';

  bool get isValid =>
      Validators.required(lotNumber) == null &&
      Validators.required(street) == null &&
      Validators.required(barangay) == null &&
      Validators.required(city) == null &&
      Validators.required(lotArea) == null;
}

/// What the applicant intends to do with the lot.
///
/// The Zoning Officer decides whether the proposed use is allowed in the zone
/// the lot sits in, so this is the substance of the application rather than
/// paperwork about it.
class ZoningProposedUse {
  /// "Residential", "Commercial", "Institutional" — as the applicant states it.
  String proposedUse = '';

  /// A short description of the project itself.
  String projectDescription = '';

  /// Total floor area proposed, in square metres.
  String floorArea = '';

  String estimatedProjectCost = '';

  /// Present use of the lot, which may differ from what is proposed.
  String existingUse = '';

  bool get isValid =>
      Validators.required(proposedUse) == null &&
      Validators.required(projectDescription) == null;
}

/// The sixteen documents FM-MPD-12 asks for.
///
/// Field names follow the requirements catalog's document ids so the two can
/// be checked against each other rather than drifting.
class ZoningRequiredDocuments {
  // The baseline every permit type needs.
  DocumentModel? landTitleUpload;
  DocumentModel? barangayClearanceUpload;
  DocumentModel? validGovernmentIdUpload;

  // FM-MPD-12's own list.
  DocumentModel? letterRequestUpload;
  DocumentModel? siteDevelopmentPlanUpload;
  DocumentModel? vicinityMapUpload;
  DocumentModel? sketchPlanUpload;
  DocumentModel? billOfMaterialsUpload;
  DocumentModel? proofOfOwnershipUpload;
  DocumentModel? taxDeclarationUpload;
  DocumentModel? landTaxReceiptUpload;
  DocumentModel? barangayBuildingClearanceUpload;
  DocumentModel? cedulaUpload;

  /// Conditional. The catalog marks these three optional, and presenting an
  /// optional document as mandatory costs the applicant a trip they did not
  /// owe.
  DocumentModel? ownerWrittenConsentUpload;
  DocumentModel? dpwhClearanceUpload;
  DocumentModel? environmentalComplianceCertificateUpload;

  bool get isValid =>
      landTitleUpload != null &&
      barangayClearanceUpload != null &&
      validGovernmentIdUpload != null &&
      letterRequestUpload != null &&
      siteDevelopmentPlanUpload != null &&
      vicinityMapUpload != null &&
      sketchPlanUpload != null &&
      billOfMaterialsUpload != null &&
      proofOfOwnershipUpload != null &&
      taxDeclarationUpload != null &&
      landTaxReceiptUpload != null &&
      barangayBuildingClearanceUpload != null &&
      cedulaUpload != null;
}

/// The applicant's certification, before submission.
class ZoningCertification {
  String submittedByName = '';
  bool certifiesTrueAndCorrect = false;
  bool acceptsOcularInspection = false;

  bool get isValid =>
      Validators.required(submittedByName) == null &&
      certifiesTrueAndCorrect &&
      acceptsOcularInspection;
}

enum ZoningPermitDraftStatus { draft, submitted }

/// The full mutable draft for one Zoning / Locational Clearance application.
class ZoningPermitDraft {
  final ZoningApplicantInfo applicant = ZoningApplicantInfo();
  final ZoningSiteLocation siteLocation = ZoningSiteLocation();
  final ZoningProposedUse proposedUse = ZoningProposedUse();
  final ZoningRequiredDocuments requiredDocuments = ZoningRequiredDocuments();
  final ZoningCertification certification = ZoningCertification();

  ZoningPermitDraftStatus status = ZoningPermitDraftStatus.draft;
  DateTime? lastSavedAt;

  bool get isStep1Valid => applicant.isValid;
  bool get isStep2Valid => siteLocation.isValid;
  bool get isStep3Valid => proposedUse.isValid;
  bool get isStep4Valid => requiredDocuments.isValid;
  bool get isStep5Valid => certification.isValid;

  /// Steps whose validation currently passes, for the drafts list.
  int get completedSteps => [
    isStep1Valid,
    isStep2Valid,
    isStep3Valid,
    isStep4Valid,
    isStep5Valid,
  ].where((valid) => valid).length;
}
