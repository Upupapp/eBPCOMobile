import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ebpco_user_app/core/theme/app_theme.dart';
import 'package:ebpco_user_app/shared/widgets/layout/amount_row.dart';

/// Four money rows across the two payment screens now depend on this, and the
/// behaviour that matters — reflowing rather than truncating — is invisible in
/// a screenshot. Assert the reflow itself, not just that nothing overflowed.

Widget _host({
  required String label,
  required String amount,
  double textScale = 1.0,
}) => MaterialApp(
  theme: AppTheme.lightTheme,
  home: Scaffold(
    body: MediaQuery(
      data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
      child: Align(
        alignment: Alignment.topLeft,
        child: AmountRow(label: Text(label), amount: Text(amount)),
      ),
    ),
  ),
);

Future<void> _pump(
  WidgetTester tester,
  Widget app, {
  double width = 360,
}) async {
  tester.view.physicalSize = Size(width, 900);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(app);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shares one line when both fit', (tester) async {
    await _pump(tester, _host(label: 'Filing fee', amount: '₱500.00'));

    final label = tester.getRect(find.text('Filing fee'));
    final amount = tester.getRect(find.text('₱500.00'));

    expect(label.top, closeTo(amount.top, 1));
    expect(amount.left, greaterThan(label.right));
  });

  testWidgets('drops the amount to its own line when they do not', (
    tester,
  ) async {
    await _pump(
      tester,
      _host(
        label: 'Architectural fees for the proposed two-storey building',
        amount: '₱2,850.50',
        textScale: 2.0,
      ),
    );

    final label = tester.getRect(
      find.text('Architectural fees for the proposed two-storey building'),
    );
    final amount = tester.getRect(find.text('₱2,850.50'));

    expect(
      amount.top,
      greaterThanOrEqualTo(label.bottom),
      reason: 'the amount should sit below the label, not beside it',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('the amount is never truncated', (tester) async {
    // Money is the one thing on this row that must survive intact.
    await _pump(
      tester,
      _host(
        label: 'Electrical fees, including the temporary service connection',
        amount: '₱1,234,567.89',
        textScale: 2.0,
      ),
      width: 320,
    );

    final amount = tester.widget<Text>(find.text('₱1,234,567.89'));
    expect(amount.overflow, isNot(TextOverflow.ellipsis));
    expect(tester.takeException(), isNull);
  });
}
