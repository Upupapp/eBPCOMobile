import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:ebpco_user_app/core/models/fencing_permit_model.dart';
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
