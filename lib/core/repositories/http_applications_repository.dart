import '../api/api_client.dart';
import '../api/api_exception.dart';
import '../api/application_dto.dart';
import '../contract/service_domain.dart';
import '../models/application_lineage.dart';
import '../models/application_model.dart';
import '../models/document_model.dart';
import '../models/money.dart';
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
    ApplicationLineage? lineage,
  }) async {
    // `applicationAction` below already carries New / Renewal / Amendment,
    // which both lines have agreed on since the first reconciliation. What
    // neither carries is *what* is being renewed or amended: the admin's
    // `ApplicationRecord` has no field pointing at a prior application or
    // permit, and neither does the contract's POST /applications body.
    //
    // So the reference is deliberately NOT sent. An undeclared field against a
    // strict server fails the whole submission, which would cost the applicant
    // their filing to gain a field the office cannot read anyway. It is kept
    // on the local record, and the gap is recorded for the backend lane as
    // M-44 rather than papered over here.
    final json = await _api.post(
      '/applications',
      body: {
        // Required by the contract and, until 30 August 2026, never sent — so
        // a conforming server refused every filing this app made. Derived
        // rather than decided: see `serviceDomainFor`.
        'serviceDomain': serviceDomainFor(permitTypeLabel).wire,
        // Null, not ''. The contract types this as a uuid or null, and an
        // empty string is neither — every construction wizard files through
        // `submitPermitApplication`, which has no business to name because a
        // construction permit is filed by a person.
        'businessId': businessId.isEmpty ? null : businessId,
        // Sent when the caller is a construction-permit wizard, which knows
        // its own permit name. The server assigns the reference, so the
        // locally-generated one is deliberately not sent — the parsed
        // response is the record of truth for the number.
        'permitType': ?permitTypeLabel,
        'applicationAction': (lineage?.action ?? type).wire,
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
    required String referenceNumber,
    required DateTime paidOn,
    PesoAmount? amountPaid,
    DocumentModel? proof,
  }) => reportPayment(
    applicationId,
    method: method,
    // Was `proof?.label ?? ''` — the label of the attached file, not the
    // reference the applicant typed. The Treasurer's Office reconciles against
    // a bank reference or an OR number, and "Proof of payment" is neither, so
    // every report sent this way was unverifiable. M-47.
    referenceNumber: referenceNumber,
    paidOn: paidOn,
    amountPaid: amountPaid,
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
    required DateTime paidOn,
    PesoAmount? amountPaid,
    DocumentModel? proof,
  }) async {
    final json = await _api.post(
      '/applications/$applicationId/payments',
      body: {
        'method': method == PaymentMethod.bankTransfer
            ? 'Bank Transfer'
            : 'Onsite',
        'referenceNumber': referenceNumber,
        // Required by the contract, and absent until 30 August 2026 — so every
        // payment report was refused before the office saw it. `format: date`,
        // which is a calendar day and not an instant: the applicant paid on a
        // date, in their own timezone, and an ISO timestamp would invite the
        // server to shift it.
        'paidOn':
            '${paidOn.year.toString().padLeft(4, '0')}-'
            '${paidOn.month.toString().padLeft(2, '0')}-'
            '${paidOn.day.toString().padLeft(2, '0')}',
        // Optional, and the app has always had the figure — the Order of
        // Payment is on the screen the applicant is looking at. Sending it
        // lets the Treasurer's Office see a short payment as a short payment
        // rather than as a mystery.
        if (amountPaid != null) 'amountCentavos': amountPaid.centavos,
        // DELIBERATELY LEFT DIVERGENT. The contract declares `documentId` —
        // the id of a receipt already uploaded through /documents — and that
        // flow is not built, so the app has no id to send. Dropping the key
        // would let the request succeed while silently discarding the receipt
        // the applicant attached; sending it fails the request loudly instead.
        // The same reasoning as `documents` on the submission body. M-47.
        if (proof != null)
          'proof': {'label': proof.label, 'fileName': proof.fileName},
      },
    );
    return ApplicationDto.parse(json);
  }

  /// Answers a Letter of Instruction, item by item.
  ///
  /// Took no arguments and posted no body until 30 August 2026, against an
  /// endpoint whose `items` array is required with `minItems: 1` — so the
  /// request was refused before the office ever saw which deficiencies the
  /// applicant had addressed. That is the call the 28 August remeasure
  /// mistook for a working M-43: the route exists, and the app was calling it
  /// wrongly, which is a different thing and was missed because nothing
  /// compared bodies.
  ///
  /// [responses] is the applicant's note against an item, keyed by item id;
  /// an item with nothing to say sends none. Document ids are deliberately
  /// absent — the /documents upload flow is not built, so there is no id to
  /// reference, and the contract makes them optional.
  Future<ApplicationModel> resubmitInstruction(
    String applicationId,
    String letterId, {
    required List<String> itemIds,
    Map<String, String> responses = const {},
  }) async {
    if (itemIds.isEmpty) {
      // `minItems: 1`. Failing here names the mistake; letting it through
      // would send a body the server rejects for a reason nobody can see.
      throw const ApiException(
        ApiFailure.rejected,
        'a Letter of Instruction cannot be answered with no items',
      );
    }
    final json = await _api.post(
      '/applications/$applicationId/instructions/$letterId/resubmit',
      body: {
        'items': [
          for (final itemId in itemIds)
            {
              'itemId': itemId,
              if (responses[itemId] != null) 'response': responses[itemId],
            },
        ],
      },
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
