import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ebpco_user_app/core/models/building_permit_model.dart';
import 'package:ebpco_user_app/core/models/document_model.dart';
import 'package:ebpco_user_app/core/theme/app_theme.dart';
import 'package:ebpco_user_app/features/applications/presentation/building_permit/steps/step5_professional_in_charge.dart';
import 'package:ebpco_user_app/features/documents/presentation/widgets/attach_document_sheet.dart';
import 'package:ebpco_user_app/shared/widgets/uploads/document_upload_tile.dart';

/// Every upload slot in every wizard does the same thing: await the document
/// chooser, then `setState` with what came back. Thirty-nine of them did it
/// without checking `mounted` first.
///
/// That is not theoretical. The chooser leads to the camera, the gallery, or
/// the system file picker — all of which are separate Android activities, and
/// the one underneath can be torn down while they are open. When the picker
/// then returns, `setState` runs against a defunct State and Flutter throws
/// "setState() called after dispose()".
///
/// This reproduces it with one representative slot: open the picker, unmount
/// the step, then let the picker return.
void main() {
  testWidgets('a picker returning after its step is gone does not throw', (
    tester,
  ) async {
    final picker = Completer<DocumentModel?>();
    debugAttachDocumentOverride = (context, {required String label}) =>
        picker.future;
    addTearDown(() => debugAttachDocumentOverride = null);

    var stepIsMounted = true;
    late StateSetter setOuter;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              setOuter = setState;
              return stepIsMounted
                  ? Step5ProfessionalInCharge(
                      formKey: GlobalKey<FormState>(),
                      draft: BuildingPermitDraft(),
                      onChanged: () {},
                    )
                  : const SizedBox();
            },
          ),
        ),
      ),
    );
    await tester.pump();

    // The applicant taps Upload; the chooser opens and stays open.
    final upload = find.descendant(
      of: find.byType(DocumentUploadTile).first,
      matching: find.text('Upload'),
    );
    await tester.ensureVisible(upload);
    await tester.tap(upload);
    await tester.pump();

    // The step goes away underneath it.
    setOuter(() => stepIsMounted = false);
    await tester.pump();
    expect(find.byType(Step5ProfessionalInCharge), findsNothing);

    // And only now does the picker come back with a document.
    picker.complete(
      DocumentModel(
        id: 'doc-1',
        label: 'PRC ID',
        fileName: 'prc-id.pdf',
        uploadedAt: DateTime(2026, 8, 24),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(
      tester.takeException(),
      isNull,
      reason: 'the upload handler must check mounted before setState',
    );
  });
}
