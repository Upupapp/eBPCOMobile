import 'package:flutter_test/flutter_test.dart';

import 'package:ebpco_user_app/core/contract/admin_vocabulary.dart';
import 'package:ebpco_user_app/core/models/money.dart';
import 'package:ebpco_user_app/core/models/order_of_payment.dart';
import 'package:ebpco_user_app/core/models/payment_assessment_model.dart';

/// What the applicant owes, after the office has accepted some payments and
/// turned others back.
///
/// Mobile carried four payment states and a single reference, method and
/// proof. That is enough for "the applicant paid" and not enough for "the
/// applicant paid twice, and the first was rejected" — which is what the admin
/// portal records, and what determines whether anything is still owed.

OrderOfPayment _order(int totalCentavos) => OrderOfPayment(
  number: 'OP-2026-0001',
  assessedAt: DateTime(2026, 8, 1),
  assessedBy: 'Assessment Section',
  dueDate: DateTime(2026, 9, 1),
  fees: AssessmentFees(filing: totalCentavos),
);

PaymentTransactionRecord _txn({
  required int centavos,
  required PaymentTransactionStatus status,
  bool isVoid = false,
  String? rejectionReason,
}) => PaymentTransactionRecord(
  id: 't${centavos}_${status.name}',
  amount: PesoAmount(centavos),
  method: PaymentMethod.bankTransfer,
  reference: 'REF-$centavos',
  status: status,
  submittedAt: DateTime(2026, 8, 5),
  isVoid: isVoid,
  rejectionReason: rejectionReason,
);

PaymentAssessmentModel _assessment({
  int total = 100000,
  List<PaymentTransactionRecord> transactions = const [],
  PaymentAssessmentStatus status = PaymentAssessmentStatus.pending,
}) => PaymentAssessmentModel(
  status: status,
  orderOfPayment: _order(total),
  transactions: transactions,
);

void main() {
  group('what has been paid', () {
    test('counts only verified payments', () {
      final assessment = _assessment(
        transactions: [
          _txn(centavos: 40000, status: PaymentTransactionStatus.verified),
          _txn(centavos: 30000, status: PaymentTransactionStatus.pendingVerification),
        ],
      );
      expect(assessment.amountPaid, const PesoAmount(40000));
    });

    test('excludes a rejected payment', () {
      // Money the office did not accept. Counting it would tell the applicant
      // they owe less than they do.
      final assessment = _assessment(
        transactions: [
          _txn(centavos: 40000, status: PaymentTransactionStatus.verified),
          _txn(
            centavos: 60000,
            status: PaymentTransactionStatus.rejected,
            rejectionReason: 'Deposit slip is for a different account.',
          ),
        ],
      );
      expect(assessment.amountPaid, const PesoAmount(40000));
      expect(assessment.balanceDue, const PesoAmount(60000));
    });

    test('excludes a voided payment even when it was verified', () {
      // The admin keeps voided transactions for audit and excludes them from
      // every total. Doing otherwise here would disagree with the portal about
      // what is owed.
      final assessment = _assessment(
        transactions: [
          _txn(centavos: 40000, status: PaymentTransactionStatus.verified),
          _txn(
            centavos: 50000,
            status: PaymentTransactionStatus.verified,
            isVoid: true,
          ),
        ],
      );
      expect(assessment.amountPaid, const PesoAmount(40000));
    });

    test('nothing paid on an untouched assessment', () {
      expect(_assessment().amountPaid, const PesoAmount.zero());
      expect(_assessment().balanceDue, const PesoAmount(100000));
    });
  });

  group('partial payment', () {
    test('is recognised when some but not all is settled', () {
      final assessment = _assessment(
        transactions: [
          _txn(centavos: 40000, status: PaymentTransactionStatus.verified),
        ],
      );
      expect(assessment.isPartiallyPaid, isTrue);
      expect(assessment.balanceDue, const PesoAmount(60000));
    });

    test('is not partial once fully settled', () {
      final assessment = _assessment(
        transactions: [
          _txn(centavos: 100000, status: PaymentTransactionStatus.verified),
        ],
      );
      expect(assessment.isPartiallyPaid, isFalse);
      expect(assessment.balanceDue, const PesoAmount.zero());
    });

    test('is not partial when nothing has been accepted', () {
      final assessment = _assessment(
        transactions: [
          _txn(centavos: 40000, status: PaymentTransactionStatus.rejected),
        ],
      );
      expect(assessment.isPartiallyPaid, isFalse);
    });

    test('the status vocabulary can express it', () {
      // The admin's own comment says mobile's four values had no room for
      // this. Now there are five.
      expect(PaymentAssessmentStatus.values, hasLength(5));
      expect(PaymentAssessmentStatus.partiallyPaid.label, 'Partially Paid');
    });
  });

  group('rejected payments', () {
    test('are surfaced for the applicant to act on', () {
      final assessment = _assessment(
        transactions: [
          _txn(centavos: 40000, status: PaymentTransactionStatus.verified),
          _txn(
            centavos: 60000,
            status: PaymentTransactionStatus.rejected,
            rejectionReason: 'Deposit slip is for a different account.',
          ),
        ],
      );
      expect(assessment.rejectedTransactions, hasLength(1));
      expect(
        assessment.rejectedTransactions.single.rejectionReason,
        'Deposit slip is for a different account.',
      );
    });

    test('a voided rejection is not asked about again', () {
      final assessment = _assessment(
        transactions: [
          _txn(
            centavos: 60000,
            status: PaymentTransactionStatus.rejected,
            isVoid: true,
          ),
        ],
      );
      expect(assessment.rejectedTransactions, isEmpty);
    });
  });

  test('every amount stays in integer centavos', () {
    // Money never becomes a double anywhere in this path.
    final assessment = _assessment(
      total: 12345,
      transactions: [
        _txn(centavos: 6789, status: PaymentTransactionStatus.verified),
      ],
    );
    expect(assessment.amountPaid.centavos, 6789);
    expect(assessment.balanceDue!.centavos, 12345 - 6789);
  });
}
