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

  Future<Map<String, dynamic>> getObject(String path,
          {Map<String, String>? query}) async =>
      _asObject(await _send('GET', path, query: query));

  Future<List<dynamic>> getList(String path,
          {Map<String, String>? query}) async =>
      _asList(await _send('GET', path, query: query));

  Future<Map<String, dynamic>> post(String path,
          {Object? body}) async =>
      _asObject(await _send('POST', path, body: body));

  Future<Map<String, dynamic>> patch(String path, {Object? body}) async =>
      _asObject(await _send('PATCH', path, body: body));

  void close() => _http.close();

  Future<dynamic> _send(
    String method,
    String path, {
    Map<String, String>? query,
    Object? body,
  }) async {
    final uri = Uri.parse('$baseUrl$path').replace(
      queryParameters: query == null || query.isEmpty ? null : query,
    );

    final headers = <String, String>{
      'Accept': 'application/json',
      if (body != null) 'Content-Type': 'application/json',
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
