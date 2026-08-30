import 'dart:convert';

/// Why a call to the eBPCO API failed.
///
/// Typed rather than a bare message because the app reacts differently to
/// each: an expired session sends the applicant to sign in, a timeout keeps
/// the cached data and offers retry, and malformed data is a bug worth
/// surfacing loudly rather than rendering as an empty screen.
enum ApiFailure {
  /// No usable connection, DNS failure, or the host refused.
  network,

  /// The request was made but nothing came back in time.
  timeout,

  /// 401 — the session is gone. The applicant signs in again and continues.
  unauthorized,

  /// 403 — signed in, but not permitted. Separate from [unauthorized] because
  /// the remedy is completely different: signing in again achieves nothing, and
  /// sending someone to a login screen for a permissions problem is a loop they
  /// cannot escape.
  forbidden,

  /// 404 — the record does not exist, or not for this applicant.
  notFound,

  /// 409/422 — the server rejected the request as invalid.
  rejected,

  /// 413 — the file is larger than the per-file or per-application cap.
  ///
  /// Separate from [rejected] because the remedy is the applicant's and is
  /// specific: photograph the page again at a lower resolution, or split the
  /// plan set. "Check your details and try again" is useless advice for it.
  tooLarge,

  /// 415 — the content is not an allowed type, by magic-byte inspection.
  ///
  /// Note what that means for the message: the server did not look at the file
  /// extension, so renaming it will not help, and telling an applicant to
  /// "try a different format" has to mean re-exporting rather than renaming.
  unsupportedMedia,

  /// 5xx — the server broke.
  server,

  /// A 2xx response the app could not parse. Distinct from [server] because
  /// the fault is a contract mismatch, not an outage, and the fix is code.
  malformed,
}

extension ApiFailureX on ApiFailure {
  /// Whether retrying the identical request could plausibly succeed.
  bool get isTransient =>
      this == ApiFailure.network ||
      this == ApiFailure.timeout ||
      this == ApiFailure.server;

  /// What the applicant is told. Deliberately free of status codes and stack
  /// traces: an applicant cannot act on "HTTP 502", and being shown one
  /// suggests they did something wrong.
  String get applicantMessage {
    switch (this) {
      case ApiFailure.network:
        return 'No connection. Showing what was saved on this device.';
      case ApiFailure.timeout:
        return 'The office’s system did not respond in time. Please try again.';
      case ApiFailure.unauthorized:
        return 'Your session has expired. Please sign in again.';
      case ApiFailure.forbidden:
        return 'This account does not have permission for that.';
      case ApiFailure.notFound:
        return 'This record could not be found.';
      case ApiFailure.rejected:
        return 'The office’s system did not accept this. Please check your '
            'details and try again.';
      case ApiFailure.tooLarge:
        return 'That file is too large to upload. Try photographing the page '
            'again at a lower resolution, or send the plans as separate '
            'files.';
      case ApiFailure.unsupportedMedia:
        return 'That file type cannot be accepted. Please upload a PDF or a '
            'photo — renaming the file will not help, because the office’s '
            'system checks the contents rather than the name.';
      case ApiFailure.server:
        return 'The office’s system is having trouble. Please try again '
            'shortly.';
      case ApiFailure.malformed:
        return 'This could not be displayed correctly. Please report it to the '
            'Office of the Building Official.';
    }
  }
}

/// The RFC 9457 Problem Details the server returns on every non-2xx.
///
/// Parsed rather than ignored because `type` is stable and machine-readable, so
/// the app can act on a specific problem — "no Order of Payment has been
/// issued" is a different screen from "you are not permitted" — where the
/// status code alone only says 4xx.
class ProblemDetails {
  const ProblemDetails({
    required this.type,
    required this.title,
    this.detail,
    this.correlationId,
    this.fieldErrors = const {},
  });

  final String type;
  final String title;
  final String? detail;

  /// Ties this failure to the server-side trace. Shown to the applicant only in
  /// a report-a-problem flow, never as part of an error message: an id is not
  /// something they can act on.
  final String? correlationId;

  /// JSON Pointer to message, for a form to attach errors to the right field.
  final Map<String, String> fieldErrors;

  static ProblemDetails? tryParse(String body) {
    if (body.isEmpty) return null;
    try {
      final decoded = jsonDecode(body);
      if (decoded is! Map<String, dynamic>) return null;
      final type = decoded['type'];
      final title = decoded['title'];
      if (type is! String || title is! String) return null;

      final errors = <String, String>{};
      final raw = decoded['errors'];
      if (raw is List) {
        for (final entry in raw.whereType<Map<String, dynamic>>()) {
          final pointer = entry['pointer'];
          final message = entry['message'];
          if (pointer is String && message is String) errors[pointer] = message;
        }
      }

      return ProblemDetails(
        type: type,
        title: title,
        detail: decoded['detail'] is String
            ? decoded['detail'] as String
            : null,
        correlationId: decoded['correlationId'] is String
            ? decoded['correlationId'] as String
            : null,
        fieldErrors: errors,
      );
    } on FormatException {
      // A non-2xx that is not problem+json is still a failure; it just carries
      // no structured detail. Falling back to the status-code mapping is
      // better than turning a 503 into a parse error.
      return null;
    }
  }
}

/// A failed API call.
class ApiException implements Exception {
  final ApiFailure failure;

  /// Engineering detail — never shown to an applicant.
  final String detail;

  final int? statusCode;

  /// The structured problem, when the server sent one.
  final ProblemDetails? problem;

  const ApiException(
    this.failure,
    this.detail, {
    this.statusCode,
    this.problem,
  });

  /// The message safe to put in front of an applicant.
  ///
  /// Prefers the server's own `detail` when there is one: it is written for the
  /// applicant and knows the specifics — "No Order of Payment has been issued
  /// for this application, so there is nothing to pay" beats a generic
  /// rejection message. Falls back to the taxonomy otherwise.
  String get applicantMessage => problem?.detail ?? failure.applicantMessage;

  /// The stable problem type, for a screen that branches on a specific case.
  String? get problemType => problem?.type;

  bool get isTransient => failure.isTransient;

  @override
  String toString() =>
      'ApiException(${failure.name}${statusCode == null ? '' : ' $statusCode'}): '
      '$detail';
}
