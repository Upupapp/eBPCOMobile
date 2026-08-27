import '../utils/validators.dart';
import 'document_model.dart';

/// Mock, frontend-only data model for the Fire Safety Inspection Certificate (FSIC) wizard.
///
/// Built from the BFP Castilla Fire Station's own **BFP-QSF-FSED-002** form, as
/// transcribed in the requirements catalog.
///
/// A Fire Safety Inspection Certificate is a precondition of the Certificate
/// of Occupancy under RA 9514: the BFP inspects the completed building before
/// the building office certifies it fit to occupy. The app's Certificate of
/// Occupancy wizard asks the applicant to upload an FSIC, and until now gave
/// them no way to obtain one.
///
/// Collected and assessed by the **Bureau of Fire Protection**, not the LGU —
/// which is why its fee must never be presented as payable at the OBO cashier.
/// Kept fully decoupled from every other permit, as they are from each other.

/// Who is applying.
class FSICApplicantInfo {
  String firstName = '';
  String middleName = '';
  String lastName = '';
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

/// The building the clearance concerns.
class FSICProjectDetails {
  String projectName = '';
  String projectAddress = '';

  /// Occupancy group as classified under the Fire Code.
  String occupancyType = '';

  String totalFloorArea = '';
  String numberOfStoreys = '';

  /// The Building Permit this clearance is filed against.
  String relatedBuildingPermitNumber = '';

  bool get isValid =>
      Validators.required(projectName) == null &&
      Validators.required(projectAddress) == null &&
      Validators.required(occupancyType) == null;
}

/// What BFP-QSF-FSED-002 asks for.
class FSICRequiredDocuments {
  DocumentModel? landTitleUpload;
  DocumentModel? barangayClearanceUpload;
  DocumentModel? locationalClearanceUpload;
  DocumentModel? validGovernmentIdUpload;
  DocumentModel? oboEndorsementUpload;
  DocumentModel? completionCertificateUpload;
  DocumentModel? assessmentCopyUpload;
  DocumentModel? ownerWrittenConsentUpload;
  DocumentModel? asBuiltPlanUpload;
  DocumentModel? commissioningReportUpload;

  bool get isValid =>
      landTitleUpload != null &&
      barangayClearanceUpload != null &&
      locationalClearanceUpload != null &&
      validGovernmentIdUpload != null &&
      oboEndorsementUpload != null &&
      completionCertificateUpload != null &&
      assessmentCopyUpload != null;
}

/// The applicant's certification before submission.
class FSICCertification {
  String submittedByName = '';
  bool certifiesTrueAndCorrect = false;
  bool acceptsFireSafetyInspection = false;

  bool get isValid =>
      Validators.required(submittedByName) == null &&
      certifiesTrueAndCorrect &&
      acceptsFireSafetyInspection;
}

enum FSICPermitDraftStatus { draft, submitted }

/// The full mutable draft for one FSIC application.
class FsicPermitDraft {
  final FSICApplicantInfo applicant = FSICApplicantInfo();
  final FSICProjectDetails project = FSICProjectDetails();
  final FSICRequiredDocuments requiredDocuments = FSICRequiredDocuments();
  final FSICCertification certification = FSICCertification();

  FSICPermitDraftStatus status = FSICPermitDraftStatus.draft;
  DateTime? lastSavedAt;

  bool get isStep1Valid => applicant.isValid;
  bool get isStep2Valid => project.isValid;
  bool get isStep3Valid => requiredDocuments.isValid;
  bool get isStep4Valid => certification.isValid;

  int get completedSteps => [
    isStep1Valid,
    isStep2Valid,
    isStep3Valid,
    isStep4Valid,
  ].where((valid) => valid).length;
}
