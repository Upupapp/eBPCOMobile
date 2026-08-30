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

  test('the wizard collects exactly what the list names', () {
    // This was a KNOWN GAP for one commit: the catalogue was corrected first
    // and the wizard followed. Asserted the other way round now — a slot that
    // disappears fails here, and so does one added for a document Castilla
    // does not ask for at this stage.
    final model = File(
      'lib/core/models/certificate_of_occupancy_model.dart',
    ).readAsStringSync();

    for (final slot in const [
      'unifiedOccupancyFormUpload',
      'certificateOfCompletionUpload',
      'approvedPlanUpload',
      'approvedSpecificationsUpload',
      'constructionLogbookUpload',
      'structurePhotographsUpload',
      'professionalLicensesUpload',
      'asBuiltPlansUpload',
      'fireSafetyComplianceReportUpload',
    ]) {
      expect(model, contains(slot), reason: slot);
    }

    // The five it used to demand and Castilla does not list. Each was a trip
    // to another office for a document nobody was going to ask for.
    for (final ghost in const [
      'landTitleOrTaxDeclarationUpload',
      'barangayClearanceUpload',
      'locationalClearanceUpload',
      'validGovernmentIdUpload',
      'electricalCertificateUpload',
    ]) {
      expect(model, isNot(contains(ghost)), reason: ghost);
    }

    expect(
      model,
      isNot(contains('fireSafetyInspectionCertificateUpload')),
      reason: 'the FSIC slot became the FSCCR, which is a different document',
    );
  });

  test('the wizard requires the eight, and not the conditional ninth', () {
    // As-built plans are "in case of changes in the building". A wizard that
    // blocks submission on them contradicts the list it is built from.
    final model = File(
      'lib/core/models/certificate_of_occupancy_model.dart',
    ).readAsStringSync();
    final validity = model.substring(
      model.indexOf(
        'bool isValid() {',
        model.indexOf('OccupancyRequiredDocuments'),
      ),
    );
    final body = validity.substring(0, validity.indexOf('\n  }'));
    expect(
      body,
      isNot(contains('asBuiltPlansUpload == null')),
      reason: 'as-built plans are conditional on the checklist',
    );
    for (final required in const [
      'unifiedOccupancyFormUpload',
      'certificateOfCompletionUpload',
      'fireSafetyComplianceReportUpload',
    ]) {
      expect(body, contains('$required == null'), reason: required);
    }
  });
}
