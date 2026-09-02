/// How far a submission's uploads have got.
///
/// A filing uploads its attachments one at a time before the application is
/// sent — sequentially on purpose, because twenty-four concurrent multipart
/// uploads from a phone on a rural connection is how a submission times out.
/// That is the right behaviour and it is slow, so the citizen has to be able
/// to see it working.
class UploadProgress {
  const UploadProgress({
    required this.index,
    required this.total,
    required this.label,
    this.sentBytes,
    this.totalBytes,
  });

  /// Zero-based position of the document being sent.
  final int index;

  /// How many documents this filing carries.
  final int total;

  /// The slot's own name — "Land Title", not "document 3". A citizen watching
  /// an upload stall wants to know which of their files it is.
  final String label;

  /// Bytes handed to the socket for this document, when known.
  ///
  /// Null before the first chunk. **Not bytes the server has acknowledged** —
  /// the OS buffers, so this can reach the total slightly before the office
  /// has the file. Worth showing anyway; "nearly done" that is a little
  /// optimistic beats four minutes of silence.
  final int? sentBytes;

  final int? totalBytes;

  /// Position in the whole filing, 0–1, across every document.
  ///
  /// A per-file bar that resets to zero twenty-four times reads as no progress
  /// at all, so the fraction spans the submission: each document is one slice,
  /// and the bytes move within its slice.
  double get fraction {
    if (total == 0) return 1;
    final within = (totalBytes ?? 0) > 0 ? (sentBytes ?? 0) / totalBytes! : 0.0;
    return ((index + within.clamp(0.0, 1.0)) / total).clamp(0.0, 1.0);
  }

  /// "Sending 3 of 24" — one-based, because nobody counts documents from zero.
  String get position => 'Sending ${index + 1} of $total';
}
