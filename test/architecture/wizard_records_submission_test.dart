import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Every permit wizard must record its submission as a real application.
///
/// For the whole life of this codebase, none of them did. `_handleSubmit`
/// called the wizard's own provider — which only flips that draft's status —
/// then invented a reference number and navigated to a confirmation screen.
/// `ApplicationsProvider`, the one thing the applications list reads, was
/// never told. The applicant submitted, read a number, and found their list
/// as empty as before.
///
/// Nothing failed while that was true, which is the point: there was no error
/// to catch, only an absence. One wizard is covered end-to-end
/// (`fencing_permit_wizard_test`), and driving all sixteen through nine steps
/// each would cost far more than it returns. This asserts the cheap half for
/// the other fifteen — that the call is still there at all.
void main() {
  test('every wizard records its submission', () {
    final offenders = <String>[];

    for (final file in Directory('lib/features/applications/presentation')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('_wizard_screen.dart'))) {
      final source = file.readAsStringSync();
      if (!source.contains('_handleSubmit')) continue;
      if (source.contains('submitPermitApplication(')) continue;
      offenders.add(file.path);
    }

    expect(
      offenders,
      isEmpty,
      reason:
          'A wizard that does not call submitPermitApplication files nothing: '
          'the applicant gets a reference number for an application that does '
          'not exist. Found at:\n  ${offenders.join('\n  ')}',
    );
  });
}
