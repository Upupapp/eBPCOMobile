import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import 'document_model.dart';
import 'money.dart';
import 'order_of_payment.dart';

/// Represents the status of a payment assessment in the mock dataset.
enum PaymentAssessmentStatus { notYetAvailable, pending, paid, overdue }

extension PaymentAssessmentStatusX on PaymentAssessmentStatus {
  String get label {
    switch (this) {
      case PaymentAssessmentStatus.notYetAvailable:
        return 'Not Yet Available';
      case PaymentAssessmentStatus.pending:
        return 'Pending Verification';
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

  const PaymentAssessmentModel({
    required this.status,
    this.orderOfPayment,
    this.referenceNumber,
    this.method,
    this.proof,
    this.submittedAt,
    this.officialReceiptNumber,
    this.verifiedAt,
  });

  /// The amount due, or null when nothing has been assessed.
  PesoAmount? get amountDue => orderOfPayment?.total;

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
    );
  }
}
