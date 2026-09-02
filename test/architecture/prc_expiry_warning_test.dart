import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ebpco_user_app/features/applications/presentation/building_permit/widgets/date_picker_field.dart';

/// A licence date the app collects and never looks at.
///
/// Twenty-six places across the wizards ask for a professional's PRC validity
/// date. **Not one of them compared it to anything.** A licence that lapsed in
/// 2019 was accepted, filed, and returned by the office weeks later, with the
/// citizen paying for the delay — while the date sat on the screen in front of
/// them. `ProfessionalsProvider.professionalsNeedingAttention` says in its own
/// doc comment that it "drives the credential warning"; there was no credential
/// warning, and no widget read that getter either.
void main() {
  test('every PRC validity field warns when the licence has lapsed', () {
    // Keyed on the bound value, NOT the label. The first pass of this fix
    // matched on `label: 'PRC Validity *'` and silently skipped the Building
    // Permit — whose field is labelled 'PRC Validity Date *'. An allow-list
    // fails by forgetting, and the one it forgot was the most-used wizard.
    final offenders = <String>[];
    var fields = 0;

    for (final file
        in Directory('lib/features/applications/presentation')
            .listSync(recursive: true)
            .whereType<File>()
            .where((f) => f.path.endsWith('.dart'))) {
      final source = file.readAsStringSync();
      if (!source.contains('prcValidityDate')) continue;

      for (final match in RegExp(
        r'DatePickerField\((.*?)\n(\s+)\),',
        dotAll: true,
      ).allMatches(source)) {
        final block = match.group(1)!;
        if (!block.contains('prcValidityDate')) continue;
        fields++;
        if (!block.contains('warnIfPast')) {
          offenders.add(file.path);
        }
      }
    }

    expect(
      fields,
      greaterThanOrEqualTo(26),
      reason:
          'the scan found $fields PRC date fields; it read 26 when written, '
          'so a much smaller number means the pattern stopped matching and '
          'this gate is passing over nothing',
    );
    expect(
      offenders,
      isEmpty,
      reason:
          'these PRC validity fields accept an expired licence without a '
          'word. Pass warnIfPast: true',
    );
  });

  testWidgets('a lapsed licence is named on the field', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DatePickerField(
            label: 'PRC Validity *',
            value: DateTime(2019, 3, 14),
            warnIfPast: true,
            clock: () => DateTime(2026, 9, 2),
            onChanged: (_) {},
          ),
        ),
      ),
    );

    expect(
      find.textContaining('This licence expired on Mar 14, 2019'),
      findsOneWidget,
    );
    expect(
      find.textContaining('You can still file'),
      findsOneWidget,
      reason:
          'a warning, not a refusal: the office accepts a filing while a '
          'renewal is in progress, and this app has no business overruling it',
    );
  });

  testWidgets('a licence still valid says nothing', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DatePickerField(
            label: 'PRC Validity *',
            value: DateTime(2027, 3, 14),
            warnIfPast: true,
            clock: () => DateTime(2026, 9, 2),
            onChanged: (_) {},
          ),
        ),
      ),
    );

    expect(find.textContaining('expired'), findsNothing);
  });

  testWidgets('a date field that is not a licence never warns', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DatePickerField(
            label: 'Date of Birth',
            value: DateTime(1980, 1, 1),
            clock: () => DateTime(2026, 9, 2),
            onChanged: (_) {},
          ),
        ),
      ),
    );

    expect(find.textContaining('expired'), findsNothing);
  });
}
