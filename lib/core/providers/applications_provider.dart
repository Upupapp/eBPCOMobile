import 'package:flutter/material.dart';

import '../models/action_item.dart';
import '../models/application_detail.dart';
import '../models/application_model.dart';
import '../models/lifecycle_status.dart';
import '../models/notification_event.dart';
import '../notifications/notification_evaluator.dart';
import '../models/document_model.dart';
import '../models/payment_assessment_model.dart';
import '../repositories/applications_repository.dart';
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
    ServicePledgeService? pledgeService,
    this.actionItemBuilder = const ActionItemBuilder(),
    DateTime Function()? clock,
  }) : _pledgeService = pledgeService ?? const ServicePledgeService(),
       _clock = clock ?? DateTime.now {
    _load();
  }

  final ApplicationsRepository _repository;
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

  ApplicationModel? byId(String id) {
    for (final application in _applications) {
      if (application.id == id) return application;
    }
    return null;
  }

  Future<void> _load() async {
    try {
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
  }) async {
    final application = await _repository.submitApplication(
      businessId: businessId,
      businessName: businessName,
      type: type,
      documents: documents,
      permitTypeLabel: permitTypeLabel,
      applicationNumber: applicationNumber,
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
      return updated;
    } catch (error) {
      _loadError = error;
      notifyListeners();
      return null;
    }
  }

  Future<ApplicationModel> attachPayment(
    String applicationId, {
    required PaymentMethod method,
    DocumentModel? proof,
  }) async {
    final updated = await _repository.attachPayment(
      applicationId,
      method: method,
      proof: proof,
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
  void resubmitAfterInstruction(String applicationId) {
    final application = byId(applicationId);
    if (application == null) return;
    if (application.openInstruction != null) return;

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
            remarks: 'Corrections resubmitted by the applicant.',
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
  void submitProofOfPayment(
    String applicationId, {
    required PaymentMethod method,
    required String referenceNumber,
    required DocumentModel proof,
  }) {
    final application = byId(applicationId);
    final payment = application?.payment;
    if (application == null || payment == null) return;
    if (!payment.isAssessed) return;

    _replace(
      application.copyWith(
        payment: payment.copyWith(
          status: PaymentAssessmentStatus.pending,
          method: method,
          referenceNumber: referenceNumber,
          proof: proof,
          submittedAt: _clock(),
        ),
      ),
    );

    _notifications.record(
      NotificationType.paymentReceived,
      applicationId: application.id,
      applicationNumber: application.applicationNumber,
    );
    _notifications.resolveFor(
      application.id,
      NotificationType.orderOfPaymentIssued,
    );
    _notifications.resolveFor(application.id, NotificationType.paymentOverdue);
  }

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
