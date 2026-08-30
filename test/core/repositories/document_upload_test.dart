import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:ebpco_user_app/core/api/api_client.dart';
import 'package:ebpco_user_app/core/api/api_exception.dart';
import 'package:ebpco_user_app/core/models/document_model.dart';
import 'package:ebpco_user_app/core/repositories/document_upload_repository.dart';

/// `POST /documents` — the half of the write path that did not exist.
///
/// Two of M-47's six divergences were this one gap seen from two request
/// bodies: the app sent a document's label and filename because it had no way
/// to produce the `documentIds` the contract asks for.
///
/// These run against a fake `http.Client` rather than a mock repository, so
/// what is asserted is the actual multipart request that would go on the wire.

DocumentModel _picked(String path) => DocumentModel(
  id: 'local',
  label: 'Land Title',
  fileName: 'land-title.pdf',
  uploadedAt: DateTime(2026, 8, 30),
  filePath: path,
);

const _response = {
  'id': '6f1a2b3c-4d5e-4f60-8a1b-2c3d4e5f6071',
  'label': 'Land Title',
  'fileName': 'land-title.pdf',
  'uploadedAt': '2026-08-30T09:00:00Z',
  'status': 'Pending',
  'scanCleared': false,
  'byteSize': 12,
  'contentType': 'application/pdf',
};

void main() {
  late Directory temp;
  late File file;

  setUp(() {
    temp = Directory.systemTemp.createTempSync('ebpco-upload');
    file = File('${temp.path}/land-title.pdf')..writeAsStringSync('%PDF-1.7\n');
  });
  tearDown(() => temp.deleteSync(recursive: true));

  /// `MockClient` hands the handler an `http.Request` whose body has already
  /// been read off the multipart stream, so the payload is inspected from
  /// `request.body` rather than by finalizing it again — a second `finalize()`
  /// throws, which is how the first version of these tests failed.
  ApiClient clientReturning(
    Map<String, Object?> body, {
    int status = 201,
    void Function(http.Request request)? inspect,
  }) => ApiClient(
    baseUrl: 'https://api.example.gov.ph',
    authToken: () async => 'token-123',
    httpClient: MockClient((request) async {
      inspect?.call(request);
      return http.Response(jsonEncode(body), status);
    }),
  );

  test('the file, the label and the bearer token all reach the wire', () async {
    late http.Request seen;
    final api = clientReturning(
      _response,
      inspect: (request) => seen = request,
    );

    await HttpDocumentUploadRepository(api).upload(_picked(file.path));

    expect(seen.url.path, '/documents');
    expect(seen.method, 'POST');
    expect(seen.headers['Authorization'], 'Bearer token-123');
    expect(
      seen.headers['Content-Type'],
      startsWith('multipart/form-data'),
      reason: 'the contract declares multipart/form-data, not JSON',
    );
    final payload = seen.body;
    expect(payload, contains('name="label"'));
    expect(payload, contains('Land Title'));
    expect(payload, contains('name="file"'));
    expect(
      payload,
      contains('%PDF-1.7'),
      reason: 'the bytes themselves, not a filename standing in for them',
    );
  });

  test('the required Idempotency-Key header is sent, and is a uuid', () async {
    // Required on every POST an applicant can make, and sent on none of them
    // until M-47. Without it a retry after a timeout is a second upload.
    late http.Request seen;
    final api = clientReturning(_response, inspect: (r) => seen = r);
    await HttpDocumentUploadRepository(api).upload(_picked(file.path));

    expect(
      seen.headers['Idempotency-Key'],
      matches(
        RegExp(
          r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-'
          r'[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
        ),
      ),
    );
  });

  test(
    'a caller retrying reuses its key rather than uploading twice',
    () async {
      final keys = <String>[];
      final api = clientReturning(
        _response,
        inspect: (r) => keys.add(r.headers['Idempotency-Key']!),
      );
      final repository = HttpDocumentUploadRepository(api);
      const key = '11111111-2222-4333-8444-555555555555';

      await repository.upload(_picked(file.path), idempotencyKey: key);
      await repository.upload(_picked(file.path), idempotencyKey: key);

      expect(keys, [
        key,
        key,
      ], reason: 'the server returns the original result');
    },
  );

  test('the id comes back, which is the whole point', () async {
    final uploaded = await HttpDocumentUploadRepository(
      clientReturning(_response),
    ).upload(_picked(file.path));

    expect(uploaded.id, '6f1a2b3c-4d5e-4f60-8a1b-2c3d4e5f6071');
    expect(uploaded.fileName, 'land-title.pdf');
    expect(uploaded.contentType, 'application/pdf');
  });

  test('scanCleared is false until the scanner says otherwise', () async {
    // `201` does NOT mean the office can open the file. Absent means not
    // cleared: the safe reading of a missing flag is the one that does not
    // tell an applicant their document is with the office.
    final uploaded = await HttpDocumentUploadRepository(
      clientReturning(_response),
    ).upload(_picked(file.path));
    expect(uploaded.scanCleared, isFalse);

    final withoutFlag = Map<String, Object?>.from(_response)
      ..remove('scanCleared');
    expect(
      (await HttpDocumentUploadRepository(
        clientReturning(withoutFlag),
      ).upload(_picked(file.path))).scanCleared,
      isFalse,
    );
  });

  test('a response with no id is a failure, not an empty id', () async {
    final api = clientReturning(
      Map<String, Object?>.from(_response)..remove('id'),
    );
    expect(
      () => HttpDocumentUploadRepository(api).upload(_picked(file.path)),
      throwsA(
        isA<ApiException>().having(
          (e) => e.failure,
          'failure',
          ApiFailure.malformed,
        ),
      ),
    );
  });

  group('the failures an applicant can act on', () {
    test('413 is too large, and says what to do about it', () async {
      final api = clientReturning(const {}, status: 413);
      await expectLater(
        () => HttpDocumentUploadRepository(api).upload(_picked(file.path)),
        throwsA(
          isA<ApiException>().having(
            (e) => e.failure,
            'failure',
            ApiFailure.tooLarge,
          ),
        ),
      );
      expect(
        ApiFailure.tooLarge.applicantMessage,
        contains('lower resolution'),
        reason: '"check your details and try again" is useless advice for it',
      );
    });

    test('415 is the wrong type, and renaming will not help', () async {
      final api = clientReturning(const {}, status: 415);
      await expectLater(
        () => HttpDocumentUploadRepository(api).upload(_picked(file.path)),
        throwsA(
          isA<ApiException>().having(
            (e) => e.failure,
            'failure',
            ApiFailure.unsupportedMedia,
          ),
        ),
      );
      expect(
        ApiFailure.unsupportedMedia.applicantMessage,
        contains('renaming the file will not help'),
        reason:
            'the server inspects magic bytes, so the extension is irrelevant '
            'and advice that ignores that sends the applicant in circles',
      );
    });

    test('a file that is gone is refused before the request is made', () async {
      var called = false;
      final api = ApiClient(
        baseUrl: 'https://api.example.gov.ph',
        httpClient: MockClient((_) async {
          called = true;
          return http.Response('{}', 201);
        }),
      );
      await expectLater(
        () => HttpDocumentUploadRepository(
          api,
        ).upload(_picked('${temp.path}/never-existed.pdf')),
        throwsA(isA<ApiException>()),
      );
      expect(called, isFalse, reason: 'nothing should have been sent');
    });

    test('an attachment with no file on the device is refused', () async {
      // The prototype fabricates DocumentModels when the applicant taps Upload
      // without a real picker behind it. Uploading one would put an id in the
      // submission for a file the office never received.
      final api = clientReturning(_response);
      expect(
        () => HttpDocumentUploadRepository(api).upload(
          DocumentModel(
            id: 'mock',
            label: 'Land Title',
            fileName: 'land-title.pdf',
            uploadedAt: DateTime(2026, 8, 30),
          ),
        ),
        throwsA(isA<ApiException>()),
      );
    });
  });

  test('a build with no server refuses rather than fabricating an id', () {
    // The worst possible mock: the submission succeeds, the office holds a
    // reference to nothing, and the applicant is told their documents arrived.
    expect(
      () => const UnavailableDocumentUploadRepository().upload(
        _picked(file.path),
      ),
      throwsA(isA<ApiException>()),
    );
  });
}
