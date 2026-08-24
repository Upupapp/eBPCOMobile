import 'package:flutter/material.dart';

/// How loudly an event is delivered.
enum NotificationPriority {
  /// Push, in-app banner, tab badge. Persists until the underlying condition
  /// is resolved.
  action,

  /// Push and feed entry. No persistent banner.
  progress,

  /// Feed entry only. Never pushes.
  ambient,
}

extension NotificationPriorityX on NotificationPriority {
  String get label {
    switch (this) {
      case NotificationPriority.action:
        return 'Needs your action';
      case NotificationPriority.progress:
        return 'Update';
      case NotificationPriority.ambient:
        return 'Info';
    }
  }

  bool get pushesByDefault => this != NotificationPriority.ambient;
}

/// Preference buckets the applicant can mute. Muting suppresses the push and
/// still records the feed entry — the applicant asked for fewer
/// interruptions, not for the record to be withheld.
enum NotificationCategory {
  applicationUpdates,
  payments,
  permitStatus,
  documentReminders,
  appointments,
  account,
}

/// The catalog. Every application-lifecycle notification the app can produce
/// is one of these, and each carries its code, priority, category, and where
/// it goes.
///
/// [accountUpdate] is deliberately outside the numbered catalog: the catalog
/// governs application lifecycle, and events like registering a business are
/// not about an application at all.
enum NotificationType {
  applicationSubmitted,
  receivedByObo,
  documentVerificationStarted,
  letterOfInstructionIssued,
  evaluationStagePassed,
  revisionRequired,
  fsecCleared,
  orderOfPaymentIssued,
  paymentReceived,
  paymentVerified,
  paymentOverdue,
  approved,
  permitGenerated,
  readyForRelease,
  released,
  rejected,
  inspectionScheduled,
  appointmentReminder,
  pledgeApproaching,
  pledgeLapsed,
  permitCommencementWarning,
  professionalCredentialExpiring,
  draftIdle,
  occupancyNowPossible,
  accountUpdate,
}

extension NotificationTypeX on NotificationType {
  /// Catalog code, or null for events outside the numbered catalog.
  String? get code {
    final index = NotificationType.values.indexOf(this);
    if (this == NotificationType.accountUpdate) return null;
    return 'N-${(index + 1).toString().padLeft(2, '0')}';
  }

  NotificationPriority get priority {
    switch (this) {
      case NotificationType.letterOfInstructionIssued:
      case NotificationType.revisionRequired:
      case NotificationType.orderOfPaymentIssued:
      case NotificationType.paymentOverdue:
      case NotificationType.readyForRelease:
      case NotificationType.rejected:
      case NotificationType.inspectionScheduled:
      case NotificationType.pledgeLapsed:
      case NotificationType.permitCommencementWarning:
        return NotificationPriority.action;

      case NotificationType.documentVerificationStarted:
      case NotificationType.pledgeApproaching:
      case NotificationType.draftIdle:
        return NotificationPriority.ambient;

      default:
        return NotificationPriority.progress;
    }
  }

  NotificationCategory get category {
    switch (this) {
      case NotificationType.orderOfPaymentIssued:
      case NotificationType.paymentReceived:
      case NotificationType.paymentVerified:
      case NotificationType.paymentOverdue:
        return NotificationCategory.payments;

      case NotificationType.approved:
      case NotificationType.permitGenerated:
      case NotificationType.readyForRelease:
      case NotificationType.released:
      case NotificationType.rejected:
      case NotificationType.permitCommencementWarning:
      case NotificationType.occupancyNowPossible:
        return NotificationCategory.permitStatus;

      case NotificationType.letterOfInstructionIssued:
      case NotificationType.revisionRequired:
      case NotificationType.documentVerificationStarted:
      case NotificationType.professionalCredentialExpiring:
      case NotificationType.draftIdle:
        return NotificationCategory.documentReminders;

      case NotificationType.inspectionScheduled:
      case NotificationType.appointmentReminder:
        return NotificationCategory.appointments;

      case NotificationType.accountUpdate:
        return NotificationCategory.account;

      default:
        return NotificationCategory.applicationUpdates;
    }
  }

  IconData get icon {
    switch (this) {
      case NotificationType.letterOfInstructionIssued:
        return Icons.assignment_late_outlined;
      case NotificationType.revisionRequired:
        return Icons.edit_document;
      case NotificationType.orderOfPaymentIssued:
      case NotificationType.paymentReceived:
      case NotificationType.paymentVerified:
        return Icons.receipt_long_outlined;
      case NotificationType.paymentOverdue:
        return Icons.warning_amber_rounded;
      case NotificationType.readyForRelease:
      case NotificationType.released:
        return Icons.inventory_2_outlined;
      case NotificationType.rejected:
        return Icons.report_gmailerrorred_outlined;
      case NotificationType.inspectionScheduled:
      case NotificationType.appointmentReminder:
        return Icons.event_available_outlined;
      case NotificationType.permitCommencementWarning:
      case NotificationType.pledgeLapsed:
      case NotificationType.pledgeApproaching:
        return Icons.timelapse_outlined;
      case NotificationType.approved:
      case NotificationType.permitGenerated:
        return Icons.verified_outlined;
      case NotificationType.professionalCredentialExpiring:
        return Icons.badge_outlined;
      case NotificationType.occupancyNowPossible:
        return Icons.home_work_outlined;
      case NotificationType.draftIdle:
        return Icons.edit_note_outlined;
      default:
        return Icons.notifications_active_outlined;
    }
  }
}

/// One notification, from production through to resolution.
///
/// The distinction that matters is [readAt] versus [resolvedAt]. Reading is
/// not resolving: an applicant who opens a Letter of Instruction and closes it
/// again has not corrected anything, so a P1 keeps its banner and its badge
/// until the underlying condition actually clears. Conflating the two is how
/// an app quietly loses the one message it most needed to land.
class NotificationEvent {
  final String id;
  final NotificationType type;
  final String? applicationId;

  /// Reference shown in the body, so an applicant with several permits in
  /// flight can tell which one is being discussed.
  final String? applicationNumber;

  /// Template values — permit type, amount, remarks, dates, counts.
  final Map<String, String> payload;

  final DateTime createdAt;
  final DateTime? readAt;
  final DateTime? resolvedAt;

  /// True when delivery was suppressed by the applicant's preferences or by
  /// quiet hours. The feed entry is recorded either way.
  final bool pushSuppressed;

  /// Identifies the condition this was derived from, for events the app works
  /// out itself rather than receives. Null for anything server-sent or posted
  /// by a user action.
  ///
  /// The evaluator re-derives every condition on every load, so without this
  /// an applicant whose pledge has lapsed would collect one identical entry
  /// per app launch.
  final String? dedupeKey;

  const NotificationEvent({
    required this.id,
    required this.type,
    required this.createdAt,
    this.applicationId,
    this.applicationNumber,
    this.payload = const {},
    this.readAt,
    this.resolvedAt,
    this.pushSuppressed = false,
    this.dedupeKey,
  });

  bool get isRead => readAt != null;
  bool get isResolved => resolvedAt != null;

  NotificationPriority get priority => type.priority;

  /// A P1 that has not been dealt with. Drives the tab badge and the Home
  /// action stack, independently of read state.
  bool get isOutstandingAction =>
      priority == NotificationPriority.action && !isResolved;

  NotificationEvent copyWith({DateTime? readAt, DateTime? resolvedAt}) =>
      NotificationEvent(
        id: id,
        type: type,
        applicationId: applicationId,
        applicationNumber: applicationNumber,
        payload: payload,
        createdAt: createdAt,
        readAt: readAt ?? this.readAt,
        resolvedAt: resolvedAt ?? this.resolvedAt,
        pushSuppressed: pushSuppressed,
        dedupeKey: dedupeKey,
      );

  String get title {
    switch (type) {
      case NotificationType.applicationSubmitted:
        return 'Application filed';
      case NotificationType.receivedByObo:
        return 'Received by the OBO';
      case NotificationType.documentVerificationStarted:
        return 'Documents being checked';
      case NotificationType.letterOfInstructionIssued:
        return 'Letter of Instruction issued';
      case NotificationType.evaluationStagePassed:
        return '${payload['stage'] ?? 'Evaluation'} passed';
      case NotificationType.revisionRequired:
        return 'Revision required';
      case NotificationType.fsecCleared:
        return 'Fire Safety Evaluation Clearance issued';
      case NotificationType.orderOfPaymentIssued:
        return 'Order of Payment ready';
      case NotificationType.paymentReceived:
        return 'Payment details received';
      case NotificationType.paymentVerified:
        return 'Payment verified';
      case NotificationType.paymentOverdue:
        return 'Payment overdue';
      case NotificationType.approved:
        return 'Application approved';
      case NotificationType.permitGenerated:
        return 'Permit generated';
      case NotificationType.readyForRelease:
        return 'Permit ready to claim';
      case NotificationType.released:
        return 'Permit released';
      case NotificationType.rejected:
        return 'Application not approved';
      case NotificationType.inspectionScheduled:
        return 'Joint inspection scheduled';
      case NotificationType.appointmentReminder:
        return 'Appointment tomorrow';
      case NotificationType.pledgeApproaching:
        return 'Target release date approaching';
      case NotificationType.pledgeLapsed:
        return 'Service pledge has lapsed';
      case NotificationType.permitCommencementWarning:
        return 'Work must start soon';
      case NotificationType.professionalCredentialExpiring:
        return 'Professional credential expiring';
      case NotificationType.draftIdle:
        return 'Unfinished draft';
      case NotificationType.occupancyNowPossible:
        return 'You may file for occupancy';
      case NotificationType.accountUpdate:
        return payload['title'] ?? 'Account update';
    }
  }

  /// The body. Every application-related message names its reference, because
  /// an applicant with several permits in flight cannot otherwise tell which
  /// one this is about.
  String get body {
    final ref = applicationNumber ?? 'your application';
    switch (type) {
      case NotificationType.applicationSubmitted:
        return 'Application $ref for ${payload['permitType'] ?? 'your permit'} '
            'has been filed.'
            '${payload['pledgeDate'] != null ? ' Target release: ${payload['pledgeDate']}.' : ''}';
      case NotificationType.receivedByObo:
        return 'The Office of the Building Official has received $ref. '
            'Processing has started.';
      case NotificationType.documentVerificationStarted:
        return 'Your documents for $ref are being checked.';
      case NotificationType.letterOfInstructionIssued:
        final n = payload['count'] ?? 'Some';
        return 'Action needed on $ref. $n item(s) must be corrected or '
            'supplied. Tap to see the list.';
      case NotificationType.evaluationStagePassed:
        return '${payload['stage'] ?? 'Evaluation'} evaluation passed for $ref.';
      case NotificationType.revisionRequired:
        return '${payload['stage'] ?? 'An'} evaluation returned $ref for '
            'revision.'
            '${payload['remarks'] != null ? ' Evaluator’s remarks: "${payload['remarks']}"' : ''}';
      case NotificationType.fsecCleared:
        return 'Fire Safety Evaluation Clearance issued for $ref.';
      case NotificationType.orderOfPaymentIssued:
        return 'Your Order of Payment for $ref is ready: '
            '${payload['total'] ?? 'see the breakdown'}. Tap to view the '
            'breakdown.';
      case NotificationType.paymentReceived:
        return 'We received your payment details for $ref. Verification '
            'usually takes a few working days.';
      case NotificationType.paymentVerified:
        return 'Payment for $ref is verified.'
            '${payload['orNumber'] != null ? ' Official receipt ${payload['orNumber']}.' : ''}';
      case NotificationType.paymentOverdue:
        return 'The Order of Payment for $ref is past due. Unpaid '
            'applications may lapse.';
      case NotificationType.approved:
        return '$ref has been approved by the Building Official.';
      case NotificationType.permitGenerated:
        return 'The permit for $ref'
            '${payload['permitNumber'] != null ? ' (${payload['permitNumber']})' : ''}'
            ' has been generated.';
      case NotificationType.readyForRelease:
        return 'The permit for $ref'
            '${payload['permitNumber'] != null ? ' (${payload['permitNumber']})' : ''}'
            ' is ready to claim. Tap for claim instructions and requirements.';
      case NotificationType.released:
        return 'The permit for $ref'
            '${payload['permitNumber'] != null ? ' (${payload['permitNumber']})' : ''}'
            ' was released'
            '${payload['claimant'] != null ? ' to ${payload['claimant']}' : ''}'
            '${payload['date'] != null ? ' on ${payload['date']}' : ''}. '
            'Your digital copy is available.';
      case NotificationType.rejected:
        return '$ref was not approved.'
            '${payload['remarks'] != null ? ' Reason: "${payload['remarks']}".' : ''}'
            ' You may refile or appeal.';
      case NotificationType.inspectionScheduled:
        return 'Joint inspection for $ref on ${payload['date'] ?? 'a scheduled date'}'
            '${payload['time'] != null ? ' at ${payload['time']}' : ''}.'
            '${payload['offices'] != null ? ' Attending: ${payload['offices']}.' : ''}';
      case NotificationType.appointmentReminder:
        return 'Your appointment at the OBO for $ref is tomorrow'
            '${payload['date'] != null ? ', ${payload['date']}' : ''}.'
            '${payload['items'] != null ? ' Bring: ${payload['items']}.' : ''}';
      case NotificationType.pledgeApproaching:
        return '$ref is due for release in ${payload['days'] ?? 'a few'} '
            'working days under its ${payload['classification'] ?? 'assigned'} '
            'classification.';
      case NotificationType.pledgeLapsed:
        return '$ref has passed its ${payload['days'] ?? 'prescribed'}-working-'
            'day service pledge. Tap to see your options.';
      case NotificationType.permitCommencementWarning:
        return 'Work under permit ${payload['permitNumber'] ?? ''} for $ref '
            'must start by ${payload['date'] ?? 'its deadline'} or the permit '
            'lapses.'
            '${payload['days'] != null ? ' ${payload['days']} days remain.' : ''}';
      case NotificationType.professionalCredentialExpiring:
        return 'The PRC ID of ${payload['professional'] ?? 'your professional'} '
            'expires on ${payload['date'] ?? 'its stated date'}. Update it '
            'before your next filing.';
      case NotificationType.draftIdle:
        return 'Your ${payload['permitType'] ?? 'permit'} draft is '
            '${payload['percent'] ?? 'partly'}% complete and has not been '
            'touched in ${payload['days'] ?? 'a while'} days.';
      case NotificationType.occupancyNowPossible:
        return 'Construction under ${payload['permitNumber'] ?? 'your permit'} '
            'is complete on record. You may now file for your Certificate of '
            'Occupancy.';
      case NotificationType.accountUpdate:
        return payload['body'] ?? '';
    }
  }

  /// Where tapping goes. Always a screen where the thing can be dealt with —
  /// never a tab root and never a dead end.
  String get deepLink {
    final id = applicationId;
    switch (type) {
      case NotificationType.letterOfInstructionIssued:
        return id == null ? '/app/applications' : '/applications/$id/instructions';
      case NotificationType.orderOfPaymentIssued:
      case NotificationType.paymentReceived:
      case NotificationType.paymentVerified:
      case NotificationType.paymentOverdue:
        return id == null ? '/app/payments' : '/applications/$id/pay';
      case NotificationType.permitGenerated:
      case NotificationType.readyForRelease:
      case NotificationType.released:
      case NotificationType.permitCommencementWarning:
        return id == null ? '/app/applications' : '/applications/$id/permit';
      case NotificationType.rejected:
      case NotificationType.pledgeLapsed:
        return id == null ? '/app/applications' : '/applications/$id/outcome';
      case NotificationType.draftIdle:
        // Back into the wizard itself. Dropping the applicant at the catalog
        // to re-pick a permit they are already part-way through is the kind
        // of small indignity that makes people abandon the draft for good.
        return payload['route'] ?? '/applications/new';
      case NotificationType.occupancyNowPossible:
        return '/applications/new';
      case NotificationType.professionalCredentialExpiring:
        return '/profile/documents';
      case NotificationType.accountUpdate:
        return '/app/profile';
      default:
        return id == null ? '/app/applications' : '/applications/$id';
    }
  }
}
