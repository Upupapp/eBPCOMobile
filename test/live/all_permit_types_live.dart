// ignore_for_file: avoid_print
//
// A transcript, not a test. See first_filing_live.dart for why these live
// under `_live.dart` and are not collected by the suite.

import 'package:flutter_test/flutter_test.dart';

import 'package:ebpco_user_app/core/api/api_client.dart';
import 'package:ebpco_user_app/core/api/api_exception.dart';
import 'package:ebpco_user_app/core/contract/admin_vocabulary.dart';
import 'package:ebpco_user_app/core/models/application_model.dart';
import 'package:ebpco_user_app/core/repositories/http_applications_repository.dart';
import 'package:ebpco_user_app/core/repositories/http_auth_repository.dart';
import 'package:ebpco_user_app/core/services/secure_session_store.dart';

/// Files one application of **every** permit type the app offers, and reports
/// which the server accepts.
///
/// This is the measure D-10 named. `application_submission_test.dart` asserts
/// how many of the nineteen the CONTRACT accepts, from a vendored schema; this
/// asks the same question of a running server, which is the only place the
/// answer is real.
///
/// Run it against a server you have started:
///
/// ```
/// flutter test test/live/all_permit_types_live.dart
/// ```
///
/// Expected today: **1 of 19**. Expected once the `permit_types` seed carries
/// the office's own names: **19 of 19**.

const base = 'http://127.0.0.1:3000';
const password = 'Str0ng-Passphrase-2026!';

class _Session implements SessionStore {
  String? _access;
  String? _refresh;
  @override
  Future<String?> accessToken() async => _access;
  @override
  Future<String?> refreshToken() async => _refresh;
  @override
  Future<void> save({
    required String accessToken,
    required String refreshToken,
  }) async {
    _access = accessToken;
    _refresh = refreshToken;
  }

  @override
  Future<void> clear() async {
    _access = null;
    _refresh = null;
  }
}

void main() {
  test(
    'every permit type the app offers, against the server',
    _run,
    timeout: const Timeout(Duration(minutes: 5)),
  );
}

Future<void> _run() async {
  final email =
      'citizen.all.${DateTime.now().millisecondsSinceEpoch}'
      '@example.ph';
  final session = _Session();
  final api = ApiClient(baseUrl: base, authToken: session.accessToken);
  final auth = HttpAuthRepository(api, session);
  final repo = HttpApplicationsRepository(api);

  await auth.registerAccount(
    firstName: 'Maria',
    lastName: 'Dela Cruz',
    email: email,
    mobileNumber: '09171234567',
    password: password,
  );
  final user = await auth.authenticate(email: email, password: password);
  if (user == null) {
    print('could not sign in — is the server running on $base?');
    return;
  }

  final accepted = <String>[];
  final refused = <String, String>{};

  for (final type in CanonicalPermitType.values) {
    try {
      await repo.submitApplication(
        businessId: '',
        businessName: 'Maria Dela Cruz',
        type: ApplicationType.newPermit,
        documents: const [],
        permitTypeLabel: type.wire,
        location: 'Lot 12, Barangay Bagumbayan, Castilla, Sorsogon',
      );
      accepted.add(type.wire);
    } on ApiException catch (error) {
      // The detail is the useful half: a 422 naming the permit is a
      // vocabulary miss, anything else is a different problem wearing the
      // same status code.
      // `problem` is the structured RFC 7807 body when the server sent one,
      // which is the useful half: a 422 naming the permit is a vocabulary
      // miss, anything else is a different problem wearing the same status.
      refused[type.wire] =
          error.problem?.detail ?? error.detail.split('\n').first;
    }
  }

  print(
    '\n── accepted: ${accepted.length} of '
    '${CanonicalPermitType.values.length}',
  );
  for (final a in accepted) {
    print('   ✓ $a');
  }
  print('\n── refused: ${refused.length}');
  refused.forEach((type, why) => print('   ✗ ${type.padRight(42)} $why'));

  print(
    '\n${accepted.length} of ${CanonicalPermitType.values.length}. '
    'D-10 is done when this reads '
    '${CanonicalPermitType.values.length} of '
    '${CanonicalPermitType.values.length}.',
  );
}
