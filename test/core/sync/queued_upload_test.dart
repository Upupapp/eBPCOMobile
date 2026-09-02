import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:ebpco_user_app/core/api/api_client.dart';
import 'package:ebpco_user_app/core/api/api_exception.dart';
import 'package:ebpco_user_app/core/models/document_model.dart';
import 'package:ebpco_user_app/core/repositories/document_upload_repository.dart';
import 'package:ebpco_user_app/core/repositories/queueing_document_upload_repository.dart';
import 'package:ebpco_user_app/core/repositories/repository_factory.dart';
import 'package:ebpco_user_app/core/sync/offline_queue.dart';
import 'package:ebpco_user_app/core/sync/queued_operation.dart';
import 'package:ebpco_user_app/core/sync/sync_provider.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// An upload that survives a dropped connection.
///
/// The queue has had a `documentUpload` kind since it was written and threw
/// for it, because two things were missing: an endpoint to send bytes to, and
/// bytes that were still there to send. Both landed on 30 August 2026 — `POST
/// /documents`, and picked attachments being copied into the app's own
/// directory instead of being referenced where the picker left them.
///
/// What is asserted here is the boundary: **transient failures queue, and
/// permanent ones do not.** Replaying a file the server will never accept
/// would fail identically forever while telling the applicant something is
/// still on its way.

DocumentModel _document({String? path}) => DocumentModel(
  id: 'doc-1',
  label: 'Land Title',
  fileName: 'land-title.pdf',
  uploadedAt: DateTime(2026, 8, 30),
  filePath: path,
);

class _Failing implements DocumentUploadRepository {
  _Failing(this.failure);
  final ApiFailure failure;
  int attempts = 0;
  final List<String?> keys = [];

  @override
  Future<UploadedDocument> upload(
    DocumentModel document, {
    String? applicationId,
    String? idempotencyKey,
    void Function(int sent, int total)? onProgress,
  }) async {
    attempts++;
    keys.add(idempotencyKey);
    throw ApiException(failure, 'no');
  }
}

class _Succeeding implements DocumentUploadRepository {
  final List<String?> keys = [];

  @override
  Future<UploadedDocument> upload(
    DocumentModel document, {
    String? applicationId,
    String? idempotencyKey,
    void Function(int sent, int total)? onProgress,
  }) async {
    keys.add(idempotencyKey);
    return UploadedDocument(
      id: 'remote-1',
      label: document.label,
      fileName: document.fileName,
      uploadedAt: DateTime(2026, 8, 30),
      scanCleared: false,
    );
  }
}

void main() {
  late OfflineQueue queue;
  late Directory temp;
  late File file;

  setUp(() {
    queue = OfflineQueue(InMemoryQueueStore());
    temp = Directory.systemTemp.createTempSync('ebpco-queue');
    file = File('${temp.path}/land-title.pdf')..writeAsStringSync('%PDF-1.7');
  });
  tearDown(() => temp.deleteSync(recursive: true));

  group('a transient failure', () {
    test('queues the file and still fails the caller', () async {
      final inner = _Failing(ApiFailure.network);
      final repository = QueueingDocumentUploadRepository(inner, queue);

      await expectLater(
        () => repository.upload(_document(path: file.path)),
        throwsA(isA<ApiException>()),
        reason:
            'queuing is not success. A caller that treated it as success would '
            'file an application referencing documents the office does not have',
      );

      final queued = await queue.all();
      expect(queued, hasLength(1));
      expect(queued.single.kind, QueuedOperationKind.documentUpload);
      expect(queued.single.payload['filePath'], file.path);
      expect(queued.single.payload['label'], 'Land Title');
      expect(queued.single.state, QueuedOperationState.pending);
    });

    test('the queued item carries the key the attempt used', () async {
      // The whole point of a durable key: a replay after the server committed
      // but before the response arrived returns the original document rather
      // than storing the file twice.
      final inner = _Failing(ApiFailure.timeout);
      await expectLater(
        () => QueueingDocumentUploadRepository(
          inner,
          queue,
        ).upload(_document(path: file.path)),
        throwsA(isA<ApiException>()),
      );
      expect((await queue.all()).single.idempotencyKey, inner.keys.single);
    });

    test('a 5xx queues too', () async {
      await expectLater(
        () => QueueingDocumentUploadRepository(
          _Failing(ApiFailure.server),
          queue,
        ).upload(_document(path: file.path)),
        throwsA(isA<ApiException>()),
      );
      expect(await queue.all(), hasLength(1));
    });
  });

  group('a permanent failure', () {
    for (final failure in const [
      ApiFailure.tooLarge,
      ApiFailure.unsupportedMedia,
      ApiFailure.rejected,
      ApiFailure.unauthorized,
    ]) {
      test('$failure queues nothing', () async {
        // Replaying it would fail identically forever while the applicant was
        // shown a pending item that can never complete.
        await expectLater(
          () => QueueingDocumentUploadRepository(
            _Failing(failure),
            queue,
          ).upload(_document(path: file.path)),
          throwsA(isA<ApiException>()),
        );
        expect(await queue.all(), isEmpty);
      });
    }
  });

  test('an attachment with no file behind it is not queued', () async {
    // A fabricated DocumentModel has no bytes. Queuing a reference to nothing
    // shows the applicant a pending item that can never complete.
    await expectLater(
      () => QueueingDocumentUploadRepository(
        _Failing(ApiFailure.network),
        queue,
      ).upload(_document()),
      throwsA(isA<ApiException>()),
    );
    expect(await queue.all(), isEmpty);
  });

  test('a success queues nothing and passes the key through', () async {
    final inner = _Succeeding();
    final uploaded = await QueueingDocumentUploadRepository(
      inner,
      queue,
    ).upload(_document(path: file.path));

    expect(uploaded.id, 'remote-1');
    expect(await queue.all(), isEmpty);
    expect(inner.keys.single, isNotNull, reason: 'a key is always supplied');
  });

  test('a caller-supplied key is used rather than a fresh one', () async {
    const key = '11111111-2222-4333-8444-555555555555';
    final inner = _Failing(ApiFailure.network);
    await expectLater(
      () => QueueingDocumentUploadRepository(
        inner,
        queue,
      ).upload(_document(path: file.path), idempotencyKey: key),
      throwsA(isA<ApiException>()),
    );
    expect(inner.keys.single, key);
    expect((await queue.all()).single.idempotencyKey, key);
  });

  group('the queue can now actually send one', () {
    // `SyncProvider._send` threw for documentUpload from the day the queue was
    // written. Driven through flush() against a fake http.Client, so what is
    // asserted is the request that would go on the wire.
    QueuedOperation operation({String? path}) => QueuedOperation(
      id: 'upload-1',
      kind: QueuedOperationKind.documentUpload,
      idempotencyKey: '11111111-2222-4333-8444-555555555555',
      enqueuedAt: DateTime(2026, 8, 30),
      applicationId: 'app-1',
      payload: {
        'filePath': ?path,
        'label': 'Land Title',
        'fileName': 'land-title.pdf',
      },
    );

    test('the bytes, the label and the queue\'s own key are sent', () async {
      late http.Request seen;
      final sync = SyncProvider(
        queue: queue,
        api: ApiClient(
          baseUrl: 'https://api.example.gov.ph',
          httpClient: MockClient((request) async {
            seen = request;
            return http.Response('{"id":"remote-1","fileName":"x.pdf"}', 201);
          }),
        ),
      );
      await queue.enqueue(operation(path: file.path));

      final outcome = await sync.flush();

      expect(outcome, isNotNull);
      expect(seen.url.path, '/documents');
      expect(seen.headers['Idempotency-Key'], operation().idempotencyKey);
      expect(seen.body, contains('%PDF-1.7'));
      expect(seen.body, contains('Land Title'));
      expect(
        await queue.all(),
        isEmpty,
        reason: 'a sent item leaves the queue',
      );
    });

    test('it stays queued when there is still no connection', () async {
      final sync = SyncProvider(
        queue: queue,
        api: ApiClient(
          baseUrl: 'https://api.example.gov.ph',
          httpClient: MockClient(
            (_) async => throw http.ClientException('offline'),
          ),
        ),
      );
      await queue.enqueue(operation(path: file.path));

      await sync.flush();
      expect(
        (await queue.all()).single.state,
        QueuedOperationState.pending,
        reason: 'still waiting, and still the applicant\'s work',
      );
    });

    test(
      'an item with no file path fails permanently rather than looping',
      () async {
        final sync = SyncProvider(
          queue: queue,
          api: ApiClient(baseUrl: 'https://api.example.gov.ph'),
        );
        await queue.enqueue(operation());

        await sync.flush();
        expect(
          (await queue.all()).single.state,
          QueuedOperationState.failedPermanently,
          reason:
              'retrying forever would show a pending item that can never '
              'complete',
        );
      },
    );
  });

  group('the factory decides whether anything queues at all', () {
    test('with no server, uploads refuse and nothing is wrapped', () {
      final uploads = RepositoryFactory(queue: queue).documentUploads();
      expect(uploads, isA<UnavailableDocumentUploadRepository>());
    });

    test('with a server and a queue, uploads are queued on failure', () {
      final uploads = RepositoryFactory(
        apiClient: ApiClient(baseUrl: 'https://api.example.gov.ph'),
        queue: queue,
      ).documentUploads();
      expect(uploads, isA<QueueingDocumentUploadRepository>());
    });

    test('with a server and no queue, behaviour is unchanged', () {
      // Not a regression: without somewhere durable to put a failed upload,
      // wrapping it would only pretend.
      final uploads = RepositoryFactory(
        apiClient: ApiClient(baseUrl: 'https://api.example.gov.ph'),
      ).documentUploads();
      expect(uploads, isA<HttpDocumentUploadRepository>());
    });
  });
}
