import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:ebpco_user_app/core/drafts/fencing_permit_draft_codec.dart';
import 'package:ebpco_user_app/core/drafts/form_payload.dart';
import 'package:ebpco_user_app/core/models/document_model.dart';
import 'package:ebpco_user_app/core/models/fencing_permit_model.dart';
import 'package:ebpco_user_app/core/services/document_storage_service.dart';

/// The attachments a filing carries.
///
/// **Until 31 August 2026 it carried none.** `submitPermitApplication`
/// hardcoded `documents: const []`, so `ApplicationsProvider._uploadAll` had
/// nothing to upload, `documentIds` went out empty, and the Office of the
/// Building Official received applications with **no documents** — no land
/// title, no survey plan, no design plans, no clearances. On a building permit
/// that is twenty-four attachments the citizen watched themselves add.
///
/// Nothing told them. The wizard showed each attachment in place, the review
/// step listed them, and the confirmation screen said the application was
/// filed. It is the same shape as `form`, found the same way — by asking what
/// the request body actually contains rather than what the screens imply.

void main() {
  setUp(() => DocumentStorageService.setRootForTesting('/tmp/ebpco-doc-test'));
  tearDown(() => DocumentStorageService.setRootForTesting(null));

  DocumentModel doc(String id, String name) => DocumentModel(
    id: id,
    label: name,
    fileName: '$name.pdf',
    filePath: '/tmp/ebpco-doc-test/$id.pdf',
    uploadedAt: DateTime(2026, 8, 31),
  );

  test('every attachment the wizard holds is collected', () {
    final draft = FencingPermitDraft();
    draft.constructionLocation.landTitleOrTaxDeclarationUpload = doc(
      'd1',
      'land-title',
    );
    draft.constructionLocation.barangayClearanceUpload = doc(
      'd2',
      'barangay-clearance',
    );

    final documents = permitDocuments(const FencingPermitDraftCodec(), draft);

    expect(documents.map((d) => d.id), containsAll(['d1', 'd2']));
  });

  test('an empty wizard carries none, rather than a null', () {
    expect(
      permitDocuments(const FencingPermitDraftCodec(), FencingPermitDraft()),
      isEmpty,
    );
  });

  test('it uses the same codec walk the drafts use', () {
    // Not a second list of document fields. The codecs already visit every
    // one — that is how a draft persists an attachment — and that walk is
    // round-trip tested for all nineteen wizards. A parallel list would
    // drift, and the drift would be invisible: a filing missing one document.
    final source = File('lib/core/drafts/form_payload.dart').readAsStringSync();
    expect(source, contains('codec.capture(draft, writer)'));
    expect(source, contains('writer.documents'));
  });

  test('and every wizard passes them to the submission', () {
    // The defect was one hardcoded `const []` in a shared helper, so it hid
    // in one line and applied to all nineteen. This asserts the wiring rather
    // than the mechanism, because the mechanism was never the problem.
    final wizards = Directory('lib/features/applications/presentation')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        .where((f) => !f.path.endsWith('submit_permit_application.dart'))
        .where((f) => f.readAsStringSync().contains('submitPermitApplication('))
        .toList();

    expect(wizards, hasLength(19), reason: 'nineteen wizards file');
    final without = wizards
        .where((f) => !f.readAsStringSync().contains('permitDocuments('))
        .map((f) => f.path)
        .toList();
    expect(
      without,
      isEmpty,
      reason: 'these file without sending the citizen\'s attachments: $without',
    );
  });

  test('the helper no longer hardcodes an empty list', () {
    expect(
      File(
        'lib/features/applications/presentation/widgets/'
        'submit_permit_application.dart',
      ).readAsStringSync(),
      isNot(contains('documents: const [],')),
      reason: 'the line that silently dropped every attachment is back',
    );
  });
}
