import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../contract/admin_vocabulary.dart';
import 'document_model.dart';
import 'money.dart';
import 'order_of_payment.dart';

/// Represents the status of a payment assessment in the mock dataset.
///
/// `partiallyPaid` mirrors the admin portal, whose own comment on this
/// vocabulary says mobile's four values "have no room to represent" genuine
/// partial payment of a staged or legally-prescribed charge, and instructs
/// every consumer to handle it explicitly rather than defaulting. An applicant
/// who has paid half of an assessment is neither Pending nor Paid, and telling
/// them either is wrong in a way they will act on.
enum PaymentAssessmentStatus {
  notYetAvailable,
  pending,
  partiallyPaid,
  paid,
  overdue,
}

extension PaymentAssessmentStatusX on PaymentAssessmentStatus {
  String get label {
    switch (this) {
      case PaymentAssessmentStatus.notYetAvailable:
        return 'Not Yet Available';
      case PaymentAssessmentStatus.pending:
        return 'Pending Verification';
      case PaymentAssessmentStatus.partiallyPaid:
        return 'Partially Paid';
      case PaymentAssessmentStatus.paid:
        return 'Paid';
      case PaymentAssessmentStatus.overdue:
        return 'Overdue';
    }
  }

  Color get color {
    switch (this) {
      case PaymentAssessmentStatus.notYetAvailable:
        return AppColors.textMuted;
      case PaymentAssessmentStatus.pending:
        return AppColors.statusPending;
      case PaymentAssessmentStatus.partiallyPaid:
        return AppColors.statusPending;
      case PaymentAssessmentStatus.paid:
        return AppColors.statusApproved;
      case PaymentAssessmentStatus.overdue:
        return AppColors.statusRejected;
    }
  }

  Color get backgroundColor {
    switch (this) {
      case PaymentAssessmentStatus.notYetAvailable:
        return AppColors.surfaceMuted;
      case PaymentAssessmentStatus.pending:
        return AppColors.statusPendingBg;
      case PaymentAssessmentStatus.partiallyPaid:
        return AppColors.statusPendingBg;
      case PaymentAssessmentStatus.paid:
        return AppColors.statusApprovedBg;
      case PaymentAssessmentStatus.overdue:
        return AppColors.statusRejectedBg;
    }
  }
}

/// How the user chose to settle a payment assessment.
enum PaymentMethod { bankTransfer, onsite }

extension PaymentMethodX on PaymentMethod {
  String get label =>
      this == PaymentMethod.bankTransfer ? 'Bank Transfer' : 'Onsite Payment';
}

/// One payment the applicant made against an assessment.
///
/// The admin records many of these per assessment, each verified or rejected on
/// its own. Mobile previously carried a single reference, method and proof —
/// enough for "the applicant paid" and not enough for "the applicant paid
/// twice, and the first was rejected".
class PaymentTransactionRecord {
  final String id;
  final PesoAmount amount;
  final PaymentMethod method;

  /// Bank transaction id, deposit slip number, or the counter reference for an
  /// onsite payment.
  final String reference;

  final PaymentTransactionStatus status;
  final DateTime submittedAt;
  final DateTime? verifiedAt;

  /// Required by the office whenever [status] is rejected, and the reason this
  /// type exists: "your payment was rejected" without the reason leaves the
  /// applicant to guess whether to pay again, and how much.
  final String? rejectionReason;

  /// Kept for the audit trail and excluded from every total, exactly as the
  /// admin does.
  final bool isVoid;

  /// Who took the money.
  ///
  /// Not decoration: FSEC and FSIC fees are collected by the Bureau of Fire
  /// Protection, not the LGU. An applicant sent to the OBO cashier to settle a
  /// BFP fee has been sent to the wrong counter.
  final CollectingAgency agency;

  /// The Official Receipt, once the Treasurer's Office has issued one.
  ///
  /// **Never fabricated.** The admin marks this field "never auto-filled" and
  /// the same applies here: an OR number is a government instrument, and a
  /// plausible-looking one invented by a mock is worse than an empty field,
  /// because the applicant would quote it.
  final String? orNumber;
  final DateTime? orDate;
  final String? orIssuedBy;

  const PaymentTransactionRecord({
    required this.id,
    required this.amount,
    required this.method,
    required this.reference,
    required this.status,
    required this.submittedAt,
    this.verifiedAt,
    this.rejectionReason,
    this.isVoid = false,
    this.agency = CollectingAgency.oboLgu,
    this.orNumber,
    this.orDate,
    this.orIssuedBy,
  });

  /// Whether a receipt has actually been issued for this payment.
  bool get hasOfficialReceipt =>
      orNumber != null && orNumber!.trim().isNotEmpty;

  /// Whether this payment counts toward what has been settled.
  ///
  /// Only a verified, unvoided payment does. A rejected one is money the
  /// office did not accept, and counting it would tell the applicant they owe
  /// less than they do.
  bool get countsTowardBalance =>
      !isVoid && status == PaymentTransactionStatus.verified;

  bool get needsApplicantAction =>
      !isVoid && status == PaymentTransactionStatus.rejected;
}

/// A correction the office applied to a recorded payment.
///
/// Shown rather than silently folded into the balance: an applicant whose total
/// changes without explanation has no way to tell a refund from an error.
class PaymentAdjustmentRecord {
  final String id;
  final PaymentAdjustmentType type;
  final PesoAmount amount;
  final DateTime appliedAt;

  /// Why the office made it.
  final String? reason;

  const PaymentAdjustmentRecord({
    required this.id,
    required this.type,
    required this.amount,
    required this.appliedAt,
    this.reason,
  });
}

/// An application's payment position.
///
/// [orderOfPayment] is the sole source of an amount. While it is null the
/// status is Not Yet Available and no figure may be shown anywhere — the LGU
/// has not assessed the application, so there is nothing legitimate to
/// display.
class PaymentAssessmentModel {
  final OrderOfPayment? orderOfPayment;
  final PaymentAssessmentStatus status;

  /// Bank transfer reference or onsite official receipt number as supplied by
  /// the applicant when submitting proof.
  final String? referenceNumber;

  final PaymentMethod? method;
  final DocumentModel? proof;
  final DateTime? submittedAt;

  /// Official receipt recorded by the Treasurer's Office once verified.
  final String? officialReceiptNumber;
  final DateTime? verifiedAt;

  /// Every payment made against this assessment, oldest first.
  ///
  /// Empty on an assessment nobody has paid against, which is the common case
  /// and is why the single-payment fields above still exist — they describe the
  /// applicant's most recent submission and are what most of the app reads.
  final List<PaymentTransactionRecord> transactions;

  /// Voids, reversals, refunds and corrections the office applied.
  final List<PaymentAdjustmentRecord> adjustments;

  const PaymentAssessmentModel({
    required this.status,
    this.orderOfPayment,
    this.referenceNumber,
    this.method,
    this.proof,
    this.submittedAt,
    this.officialReceiptNumber,
    this.verifiedAt,
    this.transactions = const [],
    this.adjustments = const [],
  });

  /// The amount due, or null when nothing has been assessed.
  PesoAmount? get amountDue => orderOfPayment?.total;

  /// What the office has actually accepted so far.
  ///
  /// Rejected and voided payments are excluded — the admin excludes them from
  /// every balance computation, and an applicant told they had paid when the
  /// office disagreed would stop paying.
  PesoAmount get amountPaid => transactions
      .where((t) => t.countsTowardBalance)
      .fold(const PesoAmount.zero(), (sum, t) => sum + t.amount);

  /// What is still owed, or null while nothing has been assessed.
  PesoAmount? get balanceDue {
    final due = amountDue;
    if (due == null) return null;
    return PesoAmount(due.centavos - amountPaid.centavos);
  }

  /// Paid something, but not all of it.
  bool get isPartiallyPaid {
    final due = amountDue;
    if (due == null) return false;
    return amountPaid.centavos > 0 && amountPaid.centavos < due.centavos;
  }

  /// Payments the office turned back and the applicant has not replaced.
  List<PaymentTransactionRecord> get rejectedTransactions =>
      transactions.where((t) => t.needsApplicantAction).toList();

  /// Receipts the applicant can actually quote.
  List<PaymentTransactionRecord> get receipts =>
      transactions.where((t) => !t.isVoid && t.hasOfficialReceipt).toList();

  /// Every agency that has collected against this assessment.
  ///
  /// More than one means the applicant has paid at more than one counter,
  /// which is normal once a fire clearance is involved and worth saying.
  Set<CollectingAgency> get collectingAgencies =>
      transactions.where((t) => !t.isVoid).map((t) => t.agency).toSet();

  bool get isAssessed => orderOfPayment != null;

  /// True once the applicant has supplied everything needed for verification.
  bool get hasProofOfPayment => referenceNumber != null && proof != null;

  PaymentAssessmentModel copyWith({
    OrderOfPayment? orderOfPayment,
    PaymentAssessmentStatus? status,
    String? referenceNumber,
    PaymentMethod? method,
    DocumentModel? proof,
    DateTime? submittedAt,
    String? officialReceiptNumber,
    DateTime? verifiedAt,
    List<PaymentTransactionRecord>? transactions,
    List<PaymentAdjustmentRecord>? adjustments,
  }) {
    return PaymentAssessmentModel(
      orderOfPayment: orderOfPayment ?? this.orderOfPayment,
      status: status ?? this.status,
      referenceNumber: referenceNumber ?? this.referenceNumber,
      method: method ?? this.method,
      proof: proof ?? this.proof,
      submittedAt: submittedAt ?? this.submittedAt,
      officialReceiptNumber:
          officialReceiptNumber ?? this.officialReceiptNumber,
      verifiedAt: verifiedAt ?? this.verifiedAt,
      transactions: transactions ?? this.transactions,
      adjustments: adjustments ?? this.adjustments,
    );
  }
}
