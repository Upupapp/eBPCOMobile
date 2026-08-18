import 'permit_classification.dart';

/// One service as published in the LGU's Citizen's Charter.
///
/// RA 11032 requires every agency to publish a Citizen's Charter stating, for
/// each service, what it costs, how long it takes, and what the applicant must
/// bring. Surfacing it in the app is what lets an applicant hold the office to
/// a stated standard instead of guessing.
class CharterEntry {
  /// Matches the permit catalog entry this describes.
  final String permitType;

  final PermitClassification classification;

  /// Offices involved, in the order the application passes through them.
  final List<String> offices;

  /// Documentary requirements, each paired with where to obtain it.
  final List<CharterRequirement> requirements;

  /// How fees are determined. Never an amount — the app does not quote a
  /// figure the LGU has not assessed for the specific application.
  final String feeBasis;

  const CharterEntry({
    required this.permitType,
    required this.classification,
    required this.offices,
    required this.requirements,
    required this.feeBasis,
  });

  int get pledgedWorkingDays => classification.prescribedWorkingDays;
}

/// A documentary requirement and its issuing office.
///
/// The "where to secure" column is copied from the Citizen's Charter format
/// because it is the single most useful thing the app can tell an applicant:
/// knowing a Certified True Copy of the title comes from the Land Registration
/// Authority saves a wasted trip to the wrong counter.
class CharterRequirement {
  final String item;
  final String whereToSecure;

  /// True where a wet-signed notarised original is required. Notarised
  /// documents sit outside RA 8792's functional equivalence, so an electronic
  /// copy will not do.
  final bool requiresNotarisation;

  const CharterRequirement({
    required this.item,
    required this.whereToSecure,
    this.requiresNotarisation = false,
  });
}

/// Requirements common to every construction permit, so each entry lists only
/// what is particular to it.
const _commonRequirements = <CharterRequirement>[
  CharterRequirement(
    item: 'Duly accomplished Unified Building Permit Application Form',
    whereToSecure: 'Office of the Building Official, or this app',
    requiresNotarisation: true,
  ),
  CharterRequirement(
    item: 'Proof of ownership — Certified True Copy of the Transfer '
        'Certificate of Title',
    whereToSecure: 'Land Registration Authority / Registry of Deeds',
  ),
  CharterRequirement(
    item: 'Additional legal document showing right to build, if you are not '
        'the registered owner',
    whereToSecure: 'Deed of sale, lease, or consent from the owner',
    requiresNotarisation: true,
  ),
  CharterRequirement(
    item: 'Locational or Zoning Clearance',
    whereToSecure: 'City / Municipal Planning and Development Office',
  ),
  CharterRequirement(
    item: 'Barangay Clearance',
    whereToSecure: 'Barangay hall with territorial jurisdiction',
  ),
  CharterRequirement(
    item: 'Real property tax declaration and tax clearance',
    whereToSecure: 'City Assessor and City Treasurer',
  ),
  CharterRequirement(
    item: 'Plans and technical documents, signed and dry-sealed by the '
        'licensed professional in charge',
    whereToSecure: 'Your architect or engineer',
  ),
  CharterRequirement(
    item: 'Current PRC ID and Professional Tax Receipt of each professional',
    whereToSecure: 'Professional Regulation Commission and the LGU treasury',
  ),
];

const _fireSafety = CharterRequirement(
  item: 'Fire Safety Evaluation Clearance (FSEC)',
  whereToSecure: 'Bureau of Fire Protection',
);

/// The charter, keyed by the permit catalog's own titles.
///
/// Classifications here are the conservative reading of Amended JMC 2021-01:
/// where a permit could fall into more than one class depending on storeys,
/// floor area, and occupancy, the longer period is shown. Understating the
/// pledge would have the app accuse the office of lateness it never promised
/// against. The authoritative per-LGU values are M-08 in docs/MANUAL-TASKS.md.
const citizensCharter = <String, CharterEntry>{
  'New Construction': CharterEntry(
    permitType: 'New Construction',
    classification: PermitClassification.highlyTechnical,
    offices: [
      'Office of the Building Official',
      'City / Municipal Planning and Development Office',
      'Bureau of Fire Protection',
      'City Treasurer',
    ],
    requirements: [..._commonRequirements, _fireSafety],
    feeBasis:
        'Assessed by the Office of the Building Official under the schedule '
        'of fees of the National Building Code, based on floor area, '
        'occupancy, and the works covered.',
  ),
  'Renovation': CharterEntry(
    permitType: 'Renovation',
    classification: PermitClassification.complex,
    offices: [
      'Office of the Building Official',
      'Bureau of Fire Protection',
      'City Treasurer',
    ],
    requirements: [
      ..._commonRequirements,
      _fireSafety,
      CharterRequirement(
        item: 'Previous Building Permit and approved plans',
        whereToSecure: 'Your records, or the OBO Administrative Division',
      ),
    ],
    feeBasis:
        'Assessed under the National Building Code schedule of fees on the '
        'value and extent of the renovation works.',
  ),
  'Addition / Extension': CharterEntry(
    permitType: 'Addition / Extension',
    classification: PermitClassification.highlyTechnical,
    offices: [
      'Office of the Building Official',
      'City / Municipal Planning and Development Office',
      'Bureau of Fire Protection',
      'City Treasurer',
    ],
    requirements: [
      ..._commonRequirements,
      _fireSafety,
      CharterRequirement(
        item: 'Previous Building Permit, Certificate of Occupancy, and '
            'approved plans of the existing structure',
        whereToSecure: 'Your records, or the OBO Administrative Division',
      ),
    ],
    feeBasis:
        'Assessed on the added floor area and works under the National '
        'Building Code schedule of fees.',
  ),
  'Demolition': CharterEntry(
    permitType: 'Demolition',
    classification: PermitClassification.complex,
    offices: ['Office of the Building Official', 'City Treasurer'],
    requirements: [
      ..._commonRequirements,
      CharterRequirement(
        item: 'Demolition plan and safety measures, signed and sealed',
        whereToSecure: 'Your civil or structural engineer',
      ),
      CharterRequirement(
        item: 'Notice to adjoining property owners',
        whereToSecure: 'Prepared by the applicant',
        requiresNotarisation: true,
      ),
    ],
    feeBasis:
        'Assessed under the National Building Code schedule of fees on the '
        'area and height of the structure to be demolished.',
  ),
  'Certificate of Occupancy': CharterEntry(
    permitType: 'Certificate of Occupancy',
    classification: PermitClassification.complex,
    offices: [
      'Office of the Building Official',
      'Bureau of Fire Protection',
      'City Treasurer',
    ],
    requirements: [
      CharterRequirement(
        item: 'Duly accomplished Unified Application Form for Certificate of '
            'Occupancy',
        whereToSecure: 'Office of the Building Official, or this app',
        requiresNotarisation: true,
      ),
      CharterRequirement(
        item: 'Certificate of Completion signed and sealed by the architect '
            'or civil engineer in charge of construction',
        whereToSecure: 'Your professional, or the contractor’s Authorised '
            'Managing Officer where the work was contracted',
        requiresNotarisation: true,
      ),
      CharterRequirement(
        item: 'As-built plans where the finished work departs from the '
            'approved plans',
        whereToSecure: 'Your architect or engineer',
      ),
      CharterRequirement(
        item: 'Completion forms for electrical, mechanical, and electronics '
            'works, each signed and sealed',
        whereToSecure: 'The respective professional engineers',
      ),
      CharterRequirement(
        item: 'Detailed bill of materials at actual cost',
        whereToSecure: 'Your supervising professional',
      ),
      CharterRequirement(
        item: 'Daily construction logbook',
        whereToSecure: 'Kept on site during construction',
      ),
      CharterRequirement(
        item: 'Photographs of the completed structure — inside, front, sides, '
            'and rear',
        whereToSecure: 'Taken by the applicant',
      ),
      CharterRequirement(
        item: 'Fire Safety Inspection Certificate (FSIC) for Occupancy',
        whereToSecure: 'Bureau of Fire Protection',
      ),
      CharterRequirement(
        item: 'Copies of the Building Permit and all ancillary permits',
        whereToSecure: 'Your records',
      ),
    ],
    feeBasis:
        'Assessed under the National Building Code schedule of fees on the '
        'floor area and occupancy of the completed building.',
  ),
};

/// Ancillary and accessory permits share a shape, so their entries are
/// generated rather than repeated a dozen times.
CharterEntry ancillaryCharterEntry(String permitType) => CharterEntry(
  permitType: permitType,
  classification: PermitClassification.complex,
  offices: ['Office of the Building Official', 'City Treasurer'],
  requirements: [
    ..._commonRequirements,
    const CharterRequirement(
      item: 'Parent Building Permit, where this is filed against an existing '
          'application',
      whereToSecure: 'Your records, or the OBO Administrative Division',
    ),
  ],
  feeBasis:
      'Assessed under the National Building Code schedule of fees on the '
      'works covered by this permit.',
);

/// The charter entry for [permitType], generating an ancillary entry for
/// anything not separately described.
CharterEntry charterFor(String permitType) =>
    citizensCharter[permitType] ?? ancillaryCharterEntry(permitType);
