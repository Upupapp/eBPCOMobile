import '../utils/validators.dart';
import 'document_model.dart';

/// Mock, frontend-only data model for the Building Permit application
/// wizard. All 9 steps are implemented.

/// Official "Form of Ownership" choices shown when the construction is
/// owned by an enterprise.
const List<String> formsOfOwnership = [
  'Sole Proprietorship',
  'Partnership',
  'Corporation',
  'Cooperative',
  'Government',
  'Others',
];

/// Step 1 — Applicant Information. The application type is fixed to "New
/// Application" for this flow (renewal/amendment aren't part of this
/// rebuild), so it's not a field the user can change.
class ApplicantInfo {
  String firstName = '';
  String middleName = '';
  String lastName = '';
  String tin = '';
  String mobileNumber = '';
  String email = '';
  bool isOwnedByEnterprise = false;
  String enterpriseName = '';
  String? formOfOwnership;

  bool get isValid {
    final basicsValid =
        Validators.required(firstName) == null &&
        Validators.required(lastName) == null &&
        Validators.philippineMobile(mobileNumber) == null &&
        Validators.email(email) == null;
    if (!basicsValid) return false;
    if (!isOwnedByEnterprise) return true;
    return Validators.required(enterpriseName) == null &&
        formOfOwnership != null;
  }
}

/// Step 2 (part 1) — Applicant Address.
class ApplicantAddress {
  String houseNumber = '';
  String street = '';
  String barangay = '';
  String city = '';
  String province = '';
  String zipCode = '';

  bool get isValid =>
      Validators.required(street) == null &&
      Validators.required(barangay) == null &&
      Validators.required(city) == null &&
      Validators.required(province) == null;
}

/// Step 2 (part 2) — Construction Location.
class ConstructionLocation {
  String lotNumber = '';
  String blockNumber = '';
  String tctNumber = '';
  String taxDeclarationNumber = '';
  String street = '';
  String barangay = '';
  String city = '';
  String province = '';
  String zipCode = '';

  bool get isValid =>
      Validators.required(lotNumber) == null &&
      Validators.required(street) == null &&
      Validators.required(barangay) == null &&
      Validators.required(city) == null &&
      Validators.required(province) == null;
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

  /// Legalising a structure built without a permit.
  ///
  /// Added 31 August 2026 by reading Castilla's Unified Application Form for
  /// Building Permit, whose Scope of Work box lists twelve options; this app
  /// had eleven. An applicant regularising an existing building had to pick
  /// "Others" and type it, on the one permit where the office most needs to
  /// know — legalisation follows a different assessment path under PD 1096.
  legalizationOfExistingBuilding,
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
      case ScopeOfWorkOption.legalizationOfExistingBuilding:
        return 'Legalization of Existing Building';
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

  /// Short plain-language description shown beneath the option label so
  /// users don't need to already know the National Building Code terms.
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

/// Step 3 — Project Information: scope of work + building use. Scope of
/// Work is preselected to "New Construction" since this wizard is reached
/// through Applications → Building Permit → New Construction, but stays
/// fully editable — the flow doesn't require it to stay fixed.
class ProjectInformation {
  Set<ScopeOfWorkOption> scopeOfWork = {ScopeOfWorkOption.newConstruction};
  String scopeOfWorkOtherDescription = '';
  OccupancyGroup? occupancyGroup;
  String occupancyOtherDescription = '';

  bool get isValid {
    if (scopeOfWork.isEmpty) return false;
    if (scopeOfWork.contains(ScopeOfWorkOption.others) &&
        Validators.required(scopeOfWorkOtherDescription) != null) {
      return false;
    }
    if (occupancyGroup == null) return false;
    if (occupancyGroup == OccupancyGroup.others &&
        Validators.required(occupancyOtherDescription) != null) {
      return false;
    }
    return true;
  }
}

/// Step 4 — Building Details: occupancy, area, cost, and schedule.
class BuildingDetails {
  String occupancyClassification = '';
  String numberOfUnits = '';

  /// How many storeys the building has.
  ///
  /// Added 31 August 2026 from the Unified Application Form, which asks for it
  /// beside Number of Units, Total Floor Area and Lot Area — all three of
  /// which this app already collected. It is not decoration: storey count
  /// drives occupancy and structural review under PD 1096, and an application
  /// that omits it is incomplete on the paper the office files.
  String numberOfStorey = '';

  String totalFloorArea = '';
  String lotArea = '';

  /// TOTAL ESTIMATED COST, as printed at the head of the form's cost block.
  String estimatedConstructionCost = '';

  // The five components the form breaks that total into, and the equipment
  // line beside them.
  //
  // Added 31 August 2026. The app asked for one figure; the form asks for six.
  // That is not a formatting difference — **building permit fees are assessed
  // from these components**, so a single number is materially less than the
  // office needs, and an applicant who gives only a total will be asked for
  // the breakdown at the counter.
  //
  // All optional. The form's own total is the required field, and an applicant
  // filing a simple residential permit may have nothing to put against
  // electronics or mechanical.
  String estimatedCostBuilding = '';
  String estimatedCostElectrical = '';
  String estimatedCostMechanical = '';
  String estimatedCostElectronics = '';
  String estimatedCostPlumbing = '';

  /// COST OF EQUIPMENT INSTALLED — the column beside the five components.
  String costOfEquipmentInstalled = '';

  DateTime? proposedConstructionDate;
  DateTime? expectedCompletionDate;

  bool get isValid {
    final proposed = proposedConstructionDate;
    final expected = expectedCompletionDate;
    if (proposed == null || expected == null) return false;
    if (!expected.isAfter(proposed)) return false;

    return Validators.required(occupancyClassification) == null &&
        Validators.positiveWholeNumber(numberOfUnits) == null &&
        Validators.positiveWholeNumber(numberOfStorey) == null &&
        Validators.positiveDecimal(totalFloorArea) == null &&
        Validators.positiveDecimal(lotArea) == null &&
        Validators.positiveDecimal(estimatedConstructionCost) == null;
  }
}

/// Licensed professional type required to supervise the construction work.
enum ProfessionType { architect, civilEngineer }

extension ProfessionTypeX on ProfessionType {
  String get label =>
      this == ProfessionType.architect ? 'Architect' : 'Civil Engineer';
}

/// Step 5 — Architect or Civil Engineer in charge. `dateSigned` is kept
/// optional for this prototype, matching the task's instruction to only
/// require it if the existing model already did (it didn't exist before).
class ProfessionalInCharge {
  String fullName = '';
  ProfessionType? profession;
  String address = '';
  String contactNumber = '';
  String tin = '';

  String prcNumber = '';
  DateTime? prcValidityDate;
  String ptrNumber = '';
  DateTime? ptrDateIssued;
  String ptrPlaceIssued = '';
  DateTime? dateSigned;

  DocumentModel? prcIdUpload;
  DocumentModel? ptrUpload;
  DocumentModel? signedSealedUpload;

  bool get isValid =>
      Validators.required(fullName) == null &&
      profession != null &&
      Validators.required(address) == null &&
      Validators.required(prcNumber) == null &&
      prcValidityDate != null &&
      Validators.required(ptrNumber) == null &&
      ptrDateIssued != null &&
      Validators.required(ptrPlaceIssued) == null &&
      prcIdUpload != null &&
      ptrUpload != null &&
      signedSealedUpload != null;

  /// Non-blocking heads-up (per the task: warn instead of blocking
  /// Continue) shown when the PRC validity date has already passed.
  bool get prcAppearsExpired =>
      prcValidityDate != null && prcValidityDate!.isBefore(DateTime.now());

  /// Non-blocking heads-up shown if the PTR date issued is in the future,
  /// which shouldn't normally happen for an already-issued PTR.
  bool get ptrDateIssuedInFuture =>
      ptrDateIssued != null && ptrDateIssued!.isAfter(DateTime.now());
}

/// Step 6 — Consent & Authorization. When the applicant is not the
/// registered property owner, a representative's details, CTC info, and
/// two supporting uploads (Authorization Letter/SPA + Owner Valid ID) are
/// required; when the applicant IS the owner, none of that applies.
class ConsentAuthorization {
  bool? isRegisteredOwner;

  String representativeName = '';
  String representativeAddress = '';

  // Boxes 3 and 4 of the Unified Application Form ask for a
  // `Gov't Issued ID No.`, with its date and place of issue — NOT a Community
  // Tax Certificate. The ancillary forms (Fencing, Civil/Structural,
  // Electrical and the rest) do ask for a C.T.C. No., which is why this app
  // models a cedula everywhere and why nobody noticed the building permit is
  // the exception.
  //
  // Read off the form on 31 August 2026. The fields are renamed and the labels
  // corrected; the STORAGE KEYS deliberately keep their old names so that a
  // draft saved before today still restores — see the codec, where the new key
  // is written and the old one is read as a fallback.
  String governmentIdNumber = '';
  DateTime? governmentIdDateIssued;
  String governmentIdPlaceIssued = '';

  DocumentModel? authorizationLetterUpload;
  DocumentModel? ownerValidIdUpload;

  bool get isValid {
    if (isRegisteredOwner == null) return false;
    if (isRegisteredOwner == true) return true;
    return Validators.required(representativeName) == null &&
        Validators.required(representativeAddress) == null &&
        Validators.required(governmentIdNumber) == null &&
        governmentIdDateIssued != null &&
        Validators.required(governmentIdPlaceIssued) == null &&
        authorizationLetterUpload != null &&
        ownerValidIdUpload != null;
  }
}

/// Step 7 — Required Documents: the consolidated document-checklist annex
/// from the Unified Application Form, grouped the same way the official
/// form groups them. These are tracked independently from any
/// similarly-named uploads collected earlier in the wizard (e.g. Step 5's
/// professional documents) since this step represents the full annex
/// checklist, not a shortcut back to those fields.
class RequiredDocuments {
  // Reconciled against Castilla's own `Building Permit Documentary
  // Requirements` checklist on 31 August 2026 — the file this app has bundled
  // all along, and which the catalogue entry for this permit already cited.
  //
  // The catalogue was a faithful transcription of it. This class was not: it
  // made four documents mandatory that the checklist does not list at all, and
  // it had no slot for one that it does.

  // Property Documents

  /// The checklist's first line: *"Certified True Copy of OCT/TCT — 2 Copies"*,
  /// with indented alternatives — Deed of Sale, Deed of Donation, Lease
  /// Contract, Assignment of Rights, *"or any valid proof of ownership"*.
  ///
  /// The field keeps its name so drafts saved before today still restore; what
  /// changed is that the app no longer demands a title specifically. An
  /// applicant building on leased land, or on land taken by deed, could not
  /// file at all.
  DocumentModel? landTitleUpload;

  /// Not on Castilla's checklist, and no longer required.
  ///
  /// It may serve as the *"any valid proof of ownership"* alternative above,
  /// which is why the slot stays — but requiring it as well as a title asked
  /// an applicant for a document the office does not ask for.
  DocumentModel? taxDeclarationUpload;

  /// Not on Castilla's checklist. Optional since 31 August 2026.
  DocumentModel? realPropertyTaxReceiptUpload;

  /// The checklist's *"Valid ID of Applicant and Owner of Lot"*.
  ///
  /// Had no slot in this step at all. The consent step collects the lot
  /// owner's ID when the applicant is not the registered owner, which is a
  /// different question — the checklist wants both people's identification on
  /// every application.
  DocumentModel? validIdOfApplicantAndOwnerUpload;

  // Technical Documents
  DocumentModel? plansUpload;
  DocumentModel? specificationsUpload;
  DocumentModel? billOfMaterialsUpload;

  // Added 27 Aug 2026 when this step was reconciled against Castilla OME's
  // real "Building Permit Documentary Requirements" checklist, as mirrored in
  // the requirements catalog. Seven required documents on that checklist had
  // no slot here at all, so an applicant who supplied everything the app asked
  // for had still not supplied everything the office needs.
  DocumentModel? surveyPlanUpload;
  DocumentModel? costEstimateUpload;
  DocumentModel? structuralDesignAndAnalysisUpload;
  DocumentModel? soilAnalysisUpload;

  // Professional Documents
  DocumentModel? prcIdChecklistUpload;
  DocumentModel? ptrChecklistUpload;
  DocumentModel? signedFormsUpload;

  // Government Clearances
  DocumentModel? barangayClearanceUpload;
  DocumentModel? zoningClearanceUpload;
  DocumentModel? fireRelatedRequirementsUpload;

  /// Issued by DOLE and DPWH/PEO respectively. This app does not route to
  /// either office, so both are submitted to the OBO as part of the
  /// documentary requirements — which is what the checklist itself says.
  DocumentModel? constructionSafetyProgramUpload;
  DocumentModel? roadClearanceUpload;

  /// The Unified Application Form itself, signed. The checklist lists the form
  /// as one of the documents to submit, distinct from the data the wizard
  /// collects.
  DocumentModel? unifiedApplicationFormUpload;

  /// The fourteen lines Castilla's checklist prints, and only those.
  ///
  /// Four documents were required here and appear nowhere on it — the tax
  /// declaration, the real property tax receipt, the bill of materials and the
  /// barangay clearance. Each was a trip to another counter for a list the
  /// office does not keep, and each is optional now rather than removed: an
  /// evaluator may still ask, and an applicant who has one should be able to
  /// send it.
  bool get isValid =>
      landTitleUpload != null &&
      validIdOfApplicantAndOwnerUpload != null &&
      plansUpload != null &&
      specificationsUpload != null &&
      prcIdChecklistUpload != null &&
      ptrChecklistUpload != null &&
      signedFormsUpload != null &&
      zoningClearanceUpload != null &&
      fireRelatedRequirementsUpload != null &&
      surveyPlanUpload != null &&
      costEstimateUpload != null &&
      structuralDesignAndAnalysisUpload != null &&
      soilAnalysisUpload != null &&
      constructionSafetyProgramUpload != null &&
      roadClearanceUpload != null &&
      unifiedApplicationFormUpload != null;
}

/// Step 8 — Review & Declaration: no new form fields, just the three
/// certifications required before the application can be submitted.
class ReviewDeclaration {
  bool certifiesTrueAndCorrect = false;
  bool understandsRequirements = false;
  bool agreesToTerms = false;

  bool get isValid =>
      certifiesTrueAndCorrect && understandsRequirements && agreesToTerms;
}

/// How the applicant intends to pay once assessment is complete.
enum PaymentMethod { payOnsite, bankTransfer }

extension PaymentMethodX on PaymentMethod {
  String get label =>
      this == PaymentMethod.payOnsite ? 'Pay Onsite' : 'Bank Transfer';
}

/// Step 9 — Assessment & Payment. This represents the Processing and
/// Evaluation Division's assessment, which the applicant does not fill in
/// — every line item is "Pending Assessment" until the office evaluates
/// the submitted application. There's nothing for the applicant to
/// complete here (payment is disabled until assessment exists), so this
/// step has no blocking validity condition.
class AssessmentPayment {
  PaymentMethod? selectedPaymentMethod;

  static const List<String> assessmentLineItems = [
    'Filing Fee',
    'Processing Fee',
    'Architectural',
    'Structural',
    'Electrical',
    'Others',
  ];

  bool get isValid => true;
}

enum BuildingPermitDraftStatus { draft, submitted }

/// The full mutable draft for one Building Permit application session.
/// Deliberately mutable — it represents actively-edited wizard state, not
/// a persisted domain entity.
class BuildingPermitDraft {
  final ApplicantInfo applicant = ApplicantInfo();
  final ApplicantAddress applicantAddress = ApplicantAddress();
  final ConstructionLocation constructionLocation = ConstructionLocation();
  final ProjectInformation projectInformation = ProjectInformation();
  final BuildingDetails buildingDetails = BuildingDetails();
  final ProfessionalInCharge professional = ProfessionalInCharge();
  final ConsentAuthorization consentAuthorization = ConsentAuthorization();
  final RequiredDocuments requiredDocuments = RequiredDocuments();
  final ReviewDeclaration reviewDeclaration = ReviewDeclaration();
  final AssessmentPayment assessmentPayment = AssessmentPayment();

  /// Whether the "Use my address as the construction location" toggle is
  /// on. Toggling it on copies the current applicant address into the
  /// construction location fields once; the copied fields stay editable
  /// afterward and are not kept in sync on further edits.
  bool useApplicantAddressForConstruction = false;

  BuildingPermitDraftStatus status = BuildingPermitDraftStatus.draft;
  DateTime? lastSavedAt;

  bool get isStep1Valid => applicant.isValid;
  bool get isStep2Valid =>
      applicantAddress.isValid && constructionLocation.isValid;
  bool get isStep3Valid => projectInformation.isValid;
  bool get isStep4Valid => buildingDetails.isValid;
  bool get isStep5Valid => professional.isValid;
  bool get isStep6Valid => consentAuthorization.isValid;
  bool get isStep7Valid => requiredDocuments.isValid;
  bool get isStep8Valid => reviewDeclaration.isValid;
  bool get isStep9Valid => assessmentPayment.isValid;

  /// Copies the applicant address into the construction location's
  /// matching fields (street/barangay/city/province/ZIP only — lot/block/
  /// title/tax-declaration numbers have no applicant-address equivalent).
  void copyApplicantAddressToConstruction() {
    constructionLocation
      ..street = applicantAddress.street
      ..barangay = applicantAddress.barangay
      ..city = applicantAddress.city
      ..province = applicantAddress.province
      ..zipCode = applicantAddress.zipCode;
  }
}
