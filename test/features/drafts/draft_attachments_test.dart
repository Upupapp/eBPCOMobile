import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:ebpco_user_app/core/drafts/building_permit_draft_codec.dart';
import 'package:ebpco_user_app/core/drafts/draft_persistence_barrel.dart';
import 'package:ebpco_user_app/core/models/building_permit_model.dart';
import 'package:ebpco_user_app/core/models/document_model.dart';
import 'package:ebpco_user_app/core/providers/building_permit_provider.dart';
import 'package:ebpco_user_app/core/services/document_storage_service.dart';

/// Attachments survive a restart — when their bytes are somewhere we can
/// vouch for, and never otherwise.
///
/// M-48 dropped every attachment, for a reason that was sound at the time: a
/// `DocumentModel` carried a path into the picker's own temporary container,
/// and persisting such a reference gives a draft that claims to hold a
/// document it cannot open.
///
/// Two things changed on 30 August 2026. Picked attachments are copied into
/// the app's own storage the moment they are chosen. And what is stored is the
/// file's NAME, resolved against the current documents directory at read time
/// — because an absolute path into an iOS container is **not stable across an
/// app update** even though the file is.
///
/// So the boundary moved, and these tests hold both sides of it.

late Directory storage;

DocumentModel _attachment(String name, {String? absolutePath}) => DocumentModel(
  id: 'doc-$name',
  label: 'Proof of ownership',
  fileName: '$name.pdf',
  uploadedAt: DateTime(2026, 8, 30),
  fileSizeBytes: 9,
  filePath: absolutePath ?? '${storage.path}/$name.pdf',
);

File _write(String name) =>
    File('${storage.path}/$name.pdf')..writeAsStringSync('%PDF-1.7');

void main() {
  setUp(() {
    storage = Directory.systemTemp.createTempSync('ebpco-attachments');
    DocumentStorageService.setRootForTesting(storage.path);
  });
  tearDown(() {
    DocumentStorageService.setRootForTesting(null);
    storage.deleteSync(recursive: true);
  });

  test('the harness actually has a storage root', () {
    // Every assertion below turns on this. With no root, `storedNameOf`
    // returns null and everything degrades to the old drop-everything
    // behaviour — which would make the "survives" tests pass for the wrong
    // reason and the "named" tests pass vacuously.
    expect(DocumentStorageService.root, storage.path);
  });

  group('a file in the app\'s own storage', () {
    test('comes back after a restart', () async {
      _write('land-title');
      final persistence = DraftPersistence(InMemoryDraftStore());
      final before = BuildingPermitProvider(persistence: persistence);
      before.startNew().requiredDocuments.landTitleUpload = _attachment(
        'land-title',
      );
      before.saveAsDraft();
      await before.pendingWrite;

      final after = BuildingPermitProvider(persistence: persistence);
      expect(await after.restoreFromStore(), isTrue);

      final restored = after.draft!.requiredDocuments.landTitleUpload;
      expect(restored, isNotNull, reason: 'the file was still there');
      expect(restored!.fileName, 'land-title.pdf');
      expect(restored.label, 'Proof of ownership');
      expect(restored.fileSizeBytes, 9);
      expect(File(restored.filePath!).existsSync(), isTrue);
      expect(
        after.documentsToReattach,
        isEmpty,
        reason: 'nothing was lost, so nothing may be asked for again',
      );
    });

    test('is resolved against the CURRENT directory, not the stored one', () {
      // The whole reason a name is stored rather than a path. On iOS the app's
      // container carries a UUID that changes on update — the file survives,
      // the path does not. Simulated by moving the root.
      _write('plans');
      const codec = BuildingPermitDraftCodec();
      final draft = BuildingPermitDraft()
        ..requiredDocuments.plansUpload = _attachment('plans');
      final snapshot = codec.snapshot(draft, step: 0);

      final moved = Directory.systemTemp.createTempSync('ebpco-moved');
      File('${moved.path}/plans.pdf').writeAsStringSync('%PDF-1.7');
      DocumentStorageService.setRootForTesting(moved.path);

      final restored = BuildingPermitDraft();
      codec.apply(restored, snapshot);
      expect(
        restored.requiredDocuments.plansUpload?.filePath,
        '${moved.path}/plans.pdf',
        reason: 'the container moved and the attachment followed it',
      );
      moved.deleteSync(recursive: true);
    });

    test('the snapshot stores a name, never a path', () {
      _write('plans');
      final snapshot = const BuildingPermitDraftCodec().snapshot(
        BuildingPermitDraft()
          ..requiredDocuments.plansUpload = _attachment('plans'),
        step: 0,
      );
      final record =
          snapshot.fields['requiredDocuments.plansUpload']!
              as Map<String, Object?>;
      expect(record['storedName'], 'plans.pdf');
      expect(
        record.values.whereType<String>().any((v) => v.contains(storage.path)),
        isFalse,
        reason: 'an absolute path in the record is the bug this design avoids',
      );
    });
  });

  group('and everything else is still named for the applicant', () {
    test('a picker path outside our storage is not kept', () async {
      // What every attachment used to be. The bytes are in a container the OS
      // may reclaim, so the reference is worthless and saying so is the point.
      final outside = Directory.systemTemp.createTempSync('ebpco-outside');
      File('${outside.path}/temp.pdf').writeAsStringSync('%PDF-1.7');

      final persistence = DraftPersistence(InMemoryDraftStore());
      final before = BuildingPermitProvider(persistence: persistence);
      before.startNew().requiredDocuments.landTitleUpload = _attachment(
        'temp',
        absolutePath: '${outside.path}/temp.pdf',
      );
      before.saveAsDraft();
      await before.pendingWrite;

      final after = BuildingPermitProvider(persistence: persistence);
      await after.restoreFromStore();
      expect(after.draft!.requiredDocuments.landTitleUpload, isNull);
      expect(after.documentsToReattach, ['Proof of ownership']);
      outside.deleteSync(recursive: true);
    });

    test('a file cleared since the draft was saved is named', () async {
      // The case a capture-time list gets wrong: it was there when saved and
      // is not there now. The applicant is told at the moment it matters.
      _write('land-title');
      final persistence = DraftPersistence(InMemoryDraftStore());
      final before = BuildingPermitProvider(persistence: persistence);
      before.startNew().requiredDocuments.landTitleUpload = _attachment(
        'land-title',
      );
      before.saveAsDraft();
      await before.pendingWrite;

      File('${storage.path}/land-title.pdf').deleteSync();

      final after = BuildingPermitProvider(persistence: persistence);
      await after.restoreFromStore();
      expect(after.draft!.requiredDocuments.landTitleUpload, isNull);
      expect(after.documentsToReattach, ['Proof of ownership']);
      expect(
        after.draftSummary!.documentsToReattach,
        ['Proof of ownership'],
        reason: 'and it reaches the Drafts row, which is where they will look',
      );
    });

    test('a stored name that is really a path resolves to nothing', () {
      // `../../somewhere` in a stored value would otherwise reach outside the
      // app's own storage.
      expect(DocumentStorageService.resolveStoredName('../escape.pdf'), isNull);
      expect(DocumentStorageService.resolveStoredName('a/b.pdf'), isNull);
    });

    test('with no storage root at all, nothing is kept', () {
      // Every widget test in this repository, and the app itself for the few
      // milliseconds before the root is read. It must degrade to the old
      // behaviour rather than to a broken one.
      _write('land-title');
      final draft = BuildingPermitDraft()
        ..requiredDocuments.landTitleUpload = _attachment('land-title');
      DocumentStorageService.setRootForTesting(null);

      final snapshot = const BuildingPermitDraftCodec().snapshot(
        draft,
        step: 0,
      );
      expect(snapshot.fields['requiredDocuments.landTitleUpload'], isNull);
      expect(snapshot.detachedDocuments, contains('Proof of ownership'));
    });
  });
}
