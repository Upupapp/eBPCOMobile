import 'package:flutter/material.dart';

import 'application_model.dart';
import 'lifecycle_status.dart';
import 'payment_assessment_model.dart';

/// The kinds of outstanding obligation the applicant can be under.
///
/// Declaration order *is* the display order: the Home action stack and the
/// Notifications work queue both sort by it, so regulatory urgency is encoded
/// once here rather than re-decided at each call site.
enum ActionItemKind {
  /// Assessed fees past their due date. First because an unpaid application
  /// can lapse outright.
  overduePayment,

  /// An unresolved Letter of Instruction — the deficiency loop that blocks
  /// everything downstream.
  letterOfInstruction,

  /// An evaluator returned the application for revision.
  revisionRequired,

  /// An Order of Payment has been issued and is not yet paid.
  paymentDue,

  /// The permit is generated and waiting to be claimed.
  readyForRelease,

  /// A joint inspection has been scheduled.
  inspectionScheduled,

  /// A released building permit is approaching its PD 1096 one-year
  /// commencement deadline.
  commencementWarning,

  /// The permit's own validity period is running out.
  ///
  /// A different obligation from [commencementWarning] with a different date:
  /// commencement is about work starting, validity about the permit lasting.
  /// A six-month permit reaches this one first.
  expiryWarning,
}

/// One thing the applicant must do, rendered as a card at the top of Home.
class ActionItem {
  final String id;
  final String applicationId;
  final String applicationNumber;
  final String permitTypeLabel;
  final ActionItemKind kind;

  /// What is required, in the applicant's terms.
  final String title;

  /// One line of supporting detail — an amount, a deadline, a count.
  final String detail;

  /// Label for the single primary action on the card.
  final String actionLabel;

  /// Where the action goes. Always a screen where the thing can actually be
  /// dealt with, never a tab root.
  final String route;

  const ActionItem({
    required this.id,
    required this.applicationId,
    required this.applicationNumber,
    required this.permitTypeLabel,
    required this.kind,
    required this.title,
    required this.detail,
    required this.actionLabel,
    required this.route,
  });

  IconData get icon {
    switch (kind) {
      case ActionItemKind.overduePayment:
        return Icons.warning_amber_rounded;
      case ActionItemKind.letterOfInstruction:
        return Icons.assignment_late_outlined;
      case ActionItemKind.revisionRequired:
        return Icons.edit_document;
      case ActionItemKind.paymentDue:
        return Icons.receipt_long_outlined;
      case ActionItemKind.readyForRelease:
        return Icons.inventory_2_outlined;
      case ActionItemKind.inspectionScheduled:
        return Icons.event_available_outlined;
      case ActionItemKind.commencementWarning:
        return Icons.timelapse_outlined;
      case ActionItemKind.expiryWarning:
        return Icons.event_busy_outlined;
    }
  }

  /// Whether this item is severe enough to warrant the alarm treatment
  /// (rejected palette) rather than the ordinary pending one.
  bool get isCritical =>
      kind == ActionItemKind.overduePayment ||
      kind == ActionItemKind.letterOfInstruction ||
      kind == ActionItemKind.revisionRequired ||
      kind == ActionItemKind.commencementWarning ||
      kind == ActionItemKind.expiryWarning;
}

/// Derives the applicant's outstanding obligations from their applications.
///
/// Pure and synchronous so it can be exercised directly in unit tests without
/// a widget tree, and so the Home tab never has to work out urgency itself.
class ActionItemBuilder {
  const ActionItemBuilder();

  List<ActionItem> build(
    List<ApplicationModel> applications, {
    required DateTime asOf,
  }) {
    final items = <ActionItem>[];

    for (final application in applications) {
      final permitLabel = application.permitTypeLabel ?? application.type.label;

      // An open Letter of Instruction outranks whatever state the record is
      // otherwise in — it is the thing actually blocking progress.
      if (application.openInstructionCount > 0) {
        final n = application.openInstructionCount;
        items.add(
          ActionItem(
            id: '${application.id}-loi',
            applicationId: application.id,
            applicationNumber: application.applicationNumber,
            permitTypeLabel: permitLabel,
            kind: ActionItemKind.letterOfInstruction,
            title: 'Letter of Instruction issued',
            detail: n == 1
                ? '1 item must be corrected or supplied.'
                : '$n items must be corrected or supplied.',
            actionLabel: 'View instructions',
            route: '/applications/${application.id}',
          ),
        );
      }

      switch (application.lifecycleStatus) {
        case ApplicationLifecycleStatus.revisionRequired:
          items.add(
            ActionItem(
              id: '${application.id}-revision',
              applicationId: application.id,
              applicationNumber: application.applicationNumber,
              permitTypeLabel: permitLabel,
              kind: ActionItemKind.revisionRequired,
              title: 'Revision required',
              detail: 'An evaluator returned this for correction.',
              actionLabel: 'See remarks',
              route: '/applications/${application.id}',
            ),
          );
        case ApplicationLifecycleStatus.assessed:
          final payment = application.payment;
          final overdue =
              payment != null &&
              payment.status == PaymentAssessmentStatus.overdue;
          items.add(
            ActionItem(
              id: '${application.id}-payment',
              applicationId: application.id,
              applicationNumber: application.applicationNumber,
              permitTypeLabel: permitLabel,
              kind: overdue
                  ? ActionItemKind.overduePayment
                  : ActionItemKind.paymentDue,
              title: overdue ? 'Payment overdue' : 'Order of Payment ready',
              detail: overdue
                  ? 'Unpaid applications may lapse.'
                  : 'Fees have been assessed and are now due.',
              actionLabel: 'View Order of Payment',
              route: '/applications/${application.id}/pay',
            ),
          );
        case ApplicationLifecycleStatus.readyForRelease:
          items.add(
            ActionItem(
              id: '${application.id}-release',
              applicationId: application.id,
              applicationNumber: application.applicationNumber,
              permitTypeLabel: permitLabel,
              kind: ActionItemKind.readyForRelease,
              title: 'Permit ready to claim',
              detail: application.permitNumber == null
                  ? 'See the claim instructions.'
                  : 'Permit ${application.permitNumber}.',
              actionLabel: 'Claim instructions',
              route: '/applications/${application.id}',
            ),
          );
        default:
          break;
      }

      // PD 1096: a building permit is void if the work it authorises is not
      // commenced within one year.
      final commenceBy = application.commenceByDate;
      if (commenceBy != null) {
        final daysLeft = _daysBetween(asOf, commenceBy);
        if (daysLeft <= ApplicationModel.commencementWarningDays) {
          items.add(
            ActionItem(
              id: '${application.id}-commencement',
              applicationId: application.id,
              applicationNumber: application.applicationNumber,
              permitTypeLabel: permitLabel,
              kind: ActionItemKind.commencementWarning,
              title: daysLeft < 0
                  ? 'Permit may have lapsed'
                  : 'Work must start soon',
              detail: daysLeft < 0
                  ? 'Work was not recorded as started within one year of issue.'
                  : '$daysLeft day(s) left to commence work under PD 1096.',
              actionLabel: 'View permit',
              route: '/applications/${application.id}',
            ),
          );
        }
      }

      // The permit's own validity, which is a separate obligation from the
      // commencement deadline above and can fall due first — a Fencing Permit
      // is valid six months and commencable for twelve. Raised as its own item
      // rather than folded into the commencement one, because the applicant's
      // remedy differs: renew the permit, versus start the work.
      final expiry = application.expiryDate;
      if (expiry != null) {
        final daysLeft = _daysBetween(asOf, expiry);
        if (daysLeft <= ApplicationModel.commencementWarningDays) {
          items.add(
            ActionItem(
              id: '${application.id}-expiry',
              applicationId: application.id,
              applicationNumber: application.applicationNumber,
              permitTypeLabel: permitLabel,
              kind: ActionItemKind.expiryWarning,
              title: daysLeft < 0 ? 'Permit has expired' : 'Permit expiring',
              detail: daysLeft < 0
                  ? 'Its validity period ended. Renewal is required before '
                        'work continues.'
                  : '$daysLeft day(s) of validity left on this permit.',
              // Straight to the renewal, not to the record. The applicant
              // reading "your permit expires in 12 days" wants the thing that
              // answers it, and an extra hop through the detail screen is
              // where an intention goes to die.
              actionLabel: 'Renew permit',
              route: '/applications/${application.id}/renew',
            ),
          );
        }
      }
    }

    items.sort((a, b) => a.kind.index.compareTo(b.kind.index));
    return items;
  }

  static int _daysBetween(DateTime from, DateTime to) {
    final a = DateTime(from.year, from.month, from.day);
    final b = DateTime(to.year, to.month, to.day);
    return b.difference(a).inDays;
  }
}
