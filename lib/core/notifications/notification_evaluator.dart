import '../models/application_model.dart';
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

  /// Warn this far ahead of a permit lapsing under PD 1096. Matches the Home
  /// action stack, so the two cannot disagree about what "soon" means.
  static const int commencementWarningDays = 60;

  List<DerivedNotification> evaluate({
    required List<ApplicationModel> applications,
    List<ProfessionalModel> professionals = const [],
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

    return derived;
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
    final permitNumber = application.permitNumber ?? application.permit?.permitNumber;
    if (commenceBy != null) {
      final daysLeft = _daysBetween(asOf, commenceBy);
      if (daysLeft <= commencementWarningDays) {
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
    if (isReleased && permitType != null && permitType != 'Certificate of Occupancy') {
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

  static int _daysBetween(DateTime from, DateTime to) =>
      DateTime(to.year, to.month, to.day)
          .difference(DateTime(from.year, from.month, from.day))
          .inDays;
}
