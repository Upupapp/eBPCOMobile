import '../../mock/mock_applications_data.dart';
import '../constants/app_constants.dart';
import '../models/application_lineage.dart';
import '../models/application_model.dart';
import '../models/document_model.dart';
import '../models/money.dart';
import '../models/payment_assessment_model.dart';

/// Source of a user's permit applications. Swap [MockApplicationsRepository]
/// for a real HTTP-backed implementation once a backend exists — callers
/// only depend on this interface.
abstract class ApplicationsRepository {
  Future<List<ApplicationModel>> fetchAll();

  Future<ApplicationModel> submitApplication({
    required String businessId,
    required String businessName,
    required ApplicationType type,
    required List<DocumentModel> documents,

    /// The permit's own name, e.g. "Fencing Permit". [ApplicationType] only
    /// distinguishes new/renewal/amendment, which is enough for a business
    /// permit and says nothing useful about a construction permit.
    String? permitTypeLabel,

    /// The reference the applicant was already shown on the confirmation
    /// screen. Passed in rather than generated so the number on that screen
    /// and the number in the list are the same number.
    String? applicationNumber,

    /// What this application continues, on a renewal or an amendment. Null on
    /// a first filing.
    ApplicationLineage? lineage,

    /// The ids of documents already uploaded through `/documents`.
    ///
    /// Empty when nothing was uploaded, which is not the same as "there are no
    /// documents": [documents] may be full while this is empty, and that is
    /// precisely the state in which a filing must fail rather than succeed
    /// without them. See `HttpApplicationsRepository.submitApplication`.
    List<String> documentIds = const [],

    /// The site, as one line. Declared by the contract as a nullable string
    /// and sent as nothing until 31 August 2026 — see
    /// `submitPermitApplication`.
    String? location,

    /// Everything the applicant typed, from the wizard's draft codec.
    ///
    /// Declared by the contract as an optional open object and sent as
    /// nothing until 1 September 2026, so a filing carried the permit type,
    /// the applicant and the site and none of the nine or ten steps behind
    /// them. See `permitFormPayload`.
    Map<String, Object?>? form,
  });

  /// Reports a payment the applicant says they made.
  ///
  /// [referenceNumber] and [paidOn] are both REQUIRED by the contract's
  /// `PaymentProof`, and both used to be missing here: the reference was
  /// fabricated from the proof document's label on the HTTP path, and the date
  /// had no field anywhere in the app. M-47.
  Future<ApplicationModel> attachPayment(
    String applicationId, {
    required PaymentMethod method,
    required String referenceNumber,
    required DateTime paidOn,
    PesoAmount? amountPaid,
    DocumentModel? proof,

    /// The id of a receipt already uploaded through `/documents`. Null when
    /// nothing could be uploaded — see the note on `documentIds` above; the
    /// same all-or-nothing rule applies, for the same reason.
    String? documentId,
  });

  /// Replaces one document on a filed application with a newly supplied file.
  ///
  /// The office keeps every earlier submission, so this appends rather than
  /// overwrites — an applicant who resubmits a rejected land title should not
  /// lose the record of what was rejected, or why.
  Future<ApplicationModel> resubmitDocument(
    String applicationId, {
    required String documentId,
    required DocumentModel replacement,
  });

  /// Moves the application to the next status in [applicationStatusSequence].
  /// No-op (returns the application unchanged) if it's already at the end.
  Future<ApplicationModel> advanceStatus(String applicationId);
}

class MockApplicationsRepository implements ApplicationsRepository {
  final List<ApplicationModel> _applications = [buildSeedApplication()];

  @override
  Future<List<ApplicationModel>> fetchAll() async {
    await Future.delayed(AppConstants.mockNetworkDelay);
    return List.unmodifiable(_applications);
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
    List<String> documentIds = const [],
    String? location,
    // Held by the wire repository only. A local filing has nowhere to send it.
    Map<String, Object?>? form,
  }) async {
    await Future.delayed(AppConstants.mockNetworkDelay);
    final now = DateTime.now();
    final sequence = (_applications.length + 1).toString().padLeft(6, '0');
    final application = ApplicationModel(
      id: 'app-${now.microsecondsSinceEpoch}',
      applicationNumber: applicationNumber ?? 'E-BPCO-${now.year}-$sequence',
      businessId: businessId,
      businessName: businessName,
      permitTypeLabel: permitTypeLabel,
      type: type,
      status: ApplicationStatus.submitted,
      submittedDate: now,
      lineage: lineage,
      documents: documents,
      statusHistory: [
        StatusHistoryEntry(status: ApplicationStatus.submitted, timestamp: now),
      ],
    );
    _applications.add(application);
    return application;
  }

  @override
  Future<ApplicationModel> attachPayment(
    String applicationId, {
    required PaymentMethod method,
    required String referenceNumber,
    required DateTime paidOn,
    PesoAmount? amountPaid,
    DocumentModel? proof,
    String? documentId,
  }) async {
    await Future.delayed(AppConstants.mockNetworkDelay);
    final index = _applications.indexWhere((a) => a.id == applicationId);
    if (index == -1) {
      throw StateError('Application $applicationId not found.');
    }
    final application = _applications[index];
    // The assessment itself comes from the LGU. Attaching proof of payment
    // never creates or alters one — it only records what the applicant paid
    // against the Order of Payment already on file.
    final existing = application.payment;
    final updated = application.copyWith(
      status: ApplicationStatus.paymentVerification,
      payment:
          (existing ??
                  const PaymentAssessmentModel(
                    status: PaymentAssessmentStatus.notYetAvailable,
                  ))
              .copyWith(
                status: PaymentAssessmentStatus.pending,
                method: method,
                referenceNumber: referenceNumber,
                paidOn: paidOn,
                proof: proof,
                submittedAt: DateTime.now(),
              ),
      statusHistory: [
        ...application.statusHistory,
        StatusHistoryEntry(
          status: ApplicationStatus.paymentVerification,
          timestamp: DateTime.now(),
        ),
      ],
    );
    _applications[index] = updated;
    return updated;
  }

  @override
  @override
  Future<ApplicationModel> resubmitDocument(
    String applicationId, {
    required String documentId,
    required DocumentModel replacement,
  }) async {
    await Future.delayed(AppConstants.mockNetworkDelay);
    final index = _applications.indexWhere((a) => a.id == applicationId);
    if (index < 0) {
      throw StateError('No application $applicationId');
    }
    final application = _applications[index];
    final updated = application.copyWith(
      documents: [
        for (final document in application.documents)
          if (document.id == documentId)
            document.resubmittedWith(
              fileName: replacement.fileName,
              submittedAt: replacement.uploadedAt,
            )
          else
            document,
      ],
    );
    _applications[index] = updated;
    return updated;
  }

  @override
  Future<ApplicationModel> advanceStatus(String applicationId) async {
    await Future.delayed(AppConstants.mockNetworkDelay);
    final index = _applications.indexWhere((a) => a.id == applicationId);
    if (index == -1) {
      throw StateError('Application $applicationId not found.');
    }
    final application = _applications[index];
    final currentIndex = applicationStatusSequence.indexOf(application.status);
    if (currentIndex == -1 ||
        currentIndex == applicationStatusSequence.length - 1) {
      return application;
    }

    final nextStatus = applicationStatusSequence[currentIndex + 1];
    final now = DateTime.now();
    final isReleased = nextStatus == ApplicationStatus.released;
    final updated = application.copyWith(
      status: nextStatus,
      payment:
          nextStatus == ApplicationStatus.approved &&
              application.payment != null
          ? application.payment!.copyWith(status: PaymentAssessmentStatus.paid)
          : application.payment,
      permitNumber: isReleased
          ? 'PERMIT-${now.year}-${(index + 1).toString().padLeft(6, '0')}'
          : application.permitNumber,
      issuedDate: isReleased ? now : application.issuedDate,
      statusHistory: [
        ...application.statusHistory,
        StatusHistoryEntry(status: nextStatus, timestamp: now),
      ],
    );
    _applications[index] = updated;
    return updated;
  }
}
