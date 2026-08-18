import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:ebpco_user_app/core/theme/app_theme.dart';
import 'package:ebpco_user_app/features/applications/presentation/pre_flight_screen.dart';

Widget _wrap() {
  final router = GoRouter(
    initialLocation: '/gate',
    routes: [
      GoRoute(
        path: '/gate',
        builder: (_, _) => const PreFlightScreen(
          permitType: 'New Construction',
          wizardRoute: '/wizard',
        ),
      ),
      GoRoute(
        path: '/wizard',
        builder: (_, _) => const Scaffold(body: Text('WIZARD')),
      ),
      GoRoute(
        path: '/charter/:permitType',
        builder: (_, _) => const Scaffold(body: Text('CHARTER')),
      ),
    ],
  );
  return MaterialApp.router(
    theme: AppTheme.lightTheme,
    routerConfig: router,
  );
}

Future<void> _answer(WidgetTester tester, String question, String choice) async {
  final card = find.ancestor(
    of: find.text(question),
    matching: find.byType(Container),
  );
  await tester.tap(
    find.descendant(of: card.first, matching: find.text(choice)),
  );
  await tester.pumpAndSettle();
}

const _clearance = 'Do you have your Locational or Zoning Clearance?';
const _ownership = 'Do you have proof of ownership, or the right to build?';
const _professional = 'Have you engaged a licensed architect or engineer?';

void main() {
  testWidgets('asks the three questions that most often stall a filing', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(400, 2000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle();

    expect(find.text('New Construction'), findsOneWidget);
    expect(find.text(_clearance), findsOneWidget);
    expect(find.text(_ownership), findsOneWidget);
    expect(find.text(_professional), findsOneWidget);
  });

  testWidgets('cannot proceed until every question is answered', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(400, 2000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle();

    ElevatedButton primary() => tester.widget<ElevatedButton>(
      find.byType(ElevatedButton).first,
    );

    // Unanswered is not the same as "no" — an untouched question must not be
    // read as a missing prerequisite.
    expect(primary().onPressed, isNull);
    expect(find.textContaining('to secure first'), findsNothing);

    await _answer(tester, _clearance, 'Yes');
    expect(primary().onPressed, isNull);

    await _answer(tester, _ownership, 'Yes');
    await _answer(tester, _professional, 'Yes');
    expect(primary().onPressed, isNotNull);
  });

  testWidgets('all yes goes straight into the wizard', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 2000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle();

    await _answer(tester, _clearance, 'Yes');
    await _answer(tester, _ownership, 'Yes');
    await _answer(tester, _professional, 'Yes');

    expect(find.text('Start the application'), findsOneWidget);
    await tester.tap(find.text('Start the application'));
    await tester.pumpAndSettle();

    expect(find.text('WIZARD'), findsOneWidget);
  });

  testWidgets('a missing prerequisite names the office that issues it', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(400, 2000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle();

    await _answer(tester, _clearance, 'Not yet');
    await _answer(tester, _ownership, 'Yes');
    await _answer(tester, _professional, 'Yes');

    expect(find.text('One thing to secure first'), findsOneWidget);
    expect(
      find.text('City or Municipal Planning and Development Office'),
      findsOneWidget,
    );
  });

  testWidgets('it guides but never blocks', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 2000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle();

    await _answer(tester, _clearance, 'Not yet');
    await _answer(tester, _ownership, 'Not yet');
    await _answer(tester, _professional, 'Not yet');

    expect(find.text('3 things to secure first'), findsOneWidget);

    // Someone mid-way through securing a clearance, or who knows something
    // the app does not, must still be able to start.
    expect(find.text('Continue anyway'), findsOneWidget);
    await tester.tap(find.text('Continue anyway'));
    await tester.pumpAndSettle();

    expect(find.text('WIZARD'), findsOneWidget);
  });

  testWidgets('offers the full requirement list before committing', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(400, 2000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle();

    expect(find.textContaining('documents in total'), findsOneWidget);
    await tester.tap(find.text('View the full requirements'));
    await tester.pumpAndSettle();

    expect(find.text('CHARTER'), findsOneWidget);
  });
}
