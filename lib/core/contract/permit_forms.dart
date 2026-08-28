/// The blank official application forms, per permit type.
///
/// Transcribed from the admin portal's `permit-form-templates.ts`, which maps
/// each of the nineteen permit types onto a PDF under its
/// `public/assets/permits/`. The same eighteen files are bundled here under
/// `assets/permits/`, byte for byte, so the two lines hand an applicant the
/// same paper.
///
/// **What the admin only says in a comment, this says in code.** The admin's
/// file records in prose that five of its templates are not genuine Castilla
/// documents — Architectural, Interior Design, Sign, Demolition and
/// Certificate of Occupancy use earlier non-Castilla-specific references. A
/// comment cannot be rendered, so on that line the distinction reaches nobody.
/// Here it is [PermitForm.isOfficialCastillaForm], and the screen is required
/// to label a reference template as one: presenting a stand-in as an LGU
/// document invites an applicant to take it to the counter.
///
/// Everything else is the admin's, unchanged. Three building sub-types share
/// one file because they share one physical form — Castilla's Unified
/// Application Form for Building Permit covers New Construction, Renovation /
/// Alteration and Addition / Extension through its own Scope of Work
/// checkboxes.
library;

import 'admin_vocabulary.dart';

/// Which office hands out, and takes back, the blank form.
///
/// Not in the admin's template file — it is in its requirements catalog, and
/// it is the first thing an applicant holding a blank form needs to know.
enum FormIssuingOffice {
  /// Office of the Building Official / Office of the Municipal Engineer.
  obo('Office of the Building Official'),

  /// Municipal Planning and Development Office.
  mpdo('Municipal Planning and Development Office'),

  /// Bureau of Fire Protection, Castilla Fire Station.
  bfp('Bureau of Fire Protection – Castilla');

  const FormIssuingOffice(this.label);
  final String label;
}

/// One bundled blank form.
class PermitForm {
  /// Asset path, resolvable through `rootBundle`.
  final String assetPath;

  /// What to call it on screen — the document's own title, not the permit
  /// type's, because they differ and the applicant is looking for the former
  /// on a counter.
  final String title;

  final FormIssuingOffice office;

  /// Whether this is the genuine Castilla / BFP document.
  ///
  /// False means a generic reference template stands in for a form the LGU
  /// has not published. Such a form is still worth showing — it tells the
  /// applicant what will be asked — but it must never be presented as the
  /// official one.
  final bool isOfficialCastillaForm;

  const PermitForm({
    required this.assetPath,
    required this.title,
    required this.office,
    required this.isOfficialCastillaForm,
  });
}

const String _dir = 'assets/permits';

/// The Castilla Unified Application Form for Building Permit. One physical
/// form, three permit types.
const PermitForm _unifiedBuildingForm = PermitForm(
  assetPath: '$_dir/New-Construction.pdf',
  title: 'Unified Application Form for Building Permit',
  office: FormIssuingOffice.obo,
  isOfficialCastillaForm: true,
);

const Map<CanonicalPermitType, PermitForm> _forms = {
  CanonicalPermitType.buildingPermitNewConstruction: _unifiedBuildingForm,
  CanonicalPermitType.buildingPermitRenovationAlteration: _unifiedBuildingForm,
  CanonicalPermitType.buildingPermitAdditionExtension: _unifiedBuildingForm,

  CanonicalPermitType.zoningLocationalClearance: PermitForm(
    assetPath: '$_dir/Zoning-Locational-Clearance-Form.pdf',
    title: 'Application for Locational Clearance / Zoning Compliance',
    office: FormIssuingOffice.mpdo,
    isOfficialCastillaForm: true,
  ),

  CanonicalPermitType.civilStructuralPermit: PermitForm(
    assetPath: '$_dir/Civil-Structural-Permit.pdf',
    title: 'Civil / Structural Permit Application',
    office: FormIssuingOffice.obo,
    isOfficialCastillaForm: true,
  ),
  CanonicalPermitType.electricalPermit: PermitForm(
    assetPath: '$_dir/Electrical-Permit-Form.pdf',
    title: 'Electrical Permit Application',
    office: FormIssuingOffice.obo,
    isOfficialCastillaForm: true,
  ),
  CanonicalPermitType.electronicsPermit: PermitForm(
    assetPath: '$_dir/Electronics-Permit.pdf',
    title: 'Electronics Permit Application',
    office: FormIssuingOffice.obo,
    isOfficialCastillaForm: true,
  ),
  CanonicalPermitType.mechanicalPermit: PermitForm(
    assetPath: '$_dir/Mechanical-Permit.pdf',
    title: 'Mechanical Permit Application',
    office: FormIssuingOffice.obo,
    isOfficialCastillaForm: true,
  ),
  CanonicalPermitType.plumbingPermit: PermitForm(
    assetPath: '$_dir/Plumbing-Permit.pdf',
    title: 'Plumbing Permit Application',
    office: FormIssuingOffice.obo,
    isOfficialCastillaForm: true,
  ),
  CanonicalPermitType.sanitaryPermit: PermitForm(
    assetPath: '$_dir/Sanitary-Plumbing-Permit.pdf',
    title: 'Sanitary / Plumbing Permit Application',
    office: FormIssuingOffice.obo,
    isOfficialCastillaForm: true,
  ),
  CanonicalPermitType.fencingPermit: PermitForm(
    assetPath: '$_dir/Fencing-Permit-Form.pdf',
    title: 'Fencing Permit Application',
    office: FormIssuingOffice.obo,
    isOfficialCastillaForm: true,
  ),
  CanonicalPermitType.excavationPermit: PermitForm(
    assetPath: '$_dir/Excavation-Permit-Form.pdf',
    title: 'Excavation Permit Application',
    office: FormIssuingOffice.obo,
    isOfficialCastillaForm: true,
  ),

  CanonicalPermitType.fsecForBuildingPermitBfp: PermitForm(
    assetPath: '$_dir/FSEC-for-Building-Permit-BFP.pdf',
    title: 'Application for Fire Safety Evaluation Clearance',
    office: FormIssuingOffice.bfp,
    isOfficialCastillaForm: true,
  ),
  CanonicalPermitType.fsicForOccupancyPermitBfp: PermitForm(
    assetPath: '$_dir/FSIC-for-Occupancy-Permit-BFP.pdf',
    title: 'Application for Fire Safety Inspection Certificate',
    office: FormIssuingOffice.bfp,
    isOfficialCastillaForm: true,
  ),

  // ── Reference templates ────────────────────────────────────────────────
  //
  // The LGU has not published its own form for these five. The admin's own
  // comment says so; the flag below is what makes it visible.
  CanonicalPermitType.architecturalPermit: PermitForm(
    assetPath: '$_dir/Architectural-Permit.pdf',
    title: 'Architectural Permit Application',
    office: FormIssuingOffice.obo,
    isOfficialCastillaForm: false,
  ),
  CanonicalPermitType.interiorDesignPermit: PermitForm(
    assetPath: '$_dir/Interior-Design-Permit.pdf',
    title: 'Interior Design Permit Application',
    office: FormIssuingOffice.obo,
    isOfficialCastillaForm: false,
  ),
  CanonicalPermitType.signPermit: PermitForm(
    assetPath: '$_dir/Sign-Permit-Form.pdf',
    title: 'Sign Permit Application',
    office: FormIssuingOffice.obo,
    isOfficialCastillaForm: false,
  ),
  CanonicalPermitType.demolitionPermit: PermitForm(
    assetPath: '$_dir/Demolition-Permit.pdf',
    title: 'Demolition Permit Application',
    office: FormIssuingOffice.obo,
    isOfficialCastillaForm: false,
  ),
  CanonicalPermitType.certificateOfOccupancy: PermitForm(
    assetPath: '$_dir/Application-for-Certificate-of-Occupancy.pdf',
    title: 'Application for Certificate of Occupancy',
    office: FormIssuingOffice.obo,
    isOfficialCastillaForm: false,
  ),
};

/// The Office of the Municipal Engineer's real documentary-requirements
/// checklist.
///
/// One combined sheet covering the Building Permit family and the Certificate
/// of Occupancy — and only those four types. It is supplementary to each
/// type's own blank form, not a replacement for it, which is why it is a
/// second lookup rather than a field on [PermitForm].
const PermitForm _oboChecklist = PermitForm(
  assetPath: '$_dir/Building-Permit-and-Occupancy-Checklist.pdf',
  title: 'Building Permit and Occupancy — Documentary Requirements Checklist',
  office: FormIssuingOffice.obo,
  isOfficialCastillaForm: true,
);

const Set<CanonicalPermitType> _checklistTypes = {
  CanonicalPermitType.buildingPermitNewConstruction,
  CanonicalPermitType.buildingPermitRenovationAlteration,
  CanonicalPermitType.buildingPermitAdditionExtension,
  CanonicalPermitType.certificateOfOccupancy,
};

/// The blank application form for [type], or null where none is bundled.
///
/// Null is a real answer and callers must render it as one — no entry point,
/// rather than an entry point that opens nothing.
PermitForm? permitFormFor(CanonicalPermitType type) => _forms[type];

/// The OBO documentary-requirements checklist, where it applies to [type].
PermitForm? permitChecklistFor(CanonicalPermitType type) =>
    _checklistTypes.contains(type) ? _oboChecklist : null;

/// Both documents available for [type], form first.
List<PermitForm> permitDocumentsFor(CanonicalPermitType type) => [
  ?permitFormFor(type),
  ?permitChecklistFor(type),
];

/// As [permitFormFor], but from the wire string the app carries on an
/// application. Returns null for a label the admin does not recognise, rather
/// than throwing: an unknown permit type should cost the applicant a missing
/// form, not a crash.
PermitForm? permitFormForLabel(String label) {
  try {
    return permitFormFor(canonicalPermitTypeFromWire(label));
  } on UnknownWireValue {
    return null;
  }
}

/// As [permitChecklistFor], from a wire string.
PermitForm? permitChecklistForLabel(String label) {
  try {
    return permitChecklistFor(canonicalPermitTypeFromWire(label));
  } on UnknownWireValue {
    return null;
  }
}
