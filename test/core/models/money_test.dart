import 'package:flutter_test/flutter_test.dart';

import 'package:ebpco_user_app/core/models/money.dart';
import 'package:ebpco_user_app/core/models/order_of_payment.dart';

void main() {
  group('PesoAmount', () {
    test('formats with a thousands separator and two decimals', () {
      expect(const PesoAmount(1234567).formatted, 'PHP 12,345.67');
      expect(const PesoAmount(5000).formatted, 'PHP 50.00');
      expect(const PesoAmount(0).formatted, 'PHP 0.00');
      expect(const PesoAmount(1).formatted, 'PHP 0.01');
    });

    test('constructs from pesos without truncating a half centavo', () {
      expect(PesoAmount.fromPesos(12345.67).centavos, 1234567);
      expect(PesoAmount.fromPesos(0.1).centavos, 10);
      // 8.115 in binary floating point is just under 8.115; rounding the
      // scaled value is what keeps this from becoming 811.
      expect(PesoAmount.fromPesos(8.115).centavos, 812);
    });

    test('addition is exact across many small amounts', () {
      // The case that motivates integer centavos: 0.1 + 0.2 in floating point
      // is 0.30000000000000004, and a fee schedule of many such lines drifts
      // far enough to disagree with the cashier.
      final tenCentavos = List.filled(1000, const PesoAmount(10));
      expect(sumPesos(tenCentavos), const PesoAmount(10000));
      expect(sumPesos(tenCentavos).formatted, 'PHP 100.00');
    });

    test('equality is by value', () {
      expect(const PesoAmount(500), const PesoAmount(500));
      expect(const PesoAmount(500) == const PesoAmount(501), isFalse);
    });

    test('sorts by amount', () {
      final amounts = [
        const PesoAmount(500),
        const PesoAmount(100),
        const PesoAmount(9999),
      ]..sort();
      expect(amounts.first.centavos, 100);
      expect(amounts.last.centavos, 9999);
    });
  });

  group('AssessmentFees', () {
    const fees = AssessmentFees(
      filing: 50000,
      processing: 120000,
      architectural: 285050,
      structural: 341275,
      electrical: 96500,
      others: 42000,
    );

    test('total equals the sum of its lines exactly', () {
      expect(fees.total.centavos, 934825);
      expect(sumPesos(fees.lines.map((l) => l.amount)), fees.total);
      expect(fees.total.formatted, 'PHP 9,348.25');
    });

    test('omits zero lines rather than showing PHP 0.00 rows', () {
      const partial = AssessmentFees(filing: 50000, processing: 120000);
      expect(partial.lines, hasLength(2));
      expect(partial.total.centavos, 170000);
    });

    test('every line carries an explainer', () {
      for (final line in fees.lines) {
        expect(line.explainer, isNotEmpty, reason: '${line.label} unexplained');
      }
    });
  });

  group('OrderOfPayment', () {
    test('is consistent when its lines add up to its total', () {
      final order = OrderOfPayment(
        number: 'OP-2026-000001',
        assessedAt: DateTime(2026, 8, 10),
        fees: const AssessmentFees(filing: 50000, processing: 120000),
      );

      expect(order.isConsistent, isTrue);
      expect(order.total.formatted, 'PHP 1,700.00');
    });
  });
}
