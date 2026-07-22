import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ebpco_user_app/core/models/building_permit_model.dart';
import 'package:ebpco_user_app/features/applications/presentation/building_permit/steps/step6_professional.dart';

Widget _wrap(Widget child) {
  return MaterialApp(home: Scaffold(body: child));
}

void main() {
  testWidgets('completing a date selection does not crash', (tester) async {
    final draft = BuildingPermitDraft();
    final formKey = GlobalKey<FormState>();
    await tester.pumpWidget(
      _wrap(Step6Professional(formKey: formKey, draft: draft, onChanged: () {})),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Select a date').first);
    await tester.pumpAndSettle();
    print('EXC after opening date picker: ${tester.takeException()}');

    // Confirm with the dialog's OK button (completes a real date pick).
    final okButton = find.text('OK');
    expect(okButton, findsOneWidget);
    await tester.tap(okButton);
    await tester.pumpAndSettle();
    print('EXC after picking a date: ${tester.takeException()}');
    expect(tester.takeException(), isNull, reason: 'after picking a date');

    // Rebuild and verify the picked date rendered without throwing.
    await tester.pump();
    print('EXC after rebuild: ${tester.takeException()}');
    expect(tester.takeException(), isNull, reason: 'after rebuild with date set');
  });

  testWidgets('uploading and removing a document does not crash', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 3000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final draft = BuildingPermitDraft();
    final formKey = GlobalKey<FormState>();
    await tester.pumpWidget(
      _wrap(Step6Professional(formKey: formKey, draft: draft, onChanged: () {})),
    );
    await tester.pumpAndSettle();

    final uploadButtons = find.text('Upload');
    expect(uploadButtons, findsWidgets);
    await tester.tap(uploadButtons.first);
    await tester.pumpAndSettle();
    print('EXC after Upload tap: ${tester.takeException()}');
    expect(tester.takeException(), isNull, reason: 'after upload');

    final removeButtons = find.byIcon(Icons.close);
    expect(removeButtons, findsWidgets, reason: 'remove icon should appear after upload');
    await tester.tap(removeButtons.first);
    await tester.pumpAndSettle();
    print('EXC after remove tap: ${tester.takeException()}');
    expect(tester.takeException(), isNull, reason: 'after remove');
  });

  testWidgets('switching Architect <-> Civil Engineer repeatedly does not crash', (
    tester,
  ) async {
    final draft = BuildingPermitDraft();
    final formKey = GlobalKey<FormState>();
    await tester.pumpWidget(
      _wrap(Step6Professional(formKey: formKey, draft: draft, onChanged: () {})),
    );
    await tester.pumpAndSettle();

    for (var i = 0; i < 3; i++) {
      await tester.tap(find.text('Profession'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Civil Engineer').last);
      await tester.pumpAndSettle();
      print('EXC after selecting Civil Engineer (iter $i): ${tester.takeException()}');

      await tester.tap(find.text('Profession'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Architect').last);
      await tester.pumpAndSettle();
      print('EXC after selecting Architect (iter $i): ${tester.takeException()}');
    }
    expect(tester.takeException(), isNull, reason: 'after repeated profession switches');
  });
}
