import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:ebpco_user_app/core/api/api_client.dart';
import 'package:ebpco_user_app/core/repositories/auth_repository.dart';
import 'package:ebpco_user_app/core/repositories/http_auth_repository.dart';
import 'package:ebpco_user_app/core/services/secure_session_store.dart';

/// `PATCH /me`, measured in bytes rather than described in prose.
///
/// The distinction the whole endpoint turns on cannot be seen from a Dart
/// signature: **absent leaves a field alone, null clears it.** A body built
/// with `if (value != null)` would look correct, pass a shape test, and
/// silently drop every clear — leaving a citizen unable to remove a middle
/// name they typed by mistake or never had. So this reads the recorded body.

/// Records what the client sent, and answers as the server does.
class _Stub {
  _Stub(this._server, {this.mobileCleared = false}) {
    _server.listen((request) async {
      method = request.method;
      path = request.uri.path;
      body =
          jsonDecode(await utf8.decoder.bind(request).join())
              as Map<String, Object?>;
      request.response
        ..statusCode = 200
        ..headers.contentType = ContentType.json
        ..write(
          jsonEncode({
            'firstName': 'Juan',
            'middleName': null,
            'lastName': 'dela Cruz',
            'email': 'juan@example.ph',
            'mobileNumber': body['mobileNumber'] ?? '09171234567',
            'street': body['street'],
            'barangay': 'Bagalayag',
            'city': 'Castilla',
            'province': 'Sorsogon',
            'postalCode': body['postalCode'],
            'accountType': 'Individual Applicant',
            'accountStatus': 'verified',
            'mobileVerifiedAt': null,
            'mobileVerificationCleared': mobileCleared,
          }),
        );
      await request.response.close();
    });
  }

  final HttpServer _server;
  final bool mobileCleared;
  String? method;
  String? path;
  Map<String, Object?> body = {};
  String get baseUrl => 'http://127.0.0.1:${_server.port}';
  static Future<_Stub> start({bool mobileCleared = false}) async => _Stub(
    await HttpServer.bind(InternetAddress.loopbackIPv4, 0),
    mobileCleared: mobileCleared,
  );
  Future<void> stop() => _server.close(force: true);
}

class _Session implements SessionStore {
  @override
  Future<String?> accessToken() async => 'a-token';
  @override
  Future<String?> refreshToken() async => 'r';
  @override
  Future<void> save({
    required String accessToken,
    required String refreshToken,
  }) async {}
  @override
  Future<void> clear() async {}
}

void main() {
  late _Stub stub;
  late HttpAuthRepository repository;

  Future<void> boot({bool mobileCleared = false}) async {
    stub = await _Stub.start(mobileCleared: mobileCleared);
    final session = _Session();
    repository = HttpAuthRepository(
      ApiClient(baseUrl: stub.baseUrl, authToken: session.accessToken),
      session,
    );
  }

  tearDown(() => stub.stop());

  test('an absent field is not sent at all', () async {
    await boot();
    await repository.updateProfile(firstName: const FieldEdit.set('Juan'));

    expect(stub.method, 'PATCH');
    expect(stub.path, '/me');
    expect(stub.body.keys, ['firstName']);
    expect(
      stub.body.containsKey('middleName'),
      isFalse,
      reason: 'absent means leave it alone, so the key must not appear',
    );
  });

  test('a cleared field is sent as an explicit null', () async {
    await boot();
    await repository.updateProfile(middleName: const FieldEdit.clear());

    expect(
      stub.body.containsKey('middleName'),
      isTrue,
      reason: 'clearing requires the key to be present',
    );
    expect(
      stub.body['middleName'],
      isNull,
      reason:
          'a body built with `if (value != null)` drops this and the citizen '
          'can never remove a middle name they do not have',
    );
  });

  test('a blank box from the citizen clears the field', () async {
    await boot();
    await repository.updateProfile(
      middleName: FieldEdit.fromInput('   '),
      street: FieldEdit.fromInput('24 Rizal Street'),
    );

    expect(stub.body['middleName'], isNull);
    expect(stub.body['street'], '24 Rizal Street');
  });

  test('the address goes out as street, the name the server uses', () async {
    await boot();
    await repository.updateProfile(
      street: FieldEdit.fromInput('24 Rizal Street'),
      postalCode: FieldEdit.fromInput('4713'),
    );

    expect(stub.body['street'], '24 Rizal Street');
    expect(
      stub.body.containsKey('address'),
      isFalse,
      reason: 'this app called it address; businesses already called it street',
    );
    expect(stub.body['postalCode'], '4713');
    expect(stub.body.containsKey('zipCode'), isFalse);
  });

  test('email is never sent, whatever the caller does', () async {
    await boot();
    await repository.updateProfile(
      firstName: const FieldEdit.set('Juan'),
      lastName: const FieldEdit.set('dela Cruz'),
      mobileNumber: const FieldEdit.set('09171234567'),
      street: const FieldEdit.set('24 Rizal Street'),
      barangay: const FieldEdit.set('Bagalayag'),
      city: const FieldEdit.set('Castilla'),
      province: const FieldEdit.set('Sorsogon'),
      postalCode: const FieldEdit.set('4713'),
      middleName: const FieldEdit.clear(),
    );

    expect(
      stub.body.containsKey('email'),
      isFalse,
      reason:
          'the sign-in identity: changing it transfers who can reach the '
          'account, and the server answers 400 rather than ignoring it',
    );
  });

  test('a mobile change reports that verification was cleared', () async {
    // Read from the server, not inferred by comparing numbers: the server
    // also deletes pending challenges against the OLD number, and only it
    // knows it did that.
    await boot(mobileCleared: true);
    final update = await repository.updateProfile(
      mobileNumber: const FieldEdit.set('09998887777'),
    );

    expect(update.mobileVerificationCleared, isTrue);
    expect(update.user.mobileNumber, '09998887777');
  });

  test('a null from the server is kept as not-recorded, not blanked', () async {
    await boot();
    final update = await repository.updateProfile(
      postalCode: const FieldEdit.clear(),
    );

    expect(
      update.user.postalCode,
      isNull,
      reason:
          'null means NOT RECORDED; collapsing it to an empty string tells a '
          'citizen they left it blank when nobody ever asked them',
    );
    expect(update.user.middleName, '');
  });
}
