import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:ebpco_user_app/core/contract/admin_vocabulary.dart';
import 'package:ebpco_user_app/core/contract/permit_forms.dart';
import 'package:ebpco_user_app/core/contract/requirements_catalog.dart';

/// The blank forms the app ships, and the two disagreeing opinions it holds
/// about them.
///
/// M-10 asks the LGU for the DPWH/JMC unified forms *"so wizard fields can be
/// audited field-for-field"*. Auditing that register turned up something worth
/// knowing before anyone asks the LGU for anything: **for ten permits the
/// app already ships a form it labels as Castilla's own, while the
/// requirements catalogue records that permit's requirements as built from a
/// national baseline rather than from a Castilla form.**
///
/// Two provenance judgements about the same nineteen permits, made in two
/// files, disagreeing. Either the catalogue is behind the forms — in which
/// case ten wizards can be audited today, against paper already on disk — or
/// the form flag is optimistic. Both are worth knowing and neither is mine to
/// settle.
///
/// **The sharpest case is a three-way one.** New Construction, Renovation /
/// Alteration and Addition / Extension share ONE physical form, because
/// Castilla's Unified Application Form covers all three through its own Scope
/// of Work checkboxes. The catalogue records the first as built from a
/// Castilla form and the other two as not. Same paper, three permits, two
/// verdicts — which cannot all be right.
///
/// **What this test cannot do**, said plainly because the flag it pins is a
/// human judgement: it cannot read a scanned PDF. Of the thirteen forms
/// flagged as genuine Castilla documents, exactly **two** — Fencing and
/// Sanitary/Plumbing — carry the words CASTILLA and SORSOGON in text this
/// repository's tools can extract. For the other eleven the absence of those
/// words is not evidence of anything: the pages are images. So this pins the
/// flags rather than verifying them, and says so.

void main() {
  test('every declared form is on disk and readable', () {
    // The failure this catches is a form dropped from the bundle while its
    // entry stays: the screen would then offer an applicant a document that
    // does not exist, offline, which is exactly when they cannot go and look.
    final missing = <String>[];
    var checked = 0;
    for (final type in CanonicalPermitType.values) {
      final form = permitFormFor(type);
      if (form == null) continue;
      checked++;
      final file = File(form.assetPath);
      if (!file.existsSync() || file.lengthSync() == 0) {
        missing.add('${type.name} → ${form.assetPath}');
      }
    }
    expect(checked, 19, reason: 'every permit type should offer a form');
    expect(missing, isEmpty);
  });

  test('the eighteen files are all reachable, and none is orphaned', () {
    final declared = {
      for (final type in CanonicalPermitType.values) ...[
        ?permitFormFor(type)?.assetPath,
        ?permitChecklistFor(type)?.assetPath,
      ],
    };
    // Seventeen application forms plus the OBO's documentary checklist.
    // Seventeen and not nineteen because three building sub-types share one
    // physical form — Castilla's Unified Application Form covers all three
    // through its own Scope of Work checkboxes.
    expect(declared, hasLength(18));

    final onDisk = Directory('assets/permits')
        .listSync()
        .whereType<File>()
        .map((f) => f.path)
        .where((p) => p.endsWith('.pdf'))
        .toSet();
    expect(
      onDisk.difference(declared),
      isEmpty,
      reason:
          'a PDF is shipped in the bundle and reachable from no screen — '
          'weight in the download for nothing',
    );
  });

  test('the assets are registered, or none of the above ships', () {
    // A file on disk that pubspec does not declare is not in the app.
    expect(
      File('pubspec.yaml').readAsStringSync(),
      contains('assets/permits/'),
    );
  });

  test('a stand-in form is labelled as one on the screen', () {
    // permit_forms.dart states the requirement in prose — "the screen is
    // required to label a reference template as one: presenting a stand-in as
    // an LGU document invites an applicant to take it to the counter". This
    // is the part of that sentence a test can hold.
    final screen = File(
      'lib/features/documents/presentation/official_form_screen.dart',
    ).readAsStringSync();
    expect(screen, contains('if (!form.isOfficialCastillaForm)'));
    expect(screen, contains('_ReferenceOnlyNotice'));
  });

  group('the two provenance judgements', () {
    /// Permits whose bundled form is flagged as Castilla's own while their
    /// requirements are recorded as NOT built from a Castilla form.
    ///
    /// Named rather than counted, so resolving one of them fails this test and
    /// says which — and so adding a ninth does too.
    const disagreeing = {
      // The two building sub-types that share New Construction's form and are
      // recorded as unverified while it is recorded as verified.
      'buildingPermitRenovationAlteration',
      'buildingPermitAdditionExtension',
      'civilStructuralPermit',
      'electricalPermit',
      'electronicsPermit',
      'mechanicalPermit',
      'plumbingPermit',
      'sanitaryPermit',
      'fencingPermit',
      'excavationPermit',
    };

    test('the counts are what they were measured to be', () {
      final genuineForms = CanonicalPermitType.values
          .where((t) => permitFormFor(t)?.isOfficialCastillaForm ?? false)
          .length;
      final verifiedRequirements = CanonicalPermitType.values
          .where((t) => requirementsForLabel(t.wire)?.verified ?? false)
          .length;
      expect(genuineForms, 14, reason: 'forms flagged as Castilla documents');
      expect(
        CanonicalPermitType.values
            .where((t) => permitFormFor(t) != null)
            .length,
        19,
        reason: 'every permit type offers a form',
      );
      expect(
        verifiedRequirements,
        4,
        reason:
            'requirement sets built from a Castilla or BFP form. If this rose, '
            'somebody did the audit — say which permits and against what',
      );
    });

    test('and they disagree about exactly these ten', () {
      final found = <String>{};
      for (final type in CanonicalPermitType.values) {
        final formIsCastilla =
            permitFormFor(type)?.isOfficialCastillaForm ?? false;
        final requirementsFromCastilla =
            requirementsForLabel(type.wire)?.verified ?? false;
        if (formIsCastilla && !requirementsFromCastilla) found.add(type.name);
      }
      expect(
        found,
        disagreeing,
        reason:
            'the disagreement moved. A permit that LEFT this set was audited '
            'against the bundled form — good, and M-10 shrinks by one. A '
            "permit that JOINED it has a form flagged as Castilla's while its "
            'requirements were not built from that form',
      );
    });
  });
}
