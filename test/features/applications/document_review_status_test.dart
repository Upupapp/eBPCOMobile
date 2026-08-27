import 'package:flutter_test/flutter_test.dart';

import 'package:ebpco_user_app/core/contract/admin_vocabulary.dart';
import 'package:ebpco_user_app/core/models/document_model.dart';

/// What the office decided about each document, and whether the applicant can
/// find out.
///
/// Before this, `DocumentModel` was id, label, fileName, uploadedAt, size and
/// path. The admin portal tracks eight review states per document and requires
/// the evaluator to write a reason whenever one is rejected or sent back — and
/// none of it could reach the applicant. A document turned back for revision
/// showed on their phone as a document that had been sent.

DocumentModel _doc({
  String label = 'Land Title',
  DocumentStatus? status,
  String? remarks,
  DateTime? expiryDate,
  List<DocumentSubmission> history = const [],
}) => DocumentModel(
  id: 'd1',
  label: label,
  fileName: 'land-title.pdf',
  uploadedAt: DateTime(2026, 8, 1),
  status: status,
  remarks: remarks,
  expiryDate: expiryDate,
  history: history,
);

void main() {
  group('what needs the applicant', () {
    test('a rejected document does', () {
      expect(_doc(status: DocumentStatus.rejected).needsApplicantAction, isTrue);
    });

    test('one sent back for revision does', () {
      expect(
        _doc(status: DocumentStatus.revisionRequired).needsApplicantAction,
        isTrue,
      );
    });

    test('an accepted one does not', () {
      expect(
        _doc(status: DocumentStatus.accepted).needsApplicantAction,
        isFalse,
      );
    });

    test('one still under review does not', () {
      // Nothing has been handed back yet. Telling the applicant to act would
      // be asking them to guess ahead of the office.
      expect(
        _doc(status: DocumentStatus.underReview).needsApplicantAction,
        isFalse,
      );
    });

    test('an unreviewed one does not', () {
      expect(_doc().needsApplicantAction, isFalse);
    });
  });

  group('expiry', () {
    test('a lapsed clearance counts as expired before the desk says so', () {
      // The applicant can act on this sooner than the office will, and should.
      final doc = _doc(
        status: DocumentStatus.accepted,
        expiryDate: DateTime.now().subtract(const Duration(days: 7)),
      );
      expect(doc.isExpired, isTrue);
      expect(doc.needsApplicantAction, isTrue);
    });

    test('a valid one is not expired', () {
      final doc = _doc(
        status: DocumentStatus.accepted,
        expiryDate: DateTime.now().add(const Duration(days: 30)),
      );
      expect(doc.isExpired, isFalse);
    });

    test('no expiry date means never expired', () {
      expect(_doc(status: DocumentStatus.accepted).isExpired, isFalse);
    });
  });

  group('resubmission', () {
    test('keeps what was sent before, and why it came back', () {
      final rejected = _doc(
        status: DocumentStatus.rejected,
        remarks: 'The copy is not certified true.',
      );

      final resubmitted = rejected.resubmittedWith(
        fileName: 'land-title-ctc.pdf',
        submittedAt: DateTime(2026, 8, 20),
      );

      expect(resubmitted.fileName, 'land-title-ctc.pdf');
      expect(resubmitted.status, DocumentStatus.submitted);
      expect(resubmitted.history, hasLength(1));

      final earlier = resubmitted.history.single;
      expect(earlier.fileName, 'land-title.pdf');
      expect(earlier.status, DocumentStatus.rejected);
      expect(
        earlier.remarks,
        'The copy is not certified true.',
        reason: 'the reason it was turned back must survive resubmission',
      );
    });

    test('the new submission carries no stale remarks', () {
      final resubmitted = _doc(
        status: DocumentStatus.rejected,
        remarks: 'Not certified.',
      ).resubmittedWith(
        fileName: 'new.pdf',
        submittedAt: DateTime(2026, 8, 20),
      );

      expect(
        resubmitted.remarks,
        isNull,
        reason: 'the old rejection does not describe the new file',
      );
    });

    test('history accumulates rather than replacing', () {
      var doc = _doc(status: DocumentStatus.rejected, remarks: 'First.');
      doc = doc.resubmittedWith(
        fileName: 'second.pdf',
        submittedAt: DateTime(2026, 8, 10),
      );
      doc = doc
          .copyWith(status: DocumentStatus.rejected, remarks: 'Second.')
          .resubmittedWith(
            fileName: 'third.pdf',
            submittedAt: DateTime(2026, 8, 20),
          );

      expect(doc.history, hasLength(2));
      expect(doc.history.map((h) => h.fileName), ['land-title.pdf', 'second.pdf']);
      expect(doc.fileName, 'third.pdf');
    });
  });

  test('a draft attachment has no review status', () {
    // The honest default. Showing a status nobody has decided would be a claim
    // about a decision that has not been made.
    final draft = DocumentModel(
      id: 'd2',
      label: 'Plans',
      fileName: 'plans.pdf',
      uploadedAt: DateTime(2026, 8, 1),
    );
    expect(draft.status, isNull);
    expect(draft.history, isEmpty);
    expect(draft.needsApplicantAction, isFalse);
  });
}
