import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:ebpco_user_app/core/drafts/fencing_permit_draft_codec.dart';
import 'package:ebpco_user_app/core/models/fencing_permit_model.dart';

/// Box 1 of the Fencing Permit form asks for a telephone number.
///
/// The wizard did not, and the model said why: *"per the official form's field
/// list for this permit, there is no contact number or province field (unlike
/// other ancillary permits' applicant sections)"*.
///
/// Reading the form — `NBC FORM NO. B–03`, Municipality of Castilla — settles
/// it. Box 1's address row is `ADDRESS NO. · STREET · BARANGAY ·
/// CITY/MUNICIPALITY · ZIP CODE · TELEPHONE NO.` There is no province, and
/// there IS a telephone number.
///
/// Fencing was the only one of the nineteen wizards without one. The comment
/// is why nobody questioned it, which is the point of this test: a wrong
/// comment justifying a real gap is harder to find than the gap.

void main() {
  test('the applicant can give a telephone number', () {
    final applicant = FencingApplicantInfo()..contactNumber = '(056) 555-0101';
    expect(applicant.contactNumber, '(056) 555-0101');
  });

  test('and the wizard step asks for it', () {
    // A field on the model that no step renders is a field the applicant
    // cannot fill, which is the same gap in a different place.
    final step = File(
      'lib/features/applications/presentation/fencing_permit/steps/'
      'step2_owner_applicant_info.dart',
    ).readAsStringSync();
    expect(step, contains('_applicant.contactNumber = v'));
    expect(step, contains("label: 'Telephone Number'"));
  });

  test('it survives a restart with the rest of the draft', () {
    const codec = FencingPermitDraftCodec();
    final draft = FencingPermitDraft()
      ..applicant.contactNumber = '(056) 555-0101';
    final restored = FencingPermitDraft();
    codec.apply(restored, codec.snapshot(draft, step: 1));
    expect(restored.applicant.contactNumber, '(056) 555-0101');
  });

  test('the comment that justified the gap is gone', () {
    // Kept as its own expectation because the sentence is the actual defect:
    // it is what stopped anyone looking at the form for eleven days.
    final model = File(
      'lib/core/models/fencing_permit_model.dart',
    ).readAsStringSync();
    expect(
      model,
      isNot(contains('there is no contact number\n/// or province field')),
    );
    expect(
      model,
      contains('TELEPHONE NO.'),
      reason: 'the corrected note should quote what the form actually says',
    );
  });

  test('Fencing is no longer the odd one out', () {
    // Nineteen wizards, and this was the only applicant section without a way
    // to reach the applicant.
    final without = <String>[];
    for (final entity in Directory('lib/core/models').listSync()) {
      if (entity is! File) continue;
      final name = entity.path.split('/').last;
      if (!name.endsWith('_permit_model.dart')) continue;
      final source = entity.readAsStringSync();
      // Excavation and the two BFP clearances model an applicant differently;
      // what is asserted is that no permit model dropped its contact field.
      if (!source.contains('contactNumber') &&
          !source.contains('telephone') &&
          !source.contains('mobileNumber')) {
        without.add(name);
      }
    }
    expect(
      without,
      isEmpty,
      reason:
          'these permit models collect no way to reach the applicant: '
          '$without. Check the form before concluding that is correct — the '
          'last time a model said the form had no such field, the form had one',
    );
  });
}
