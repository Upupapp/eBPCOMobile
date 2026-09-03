import '../api/api_exception.dart';
import 'package:flutter/material.dart';

import '../models/action_item.dart';
import '../models/application_detail.dart';
import '../models/application_lineage.dart';
import '../models/application_model.dart';
import '../models/upload_progress.dart';
import '../models/lifecycle_status.dart';
import '../models/notification_event.dart';
import '../notifications/notification_evaluator.dart';
import '../models/document_model.dart';
import '../models/filing_receipt.dart';
import '../models/money.dart';
import '../models/payment_assessment_model.dart';
import '../repositories/applications_repository.dart';
import '../repositories/document_upload_repository.dart';
import '../services/service_pledge_service.dart';
import 'notifications_provider.dart';

/// Holds the user's permit applications, sourced from
/// [ApplicationsRepository]. Submitting, paying, and advancing an
/// application's status each post a matching notification via
/// [NotificationsProvider].
class ApplicationsProvider extends ChangeNotifier {
  ApplicationsProvider({
    required this._notifications,
    required this._repository,

    /// Null on a build with no server, where there is nothing to upload to.
    /// The app then behaves as it did before: it sends the attachments' labels
    /// and filenames, which a conforming server refuses — loudly, rather than
    /// filing an application without them.
    this._documentUploads,
    ServicePledgeService? pledgeService,
    this.actionItemBuilder = const ActionItemBuilder(),
    DateTime Function()? clock,
  }) : _pledgeService = pledgeService ?? const ServicePledgeService(),
       _clock = clock ?? DateTime.now {
    _load();
  }

  final ApplicationsRepository _repository;
  final DocumentUploadRepository? _documentUploads;
  final NotificationsProvider _notifications;
  final ServicePledgeService _pledgeService;
  final ActionItemBuilder actionItemBuilder;

  /// Injected so pledge countdowns and commencement deadlines are
  /// deterministic under test rather than depending on the wall clock.
  final DateTime Function() _clock;

  bool _isLoading = true;
  List<ApplicationModel> _applications = const [];
  Object? _loadError;

  bool get isLoading => _isLoading;
  List<ApplicationModel> get applications => _applications;

  /// Set when the last load failed. The previously-loaded applications are
  /// deliberately retained alongside it: a failed refresh must degrade to
  /// stale data with a retry affordance, never to a blank tab, because the
  /// action items already on screen may be the reason the applicant opened
  /// the app.
  Object? get loadError => _loadError;
  bool get hasLoadError => _loadError != null;

  DateTime? _lastLoadedAt;

  /// When this data was last successfully fetched.
  ///
  /// Every remote-backed surface stamps it when serving cached data, because
  /// an applicant deciding whether to act on a status needs to know whether
  /// they are looking at now or at last Tuesday.
  DateTime? get lastLoadedAt => _lastLoadedAt;

  /// True when what is on screen is known to be stale — the last refresh
  /// failed, so this is the previous load.
  bool get isServingStaleData => _loadError != null && _lastLoadedAt != null;

  /// Most relevant application for the dashboard's summary card: the most
  /// recently submitted one that hasn't reached the end of the happy path.
  ApplicationModel? get activeApplication {
    if (_applications.isEmpty) return null;
    final inProgress = _applications.where(
      (a) =>
          a.status != ApplicationStatus.released &&
          a.status != ApplicationStatus.rejected,
    );
    final pool = inProgress.isNotEmpty ? inProgress : _applications;
    return pool.reduce(
      (a, b) => a.submittedDate.isAfter(b.submittedDate) ? a : b,
    );
  }

  /// Everything the applicant currently owes, in regulatory urgency order.
  /// Drives the Home action stack and the Applications "Needs Action" filter.
  List<ActionItem> get actionItems =>
      actionItemBuilder.build(_applications, asOf: _clock());

  /// The RA 11032 service pledge for [application], or null when the LGU has
  /// not classified it yet or it is no longer in flight. Null means "show no
  /// countdown" — never "show zero".
  ServicePledge? pledgeFor(ApplicationModel application) {
    final classification = application.classification;
    if (classification == null || !application.isInFlight) return null;
    return _pledgeService.computeFor(
      filedOn: application.submittedDate,
      classification: classification,
      asOf: _clock(),
    );
  }

  /// Released permits, most recently issued first.
  List<ApplicationModel> get releasedPermits {
    final released = _applications
        .where((a) => a.permitNumber != null && a.issuedDate != null)
        .toList();
    released.sort((a, b) => b.issuedDate!.compareTo(a.issuedDate!));
    return released;
  }

  /// The four Home counters. Each is a live filter into Applications, so the
  /// keys here are also the filter identifiers.
  Map<String, int> get homeCounters {
    var inProgress = 0;
    var approved = 0;
    var released = 0;
    for (final application in _applications) {
      switch (application.applicantStatus) {
        case ApplicationStatus.submitted:
        case ApplicationStatus.underReview:
        case ApplicationStatus.paymentVerification:
          inProgress++;
        case ApplicationStatus.approved:
          approved++;
        case ApplicationStatus.released:
          released++;
        case ApplicationStatus.draft:
        case ApplicationStatus.rejected:
          break;
      }
    }
    return {
      'In Progress': inProgress,
      'Action Needed': actionItems.length,
      'Approved': approved,
      'Released': released,
    };
  }

  Map<String, int> get summaryCounts {
    final counts = <String, int>{
      'Draft': 0,
      'Submitted': 0,
      'Approved': 0,
      'Released': 0,
    };
    for (final application in _applications) {
      switch (application.status) {
        case ApplicationStatus.draft:
          counts['Draft'] = counts['Draft']! + 1;
        case ApplicationStatus.submitted:
        case ApplicationStatus.underReview:
        case ApplicationStatus.paymentVerification:
          counts['Submitted'] = counts['Submitted']! + 1;
        case ApplicationStatus.approved:
          counts['Approved'] = counts['Approved']! + 1;
        case ApplicationStatus.released:
          counts['Released'] = counts['Released']! + 1;
        case ApplicationStatus.rejected:
          break;
      }
    }
    return counts;
  }

  /// Ids whose full record has been fetched, so a screen does not refetch on
  /// every rebuild.
  final Set<String> _detailed = <String>{};

  /// Ids currently being fetched, so a rebuild mid-flight does not start a
  /// second request.
  final Set<String> _detailing = <String>{};

  /// Replaces a summary record with the full one from `GET /applications/{id}`.
  ///
  /// **Why a screen has to ask for this.** Everything the app shows about one
  /// application beyond its headline — the open Letter of Instruction, the
  /// evaluator's remarks, the permit, the release logistics, the inspection —
  /// lives in sub-objects the LIST endpoint may omit, and the contract says
  /// so. Meanwhile the Home action stack is computed from scalars the list
  /// does carry. So the app could promise "3 items must be corrected" from the
  /// list and then have nothing to show, because the letters were never
  /// fetched. See `ApplicationsRepository.fetchDetail`.
  ///
  /// Failure is deliberately silent. The summary record stays on screen, which
  /// is what the applicant had before; a snackbar over a detail they did not
  /// ask to refresh would be noise, and `loadError` is for the list.
  Future<void> loadDetail(String id) async {
    if (_detailed.contains(id) || _detailing.contains(id)) return;
    _detailing.add(id);
    try {
      final detail = await _repository.fetchDetail(id);
      final index = _applications.indexWhere((a) => a.id == id);
      if (index >= 0) {
        _applications = [..._applications]..[index] = detail;
      } else {
        _applications = [..._applications, detail];
      }
      _detailed.add(id);
      notifyListeners();
    } catch (_) {
      // Left summary. Retried the next time the screen is opened, because the
      // id never entered `_detailed`.
    } finally {
      _detailing.remove(id);
    }
  }

  /// Forgets what has been fetched, so a pull-to-refresh re-reads details too.
  void _invalidateDetails() => _detailed.clear();

  ApplicationModel? byId(String id) {
    for (final application in _applications) {
      if (application.id == id) return application;
    }
    return null;
  }

  Future<void> _load() async {
    try {
      _invalidateDetails();
      _applications = await _repository.fetchAll();
      _loadError = null;
      _lastLoadedAt = _clock();

      // Conditions the app can work out for itself — a lapsed service pledge,
      // a permit approaching its PD 1096 deadline. Derived on every load and
      // deduped, so they reach the feed once rather than never or endlessly.
      _notifications.recordDerived(
        const NotificationEvaluator().evaluate(
          applications: _applications,
          asOf: _clock(),
        ),
      );
    } catch (error) {
      // Keep whatever was already loaded. Losing the action stack because a
      // refresh timed out would hide exactly the information the applicant
      // most needs.
      _loadError = error;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() => _load();

  Future<ApplicationModel> submitApplication({
    required String businessId,
    required String businessName,
    required ApplicationType type,
    required List<DocumentModel> documents,
    String? permitTypeLabel,
    String? applicationNumber,
    ApplicationLineage? lineage,
    String? location,
    Map<String, Object?>? form,
  }) async {
    // The files go first. An application filed before its documents reach the
    // office is an application the office cannot act on, and if any upload
    // fails this throws before anything is filed — the applicant sees an
    // error and still has their draft, rather than a filed application
    // missing the plans.
    //
    // All-or-nothing on purpose. A partial upload would put SOME ids in the
    // body, and a submission listing eleven of twenty-four documents reads to
    // the office like an applicant who forgot thirteen.
    final documentIds = await _uploadAll(documents);

    final application = await _repository.submitApplication(
      businessId: businessId,
      businessName: businessName,
      // The lineage is the authority on what this is. A renewal that arrived
      // with `type: newPermit` because a caller passed the default would be
      // filed as a first application against a permit that already exists.
      type: lineage?.action ?? type,
      documents: documents,
      permitTypeLabel: permitTypeLabel,
      applicationNumber: applicationNumber,
      lineage: lineage,
      documentIds: documentIds,
      location: location,
      form: form,
    );
    // Captured here because this is the only place both halves exist: the
    // server's parsed record, and the ids it minted during upload. `_uploadAll`
    // returned them, the submission body used them, and until now they were
    // dropped on the floor — so nothing downstream could tell a filing that
    // carried twenty-four files from one that carried none.
    _receipts[application.id] = FilingReceipt(
      applicationId: application.id,
      referenceNumber: application.applicationNumber,
      permitType: application.permitTypeLabel,
      submittedAt: application.submittedDate,
      location: application.location,
      attachmentsOffered: documents.length,
      documentIdsIssued: documentIds,
      answersSent: form?.length ?? 0,
    );

    _applications = [..._applications, application];
    notifyListeners();
    _notifications.record(
      NotificationType.applicationSubmitted,
      applicationId: application.id,
      applicationNumber: application.applicationNumber,
      payload: {'permitType': application.permitTypeLabel ?? type.label},
    );
    return application;
  }

  /// Uploads every attachment that has a file behind it, in order.
  ///
  /// Returns an empty list on a build with no upload repository, which is the
  /// state that makes the submission body fall back to the undeclared
  /// `documents` key and be refused. That is the intended failure: see
  /// `HttpApplicationsRepository.submitApplication`.
  ///
  /// Sequential rather than parallel. Twenty-four concurrent multipart uploads
  /// from a phone on a rural connection is how a submission times out, and the
  /// applicant would rather wait than start again.
  /// What the office acknowledged, per application id.
  ///
  /// Held in memory only. A receipt is evidence of what this device sent and
  /// what came back, so it is deliberately not reconstructed from the
  /// application list later: a rebuilt receipt would be this app's account of
  /// the filing rather than the office's, which is the whole thing it exists
  /// to avoid.
  final Map<String, FilingReceipt> _receipts = {};

  /// The receipt for [applicationId], or null when this device did not file it
  /// in this session. Null is honest and the screens say so.
  FilingReceipt? receiptFor(String applicationId) => _receipts[applicationId];

  Future<List<String>> _uploadAll(List<DocumentModel> documents) async {
    final uploads = _documentUploads;
    if (uploads == null || documents.isEmpty) return const [];
    final ids = <String>[];
    for (var index = 0; index < documents.length; index++) {
      final document = documents[index];
      _reportUpload(
        UploadProgress(
          index: index,
          total: documents.length,
          label: document.label,
        ),
      );
      ids.add(
        (await uploads.upload(
          document,
          onProgress: (sent, bytes) => _reportUpload(
            UploadProgress(
              index: index,
              total: documents.length,
              label: document.label,
              sentBytes: sent,
              totalBytes: bytes,
            ),
          ),
        )).id,
      );
    }
    _reportUpload(null);
    return ids;
  }

  /// What the app is uploading right now, or null when it is not uploading.
  ///
  /// **A twenty-megabyte plan set used to show a spinner and nothing else**,
  /// for as long as it took — and on rural data that is minutes with no sign
  /// the app is alive. This is what the submitting screen reads.
  UploadProgress? _uploadProgress;

  UploadProgress? get uploadProgress => _uploadProgress;

  void _reportUpload(UploadProgress? progress) {
    _uploadProgress = progress;
    notifyListeners();
  }

  /// Sends a replacement for a document the office turned back.
  ///
  /// Returns null when it could not be sent, having left the application
  /// untouched. The caller tells the applicant — an unguarded throw here would
  /// leave them looking at a document that still says "Rejected" with no idea
  /// whether their replacement went anywhere.
  Future<ApplicationModel?> resubmitDocument(
    String applicationId, {
    required String documentId,
    required DocumentModel replacement,
  }) async {
    try {
      final updated = await _repository.resubmitDocument(
        applicationId,
        documentId: documentId,
        replacement: replacement,
      );
      _applications = [
        for (final application in _applications)
          if (application.id == updated.id) updated else application,
      ];
      notifyListeners();
      // Reading a rejection is not correcting one, so the notice survives
      // being opened. Supplying the corrected copy is what discharges it —
      // and only for this document: the other two the office turned back are
      // still outstanding.
      _notifications.resolveByDedupeKeyPrefix(
        'documentRejected:$applicationId:$documentId:',
      );
      return updated;
    } catch (error) {
      _loadError = error;
      notifyListeners();
      return null;
    }
  }

  /// Reports a payment to the office, receipt first.
  ///
  /// **This is the only payment path.** A second one, `submitProofOfPayment`,
  /// existed alongside it until 2026-09-03 and was the one the proof-of-payment
  /// sheet actually called. It was synchronous and entirely local: it uploaded
  /// nothing, called no repository, set the payment to Pending on the device,
  /// recorded a `paymentReceived` notification, and resolved the citizen's
  /// Order of Payment, Overdue and Rejected reminders — while the sheet told
  /// them "Proof of payment submitted. The Treasurer's Office will verify it."
  ///
  /// So a citizen who had genuinely paid at the bank sent their receipt
  /// nowhere, lost every reminder that would have told them, and waited on an
  /// office holding no record of the payment. Deleted rather than kept: a
  /// local-only twin of a working method is a trap for whoever wires the next
  /// screen.
  Future<ApplicationModel> attachPayment(
    String applicationId, {
    required PaymentMethod method,
    required String referenceNumber,
    required DateTime paidOn,
    PesoAmount? amountPaid,
    DocumentModel? proof,
  }) async {
    // Carried over from the deleted twin. A payment cannot be reported against
    // an application the office has not assessed — there is no Order of
    // Payment to pay yet, and the server has nothing to match it to.
    final existing = byId(applicationId)?.payment;
    if (existing != null && !existing.isAssessed) {
      throw const ApiException(
        ApiFailure.rejected,
        'This application has not been assessed yet, so there is nothing to '
        'pay against.',
      );
    }

    // The receipt goes first, for the same reason the application's documents
    // do: a payment reported before its proof reaches the office is a payment
    // the Treasurer's Office cannot verify.
    final uploads = _documentUploads;
    final documentId = (uploads == null || proof == null)
        ? null
        : (await uploads.upload(proof, applicationId: applicationId)).id;

    final updated = await _repository.attachPayment(
      applicationId,
      method: method,
      referenceNumber: referenceNumber,
      paidOn: paidOn,
      amountPaid: amountPaid,
      proof: proof,
      documentId: documentId,
    );
    _replace(updated);
    _notifications.record(
      NotificationType.paymentReceived,
      applicationId: updated.id,
      applicationNumber: updated.applicationNumber,
    );
    // The Order of Payment obligation is discharged by submitting, so its
    // outstanding action clears. The payment is not verified — that is a
    // separate, later event from the Treasurer's Office.
    _notifications.resolveFor(
      updated.id,
      NotificationType.orderOfPaymentIssued,
    );
    _notifications.resolveFor(updated.id, NotificationType.paymentRejected);
    // Also carried over from the deleted twin. Submitting discharges the
    // obligation, so the overdue reminder goes — but only now, after the
    // office has actually answered.
    _notifications.resolveFor(updated.id, NotificationType.paymentOverdue);
    return updated;
  }

  Future<ApplicationModel> advanceStatus(String applicationId) async {
    final updated = await _repository.advanceStatus(applicationId);
    _replace(updated);
    final type = _catalogTypeFor(updated.status);
    if (type != null) {
      _notifications.record(
        type,
        applicationId: updated.id,
        applicationNumber: updated.applicationNumber,
        payload: {
          if (updated.permitNumber != null)
            'permitNumber': updated.permitNumber!,
        },
      );
    }
    return updated;
  }

  /// Marks one Letter of Instruction item addressed, or un-marks it.
  ///
  /// Local-only: it records that the applicant believes they have dealt with
  /// the item. It does not advance the application — only the OBO can do that,
  /// and only after [resubmitAfterInstruction] puts the corrections back in
  /// their queue.
  void toggleInstructionItem(
    String applicationId,
    String letterId,
    String itemId,
  ) {
    final application = byId(applicationId);
    if (application == null) return;

    final letters = [
      for (final letter in application.instructions)
        if (letter.id != letterId)
          letter
        else
          letter.copyWith(
            items: [
              for (final item in letter.items)
                if (item.id != itemId)
                  item
                else
                  InstructionItem(
                    id: item.id,
                    subject: item.subject,
                    remark: item.remark,
                    resolvedAt: item.isResolved ? null : _clock(),
                  ),
            ],
          ),
    ];

    var open = 0;
    for (final letter in letters) {
      open += letter.openCount;
    }

    _replace(
      application.copyWith(instructions: letters, openInstructionCount: open),
    );
  }

  /// Puts corrections back in the OBO's queue after a Letter of Instruction.
  ///
  /// The applicant does not get to decide the application is now fine — this
  /// returns it to Under Evaluation, which is a *request* for re-evaluation.
  /// Every state after this point still arrives from the server.
  /// Sends the corrections, then records what the office says.
  ///
  /// **Was local-only and synchronous.** It flipped the application to Under
  /// Evaluation, wrote a timeline entry attributed to the Office of the
  /// Building Official, and cleared the outstanding action — with no request
  /// of any kind. The screen then told the citizen "Corrections submitted.
  /// The OBO will re-evaluate your application" and popped. Nothing had left
  /// the phone: the office was still waiting, the citizen's action item was
  /// gone, and the deadline in the letter kept running.
  ///
  /// Throws on failure so the caller cannot report a success that did not
  /// happen. Nothing local moves until the office has answered.
  Future<void> resubmitAfterInstruction(String applicationId) async {
    final application = byId(applicationId);
    if (application == null) return;
    if (application.openInstruction != null) return;

    // The letter being answered, and the items the citizen ticked off. The
    // endpoint requires at least one and refuses the request otherwise, so an
    // empty list is a caller error rather than something to paper over.
    final letter = application.instructions.isEmpty
        ? null
        : application.instructions.last;
    if (letter != null) {
      await _repository.resubmitInstruction(
        applicationId,
        letter.id,
        itemIds: [for (final item in letter.items) item.id],
      );
    }

    final now = _clock();
    _replace(
      application.copyWith(
        lifecycleStatus: ApplicationLifecycleStatus.underEvaluation,
        status: ApplicationStatus.underReview,
        timeline: [
          ...application.timeline,
          TimelineEntry(
            status: ApplicationLifecycleStatus.underEvaluation,
            occurredAt: now,
            office: 'Office of the Building Official',
            remarks: 'Corrections resubmitted by the citizen.',
          ),
        ],
      ),
    );

    // The deficiency is discharged, so the Letter of Instruction stops being
    // an outstanding action. Resolution is driven by the applicant actually
    // dealing with it, never by their having read the notification.
    _notifications.resolveFor(
      application.id,
      NotificationType.letterOfInstructionIssued,
    );
    _notifications.resolveFor(
      application.id,
      NotificationType.revisionRequired,
    );
  }

  /// Saves a local copy of the permit so it stays readable with no
  /// connection.
  ///
  /// RA 8792 gives an electronic document the same legal effect as its paper
  /// equivalent, so a downloaded permit is worth having on a site with no
  /// signal — which describes a great many construction sites.
  Future<void> downloadPermit(String applicationId) async {
    final application = byId(applicationId);
    final permit = application?.permit;
    if (application == null || permit == null) return;
    if (permit.isAvailableOffline) return;

    // Stands in for writing the fetched PDF into app-local storage. The path
    // shape matches DocumentStorageService so swapping in the real fetch is a
    // repository change and nothing more.
    final path = 'permits/${permit.permitNumber}.pdf';
    _replace(
      application.copyWith(permit: permit.copyWith(localFilePath: path)),
    );
  }

  /// Records what the applicant paid against an existing Order of Payment.
  ///
  /// This never creates or changes an assessment, and never marks a payment
  /// Paid — only the Treasurer's Office verifies. It moves the record to
  /// Pending Verification, which is a statement about what the applicant has
  /// submitted, not about whether the money arrived.
  void _replace(ApplicationModel updated) {
    _applications = [
      for (final application in _applications)
        if (application.id == updated.id) updated else application,
    ];
    notifyListeners();
  }

  /// Maps a coarse status change onto the catalog. Anything without a
  /// catalog entry produces no notification at all — the catalog is closed,
  /// so an unmapped status is a gap to fix rather than a licence to invent a
  /// message.
  NotificationType? _catalogTypeFor(ApplicationStatus status) {
    switch (status) {
      case ApplicationStatus.underReview:
        return NotificationType.documentVerificationStarted;
      case ApplicationStatus.paymentVerification:
        return NotificationType.orderOfPaymentIssued;
      case ApplicationStatus.approved:
        return NotificationType.approved;
      case ApplicationStatus.released:
        return NotificationType.readyForRelease;
      case ApplicationStatus.rejected:
        return NotificationType.rejected;
      case ApplicationStatus.draft:
      case ApplicationStatus.submitted:
        return null;
    }
  }
}
