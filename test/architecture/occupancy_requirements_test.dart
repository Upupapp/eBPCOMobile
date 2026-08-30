import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:ebpco_user_app/core/contract/admin_vocabulary.dart';
import 'package:ebpco_user_app/core/contract/requirements_catalog.dart';

/// The Certificate of Occupancy, against Castilla's own checklist.
///
/// `assets/permits/Building-Permit-and-Occupancy-Checklist.pdf` has a section
/// headed **CERTIFICATE OF OCCUPANCY DOCUMENTARY REQUIREMENTS**, and until 31
/// August 2026 only the building permit entry cited that file. The occupancy
/// entry was built from PD 1096 and a Puerto Princesa sample, and it differed
/// from Castilla's list **in both directions**.
///
/// This is the permit that closes out a build. An applicant turned away at the
/// counter here has already finished the work.

void main() {
  final requirements = requirementsForLabel(
    CanonicalPermitType.certificateOfOccupancy.wire,
  )!;
  final labels = requirements.documents.map((d) => d.label).toList();

  test('every item Castilla prints is asked for', () {
    for (final item in const [
      'Unified Form for Certificate of Occupancy',
      'Certificate of Completion',
      'Approved Plan',
      'Approved Specifications',
      'Construction Logbook',
      'Photographs of the Structure (all sides)',
      'Valid Licenses of all involved professionals',
      'As-Built Plans',
      'Fire Safety Compliance and Commissioning Report (FSCCR)',
    ]) {
      expect(labels, contains(item), reason: item);
    }
    expect(labels, hasLength(9), reason: 'the checklist prints nine lines');
  });

  test('and nothing Castilla does not print is demanded', () {
    // The five the app used to ask for. Each is a document the applicant would
    // have gone and secured, at a counter, for a list the office does not
    // keep.
    for (final ghost in const [
      'Land Title or Tax Declaration of the property',
      'Barangay Clearance',
      'Locational Clearance / Zoning Certification',
      'Valid Government-Issued ID of Applicant/Owner',
      'Certificate of Final Electrical Inspection',
    ]) {
      expect(labels, isNot(contains(ghost)), reason: ghost);
    }
  });

  test('the FSCCR is not the FSIC', () {
    // The app asked for a Fire Safety INSPECTION Certificate; the checklist
    // asks for a Fire Safety Compliance and Commissioning REPORT. The FSCCR is
    // prepared by the project's own fire safety practitioner and precedes the
    // FSIC, so an applicant sent for the wrong one arrives with a document the
    // office cannot accept and no way to know why.
    expect(labels.any((l) => l.contains('FSCCR')), isTrue);
    expect(
      labels.any((l) => l.contains('Fire Safety Inspection Certificate')),
      isFalse,
    );
  });

  test('the as-built plans are conditional, as the checklist says', () {
    // "in case of changes in the building". Presenting an optional document as
    // mandatory costs the applicant a trip they did not owe — which is
    // `RequirementDocument.isRequired`'s own stated reason for existing.
    final asBuilt = requirements.documents.singleWhere(
      (d) => d.label == 'As-Built Plans',
    );
    expect(asBuilt.isRequired, isFalse);
    expect(asBuilt.description, contains('differs from the approved plan'));
  });

  test('the entry cites the checklist, and says it is Castilla-sourced', () {
    expect(requirements.verified, isTrue);
    expect(
      requirements.sources.map((s) => s.verificationStatus),
      contains('CASTILLA_OFFICIAL_FORM_VERIFIED'),
    );
    expect(
      requirements.sources.map((s) => s.url),
      contains('/assets/permits/Building-Permit-and-Occupancy-Checklist.pdf'),
    );
  });

  test('the copy counts the office actually counts are carried', () {
    // Four copies of the form, three of the licences, one of the FSCCR. An
    // applicant who brings one of four is turned away as surely as one who
    // brings none.
    String descriptionOf(String label) =>
        requirements.documents
            .singleWhere((d) => d.label == label)
            .description ??
        '';
    expect(
      descriptionOf('Unified Form for Certificate of Occupancy'),
      contains('Four copies'),
    );
    expect(
      descriptionOf('Valid Licenses of all involved professionals'),
      contains('Three copies'),
    );
    expect(descriptionOf('Certificate of Completion'), contains('notarised'));
  });

  test('KNOWN GAP — the wizard does not yet collect what the list names', () {
    // Asserted as it stands, so the day the wizard is aligned this fails and
    // says so. The catalogue tells the applicant what to bring; the wizard
    // gives them somewhere to put it, and the two do not agree.
    final model = File(
      'lib/core/models/certificate_of_occupancy_model.dart',
    ).readAsStringSync();
    final missing = [
      for (final entry in const {
        'Unified Form for Certificate of Occupancy': 'unifiedOccupancyForm',
        'Approved Plan': 'approvedPlanUpload',
        'Approved Specifications': 'approvedSpecificationsUpload',
        'Photographs of the Structure (all sides)': 'structurePhotographs',
        'Valid Licenses of all involved professionals': 'professionalLicenses',
        'Fire Safety Compliance and Commissioning Report (FSCCR)':
            'fsccrUpload',
      }.entries)
        if (!model.contains(entry.value)) entry.key,
    ];
    expect(
      missing,
      hasLength(6),
      reason:
          'the wizard now has an upload slot for one of these — good. Remove '
          'it from this list, and check the applicant is asked for it on the '
          'step that reviews the occupancy documents: $missing',
    );
    expect(
      model,
      contains('fireSafetyInspectionCertificateUpload'),
      reason:
          'the wizard still collects an FSIC, which Castilla does not ask for '
          'at this stage. When that slot becomes the FSCCR, delete this',
    );
  });
}
