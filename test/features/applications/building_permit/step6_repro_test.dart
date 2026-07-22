import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ebpco_user_app/core/models/building_permit_model.dart';
import 'package:ebpco_user_app/features/applications/presentation/building_permit/steps/step6_professional.dart';

void main() {
  testWidgets('Step6Professional builds without throwing', (tester) async {
    final draft = BuildingPermitDraft();
    final formKey = GlobalKey<FormState>();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Step6Professional(formKey: formKey, draft: draft, onChanged: () {}),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
