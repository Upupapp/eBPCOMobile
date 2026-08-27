import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Fifteen permit types each had their own terminal confirmation screen, and
/// they were copies: same success mark, same layout, same summary card, same
/// two buttons. The copying had already cost something — three headlines said
/// "… Permit Submitted!" where twelve said "… Application Submitted!", and
/// nothing in the code could have told you which was intended.
///
/// They now share `ApplicationSubmittedView`. This keeps the sixteenth permit
/// type from starting the cycle again, which is the failure mode this codebase
/// has repeated more than any other: the shared widget exists, and the next
/// author does not know it.
void main() {
  test('every submitted screen uses ApplicationSubmittedView', () {
    final offenders = <String>[];

    for (final file
        in Directory('lib/features/applications/presentation')
            .listSync(recursive: true)
            .whereType<File>()
            .where((f) => f.path.endsWith('submitted_screen.dart'))) {
      final source = file.readAsStringSync();
      if (source.contains('ApplicationSubmittedView')) continue;

      // The Building Permit screen is the deliberate exception: its summary is
      // a single centred tracking number rather than a card of labelled facts,
      // and folding it in would change how it looks.
      if (file.path.endsWith(
        'building_permit/application_submitted_screen.dart',
      )) {
        continue;
      }
      offenders.add(file.path);
    }

    expect(
      offenders,
      isEmpty,
      reason:
          'Build confirmation screens on ApplicationSubmittedView rather than '
          'copying one. Found at:\n  ${offenders.join('\n  ')}',
    );
  });
}
