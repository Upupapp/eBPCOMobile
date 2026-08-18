import 'package:flutter_test/flutter_test.dart';

import 'package:ebpco_user_app/core/models/saved_document_model.dart';

SavedDocumentModel _document({DateTime? expiry, String id = 'doc-1'}) =>
    SavedDocumentModel(
      id: id,
      originalFileName: 'barangay_clearance.pdf',
      localPath: '/tmp/barangay_clearance.pdf',
      fileType: SavedDocumentFileType.pdf,
      fileSizeBytes: 120000,
      dateImported: DateTime(2026, 1, 10),
      category: SavedDocumentCategory.barangayClearance,
      expiryDate: expiry,
    );

final _asOf = DateTime(2026, 8, 18);

void main() {
  group('time-bound documents', () {
    test('a document with no expiry is never expired or nagging', () {
      final document = _document();

      expect(document.isTimeBound, isFalse);
      expect(document.isExpired(_asOf), isFalse);
      expect(document.daysUntilExpiry(_asOf), isNull);
      expect(document.needsAttention(_asOf), isFalse);
    });

    test('one lapsing far ahead is quiet', () {
      final document = _document(expiry: DateTime(2027, 1, 10));

      expect(document.isTimeBound, isTrue);
      expect(document.isExpired(_asOf), isFalse);
      expect(document.needsAttention(_asOf), isFalse);
    });

    test('one lapsing within 30 days needs attention', () {
      // Thirty rather than sixty: most of these are re-obtained in a single
      // visit, so warning earlier would nag without giving anything to do.
      final document = _document(expiry: DateTime(2026, 9, 10));

      expect(document.daysUntilExpiry(_asOf), 23);
      expect(document.needsAttention(_asOf), isTrue);
      expect(document.isExpired(_asOf), isFalse);
    });

    test('is not yet expired on its expiry date', () {
      final document = _document(expiry: _asOf);

      expect(document.isExpired(_asOf), isFalse);
      expect(document.daysUntilExpiry(_asOf), 0);
      expect(document.needsAttention(_asOf), isTrue);
    });

    test('is expired the day after', () {
      final document = _document(expiry: DateTime(2026, 8, 17));

      expect(document.isExpired(_asOf), isTrue);
      expect(document.daysUntilExpiry(_asOf), -1);
      expect(document.needsAttention(_asOf), isTrue);
    });

    test('ignores the time of day', () {
      final document = _document(expiry: DateTime(2026, 8, 18, 23, 59));

      expect(document.isExpired(DateTime(2026, 8, 18, 0, 1)), isFalse);
    });
  });

  group('persistence', () {
    test('an expiry date survives a round trip', () {
      final document = _document(expiry: DateTime(2026, 9, 10));
      final restored = SavedDocumentModel.fromJson(document.toJson());

      expect(restored.expiryDate, DateTime(2026, 9, 10));
      expect(restored.isTimeBound, isTrue);
    });

    test('a document saved before expiry tracking reads as having none', () {
      // An unknown expiry is not an expired one, so older saved documents
      // must not start warning the moment the app updates.
      final legacy = _document().toJson()..remove('expiryDate');
      final restored = SavedDocumentModel.fromJson(legacy);

      expect(restored.expiryDate, isNull);
      expect(restored.needsAttention(_asOf), isFalse);
    });
  });

  group('copyWith', () {
    test('sets an expiry date', () {
      final updated = _document().copyWith(expiryDate: DateTime(2027, 1, 1));
      expect(updated.expiryDate, DateTime(2027, 1, 1));
    });

    test('clears one explicitly, since a null argument cannot', () {
      // The usual `expiryDate ?? this.expiryDate` idiom makes null mean
      // "unchanged", so clearing needs its own flag.
      final document = _document(expiry: DateTime(2027, 1, 1));

      expect(document.copyWith().expiryDate, DateTime(2027, 1, 1));
      expect(document.copyWith(clearExpiryDate: true).expiryDate, isNull);
    });

    test('leaves everything else alone', () {
      final updated = _document(
        expiry: DateTime(2027, 1, 1),
      ).copyWith(clearExpiryDate: true);

      expect(updated.id, 'doc-1');
      expect(updated.category, SavedDocumentCategory.barangayClearance);
      expect(updated.fileSizeBytes, 120000);
    });
  });
}
