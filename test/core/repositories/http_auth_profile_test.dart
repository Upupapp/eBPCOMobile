import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'package:ebpco_user_app/core/api/api_client.dart';
import 'package:ebpco_user_app/core/models/user_model.dart';
import 'package:ebpco_user_app/core/repositories/http_auth_repository.dart';
import 'package:ebpco_user_app/core/services/secure_session_store.dart';

/// The signed-in applicant's own record.
///
/// Found by the same audit that caught the payment and document gaps: the
/// parser filled FOUR of `UserModel`'s fourteen fields. The Profile screen
/// renders every one of them, so an applicant looking at their own record
/// against a live server would have seen no address, no account type, no
/// status and no join date — all of it blank, none of it explained.

class _Canned extends http.BaseClient {
  _Canned(this.body);
  final String body;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async =>
      http.StreamedResponse(
        Stream.value(utf8.encode(body)),
        200,
        headers: {'content-type': 'application/json'},
      );
}

Future<UserModel?> hydrate(Map<String, dynamic> me) {
  final repo = HttpAuthRepository(
    ApiClient(
      baseUrl: 'https://ebpco.example.gov.ph/api',
      httpClient: _Canned(jsonEncode(me)),
    ),
    InMemorySessionStore(),
  );
  return repo.hydrateUser('juan@example.com');
}

void main() {
  test('the whole profile arrives, not four fields of it', () async {
    final user = (await hydrate({
      'firstName': 'Juan',
      'middleName': 'Santos',
      'lastName': 'Dela Cruz',
      'email': 'juan@example.com',
      'mobileNumber': '09171234567',
      'address': '12 Rizal Street',
      'barangay': 'Poblacion',
      'city': 'Castilla',
      'province': 'Sorsogon',
      'zipCode': '4718',
      'accountType': 'Individual Applicant',
      'accountStatus': 'Verified',
      'registeredSince': '2026-01-15T09:00:00+08:00',
    }))!;

    expect(user.fullName, 'Juan Santos Dela Cruz');
    expect(user.mobileNumber, '09171234567');
    expect(
      user.fullAddress,
      '12 Rizal Street, Poblacion, Castilla, Sorsogon, 4718',
    );
    expect(user.accountType, 'Individual Applicant');
    expect(user.accountStatus, AccountStatus.verified);
    expect(user.registeredSince, isNotNull);
  });

  test('an absent account status is Pending, never Verified', () async {
    // Getting this wrong in the safe direction matters. An account shown as
    // Verified that the office has not verified is a claim this app has no
    // basis for; an unnecessary "Pending Verification" costs a question at the
    // counter.
    final user = (await hydrate({
      'firstName': 'Juan',
      'lastName': 'Dela Cruz',
      'email': 'juan@example.com',
    }))!;
    expect(user.accountStatus, AccountStatus.pending);
  });

  test(
    'an unrecognised status is Pending, and does not lock anyone out',
    () async {
      // A profile that failed to load would lock the applicant out of
      // everything, so this deliberately does not throw the way a closed
      // vocabulary would.
      final user = (await hydrate({
        'firstName': 'Juan',
        'lastName': 'Dela Cruz',
        'email': 'juan@example.com',
        'accountStatus': 'Under Adjudication',
      }))!;
      expect(user.accountStatus, AccountStatus.pending);
    },
  );

  test('a sparse profile still parses, with empty strings not nulls', () async {
    final user = (await hydrate({
      'firstName': 'Juan',
      'lastName': 'Dela Cruz',
      'email': 'juan@example.com',
    }))!;
    expect(user.fullAddress, isEmpty);
    expect(user.middleName, isEmpty);
    expect(user.photoPath, isNull);
    expect(user.registeredSince, isNull);
  });
}
