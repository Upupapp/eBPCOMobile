import 'package:flutter_test/flutter_test.dart';

import 'package:ebpco_user_app/core/api/api_exception.dart';
import 'package:ebpco_user_app/core/models/application_model.dart';
import 'package:ebpco_user_app/core/models/document_model.dart';
import 'package:ebpco_user_app/core/providers/applications_provider.dart';
import 'package:ebpco_user_app/core/providers/notifications_provider.dart';
import 'package:ebpco_user_app/core/repositories/applications_repository.dart';
import 'package:ebpco_user_app/core/repositories/document_upload_repository.dart';
import 'package:ebpco_user_app/core/repositories/notifications_repository.dart';

/// The files go before the filing, and all of them or none.
///
/// An application filed before its documents reach the office is one the
/// office cannot act on. A PARTIALLY uploaded one is worse: a submission
/// listing eleven of twenty-four documents reads to an evaluator like an
/// applicant who forgot thirteen, and the applicant has no way to know.

DocumentModel _document(String label) => DocumentModel(
  id: label,
  label: label,
  fileName: '$label.pdf',
  uploadedAt: DateTime(2026, 8, 30),
  filePath: '/tmp/$label.pdf',
);

class _Uploads implements DocumentUploadRepository {
  _Uploads({this.failOn});

  /// The label whose upload fails, if any.
  final String? failOn;
  final List<String> uploaded = [];

  @override
  Future<UploadedDocument> upload(
    DocumentModel document, {
    String? applicationId,
    String? idempotencyKey,
    void Function(int sent, int total)? onProgress,
  }) async {
    if (document.label == failOn) {
      throw const ApiException(ApiFailure.tooLarge, 'too large');
    }
    uploaded.add(document.label);
    return UploadedDocument(
      id: 'id-${document.label}',
      label: document.label,
      fileName: document.fileName,
      uploadedAt: DateTime(2026, 8, 30),
      scanCleared: false,
    );
  }
}

/// Built and then settled. `MockApplicationsRepository` loads seed data
/// asynchronously from the constructor, so a count taken immediately is a
/// count of nothing and every "did it file?" assertion below would be
/// measuring the seed load instead.
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

void main() {
  test(
    'every attachment is uploaded before the application is filed',
    () async {
      final uploads = _Uploads();
      final applications = await _provider(uploads);
      final before = applications.applications.length;

      await applications.submitApplication(
        businessId: 'biz-seed-1',
        businessName: "Juan's General Merchandise",
        type: ApplicationType.newPermit,
        documents: [_document('Land Title'), _document('Plans')],
      );

      expect(uploads.uploaded, ['Land Title', 'Plans']);
      expect(applications.applications.length, before + 1);
    },
  );

  test('one failed upload files nothing at all', () async {
    // The applicant sees an error and still has their draft — rather than a
    // filed application missing the plans, which nobody would notice until an
    // evaluator turned it back weeks later.
    final uploads = _Uploads(failOn: 'Plans');
    final applications = await _provider(uploads);
    final before = applications.applications.length;

    await expectLater(
      () => applications.submitApplication(
        businessId: 'biz-seed-1',
        businessName: "Juan's General Merchandise",
        type: ApplicationType.newPermit,
        documents: [
          _document('Land Title'),
          _document('Plans'),
          _document('Barangay Clearance'),
        ],
      ),
      throwsA(isA<ApiException>()),
    );

    expect(
      applications.applications.length,
      before,
      reason: 'nothing may be filed when an attachment did not arrive',
    );
    expect(uploads.uploaded, [
      'Land Title',
    ], reason: 'and it stops at the failure rather than pressing on');
  });

  test(
    'with no upload repository, filing still works as it always did',
    () async {
      // Every widget test in this repository builds the provider this way, and
      // the mock build has no server to upload to. It must behave exactly as it
      // did before: the submission carries the attachments' labels, which a
      // conforming server refuses — loudly.
      final applications = await _provider(null);
      expect(
        () => applications.submitApplication(
          businessId: 'biz-seed-1',
          businessName: "Juan's General Merchandise",
          type: ApplicationType.newPermit,
          documents: [_document('Land Title')],
        ),
        returnsNormally,
      );
    },
  );
}
