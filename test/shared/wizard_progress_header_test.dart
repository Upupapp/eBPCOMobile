import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ebpco_user_app/core/theme/app_theme.dart';
import 'package:ebpco_user_app/shared/widgets/layout/wizard_progress_header.dart';

/// One widget now carries the header for all sixteen wizards, so it is worth
/// testing directly rather than only through them.

Widget _host({
  int currentStep = 0,
  int totalSteps = 9,
  double textScale = 1.0,
  double width = 360,
  String intro = 'Complete your Building Permit application step by step.',
  String title = 'Applicant Information',
  String subtitle = 'Tell us who is applying and how to reach you.',
}) => MaterialApp(
  theme: AppTheme.lightTheme,
  home: Scaffold(
    body: MediaQuery(
      data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
      child: WizardProgressHeader(
        currentStep: currentStep,
        totalSteps: totalSteps,
        intro: intro,
        title: title,
        subtitle: subtitle,
      ),
    ),
  ),
);

Future<void> _pump(WidgetTester tester, Widget app, {double width = 360}) async {
  tester.view.physicalSize = Size(width, 900);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(app);
  await tester.pumpAndSettle();
}

void main() {
  group('the step counter', () {
    testWidgets('is one-based for the applicant, zero-based in code', (
      tester,
    ) async {
      await _pump(tester, _host(currentStep: 0));
      expect(find.text('Step 1 of 9'), findsOneWidget);

      await _pump(tester, _host(currentStep: 8));
      expect(find.text('Step 9 of 9'), findsOneWidget);
    });

    testWidgets('adapts to a shorter wizard', (tester) async {
      // The Certificate of Occupancy wizard is five steps, not nine.
      await _pump(tester, _host(currentStep: 0, totalSteps: 5));
      expect(find.text('Step 1 of 5'), findsOneWidget);
    });
  });

  group('progress', () {
    testWidgets('the bar tracks the step', (tester) async {
      await _pump(tester, _host(currentStep: 4, totalSteps: 10));
      final bar = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      expect(bar.value, closeTo(0.5, 0.001));
    });

    testWidgets('is announced, not just drawn', (tester) async {
      // A progress bar is invisible to a screen reader without a label.
      final handle = tester.ensureSemantics();
      await _pump(tester, _host(currentStep: 2, totalSteps: 9));

      expect(
        find.bySemanticsLabel(RegExp('Step 3 of 9')),
        findsAtLeastNWidgets(1),
      );
      handle.dispose();
    });
  });

  group('long content does not squeeze the form', () {
    // The header sits above an Expanded(PageView). Anything unbounded here
    // takes space from the fields; at 200% an unbounded header consumed the
    // whole viewport and the applicant could not reach them.
    testWidgets('at 200% text scale on a 360dp phone', (tester) async {
      await _pump(
        tester,
        _host(
          textScale: 2.0,
          intro:
              'Complete your Excavation & Ground Preparation Permit '
              'application step by step.',
          title: 'Professional in Charge and Signed Documents',
          subtitle:
              'Give the details of the licensed professional who prepared '
              'and sealed the plans, and attach their credentials.',
        ),
      );

      expect(tester.takeException(), isNull);
      // The counter survives whatever the prose does — it is the part that
      // must always be readable.
      expect(find.text('Step 1 of 9'), findsOneWidget);
    });

    testWidgets('at 320dp, the narrowest phone still supported', (
      tester,
    ) async {
      await _pump(tester, _host(width: 320), width: 320);
      expect(tester.takeException(), isNull);
    });
  });
}
