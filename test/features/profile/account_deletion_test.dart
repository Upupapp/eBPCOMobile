import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:ebpco_user_app/core/api/api_client.dart';
import 'package:ebpco_user_app/core/repositories/http_auth_repository.dart';
import 'package:ebpco_user_app/core/services/secure_session_store.dart';

/// In-app account deletion — Apple Guideline 5.1.1(v), RA 10173 §16(e).
///
/// **This was filed as a certain App Store rejection and it was not one.** The
/// mobile lane reported that the contract declares no DELETE operation, so
/// deletion could not be built client-side. The backend lane answered that
/// `DELETE /me` has existed all along, and a call against the running server
/// confirmed it:
///
/// ```
/// DELETE /me            → 202
/// GET    /me afterwards → 401
/// ```
///
/// The contract is the stale party. The lesson is the same one this repository
/// keeps relearning from the other direction: **the contract is a description,
/// and a description can be wrong about the thing it describes.** A grep of
/// the specification said the operation did not exist; the server said it did.

/// Records what the client sent, and answers as the real server does.
class _Stub {
  _Stub(this._server) {
    _server.listen((request) async {
      calls.add('${request.method} ${request.uri.path}');
      headers.add(request.headers.value('idempotency-key'));
      request.response.statusCode = request.method == 'DELETE' ? 202 : 200;
      if (request.method != 'DELETE') {
        request.response
          ..headers.contentType = ContentType.json
          ..write(jsonEncode({'email': 'citizen@example.ph'}));
      }
      // 202 with NO BODY, which is what the server sends and what broke a
      // first draft that insisted on parsing an object.
      await request.response.close();
    });
  }

  final HttpServer _server;
  final List<String> calls = [];
  final List<String?> headers = [];
  String get baseUrl => 'http://127.0.0.1:${_server.port}';
  static Future<_Stub> start() async =>
      _Stub(await HttpServer.bind(InternetAddress.loopbackIPv4, 0));
  Future<void> stop() => _server.close(force: true);
}

class _Session implements SessionStore {
  String? token = 'a-token';
  bool cleared = false;

  @override
  Future<String?> accessToken() async => token;
  @override
  Future<String?> refreshToken() async => 'r';
  @override
  Future<void> save({
    required String accessToken,
    required String refreshToken,
  }) async => token = accessToken;
  @override
  Future<void> clear() async {
    cleared = true;
    token = null;
  }
}

void main() {
  late _Stub stub;
  late _Session session;
  late HttpAuthRepository repository;

  setUp(() async {
    stub = await _Stub.start();
    session = _Session();
    repository = HttpAuthRepository(
      ApiClient(baseUrl: stub.baseUrl, authToken: session.accessToken),
      session,
    );
  });

  tearDown(() => stub.stop());

  test('it calls DELETE /me', () async {
    await repository.deleteAccount();
    expect(stub.calls, ['DELETE /me']);
  });

  test('a 202 with no body is success, not a parse failure', () async {
    // The server queues erasure rather than performing it inline, which is
    // what RA 10173 §16(e) asks for. A client that demanded a JSON object
    // would turn a correct deletion into an error the citizen sees.
    await expectLater(repository.deleteAccount(), completes);
  });

  test('it carries an idempotency key', () async {
    // Deleting twice must not be two deletions, and a citizen on a bad
    // connection will tap twice.
    await repository.deleteAccount();
    expect(stub.headers.single, isNotNull);
    expect(
      stub.headers.single,
      matches(
        RegExp(
          r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-'
          r'[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
        ),
      ),
    );
  });

  test('and the local session goes with it', () async {
    // Measured against the real server: the token is invalid immediately
    // afterwards. Leaving it on the device means the next screen fails with a
    // 401 the citizen cannot explain.
    await repository.deleteAccount();
    expect(session.cleared, isTrue);
    expect(await session.accessToken(), isNull);
  });

  test('the control exists on the screen a citizen can reach', () {
    // 5.1.1(v) is about reachability, not capability: a repository method
    // nobody can invoke does not satisfy it.
    final profile = File(
      'lib/features/profile/presentation/profile_screen.dart',
    ).readAsStringSync();
    expect(profile, contains("'Delete Account'"));
    expect(profile, contains('_handleDeleteAccount'));
    expect(
      profile,
      contains('remain public records'),
      reason:
          'a citizen deleting an account must be told that a permit already '
          'issued is a public record and does not go with it',
    );
  });
}
