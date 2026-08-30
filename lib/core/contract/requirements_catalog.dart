// GENERATED FROM THE ADMIN PORTAL — DO NOT HAND-EDIT.
//
// Source: Upupapp/eBPCO-Web @ e3cd7c3, src/app/core/domain/requirements-catalog.ts.
// Produced on 27 August 2026 by bundling that module with esbuild and running
// it, rather than by parsing the TypeScript — two earlier attempts to read this
// file with regular expressions mis-assigned documents across spec boundaries
// and undercounted six permit types. The catalog is the authority on what a
// permit requires; it is worth executing rather than interpreting.
//
// 19 permit types, 171 requirement documents.

import 'admin_vocabulary.dart';

/// One document an applicant must supply for a given permit type.
class RequirementDocument {
  final String id;
  final String label;

  /// False for the genuinely conditional ones — a DPWH clearance "if
  /// applicable", an ECC where the project needs one. Presenting an optional
  /// document as mandatory costs the applicant a trip they did not owe.
  final bool isRequired;

  /// The office that reviews this document, which is not always the office
  /// responsible for the permit.
  final String reviewingDepartmentId;

  final String? description;

  const RequirementDocument({
    required this.id,
    required this.label,
    required this.isRequired,
    required this.reviewingDepartmentId,
    this.description,
  });
}

/// One step of the evaluation an application passes through.
class EvaluationSequenceStep {
  final EvaluationStageRef stage;
  final String departmentId;

  const EvaluationSequenceStep({
    required this.stage,
    required this.departmentId,
  });
}

/// The evaluation stages, named here to avoid importing the wizard-facing
/// `EvaluationStage` into the contract layer and coupling the two.
enum EvaluationStageRef { initial, zoning, fireSafety, obo, finalApproval }

/// Where a requirement comes from, and how firmly.
class RequirementSource {
  final String title;
  final String url;
  final String jurisdiction;
  final String effectiveDate;

  /// One of NATIONAL_LAW_VERIFIED, SAMPLE_REFERENCE_ONLY,
  /// PENDING_CASTILLA_VERIFICATION, CASTILLA_OFFICIAL_FORM_VERIFIED.
  ///
  /// Carry this to the applicant. A requirement the LGU has not confirmed must
  /// not be shown in the same voice as PD 1096.
  final String verificationStatus;

  const RequirementSource({
    required this.title,
    required this.url,
    required this.jurisdiction,
    required this.effectiveDate,
    required this.verificationStatus,
  });
}

/// Everything the admin knows about what one permit type requires.
class PermitRequirements {
  final CanonicalPermitType permitType;

  /// The official form, by its real name and number where Castilla has one.
  final String requiredForm;

  final List<RequirementDocument> documents;
  final String responsibleDepartmentId;
  final List<EvaluationSequenceStep> evaluationSequence;
  final String paymentRequirements;
  final String inspectionRequirements;
  final String validityRules;

  /// Whole months of validity from issuance, or null where the permit type
  /// carries no fixed expiry — the Certificate of Occupancy.
  ///
  /// Distinct from PD 1096's commencement deadline, which is one year for
  /// every type and is modelled separately on the issued permit.
  final int? validityMonths;

  final String finalDocument;
  final String releaseRequirements;
  final String sourceNote;
  final String effectiveDate;

  /// True only where this entry was built from an actual Castilla or BFP form
  /// rather than a national-law baseline or a placeholder.
  final bool verified;

  final List<RequirementSource> sources;

  const PermitRequirements({
    required this.permitType,
    required this.requiredForm,
    required this.documents,
    required this.responsibleDepartmentId,
    required this.evaluationSequence,
    required this.paymentRequirements,
    required this.inspectionRequirements,
    required this.validityRules,
    required this.validityMonths,
    required this.finalDocument,
    required this.releaseRequirements,
    required this.sourceNote,
    required this.effectiveDate,
    required this.verified,
    required this.sources,
  });

  int get requiredDocumentCount => documents.where((d) => d.isRequired).length;
}

// The cited sources, shared across entries.
const _src0 = RequirementSource(
  title:
      'Municipality of Castilla, Sorsogon — Office of the Municipal Engineer, "Building Permit Documentary Requirements" checklist',
  url: '/assets/permits/Building-Permit-and-Occupancy-Checklist.pdf',
  jurisdiction:
      'Municipality of Castilla, Sorsogon — Office of the Municipal Engineer',
  effectiveDate: 'UNDATED on the form itself',
  verificationStatus: 'CASTILLA_OFFICIAL_FORM_VERIFIED',
);
const _src1 = RequirementSource(
  title:
      'Presidential Decree No. 1096 — National Building Code of the Philippines (official text, DPWH)',
  url: 'https://www.dpwh.gov.ph/DPWH/files/nbc/PD.pdf',
  jurisdiction:
      'Republic of the Philippines — national law, binds every LGU including Castilla',
  effectiveDate: '1977-02-19',
  verificationStatus: 'NATIONAL_LAW_VERIFIED',
);
const _src2 = RequirementSource(
  title:
      'Republic Act No. 9514 — Fire Code of the Philippines of 2008, Sec. 5(g) & 7(a) (Fire Safety Inspection Certificate is a prerequisite to any occupancy/operating permit)',
  url: 'https://lawphil.net/statutes/repacts/ra2008/ra_9514_2008.html',
  jurisdiction:
      'Republic of the Philippines — national law, binds every LGU including Castilla',
  effectiveDate: '2008-12-19',
  verificationStatus: 'NATIONAL_LAW_VERIFIED',
);
const _src3 = RequirementSource(
  title:
      'City of Puerto Princesa, Office of the City Building Official — "Documentary Requirements for Building Permit Applications" (structural reference only)',
  url:
      'https://ocbo.puertoprincesa.ph/wp-content/uploads/2022/01/1.-Building-Permit-Checklist.pdf',
  jurisdiction:
      'City of Puerto Princesa, Palawan — NOT the Municipality of Castilla; used only as a structural example of how a Unified Application/Ancillary Permit checklist under PD 1096 is laid out',
  effectiveDate: '2022-01-01',
  verificationStatus: 'SAMPLE_REFERENCE_ONLY',
);
const _src4 = RequirementSource(
  title:
      'Municipality of Castilla, Sorsogon — official Citizen\'s Charter / OBO documentary checklist',
  url: 'https://www.castillasorsogon.gov.ph/',
  jurisdiction: 'Municipality of Castilla, Sorsogon',
  effectiveDate:
      'UNKNOWN — not accessible to automated research as of 2026-08-20; obtain directly from the Municipality of Castilla OBO before production use',
  verificationStatus: 'PENDING_CASTILLA_VERIFICATION',
);
const _src5 = RequirementSource(
  title:
      'Municipality of Castilla, Sorsogon — Municipal Planning and Development Office, "Application for Locational Clearance / Certificate of Zoning Compliance" (Form FM-MPD-12)',
  url: '/assets/permits/Zoning-Locational-Clearance-Form.pdf',
  jurisdiction:
      'Municipality of Castilla, Sorsogon — Municipal Planning and Development Office (Zoning Section)',
  effectiveDate: '2024-08-01',
  verificationStatus: 'CASTILLA_OFFICIAL_FORM_VERIFIED',
);
const _src6 = RequirementSource(
  title:
      'Bureau of Fire Protection — Castilla Fire Station (Sorsogon Provincial Office, Region 5), "Fire Safety Evaluation Clearance Application Form" (BFP-QSF-FSED-001 Rev.02)',
  url: '/assets/permits/FSEC-for-Building-Permit-BFP.pdf',
  jurisdiction:
      'Bureau of Fire Protection — Castilla Fire Station, Municipality of Castilla, Sorsogon',
  effectiveDate: '2020-08-24',
  verificationStatus: 'CASTILLA_OFFICIAL_FORM_VERIFIED',
);
const _src7 = RequirementSource(
  title:
      'Bureau of Fire Protection — CY 2021 Updates on BFP Citizen\'s Charter (ARTA)',
  url:
      'https://bfp.gov.ph/wp-content/uploads/2021/12/1-CY-2021-Updates-on-BFP-Citizens-Charter-for-ARTA-Final.pdf',
  jurisdiction:
      'Bureau of Fire Protection — national agency; a general/national-level citizen\'s charter, NOT the Municipality of Castilla\'s own BFP station checklist',
  effectiveDate: '2021-12-01',
  verificationStatus: 'SAMPLE_REFERENCE_ONLY',
);
const _src8 = RequirementSource(
  title:
      'Bureau of Fire Protection — Castilla Fire Station (Sorsogon Provincial Office, Region 5), "Fire Safety Inspection Certificate Application Form" (BFP-QSF-FSED-002 Rev.02)',
  url: '/assets/permits/FSIC-for-Occupancy-Permit-BFP.pdf',
  jurisdiction:
      'Bureau of Fire Protection — Castilla Fire Station, Municipality of Castilla, Sorsogon',
  effectiveDate: '2020-08-24',
  verificationStatus: 'CASTILLA_OFFICIAL_FORM_VERIFIED',
);

/// Every permit type, in the admin's own order.
const Map<CanonicalPermitType, PermitRequirements> requirementsCatalog = {
  CanonicalPermitType.buildingPermitNewConstruction: PermitRequirements(
    permitType: CanonicalPermitType.buildingPermitNewConstruction,
    requiredForm: 'Unified Building Permit Form',
    documents: [
      RequirementDocument(
        id: 'bpnc-oct-tct',
        label: 'Certified True Copy of OCT/TCT',
        isRequired: true,
        reviewingDepartmentId: 'obo',
        description:
            'Or, if the applicant is not the registered owner: Deed of Sale, Deed of Donation, Lease Contract, Assignment of Rights, or other valid proof of ownership.',
      ),
      RequirementDocument(
        id: 'bpnc-survey-plan',
        label: 'Survey Plan',
        isRequired: true,
        reviewingDepartmentId: 'obo',
      ),
      RequirementDocument(
        id: 'bpnc-design-plans',
        label: 'Design Plans (duly signed and sealed)',
        isRequired: true,
        reviewingDepartmentId: 'obo',
        description:
            'Covers Architectural, Civil/Structural, Electrical, Sanitary/Plumbing, and Mechanical plans as applicable to the scope of work.',
      ),
      RequirementDocument(
        id: 'bpnc-unified-form',
        label: 'Unified Building Permit Form',
        isRequired: true,
        reviewingDepartmentId: 'obo',
      ),
      RequirementDocument(
        id: 'bpnc-ancillary-electrical',
        label: 'Electrical Permit (ancillary application form)',
        isRequired: false,
        reviewingDepartmentId: 'obo',
        description:
            'Submit only if the project scope includes electrical work.',
      ),
      RequirementDocument(
        id: 'bpnc-ancillary-fencing',
        label: 'Fencing Permit (ancillary application form)',
        isRequired: false,
        reviewingDepartmentId: 'obo',
        description: 'Submit only if the project scope includes fencing.',
      ),
      RequirementDocument(
        id: 'bpnc-ancillary-architectural',
        label: 'Architectural Permit (ancillary application form)',
        isRequired: false,
        reviewingDepartmentId: 'obo',
      ),
      RequirementDocument(
        id: 'bpnc-ancillary-sanitary-plumbing',
        label: 'Sanitary/Plumbing Permit (ancillary application form)',
        isRequired: false,
        reviewingDepartmentId: 'obo',
        description:
            'Submit only if the project scope includes sanitary/plumbing work.',
      ),
      RequirementDocument(
        id: 'bpnc-ancillary-mechanical',
        label: 'Mechanical Permit (ancillary application form)',
        isRequired: false,
        reviewingDepartmentId: 'obo',
        description:
            'Submit only if the project scope includes mechanical work.',
      ),
      RequirementDocument(
        id: 'bpnc-ancillary-civil-structural',
        label: 'Civil/Structural Permit (ancillary application form)',
        isRequired: false,
        reviewingDepartmentId: 'obo',
      ),
      RequirementDocument(
        id: 'bpnc-ancillary-excavation',
        label: 'Excavation Permit (ancillary application form)',
        isRequired: false,
        reviewingDepartmentId: 'obo',
        description: 'Submit only if the project scope includes excavation.',
      ),
      RequirementDocument(
        id: 'bpnc-ancillary-electronics',
        label: 'Electronics Permit (ancillary application form)',
        isRequired: false,
        reviewingDepartmentId: 'obo',
        description:
            'Submit only if the project scope includes electronics/communications installation.',
      ),
      RequirementDocument(
        id: 'bpnc-cost-estimate',
        label: 'Cost Estimate (duly signed and sealed)',
        isRequired: true,
        reviewingDepartmentId: 'obo',
      ),
      RequirementDocument(
        id: 'bpnc-technical-specs',
        label: 'Technical Specifications (duly signed and sealed)',
        isRequired: true,
        reviewingDepartmentId: 'obo',
      ),
      RequirementDocument(
        id: 'bpnc-structural-design-analysis',
        label: 'Structural Design and Analysis',
        isRequired: true,
        reviewingDepartmentId: 'obo',
      ),
      RequirementDocument(
        id: 'bpnc-soil-analysis',
        label: 'Soil Analysis / Plate Load Test / Seismic Analysis',
        isRequired: true,
        reviewingDepartmentId: 'obo',
      ),
      RequirementDocument(
        id: 'bpnc-professional-licenses',
        label: 'Valid Licenses (PRC) of all involved professionals',
        isRequired: true,
        reviewingDepartmentId: 'obo',
      ),
      RequirementDocument(
        id: 'bpnc-valid-id',
        label: 'Valid ID of Applicant and Owner of Lot',
        isRequired: true,
        reviewingDepartmentId: 'obo',
      ),
      RequirementDocument(
        id: 'bpnc-zoning-locational',
        label: 'Zoning / Locational Clearance',
        isRequired: true,
        reviewingDepartmentId: 'zoning',
        description: 'Issued by MPDC.',
      ),
      RequirementDocument(
        id: 'bpnc-fire-safety-clearance',
        label: 'Fire Safety Evaluation Clearance',
        isRequired: true,
        reviewingDepartmentId: 'bfp',
        description: 'Issued by BFP.',
      ),
      RequirementDocument(
        id: 'bpnc-construction-safety-health',
        label: 'Approved Construction Safety and Health Program',
        isRequired: true,
        reviewingDepartmentId: 'obo',
        description:
            'Issued by DOLE — this app does not route to DOLE directly, so the approved program is submitted to OBO as part of the documentary requirements.',
      ),
      RequirementDocument(
        id: 'bpnc-road-clearance',
        label: 'Road Clearance',
        isRequired: true,
        reviewingDepartmentId: 'obo',
        description:
            'Issued by DPWH/PEO — this app does not route to DPWH/PEO directly, so the clearance is submitted to OBO as part of the documentary requirements.',
      ),
    ],
    responsibleDepartmentId: 'obo',
    evaluationSequence: [
      EvaluationSequenceStep(
        stage: EvaluationStageRef.initial,
        departmentId: 'obo',
      ),
      EvaluationSequenceStep(
        stage: EvaluationStageRef.zoning,
        departmentId: 'zoning',
      ),
      EvaluationSequenceStep(
        stage: EvaluationStageRef.fireSafety,
        departmentId: 'bfp',
      ),
      EvaluationSequenceStep(
        stage: EvaluationStageRef.obo,
        departmentId: 'obo',
      ),
      EvaluationSequenceStep(
        stage: EvaluationStageRef.finalApproval,
        departmentId: 'obo',
      ),
    ],
    paymentRequirements:
        'Building/permit fee, line-item fees per discipline (architectural/structural/electrical/mechanical/sanitary as applicable), and other regulatory fees assessed by the Municipal Treasurer’s Office based on project cost/floor area.',
    inspectionRequirements:
        'Site inspection prior to permit issuance; periodic inspections during construction; final inspection before Certificate of Occupancy.',
    validityRules:
        'Valid for twelve (12) months from issuance; work must commence within one year or the permit lapses and must be renewed.',
    validityMonths: 12,
    finalDocument: 'Building Permit – New Construction',
    releaseRequirements:
        'Full payment verified, OBO final sign-off recorded, and permit signed by the Municipal Engineer/Building Official.',
    sourceNote:
        'Documentary requirements transcribed directly from the Municipality of Castilla Office of the Municipal Engineer\'s own "Building Permit Documentary Requirements" checklist — see `sources`. Legal basis for the permit itself remains PD 1096 (National Building Code).',
    effectiveDate: '2026-08-20',
    verified: true,
    sources: [_src0, _src1],
  ),
  CanonicalPermitType.buildingPermitRenovationAlteration: PermitRequirements(
    permitType: CanonicalPermitType.buildingPermitRenovationAlteration,
    requiredForm: 'Application for Building Permit (Renovation / Alteration)',
    documents: [
      RequirementDocument(
        id: 'building-permit-renovation-alteration-land-title',
        label: 'Land Title or Tax Declaration of the property',
        isRequired: true,
        reviewingDepartmentId: 'obo',
      ),
      RequirementDocument(
        id: 'building-permit-renovation-alteration-owner-consent',
        label: 'Owner\'s Written Consent (if applicant is not the lot owner)',
        isRequired: false,
        reviewingDepartmentId: 'obo',
      ),
      RequirementDocument(
        id: 'building-permit-renovation-alteration-brgy-clearance',
        label: 'Barangay Clearance',
        isRequired: true,
        reviewingDepartmentId: 'zoning',
      ),
      RequirementDocument(
        id: 'building-permit-renovation-alteration-locational',
        label: 'Locational Clearance / Zoning Certification',
        isRequired: true,
        reviewingDepartmentId: 'zoning',
      ),
      RequirementDocument(
        id: 'building-permit-renovation-alteration-id',
        label: 'Valid Government-Issued ID of Applicant/Owner',
        isRequired: true,
        reviewingDepartmentId: 'obo',
      ),
      RequirementDocument(
        id: 'renovation-plan',
        label: 'Renovation/Alteration Plans (signed and sealed)',
        isRequired: true,
        reviewingDepartmentId: 'obo',
      ),
      RequirementDocument(
        id: 'renovation-existing-permit',
        label: 'Copy of Original Building Permit (if available)',
        isRequired: false,
        reviewingDepartmentId: 'obo',
      ),
      RequirementDocument(
        id: 'renovation-bom',
        label: 'Bill of Materials and Specifications',
        isRequired: true,
        reviewingDepartmentId: 'obo',
      ),
      RequirementDocument(
        id: 'renovation-prc',
        label: 'PRC License and PTR of Engineer/Architect of Record',
        isRequired: true,
        reviewingDepartmentId: 'obo',
      ),
    ],
    responsibleDepartmentId: 'obo',
    evaluationSequence: [
      EvaluationSequenceStep(
        stage: EvaluationStageRef.initial,
        departmentId: 'obo',
      ),
      EvaluationSequenceStep(
        stage: EvaluationStageRef.zoning,
        departmentId: 'zoning',
      ),
      EvaluationSequenceStep(
        stage: EvaluationStageRef.fireSafety,
        departmentId: 'bfp',
      ),
      EvaluationSequenceStep(
        stage: EvaluationStageRef.obo,
        departmentId: 'obo',
      ),
      EvaluationSequenceStep(
        stage: EvaluationStageRef.finalApproval,
        departmentId: 'obo',
      ),
    ],
    paymentRequirements:
        'Building/permit fee, line-item fees per discipline (architectural/structural/electrical/mechanical/sanitary as applicable), and other regulatory fees assessed by the Municipal Treasurer’s Office based on project cost/floor area.',
    inspectionRequirements:
        'Site inspection to confirm scope matches submitted plans; final inspection upon completion.',
    validityRules: 'Valid for twelve (12) months from issuance.',
    validityMonths: 12,
    finalDocument: 'Building Permit – Renovation / Alteration',
    releaseRequirements:
        'Full payment verified, OBO final sign-off recorded, and permit signed by the Municipal Engineer/Building Official.',
    sourceNote:
        'Legal basis: PD 1096 (National Building Code) for the permit itself and RA 9514 Sec. 5(g) where a Fire Safety Inspection Certificate is required; Puerto Princesa OCBO\'s published checklist used only as a structural example of the Unified Application/Ancillary Permit format. Castilla\'s own OBO checklist and fee schedule were not accessible during this research pass — see `sources` below.',
    effectiveDate: '2026-08-20',
    verified: false,
    sources: [_src1, _src2, _src3, _src4],
  ),
  CanonicalPermitType.buildingPermitAdditionExtension: PermitRequirements(
    permitType: CanonicalPermitType.buildingPermitAdditionExtension,
    requiredForm: 'Application for Building Permit (Addition / Extension)',
    documents: [
      RequirementDocument(
        id: 'building-permit-addition-extension-land-title',
        label: 'Land Title or Tax Declaration of the property',
        isRequired: true,
        reviewingDepartmentId: 'obo',
      ),
      RequirementDocument(
        id: 'building-permit-addition-extension-owner-consent',
        label: 'Owner\'s Written Consent (if applicant is not the lot owner)',
        isRequired: false,
        reviewingDepartmentId: 'obo',
      ),
      RequirementDocument(
        id: 'building-permit-addition-extension-brgy-clearance',
        label: 'Barangay Clearance',
        isRequired: true,
        reviewingDepartmentId: 'zoning',
      ),
      RequirementDocument(
        id: 'building-permit-addition-extension-locational',
        label: 'Locational Clearance / Zoning Certification',
        isRequired: true,
        reviewingDepartmentId: 'zoning',
      ),
      RequirementDocument(
        id: 'building-permit-addition-extension-id',
        label: 'Valid Government-Issued ID of Applicant/Owner',
        isRequired: true,
        reviewingDepartmentId: 'obo',
      ),
      RequirementDocument(
        id: 'addition-plan',
        label: 'Addition / Extension Plans (signed and sealed)',
        isRequired: true,
        reviewingDepartmentId: 'obo',
      ),
      RequirementDocument(
        id: 'addition-struct-plan',
        label: 'Structural Analysis for the added load (signed and sealed)',
        isRequired: true,
        reviewingDepartmentId: 'obo',
      ),
      RequirementDocument(
        id: 'addition-bom',
        label: 'Bill of Materials and Specifications',
        isRequired: true,
        reviewingDepartmentId: 'obo',
      ),
      RequirementDocument(
        id: 'addition-prc',
        label: 'PRC License and PTR of Engineer/Architect of Record',
        isRequired: true,
        reviewingDepartmentId: 'obo',
      ),
    ],
    responsibleDepartmentId: 'obo',
    evaluationSequence: [
      EvaluationSequenceStep(
        stage: EvaluationStageRef.initial,
        departmentId: 'obo',
      ),
      EvaluationSequenceStep(
        stage: EvaluationStageRef.zoning,
        departmentId: 'zoning',
      ),
      EvaluationSequenceStep(
        stage: EvaluationStageRef.fireSafety,
        departmentId: 'bfp',
      ),
      EvaluationSequenceStep(
        stage: EvaluationStageRef.obo,
        departmentId: 'obo',
      ),
      EvaluationSequenceStep(
        stage: EvaluationStageRef.finalApproval,
        departmentId: 'obo',
      ),
    ],
    paymentRequirements:
        'Building/permit fee, line-item fees per discipline (architectural/structural/electrical/mechanical/sanitary as applicable), and other regulatory fees assessed by the Municipal Treasurer’s Office based on project cost/floor area.',
    inspectionRequirements:
        'Structural site inspection to verify the existing structure can carry the addition; final inspection upon completion.',
    validityRules: 'Valid for twelve (12) months from issuance.',
    validityMonths: 12,
    finalDocument: 'Building Permit – Addition / Extension',
    releaseRequirements:
        'Full payment verified, OBO final sign-off recorded, and permit signed by the Municipal Engineer/Building Official.',
    sourceNote:
        'Legal basis: PD 1096 (National Building Code) for the permit itself and RA 9514 Sec. 5(g) where a Fire Safety Inspection Certificate is required; Puerto Princesa OCBO\'s published checklist used only as a structural example of the Unified Application/Ancillary Permit format. Castilla\'s own OBO checklist and fee schedule were not accessible during this research pass — see `sources` below.',
    effectiveDate: '2026-08-20',
    verified: false,
    sources: [_src1, _src2, _src3, _src4],
  ),
  CanonicalPermitType.demolitionPermit: PermitRequirements(
    permitType: CanonicalPermitType.demolitionPermit,
    requiredForm: 'Application for Demolition Permit',
    documents: [
      RequirementDocument(
        id: 'demolition-permit-land-title',
        label: 'Land Title or Tax Declaration of the property',
        isRequired: true,
        reviewingDepartmentId: 'obo',
      ),
      RequirementDocument(
        id: 'demolition-permit-owner-consent',
        label: 'Owner\'s Written Consent (if applicant is not the lot owner)',
        isRequired: false,
        reviewingDepartmentId: 'obo',
      ),
      RequirementDocument(
        id: 'demolition-permit-brgy-clearance',
        label: 'Barangay Clearance',
        isRequired: true,
        reviewingDepartmentId: 'zoning',
      ),
      RequirementDocument(
        id: 'demolition-permit-locational',
        label: 'Locational Clearance / Zoning Certification',
        isRequired: true,
        reviewingDepartmentId: 'zoning',
      ),
      RequirementDocument(
        id: 'demolition-permit-id',
        label: 'Valid Government-Issued ID of Applicant/Owner',
        isRequired: true,
        reviewingDepartmentId: 'obo',
      ),
      RequirementDocument(
        id: 'demolition-method',
        label: 'Method of Demolition / Work Plan',
        isRequired: true,
        reviewingDepartmentId: 'obo',
      ),
      RequirementDocument(
        id: 'demolition-safety',
        label: 'Structural Safety Assessment and Safety Measures Plan',
        isRequired: true,
        reviewingDepartmentId: 'obo',
      ),
      RequirementDocument(
        id: 'demolition-prc',
        label: 'PRC License and PTR of Engineer of Record',
        isRequired: true,
        reviewingDepartmentId: 'obo',
      ),
      RequirementDocument(
        id: 'demolition-utility-clearance',
        label: 'Utility Disconnection Clearance (water/power)',
        isRequired: false,
        reviewingDepartmentId: 'obo',
      ),
    ],
    responsibleDepartmentId: 'obo',
    evaluationSequence: [
      EvaluationSequenceStep(
        stage: EvaluationStageRef.initial,
        departmentId: 'obo',
      ),
      EvaluationSequenceStep(
        stage: EvaluationStageRef.zoning,
        departmentId: 'zoning',
      ),
      EvaluationSequenceStep(
        stage: EvaluationStageRef.fireSafety,
        departmentId: 'bfp',
      ),
      EvaluationSequenceStep(
        stage: EvaluationStageRef.obo,
        departmentId: 'obo',
      ),
      EvaluationSequenceStep(
        stage: EvaluationStageRef.finalApproval,
        departmentId: 'obo',
      ),
    ],
    paymentRequirements:
        'Building/permit fee, line-item fees per discipline (architectural/structural/electrical/mechanical/sanitary as applicable), and other regulatory fees assessed by the Municipal Treasurer’s Office based on project cost/floor area.',
    inspectionRequirements:
        'Pre-demolition site inspection for safety compliance; post-demolition site clearance inspection.',
    validityRules: 'Valid for six (6) months from issuance.',
    validityMonths: 6,
    finalDocument: 'Demolition Permit',
    releaseRequirements:
        'Full payment verified, OBO final sign-off recorded, and permit signed by the Municipal Engineer/Building Official.',
    sourceNote:
        'Legal basis: PD 1096 (National Building Code) for the permit itself and RA 9514 Sec. 5(g) where a Fire Safety Inspection Certificate is required; Puerto Princesa OCBO\'s published checklist used only as a structural example of the Unified Application/Ancillary Permit format. Castilla\'s own OBO checklist and fee schedule were not accessible during this research pass — see `sources` below.',
    effectiveDate: '2026-08-20',
    verified: false,
    sources: [_src1, _src2, _src3, _src4],
  ),
  CanonicalPermitType.zoningLocationalClearance: PermitRequirements(
    permitType: CanonicalPermitType.zoningLocationalClearance,
    requiredForm:
        'Application for Locational Clearance / Certificate of Zoning Compliance (Form FM-MPD-12)',
    documents: [
      RequirementDocument(
        id: 'zoning-locational-clearance-land-title',
        label: 'Land Title or Tax Declaration of the property',
        isRequired: true,
        reviewingDepartmentId: 'obo',
      ),
      RequirementDocument(
        id: 'zoning-locational-clearance-owner-consent',
        label: 'Owner\'s Written Consent (if applicant is not the lot owner)',
        isRequired: false,
        reviewingDepartmentId: 'obo',
      ),
      RequirementDocument(
        id: 'zoning-locational-clearance-brgy-clearance',
        label: 'Barangay Clearance',
        isRequired: true,
        reviewingDepartmentId: 'zoning',
      ),
      RequirementDocument(
        id: 'zoning-locational-clearance-id',
        label: 'Valid Government-Issued ID of Applicant/Owner',
        isRequired: true,
        reviewingDepartmentId: 'obo',
      ),
      RequirementDocument(
        id: 'zoning-letter-request',
        label: 'Notarized Letter Request addressed to the Zoning Administrator',
        isRequired: true,
        reviewingDepartmentId: 'zoning',
      ),
      RequirementDocument(
        id: 'zoning-site-plan',
        label: 'Site Development Plan',
        isRequired: true,
        reviewingDepartmentId: 'zoning',
      ),
      RequirementDocument(
        id: 'zoning-vicinity-map',
        label: 'Vicinity Map',
        isRequired: true,
        reviewingDepartmentId: 'zoning',
      ),
      RequirementDocument(
        id: 'zoning-sketch-plan',
        label: 'Sketch Plan of the House',
        isRequired: true,
        reviewingDepartmentId: 'zoning',
      ),
      RequirementDocument(
        id: 'zoning-bom',
        label: 'Bill of Materials',
        isRequired: true,
        reviewingDepartmentId: 'zoning',
      ),
      RequirementDocument(
        id: 'zoning-ownership',
        label: 'Proof of Ownership',
        isRequired: true,
        reviewingDepartmentId: 'zoning',
      ),
      RequirementDocument(
        id: 'zoning-tax-dec',
        label: 'Tax Declaration / Certificate of Title (COT) / OCT',
        isRequired: true,
        reviewingDepartmentId: 'zoning',
      ),
      RequirementDocument(
        id: 'zoning-land-tax',
        label: 'Land Tax Receipt (Current Year)',
        isRequired: true,
        reviewingDepartmentId: 'zoning',
      ),
      RequirementDocument(
        id: 'zoning-brgy-building-clearance',
        label: 'Barangay Building Clearance',
        isRequired: true,
        reviewingDepartmentId: 'zoning',
      ),
      RequirementDocument(
        id: 'zoning-cedula',
        label: 'Cedula (Photocopy)',
        isRequired: true,
        reviewingDepartmentId: 'zoning',
      ),
      RequirementDocument(
        id: 'zoning-dpwh',
        label: 'DPWH Clearance (if applicable)',
        isRequired: false,
        reviewingDepartmentId: 'zoning',
      ),
      RequirementDocument(
        id: 'zoning-ecc',
        label: 'Environmental Compliance Certificate / ECC (if applicable)',
        isRequired: false,
        reviewingDepartmentId: 'zoning',
      ),
    ],
    responsibleDepartmentId: 'zoning',
    evaluationSequence: [
      EvaluationSequenceStep(
        stage: EvaluationStageRef.initial,
        departmentId: 'obo',
      ),
      EvaluationSequenceStep(
        stage: EvaluationStageRef.zoning,
        departmentId: 'zoning',
      ),
      EvaluationSequenceStep(
        stage: EvaluationStageRef.fireSafety,
        departmentId: 'bfp',
      ),
      EvaluationSequenceStep(
        stage: EvaluationStageRef.obo,
        departmentId: 'obo',
      ),
      EvaluationSequenceStep(
        stage: EvaluationStageRef.finalApproval,
        departmentId: 'obo',
      ),
    ],
    paymentRequirements:
        'Zoning fee (\'Locational / Zoning of Land\' line item) computed and assessed by the Zoning Administrator, per the Unified Application Form\'s own Box 6 fee schedule.',
    inspectionRequirements:
        'Ocular site inspection and preparation of a project evaluation report by the Zoning Officer, per FM-MPD-12\'s own stated procedure.',
    validityRules:
        'Valid for twelve (12) months from issuance, per standard LGU clearance practice — the Castilla MPDO form itself does not print a fixed validity period on its face.',
    validityMonths: 12,
    finalDocument: 'Zoning / Locational Clearance',
    releaseRequirements:
        'Order of Payment issued and paid, evaluation and decision encoded, then the Locational / Zoning Clearance is approved and issued by the Zoning Administrator.',
    sourceNote:
        'This clearance is a prerequisite before filing a Building Permit application (its output is the \'Locational Clearance / Zoning Certification\' document required by every other permit type\'s checklist). Document list and procedure transcribed directly from the Municipality of Castilla\'s own MPDO form FM-MPD-12, obtained and reviewed in full — see `sources` below.',
    effectiveDate: '2026-08-20',
    verified: true,
    sources: [_src5],
  ),
  CanonicalPermitType.architecturalPermit: PermitRequirements(
    permitType: CanonicalPermitType.architecturalPermit,
    requiredForm: 'Application for Architectural Permit',
    documents: [
      RequirementDocument(
        id: 'architectural-permit-land-title',
        label: 'Land Title or Tax Declaration of the property',
        isRequired: true,
        reviewingDepartmentId: 'obo',
      ),
      RequirementDocument(
        id: 'architectural-permit-owner-consent',
        label: 'Owner\'s Written Consent (if applicant is not the lot owner)',
        isRequired: false,
        reviewingDepartmentId: 'obo',
      ),
      RequirementDocument(
        id: 'architectural-permit-brgy-clearance',
        label: 'Barangay Clearance',
        isRequired: true,
        reviewingDepartmentId: 'zoning',
      ),
      RequirementDocument(
        id: 'architectural-permit-locational',
        label: 'Locational Clearance / Zoning Certification',
        isRequired: true,
        reviewingDepartmentId: 'zoning',
      ),
      RequirementDocument(
        id: 'architectural-permit-id',
        label: 'Valid Government-Issued ID of Applicant/Owner',
        isRequired: true,
        reviewingDepartmentId: 'obo',
      ),
      RequirementDocument(
        id: 'arch-plan',
        label: 'Architectural Plans (signed and sealed)',
        isRequired: true,
        reviewingDepartmentId: 'obo',
      ),
      RequirementDocument(
        id: 'arch-prc',
        label: 'PRC License and PTR of Architect of Record',
        isRequired: true,
        reviewingDepartmentId: 'obo',
      ),
    ],
    responsibleDepartmentId: 'obo',
    evaluationSequence: [
      EvaluationSequenceStep(
        stage: EvaluationStageRef.initial,
        departmentId: 'obo',
      ),
      EvaluationSequenceStep(
        stage: EvaluationStageRef.zoning,
        departmentId: 'zoning',
      ),
      EvaluationSequenceStep(
        stage: EvaluationStageRef.fireSafety,
        departmentId: 'bfp',
      ),
      EvaluationSequenceStep(
        stage: EvaluationStageRef.obo,
        departmentId: 'obo',
      ),
      EvaluationSequenceStep(
        stage: EvaluationStageRef.finalApproval,
        departmentId: 'obo',
      ),
    ],
    paymentRequirements:
        'Building/permit fee, line-item fees per discipline (architectural/structural/electrical/mechanical/sanitary as applicable), and other regulatory fees assessed by the Municipal Treasurer’s Office based on project cost/floor area.',
    inspectionRequirements:
        'Included as part of the overall Building Permit site inspection when filed jointly; independent site check when filed standalone.',
    validityRules: 'Valid for twelve (12) months from issuance.',
    validityMonths: 12,
    finalDocument: 'Architectural Permit',
    releaseRequirements:
        'Full payment verified, OBO final sign-off recorded, and permit signed by the Municipal Engineer/Building Official.',
    sourceNote:
        'Legal basis: PD 1096 (National Building Code) for the permit itself and RA 9514 Sec. 5(g) where a Fire Safety Inspection Certificate is required; Puerto Princesa OCBO\'s published checklist used only as a structural example of the Unified Application/Ancillary Permit format. Castilla\'s own OBO checklist and fee schedule were not accessible during this research pass — see `sources` below.',
    effectiveDate: '2026-08-20',
    verified: false,
    sources: [_src1, _src2, _src3, _src4],
  ),
  CanonicalPermitType.civilStructuralPermit: PermitRequirements(
    permitType: CanonicalPermitType.civilStructuralPermit,
    requiredForm: 'Application for Civil / Structural Permit',
    documents: [
      RequirementDocument(
        id: 'civil-structural-permit-land-title',
        label: 'Land Title or Tax Declaration of the property',
        isRequired: true,
        reviewingDepartmentId: 'obo',
      ),
      RequirementDocument(
        id: 'civil-structural-permit-owner-consent',
        label: 'Owner\'s Written Consent (if applicant is not the lot owner)',
        isRequired: false,
        reviewingDepartmentId: 'obo',
      ),
      RequirementDocument(
        id: 'civil-structural-permit-brgy-clearance',
        label: 'Barangay Clearance',
        isRequired: true,
        reviewingDepartmentId: 'zoning',
      ),
      RequirementDocument(
        id: 'civil-structural-permit-locational',
        label: 'Locational Clearance / Zoning Certification',
        isRequired: true,
        reviewingDepartmentId: 'zoning',
      ),
      RequirementDocument(
        id: 'civil-structural-permit-id',
        label: 'Valid Government-Issued ID of Applicant/Owner',
        isRequired: true,
        reviewingDepartmentId: 'obo',
      ),
      RequirementDocument(
        id: 'struct-plan',
        label: 'Structural Plans (signed and sealed)',
        isRequired: true,
        reviewingDepartmentId: 'obo',
      ),
      RequirementDocument(
        id: 'struct-analysis',
        label: 'Structural Design Analysis',
        isRequired: true,
        reviewingDepartmentId: 'obo',
      ),
      RequirementDocument(
        id: 'struct-prc',
        label: 'PRC License and PTR of Civil Engineer of Record',
        isRequired: true,
        reviewingDepartmentId: 'obo',
      ),
    ],
    responsibleDepartmentId: 'obo',
    evaluationSequence: [
      EvaluationSequenceStep(
        stage: EvaluationStageRef.initial,
        departmentId: 'obo',
      ),
      EvaluationSequenceStep(
        stage: EvaluationStageRef.zoning,
        departmentId: 'zoning',
      ),
      EvaluationSequenceStep(
        stage: EvaluationStageRef.fireSafety,
        departmentId: 'bfp',
      ),
      EvaluationSequenceStep(
        stage: EvaluationStageRef.obo,
        departmentId: 'obo',
      ),
      EvaluationSequenceStep(
        stage: EvaluationStageRef.finalApproval,
        departmentId: 'obo',
      ),
    ],
    paymentRequirements:
        'Building/permit fee, line-item fees per discipline (architectural/structural/electrical/mechanical/sanitary as applicable), and other regulatory fees assessed by the Municipal Treasurer’s Office based on project cost/floor area.',
    inspectionRequirements:
        'Structural site inspection during key pours/erection stages; final structural inspection.',
    validityRules: 'Valid for twelve (12) months from issuance.',
    validityMonths: 12,
    finalDocument: 'Civil / Structural Permit',
    releaseRequirements:
        'Full payment verified, OBO final sign-off recorded, and permit signed by the Municipal Engineer/Building Official.',
    sourceNote:
        'Legal basis: PD 1096 (National Building Code) for the permit itself and RA 9514 Sec. 5(g) where a Fire Safety Inspection Certificate is required; Puerto Princesa OCBO\'s published checklist used only as a structural example of the Unified Application/Ancillary Permit format. Castilla\'s own OBO checklist and fee schedule were not accessible during this research pass — see `sources` below.',
    effectiveDate: '2026-08-20',
    verified: false,
    sources: [_src1, _src2, _src3, _src4],
  ),
  CanonicalPermitType.electricalPermit: PermitRequirements(
    permitType: CanonicalPermitType.electricalPermit,
    requiredForm: 'Application for Electrical Permit',
    documents: [
      RequirementDocument(
        id: 'electrical-permit-land-title',
        label: 'Land Title or Tax Declaration of the property',
        isRequired: true,
        reviewingDepartmentId: 'obo',
      ),
      RequirementDocument(
        id: 'electrical-permit-owner-consent',
        label: 'Owner\'s Written Consent (if applicant is not the lot owner)',
        isRequired: false,
        reviewingDepartmentId: 'obo',
      ),
      RequirementDocument(
        id: 'electrical-permit-brgy-clearance',
        label: 'Barangay Clearance',
        isRequired: true,
        reviewingDepartmentId: 'zoning',
      ),
      RequirementDocument(
        id: 'electrical-permit-locational',
        label: 'Locational Clearance / Zoning Certification',
        isRequired: true,
        reviewingDepartmentId: 'zoning',
      ),
      RequirementDocument(
        id: 'electrical-permit-id',
        label: 'Valid Government-Issued ID of Applicant/Owner',
        isRequired: true,
        reviewingDepartmentId: 'obo',
      ),
      RequirementDocument(
        id: 'elec-plan',
        label: 'Electrical Plans (signed and sealed)',
        isRequired: true,
        reviewingDepartmentId: 'obo',
      ),
      RequirementDocument(
        id: 'elec-prc',
        label:
            'PRC License and PTR of Professional Electrical Engineer of Record',
        isRequired: true,
        reviewingDepartmentId: 'obo',
      ),
    ],
    responsibleDepartmentId: 'obo',
    evaluationSequence: [
      EvaluationSequenceStep(
        stage: EvaluationStageRef.initial,
        departmentId: 'obo',
      ),
      EvaluationSequenceStep(
        stage: EvaluationStageRef.zoning,
        departmentId: 'zoning',
      ),
      EvaluationSequenceStep(
        stage: EvaluationStageRef.fireSafety,
        departmentId: 'bfp',
      ),
      EvaluationSequenceStep(
        stage: EvaluationStageRef.obo,
        departmentId: 'obo',
      ),
      EvaluationSequenceStep(
        stage: EvaluationStageRef.finalApproval,
        departmentId: 'obo',
      ),
    ],
    paymentRequirements:
        'Building/permit fee, line-item fees per discipline (architectural/structural/electrical/mechanical/sanitary as applicable), and other regulatory fees assessed by the Municipal Treasurer’s Office based on project cost/floor area.',
    inspectionRequirements:
        'Electrical rough-in inspection and final electrical inspection prior to energization.',
    validityRules: 'Valid for twelve (12) months from issuance.',
    validityMonths: 12,
    finalDocument: 'Electrical Permit',
    releaseRequirements:
        'Full payment verified, OBO final sign-off recorded, and permit signed by the Municipal Engineer/Building Official.',
    sourceNote:
        'Legal basis: PD 1096 (National Building Code) for the permit itself and RA 9514 Sec. 5(g) where a Fire Safety Inspection Certificate is required; Puerto Princesa OCBO\'s published checklist used only as a structural example of the Unified Application/Ancillary Permit format. Castilla\'s own OBO checklist and fee schedule were not accessible during this research pass — see `sources` below.',
    effectiveDate: '2026-08-20',
    verified: false,
    sources: [_src1, _src2, _src3, _src4],
  ),
  CanonicalPermitType.mechanicalPermit: PermitRequirements(
    permitType: CanonicalPermitType.mechanicalPermit,
    requiredForm: 'Application for Mechanical Permit',
    documents: [
      RequirementDocument(
        id: 'mechanical-permit-land-title',
        label: 'Land Title or Tax Declaration of the property',
        isRequired: true,
        reviewingDepartmentId: 'obo',
      ),
      RequirementDocument(
        id: 'mechanical-permit-owner-consent',
        label: 'Owner\'s Written Consent (if applicant is not the lot owner)',
        isRequired: false,
        reviewingDepartmentId: 'obo',
      ),
      RequirementDocument(
        id: 'mechanical-permit-brgy-clearance',
        label: 'Barangay Clearance',
        isRequired: true,
        reviewingDepartmentId: 'zoning',
      ),
      RequirementDocument(
        id: 'mechanical-permit-locational',
        label: 'Locational Clearance / Zoning Certification',
        isRequired: true,
        reviewingDepartmentId: 'zoning',
      ),
      RequirementDocument(
        id: 'mechanical-permit-id',
        label: 'Valid Government-Issued ID of Applicant/Owner',
        isRequired: true,
        reviewingDepartmentId: 'obo',
      ),
      RequirementDocument(
        id: 'mech-plan',
        label: 'Mechanical Plans (signed and sealed)',
        isRequired: true,
        reviewingDepartmentId: 'obo',
      ),
      RequirementDocument(
        id: 'mech-prc',
        label:
            'PRC License and PTR of Professional Mechanical Engineer of Record',
        isRequired: true,
        reviewingDepartmentId: 'obo',
      ),
    ],
    responsibleDepartmentId: 'obo',
    evaluationSequence: [
      EvaluationSequenceStep(
        stage: EvaluationStageRef.initial,
        departmentId: 'obo',
      ),
      EvaluationSequenceStep(
        stage: EvaluationStageRef.zoning,
        departmentId: 'zoning',
      ),
      EvaluationSequenceStep(
        stage: EvaluationStageRef.fireSafety,
        departmentId: 'bfp',
      ),
      EvaluationSequenceStep(
        stage: EvaluationStageRef.obo,
        departmentId: 'obo',
      ),
      EvaluationSequenceStep(
        stage: EvaluationStageRef.finalApproval,
        departmentId: 'obo',
      ),
    ],
    paymentRequirements:
        'Building/permit fee, line-item fees per discipline (architectural/structural/electrical/mechanical/sanitary as applicable), and other regulatory fees assessed by the Municipal Treasurer’s Office based on project cost/floor area.',
    inspectionRequirements:
        'Mechanical equipment installation inspection prior to operation.',
    validityRules: 'Valid for twelve (12) months from issuance.',
    validityMonths: 12,
    finalDocument: 'Mechanical Permit',
    releaseRequirements:
        'Full payment verified, OBO final sign-off recorded, and permit signed by the Municipal Engineer/Building Official.',
    sourceNote:
        'Legal basis: PD 1096 (National Building Code) for the permit itself and RA 9514 Sec. 5(g) where a Fire Safety Inspection Certificate is required; Puerto Princesa OCBO\'s published checklist used only as a structural example of the Unified Application/Ancillary Permit format. Castilla\'s own OBO checklist and fee schedule were not accessible during this research pass — see `sources` below.',
    effectiveDate: '2026-08-20',
    verified: false,
    sources: [_src1, _src2, _src3, _src4],
  ),
  CanonicalPermitType.sanitaryPermit: PermitRequirements(
    permitType: CanonicalPermitType.sanitaryPermit,
    requiredForm: 'Application for Sanitary Permit',
    documents: [
      RequirementDocument(
        id: 'sanitary-permit-land-title',
        label: 'Land Title or Tax Declaration of the property',
        isRequired: true,
        reviewingDepartmentId: 'obo',
      ),
      RequirementDocument(
        id: 'sanitary-permit-owner-consent',
        label: 'Owner\'s Written Consent (if applicant is not the lot owner)',
        isRequired: false,
        reviewingDepartmentId: 'obo',
      ),
      RequirementDocument(
        id: 'sanitary-permit-brgy-clearance',
        label: 'Barangay Clearance',
        isRequired: true,
        reviewingDepartmentId: 'zoning',
      ),
      RequirementDocument(
        id: 'sanitary-permit-locational',
        label: 'Locational Clearance / Zoning Certification',
        isRequired: true,
        reviewingDepartmentId: 'zoning',
      ),
      RequirementDocument(
        id: 'sanitary-permit-id',
        label: 'Valid Government-Issued ID of Applicant/Owner',
        isRequired: true,
        reviewingDepartmentId: 'obo',
      ),
      RequirementDocument(
        id: 'sanplumb-plan',
        label: 'Sanitary / Plumbing Plans (signed and sealed)',
        isRequired: true,
        reviewingDepartmentId: 'obo',
      ),
      RequirementDocument(
        id: 'sanplumb-prc',
        label:
            'PRC License and PTR of Sanitary Engineer/Master Plumber of Record',
        isRequired: true,
        reviewingDepartmentId: 'obo',
      ),
    ],
    responsibleDepartmentId: 'obo',
    evaluationSequence: [
      EvaluationSequenceStep(
        stage: EvaluationStageRef.initial,
        departmentId: 'obo',
      ),
      EvaluationSequenceStep(
        stage: EvaluationStageRef.zoning,
        departmentId: 'zoning',
      ),
      EvaluationSequenceStep(
        stage: EvaluationStageRef.fireSafety,
        departmentId: 'bfp',
      ),
      EvaluationSequenceStep(
        stage: EvaluationStageRef.obo,
        departmentId: 'obo',
      ),
      EvaluationSequenceStep(
        stage: EvaluationStageRef.finalApproval,
        departmentId: 'obo',
      ),
    ],
    paymentRequirements:
        'Building/permit fee, line-item fees per discipline (architectural/structural/electrical/mechanical/sanitary as applicable), and other regulatory fees assessed by the Municipal Treasurer’s Office based on project cost/floor area.',
    inspectionRequirements:
        'Plumbing rough-in inspection and final sanitary inspection.',
    validityRules: 'Valid for twelve (12) months from issuance.',
    validityMonths: 12,
    finalDocument: 'Sanitary Permit',
    releaseRequirements:
        'Full payment verified, OBO final sign-off recorded, and permit signed by the Municipal Engineer/Building Official.',
    sourceNote:
        'Legal basis: PD 1096 (National Building Code) for the permit itself and RA 9514 Sec. 5(g) where a Fire Safety Inspection Certificate is required; Puerto Princesa OCBO\'s published checklist used only as a structural example of the Unified Application/Ancillary Permit format. Castilla\'s own OBO checklist and fee schedule were not accessible during this research pass — see `sources` below.',
    effectiveDate: '2026-08-20',
    verified: false,
    sources: [_src1, _src2, _src3, _src4],
  ),
  CanonicalPermitType.plumbingPermit: PermitRequirements(
    permitType: CanonicalPermitType.plumbingPermit,
    requiredForm: 'Application for Plumbing Permit',
    documents: [
      RequirementDocument(
        id: 'plumbing-permit-land-title',
        label: 'Land Title or Tax Declaration of the property',
        isRequired: true,
        reviewingDepartmentId: 'obo',
      ),
      RequirementDocument(
        id: 'plumbing-permit-owner-consent',
        label: 'Owner\'s Written Consent (if applicant is not the lot owner)',
        isRequired: false,
        reviewingDepartmentId: 'obo',
      ),
      RequirementDocument(
        id: 'plumbing-permit-brgy-clearance',
        label: 'Barangay Clearance',
        isRequired: true,
        reviewingDepartmentId: 'zoning',
      ),
      RequirementDocument(
        id: 'plumbing-permit-locational',
        label: 'Locational Clearance / Zoning Certification',
        isRequired: true,
        reviewingDepartmentId: 'zoning',
      ),
      RequirementDocument(
        id: 'plumbing-permit-id',
        label: 'Valid Government-Issued ID of Applicant/Owner',
        isRequired: true,
        reviewingDepartmentId: 'obo',
      ),
      RequirementDocument(
        id: 'plumb-plan',
        label: 'Plumbing Layout Plans (signed and sealed)',
        isRequired: true,
        reviewingDepartmentId: 'obo',
      ),
      RequirementDocument(
        id: 'plumb-prc',
        label: 'PRC License and PTR of Master Plumber of Record',
        isRequired: true,
        reviewingDepartmentId: 'obo',
      ),
    ],
    responsibleDepartmentId: 'obo',
    evaluationSequence: [
      EvaluationSequenceStep(
        stage: EvaluationStageRef.initial,
        departmentId: 'obo',
      ),
      EvaluationSequenceStep(
        stage: EvaluationStageRef.zoning,
        departmentId: 'zoning',
      ),
      EvaluationSequenceStep(
        stage: EvaluationStageRef.fireSafety,
        departmentId: 'bfp',
      ),
      EvaluationSequenceStep(
        stage: EvaluationStageRef.obo,
        departmentId: 'obo',
      ),
      EvaluationSequenceStep(
        stage: EvaluationStageRef.finalApproval,
        departmentId: 'obo',
      ),
    ],
    paymentRequirements:
        'Building/permit fee, line-item fees per discipline (architectural/structural/electrical/mechanical/sanitary as applicable), and other regulatory fees assessed by the Municipal Treasurer’s Office based on project cost/floor area.',
    inspectionRequirements: 'Plumbing rough-in and final inspection.',
    validityRules: 'Valid for twelve (12) months from issuance.',
    validityMonths: 12,
    finalDocument: 'Plumbing Permit',
    releaseRequirements:
        'Full payment verified, OBO final sign-off recorded, and permit signed by the Municipal Engineer/Building Official.',
    sourceNote:
        'Legal basis: PD 1096 (National Building Code) for the permit itself and RA 9514 Sec. 5(g) where a Fire Safety Inspection Certificate is required; Puerto Princesa OCBO\'s published checklist used only as a structural example of the Unified Application/Ancillary Permit format. Castilla\'s own OBO checklist and fee schedule were not accessible during this research pass — see `sources` below.',
    effectiveDate: '2026-08-20',
    verified: false,
    sources: [_src1, _src2, _src3, _src4],
  ),
  CanonicalPermitType.electronicsPermit: PermitRequirements(
    permitType: CanonicalPermitType.electronicsPermit,
    requiredForm: 'Application for Electronics Permit',
    documents: [
      RequirementDocument(
        id: 'electronics-permit-land-title',
        label: 'Land Title or Tax Declaration of the property',
        isRequired: true,
        reviewingDepartmentId: 'obo',
      ),
      RequirementDocument(
        id: 'electronics-permit-owner-consent',
        label: 'Owner\'s Written Consent (if applicant is not the lot owner)',
        isRequired: false,
        reviewingDepartmentId: 'obo',
      ),
      RequirementDocument(
        id: 'electronics-permit-brgy-clearance',
        label: 'Barangay Clearance',
        isRequired: true,
        reviewingDepartmentId: 'zoning',
      ),
      RequirementDocument(
        id: 'electronics-permit-locational',
        label: 'Locational Clearance / Zoning Certification',
        isRequired: true,
        reviewingDepartmentId: 'zoning',
      ),
      RequirementDocument(
        id: 'electronics-permit-id',
        label: 'Valid Government-Issued ID of Applicant/Owner',
        isRequired: true,
        reviewingDepartmentId: 'obo',
      ),
      RequirementDocument(
        id: 'electronics-plan',
        label: 'Electronics/Communications Layout Plans (signed and sealed)',
        isRequired: true,
        reviewingDepartmentId: 'obo',
      ),
      RequirementDocument(
        id: 'electronics-prc',
        label:
            'PRC License and PTR of Professional Electronics Engineer of Record',
        isRequired: true,
        reviewingDepartmentId: 'obo',
      ),
    ],
    responsibleDepartmentId: 'obo',
    evaluationSequence: [
      EvaluationSequenceStep(
        stage: EvaluationStageRef.initial,
        departmentId: 'obo',
      ),
      EvaluationSequenceStep(
        stage: EvaluationStageRef.zoning,
        departmentId: 'zoning',
      ),
      EvaluationSequenceStep(
        stage: EvaluationStageRef.fireSafety,
        departmentId: 'bfp',
      ),
      EvaluationSequenceStep(
        stage: EvaluationStageRef.obo,
        departmentId: 'obo',
      ),
      EvaluationSequenceStep(
        stage: EvaluationStageRef.finalApproval,
        departmentId: 'obo',
      ),
    ],
    paymentRequirements:
        'Building/permit fee, line-item fees per discipline (architectural/structural/electrical/mechanical/sanitary as applicable), and other regulatory fees assessed by the Municipal Treasurer’s Office based on project cost/floor area.',
    inspectionRequirements:
        'Installation inspection of electronics/communication systems prior to operation.',
    validityRules: 'Valid for twelve (12) months from issuance.',
    validityMonths: 12,
    finalDocument: 'Electronics Permit',
    releaseRequirements:
        'Full payment verified, OBO final sign-off recorded, and permit signed by the Municipal Engineer/Building Official.',
    sourceNote:
        'Legal basis: PD 1096 (National Building Code) for the permit itself and RA 9514 Sec. 5(g) where a Fire Safety Inspection Certificate is required; Puerto Princesa OCBO\'s published checklist used only as a structural example of the Unified Application/Ancillary Permit format. Castilla\'s own OBO checklist and fee schedule were not accessible during this research pass — see `sources` below.',
    effectiveDate: '2026-08-20',
    verified: false,
    sources: [_src1, _src2, _src3, _src4],
  ),
  CanonicalPermitType.interiorDesignPermit: PermitRequirements(
    permitType: CanonicalPermitType.interiorDesignPermit,
    requiredForm: 'Application for Interior Design Permit',
    documents: [
      RequirementDocument(
        id: 'interior-design-permit-land-title',
        label: 'Land Title or Tax Declaration of the property',
        isRequired: true,
        reviewingDepartmentId: 'obo',
      ),
      RequirementDocument(
        id: 'interior-design-permit-owner-consent',
        label: 'Owner\'s Written Consent (if applicant is not the lot owner)',
        isRequired: false,
        reviewingDepartmentId: 'obo',
      ),
      RequirementDocument(
        id: 'interior-design-permit-brgy-clearance',
        label: 'Barangay Clearance',
        isRequired: true,
        reviewingDepartmentId: 'zoning',
      ),
      RequirementDocument(
        id: 'interior-design-permit-locational',
        label: 'Locational Clearance / Zoning Certification',
        isRequired: true,
        reviewingDepartmentId: 'zoning',
      ),
      RequirementDocument(
        id: 'interior-design-permit-id',
        label: 'Valid Government-Issued ID of Applicant/Owner',
        isRequired: true,
        reviewingDepartmentId: 'obo',
      ),
      RequirementDocument(
        id: 'interior-plan',
        label: 'Interior Design Layout Plans (signed and sealed)',
        isRequired: true,
        reviewingDepartmentId: 'obo',
      ),
      RequirementDocument(
        id: 'interior-prc',
        label: 'PRC License and PTR of Interior Designer of Record',
        isRequired: true,
        reviewingDepartmentId: 'obo',
      ),
    ],
    responsibleDepartmentId: 'obo',
    evaluationSequence: [
      EvaluationSequenceStep(
        stage: EvaluationStageRef.initial,
        departmentId: 'obo',
      ),
      EvaluationSequenceStep(
        stage: EvaluationStageRef.zoning,
        departmentId: 'zoning',
      ),
      EvaluationSequenceStep(
        stage: EvaluationStageRef.fireSafety,
        departmentId: 'bfp',
      ),
      EvaluationSequenceStep(
        stage: EvaluationStageRef.obo,
        departmentId: 'obo',
      ),
      EvaluationSequenceStep(
        stage: EvaluationStageRef.finalApproval,
        departmentId: 'obo',
      ),
    ],
    paymentRequirements:
        'Building/permit fee, line-item fees per discipline (architectural/structural/electrical/mechanical/sanitary as applicable), and other regulatory fees assessed by the Municipal Treasurer’s Office based on project cost/floor area.',
    inspectionRequirements:
        'Site verification that fit-out matches submitted layout and fire egress is preserved.',
    validityRules: 'Valid for twelve (12) months from issuance.',
    validityMonths: 12,
    finalDocument: 'Interior Design Permit',
    releaseRequirements:
        'Full payment verified, OBO final sign-off recorded, and permit signed by the Municipal Engineer/Building Official.',
    sourceNote:
        'Legal basis: PD 1096 (National Building Code) for the permit itself and RA 9514 Sec. 5(g) where a Fire Safety Inspection Certificate is required; Puerto Princesa OCBO\'s published checklist used only as a structural example of the Unified Application/Ancillary Permit format. Castilla\'s own OBO checklist and fee schedule were not accessible during this research pass — see `sources` below.',
    effectiveDate: '2026-08-20',
    verified: false,
    sources: [_src1, _src2, _src3, _src4],
  ),
  CanonicalPermitType.fencingPermit: PermitRequirements(
    permitType: CanonicalPermitType.fencingPermit,
    requiredForm: 'Application for Fencing Permit',
    documents: [
      RequirementDocument(
        id: 'fencing-permit-land-title',
        label: 'Land Title or Tax Declaration of the property',
        isRequired: true,
        reviewingDepartmentId: 'obo',
      ),
      RequirementDocument(
        id: 'fencing-permit-owner-consent',
        label: 'Owner\'s Written Consent (if applicant is not the lot owner)',
        isRequired: false,
        reviewingDepartmentId: 'obo',
      ),
      RequirementDocument(
        id: 'fencing-permit-brgy-clearance',
        label: 'Barangay Clearance',
        isRequired: true,
        reviewingDepartmentId: 'zoning',
      ),
      RequirementDocument(
        id: 'fencing-permit-locational',
        label: 'Locational Clearance / Zoning Certification',
        isRequired: true,
        reviewingDepartmentId: 'zoning',
      ),
      RequirementDocument(
        id: 'fencing-permit-id',
        label: 'Valid Government-Issued ID of Applicant/Owner',
        isRequired: true,
        reviewingDepartmentId: 'obo',
      ),
      RequirementDocument(
        id: 'fencing-plan',
        label: 'Fence Plan / Site Development Plan',
        isRequired: true,
        reviewingDepartmentId: 'obo',
      ),
    ],
    responsibleDepartmentId: 'obo',
    evaluationSequence: [
      EvaluationSequenceStep(
        stage: EvaluationStageRef.initial,
        departmentId: 'obo',
      ),
      EvaluationSequenceStep(
        stage: EvaluationStageRef.zoning,
        departmentId: 'zoning',
      ),
      EvaluationSequenceStep(
        stage: EvaluationStageRef.fireSafety,
        departmentId: 'bfp',
      ),
      EvaluationSequenceStep(
        stage: EvaluationStageRef.obo,
        departmentId: 'obo',
      ),
      EvaluationSequenceStep(
        stage: EvaluationStageRef.finalApproval,
        departmentId: 'obo',
      ),
    ],
    paymentRequirements:
        'Building/permit fee, line-item fees per discipline (architectural/structural/electrical/mechanical/sanitary as applicable), and other regulatory fees assessed by the Municipal Treasurer’s Office based on project cost/floor area.',
    inspectionRequirements:
        'Site inspection to confirm fence height/setback compliance.',
    validityRules: 'Valid for six (6) months from issuance.',
    validityMonths: 6,
    finalDocument: 'Fencing Permit',
    releaseRequirements:
        'Full payment verified, OBO final sign-off recorded, and permit signed by the Municipal Engineer/Building Official.',
    sourceNote:
        'Legal basis: PD 1096 (National Building Code) for the permit itself and RA 9514 Sec. 5(g) where a Fire Safety Inspection Certificate is required; Puerto Princesa OCBO\'s published checklist used only as a structural example of the Unified Application/Ancillary Permit format. Castilla\'s own OBO checklist and fee schedule were not accessible during this research pass — see `sources` below.',
    effectiveDate: '2026-08-20',
    verified: false,
    sources: [_src1, _src2, _src3, _src4],
  ),
  CanonicalPermitType.signPermit: PermitRequirements(
    permitType: CanonicalPermitType.signPermit,
    requiredForm: 'Application for Signboard/Billboard Permit',
    documents: [
      RequirementDocument(
        id: 'sign-permit-land-title',
        label: 'Land Title or Tax Declaration of the property',
        isRequired: true,
        reviewingDepartmentId: 'obo',
      ),
      RequirementDocument(
        id: 'sign-permit-owner-consent',
        label: 'Owner\'s Written Consent (if applicant is not the lot owner)',
        isRequired: false,
        reviewingDepartmentId: 'obo',
      ),
      RequirementDocument(
        id: 'sign-permit-brgy-clearance',
        label: 'Barangay Clearance',
        isRequired: true,
        reviewingDepartmentId: 'zoning',
      ),
      RequirementDocument(
        id: 'sign-permit-locational',
        label: 'Locational Clearance / Zoning Certification',
        isRequired: true,
        reviewingDepartmentId: 'zoning',
      ),
      RequirementDocument(
        id: 'sign-permit-id',
        label: 'Valid Government-Issued ID of Applicant/Owner',
        isRequired: true,
        reviewingDepartmentId: 'obo',
      ),
      RequirementDocument(
        id: 'sign-plan',
        label:
            'Sign Design and Structural Detail (if elevated or free-standing)',
        isRequired: true,
        reviewingDepartmentId: 'obo',
      ),
      RequirementDocument(
        id: 'sign-prc',
        label:
            'PRC License and PTR of Engineer of Record (required for elevated/structural signs)',
        isRequired: false,
        reviewingDepartmentId: 'obo',
      ),
    ],
    responsibleDepartmentId: 'obo',
    evaluationSequence: [
      EvaluationSequenceStep(
        stage: EvaluationStageRef.initial,
        departmentId: 'obo',
      ),
      EvaluationSequenceStep(
        stage: EvaluationStageRef.zoning,
        departmentId: 'zoning',
      ),
      EvaluationSequenceStep(
        stage: EvaluationStageRef.fireSafety,
        departmentId: 'bfp',
      ),
      EvaluationSequenceStep(
        stage: EvaluationStageRef.obo,
        departmentId: 'obo',
      ),
      EvaluationSequenceStep(
        stage: EvaluationStageRef.finalApproval,
        departmentId: 'obo',
      ),
    ],
    paymentRequirements:
        'Building/permit fee, line-item fees per discipline (architectural/structural/electrical/mechanical/sanitary as applicable), and other regulatory fees assessed by the Municipal Treasurer’s Office based on project cost/floor area.',
    inspectionRequirements:
        'Structural safety inspection for elevated or free-standing signs.',
    validityRules:
        'Valid for twelve (12) months from issuance; subject to annual renewal.',
    validityMonths: 12,
    finalDocument: 'Sign Permit',
    releaseRequirements:
        'Full payment verified, OBO final sign-off recorded, and permit signed by the Municipal Engineer/Building Official.',
    sourceNote:
        'Legal basis: PD 1096 (National Building Code) for the permit itself and RA 9514 Sec. 5(g) where a Fire Safety Inspection Certificate is required; Puerto Princesa OCBO\'s published checklist used only as a structural example of the Unified Application/Ancillary Permit format. Castilla\'s own OBO checklist and fee schedule were not accessible during this research pass — see `sources` below.',
    effectiveDate: '2026-08-20',
    verified: false,
    sources: [_src1, _src2, _src3, _src4],
  ),
  CanonicalPermitType.excavationPermit: PermitRequirements(
    permitType: CanonicalPermitType.excavationPermit,
    requiredForm: 'Application for Excavation Permit',
    documents: [
      RequirementDocument(
        id: 'excavation-permit-land-title',
        label: 'Land Title or Tax Declaration of the property',
        isRequired: true,
        reviewingDepartmentId: 'obo',
      ),
      RequirementDocument(
        id: 'excavation-permit-owner-consent',
        label: 'Owner\'s Written Consent (if applicant is not the lot owner)',
        isRequired: false,
        reviewingDepartmentId: 'obo',
      ),
      RequirementDocument(
        id: 'excavation-permit-brgy-clearance',
        label: 'Barangay Clearance',
        isRequired: true,
        reviewingDepartmentId: 'zoning',
      ),
      RequirementDocument(
        id: 'excavation-permit-locational',
        label: 'Locational Clearance / Zoning Certification',
        isRequired: true,
        reviewingDepartmentId: 'zoning',
      ),
      RequirementDocument(
        id: 'excavation-permit-id',
        label: 'Valid Government-Issued ID of Applicant/Owner',
        isRequired: true,
        reviewingDepartmentId: 'obo',
      ),
      RequirementDocument(
        id: 'excavation-plan',
        label: 'Excavation/Site Development Plan',
        isRequired: true,
        reviewingDepartmentId: 'obo',
      ),
      RequirementDocument(
        id: 'excavation-geotech',
        label:
            'Geotechnical/Soil Assessment (if excavation exceeds regulated depth)',
        isRequired: false,
        reviewingDepartmentId: 'obo',
      ),
      RequirementDocument(
        id: 'excavation-prc',
        label: 'PRC License and PTR of Engineer of Record',
        isRequired: true,
        reviewingDepartmentId: 'obo',
      ),
    ],
    responsibleDepartmentId: 'obo',
    evaluationSequence: [
      EvaluationSequenceStep(
        stage: EvaluationStageRef.initial,
        departmentId: 'obo',
      ),
      EvaluationSequenceStep(
        stage: EvaluationStageRef.zoning,
        departmentId: 'zoning',
      ),
      EvaluationSequenceStep(
        stage: EvaluationStageRef.fireSafety,
        departmentId: 'bfp',
      ),
      EvaluationSequenceStep(
        stage: EvaluationStageRef.obo,
        departmentId: 'obo',
      ),
      EvaluationSequenceStep(
        stage: EvaluationStageRef.finalApproval,
        departmentId: 'obo',
      ),
    ],
    paymentRequirements:
        'Building/permit fee, line-item fees per discipline (architectural/structural/electrical/mechanical/sanitary as applicable), and other regulatory fees assessed by the Municipal Treasurer’s Office based on project cost/floor area.',
    inspectionRequirements:
        'Pre-excavation site inspection for shoring/safety measures; ongoing monitoring for deep excavations.',
    validityRules: 'Valid for six (6) months from issuance.',
    validityMonths: 6,
    finalDocument: 'Excavation Permit',
    releaseRequirements:
        'Full payment verified, OBO final sign-off recorded, and permit signed by the Municipal Engineer/Building Official.',
    sourceNote:
        'Legal basis: PD 1096 (National Building Code) for the permit itself and RA 9514 Sec. 5(g) where a Fire Safety Inspection Certificate is required; Puerto Princesa OCBO\'s published checklist used only as a structural example of the Unified Application/Ancillary Permit format. Castilla\'s own OBO checklist and fee schedule were not accessible during this research pass — see `sources` below.',
    effectiveDate: '2026-08-20',
    verified: false,
    sources: [_src1, _src2, _src3, _src4],
  ),
  CanonicalPermitType.fsecForBuildingPermitBfp: PermitRequirements(
    permitType: CanonicalPermitType.fsecForBuildingPermitBfp,
    requiredForm:
        'Fire Safety Evaluation Clearance Application Form (BFP-QSF-FSED-001, BFP Castilla Fire Station)',
    documents: [
      RequirementDocument(
        id: 'fsec-for-building-permit-bfp--land-title',
        label: 'Land Title or Tax Declaration of the property',
        isRequired: true,
        reviewingDepartmentId: 'obo',
      ),
      RequirementDocument(
        id: 'fsec-for-building-permit-bfp--owner-consent',
        label: 'Owner\'s Written Consent (if applicant is not the lot owner)',
        isRequired: false,
        reviewingDepartmentId: 'obo',
      ),
      RequirementDocument(
        id: 'fsec-for-building-permit-bfp--brgy-clearance',
        label: 'Barangay Clearance',
        isRequired: true,
        reviewingDepartmentId: 'zoning',
      ),
      RequirementDocument(
        id: 'fsec-for-building-permit-bfp--locational',
        label: 'Locational Clearance / Zoning Certification',
        isRequired: true,
        reviewingDepartmentId: 'zoning',
      ),
      RequirementDocument(
        id: 'fsec-for-building-permit-bfp--id',
        label: 'Valid Government-Issued ID of Applicant/Owner',
        isRequired: true,
        reviewingDepartmentId: 'obo',
      ),
      RequirementDocument(
        id: 'fsec-plan-set',
        label:
            'Three (3) complete sets of proposed plans: Architectural, Civil/Structural, Electrical, Mechanical, Plumbing, Electronics, Sanitary, and Fire Protection documents',
        isRequired: true,
        reviewingDepartmentId: 'bfp',
      ),
      RequirementDocument(
        id: 'fsec-fscr',
        label:
            'Fire Safety Compliance Report (FSCR), one (1) set (if necessary)',
        isRequired: false,
        reviewingDepartmentId: 'bfp',
      ),
      RequirementDocument(
        id: 'fsec-cost-estimate',
        label:
            'Cost Estimate of the building, including labor cost, signed and sealed by the designer/contractor and duly notarized, one (1) set',
        isRequired: true,
        reviewingDepartmentId: 'bfp',
      ),
      RequirementDocument(
        id: 'fsec-hotworks-clearance',
        label:
            'Fire Safety Clearance for Welding, Cutting, and other Hot Work Operations (if required)',
        isRequired: false,
        reviewingDepartmentId: 'bfp',
      ),
    ],
    responsibleDepartmentId: 'bfp',
    evaluationSequence: [
      EvaluationSequenceStep(
        stage: EvaluationStageRef.initial,
        departmentId: 'obo',
      ),
      EvaluationSequenceStep(
        stage: EvaluationStageRef.zoning,
        departmentId: 'zoning',
      ),
      EvaluationSequenceStep(
        stage: EvaluationStageRef.fireSafety,
        departmentId: 'bfp',
      ),
      EvaluationSequenceStep(
        stage: EvaluationStageRef.obo,
        departmentId: 'obo',
      ),
      EvaluationSequenceStep(
        stage: EvaluationStageRef.finalApproval,
        departmentId: 'obo',
      ),
    ],
    paymentRequirements:
        'Fire Code Construction Tax and related fire-code fees under RA 9514 and its IRR, collected by BFP (see the Unified Application Form\'s own Box 6 \'FOR FIRE SAFETY (BFP)\' fee lines).',
    inspectionRequirements:
        'Plan evaluation by BFP Castilla Fire Station personnel (CRO, FCA, FCCA, C,FSES, BPE, CFM/MFM per the form\'s own monitoring routing); the Fire Marshal approves or disapproves the FSEC application.',
    validityRules:
        'Serves as a prerequisite to Building Permit issuance under RA 9514; the form itself does not print a fixed validity/expiry period.',
    validityMonths: 12,
    finalDocument: 'FSEC for Building Permit (BFP)',
    releaseRequirements:
        'Full payment verified and FSEC signed/certified by the BFP Castilla Fire Station Customer Relation Officer and Fire Marshal.',
    sourceNote:
        'Legal basis: RA 9514 (Fire Code of the Philippines of 2008) — plan evaluation for fire-safety compliance is a statutory prerequisite to a Building Permit. Document list transcribed directly from the actual BFP Castilla Fire Station FSEC application form (BFP-QSF-FSED-001), obtained and reviewed in full — see `sources` below. (An authorized representative must present an authorization letter and a copy of the owner\'s ID, per the form\'s own note.)',
    effectiveDate: '2026-08-20',
    verified: true,
    sources: [_src2, _src6, _src7],
  ),
  CanonicalPermitType.certificateOfOccupancy: PermitRequirements(
    permitType: CanonicalPermitType.certificateOfOccupancy,
    requiredForm: 'Application for Certificate of Occupancy',
    // Transcribed from the Municipality of Castilla's own documentary
    // checklist on 31 August 2026 — the `CERTIFICATE OF OCCUPANCY DOCUMENTARY
    // REQUIREMENTS` section of `Building-Permit-and-Occupancy-Checklist.pdf`,
    // which has been bundled with this app all along and which only the
    // building permit entry had ever cited.
    //
    // What was here before came from PD 1096 and a Puerto Princesa sample, and
    // it differed from Castilla's list in both directions. It asked for five
    // documents Castilla does not list — Land Title, Barangay Clearance,
    // Locational Clearance, a valid ID and a Certificate of Final Electrical
    // Inspection — and omitted five it does: the Unified Form itself, the
    // approved plan, the approved specifications, photographs of the structure
    // and the professionals' licences. It also asked for a Fire Safety
    // INSPECTION Certificate where Castilla asks for a Fire Safety Compliance
    // and Commissioning **Report**, which is a different document.
    //
    // Copy counts are carried in the descriptions because the office counts
    // them at the counter, and an applicant who brings one of four is turned
    // away as surely as one who brings none.
    documents: [
      RequirementDocument(
        id: 'coo-unified-form',
        label: 'Unified Form for Certificate of Occupancy',
        isRequired: true,
        reviewingDepartmentId: 'obo',
        description: 'Four copies.',
      ),
      RequirementDocument(
        id: 'coo-completion',
        label: 'Certificate of Completion',
        isRequired: true,
        reviewingDepartmentId: 'obo',
        description: 'Duly notarised, signed and sealed. Four copies.',
      ),
      RequirementDocument(
        id: 'coo-approved-plan',
        label: 'Approved Plan',
        isRequired: true,
        reviewingDepartmentId: 'obo',
      ),
      RequirementDocument(
        id: 'coo-approved-specifications',
        label: 'Approved Specifications',
        isRequired: true,
        reviewingDepartmentId: 'obo',
      ),
      RequirementDocument(
        id: 'coo-construction-logbook',
        label: 'Construction Logbook',
        isRequired: true,
        reviewingDepartmentId: 'obo',
      ),
      RequirementDocument(
        id: 'coo-structure-photographs',
        label: 'Photographs of the Structure (all sides)',
        isRequired: true,
        reviewingDepartmentId: 'obo',
        description: 'Four copies.',
      ),
      RequirementDocument(
        id: 'coo-professional-licenses',
        label: 'Valid Licenses of all involved professionals',
        isRequired: true,
        reviewingDepartmentId: 'obo',
        description: 'Three copies.',
      ),
      RequirementDocument(
        id: 'coo-asbuilt',
        label: 'As-Built Plans',
        isRequired: false,
        reviewingDepartmentId: 'obo',
        description:
            'Four copies, and only where the building as completed differs '
            'from the approved plan. The checklist says "in case of changes '
            'in the building", so it is not demanded of every applicant.',
      ),
      RequirementDocument(
        id: 'coo-fsccr',
        label: 'Fire Safety Compliance and Commissioning Report (FSCCR)',
        isRequired: true,
        reviewingDepartmentId: 'bfp',
        description:
            'One copy. NOT the Fire Safety Inspection Certificate, which this '
            'app asked for until 31 August 2026 — the FSCCR is prepared by the '
            'project\'s own fire safety practitioner and precedes the FSIC.',
      ),
    ],
    responsibleDepartmentId: 'obo',
    evaluationSequence: [
      EvaluationSequenceStep(
        stage: EvaluationStageRef.initial,
        departmentId: 'obo',
      ),
      EvaluationSequenceStep(
        stage: EvaluationStageRef.zoning,
        departmentId: 'zoning',
      ),
      EvaluationSequenceStep(
        stage: EvaluationStageRef.fireSafety,
        departmentId: 'bfp',
      ),
      EvaluationSequenceStep(
        stage: EvaluationStageRef.obo,
        departmentId: 'obo',
      ),
      EvaluationSequenceStep(
        stage: EvaluationStageRef.finalApproval,
        departmentId: 'obo',
      ),
    ],
    paymentRequirements:
        'Building/permit fee, line-item fees per discipline (architectural/structural/electrical/mechanical/sanitary as applicable), and other regulatory fees assessed by the Municipal Treasurer’s Office based on project cost/floor area.',
    inspectionRequirements:
        'Final multi-discipline inspection (architectural, structural, electrical, mechanical, sanitary, fire safety) confirming the completed structure matches approved plans.',
    validityRules:
        'Valid for the life of the structure unless a change in use, occupancy, or ownership requires re-certification.',
    validityMonths: null,
    finalDocument: 'Certificate of Occupancy',
    releaseRequirements:
        'Full payment verified, OBO final sign-off recorded, and permit signed by the Municipal Engineer/Building Official.',
    sourceNote:
        'Legal basis: PD 1096 (National Building Code) for the permit itself and RA 9514 Sec. 5(g) where a Fire Safety Inspection Certificate is required; Puerto Princesa OCBO\'s published checklist used only as a structural example of the Unified Application/Ancillary Permit format. Castilla\'s own OBO checklist and fee schedule were not accessible during this research pass — see `sources` below.',
    effectiveDate: '2026-08-20',
    verified: true,
    sources: [_src0, _src1, _src2],
  ),
  CanonicalPermitType.fsicForOccupancyPermitBfp: PermitRequirements(
    permitType: CanonicalPermitType.fsicForOccupancyPermitBfp,
    requiredForm:
        'Fire Safety Inspection Certificate Application Form — FSIC for Certificate of Occupancy (BFP-QSF-FSED-002, BFP Castilla Fire Station)',
    documents: [
      RequirementDocument(
        id: 'fsic-for-occupancy-permit-bfp--land-title',
        label: 'Land Title or Tax Declaration of the property',
        isRequired: true,
        reviewingDepartmentId: 'obo',
      ),
      RequirementDocument(
        id: 'fsic-for-occupancy-permit-bfp--owner-consent',
        label: 'Owner\'s Written Consent (if applicant is not the lot owner)',
        isRequired: false,
        reviewingDepartmentId: 'obo',
      ),
      RequirementDocument(
        id: 'fsic-for-occupancy-permit-bfp--brgy-clearance',
        label: 'Barangay Clearance',
        isRequired: true,
        reviewingDepartmentId: 'zoning',
      ),
      RequirementDocument(
        id: 'fsic-for-occupancy-permit-bfp--locational',
        label: 'Locational Clearance / Zoning Certification',
        isRequired: true,
        reviewingDepartmentId: 'zoning',
      ),
      RequirementDocument(
        id: 'fsic-for-occupancy-permit-bfp--id',
        label: 'Valid Government-Issued ID of Applicant/Owner',
        isRequired: true,
        reviewingDepartmentId: 'obo',
      ),
      RequirementDocument(
        id: 'fsic-asbuilt',
        label: 'As-Built Plan (if necessary)',
        isRequired: false,
        reviewingDepartmentId: 'bfp',
      ),
      RequirementDocument(
        id: 'fsic-obo-endorsement',
        label: 'Endorsement from the Office of the Building Official (OBO)',
        isRequired: true,
        reviewingDepartmentId: 'bfp',
      ),
      RequirementDocument(
        id: 'fsic-completion-cert',
        label: 'Certificate of Completion',
        isRequired: true,
        reviewingDepartmentId: 'bfp',
      ),
      RequirementDocument(
        id: 'fsic-assessment-copy',
        label:
            'Certified True Copy of the Assessment Fee for securing the Certificate of Occupancy from OBO',
        isRequired: true,
        reviewingDepartmentId: 'bfp',
      ),
      RequirementDocument(
        id: 'fsic-fsccr',
        label:
            'Fire Safety Compliance and Commissioning Report (FSCCR), one (1) set (if necessary)',
        isRequired: false,
        reviewingDepartmentId: 'bfp',
      ),
    ],
    responsibleDepartmentId: 'bfp',
    evaluationSequence: [
      EvaluationSequenceStep(
        stage: EvaluationStageRef.initial,
        departmentId: 'obo',
      ),
      EvaluationSequenceStep(
        stage: EvaluationStageRef.zoning,
        departmentId: 'zoning',
      ),
      EvaluationSequenceStep(
        stage: EvaluationStageRef.fireSafety,
        departmentId: 'bfp',
      ),
      EvaluationSequenceStep(
        stage: EvaluationStageRef.obo,
        departmentId: 'obo',
      ),
      EvaluationSequenceStep(
        stage: EvaluationStageRef.finalApproval,
        departmentId: 'obo',
      ),
    ],
    paymentRequirements:
        'Fire code assessment fee under RA 9514 and its IRR, assessed by BFP and collected through/coordinated with the Municipal Treasurer\'s Office.',
    inspectionRequirements:
        'Final fire safety inspection by BFP Castilla Fire Station personnel confirming the completed building complies with fire safety standards, per the form\'s own monitoring routing (CRO, FCA, FCCA, C,FSES, FSI, CFM/MFM).',
    validityRules:
        'A final FSIC is a statutory prerequisite to a Certificate of Occupancy under RA 9514 Sec. 5(g)/7(a); the form itself does not print a fixed validity/expiry period for the occupancy FSIC.',
    validityMonths: 12,
    finalDocument: 'FSIC for Occupancy Permit (BFP)',
    releaseRequirements:
        'Full payment verified and FSIC signed/certified by the BFP Castilla Fire Station Customer Relation Officer and Fire Marshal.',
    sourceNote:
        'Legal basis: RA 9514 Sec. 5(g)/7(a) — a final Fire Safety Inspection Certificate is a statutory prerequisite to occupancy. This entry exposes FSIC as its own independently-filable permit type for applicants who file the fire inspection separately from the Certificate of Occupancy application itself (which retains its own bundled `coo-fsic` document requirement in the Certificate of Occupancy entry, unchanged). Document list transcribed directly from the actual BFP Castilla Fire Station FSIC application form (BFP-QSF-FSED-002), obtained and reviewed in full — see `sources` below.',
    effectiveDate: '2026-08-20',
    verified: true,
    sources: [_src2, _src8, _src7],
  ),
};

/// The catalog entry for a permit named by its wire string, or null when the
/// name is not one the admin defines.
///
/// Returns null rather than throwing: this is a display lookup, and a screen
/// reached with an unmapped label should say less, not crash. Parsing a value
/// that must be correct uses `canonicalPermitTypeFromWire`, which does throw.
PermitRequirements? requirementsForLabel(String wire) {
  for (final entry in requirementsCatalog.entries) {
    if (entry.key.wire == wire) return entry.value;
  }
  return null;
}
