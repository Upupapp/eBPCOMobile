import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ebpco_user_app/core/constants/app_strings.dart';
import 'package:ebpco_user_app/core/theme/app_theme.dart';
import 'package:ebpco_user_app/shared/widgets/branding/app_logo.dart';

/// The branding block carries the product name, so it is the one place a
/// rename lands in front of every user on the very first screen. These guard
/// the rename rather than the widget.
Widget _wrap({double textScale = 1.0}) => MaterialApp(
  theme: AppTheme.lightTheme,
  home: Scaffold(
    body: MediaQuery(
      data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
      child: const Center(child: AppLogo(showSubtitle: true)),
    ),
  ),
);

void main() {
  test('the product name is the ruled one', () {
    // Ruled by the owner on 19 Aug 2026: this is a building-permit system, not
    // a business-permit one. The sixteen construction wizards and the
    // Certificate of Occupancy are the product; the legacy business-permit
    // flow is the outlier.
    expect(
      AppStrings.appFullName,
      'Electronic Building Permit and Certificate of Occupancy',
    );
    expect(
      AppStrings.appTagline,
      'Building Permit and Certificate of Occupancy',
    );
  });

  testWidgets('the tagline fits a 360dp phone without overflowing', (
    tester,
  ) async {
    // The ruled name is seven characters longer than the one it replaced, and
    // it sits centred under the wordmark on the login screen — the first
    // thing every applicant sees.
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text(AppStrings.appTagline), findsOneWidget);
  });

  testWidgets('and still fits at 200% text scale', (tester) async {
    tester.view.physicalSize = const Size(360, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_wrap(textScale: 2.0));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
