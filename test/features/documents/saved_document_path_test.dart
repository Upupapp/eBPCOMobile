import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:ebpco_user_app/core/models/saved_document_model.dart';
import 'package:ebpco_user_app/core/services/document_storage_service.dart';

/// A saved document survives an app update.
///
/// "My Documents" stored the file's **absolute path** in SharedPreferences.
/// On iOS the app's container is
/// `/var/mobile/Containers/Data/Application/<UUID>/…` and that UUID changes on
/// every app update — so every entry in an applicant's library would have
/// broken at the first update: the list would still show the documents, and
/// none of them would open.
///
/// Nothing about that is visible on a simulator or in a test that never
/// updates the app, which is why it sat there. The draft snapshots learned it
/// first; this is the same fix applied to the other place the app remembers a
/// file.

late Directory storage;

SavedDocumentModel _document({String? storedName, String? knownPath}) =>
    SavedDocumentModel(
      id: 'doc-1',
      originalFileName: 'barangay-clearance.pdf',
      storedName: storedName ?? 'doc_1.pdf',
      knownPath: knownPath,
      fileType: SavedDocumentFileType.pdf,
      fileSizeBytes: 9,
      dateImported: DateTime(2026, 8, 31),
    );

void main() {
  setUp(() {
    storage = Directory.systemTemp.createTempSync('ebpco-saved-docs');
    DocumentStorageService.setRootForTesting(storage.path);
    File('${storage.path}/doc_1.pdf').writeAsStringSync('%PDF-1.7');
  });
  tearDown(() {
    DocumentStorageService.setRootForTesting(null);
    storage.deleteSync(recursive: true);
  });

  test('the harness has a storage root', () {
    // Without one, every resolution below falls through to the legacy path and
    // the tests would pass for the wrong reason.
    expect(DocumentStorageService.root, storage.path);
  });

  test('the path is resolved now, not remembered', () {
    expect(_document().localPath, '${storage.path}/doc_1.pdf');
    expect(_document().fileExists, isTrue);
  });

  test('and it follows the container when the container moves', () {
    // The whole point. An app update changes the prefix; the file does not
    // move, and neither does its name.
    final moved = Directory.systemTemp.createTempSync('ebpco-moved');
    File('${moved.path}/doc_1.pdf').writeAsStringSync('%PDF-1.7');
    DocumentStorageService.setRootForTesting(moved.path);

    expect(_document().localPath, '${moved.path}/doc_1.pdf');
    expect(_document().fileExists, isTrue);
    moved.deleteSync(recursive: true);
  });

  test('nothing writes an absolute path back to storage', () {
    final json = _document(knownPath: '/old/container/doc_1.pdf').toJson();
    expect(json['storedName'], 'doc_1.pdf');
    expect(
      json.containsKey('localPath'),
      isFalse,
      reason:
          'writing the path again is the defect. The legacy value is read for '
          'migration and never written back',
    );
    expect(
      json.values.whereType<String>().any((v) => v.startsWith('/')),
      isFalse,
    );
  });

  group('an entry saved before the migration', () {
    test('is migrated by its basename, on read', () {
      // No separate migration pass: the basename of the old absolute path IS
      // the file's name in our own storage, so reading it is the migration and
      // the next save writes the new shape.
      final legacy = SavedDocumentModel.fromJson({
        'id': 'doc-1',
        'originalFileName': 'barangay-clearance.pdf',
        'localPath':
            '/var/mobile/Containers/Data/Application/OLD-UUID/Documents/'
            'my_documents/doc_1.pdf',
        'fileType': 'pdf',
        'fileSizeBytes': 9,
        'dateImported': '2026-08-31T00:00:00.000',
        'category': 'uncategorized',
      });

      expect(legacy.storedName, 'doc_1.pdf');
      expect(
        legacy.localPath,
        '${storage.path}/doc_1.pdf',
        reason:
            'resolved under the CURRENT container, not the one it was '
            'saved under',
      );
      expect(legacy.fileExists, isTrue);
    });

    test('and its next save drops the absolute path', () {
      final legacy = SavedDocumentModel.fromJson({
        'id': 'doc-1',
        'originalFileName': 'barangay-clearance.pdf',
        'localPath': '/old/container/doc_1.pdf',
        'fileType': 'pdf',
        'fileSizeBytes': 9,
        'dateImported': '2026-08-31T00:00:00.000',
        'category': 'uncategorized',
      });
      expect(legacy.toJson()['storedName'], 'doc_1.pdf');
      expect(legacy.toJson().containsKey('localPath'), isFalse);
    });
  });

  test('a file that has gone is reported gone, not silently shown', () {
    // The list still shows the entry: an applicant is owed the difference
    // between "you never imported this" and "it is no longer on this device".
    File('${storage.path}/doc_1.pdf').deleteSync();
    final document = _document();
    expect(document.fileExists, isFalse);
    expect(document.storedName, 'doc_1.pdf', reason: 'the entry survives');
  });

  test('copyWith carries the name and the legacy fallback', () {
    final renamed = _document(
      knownPath: '/old/doc_1.pdf',
    ).copyWith(displayName: 'Barangay clearance 2026');
    expect(renamed.storedName, 'doc_1.pdf');
    expect(renamed.knownPath, '/old/doc_1.pdf');
    expect(renamed.localPath, '${storage.path}/doc_1.pdf');
  });
}
