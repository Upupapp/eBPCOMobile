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

  /// 401/403 — the session is gone or the applicant may not see this.
  unauthorized,

  /// 404 — the record does not exist, or not for this applicant.
  notFound,

  /// 409/422 — the server rejected the request as invalid.
  rejected,

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
      case ApiFailure.notFound:
        return 'This record could not be found.';
      case ApiFailure.rejected:
        return 'The office’s system did not accept this. Please check your '
            'details and try again.';
      case ApiFailure.server:
        return 'The office’s system is having trouble. Please try again '
            'shortly.';
      case ApiFailure.malformed:
        return 'This could not be displayed correctly. Please report it to the '
            'Office of the Building Official.';
    }
  }
}

/// A failed API call.
class ApiException implements Exception {
  final ApiFailure failure;

  /// Engineering detail — never shown to an applicant.
  final String detail;

  final int? statusCode;

  const ApiException(this.failure, this.detail, {this.statusCode});

  /// The message safe to put in front of an applicant.
  String get applicantMessage => failure.applicantMessage;

  bool get isTransient => failure.isTransient;

  @override
  String toString() =>
      'ApiException(${failure.name}${statusCode == null ? '' : ' $statusCode'}): '
      '$detail';
}
