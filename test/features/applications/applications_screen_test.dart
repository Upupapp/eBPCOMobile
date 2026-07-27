import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:ebpco_user_app/core/providers/building_permit_provider.dart';
import 'package:ebpco_user_app/features/applications/presentation/applications_screen.dart';
import 'package:ebpco_user_app/features/applications/presentation/building_permit/building_permit_wizard_screen.dart';

Widget _wrapWithRouter() {
  final router = GoRouter(
    initialLocation: '/app/applications',
    routes: [
      GoRoute(
        path: '/app/applications',
        builder: (context, state) => const ApplicationsScreen(),
      ),
      GoRoute(
        path: '/applications/new',
        builder: (context, state) =>
            const Scaffold(body: Text('New Application Screen')),
      ),
      GoRoute(
        path: '/applications/new/building-permit',
        builder: (context, state) => const BuildingPermitWizardScreen(),
      ),
    ],
  );
  return ChangeNotifierProvider<BuildingPermitProvider>(
    create: (_) => BuildingPermitProvider(),
    child: MaterialApp.router(routerConfig: router),
  );
}

void main() {
  // The Applications page's content is taller than the default 800x600 test
  // canvas, which would leave the "Building Permit" list card (and the
  // grid cards) outside the lazily-built viewport.
  Future<void> useTallSurface(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
  }

  testWidgets(
    'Applications page renders with the Building Permit entry points',
    (tester) async {
      await useTallSurface(tester);
      await tester.pumpWidget(_wrapWithRouter());
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      expect(find.text('Applications'), findsOneWidget);
      expect(find.text('New Construction'), findsOneWidget);
      expect(find.text('Building Permit'), findsOneWidget);
    },
  );

  testWidgets('Building Permit card opens the wizard at Step 1', (
    tester,
  ) async {
    await useTallSurface(tester);
    await tester.pumpWidget(_wrapWithRouter());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Building Permit'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    expect(find.widgetWithText(AppBar, 'Building Permit'), findsOneWidget);
    expect(find.text('Step 1 of 9'), findsOneWidget);
    expect(find.text('Applicant Information'), findsOneWidget);
    expect(find.text('New Application'), findsOneWidget);
  });

  testWidgets(
    'the four project-type grid cards also open the wizard at Step 1',
    (tester) async {
      await useTallSurface(tester);
      await tester.pumpWidget(_wrapWithRouter());
      await tester.pumpAndSettle();

      for (final label in [
        'New Construction',
        'Renovation',
        'Extension',
        'Demolition',
      ]) {
        await tester.tap(find.text(label));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: 'tapping "$label"');
        expect(
          find.widgetWithText(AppBar, 'Building Permit'),
          findsOneWidget,
          reason: '"$label" should open the Building Permit wizard',
        );
        expect(find.text('Step 1 of 9'), findsOneWidget);

        // The AppBar's back arrow now opens an exit-confirmation dialog
        // (to avoid losing draft progress) rather than popping directly.
        await tester.tap(find.byIcon(Icons.arrow_back));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Save & Exit'));
        await tester.pumpAndSettle();
      }
    },
  );
}
