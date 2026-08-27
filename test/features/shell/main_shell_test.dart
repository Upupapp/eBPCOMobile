import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ebpco_user_app/core/providers/notifications_provider.dart';
import 'package:ebpco_user_app/core/repositories/notifications_repository.dart';
import 'package:ebpco_user_app/core/theme/app_theme.dart';
import 'package:ebpco_user_app/features/shell/presentation/main_shell.dart';

import '../../support/clipping.dart';

import '../../support/wizard_providers.dart';

/// The bottom navigation bar is on every primary screen and had no test.
///
/// It is also the first thing named in `app.dart`'s comment justifying the
/// text-scale clamp — "the 5-item bottom nav bar … was built and tested
/// against that 1.0x baseline". So it decides whether that clamp can be
/// raised: a nav bar that clips its labels at 2.0 would do it on every screen
/// at once, which is worse than any single screen overflowing.
///
/// `NavigationBar` pins itself to `height: 88` here. That is the shape that
/// usually fails at scale, so it is the thing to check rather than assume.

Widget _host(double textScale, {double width = 360}) {
  final router = GoRouter(
    initialLocation: '/home',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            MainShell(navigationShell: navigationShell),
        branches: [
          for (final path in [
            '/home',
            '/applications',
            '/payments',
            '/profile',
          ])
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: path,
                  builder: (_, _) => Scaffold(body: Center(child: Text(path))),
                ),
              ],
            ),
        ],
      ),
    ],
  );

  return MultiProvider(
    providers: [
      ChangeNotifierProvider<NotificationsProvider>(
        create: (_) =>
            NotificationsProvider(repository: MockNotificationsRepository()),
      ),
      // Everything DraftRegistry looks up, for the idle-draft nudge.
      ...wizardProviders(),
    ],
    child: MaterialApp.router(
      theme: AppTheme.lightTheme,
      routerConfig: router,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
    ),
  );
}

Future<void> _pump(
  WidgetTester tester,
  double textScale, {
  double width = 360,
}) async {
  tester.view.physicalSize = Size(width, 900);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(_host(textScale, width: width));
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('the bottom navigation bar renders', () {
    for (final scale in [1.0, 1.3, 2.0]) {
      for (final width in [320.0, 360.0]) {
        testWidgets('at ${scale}x on ${width.toInt()}dp', (tester) async {
          await _pump(tester, scale, width: width);
          expect(tester.takeException(), isNull);
          expect(find.byType(NavigationBar), findsOneWidget);
        });
      }
    }
  });

  testWidgets('every destination label stays inside the bar', (tester) async {
    // The bar pins itself to 88dp. A label that needs more than that is not
    // reported as an overflow — NavigationBar clips it — so height alone is
    // what has to be asserted.
    await _pump(tester, 2.0, width: 320);

    final bar = tester.getRect(find.byType(NavigationBar));
    for (final label in ['Home', 'Applications', 'Payments', 'Profile']) {
      final text = tester.getRect(find.text(label));
      expect(
        text.bottom,
        lessThanOrEqualTo(bar.bottom + 0.5),
        reason: '"$label" runs past the bottom of the navigation bar',
      );
      expect(
        text.top,
        greaterThanOrEqualTo(bar.top - 0.5),
        reason: '"$label" runs above the top of the navigation bar',
      );
    }
  });

  testWidgets('tapping a destination switches branch', (tester) async {
    await _pump(tester, 1.0);
    expect(find.text('/home'), findsOneWidget);

    await tester.tap(find.text('Payments'));
    await tester.pumpAndSettle();

    expect(find.text('/payments'), findsOneWidget);
  });

  group('nothing in the shell chrome is cut off', () {
    // The same check the screen suites run, applied where the defect actually
    // was. The explicit assertion above names the four labels; this one would
    // catch a fifth destination, or anything else pinned inside the bar.
    for (final scale in [1.0, 1.3, 2.0]) {
      for (final width in [320.0, 360.0]) {
        testWidgets('at ${scale}x on ${width.toInt()}dp', (tester) async {
          await _pump(tester, scale, width: width);
          expectNoClippedText(
            tester,
            context: 'MainShell ${scale}x/${width.toInt()}dp',
          );
        });
      }
    }
  });
}
