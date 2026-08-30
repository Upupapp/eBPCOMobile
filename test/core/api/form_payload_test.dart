import 'package:flutter_test/flutter_test.dart';

import 'package:ebpco_user_app/core/drafts/fencing_permit_draft_codec.dart';
import 'package:ebpco_user_app/core/drafts/form_payload.dart';
import 'package:ebpco_user_app/core/models/document_model.dart';
import 'package:ebpco_user_app/core/models/fencing_permit_model.dart';
import 'package:ebpco_user_app/core/services/document_storage_service.dart';

/// What a filing actually carries to the Office of the Building Official.
///
/// Until 31 August 2026 the answer was: the permit type, the action, the
/// applicant's name, the site line and the uploaded document ids. **Nothing
/// the applicant typed.** Nine or ten steps of owner details, lot data, scope
/// of work, professionals and supervisors were collected, validated, shown
/// back on a review step, saved to the keychain — and then not sent.
///
/// The contract has declared `form` since it was written. M-47 filed it as
/// blocked on M-10, the DPWH/JMC unified forms; that premise died when the
/// wizards were audited field-for-field against Castilla's OWN forms on 31
/// August, which is a better source than the national templates.

void main() {
  setUp(() => DocumentStorageService.setRootForTesting('/tmp/ebpco-test-docs'));
  tearDown(() => DocumentStorageService.setRootForTesting(null));

  FencingPermitDraft filled() {
    final draft = FencingPermitDraft();
    draft.applicant.firstName = 'Maria';
    draft.applicant.lastName = 'Dela Cruz';
    draft.constructionLocation.lotNumber = '12';
    draft.constructionLocation.barangay = 'Bagumbayan';
    return draft;
  }

  test('the payload carries what the applicant typed', () {
    final form = permitFormPayload(const FencingPermitDraftCodec(), filled());

    expect(form['applicant.firstName'], 'Maria');
    expect(form['applicant.lastName'], 'Dela Cruz');
    expect(form['constructionLocation.lotNumber'], '12');
    expect(form['constructionLocation.barangay'], 'Bagumbayan');
    expect(
      form.length,
      greaterThan(30),
      reason:
          'the fencing wizard collects far more than four fields. A payload '
          'this small means the codec was not asked for everything',
    );
  });

  test('and it is the codec that decides, not a second field list', () {
    // The keys are the draft snapshot's keys on purpose. A parallel
    // serialisation of nineteen wizards would drift from the one that is
    // round-trip tested; this one cannot.
    final snapshot = const FencingPermitDraftCodec().snapshot(
      filled(),
      step: 0,
    );
    final form = permitFormPayload(const FencingPermitDraftCodec(), filled());
    expect(form.keys.toSet().difference(snapshot.fields.keys.toSet()), isEmpty);
  });

  test('attachments are excluded — documentIds carries those', () {
    // The snapshot records an attachment as a map holding `storedName`: the
    // file's name inside THIS DEVICE's app container. It means nothing to a
    // server, and it is not what carries a document to the office.
    final draft = filled();
    draft.constructionLocation.landTitleOrTaxDeclarationUpload = DocumentModel(
      id: 'doc-1',
      label: 'Land Title',
      fileName: 'land-title.pdf',
      filePath: '/tmp/ebpco-test-docs/doc_1.pdf',
      uploadedAt: DateTime(2026, 9, 1),
    );

    final form = permitFormPayload(const FencingPermitDraftCodec(), draft);
    final withStoredName = form.values.whereType<Map>().where(
      (v) => v.containsKey('storedName'),
    );
    expect(withStoredName, isEmpty);
    expect(
      form.values.any((v) => v.toString().contains('/tmp/ebpco-test-docs')),
      isFalse,
      reason: 'a local device path must never leave the device',
    );
  });

  test('an empty wizard sends empty values, not a missing payload', () {
    // `{}` from a blank draft would be wrong in the other direction, but a
    // draft the applicant has half filled must send the half they filled.
    final form = permitFormPayload(
      const FencingPermitDraftCodec(),
      FencingPermitDraft(),
    );
    expect(form, isNotEmpty);
    expect(form['applicant.firstName'], anyOf(isNull, ''));
  });
}
