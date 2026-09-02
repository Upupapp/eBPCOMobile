import '../api/api_client.dart';
import '../api/api_exception.dart';
import '../api/idempotency_key.dart';
import '../models/document_model.dart';

/// Sends a file the applicant picked to the office, and returns its id.
///
/// **The missing half of the write path.** Until this existed, the app sent a
/// document's *label and filename* inside the submission body — an undeclared
/// key that a conforming server refuses outright — because there was no way to
/// produce the `documentIds` the contract asks for. Two of M-47's six
/// divergences were that one gap, seen from two request bodies.
///
/// The office does not have the file when this returns. `POST /documents`
/// answers `201` with `scanCleared: false`, and the bytes are unavailable to
/// anyone until malware scanning finishes. That is why [UploadedDocument]
/// carries the flag rather than hiding it: an applicant told "uploaded" and an
/// office that cannot open the file yet are both true at once, and only one of
/// them is on the screen.
abstract class DocumentUploadRepository {
  /// Uploads one picked file.
  ///
  /// [applicationId] is null when the document is being attached to an
  /// application that does not exist yet — which is every wizard, because the
  /// files are gathered before the application is filed.
  Future<UploadedDocument> upload(
    DocumentModel document, {
    String? applicationId,
    String? idempotencyKey,

    /// Bytes handed to the socket, and the total. See `ApiClient.upload` for
    /// what that does and does not mean.
    void Function(int sent, int total)? onProgress,
  });
}

/// What the office gave back for one uploaded file.
class UploadedDocument {
  const UploadedDocument({
    required this.id,
    required this.label,
    required this.fileName,
    required this.uploadedAt,
    required this.scanCleared,
    this.byteSize,
    this.contentType,
  });

  /// The uuid to put in `documentIds`. The whole reason this class exists.
  final String id;

  final String label;
  final String fileName;
  final DateTime uploadedAt;

  /// False until malware scanning completes, and the office cannot open the
  /// file while it is false. Never presented as "the office has your document".
  final bool scanCleared;

  final int? byteSize;

  /// As determined by magic-byte inspection, not as the app supplied it. A
  /// file renamed to `.pdf` comes back as what it actually is.
  final String? contentType;

  static UploadedDocument parse(Map<String, dynamic> json) {
    final id = json['id'];
    final fileName = json['fileName'];
    if (id is! String || fileName is! String) {
      throw const ApiException(
        ApiFailure.malformed,
        'the upload response carried no document id',
      );
    }
    return UploadedDocument(
      id: id,
      label: json['label'] is String ? json['label'] as String : '',
      fileName: fileName,
      uploadedAt: DateTime.tryParse('${json['uploadedAt']}') ?? DateTime.now(),
      // Absent means not cleared. The safe reading of a missing flag is the
      // one that does not tell an applicant their document is with the office.
      scanCleared: json['scanCleared'] == true,
      byteSize: json['byteSize'] is int ? json['byteSize'] as int : null,
      contentType: json['contentType'] is String
          ? json['contentType'] as String
          : null,
    );
  }
}

class HttpDocumentUploadRepository implements DocumentUploadRepository {
  const HttpDocumentUploadRepository(this._api);

  final ApiClient _api;

  @override
  Future<UploadedDocument> upload(
    DocumentModel document, {
    String? applicationId,
    String? idempotencyKey,
    void Function(int sent, int total)? onProgress,
  }) async {
    final path = document.filePath;
    if (path == null || path.isEmpty) {
      // A fabricated attachment — the mock documents the prototype creates
      // when the applicant taps Upload without a real file picker behind it.
      // There is nothing to send, and pretending otherwise would put an id in
      // the submission for a file the office never received.
      throw const ApiException(
        ApiFailure.rejected,
        'this attachment has no file on the device to upload',
      );
    }
    return UploadedDocument.parse(
      await _api.upload(
        onProgress: onProgress,
        '/documents',
        filePath: path,
        label: document.label,
        applicationId: applicationId,
        // One key per upload, made here when the operation is first attempted.
        // Passed in when the caller is retrying, so the server returns the
        // original result rather than storing the file twice.
        idempotencyKey: idempotencyKey ?? newIdempotencyKey(),
      ),
    );
  }
}

/// The mock build's upload repository, which refuses rather than pretends.
///
/// Returning a fabricated id would be the worst possible mock: the submission
/// would succeed, the office would hold a reference to nothing, and the
/// applicant would be told their documents were received. The same rule the
/// sync engine follows for the four operations it cannot send.
class UnavailableDocumentUploadRepository implements DocumentUploadRepository {
  const UnavailableDocumentUploadRepository();

  @override
  Future<UploadedDocument> upload(
    DocumentModel document, {
    String? applicationId,
    String? idempotencyKey,
    void Function(int sent, int total)? onProgress,
  }) async => throw const ApiException(
    ApiFailure.rejected,
    'this build has no server to upload documents to',
  );
}
