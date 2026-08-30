import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:ebpco_user_app/core/contract/admin_vocabulary.dart';
import 'package:ebpco_user_app/core/contract/lgu_source_notice.dart';
import 'package:ebpco_user_app/core/models/civil_structural_permit_model.dart';
import 'package:ebpco_user_app/core/models/electrical_permit_model.dart';
import 'package:ebpco_user_app/core/models/electronics_permit_model.dart';
import 'package:ebpco_user_app/core/models/excavation_permit_model.dart';
import 'package:ebpco_user_app/core/models/fencing_permit_model.dart';
import 'package:ebpco_user_app/core/models/interior_design_permit_model.dart';
import 'package:ebpco_user_app/core/models/mechanical_permit_model.dart';
import 'package:ebpco_user_app/core/models/plumbing_permit_model.dart';
import 'package:ebpco_user_app/core/models/sanitary_plumbing_permit_model.dart';

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

  group('Civil/Structural — NBC Form A-02, Box 8', () {
    test('Article 1723 is stated in full, both halves of it', () {
      // What stood here was "The Engineer responsible for the plans and
      // specifications remains professionally accountable" — no period, no
      // consequence, and only one of the two professionals the article binds.
      final joined = CivilStructuralEvaluationPermitStatus.permitConditions
          .join(' ');
      expect(joined, contains('Article 1723'));
      expect(joined, contains('fifteen years'));
      expect(
        joined,
        contains('solidarily liable'),
        reason:
            'the supervising engineer is solidarily liable with the '
            'contractor. That half was missing entirely, and it is the half '
            'that binds the professional an applicant actually hires',
      );
      expect(joined, isNot(contains('remains professionally accountable')));
    });

    test('the Notice of Construction covers any construction activity', () {
      final notice = CivilStructuralEvaluationPermitStatus.permitConditions
          .singleWhere((c) => c.contains('Notice of Construction'));
      expect(notice, contains('Before any construction activity'));
    });
  });

  group(
    'The two patterns, swept across every wizard that shows conditions',
    () {
      // Per-wizard assertions catch what has been read. These catch the next
      // one: a list added or edited later cannot reintroduce either defect
      // without failing here.

      /// Every `permitConditions` list in the models, by file.
      Map<String, String> conditionLists() {
        final found = <String, String>{};
        for (final entity in Directory('lib/core/models').listSync()) {
          if (entity is! File || !entity.path.endsWith('.dart')) continue;
          final source = entity.readAsStringSync();
          final start = source.indexOf('permitConditions = [');
          if (start < 0) continue;
          final end = source.indexOf('];', start);
          found[entity.uri.pathSegments.last] = source.substring(start, end);
        }
        return found;
      }

      test('the scan finds all twelve lists', () {
        expect(
          conditionLists().length,
          12,
          reason:
              'the two sweeps below are only worth as much as what they read. '
              'If this fell, a model moved or its declaration was reformatted '
              'and the sweeps are passing against nothing',
        );
      });

      test('no list softens an obligation to "when required"', () {
        // Six forms print the Notice of Construction as an unconditional
        // "shall". Every one of the six wizards said "when required" until it
        // was read.
        final offenders = <String>[];
        conditionLists().forEach((file, list) {
          if (list.contains('when required')) offenders.add(file);
        });
        expect(
          offenders,
          isEmpty,
          reason:
              'these make an obligation conditional: $offenders. No form read '
              'so far prints one that way, and the applicant is the party who '
              'bears the stop-work order',
        );
      });

      test('no list invents a condition about the applicant\'s honesty', () {
        final offenders = <String>[];
        conditionLists().forEach((file, list) {
          if (list.contains('must be authentic')) offenders.add(file);
        });
        expect(offenders, isEmpty, reason: 'on no form: $offenders');
      });

      test('each permit names the code that governs it', () {
        // "Applicable codes" tells a professional there is a code. Which one is
        // the part they need, and each form prints a different statute.
        const governing = {
          'National Structural Code':
              CivilStructuralEvaluationPermitStatus.permitConditions,
          'Philippine Interior Design Act':
              InteriorProcessingInfo.permitConditions,
          'Electronics Code': ElectronicsProcessingInfo.permitConditions,
          'Code on Sanitation': SanitaryEvaluationPermitStatus.permitConditions,
        };
        governing.forEach((code, conditions) {
          expect(
            conditions.join(' '),
            contains(code),
            reason: '$code is what the form names',
          );
        });
      });
    },
  );

  group('Excavation — NBC Form B-02, Box 7, and the money in it', () {
    test('the cash bond states the threshold, the amounts and the forfeit', () {
      // "Larger excavations may require a cash bond per the permit
      // conditions" is what stood here. Everything an owner needs to budget
      // for it — and the one thing they must not do — was absent.
      final joined = ExcavationProcessingInfo.permitConditions.join(' ');
      expect(joined, contains('fifty (50) cubic metres'));
      expect(joined, contains('two (2) metres deep'));
      expect(joined, contains('P50,000.00'));
      expect(joined, contains('P300.00'));
      expect(joined, contains('one hundred twenty (120) days'));
      expect(joined, contains('forfeited'));
      expect(joined, isNot(contains('may require a cash bond')));
    });

    test('the ten-day notice to the neighbour is here too', () {
      // The same obligation as the fencing permit's, and it was missing from
      // both until each form was read.
      final notice = ExcavationProcessingInfo.permitConditions.singleWhere(
        (c) => c.contains('ten (10) days'),
      );
      expect(notice, contains('in writing'));
      expect(notice, contains('protected'));
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
