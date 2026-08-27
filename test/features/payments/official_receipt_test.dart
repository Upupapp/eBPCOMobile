import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:ebpco_user_app/core/contract/admin_vocabulary.dart';
import 'package:ebpco_user_app/core/models/money.dart';
import 'package:ebpco_user_app/core/models/payment_assessment_model.dart';

/// The Official Receipt is the applicant's proof that a government office took
/// their money, and the number they will be asked to quote at a counter.
///
/// The app referenced an OR number in four wizard steps and one notification
/// payload while having no field to hold one, so the real value lived nowhere.

PaymentTransactionRecord _txn({
  String? orNumber,
  DateTime? orDate,
  String? orIssuedBy,
  CollectingAgency agency = CollectingAgency.oboLgu,
  bool isVoid = false,
  PaymentTransactionStatus status = PaymentTransactionStatus.verified,
}) => PaymentTransactionRecord(
  id: 't1',
  amount: const PesoAmount(100000),
  method: PaymentMethod.onsite,
  reference: 'REF-1',
  status: status,
  submittedAt: DateTime(2026, 8, 5),
  isVoid: isVoid,
  agency: agency,
  orNumber: orNumber,
  orDate: orDate,
  orIssuedBy: orIssuedBy,
);

void main() {
  group('receipts', () {
    test('a payment with no receipt has none', () {
      expect(_txn().hasOfficialReceipt, isFalse);
    });

    test('whitespace is not a receipt number', () {
      expect(_txn(orNumber: '   ').hasOfficialReceipt, isFalse);
    });

    test('only issued, unvoided receipts are offered to the applicant', () {
      final assessment = PaymentAssessmentModel(
        status: PaymentAssessmentStatus.paid,
        transactions: [
          _txn(orNumber: 'OR-2026-004821'),
          _txn(),
          _txn(orNumber: 'OR-2026-004822', isVoid: true),
        ],
      );
      expect(assessment.receipts, hasLength(1));
      expect(assessment.receipts.single.orNumber, 'OR-2026-004821');
    });
  });

  group('collecting agency', () {
    test('defaults to the LGU', () {
      expect(_txn().agency, CollectingAgency.oboLgu);
    });

    test('a fire clearance fee is collected by the BFP, not the LGU', () {
      // Sending an applicant to the OBO cashier to settle a BFP fee sends them
      // to the wrong counter.
      final assessment = PaymentAssessmentModel(
        status: PaymentAssessmentStatus.partiallyPaid,
        transactions: [
          _txn(agency: CollectingAgency.oboLgu),
          _txn(agency: CollectingAgency.bfp),
        ],
      );
      expect(assessment.collectingAgencies, {
        CollectingAgency.oboLgu,
        CollectingAgency.bfp,
      });
    });

    test('a voided payment does not imply its agency collected anything', () {
      final assessment = PaymentAssessmentModel(
        status: PaymentAssessmentStatus.pending,
        transactions: [_txn(agency: CollectingAgency.bfp, isVoid: true)],
      );
      expect(assessment.collectingAgencies, isEmpty);
    });
  });

  test('no code path fabricates an Official Receipt number', () {
    // The admin marks this field "never auto-filled". A plausible-looking OR
    // invented by a mock is worse than an empty one, because the applicant
    // would quote it at a counter.
    //
    // The wizards generate their own reference numbers from the clock — this
    // asserts that trick was never applied to a receipt.
    final offenders = <String>[];
    for (final file in Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))) {
      final lines = file.readAsStringSync().split('\n');
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];
        if (!RegExp(r'\borNumber\s*[:=]').hasMatch(line)) continue;
        // A literal or a generated string on the same line is a fabrication;
        // passing a parameter or a parsed value through is not.
        if (RegExp(r"orNumber\s*[:=]\s*'").hasMatch(line) ||
            line.contains('millisecondsSinceEpoch') ||
            line.contains('DateTime.now()')) {
          offenders.add('${file.path}:${i + 1}  ${line.trim()}');
        }
      }
    }
    expect(
      offenders,
      isEmpty,
      reason: 'an Official Receipt number must come from the office that '
          'issued it. Found at:\n  ${offenders.join('\n  ')}',
    );
  });

  test('adjustments carry their type, amount and reason', () {
    // An applicant whose total changes without explanation cannot tell a
    // refund from an error.
    final adjustment = PaymentAdjustmentRecord(
      id: 'a1',
      type: PaymentAdjustmentType.refund,
      amount: const PesoAmount(25000),
      appliedAt: DateTime(2026, 8, 20),
      reason: 'Overpayment on the electrical fee.',
    );

    expect(adjustment.type.wire, 'Refund');
    expect(adjustment.amount.centavos, 25000);
    expect(adjustment.reason, isNotNull);
  });
}
