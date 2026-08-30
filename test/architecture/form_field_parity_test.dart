import 'package:flutter_test/flutter_test.dart';

import 'package:ebpco_user_app/core/contract/admin_vocabulary.dart';
import 'package:ebpco_user_app/core/contract/permit_forms.dart';
import 'package:ebpco_user_app/core/models/building_permit_model.dart';
import 'package:ebpco_user_app/core/models/civil_structural_permit_model.dart';
import 'package:ebpco_user_app/core/models/electrical_permit_model.dart';
import 'package:ebpco_user_app/core/models/electronics_permit_model.dart';
import 'package:ebpco_user_app/core/models/excavation_permit_model.dart';
import 'package:ebpco_user_app/core/models/mechanical_permit_model.dart';
import 'package:ebpco_user_app/core/models/plumbing_permit_model.dart';
import 'package:ebpco_user_app/core/models/sanitary_plumbing_permit_model.dart';

/// What the bundled forms actually ask for, counted off the paper.
///
/// Each figure below was read from page one of the form itself on 31 August
/// 2026, rendered with `tool/render-form.sh`. They are pinned here because a
/// count that lives only in a document is a count nobody checks: an option
/// quietly added to or dropped from an enum fails this test and has to be
/// justified against the paper.
///
/// **Scope, honestly.** Page one only — there is no poppler on this machine,
/// so `qlmanage` gives the first page and nothing else. Every figure here is
/// from a box that appears on page one. Fixture inventories and specification
/// tables that continue overleaf are NOT covered, and the two fixture counts
/// below are asserted as the app's own, not as the form's.

void main() {
  group('Scope of Work, as printed', () {
    test('Unified Application Form for Building Permit — twelve options', () {
      // NEW CONSTRUCTION · ERECTION · ADDITION · ALTERATION · RENOVATION ·
      // CONVERSION · REPAIR · MOVING · RAISING · ACCESSORY BUILDING/STRUCTURE ·
      // LEGALIZATION OF EXISTING BUILDING · OTHERS
      //
      // The app had eleven until 31 August: legalisation was missing, so an
      // applicant regularising an unpermitted structure had to choose
      // "Others" and type it.
      expect(ScopeOfWorkOption.values, hasLength(12));
      expect(
        ScopeOfWorkOption.values.map((o) => o.label),
        contains('Legalization of Existing Building'),
      );
    });

    test('the ancillary permits that share the twelve-option box', () {
      // Civil/Structural (A-02), Mechanical (A-04), Sanitary (A-05) and
      // Plumbing (A-06) print the same twelve, with DEMOLITION in place of the
      // building form's LEGALIZATION.
      expect(CivilStructuralScopeType.values, hasLength(12));
      expect(MechanicalScopeType.values, hasLength(12));
      expect(SanitaryScopeType.values, hasLength(12));
      expect(PlumbingScopeType.values, hasLength(12));
    });

    test('Electrical (A-03) prints eight', () {
      // NEW INSTALLATION · ANNUAL INSPECTION · TEMPORARY · RECONNECTION ·
      // SEPARATION · UPGRADING · RELOCATION of service entrance · OTHERS
      expect(ElectricalScopeType.values, hasLength(8));
    });

    test('Electronics (A-07) prints three', () {
      // NEW INSTALATION [sic] · ANNUAL INSPECTION · OTHERS
      expect(ElectronicsScopeType.values, hasLength(3));
    });

    test('Excavation (B-02) prints six', () {
      // NEW CONSTRUCTION · ERECTION · ADDITION · RENOVATION · REPAIR · OTHERS
      expect(ExcavationScopeType.values, hasLength(6));
    });
  });

  group('the technical boxes each form prints', () {
    test('Civil/Structural Box 2 — fifteen natures of work', () {
      expect(NatureOfWork.values, hasLength(15));
    });

    test('Electrical Box 3 — the supervisor may be one of three', () {
      // PROFESSIONAL ELECTRICAL ENGINEER · REGISTERED ELECTRICAL ENGINEER ·
      // REGISTERED MASTER ELECTRICIAN. The third is the common one on small
      // works, and dropping it would push those applicants into a wrong
      // answer rather than no answer.
      expect(ElectricalProfessionType.values, hasLength(3));
    });

    test('Mechanical Box 4 — the supervisor may be one of two', () {
      expect(MechanicalProfessionType.values, hasLength(2));
    });

    test('Electronics Box 2 — fourteen systems', () {
      expect(ElectronicsSystemType.values, hasLength(14));
    });

    test('Sanitary Box 2 — four water supplies, eight disposal systems', () {
      expect(WaterSupplyType.values, hasLength(4));
      expect(DisposalSystemType.values, hasLength(8));
    });

    test('Plumbing Box 2 — four systems, and the app\'s own fixture list', () {
      expect(PlumbingSystemType.values, hasLength(4));
      // The form's page-one fixture table prints twenty-two kinds; the app
      // offers twenty-three, the extra being a swimming pool. Recorded as the
      // app's number rather than the form's, because it is a superset and
      // because the sanitary fixture table continues overleaf where this
      // audit could not follow.
      expect(PlumbingFixtureType.values, hasLength(23));
      expect(SanitaryFixtureType.values, hasLength(23));
    });
  });

  test('a form is named as the document names itself', () {
    // `PermitForm.title` is documented as "the document's own title, not the
    // permit type's, because they differ and the applicant is looking for the
    // former on a counter". Two were the permit type's until this audit.
    expect(
      permitFormFor(CanonicalPermitType.excavationPermit)!.title,
      'Excavation and Ground Preparation Permit',
    );
    expect(
      permitFormFor(CanonicalPermitType.sanitaryPermit)!.title,
      'Sanitary Permit',
    );
    expect(
      permitFormFor(CanonicalPermitType.buildingPermitNewConstruction)!.title,
      'Unified Application Form for Building Permit',
    );
  });
}
