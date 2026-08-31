import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ebpco_user_app/core/models/excavation_permit_model.dart';
import 'package:ebpco_user_app/core/models/sign_permit_model.dart';
import 'package:ebpco_user_app/shared/widgets/layout/permit_conditions_card.dart';

/// The conditions an applicant actually sees, rendered rather than scanned.
///
/// `permit_conditions_test.dart` proves the source references the list. This
/// proves it reaches a screen and fits on one — the distinction that has
/// caught things here before: `ReattachNotice` referenced its data correctly
/// and overflowed by 2,741 pixels at 200% text scale, which no source scan
/// could see.
///
/// The excavation list is the longest in the app (thirteen conditions, one of
/// them four lines of peso amounts), so it is the one worth rendering.

Widget _wrap(Widget child, {double textScale = 1.0}) => MaterialApp(
  home: MediaQuery(
    data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
    child: Scaffold(body: SingleChildScrollView(child: child)),
  ),
);

void main() {
  testWidgets('the cash bond reaches the screen, in full', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 3000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      _wrap(
        const PermitConditionsCard(
          conditions: ExcavationProcessingInfo.permitConditions,
        ),
      ),
    );

    // The numbers an owner needs to budget, each asserted separately: a
    // paraphrase that kept the threshold and dropped the amount would still
    // leave them unable to plan.
    expect(find.textContaining('fifty (50) cubic metres'), findsWidgets);
    expect(find.textContaining('P50,000.00'), findsOneWidget);
    expect(find.textContaining('P300.00'), findsOneWidget);
    expect(find.textContaining('forfeited'), findsOneWidget);
    expect(find.textContaining('ten (10) days'), findsOneWidget);
  });

  testWidgets('and it does not promise conditions on a reference form', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 3000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      _wrap(
        const PermitConditionsCard(
          conditions: SignProcessingInfo.permitConditions,
          isReferenceForm: true,
        ),
      ),
    );

    expect(
      find.textContaining('has not published its own form'),
      findsOneWidget,
    );
    expect(
      find.textContaining('will apply once the permit is issued'),
      findsNothing,
      reason:
          'the sign form is signed by a CITY Building Official; Castilla is a '
          'municipality, so these are not its conditions to promise',
    );
  });

  testWidgets('the excavation list survives 200% text scale', (tester) async {
    // Thirteen conditions, the longest of them four lines of peso amounts.
    // An overflow here would be counted by tool/verify.sh, which greps the
    // test output for "overflowed by" — so this test failing is not the only
    // way the problem surfaces, but it is the earliest.
    await tester.binding.setSurfaceSize(const Size(390, 12000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      _wrap(
        const PermitConditionsCard(
          conditions: ExcavationProcessingInfo.permitConditions,
        ),
        textScale: 2.0,
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.textContaining('P50,000.00'), findsOneWidget);
  });
}
