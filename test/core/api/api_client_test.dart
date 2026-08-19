import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'package:ebpco_user_app/core/api/api_client.dart';
import 'package:ebpco_user_app/core/api/api_exception.dart';

/// Answers with whatever the test sets, so every HTTP outcome can be exercised
/// without a network.
class _FakeClient extends http.BaseClient {
  _FakeClient({this.status = 200, this.body = '{}'});

  int status;
  String body;
  Object? throws;
  Duration? delay;

  http.BaseRequest? lastRequest;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    lastRequest = request;
    if (delay != null) await Future<void>.delayed(delay!);
    if (throws != null) throw throws!;
    return http.StreamedResponse(
      Stream.value(utf8.encode(body)),
      status,
      request: request,
    );
  }
}

void main() {
  group('requests', () {
    test('builds the URL, headers, and JSON body', () async {
      final fake = _FakeClient(body: '{"ok":true}');
      final api = ApiClient(
        baseUrl: 'https://ebpco.example.gov.ph/api',
        httpClient: fake,
        authToken: () async => 'token-123',
      );

      await api.post('/applications', body: {'businessId': 'biz-1'});

      final request = fake.lastRequest! as http.Request;
      expect(request.method, 'POST');
      expect(
        request.url.toString(),
        'https://ebpco.example.gov.ph/api/applications',
      );
      expect(request.headers['Authorization'], 'Bearer token-123');
      expect(request.headers['Content-Type'], contains('application/json'));
      expect(jsonDecode(request.body), {'businessId': 'biz-1'});
    });

    test('omits the Authorization header when signed out', () async {
      final fake = _FakeClient();
      final api = ApiClient(baseUrl: 'https://x', httpClient: fake);

      await api.getObject('/applications');

      expect(fake.lastRequest!.headers.containsKey('Authorization'), isFalse);
    });

    test('asks for the token on every call rather than caching one', () async {
      var issued = 0;
      final fake = _FakeClient();
      final api = ApiClient(
        baseUrl: 'https://x',
        httpClient: fake,
        authToken: () async => 'token-${++issued}',
      );

      await api.getObject('/a');
      await api.getObject('/b');

      // A cached token survives a re-authentication and starts failing; asking
      // each time is what keeps a refreshed session working.
      expect(fake.lastRequest!.headers['Authorization'], 'Bearer token-2');
    });

    test('appends query parameters', () async {
      final fake = _FakeClient(body: '[]');
      final api = ApiClient(baseUrl: 'https://x', httpClient: fake);

      await api.getList('/applications', query: {'status': 'Assessed'});

      expect(fake.lastRequest!.url.query, contains('status=Assessed'));
    });

    test('accepts a list wrapped in a data envelope', () async {
      final fake = _FakeClient(body: '{"data":[{"id":"a"}]}');
      final api = ApiClient(baseUrl: 'https://x', httpClient: fake);

      expect(await api.getList('/applications'), hasLength(1));
    });
  });

  group('failure classification', () {
    Future<ApiException> failureFor(int status) async {
      final api = ApiClient(
        baseUrl: 'https://x',
        httpClient: _FakeClient(status: status, body: '{"error":"nope"}'),
      );
      try {
        await api.getObject('/applications');
      } on ApiException catch (error) {
        return error;
      }
      fail('expected $status to throw');
    }

    test('401 is unauthorized: the session is gone', () async {
      expect((await failureFor(401)).failure, ApiFailure.unauthorized);
    });

    test('403 is forbidden, NOT unauthorized', () async {
      // They used to be merged. The remedies are opposite: signing in again
      // fixes a 401 and achieves nothing for a 403, and sending someone to a
      // login screen for a permissions problem is a loop they cannot escape.
      expect((await failureFor(403)).failure, ApiFailure.forbidden);
    });

    test('a forbidden failure does not offer signing in again', () async {
      expect(ApiFailure.forbidden.applicantMessage, isNot(contains('sign in')));
      expect(ApiFailure.unauthorized.applicantMessage, contains('sign in'));
    });

    test('404 is notFound', () async {
      expect((await failureFor(404)).failure, ApiFailure.notFound);
    });

    test('409 and 422 are rejected', () async {
      expect((await failureFor(409)).failure, ApiFailure.rejected);
      expect((await failureFor(422)).failure, ApiFailure.rejected);
    });

    test('5xx is server', () async {
      expect((await failureFor(500)).failure, ApiFailure.server);
      expect((await failureFor(503)).failure, ApiFailure.server);
    });

    test('a transport error is network, not server', () async {
      final fake = _FakeClient()..throws = http.ClientException('no route');
      final api = ApiClient(baseUrl: 'https://x', httpClient: fake);

      try {
        await api.getObject('/applications');
        fail('expected a throw');
      } on ApiException catch (error) {
        expect(error.failure, ApiFailure.network);
      }
    });

    test('a slow response times out rather than hanging', () async {
      final fake = _FakeClient()..delay = const Duration(seconds: 5);
      final api = ApiClient(
        baseUrl: 'https://x',
        httpClient: fake,
        timeout: const Duration(milliseconds: 50),
      );

      try {
        await api.getObject('/applications');
        fail('expected a timeout');
      } on ApiException catch (error) {
        expect(error.failure, ApiFailure.timeout);
      }
    });

    test('unparseable JSON on a 200 is malformed, not server', () async {
      final api = ApiClient(
        baseUrl: 'https://x',
        httpClient: _FakeClient(body: 'not json at all'),
      );

      try {
        await api.getObject('/applications');
        fail('expected a throw');
      } on ApiException catch (error) {
        // The fault is a contract mismatch, and the fix is code — not an
        // outage the applicant should be told to wait out.
        expect(error.failure, ApiFailure.malformed);
      }
    });

    test('an empty 204 body is not an error', () async {
      final api = ApiClient(
        baseUrl: 'https://x',
        httpClient: _FakeClient(status: 204, body: ''),
      );

      expect(await api.post('/applications/a/instructions/l/resubmit'), isEmpty);
    });
  });

  group('what the applicant is told', () {
    test('never mentions a status code or a stack trace', () {
      for (final failure in ApiFailure.values) {
        final message = failure.applicantMessage;
        expect(message, isNotEmpty, reason: failure.name);
        expect(RegExp(r'\b[45]\d\d\b').hasMatch(message), isFalse,
            reason: '${failure.name} leaks a status code');
        expect(message.toLowerCase(), isNot(contains('exception')),
            reason: failure.name);
      }
    });

    test('only network, timeout, and server are worth retrying', () {
      final transient =
          ApiFailure.values.where((f) => f.isTransient).toSet();
      expect(transient, {
        ApiFailure.network,
        ApiFailure.timeout,
        ApiFailure.server,
      });
    });
  });
}
