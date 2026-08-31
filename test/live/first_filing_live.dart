// ignore_for_file: avoid_print
//
// This file's whole output is a transcript. A logging framework here would
// route it somewhere a person running it by hand would not look.

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:ebpco_user_app/core/api/api_client.dart';
import 'package:ebpco_user_app/core/api/idempotency_key.dart';
import 'package:ebpco_user_app/core/contract/admin_vocabulary.dart';
import 'package:ebpco_user_app/core/drafts/fencing_permit_draft_codec.dart';
import 'package:ebpco_user_app/core/drafts/form_payload.dart';
import 'package:ebpco_user_app/core/models/application_model.dart';
import 'package:ebpco_user_app/core/models/fencing_permit_model.dart';
import 'package:ebpco_user_app/core/repositories/http_applications_repository.dart';
import 'package:ebpco_user_app/core/repositories/http_auth_repository.dart';
import 'package:ebpco_user_app/core/services/document_storage_service.dart';
import 'package:ebpco_user_app/core/services/secure_session_store.dart';

/// One real filing, against a real server.
///
/// **Named `_live.dart`, not `_test.dart`, so `flutter test` does not collect
/// it.** It needs a running API and it asserts nothing — it prints a
/// transcript. A test that passes whether or not the server answered is
/// exactly the shape this repository has spent the week removing, so this is
/// kept out of the suite rather than made to look like part of it.
///
/// Run it deliberately, against a server you have started:
///
/// ```
/// flutter test test/live/first_filing_live.dart
/// ```
///
/// Findings from the first run are in `docs/FIRST-LIVE-FILING.md`.
const base = 'http://127.0.0.1:3000';
final email =
    'citizen.live.${DateTime.now().millisecondsSinceEpoch}@example.ph';
const password = 'Str0ng-Passphrase-2026!';
// A fresh address each run: registration is idempotent by email, and reusing
// one hides whether a SELF-REGISTERED account can file — which is the whole
// question D-9 asked.

class _MemorySession implements SessionStore {
  String? token;
  String? _refresh;
  @override
  Future<String?> accessToken() async => token;
  @override
  Future<String?> refreshToken() async => _refresh;
  @override
  Future<void> save({
    required String accessToken,
    required String refreshToken,
  }) async {
    token = accessToken;
    _refresh = refreshToken;
  }

  @override
  Future<void> clear() async {
    token = null;
    _refresh = null;
  }
}

void step(String s) => print('\n── $s');

void main() {
  test(
    'one real filing against the live API',
    _run,
    timeout: const Timeout(Duration(minutes: 3)),
  );
}

Future<void> _run() async {
  DocumentStorageService.setRootForTesting('/tmp/ebpco-live-docs');
  // Composed as RepositoryFactory composes it: the client asks the SESSION for
  // a token on every request. Building it without that is how the first run of
  // this script manufactured a defect — /me went out unauthenticated, returned
  // 401, and `authenticate()` correctly reported null, which read as "the
  // password was refused at the moment it was accepted". A live harness that
  // does not reproduce the app's own wiring invents faults.
  final session = _MemorySession();
  var api = ApiClient(baseUrl: base, authToken: session.accessToken);

  step('register');
  try {
    final r = await api.post(
      '/auth/register',
      body: {
        'firstName': 'Maria',
        'lastName': 'Dela Cruz',
        'email': email,
        'mobileNumber': '09171234567',
        'password': password,
      },
      idempotencyKey: newIdempotencyKey(),
    );
    print(
      '  ok: ${jsonEncode(r).substring(0, r.toString().length.clamp(0, 160))}',
    );
  } catch (e) {
    print('  $e');
  }

  step('sign in — through the app\'s own repository, not a hand-rolled body');
  // The first attempt here posted /auth/token directly and got a 400 for a
  // missing `grantType`. That was MY script, not the app: the repository has
  // sent `grantType: 'password'` all along. Exercising the repository is the
  // whole point — a hand-rolled request tests nothing the app actually does.
  String? token;
  final auth = HttpAuthRepository(api, session);
  try {
    final user = await auth.authenticate(email: email, password: password);
    token = session.token;
    print('  user: ${user?.email ?? "NULL"}');
    print('  token: ${token == null ? "NONE" : "${token.substring(0, 12)}…"}');
  } catch (e) {
    print('  $e');
  }
  if (token == null) return;

  final repo = HttpApplicationsRepository(api);

  step('GET /me');
  try {
    print('  ${(await api.getObject('/me')).keys.toList()}');
  } catch (e) {
    print('  $e');
  }

  step(
    'POST /applications — the whole wizard, on the one permit type the '
    'server currently issues',
  );
  // Certificate of Occupancy is spelled identically in both vocabularies, so
  // it is the only one of the app's nineteen that files today. D-10 is ruled
  // and the seed has not moved yet; using this one measures everything PAST
  // submission without waiting for it.
  final draft = FencingPermitDraft();
  // The fencing draft is still what fills `form`: the payload is the wizard's
  // field set, and which wizard it came from is not what is being measured
  // here — that the 239 fields arrive is.
  draft.applicant.firstName = 'Maria';
  draft.applicant.lastName = 'Dela Cruz';
  draft.constructionLocation.lotNumber = '12';
  draft.constructionLocation.barangay = 'Bagumbayan';
  ApplicationModel? filed;
  try {
    filed = await repo.submitApplication(
      businessId: '',
      businessName: 'Maria Dela Cruz',
      type: ApplicationType.newPermit,
      documents: const [],
      permitTypeLabel: CanonicalPermitType.certificateOfOccupancy.wire,
      location: 'Lot 12, Barangay Bagumbayan, Castilla, Sorsogon',
      form: permitFormPayload(const FencingPermitDraftCodec(), draft),
    );
    print('  FILED: ${filed.applicationNumber}  id=${filed.id}');
    print('  status: ${filed.lifecycleStatus?.name}');
  } catch (e) {
    print('  REFUSED: $e');
  }

  step('GET /applications — the list read');
  try {
    final rows = await repo.fetchAll();
    print('  ${rows.length} row(s)');
    for (final r in rows) {
      print(
        '    ${r.applicationNumber} | ${r.permitTypeLabel} | '
        'openInstructionCount=${r.openInstructionCount} | '
        'instructions=${r.instructions.length}',
      );
    }
  } catch (e) {
    print('  $e');
  }

  if (filed == null) return;
  step('GET /applications/{id} — the detail read');
  try {
    final d = await repo.fetchDetail(filed.id);
    print(
      '  instructions=${d.instructions.length} evaluations=${d.evaluations.length} '
      'timeline=${d.timeline.length} permit=${d.permit != null} release=${d.release != null}',
    );
  } catch (e) {
    print('  $e');
  }
}
