import '../api/api_exception.dart';
import '../api/idempotency_key.dart';
import '../models/document_model.dart';
import '../sync/offline_queue.dart';
import '../sync/queued_operation.dart';
import 'document_upload_repository.dart';

/// An upload that survives a dropped connection.
///
/// Wraps the real upload. On a **transient** failure — no signal, a timeout, a
/// 5xx — the file is queued and the failure is rethrown, so the caller still
/// fails and nothing is filed against documents the office does not have. On a
/// **permanent** one — a file too large, a type the server will not take, a
/// rejected request — nothing is queued, because replaying it would fail
/// identically forever while telling the applicant something is still coming.
///
/// **What this does and does not promise.** It queues the FILE, not the
/// filing. An applicant whose connection drops mid-submission still has to
/// submit again — but when they do, the bytes are already at the office and
/// the retry is fast. Their typing survives separately, because M-48 persists
/// the draft. The queue's `applicationSubmission` kind is still unimplemented;
/// that is the piece that would make the whole filing automatic.
///
/// The queued item carries its own idempotency key, created once here and
/// reused on every replay, so a retry after the server committed but before
/// the response arrived returns the original document rather than storing the
/// file twice.
class QueueingDocumentUploadRepository implements DocumentUploadRepository {
  const QueueingDocumentUploadRepository(this._inner, this._queue);

  final DocumentUploadRepository _inner;
  final OfflineQueue _queue;

  @override
  Future<UploadedDocument> upload(
    DocumentModel document, {
    String? applicationId,
    String? idempotencyKey,
    void Function(int sent, int total)? onProgress,
  }) async {
    final key = idempotencyKey ?? newIdempotencyKey();
    try {
      return await _inner.upload(
        document,
        applicationId: applicationId,
        idempotencyKey: key,
        onProgress: onProgress,
      );
    } on ApiException catch (error) {
      if (error.failure.isTransient) {
        await _enqueue(document, applicationId: applicationId, key: key);
      }
      // Rethrown either way. Queuing is not success, and a caller that treated
      // it as success would file an application referencing documents the
      // office has not received.
      rethrow;
    }
  }

  Future<void> _enqueue(
    DocumentModel document, {
    required String key,
    String? applicationId,
  }) async {
    final path = document.filePath;
    // Nothing to replay from. A fabricated attachment has no bytes, and
    // queuing a reference to nothing would show the applicant a pending item
    // that can never complete.
    if (path == null || path.isEmpty) return;

    try {
      await _queue.enqueue(
        QueuedOperation(
          id: 'upload-${document.id}-$key',
          kind: QueuedOperationKind.documentUpload,
          idempotencyKey: key,
          enqueuedAt: DateTime.now(),
          applicationId: applicationId,
          payload: {
            'filePath': path,
            'label': document.label,
            'fileName': document.fileName,
          },
        ),
      );
    } on QueueFullException {
      // The queue is full, which is its own honest failure and not this
      // upload's. The applicant is told about the upload; the queue reports
      // its own state separately.
      return;
    }
  }
}
