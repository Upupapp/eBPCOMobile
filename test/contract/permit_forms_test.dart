import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:ebpco_user_app/core/contract/admin_vocabulary.dart';
import 'package:ebpco_user_app/core/contract/permit_forms.dart';

/// The forms register against the files and against the admin's own map.
///
/// The failure this exists to prevent is the one the master command names: a
/// permit type offering "View the official form" and opening nothing. A path
/// in Dart proves nothing on its own — the file has to be there, and the
/// directory has to be declared in `pubspec.yaml`, or the button is live and
/// the bundle is empty.

/// The admin's `permit-form-templates.ts`, transcribed. Kept as data here so
/// the two lines can be compared rather than assumed equal — if the admin
/// repoints a type at a different PDF, this list is where the divergence
/// shows up.
const _adminFormFiles = <String, String>{
  'Building Permit – New Construction': 'New-Construction.pdf',
  'Building Permit – Renovation / Alteration': 'New-Construction.pdf',
  'Building Permit – Addition / Extension': 'New-Construction.pdf',
  'Architectural Permit': 'Architectural-Permit.pdf',
  'Civil / Structural Permit': 'Civil-Structural-Permit.pdf',
  'Demolition Permit': 'Demolition-Permit.pdf',
  'Zoning / Locational Clearance': 'Zoning-Locational-Clearance-Form.pdf',
  'Electrical Permit': 'Electrical-Permit-Form.pdf',
  'Electronics Permit': 'Electronics-Permit.pdf',
  'Mechanical Permit': 'Mechanical-Permit.pdf',
  'Plumbing Permit': 'Plumbing-Permit.pdf',
  'Sanitary Permit': 'Sanitary-Plumbing-Permit.pdf',
  'Interior Design Permit': 'Interior-Design-Permit.pdf',
  'Fencing Permit': 'Fencing-Permit-Form.pdf',
  'Sign Permit': 'Sign-Permit-Form.pdf',
  'Excavation Permit': 'Excavation-Permit-Form.pdf',
  'FSEC for Building Permit (BFP)': 'FSEC-for-Building-Permit-BFP.pdf',
  'Certificate of Occupancy': 'Application-for-Certificate-of-Occupancy.pdf',
  'FSIC for Occupancy Permit (BFP)': 'FSIC-for-Occupancy-Permit-BFP.pdf',
};

/// The five the admin's comment marks as generic stand-ins rather than
/// Castilla documents.
const _referenceOnly = <CanonicalPermitType>{
  CanonicalPermitType.architecturalPermit,
  CanonicalPermitType.interiorDesignPermit,
  CanonicalPermitType.signPermit,
  CanonicalPermitType.demolitionPermit,
  CanonicalPermitType.certificateOfOccupancy,
};

void main() {
  group('every bundled path resolves to a real file', () {
    for (final type in CanonicalPermitType.values) {
      test('${type.wire} — form', () {
        final form = permitFormFor(type);
        if (form == null) return; // null is a permitted answer; see below
        final file = File(form.assetPath);
        expect(
          file.existsSync(),
          isTrue,
          reason:
              '${form.assetPath} is offered to the applicant but is not on '
              'disk — the button would open nothing',
        );
        expect(
          file.lengthSync(),
          greaterThan(1000),
          reason: '${form.assetPath} is too small to be a real form',
        );
        expect(
          file.readAsBytesSync().sublist(0, 4),
          [0x25, 0x50, 0x44, 0x46], // %PDF
          reason: '${form.assetPath} is not a PDF',
        );
      });
    }

    test('the checklist file is real', () {
      final checklist = permitChecklistFor(
        CanonicalPermitType.buildingPermitNewConstruction,
      )!;
      expect(File(checklist.assetPath).existsSync(), isTrue);
    });
  });

  test('the asset directory is declared in pubspec', () {
    // Without this line every path above resolves on disk and none of them
    // resolves in the shipped app.
    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(pubspec, contains('assets/permits/'));
  });

  group('the register matches the admin', () {
    test('the same nineteen types map to the same nineteen files', () {
      for (final type in CanonicalPermitType.values) {
        final expected = _adminFormFiles[type.wire];
        final actual = permitFormFor(type)?.assetPath.split('/').last;
        expect(
          actual,
          expected,
          reason: '${type.wire} points at a different form than the admin',
        );
      }
    });

    test('three building sub-types share one physical form', () {
      final paths = {
        permitFormFor(
          CanonicalPermitType.buildingPermitNewConstruction,
        )!.assetPath,
        permitFormFor(
          CanonicalPermitType.buildingPermitRenovationAlteration,
        )!.assetPath,
        permitFormFor(
          CanonicalPermitType.buildingPermitAdditionExtension,
        )!.assetPath,
      };
      expect(
        paths,
        hasLength(1),
        reason: 'Castilla issues one Unified Application Form for all three',
      );
    });

    test('the checklist covers exactly the four types the admin gives it', () {
      final covered = CanonicalPermitType.values
          .where((t) => permitChecklistFor(t) != null)
          .toSet();
      expect(covered, {
        CanonicalPermitType.buildingPermitNewConstruction,
        CanonicalPermitType.buildingPermitRenovationAlteration,
        CanonicalPermitType.buildingPermitAdditionExtension,
        CanonicalPermitType.certificateOfOccupancy,
      });
    });
  });

  group('reference templates are marked as such', () {
    test('exactly the five the admin identifies', () {
      final flagged = CanonicalPermitType.values
          .where((t) => permitFormFor(t)?.isOfficialCastillaForm == false)
          .toSet();
      expect(
        flagged,
        _referenceOnly,
        reason:
            'the admin records this in a comment only; getting it wrong here '
            'presents a stand-in as an LGU document',
      );
    });

    test('the BFP forms are the BFP\'s, and zoning is the MPDO\'s', () {
      // Three offices issue these, and an applicant who takes an FSEC form to
      // the Building Official has wasted the trip.
      expect(
        permitFormFor(CanonicalPermitType.fsecForBuildingPermitBfp)!.office,
        FormIssuingOffice.bfp,
      );
      expect(
        permitFormFor(CanonicalPermitType.fsicForOccupancyPermitBfp)!.office,
        FormIssuingOffice.bfp,
      );
      expect(
        permitFormFor(CanonicalPermitType.zoningLocationalClearance)!.office,
        FormIssuingOffice.mpdo,
      );
    });
  });

  group('lookup by wire label', () {
    test('finds the form the applicant filed under', () {
      expect(
        permitFormForLabel('Fencing Permit')?.assetPath,
        contains('Fencing-Permit-Form.pdf'),
      );
      expect(permitChecklistForLabel('Certificate of Occupancy'), isNotNull);
    });

    test('an unrecognised label costs a missing form, not a crash', () {
      expect(permitFormForLabel('Business Permit'), isNull);
      expect(permitChecklistForLabel('Business Permit'), isNull);
    });
  });

  test('permitDocumentsFor lists the form first, then the checklist', () {
    final building = permitDocumentsFor(
      CanonicalPermitType.buildingPermitNewConstruction,
    );
    expect(building, hasLength(2));
    expect(building.first.title, contains('Unified Application Form'));
    expect(building.last.title, contains('Checklist'));

    // A type with no checklist gets one entry, not an empty slot.
    expect(permitDocumentsFor(CanonicalPermitType.fencingPermit), hasLength(1));
  });
}
