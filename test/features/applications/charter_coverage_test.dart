import 'package:flutter_test/flutter_test.dart';

import 'package:ebpco_user_app/core/contract/admin_vocabulary.dart';
import 'package:ebpco_user_app/core/contract/requirements_catalog.dart';
import 'package:ebpco_user_app/core/models/citizens_charter.dart';

/// RA 11032 requires the LGU to publish, for every service, what it costs, how
/// long it takes and what the applicant must bring. Surfacing that is what lets
/// an applicant hold the office to a stated standard instead of guessing.
///
/// The charter was keyed on the app's own short display names — 'New
/// Construction' — while the requirements catalog and the admin portal both
/// say 'Building Permit – New Construction'. Every lookup by the office's own
/// name missed and fell through to a generic ancillary entry.

void main() {
  test('every permit type in the catalog has a charter entry', () {
    for (final type in CanonicalPermitType.values) {
      final entry = charterFor(type.wire);
      expect(entry, isNotNull, reason: type.wire);
      expect(
        entry.requirements,
        isNotEmpty,
        reason: '${type.wire} must tell the applicant what to bring',
      );
      expect(entry.feeBasis, isNotEmpty, reason: type.wire);
      expect(entry.pledgedWorkingDays, greaterThan(0), reason: type.wire);
    }
  });

  test('the described permits are not the generic entry', () {
    // These have their own transcribed requirements. Falling back would lose
    // them silently, which is what was happening.
    // Asserted by map membership, not by comparing requirement counts: one of
    // these legitimately lists as many requirements as the generic entry, so a
    // count comparison would report a fallback that had not happened.
    for (final type in [
      CanonicalPermitType.buildingPermitNewConstruction,
      CanonicalPermitType.buildingPermitRenovationAlteration,
      CanonicalPermitType.buildingPermitAdditionExtension,
      CanonicalPermitType.demolitionPermit,
      CanonicalPermitType.certificateOfOccupancy,
      CanonicalPermitType.zoningLocationalClearance,
      CanonicalPermitType.fsecForBuildingPermitBfp,
      CanonicalPermitType.fsicForOccupancyPermitBfp,
    ]) {
      expect(
        citizensCharter.containsKey(type.wire),
        isTrue,
        reason: '${type.wire} falls through to the generic ancillary entry',
      );
      expect(charterFor(type.wire).permitType, type.wire);
    }
  });

  group('the three permits that are not the OBO', () {
    test('Zoning is handled by the MPDO', () {
      final entry = charterFor(
        CanonicalPermitType.zoningLocationalClearance.wire,
      );
      expect(entry.offices.first, contains('Planning'));
      expect(
        entry.offices.any((o) => o.contains('Building Official')),
        isFalse,
        reason:
            'sending an applicant to the OBO for zoning is the wrong '
            'counter',
      );
    });

    test('both fire clearances are handled by the BFP', () {
      for (final type in [
        CanonicalPermitType.fsecForBuildingPermitBfp,
        CanonicalPermitType.fsicForOccupancyPermitBfp,
      ]) {
        final entry = charterFor(type.wire);
        expect(entry.offices.single, contains('Bureau of Fire Protection'));
        expect(
          entry.feeBasis,
          contains('not \nby the LGU.'.replaceAll('\n', '')),
          reason: '${type.wire} fees are collected by the Bureau',
        );
      }
    });

    test('their responsible office matches the requirements catalog', () {
      // The two sources must not disagree about which office owns a permit.
      const expected = {
        CanonicalPermitType.zoningLocationalClearance: 'zoning',
        CanonicalPermitType.fsecForBuildingPermitBfp: 'bfp',
        CanonicalPermitType.fsicForOccupancyPermitBfp: 'bfp',
      };
      expected.forEach((type, departmentId) {
        expect(
          requirementsCatalog[type]!.responsibleDepartmentId,
          departmentId,
        );
      });
    });
  });

  test('a permit type nobody has described still answers', () {
    // The generic entry is a fallback, not a failure — but it must still tell
    // the applicant something usable.
    final entry = charterFor('Some Permit The Catalog Never Heard Of');
    expect(entry.requirements, isNotEmpty);
    expect(entry.pledgedWorkingDays, greaterThan(0));
  });
}
