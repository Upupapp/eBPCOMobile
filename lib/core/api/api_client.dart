import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_exception.dart';

/// Supplies the bearer token for outgoing requests, or null when signed out.
///
/// A callback rather than a stored string so the client always asks for the
/// current token instead of holding a stale one across a re-authentication.
typedef AuthTokenProvider = Future<String?> Function();

/// The eBPCO API.
///
/// Thin on purpose: it owns transport, headers, timeouts, and the mapping from
/// HTTP outcomes to [ApiException]. It knows nothing about applications,
/// payments, or permits — repositories translate between this and the domain,
/// so the shape of the API can change without the app's screens noticing.
class ApiClient {
  ApiClient({
    required this.baseUrl,
    http.Client? httpClient,
    AuthTokenProvider? authToken,
    this.timeout = const Duration(seconds: 20),
  }) : _http = httpClient ?? http.Client(),
       _authToken = authToken ?? _noToken;

  /// Root of the API, without a trailing slash.
  final String baseUrl;

  final http.Client _http;
  final AuthTokenProvider _authToken;

  /// Generous by mobile-data standards, because the alternative — a spurious
  /// timeout on a slow connection — sends an applicant back to a queue they
  /// have already joined.
  final Duration timeout;

  static Future<String?> _noToken() async => null;

  Future<Map<String, dynamic>> getObject(
    String path, {
    Map<String, String>? query,
  }) async => _asObject(await _send('GET', path, query: query));

  Future<List<dynamic>> getList(
    String path, {
    Map<String, String>? query,
  }) async => _asList(await _send('GET', path, query: query));

  /// A write.
  ///
  /// [idempotencyKey] is REQUIRED here because the contract requires the
  /// header on every POST an applicant can make, and because a named parameter
  /// nobody can forget is the only version of this that stays true. It used to
  /// be sent on none of them: a retry after a timeout was a SECOND filing.
  ///
  /// Pass the SAME key when retrying the same operation — that is the whole
  /// point of it. `newIdempotencyKey()` makes one.
  Future<Map<String, dynamic>> post(
    String path, {
    Object? body,
    required String idempotencyKey,
  }) async => _asObject(
    await _send('POST', path, body: body, idempotencyKey: idempotencyKey),
  );

  /// Uploads one file as `multipart/form-data`.
  ///
  /// Separate from [post] because the body is bytes rather than JSON, and
  /// because the failures are different: 413 and 415 are both things the
  /// applicant can act on and neither means "check your details".
  ///
  /// The bytes are streamed from [filePath] rather than read into memory. A
  /// scanned plan set is tens of megabytes and this app runs on mid-range
  /// Android hardware.
  Future<Map<String, dynamic>> upload(
    String path, {
    required String filePath,
    required String label,
    String? applicationId,
    required String idempotencyKey,

    /// Called as the body is handed to the socket, with bytes sent and the
    /// total.
    ///
    /// **What it measures, honestly.** These are bytes written to the
    /// transport, not bytes the server has acknowledged. The OS buffers, so on
    /// a slow link this can reach the total before the office has the file.
    /// It is still worth showing: a citizen uploading a twenty-megabyte plan
    /// set over rural data needs to know something is happening and roughly
    /// how much is left, and "nearly done" that is slightly optimistic beats a
    /// spinner that says nothing for four minutes.
    void Function(int sent, int total)? onProgress,
  }) async {
    final uri = Uri.parse('$baseUrl$path');
    final request = onProgress == null
        ? http.MultipartRequest('POST', uri)
        : _ProgressMultipartRequest('POST', uri, onProgress)
              as http.MultipartRequest;
    request
      ..headers['Accept'] = 'application/json'
      ..headers['Idempotency-Key'] = idempotencyKey
      ..fields['label'] = label;
    if (applicationId != null) request.fields['applicationId'] = applicationId;

    final token = await _authToken();
    if (token != null) request.headers['Authorization'] = 'Bearer $token';

    try {
      request.files.add(await http.MultipartFile.fromPath('file', filePath));
    } on Exception catch (error) {
      // The picked file is gone — the OS reclaimed the temporary container, or
      // the applicant deleted it between picking and filing. Reported as its
      // own failure rather than as a network problem, because retrying will
      // not help and the applicant has to pick the file again.
      throw ApiException(
        ApiFailure.rejected,
        'the file to upload could not be read: $error',
      );
    }

    http.Response response;
    try {
      final streamed = await _http.send(request).timeout(timeout);
      response = await http.Response.fromStream(streamed);
    } on TimeoutException catch (error) {
      throw ApiException(ApiFailure.timeout, 'POST $uri timed out: $error');
    } catch (error) {
      throw ApiException(ApiFailure.network, 'POST $uri failed: $error');
    }

    _throwOnError(response, 'POST', uri);
    return _asObject(jsonDecode(response.body));
  }

  Future<Map<String, dynamic>> patch(String path, {Object? body}) async =>
      _asObject(await _send('PATCH', path, body: body));

  /// A destructive request, and the only verb here that takes an idempotency
  /// key without a body.
  ///
  /// `DELETE /me` answers **202**, not 200 — erasure is queued, not immediate,
  /// which is what RA 10173 §16(e) requires. `_send` already returns an empty
  /// map for an empty body, so nothing here insists on a payload that a
  /// correct response need not carry.
  Future<void> delete(String path, {required String idempotencyKey}) async {
    await _send('DELETE', path, idempotencyKey: idempotencyKey);
  }

  void close() => _http.close();

  Future<dynamic> _send(
    String method,
    String path, {
    Map<String, String>? query,
    Object? body,
    String? idempotencyKey,
  }) async {
    final uri = Uri.parse(
      '$baseUrl$path',
    ).replace(queryParameters: query == null || query.isEmpty ? null : query);

    final headers = <String, String>{
      'Accept': 'application/json',
      if (body != null) 'Content-Type': 'application/json',
      'Idempotency-Key': ?idempotencyKey,
    };
    final token = await _authToken();
    if (token != null) headers['Authorization'] = 'Bearer $token';

    final request = http.Request(method, uri)..headers.addAll(headers);
    if (body != null) request.body = jsonEncode(body);

    http.Response response;
    try {
      final streamed = await _http.send(request).timeout(timeout);
      response = await http.Response.fromStream(streamed);
    } on TimeoutException catch (error) {
      throw ApiException(ApiFailure.timeout, '$method $uri timed out: $error');
    } on http.ClientException catch (error) {
      throw ApiException(ApiFailure.network, '$method $uri failed: $error');
    } catch (error) {
      // Anything else reaching here is a transport problem — a socket error, a
      // TLS failure, a DNS failure. Classifying it as network keeps the
      // applicant-facing message honest without pretending to know which.
      throw ApiException(ApiFailure.network, '$method $uri failed: $error');
    }

    _throwOnError(response, method, uri);
    if (response.body.isEmpty) return const <String, dynamic>{};

    try {
      return jsonDecode(response.body);
    } on FormatException catch (error) {
      throw ApiException(
        ApiFailure.malformed,
        '$method $uri returned unparseable JSON: $error',
        statusCode: response.statusCode,
      );
    }
  }

  void _throwOnError(http.Response response, String method, Uri uri) {
    final status = response.statusCode;
    if (status >= 200 && status < 300) return;

    final failure = switch (status) {
      401 => ApiFailure.unauthorized,
      // Separate from 401: signing in again achieves nothing for a permissions
      // problem, and sending someone to a login screen for one is a loop.
      403 => ApiFailure.forbidden,
      404 => ApiFailure.notFound,
      409 || 422 => ApiFailure.rejected,
      413 => ApiFailure.tooLarge,
      415 => ApiFailure.unsupportedMedia,
      _ when status >= 500 => ApiFailure.server,
      // Any other 4xx is the app sending something wrong, which is a bug on
      // this side rather than an outage.
      _ => ApiFailure.rejected,
    };

    throw ApiException(
      failure,
      '$method $uri returned $status: ${_briefly(response.body)}',
      statusCode: status,
      // RFC 9457. Null when the server sent something else, which is a failure
      // with no structured detail rather than a parse error.
      problem: ProblemDetails.tryParse(response.body),
    );
  }

  static String _briefly(String body) =>
      body.length <= 200 ? body : '${body.substring(0, 200)}…';

  Map<String, dynamic> _asObject(dynamic decoded) {
    if (decoded is Map<String, dynamic>) return decoded;
    throw ApiException(
      ApiFailure.malformed,
      'expected a JSON object, got ${decoded.runtimeType}',
    );
  }

  List<dynamic> _asList(dynamic decoded) {
    if (decoded is List) return decoded;
    // A collection endpoint that wraps its rows is common enough to accept.
    if (decoded is Map<String, dynamic> && decoded['data'] is List) {
      return decoded['data'] as List;
    }
    throw ApiException(
      ApiFailure.malformed,
      'expected a JSON array, got ${decoded.runtimeType}',
    );
  }
}

/// A multipart request that reports how much of itself has gone out.
///
/// `package:http` has no progress callback, and the file is streamed rather
/// than buffered — which is right for a twenty-megabyte plan set on a phone —
/// so the only place to count is the stream the request hands to the client.
class _ProgressMultipartRequest extends http.MultipartRequest {
  _ProgressMultipartRequest(super.method, super.url, this._onProgress);

  final void Function(int sent, int total) _onProgress;

  @override
  http.ByteStream finalize() {
    final total = contentLength;
    var sent = 0;
    return http.ByteStream(
      super.finalize().transform(
        StreamTransformer.fromHandlers(
          handleData: (chunk, sink) {
            sent += chunk.length;
            _onProgress(sent, total);
            sink.add(chunk);
          },
        ),
      ),
    );
  }
}
