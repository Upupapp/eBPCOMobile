import 'package:flutter_test/flutter_test.dart';

import 'package:ebpco_user_app/core/contract/admin_vocabulary.dart';
import 'package:ebpco_user_app/core/models/document_model.dart';
import 'package:ebpco_user_app/core/models/document_review_reason.dart';

/// The standard reason and the custom remark, and why this one vocabulary is
/// deliberately open when every other one this app mirrors is closed.

DocumentModel _document({
  DocumentStatus? status = DocumentStatus.rejected,
  String? remarks,
  DocumentReviewReason? reason,
}) => DocumentModel(
  id: 'doc-1',
  label: 'Certified True Copy of Title',
  fileName: 'title.pdf',
  uploadedAt: DateTime(2026, 8, 1),
  status: status,
  remarks: remarks,
  reviewReason: reason,
);

const _illegible = DocumentReviewReason(code: 'illegible', label: 'Illegible');

void main() {
  group('the catalogue is OPEN, unlike every other vocabulary here', () {
    test('an unrecognised code renders instead of throwing', () {
      // The admin's closed vocabularies throw UnknownWireValue on purpose,
      // because a status the app invents a meaning for is how an applicant
      // gets told their document was accepted. This is the opposite: the LGU
      // edits this catalogue, and an office adding a row must not crash a
      // phone that shipped last month.
      final reason = DocumentReviewReason.fromWire(
        code: 'blurred-photograph',
        label: 'Blurred photograph',
      );
      expect(reason.code, 'blurred-photograph');
      expect(reason.label, 'Blurred photograph');
    });

    test('a code with no label is humanised rather than shown raw', () {
      final reason = DocumentReviewReason.fromWire(
        code: 'not-certified-true-copy',
      );
      expect(reason.label, 'Not certified true copy');
    });

    test('an empty label is treated as no label', () {
      expect(
        DocumentReviewReason.fromWire(code: 'illegible', label: '   ').label,
        'Illegible',
      );
    });

    test('a nonsense code still produces something to render', () {
      // Never a blank chip, and never a crash.
      expect(DocumentReviewReason.fromWire(code: '  ').label, isNotEmpty);
    });

    test('identity is the code, not the label', () {
      // An LGU rewording "Illegible" to "Not readable" has not created a
      // different reason.
      expect(
        const DocumentReviewReason(code: 'illegible', label: 'Illegible'),
        const DocumentReviewReason(code: 'illegible', label: 'Not readable'),
      );
    });
  });

  group('both halves reach the applicant', () {
    test('a standard reason and a remark read as one line, category first', () {
      final doc = _document(
        reason: _illegible,
        remarks: 'Page 3 cannot be read.',
      );
      expect(doc.reviewFeedback, 'Illegible — Page 3 cannot be read.');
    });

    test('a standard reason alone is enough', () {
      // A code IS a reason. The office is not obliged to type as well.
      expect(_document(reason: _illegible).reviewFeedback, 'Illegible');
    });

    test('custom feedback alone is enough', () {
      expect(
        _document(remarks: 'The notarial seal is missing.').reviewFeedback,
        'The notarial seal is missing.',
      );
    });

    test('"Other" alone is suppressed, because it says nothing', () {
      // A filing category, not something to tell an applicant. Showing
      // "Other" on its own is worse than showing nothing: it looks like an
      // answer.
      const other = DocumentReviewReason(code: 'other', label: 'Other');
      expect(_document(reason: other).reviewFeedback, isNull);
    });

    test('"Other" with a remark shows the remark alone', () {
      const other = DocumentReviewReason(code: 'other', label: 'Other');
      expect(
        _document(reason: other, remarks: 'Wrong lot number.').reviewFeedback,
        'Wrong lot number.',
      );
    });

    test('a document nobody turned back has nothing to say', () {
      expect(_document(status: DocumentStatus.accepted).reviewFeedback, isNull);
    });

    test('whitespace-only remarks are not feedback', () {
      expect(_document(remarks: '   ').reviewFeedback, isNull);
    });
  });

  group('resubmitting answers the verdict', () {
    test('the reason does not survive onto the replacement', () {
      // A reason left standing beside a fresh submission reads as a fresh
      // rejection of work the office has not looked at yet.
      final rejected = _document(
        reason: _illegible,
        remarks: 'Page 3 cannot be read.',
      );

      final replacement = rejected.resubmittedWith(
        fileName: 'title-v2.pdf',
        submittedAt: DateTime(2026, 8, 20),
      );

      expect(replacement.status, DocumentStatus.submitted);
      expect(replacement.reviewReason, isNull);
      expect(replacement.remarks, isNull);
      expect(replacement.reviewFeedback, isNull);
    });

    test('but the history keeps what was said', () {
      final replacement =
          _document(
            reason: _illegible,
            remarks: 'Page 3 cannot be read.',
          ).resubmittedWith(
            fileName: 'title-v2.pdf',
            submittedAt: DateTime(2026, 8, 20),
          );

      expect(replacement.history, hasLength(1));
      expect(replacement.history.single.remarks, 'Page 3 cannot be read.');
      expect(replacement.history.single.status, DocumentStatus.rejected);
    });
  });
}
