import '../contract/admin_vocabulary.dart';
import '../models/application_model.dart';
import '../models/draft_summary.dart';
import '../models/lifecycle_status.dart';
import '../models/notification_event.dart';
import '../models/permit_classification.dart';
import '../models/professional_model.dart';
import '../services/service_pledge_service.dart';

/// A notification the app worked out for itself, ready to be recorded.
///
/// [dedupeKey] is what stops the feed filling with copies. The evaluator runs
/// on every load, so it will keep deriving the same conditions for as long as
/// they hold; the key identifies *this occurrence of this condition for this
/// subject*, so a second run recognises it and does nothing.
class DerivedNotification {
  final NotificationType type;
  final String dedupeKey;
  final String? applicationId;
  final String? applicationNumber;
  final Map<String, String> payload;

  const DerivedNotification({
    required this.type,
    required this.dedupeKey,
    this.applicationId,
    this.applicationNumber,
    this.payload = const {},
  });
}

/// Derives the notifications the app can work out without a server.
///
/// Some of the catalog originates with the LGU — a clearance issued, a payment
/// verified — and arrives over the wire. These five do not. The app already
/// computes every one of the underlying conditions to render Home and the
/// professionals list; before this, it computed them and then dropped them, so
/// a lapsed service pledge or an expiring PRC was known to the app and never
/// said out loud.
///
/// Pure and synchronous: given the same inputs it returns the same list, which
/// is what makes the dedupe keys stable and the whole thing testable without a
/// widget tree.
class NotificationEvaluator {
  const NotificationEvaluator({
    this.pledgeService = const ServicePledgeService(),
  });

  final ServicePledgeService pledgeService;

  List<DerivedNotification> evaluate({
    required List<ApplicationModel> applications,
    List<ProfessionalModel> professionals = const [],
    List<DraftSummary> drafts = const [],
    required DateTime asOf,
  }) {
    final derived = <DerivedNotification>[];

    for (final application in applications) {
      derived.addAll(_forApplication(application, asOf));
    }
    for (final professional in professionals) {
      final credential = _forProfessional(professional, asOf);
      if (credential != null) derived.add(credential);
    }
    for (final draft in drafts) {
      final idle = _forDraft(draft, asOf);
      if (idle != null) derived.add(idle);
    }

    return derived;
  }

  DerivedNotification? _forDraft(DraftSummary draft, DateTime asOf) {
    if (!draft.isIdle(asOf)) return null;
    final days = draft.daysSinceSaved(asOf)!;
    return DerivedNotification(
      type: NotificationType.draftIdle,
      // Keyed on the save date, so the nudge repeats if the applicant opens
      // the draft, changes something, and abandons it again — but not while
      // the same untouched draft simply sits there.
      dedupeKey: '${draft.route}:${_dateKey(draft.lastSavedAt!)}',
      payload: {
        'permitType': draft.permitTypeLabel,
        'percent': '${draft.percentComplete}',
        'days': '$days',
        'route': draft.route,
      },
    );
  }

  Iterable<DerivedNotification> _forApplication(
    ApplicationModel application,
    DateTime asOf,
  ) sync* {
    final reference = application.applicationNumber;

    // -- service pledge ---------------------------------------------------
    final classification = application.classification;
    if (classification != null && application.isInFlight) {
      final pledge = pledgeService.computeFor(
        filedOn: application.submittedDate,
        classification: classification,
        asOf: asOf,
      );
      final due = _dateKey(pledge.pledgedCompletionDate);

      if (pledge.hasLapsed) {
        yield DerivedNotification(
          type: NotificationType.pledgeLapsed,
          // Keyed on the pledged date rather than the application alone, so a
          // re-filed application with a new pledge can lapse again.
          dedupeKey: 'pledgeLapsed:${application.id}:$due',
          applicationId: application.id,
          applicationNumber: reference,
          payload: {'days': '${classification.prescribedWorkingDays}'},
        );
      } else if (pledge.isDueSoon) {
        yield DerivedNotification(
          type: NotificationType.pledgeApproaching,
          dedupeKey: 'pledgeApproaching:${application.id}:$due',
          applicationId: application.id,
          applicationNumber: reference,
          payload: {
            'days': '${pledge.workingDaysRemaining}',
            'classification': classification.label,
          },
        );
      }
    }

    // -- PD 1096 commencement deadline ------------------------------------
    final commenceBy = application.commenceByDate;
    final permitNumber =
        application.permitNumber ?? application.permit?.permitNumber;
    if (commenceBy != null) {
      final daysLeft = _daysBetween(asOf, commenceBy);
      if (daysLeft <= ApplicationModel.commencementWarningDays) {
        yield DerivedNotification(
          type: NotificationType.permitCommencementWarning,
          // Bucketed, so the applicant is told once at sixty days, once at
          // thirty, and once when it has gone — not every time they open the
          // app for two months.
          dedupeKey:
              'commencement:${application.id}:${_commencementBucket(daysLeft)}',
          applicationId: application.id,
          applicationNumber: reference,
          payload: {
            'permitNumber': ?permitNumber,
            'date': _dateKey(commenceBy),
            'days': '$daysLeft',
          },
        );
      }
    }

    // -- permit validity ---------------------------------------------------
    //
    // A second deadline on the same permit, and not the one above. PD 1096's
    // commencement rule is about work starting; validity is how long the
    // permit itself lasts — six months, twelve, or none for a Certificate of
    // Occupancy. A Fencing Permit expires before it must be commenced, so an
    // applicant told only about commencement is told the later of the two
    // dates and none of the consequence.
    final expiry = application.expiryDate;
    if (expiry != null) {
      final daysLeft = _daysBetween(asOf, expiry);
      if (daysLeft <= ApplicationModel.commencementWarningDays) {
        yield DerivedNotification(
          type: NotificationType.permitExpiryWarning,
          // Same 60/30/lapsed bucketing as commencement, and deliberately a
          // separate key namespace: both can be outstanding at once on a
          // twelve-month permit, where the two dates coincide.
          dedupeKey:
              'expiry:${application.id}:${_commencementBucket(daysLeft)}',
          applicationId: application.id,
          applicationNumber: reference,
          payload: {
            'permitNumber': ?permitNumber,
            'date': _dateKey(expiry),
            'days': '$daysLeft',
          },
        );
      }
    }

    // -- documents the office turned back ----------------------------------
    //
    // One notice per document, not one per application. The remarks are what
    // the applicant has to act on, and merging three rejections into "3
    // documents need attention" throws away the only part that tells them
    // what to do.
    for (final document in application.documents) {
      if (document.status != DocumentStatus.rejected &&
          document.status != DocumentStatus.revisionRequired) {
        continue;
      }
      yield DerivedNotification(
        type: NotificationType.documentRejected,
        // Keyed on the document and how many times it has been submitted, so
        // a corrected copy that is turned back again raises a fresh notice
        // rather than being swallowed by the resolved one.
        dedupeKey:
            'documentRejected:${application.id}:${document.id}'
            ':${document.history.length}',
        applicationId: application.id,
        applicationNumber: reference,
        payload: {'document': document.label, 'remarks': ?document.remarks},
      );
    }

    // -- payments the office refused, and assessments it replaced ----------
    final payment = application.payment;
    if (payment != null) {
      for (final transaction in payment.rejectedTransactions) {
        yield DerivedNotification(
          type: NotificationType.paymentRejected,
          // The transaction id is already unique per attempt, so paying again
          // and being refused again says so again.
          dedupeKey: 'paymentRejected:${application.id}:${transaction.id}',
          applicationId: application.id,
          applicationNumber: reference,
          payload: {'reason': ?transaction.rejectionReason},
        );
      }

      // A revised Order of Payment. Progress rather than action: the
      // replacement carries its own orderOfPaymentIssued with the new total,
      // and two notices disagreeing about what is owed is worse than one
      // saying less.
      final current = payment.orderOfPayment;
      if (payment.wasReassessed && current != null) {
        yield DerivedNotification(
          type: NotificationType.assessmentSuperseded,
          // Keyed on the version that replaced them, so a second revision is
          // announced too.
          dedupeKey: 'superseded:${application.id}:v${current.version}',
          applicationId: application.id,
          applicationNumber: reference,
          payload: {'reason': ?current.revisionReason},
        );
      }
    }

    // -- occupancy now possible -------------------------------------------
    //
    // A released construction permit is the point at which a Certificate of
    // Occupancy becomes the applicant's next filing. Excluded for the
    // Certificate of Occupancy itself, which would otherwise invite the
    // applicant to file the thing they have just been granted.
    final isReleased =
        application.lifecycleStatus == ApplicationLifecycleStatus.released ||
        application.lifecycleStatus == ApplicationLifecycleStatus.completed;
    final permitType = application.permitTypeLabel;
    if (isReleased &&
        permitType != null &&
        permitType != 'Certificate of Occupancy') {
      yield DerivedNotification(
        type: NotificationType.occupancyNowPossible,
        dedupeKey: 'occupancy:${application.id}',
        applicationId: application.id,
        applicationNumber: reference,
        payload: {'permitNumber': ?permitNumber},
      );
    }
  }

  DerivedNotification? _forProfessional(
    ProfessionalModel professional,
    DateTime asOf,
  ) {
    if (!professional.prcNeedsAttention(asOf)) return null;
    return DerivedNotification(
      type: NotificationType.professionalCredentialExpiring,
      // Keyed on the validity date, so renewing the licence re-arms the
      // warning for the next expiry instead of silencing it forever.
      dedupeKey:
          'prc:${professional.id}:${_dateKey(professional.prcValidityDate)}',
      payload: {
        'professional': professional.fullName,
        'date': _dateKey(professional.prcValidityDate),
      },
    );
  }

  /// Which side of the 60/30/lapsed thresholds a deadline falls on.
  static String _commencementBucket(int daysLeft) {
    if (daysLeft < 0) return 'lapsed';
    if (daysLeft <= 30) return '30';
    return '60';
  }

  static String _dateKey(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';

  static int _daysBetween(DateTime from, DateTime to) => DateTime(
    to.year,
    to.month,
    to.day,
  ).difference(DateTime(from.year, from.month, from.day)).inDays;
}
