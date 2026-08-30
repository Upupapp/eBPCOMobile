import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:ebpco_user_app/core/contract/admin_vocabulary.dart';
import 'package:ebpco_user_app/core/contract/lgu_source_notice.dart';
import 'package:ebpco_user_app/core/models/electrical_permit_model.dart';
import 'package:ebpco_user_app/core/models/fencing_permit_model.dart';
import 'package:ebpco_user_app/core/models/interior_design_permit_model.dart';
import 'package:ebpco_user_app/core/models/mechanical_permit_model.dart';
import 'package:ebpco_user_app/core/models/plumbing_permit_model.dart';

/// What the app tells an applicant their permit requires.
///
/// `permitConditions` is rendered on the Evaluation & Permit Status step in
/// twelve wizards, so it reads as the conditions the office attaches. Box 8 of
/// each NBC form prints the real ones — and page two, where Box 8 lives, was
/// unread until 31 August 2026 because `qlmanage` renders only the first page
/// and nobody had looked for another renderer.
///
/// **Getting these wrong is not a wording problem.** An applicant who never
/// hears about the ten-day notice to their neighbour does not give it.

void main() {
  group('Fencing — NBC Form B-03, Box 8', () {
    test('the obligations the form puts on the applicant are all there', () {
      const conditions = FencingProcessingInfo.permitConditions;
      final joined = conditions.join(' ');

      // Each of these was absent from the paraphrase that stood here.
      expect(joined, contains('relocation survey'));
      expect(joined, contains('ten (10) days'));
      expect(joined, contains('adjoining'));
      expect(joined, contains('logbook'));
      expect(joined, contains('Article 1723'));
      expect(joined, contains('full-time'));
    });

    test('and the one the form does not print is gone', () {
      expect(
        FencingProcessingInfo.permitConditions.join(' '),
        isNot(contains('must be authentic')),
        reason:
            'not a condition on the permit. Inventing one is the same defect '
            'as omitting a real one, in the other direction',
      );
    });

    test('the ten-day notice says what to do, not just that it exists', () {
      // "Notify the adjoining owner" without "and show how their building
      // will be protected" is half the obligation.
      final notice = FencingProcessingInfo.permitConditions.singleWhere(
        (c) => c.contains('ten (10) days'),
      );
      expect(notice, contains('in writing'));
      expect(notice, contains('protected'));
    });
  });

  group('Plumbing — NBC Form A-06, Box 8', () {
    test('the Notice of Construction is unconditional, as the form is', () {
      // The form: "prior to any commencement of plumbing works, a duly
      // accomplished prescribed Notice of Construction SHALL be submitted".
      // The app said "when required", which is a softening nobody had the
      // authority for.
      final notice = PlumbingEvaluationPermitStatus.permitConditions
          .singleWhere((c) => c.contains('Notice of Construction'));
      expect(notice, isNot(contains('when required')));
      expect(notice, contains('Before any plumbing work begins'));
      expect(notice, contains('Office of the Building Official'));
    });

    test('the rest of Box 8 is still represented', () {
      final joined = PlumbingEvaluationPermitStatus.permitConditions.join(' ');
      expect(joined, contains('approved plumbing plans'));
      expect(joined, contains('Master Plumber'));
      expect(joined, contains('as-built'));
      expect(joined, contains('without the related Building Permit'));
    });
  });

  group('Mechanical — NBC Form A-04, Box 9', () {
    test('the Notice of Construction is unconditional here too', () {
      final notice = MechanicalEvaluationPermitStatus.permitConditions
          .singleWhere((c) => c.contains('Notice of Construction'));
      expect(notice, isNot(contains('when required')));
      expect(notice, contains('Before any mechanical installation'));
      expect(notice, contains('Office of the Building Official'));
    });
  });

  group('Electrical — NBC Form A-03, Box 8', () {
    test('the Notice of Construction names who must submit it', () {
      // The form is specific where the app was not: "the Owner/Permittee
      // shall submit". An applicant reading "a Notice of Construction must be
      // submitted" can reasonably assume their engineer handles it.
      final notice = ElectricalEvaluationPermitStatus.permitConditions
          .singleWhere((c) => c.contains('Notice of Construction'));
      expect(notice, isNot(contains('when required')));
      expect(notice, contains('owner or permittee'));
    });

    test('the PCAB threshold is stated, not called "qualifying"', () {
      // 200 amperes at 230 volts is the whole content of that condition: it
      // is how an applicant works out whether it binds them. "Qualifying
      // installations" told them there is a rule and not what it is.
      final pcab = ElectricalEvaluationPermitStatus.permitConditions
          .singleWhere((c) => c.contains('PCAB'));
      expect(pcab, contains('200 amperes'));
      expect(pcab, contains('230 volts'));
      expect(pcab, isNot(contains('qualifying')));
    });
  });

  group('Interior Design — a REFERENCE form, and treated as one', () {
    test('the national obligations are stated', () {
      final joined = InteriorProcessingInfo.permitConditions.join(' ');
      expect(joined, contains('Article 1723'));
      expect(joined, contains('R.A. 8534'));
      expect(joined, contains('Certificate of Completion'));
      expect(joined, contains('logbook'));
    });

    test('and the invented one is gone here too', () {
      expect(
        InteriorProcessingInfo.permitConditions.join(' '),
        isNot(contains('must be authentic')),
        reason:
            'the same phantom condition removed from fencing. It appears on '
            'no form, and it is a rule about the applicant rather than one '
            'about the permit',
      );
    });

    test('the three reference-form wizards do not claim these will apply', () {
      // The interior design form's signature block names another
      // municipality's Municipal Engineer and two of its Processing and
      // Evaluation Division staff. Its Box 10 is that LGU's, not Castilla's,
      // so the screen may not say "these conditions will apply once the
      // permit is issued" the way the wizards with a real Castilla form do.
      for (final wizard in ['architectural', 'demolition', 'interior_design']) {
        final source = File(
          'lib/features/applications/presentation/${wizard}_permit/steps/'
          'step9_evaluation_status.dart',
        ).readAsStringSync();
        expect(
          source,
          contains('LguSourceNotice.conditionsFromReferenceForm'),
          reason: '$wizard ships a reference form and must say so',
        );
        expect(
          source,
          isNot(contains('will apply once the permit is issued')),
          reason: '$wizard cannot promise conditions no Castilla form carries',
        );
      }
    });

    test('and that set is exactly the forms flagged as not Castilla\'s', () {
      // Delegates rather than holding a second opinion: if the LGU publishes
      // its own architectural form and the flag flips, this fails and the
      // caveat above comes off that screen.
      const shown = {
        CanonicalPermitType.architecturalPermit,
        CanonicalPermitType.civilStructuralPermit,
        CanonicalPermitType.demolitionPermit,
        CanonicalPermitType.electricalPermit,
        CanonicalPermitType.electronicsPermit,
        CanonicalPermitType.interiorDesignPermit,
        CanonicalPermitType.mechanicalPermit,
        CanonicalPermitType.plumbingPermit,
        CanonicalPermitType.sanitaryPermit,
      };
      final reference = shown
          .where((t) => !LguSourceNotice.isFormCastillasOwn(t))
          .toSet();
      expect(reference, {
        CanonicalPermitType.architecturalPermit,
        CanonicalPermitType.demolitionPermit,
        CanonicalPermitType.interiorDesignPermit,
      });
    });
  });

  test('these are shown to the applicant, which is why they matter', () {
    // A list nobody renders would be a documentation problem. This one is on
    // the step that tells an applicant where their application stands.
    final step = File(
      'lib/features/applications/presentation/fencing_permit/steps/'
      'step9_review_submission.dart',
    );
    final rendered = Directory('lib/features/applications/presentation')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.readAsStringSync().contains('permitConditions'))
        .length;
    expect(
      rendered,
      9,
      reason:
          'permitConditions is rendered by nine wizard steps. If that fell, '
          'these lists stopped reaching the applicants they are written for; '
          'if it rose, a tenth wizard now shows conditions that should be '
          'checked against its own form',
    );
    expect(step.existsSync(), isTrue);
  });
}
