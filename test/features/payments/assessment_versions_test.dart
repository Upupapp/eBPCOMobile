import 'package:flutter_test/flutter_test.dart';

import 'package:ebpco_user_app/core/contract/admin_vocabulary.dart';
import 'package:ebpco_user_app/core/models/money.dart';
import 'package:ebpco_user_app/core/models/order_of_payment.dart';
import 'package:ebpco_user_app/core/models/payment_assessment_model.dart';

/// The office does not edit an issued assessment. A correction after issuance
/// builds a new version and marks the old one superseded, so the figures an
/// applicant was shown before are still the figures they were shown — which
/// matters if they paid against them.
///
/// Mobile had a single Order of Payment with no version and no status, so a
/// reassessment looked exactly like the original: a total that had silently
/// changed since the applicant last looked.

OrderOfPayment _order({
  int filing = 100000,
  int version = 1,
  AssessmentStatus status = AssessmentStatus.issued,
  String? revisionReason,
}) => OrderOfPayment(
  number: 'OP-2026-000$version',
  assessedAt: DateTime(2026, 8, version),
  fees: AssessmentFees(filing: filing),
  version: version,
  status: status,
  revisionReason: revisionReason,
);

void main() {
  group('payability', () {
    test('an issued assessment is payable', () {
      expect(_order().isPayable, isTrue);
    });

    test('a superseded one is not', () {
      expect(_order(status: AssessmentStatus.superseded).isPayable, isFalse);
    });

    test('a voided one is not', () {
      expect(_order(status: AssessmentStatus.voided).isPayable, isFalse);
    });

    test('a draft is not', () {
      // Not yet issued to the applicant; paying against it would be paying
      // against a figure the office has not committed to.
      expect(_order(status: AssessmentStatus.draft).isPayable, isFalse);
    });
  });

  group('what is owed', () {
    test('a payable assessment states its total', () {
      final assessment = PaymentAssessmentModel(
        status: PaymentAssessmentStatus.pending,
        orderOfPayment: _order(filing: 250000),
      );
      expect(assessment.amountDue, const PesoAmount(250000));
    });

    test('a superseded assessment states no amount at all', () {
      // Showing its total would invite payment against a figure the office has
      // replaced — the one case where a number is worse than a blank.
      final assessment = PaymentAssessmentModel(
        status: PaymentAssessmentStatus.pending,
        orderOfPayment: _order(status: AssessmentStatus.superseded),
      );
      expect(assessment.amountDue, isNull);
      expect(assessment.balanceDue, isNull);
    });
  });

  group('reassessment', () {
    test('keeps what the applicant was shown before', () {
      final assessment = PaymentAssessmentModel(
        status: PaymentAssessmentStatus.pending,
        orderOfPayment: _order(
          filing: 320000,
          version: 2,
          revisionReason: 'Floor area corrected after evaluation.',
        ),
        supersededOrders: [
          _order(filing: 250000, status: AssessmentStatus.superseded),
        ],
      );

      expect(assessment.wasReassessed, isTrue);
      expect(assessment.amountDue, const PesoAmount(320000));
      expect(
        assessment.supersededOrders.single.total,
        const PesoAmount(250000),
        reason:
            '"the figure changed" with no way to see what it was before '
            'is not an explanation',
      );
      expect(
        assessment.orderOfPayment!.revisionReason,
        'Floor area corrected after evaluation.',
      );
    });

    test('a first assessment is not a reassessment', () {
      final assessment = PaymentAssessmentModel(
        status: PaymentAssessmentStatus.pending,
        orderOfPayment: _order(),
      );
      expect(assessment.wasReassessed, isFalse);
      expect(assessment.orderOfPayment!.version, 1);
    });

    test('payments already made survive a reassessment', () {
      // The applicant paid against version 1. That money does not vanish
      // because the office reassessed.
      final assessment = PaymentAssessmentModel(
        status: PaymentAssessmentStatus.partiallyPaid,
        orderOfPayment: _order(filing: 320000, version: 2),
        supersededOrders: [
          _order(filing: 250000, status: AssessmentStatus.superseded),
        ],
        transactions: [
          PaymentTransactionRecord(
            id: 't1',
            amount: const PesoAmount(250000),
            method: PaymentMethod.bankTransfer,
            reference: 'REF-1',
            status: PaymentTransactionStatus.verified,
            submittedAt: DateTime(2026, 8, 3),
          ),
        ],
      );

      expect(assessment.amountPaid, const PesoAmount(250000));
      expect(assessment.balanceDue, const PesoAmount(70000));
    });
  });
}
