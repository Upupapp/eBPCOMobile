/// Represents one simulated attached file — used both for permit
/// requirement uploads and proof-of-payment uploads. No real file picking
/// happens; a fixed mock filename is fabricated when the user taps upload.
class DocumentModel {
  final String id;
  final String label;
  final String fileName;
  final DateTime uploadedAt;
  final int? fileSizeBytes;

  const DocumentModel({
    required this.id,
    required this.label,
    required this.fileName,
    required this.uploadedAt,
    this.fileSizeBytes,
  });
}
