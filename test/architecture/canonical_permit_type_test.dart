import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// A wizard must file the permit type the admin recognises, not a name chosen
/// for the screen.
///
/// When the wizards were first wired to record submissions they each passed a
/// hand-written label, and five of the sixteen were wrong against the admin's
/// list: "Building Permit" for what the admin calls "Building Permit – New
/// Construction", "Excavation & Ground Preparation Permit" for "Excavation
/// Permit", "Sanitary / Plumbing Permit" for "Sanitary Permit", and two that
/// used an em dash (—) where the admin uses an en dash (–).
///
/// None of that would fail anything. The application files, the confirmation
/// screen renders, and the value only becomes wrong when it reaches a portal
/// that validates it — by which time it is an applicant's filing.
void main() {
  test('every wizard files a canonical permit type', () {
    final offenders = <String>[];

    for (final file
        in Directory('lib/features/applications/presentation')
            .listSync(recursive: true)
            .whereType<File>()
            .where((f) => f.path.endsWith('_wizard_screen.dart'))) {
      final source = file.readAsStringSync();
      final match = RegExp(r"permitTypeLabel:\s*([^,\n]+)").firstMatch(source);
      if (match == null) continue;

      final value = match.group(1)!.trim();
      if (value.startsWith('CanonicalPermitType.')) continue;
      offenders.add('${file.path}  ->  $value');
    }

    expect(
      offenders,
      isEmpty,
      reason:
          'Pass CanonicalPermitType.<type>.wire, not a literal. The admin '
          'validates this string and rejects anything not on its list. Found '
          'at:\n  ${offenders.join('\n  ')}',
    );
  });
}
