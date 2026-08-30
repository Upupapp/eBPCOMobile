import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ebpco_user_app/shared/widgets/layout/reattach_notice.dart';

/// The explanation for an empty slot, on the screen where the slot is.
///
/// The Drafts row has named the missing files since M-48. But that is where
/// the applicant CHOSE the draft, not where they fill it in: resume into step
/// 7 and the slots are empty on a step they remember finishing, with nothing
/// on that screen saying why.

Widget _wrap(Widget child) => MaterialApp(
  home: Scaffold(body: SingleChildScrollView(child: child)),
);

void main() {
  testWidgets('nothing missing shows nothing at all', (tester) async {
    // The common case by far, now that attachments persist. A banner that
    // renders empty chrome on every resume would be worse than none.
    await tester.pumpWidget(
      _wrap(ReattachNotice(documents: const [], onDismiss: () {})),
    );
    expect(find.byType(IconButton), findsNothing);
    expect(find.textContaining('attach'), findsNothing);
  });

  testWidgets('one file reads as one file', (tester) async {
    await tester.pumpWidget(
      _wrap(ReattachNotice(documents: const ['Land Title'], onDismiss: () {})),
    );
    expect(find.text('One file was not kept with this draft'), findsOneWidget);
    expect(find.text('Please attach it again: Land Title.'), findsOneWidget);
  });

  testWidgets('several are counted and named', (tester) async {
    // Named, not counted only: "3 files are missing" sends an applicant back
    // through nine steps to work out which.
    await tester.pumpWidget(
      _wrap(
        ReattachNotice(
          documents: const ['Land Title', 'Plans', 'Barangay Clearance'],
          onDismiss: () {},
        ),
      ),
    );
    expect(find.text('3 files were not kept with this draft'), findsOneWidget);
    expect(
      find.text(
        'Please attach them again: Land Title, Plans, Barangay Clearance.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('it can be dismissed', (tester) async {
    // An explanation, not an error. A banner that cannot be closed becomes
    // furniture the eye stops reading.
    var dismissed = false;
    await tester.pumpWidget(
      _wrap(
        ReattachNotice(
          documents: const ['Land Title'],
          onDismiss: () => dismissed = true,
        ),
      ),
    );
    await tester.tap(find.byIcon(Icons.close));
    expect(dismissed, isTrue);
  });

  testWidgets('twenty-four names at 200% text scale do not overflow', (
    tester,
  ) async {
    // The notice sits in the same Column as WizardProgressHeader, above an
    // Expanded(PageView) — and that header's own comment records that an
    // unbounded widget there consumed the whole viewport at 200% scale and
    // left the applicant unable to reach the fields.
    //
    // A Building Permit carries twenty-four attachments, so this is the worst
    // case rather than a contrived one.
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(2)),
        child: MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                ReattachNotice(
                  documents: List.generate(24, (i) => 'Document number $i'),
                  onDismiss: () {},
                ),
                const Expanded(child: SizedBox()),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);

    // And the count is still legible after the names are truncated — it is
    // the part that tells an applicant whether they are missing one file or
    // twenty.
    expect(find.text('24 files were not kept with this draft'), findsOneWidget);
  });

  test('every wizard shows it', () {
    // Nineteen screens. One that does not is a wizard where the applicant
    // meets an empty slot with no explanation — which is the whole defect.
    final screens = Directory('lib/features/applications/presentation')
        .listSync()
        .whereType<Directory>()
        .expand((d) => d.listSync().whereType<File>())
        .where((f) => f.path.endsWith('_wizard_screen.dart'))
        .toList();
    expect(screens, hasLength(19));

    final without = [
      for (final screen in screens)
        if (!screen.readAsStringSync().contains('ReattachNotice('))
          screen.path.split('/').last,
    ];
    expect(without, isEmpty);
  });

  test('and each one dismisses through its own provider', () {
    // Reading one provider and dismissing on another would leave the notice
    // on screen for ever, which is exactly the sort of thing nineteen
    // near-identical edits produce.
    for (final screen
        in Directory('lib/features/applications/presentation')
            .listSync()
            .whereType<Directory>()
            .expand((d) => d.listSync().whereType<File>())
            .where((f) => f.path.endsWith('_wizard_screen.dart'))) {
      final source = screen.readAsStringSync();
      final watched = RegExp(
        r'\.watch<(\w+)>\(\)\s*\.documentsToReattach',
      ).firstMatch(source)?.group(1);
      final dismissed = RegExp(
        r'\.read<(\w+)>\(\)\s*\.acknowledgeDetachedDocuments',
      ).firstMatch(source)?.group(1);
      expect(
        watched,
        isNotNull,
        reason: '${screen.path} does not read documentsToReattach',
      );
      expect(dismissed, watched, reason: screen.path);
    }
  });
}
