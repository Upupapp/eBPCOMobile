import '../api/api_client.dart';
import '../api/api_exception.dart';
import '../api/application_dto.dart';
import '../models/application_model.dart';
import '../models/document_model.dart';
import '../models/payment_assessment_model.dart';
import 'applications_repository.dart';

/// The real [ApplicationsRepository], backed by the eBPCO API.
///
/// Drops in wherever [MockApplicationsRepository] is used today — the swap is
/// one line at the provider, because everything above this depends only on the
/// interface. That was the point of keeping mocks confined to repositories.
///
/// Nothing here advances an application. The endpoints it calls are all
/// submissions into the office's queue: filing, resubmitting corrections,
/// reporting a payment. Status arrives from the server or not at all.
class HttpApplicationsRepository implements ApplicationsRepository {
  HttpApplicationsRepository(this._api);

  final ApiClient _api;

  @override
  Future<List<ApplicationModel>> fetchAll() async {
    final rows = await _api.getList('/applications');
    return ApplicationDto.parseList(rows);
  }

  /// One application in full, including timeline, evaluations, letters, and
  /// permit — the §7.2 ApplicationDetail payload.
  Future<ApplicationModel> fetchDetail(String applicationId) async {
    final json = await _api.getObject('/applications/$applicationId');
    return ApplicationDto.parse(json);
  }

  @override
  Future<ApplicationModel> submitApplication({
    required String businessId,
    required String businessName,
    required ApplicationType type,
    required List<DocumentModel> documents,
    String? permitTypeLabel,
    String? applicationNumber,
  }) async {
    final json = await _api.post(
      '/applications',
      body: {
        'businessId': businessId,
        // Sent when the caller is a construction-permit wizard, which knows
        // its own permit name. The server assigns the reference, so the
        // locally-generated one is deliberately not sent — the parsed
        // response is the record of truth for the number.
        'permitType': ?permitTypeLabel,
        'applicationAction': switch (type) {
          ApplicationType.newPermit => 'New',
          ApplicationType.renewal => 'Renewal',
          ApplicationType.amendment => 'Amendment',
        },
        'documents': [
          for (final document in documents)
            {'label': document.label, 'fileName': document.fileName},
        ],
      },
    );
    return ApplicationDto.parse(json);
  }

  @override
  Future<ApplicationModel> resubmitDocument(
    String applicationId, {
    required String documentId,
    required DocumentModel replacement,
  }) async {
    // The route this posts to does not exist on the backend yet. Recorded as a
    // hand-off rather than faked: on a live build this should fail loudly, not
    // quietly tell the applicant their document was resent.
    final json = await _api.post(
      '/applications/$applicationId/documents/$documentId/resubmit',
      body: {'fileName': replacement.fileName, 'label': replacement.label},
    );
    return ApplicationDto.parse(json);
  }

  @override
  Future<ApplicationModel> attachPayment(
    String applicationId, {
    required PaymentMethod method,
    DocumentModel? proof,
  }) => reportPayment(
    applicationId,
    method: method,
    referenceNumber: proof?.label ?? '',
    proof: proof,
  );

  /// Reports a payment made against an existing Order of Payment.
  ///
  /// Named for what it does. The applicant is telling the office they paid;
  /// whether the money arrived is the Treasurer's Office's finding, and the
  /// response will say Pending Verification, never Paid.
  Future<ApplicationModel> reportPayment(
    String applicationId, {
    required PaymentMethod method,
    required String referenceNumber,
    DocumentModel? proof,
  }) async {
    final json = await _api.post(
      '/applications/$applicationId/payments',
      body: {
        'method': method == PaymentMethod.bankTransfer
            ? 'Bank Transfer'
            : 'Onsite',
        'referenceNumber': referenceNumber,
        if (proof != null)
          'proof': {'label': proof.label, 'fileName': proof.fileName},
      },
    );
    return ApplicationDto.parse(json);
  }

  /// Returns corrected documents to the office after a Letter of Instruction.
  Future<ApplicationModel> resubmitInstruction(
    String applicationId,
    String letterId,
  ) async {
    final json = await _api.post(
      '/applications/$applicationId/instructions/$letterId/resubmit',
    );
    return ApplicationDto.parse(json);
  }

  @override
  Future<ApplicationModel> advanceStatus(String applicationId) {
    // Deliberately unimplemented. Advancing an application is an act of the
    // Office of the Building Official; the mock repository simulates it so the
    // prototype can be demonstrated, and against a real server there is no
    // such endpoint for an applicant to call. Anything reaching this is a bug
    // worth failing loudly for.
    throw ApiException(
      ApiFailure.rejected,
      'applicants cannot advance their own application — status changes come '
      'from the Office of the Building Official',
    );
  }
}
