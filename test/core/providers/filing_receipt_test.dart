import 'package:flutter_test/flutter_test.dart';

import 'package:ebpco_user_app/core/models/application_model.dart';
import 'package:ebpco_user_app/core/models/document_model.dart';
import 'package:ebpco_user_app/core/providers/applications_provider.dart';
import 'package:ebpco_user_app/core/providers/notifications_provider.dart';
import 'package:ebpco_user_app/core/repositories/applications_repository.dart';
import 'package:ebpco_user_app/core/repositories/document_upload_repository.dart';
import 'package:ebpco_user_app/core/repositories/notifications_repository.dart';

/// The receipt counts what the OFFICE took, never what the draft held.
///
/// Both of this app's worst defects were invisible for the same reason: the
/// confirmation screen had no number on it that could have been wrong.
/// `documents` was hardcoded to `const []` and no attachment was ever sent;
/// no wizard sent `form` and 239 typed fields were dropped at the wire. The
/// wizard collected the work, the review step listed it, the confirmation said
/// Submitted, and nothing was in a position to disagree.
///
/// So these assert the disagreement is possible.

DocumentModel _document(String label) => DocumentModel(
  id: label,
  label: label,
  fileName: '$label.pdf',
  uploadedAt: DateTime(2026, 9, 2),
  filePath: '/tmp/$label.pdf',
);

class _Uploads implements DocumentUploadRepository {
  @override
  Future<UploadedDocument> upload(
    DocumentModel document, {
    String? applicationId,
    String? idempotencyKey,
    void Function(int sent, int total)? onProgress,
  }) async => UploadedDocument(
    id: 'server-id-${document.label}',
    label: document.label,
    fileName: document.fileName,
    uploadedAt: DateTime(2026, 9, 2),
    scanCleared: false,
  );
}

Future<ApplicationsProvider> _provider(
  DocumentUploadRepository? uploads,
) async {
  final provider = ApplicationsProvider(
    notifications: NotificationsProvider(
      repository: MockNotificationsRepository(),
    ),
    repository: MockApplicationsRepository(),
    documentUploads: uploads,
  );
  await Future.delayed(const Duration(milliseconds: 1200));
  return provider;
}

Future<ApplicationModel> _file(
  ApplicationsProvider provider, {
  required List<DocumentModel> documents,
  Map<String, Object?>? form,
  String? location,
}) => provider.submitApplication(
  businessId: '',
  businessName: 'Juan dela Cruz',
  type: ApplicationType.newPermit,
  documents: documents,
  permitTypeLabel: 'Demolition Permit',
  location: location,
  form: form,
);

void main() {
  test(
    'the receipt counts the ids the server issued, not the attachments',
    () async {
      final provider = await _provider(_Uploads());
      final filed = await _file(
        provider,
        documents: [_document('Lot Plan'), _document('Land Title')],
        form: {'applicant.name': 'Juan', 'site.barangay': 'Bagalayag'},
        location: 'Lot 4, Bagalayag, Castilla',
      );

      final receipt = provider.receiptFor(filed.id)!;
      expect(receipt.documentIdsIssued, [
        'server-id-Lot Plan',
        'server-id-Land Title',
      ]);
      expect(receipt.attachmentsAccepted, 2);
      expect(receipt.attachmentsOffered, 2);
      expect(receipt.attachmentsAreShort, isFalse);
      expect(receipt.answersSent, 2);
      expect(receipt.location, 'Lot 4, Bagalayag, Castilla');
    },
  );

  test('a filing that sent no attachments says 0, not 2', () async {
    // The original defect, reproduced exactly: a build with no upload
    // repository files the application and sends no documents at all. The
    // citizen attached two. Before the receipt existed, every screen in the
    // app agreed this was a complete filing.
    final provider = await _provider(null);
    final filed = await _file(
      provider,
      documents: [_document('Lot Plan'), _document('Land Title')],
      form: {'applicant.name': 'Juan'},
    );

    final receipt = provider.receiptFor(filed.id)!;
    expect(receipt.attachmentsOffered, 2);
    expect(
      receipt.attachmentsAccepted,
      0,
      reason: 'no upload repository means the office received nothing',
    );
    expect(
      receipt.attachmentsAreShort,
      isTrue,
      reason: 'this is the shortfall the confirmation screen could not express',
    );
  });

  test('a filing carrying no answers is reported as carrying none', () async {
    final provider = await _provider(_Uploads());
    final filed = await _file(provider, documents: const []);

    final receipt = provider.receiptFor(filed.id)!;
    expect(receipt.answersSent, 0);
    expect(receipt.carriesNoAnswers, isTrue);
  });

  test(
    'no receipt is invented for an application this device did not file',
    () async {
      final provider = await _provider(_Uploads());
      expect(provider.receiptFor('some-other-application'), isNull);
    },
  );

  test(
    'the receipt takes the reference number from the server record',
    () async {
      final provider = await _provider(_Uploads());
      final filed = await _file(provider, documents: const []);

      final receipt = provider.receiptFor(filed.id)!;
      expect(receipt.referenceNumber, filed.applicationNumber);
      expect(receipt.submittedAt, filed.submittedDate);
    },
  );
}
