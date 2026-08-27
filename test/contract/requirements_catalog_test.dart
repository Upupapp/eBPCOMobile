import 'package:flutter_test/flutter_test.dart';

import 'package:ebpco_user_app/core/contract/admin_vocabulary.dart';
import 'package:ebpco_user_app/core/contract/requirements_catalog.dart';

/// The catalog is the admin's answer to "what does this permit require", and
/// this app now mirrors it. These fixtures were produced by bundling the
/// admin's own `requirements-catalog.ts` with esbuild and running it, on
/// 27 August 2026 at Upupapp/eBPCO-Web @ e3cd7c3.
///
/// Executing the source beat reading it: two earlier attempts to parse that
/// file with regular expressions mis-assigned documents across spec boundaries
/// and undercounted six permit types. A fixture derived from a bad parse is
/// worse than none, because it makes the wrong number look checked.
///
/// When the admin changes, regenerate — do not edit a number to make a test
/// pass.

typedef _Expected = ({int docs, int required, int? validity, String dept});

const _fixture = <String, _Expected>{
  'Building Permit – New Construction': (docs: 22, required: 14, validity: 12, dept: 'obo'),
  'Building Permit – Renovation / Alteration': (docs: 9, required: 7, validity: 12, dept: 'obo'),
  'Building Permit – Addition / Extension': (docs: 9, required: 8, validity: 12, dept: 'obo'),
  'Demolition Permit': (docs: 9, required: 7, validity: 6, dept: 'obo'),
  'Zoning / Locational Clearance': (docs: 16, required: 13, validity: 12, dept: 'zoning'),
  'Architectural Permit': (docs: 7, required: 6, validity: 12, dept: 'obo'),
  'Civil / Structural Permit': (docs: 8, required: 7, validity: 12, dept: 'obo'),
  'Electrical Permit': (docs: 7, required: 6, validity: 12, dept: 'obo'),
  'Mechanical Permit': (docs: 7, required: 6, validity: 12, dept: 'obo'),
  'Sanitary Permit': (docs: 7, required: 6, validity: 12, dept: 'obo'),
  'Plumbing Permit': (docs: 7, required: 6, validity: 12, dept: 'obo'),
  'Electronics Permit': (docs: 7, required: 6, validity: 12, dept: 'obo'),
  'Interior Design Permit': (docs: 7, required: 6, validity: 12, dept: 'obo'),
  'Fencing Permit': (docs: 6, required: 5, validity: 6, dept: 'obo'),
  'Sign Permit': (docs: 7, required: 5, validity: 12, dept: 'obo'),
  'Excavation Permit': (docs: 8, required: 6, validity: 6, dept: 'obo'),
  'FSEC for Building Permit (BFP)': (docs: 9, required: 6, validity: 12, dept: 'bfp'),
  'Certificate of Occupancy': (docs: 9, required: 8, validity: null, dept: 'obo'),
  'FSIC for Occupancy Permit (BFP)': (docs: 10, required: 7, validity: 12, dept: 'bfp'),
};

void main() {
  test('every permit type has an entry', () {
    expect(requirementsCatalog.length, CanonicalPermitType.values.length);
    for (final type in CanonicalPermitType.values) {
      expect(requirementsCatalog[type], isNotNull,
          reason: '${type.wire} missing');
    }
  });

  test('document counts, required counts, validity and office all match', () {
    for (final entry in requirementsCatalog.entries) {
      final expected = _fixture[entry.key.wire]!;
      final actual = entry.value;
      expect(actual.documents.length, expected.docs,
          reason: '${entry.key.wire} document count');
      expect(actual.requiredDocumentCount, expected.required,
          reason: '${entry.key.wire} required count');
      expect(actual.validityMonths, expected.validity,
          reason: '${entry.key.wire} validity');
      expect(actual.responsibleDepartmentId, expected.dept,
          reason: '${entry.key.wire} responsible office');
    }
  });

  test('the three offices are represented', () {
    // Not every permit is the OBO's. Zoning belongs to the MPDO and the two
    // fire clearances to the BFP, which is why a fee or a status for those
    // types must not be attributed to the building office.
    final offices =
        requirementsCatalog.values.map((e) => e.responsibleDepartmentId).toSet();
    expect(offices, containsAll(<String>['obo', 'zoning', 'bfp']));
  });

  test('document ids are unique within a permit type', () {
    for (final entry in requirementsCatalog.entries) {
      final ids = entry.value.documents.map((d) => d.id).toList();
      expect(ids.toSet().length, ids.length,
          reason: '${entry.key.wire} has a duplicate document id');
    }
  });

  test('only the Certificate of Occupancy has no fixed expiry', () {
    final noExpiry = requirementsCatalog.entries
        .where((e) => e.value.validityMonths == null)
        .map((e) => e.key)
        .toList();
    expect(noExpiry, [CanonicalPermitType.certificateOfOccupancy]);
  });

  test('every entry cites a source with a verification status', () {
    for (final entry in requirementsCatalog.entries) {
      expect(entry.value.sources, isNotEmpty, reason: entry.key.wire);
      for (final source in entry.value.sources) {
        expect(source.verificationStatus, isNotEmpty);
      }
    }
  });

  test('provisional entries are distinguishable from verified ones', () {
    // The applicant is told which is which — see X4. This only asserts the
    // distinction survives into the mirror.
    final verified = requirementsCatalog.values.where((e) => e.verified).length;
    expect(verified, greaterThan(0));
    expect(verified, lessThan(requirementsCatalog.length));
  });
}
