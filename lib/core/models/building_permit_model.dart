import 'document_model.dart';
import 'payment_assessment_model.dart' show PaymentMethod;

/// Mock data model for the Unified Application Form for Building Permit and
/// Fire Safety Evaluation Clearance (DILG-DPWH-DICT-DTI JMC 2018-01),
/// reorganized into a 10-step mobile wizard. Everything here is
/// session-local, editable draft state — no network/database involved.

/// The official form supports New / Renewal / Amendatory; this wizard only
/// implements the New flow (entered from the Applications tab), so the
/// value is fixed and shown read-only.
enum BuildingPermitApplicationType { newApplication, renewal, amendatory }

extension BuildingPermitApplicationTypeX on BuildingPermitApplicationType {
  String get label {
    switch (this) {
      case BuildingPermitApplicationType.newApplication:
        return 'New';
      case BuildingPermitApplicationType.renewal:
        return 'Renewal';
      case BuildingPermitApplicationType.amendatory:
        return 'Amendatory';
    }
  }
}

/// The project category the user picked from the Applications tab grid,
/// passed into the wizard as route `extra` to preselect Scope of Work.
enum BuildingPermitProjectScope {
  newConstruction,
  renovation,
  extension,
  demolition,
}

extension BuildingPermitProjectScopeX on BuildingPermitProjectScope {
  String get label {
    switch (this) {
      case BuildingPermitProjectScope.newConstruction:
        return 'New Construction';
      case BuildingPermitProjectScope.renovation:
        return 'Renovation';
      case BuildingPermitProjectScope.extension:
        return 'Extension';
      case BuildingPermitProjectScope.demolition:
        return 'Demolition';
    }
  }
}

/// Official "Scope of Work" checklist from the Unified Application Form.
/// Multiple options may apply to a single project, so the draft stores a
/// [Set] rather than a single value.
enum ScopeOfWorkOption {
  newConstruction,
  erection,
  addition,
  alteration,
  renovation,
  conversion,
  repair,
  moving,
  raising,
  accessoryBuilding,
  others,
}

extension ScopeOfWorkOptionX on ScopeOfWorkOption {
  String get label {
    switch (this) {
      case ScopeOfWorkOption.newConstruction:
        return 'New Construction';
      case ScopeOfWorkOption.erection:
        return 'Erection';
      case ScopeOfWorkOption.addition:
        return 'Addition';
      case ScopeOfWorkOption.alteration:
        return 'Alteration';
      case ScopeOfWorkOption.renovation:
        return 'Renovation';
      case ScopeOfWorkOption.conversion:
        return 'Conversion';
      case ScopeOfWorkOption.repair:
        return 'Repair';
      case ScopeOfWorkOption.moving:
        return 'Moving';
      case ScopeOfWorkOption.raising:
        return 'Raising';
      case ScopeOfWorkOption.accessoryBuilding:
        return 'Accessory Building or Structure';
      case ScopeOfWorkOption.others:
        return 'Others';
    }
  }
}

/// Official "Use or Character of Occupancy" classification groups.
enum OccupancyGroup {
  groupA,
  groupB,
  groupC,
  groupD,
  groupE,
  groupF,
  groupG,
  groupH,
  groupI,
  groupJ,
  others,
}

extension OccupancyGroupX on OccupancyGroup {
  String get label {
    switch (this) {
      case OccupancyGroup.groupA:
        return 'Group A — Residential, Dwellings';
      case OccupancyGroup.groupB:
        return 'Group B — Residential Hotel, Apartment';
      case OccupancyGroup.groupC:
        return 'Group C — Educational, Recreational';
      case OccupancyGroup.groupD:
        return 'Group D — Institutional';
      case OccupancyGroup.groupE:
        return 'Group E — Business and Mercantile';
      case OccupancyGroup.groupF:
        return 'Group F — Industrial';
      case OccupancyGroup.groupG:
        return 'Group G — Industrial Storage and Hazardous';
      case OccupancyGroup.groupH:
        return 'Group H — Recreational or Assembly (below 1,000)';
      case OccupancyGroup.groupI:
        return 'Group I — Recreational or Assembly (1,000 or more)';
      case OccupancyGroup.groupJ:
        return 'Group J — Agricultural, Accessory';
      case OccupancyGroup.others:
        return 'Others';
    }
  }

  /// Short plain-language description shown beneath the option label.
  String get description {
    switch (this) {
      case OccupancyGroup.groupA:
        return 'Single-family and duplex houses.';
      case OccupancyGroup.groupB:
        return 'Apartments, hotels, and multi-unit dwellings.';
      case OccupancyGroup.groupC:
        return 'Schools and recreational facilities.';
      case OccupancyGroup.groupD:
        return 'Hospitals, jails, and similar institutions.';
      case OccupancyGroup.groupE:
        return 'Offices, shops, and stores.';
      case OccupancyGroup.groupF:
        return 'Factories and light industrial use.';
      case OccupancyGroup.groupG:
        return 'Storage of hazardous or combustible materials.';
      case OccupancyGroup.groupH:
        return 'Assembly venues for fewer than 1,000 people.';
      case OccupancyGroup.groupI:
        return 'Assembly venues for 1,000 or more people.';
      case OccupancyGroup.groupJ:
        return 'Farm structures and accessory buildings.';
      case OccupancyGroup.others:
        return 'Use not listed above.';
    }
  }
}

/// Licensed professional type required to supervise the construction work.
enum ProfessionType { architect, civilEngineer }

extension ProfessionTypeX on ProfessionType {
  String get label =>
      this == ProfessionType.architect ? 'Architect' : 'Civil Engineer';
}

/// How strictly a Step 8 document is required before the wizard allows
/// submission.
enum DocumentRequirement { required, requiredIfApplicable, optional }

extension DocumentRequirementX on DocumentRequirement {
  String get label {
    switch (this) {
      case DocumentRequirement.required:
        return 'Required';
      case DocumentRequirement.requiredIfApplicable:
        return 'Required when applicable';
      case DocumentRequirement.optional:
        return 'Optional';
    }
  }
}

enum BuildingPermitSubmissionStatus { draft, submittedForAssessment }

extension BuildingPermitSubmissionStatusX on BuildingPermitSubmissionStatus {
  String get label {
    switch (this) {
      case BuildingPermitSubmissionStatus.draft:
        return 'Draft';
      case BuildingPermitSubmissionStatus.submittedForAssessment:
        return 'Submitted for Assessment';
    }
  }
}

/// One uploadable requirement inside the Step 8 checklist.
class BuildingPermitDocumentSlot {
  final String id;
  final String label;
  final DocumentRequirement requirement;
  DocumentModel? document;

  BuildingPermitDocumentSlot({
    required this.id,
    required this.label,
    required this.requirement,
    this.document,
  });
}

/// A collapsible group of [BuildingPermitDocumentSlot]s (Official Forms,
/// Property Documents, Plans, Clearances).
class BuildingPermitDocumentCategory {
  final String title;
  final List<BuildingPermitDocumentSlot> slots;

  const BuildingPermitDocumentCategory({
    required this.title,
    required this.slots,
  });
}

/// Builds a fresh copy of the Step 8 document checklist (mutable per-draft,
/// so each application gets its own upload state).
List<BuildingPermitDocumentCategory> buildBuildingPermitDocumentChecklist() {
  BuildingPermitDocumentSlot slot(
    String id,
    String label,
    DocumentRequirement requirement,
  ) => BuildingPermitDocumentSlot(
    id: id,
    label: label,
    requirement: requirement,
  );

  return [
    BuildingPermitDocumentCategory(
      title: 'Official Application Forms',
      slots: [
        slot(
          'official-unified-form',
          'Accomplished Unified Application Form',
          DocumentRequirement.required,
        ),
        slot(
          'official-notarized-form',
          'Notarized Unified Application Form',
          DocumentRequirement.required,
        ),
        slot(
          'official-architectural-permit',
          'Architectural Permit',
          DocumentRequirement.requiredIfApplicable,
        ),
        slot(
          'official-civil-structural-permit',
          'Civil or Structural Permit',
          DocumentRequirement.requiredIfApplicable,
        ),
        slot(
          'official-electrical-permit',
          'Electrical Permit',
          DocumentRequirement.requiredIfApplicable,
        ),
        slot(
          'official-mechanical-permit',
          'Mechanical Permit',
          DocumentRequirement.requiredIfApplicable,
        ),
        slot(
          'official-sanitary-permit',
          'Sanitary Permit',
          DocumentRequirement.requiredIfApplicable,
        ),
        slot(
          'official-plumbing-permit',
          'Plumbing Permit',
          DocumentRequirement.requiredIfApplicable,
        ),
        slot(
          'official-electronics-permit',
          'Electronics Permit',
          DocumentRequirement.requiredIfApplicable,
        ),
        slot(
          'official-interior-permit',
          'Interior Permit',
          DocumentRequirement.requiredIfApplicable,
        ),
        slot(
          'official-fencing-permit',
          'Fencing Permit',
          DocumentRequirement.requiredIfApplicable,
        ),
        slot(
          'official-line-grade-permit',
          'Line and Grade or Geodetic Permit',
          DocumentRequirement.requiredIfApplicable,
        ),
      ],
    ),
    BuildingPermitDocumentCategory(
      title: 'Property Documents',
      slots: [
        slot(
          'property-tct-ort',
          'Certified True Copy of TCT or OCT',
          DocumentRequirement.required,
        ),
        slot(
          'property-tax-declaration',
          'Tax Declaration',
          DocumentRequirement.required,
        ),
        slot(
          'property-tax-receipt',
          'Latest Real Property Tax Receipt',
          DocumentRequirement.required,
        ),
        slot(
          'property-lease-contract',
          'Contract of Lease',
          DocumentRequirement.requiredIfApplicable,
        ),
        slot(
          'property-deed-of-sale',
          'Deed of Sale',
          DocumentRequirement.requiredIfApplicable,
        ),
        slot(
          'property-owners-consent',
          "Owner's Consent",
          DocumentRequirement.requiredIfApplicable,
        ),
      ],
    ),
    BuildingPermitDocumentCategory(
      title: 'Plans and Technical Documents',
      slots: [
        slot(
          'plans-architectural',
          'Architectural Plans',
          DocumentRequirement.required,
        ),
        slot(
          'plans-civil-structural',
          'Civil or Structural Plans',
          DocumentRequirement.required,
        ),
        slot(
          'plans-electrical',
          'Electrical Plans',
          DocumentRequirement.required,
        ),
        slot(
          'plans-mechanical',
          'Mechanical Plans',
          DocumentRequirement.requiredIfApplicable,
        ),
        slot('plans-sanitary', 'Sanitary Plans', DocumentRequirement.required),
        slot('plans-plumbing', 'Plumbing Plans', DocumentRequirement.required),
        slot(
          'plans-electronics',
          'Electronics Plans',
          DocumentRequirement.requiredIfApplicable,
        ),
        slot(
          'plans-fire-protection',
          'Fire Protection Plans',
          DocumentRequirement.requiredIfApplicable,
        ),
        slot(
          'plans-bill-of-materials',
          'Bill of Materials and Cost Estimates',
          DocumentRequirement.required,
        ),
        slot(
          'plans-technical-specs',
          'Technical Specifications',
          DocumentRequirement.required,
        ),
        slot(
          'plans-structural-analysis',
          'Structural Analysis or Calculations',
          DocumentRequirement.requiredIfApplicable,
        ),
        slot(
          'plans-lot-survey',
          'Lot or Survey Plan',
          DocumentRequirement.required,
        ),
        slot(
          'plans-safety-health-program',
          'Construction Safety and Health Program',
          DocumentRequirement.requiredIfApplicable,
        ),
      ],
    ),
    BuildingPermitDocumentCategory(
      title: 'Clearances and Identification',
      slots: [
        slot(
          'clearance-locational-zoning',
          'Locational or Zoning Clearance',
          DocumentRequirement.required,
        ),
        slot(
          'clearance-barangay',
          'Barangay Clearance',
          DocumentRequirement.required,
        ),
        slot(
          'clearance-fire-safety',
          'Fire Safety-related Requirements',
          DocumentRequirement.required,
        ),
        slot(
          'clearance-applicant-id',
          "Applicant's Valid Government ID",
          DocumentRequirement.required,
        ),
        slot(
          'clearance-professional-prc-ptr',
          'Professional PRC ID and PTR',
          DocumentRequirement.required,
        ),
        slot(
          'clearance-authorization-letter',
          'Authorization Letter or SPA',
          DocumentRequirement.requiredIfApplicable,
        ),
      ],
    ),
  ];
}

/// Step 1 — Applicant and Ownership.
class ApplicantOwnershipDetails {
  String lastName = '';
  String firstName = '';
  String middleInitial = '';
  String tin = '';
  String contactNumber = '';
  bool isOwnedByEnterprise = false;
  String enterpriseName = '';
  String formOfOwnership = '';
  String houseNumber = '';
  String street = '';
  String barangay = '';
  String city = '';
  String province = '';
  String zipCode = '';
}

/// Step 2 — Construction/Property Location.
class PropertyLocationDetails {
  String lotNumber = '';
  String blockNumber = '';
  String tctOrOctNumber = '';
  String taxDeclarationNumber = '';
  String street = '';
  String barangay = '';
  String city = '';
  String province = '';
  String zipCode = '';
}

/// Step 5 — Project Details.
class ProjectDetails {
  String totalFloorArea = '';
  String lotArea = '';
  String estimatedCost = '';
  DateTime? proposedConstructionDate;
  DateTime? expectedCompletionDate;
}

/// Step 6 — Architect or Civil Engineer in charge.
class ProfessionalDetails {
  String fullName = '';
  ProfessionType? profession;
  String address = '';
  String prcNumber = '';
  DateTime? prcValidityDate;
  String ptrNumber = '';
  DateTime? ptrDateIssued;
  String ptrPlaceIssued = '';
  String tin = '';
  String contactNumber = '';
  DateTime? dateSigned;
  DocumentModel? prcIdUpload;
  DocumentModel? ptrUpload;
  DocumentModel? signedSealedFormUpload;
}

/// Step 7 — Consent and Representative.
class ConsentDetails {
  bool? isRegisteredOwner;

  // Shown only when isRegisteredOwner == false.
  String representativeFullName = '';
  String representativeAddress = '';
  String representativeCtcNumber = '';
  DateTime? representativeCtcDateIssued;
  String representativeCtcPlaceIssued = '';
  String representativeContactNumber = '';
  String relationshipToApplicant = '';
  String authorizationType = '';
  DocumentModel? ownerValidIdUpload;
  DocumentModel? applicantValidIdUpload;
  DocumentModel? authorizationLetterUpload;
  DocumentModel? proofOfOwnershipUpload;

  // Always shown once the question above is answered.
  String applicantCtcNumber = '';
  DateTime? applicantCtcDateIssued;
  String applicantCtcPlaceIssued = '';
  bool declarationConfirmed = false;
}

/// The full mutable draft for one Building Permit application session.
/// Deliberately mutable (unlike the app's immutable domain models) since it
/// represents actively-edited wizard state, not a persisted record.
class BuildingPermitDraft {
  BuildingPermitDraft({this.projectScope});

  final BuildingPermitApplicationType applicationType =
      BuildingPermitApplicationType.newApplication;
  BuildingPermitProjectScope? projectScope;

  final ApplicantOwnershipDetails applicant = ApplicantOwnershipDetails();
  final PropertyLocationDetails location = PropertyLocationDetails();

  final Set<ScopeOfWorkOption> scopeOfWork = {};
  String scopeOfWorkOtherDetail = '';

  OccupancyGroup? occupancyGroup;
  String occupancyOtherDetail = '';
  String occupancyClassification = '';
  String numberOfUnits = '';

  final ProjectDetails project = ProjectDetails();
  final ProfessionalDetails professional = ProfessionalDetails();
  final ConsentDetails consent = ConsentDetails();

  final List<BuildingPermitDocumentCategory> documentCategories =
      buildBuildingPermitDocumentChecklist();

  bool declareTrueAndCorrect = false;
  bool declareUnderstandDelay = false;
  bool declareSignedSealed = false;
  bool declareDataPrivacy = false;

  PaymentMethod? paymentMethod;
  DocumentModel? paymentProof;

  BuildingPermitSubmissionStatus status = BuildingPermitSubmissionStatus.draft;
  String? referenceNumber;
  DateTime? submittedDate;
  DateTime? lastSavedAt;

  bool get allDeclarationsConfirmed =>
      declareTrueAndCorrect &&
      declareUnderstandDelay &&
      declareSignedSealed &&
      declareDataPrivacy;

  List<BuildingPermitDocumentSlot> get missingRequiredDocuments =>
      documentCategories
          .expand((category) => category.slots)
          .where(
            (slot) =>
                slot.requirement == DocumentRequirement.required &&
                slot.document == null,
          )
          .toList();
}

/// Maps the project selected on the Applications tab to the closest
/// official Scope of Work checklist option. Demolition has no equivalent
/// in the official checklist, so it is intentionally left unmapped — the
/// UI preserves the demolition context separately instead of forcing an
/// incorrect match.
ScopeOfWorkOption? mapProjectScopeToScopeOfWork(
  BuildingPermitProjectScope? scope,
) {
  switch (scope) {
    case BuildingPermitProjectScope.newConstruction:
      return ScopeOfWorkOption.newConstruction;
    case BuildingPermitProjectScope.renovation:
      return ScopeOfWorkOption.renovation;
    case BuildingPermitProjectScope.extension:
      return ScopeOfWorkOption.addition;
    case BuildingPermitProjectScope.demolition:
    case null:
      return null;
  }
}
