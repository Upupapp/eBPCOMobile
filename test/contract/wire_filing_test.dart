import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:ebpco_user_app/core/api/api_client.dart';
import 'package:ebpco_user_app/core/contract/admin_vocabulary.dart';
import 'package:ebpco_user_app/core/drafts/fencing_permit_draft_codec.dart';
import 'package:ebpco_user_app/core/drafts/form_payload.dart';
import 'package:ebpco_user_app/core/models/application_model.dart';
import 'package:ebpco_user_app/core/models/fencing_permit_model.dart';
import 'package:ebpco_user_app/core/repositories/http_applications_repository.dart';
import 'package:ebpco_user_app/core/services/document_storage_service.dart';

/// One filing, watched over a real socket.
///
/// **Every other test of the write path is a claim about source code.**
/// `application_submission_test.dart` — the gate that has caught four
/// divergences — reads `http_applications_repository.dart` with a regular
/// expression and counts the quoted keys. That is a good gate and it is not
/// this: it cannot see a header, a serialisation, an encoding, or a response
/// the app cannot parse. It asserts what the source looks like.
///
/// The closing sweep of 31 August 2026 recommended one filing against a
/// staging server, watched end to end, on the grounds that every defect found
/// that week lived between the wizard and the wire and survived a green suite
/// because nothing on the other side could contradict it. **A staging server
/// is blocked on B-1. A socket is not.**
///
/// So this binds a real `HttpServer` on the loopback interface, points the
/// real `ApiClient` at it, files through the real repository, and inspects the
/// bytes that actually arrive. It is the same shape as the recommendation,
/// minus the deployment.
///
/// What it would have caught, each of which shipped: `serviceDomain` absent;
/// `location` absent; `form` absent; `Idempotency-Key` absent; `businessId`
/// sent as `''` where the contract types a uuid or null.

/// One request, as the server received it.
class _Received {
  _Received(this.method, this.path, this.headers, this.body);
  final String method;
  final String path;
  final Map<String, String> headers;
  final Map<String, dynamic> body;
}

/// A server that records what it is sent and answers from the contract.
class _WireStub {
  _WireStub(this._server) {
    _server.listen((request) async {
      final raw = await utf8.decoder.bind(request).join();
      received.add(
        _Received(request.method, request.uri.path, {
          for (final name in const [
            'idempotency-key',
            'content-type',
            'accept',
          ])
            if (request.headers.value(name) != null)
              name: request.headers.value(name)!,
        }, raw.isEmpty ? const {} : jsonDecode(raw) as Map<String, dynamic>),
      );
      final body = switch ((request.method, request.uri.path)) {
        ('GET', '/applications') => {
          'data': [_summaryRow],
        },
        ('GET', final path) when path.startsWith('/applications/') =>
          _detailRow,
        _ => _filedApplication,
      };
      request.response
        ..statusCode = request.method == 'POST' ? 201 : 200
        ..headers.contentType = ContentType.json
        ..write(jsonEncode(body));
      await request.response.close();
    });
  }

  final HttpServer _server;
  final List<_Received> received = [];

  String get baseUrl => 'http://127.0.0.1:${_server.port}';

  static Future<_WireStub> start() async =>
      _WireStub(await HttpServer.bind(InternetAddress.loopbackIPv4, 0));

  Future<void> stop() => _server.close(force: true);
}

/// The response an office would send back, shaped as the contract declares it.
const _filedApplication = {
  'id': '7c1d4b62-0a6f-4d5e-9d1f-2b3c4d5e6f70',
  'referenceNumber': 'E-BPCO-2026-000145',
  'applicationAction': 'New',
  'permitType': 'Fencing Permit',
  'lifecycleStatus': 'Submitted',
  'dateSubmitted': '2026-08-31T02:10:00.000Z',
};

/// What a LIST payload may legitimately carry: the scalars, and none of the
/// sub-objects. Every optional field on the shared schema is omitted, which a
/// conforming server is entitled to do.
const _summaryRow = {
  'id': '7c1d4b62-0a6f-4d5e-9d1f-2b3c4d5e6f70',
  'referenceNumber': 'E-BPCO-2026-000145',
  'applicationAction': 'New',
  'permitType': 'Fencing Permit',
  'lifecycleStatus': 'Revision Required',
  'dateSubmitted': '2026-08-31T02:10:00.000Z',
  // The scalar the Home action stack is computed from.
  'openInstructionCount': 3,
};

/// And what `GET /applications/{id}` adds — "One application in full".
const _detailRow = {
  ..._summaryRow,
  'instructions': [
    {
      'id': 'loi-1',
      'issuedAt': '2026-08-25T01:00:00.000Z',
      'items': [
        {
          'id': 'item-1',
          'subject': 'Structural computations',
          'remark': 'Unsigned and unsealed. Resubmit signed and sealed.',
        },
      ],
    },
  ],
};

FencingPermitDraft _draft() {
  final draft = FencingPermitDraft();
  draft.applicant.firstName = 'Maria';
  draft.applicant.lastName = 'Dela Cruz';
  draft.constructionLocation.lotNumber = '12';
  draft.constructionLocation.barangay = 'Bagumbayan';
  return draft;
}

void main() {
  late _WireStub stub;
  late HttpApplicationsRepository repository;

  final schema =
      jsonDecode(
            File(
              'test/contract/application-submission.json',
            ).readAsStringSync(),
          )
          as Map<String, dynamic>;
  List<String> listOf(String key) => (schema[key] as List).cast<String>();

  setUp(() async {
    DocumentStorageService.setRootForTesting('/tmp/ebpco-wire-docs');
    stub = await _WireStub.start();
    repository = HttpApplicationsRepository(ApiClient(baseUrl: stub.baseUrl));
  });

  tearDown(() async {
    DocumentStorageService.setRootForTesting(null);
    await stub.stop();
  });

  Future<ApplicationModel> file() => repository.submitApplication(
    businessId: '',
    businessName: 'Maria Dela Cruz',
    type: ApplicationType.newPermit,
    documents: const [],
    permitTypeLabel: CanonicalPermitType.fencingPermit.wire,
    location: 'Lot 12, Barangay Bagumbayan, Castilla, Sorsogon',
    form: permitFormPayload(const FencingPermitDraftCodec(), _draft()),
  );

  test('the filing reaches the wire at all', () async {
    // The vacuity guard. Everything below reads `stub.received.single`, and a
    // repository that threw before sending would make them all pass against
    // nothing.
    await file();
    expect(stub.received, hasLength(1));
    expect(stub.received.single.method, 'POST');
    expect(stub.received.single.path, '/applications');
  });

  test('every required field is on the wire, not just in the source', () async {
    await file();
    final body = stub.received.single.body;
    for (final field in listOf('required')) {
      expect(
        body.containsKey(field),
        isTrue,
        reason:
            '$field is required by the contract and did not arrive. '
            'serviceDomain was absent from every filing this app made until '
            '30 August 2026, and a conforming server refuses the submission',
      );
      expect(body[field], isNotNull);
    }
  });

  test('and nothing undeclared arrives with it', () async {
    // `additionalProperties: false`. One undeclared key rejects the whole
    // filing — which is why the lineage reference is deliberately not sent.
    await file();
    final undeclared = stub.received.single.body.keys
        .where((key) => !listOf('properties').contains(key))
        .toList();
    expect(
      undeclared,
      isEmpty,
      reason:
          'these would cost the applicant their filing: $undeclared. The '
          'contract closes this object',
    );
  });

  test('the applicant\'s answers arrive, and are the wizard\'s own', () async {
    // The defect closed on 31 August: a filing carried the permit type, the
    // applicant and the site, and none of the nine steps behind them.
    await file();
    final form = stub.received.single.body['form'] as Map<String, dynamic>;
    expect(form['applicant.firstName'], 'Maria');
    expect(form['constructionLocation.barangay'], 'Bagumbayan');
    expect(form.length, greaterThan(30));
  });

  test('the site arrives as one line', () async {
    await file();
    expect(
      stub.received.single.body['location'],
      'Lot 12, Barangay Bagumbayan, Castilla, Sorsogon',
    );
  });

  test('businessId is null, never an empty string', () async {
    // The contract types it as a uuid or null. `''` is neither, and it was
    // sent that way until 30 August.
    await file();
    final body = stub.received.single.body;
    expect(body.containsKey('businessId'), isTrue);
    expect(body['businessId'], isNull);
  });

  test('the required header arrives — which no body gate can see', () async {
    // The third divergence class. A body-diff gate is blind to a missing
    // required HEADER, and `Idempotency-Key` is required on eight operations.
    // The case that matters is a filing whose response was lost on a dropped
    // connection: replaying must return the original application rather than
    // create a second one.
    await file();
    final key = stub.received.single.headers['idempotency-key'];
    expect(key, isNotNull, reason: 'no Idempotency-Key on a filing');
    expect(
      key,
      matches(
        RegExp(
          r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-'
          r'[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
        ),
      ),
      reason: 'the contract asks for format: uuid — a v4, with its bits set',
    );
    expect(stub.received.single.headers['content-type'], contains('json'));
  });

  test('a fresh filing gets a fresh key', () async {
    // Per operation, not per app run. Two filings sharing a key would let a
    // server treat the second as a replay of the first and return the wrong
    // application.
    await file();
    await file();
    expect(
      stub.received[0].headers['idempotency-key'],
      isNot(stub.received[1].headers['idempotency-key']),
    );
  });

  group('the read path, which is where the promises are cashed', () {
    test('a list row carries the count and none of the letters', () async {
      // Not a hypothetical: the contract makes every sub-object optional, and
      // `ApplicationDto.parse` has always said "a summary payload may omit the
      // letters themselves".
      final rows = await repository.fetchAll();
      expect(rows.single.openInstructionCount, 3);
      expect(
        rows.single.instructions,
        isEmpty,
        reason: 'the list omitted them, as it is entitled to',
      );
      expect(
        rows.single.openInstruction,
        isNull,
        reason:
            'and this is the gap the app shipped with: Home promises "3 items '
            'must be corrected" from the count, and the banner that routes to '
            'the letter is guarded on THIS being non-null',
      );
    });

    test('and the detail read supplies them', () async {
      // The call that existed on the HTTP repository and could not be made,
      // because the interface every caller holds did not declare it.
      final detail = await repository.fetchDetail(
        '7c1d4b62-0a6f-4d5e-9d1f-2b3c4d5e6f70',
      );
      expect(detail.instructions, hasLength(1));
      expect(detail.openInstruction, isNotNull);
      expect(
        detail.openInstruction!.items.single.remark,
        'Unsigned and unsealed. Resubmit signed and sealed.',
      );
    });

    test('the two reads are different requests, to different paths', () async {
      await repository.fetchAll();
      await repository.fetchDetail('7c1d4b62-0a6f-4d5e-9d1f-2b3c4d5e6f70');
      expect(stub.received.map((r) => r.path), [
        '/applications',
        '/applications/7c1d4b62-0a6f-4d5e-9d1f-2b3c4d5e6f70',
      ]);
    });
  });

  test('and the office\'s answer parses back into a record', () async {
    // The other half of end-to-end: a body that goes out correctly and comes
    // back unreadable is still a failed filing.
    final filed = await file();
    expect(filed.id, '7c1d4b62-0a6f-4d5e-9d1f-2b3c4d5e6f70');
    expect(filed.applicationNumber, 'E-BPCO-2026-000145');
    expect(filed.permitTypeLabel, 'Fencing Permit');
    expect(filed.lifecycleStatus, isNotNull);
  });
}
