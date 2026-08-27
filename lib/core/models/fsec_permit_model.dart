import '../utils/validators.dart';
import 'document_model.dart';

/// Mock, frontend-only data model for the Fire Safety Evaluation Clearance (FSEC) wizard.
///
/// Built from the BFP Castilla Fire Station's own **BFP-QSF-FSED-001** form, as
/// transcribed in the requirements catalog.
///
/// A Fire Safety Evaluation Clearance is a precondition of the Building Permit
/// under RA 9514: the BFP evaluates the proposed plans before the building
/// office issues. Until this wizard existed the app's Fire Safety evaluation
/// stage reported on a clearance the applicant had no way to apply for.
///
/// Collected and assessed by the **Bureau of Fire Protection**, not the LGU —
/// which is why its fee must never be presented as payable at the OBO cashier.
/// Kept fully decoupled from every other permit, as they are from each other.

/// Who is applying.
class FSECApplicantInfo {
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
class FSECProjectDetails {
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

/// What BFP-QSF-FSED-001 asks for.
class FSECRequiredDocuments {
  DocumentModel? landTitleUpload;
  DocumentModel? barangayClearanceUpload;
  DocumentModel? locationalClearanceUpload;
  DocumentModel? validGovernmentIdUpload;
  DocumentModel? planSetUpload;
  DocumentModel? costEstimateUpload;
  DocumentModel? ownerWrittenConsentUpload;
  DocumentModel? fireSafetyComplianceReportUpload;
  DocumentModel? hotWorksClearanceUpload;

  bool get isValid =>
      landTitleUpload != null &&
      barangayClearanceUpload != null &&
      locationalClearanceUpload != null &&
      validGovernmentIdUpload != null &&
      planSetUpload != null &&
      costEstimateUpload != null;
}

/// The applicant's certification before submission.
class FSECCertification {
  String submittedByName = '';
  bool certifiesTrueAndCorrect = false;
  bool acceptsFireSafetyInspection = false;

  bool get isValid =>
      Validators.required(submittedByName) == null &&
      certifiesTrueAndCorrect &&
      acceptsFireSafetyInspection;
}

enum FSECPermitDraftStatus { draft, submitted }

/// The full mutable draft for one FSEC application.
class FsecPermitDraft {
  final FSECApplicantInfo applicant = FSECApplicantInfo();
  final FSECProjectDetails project = FSECProjectDetails();
  final FSECRequiredDocuments requiredDocuments = FSECRequiredDocuments();
  final FSECCertification certification = FSECCertification();

  FSECPermitDraftStatus status = FSECPermitDraftStatus.draft;
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
