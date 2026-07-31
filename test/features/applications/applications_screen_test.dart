import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:ebpco_user_app/core/providers/addition_extension_permit_provider.dart';
import 'package:ebpco_user_app/core/providers/architectural_permit_provider.dart';
import 'package:ebpco_user_app/core/providers/auth_provider.dart';
import 'package:ebpco_user_app/core/providers/building_permit_provider.dart';
import 'package:ebpco_user_app/core/providers/civil_structural_permit_provider.dart';
import 'package:ebpco_user_app/core/providers/demolition_permit_provider.dart';
import 'package:ebpco_user_app/core/providers/electrical_permit_provider.dart';
import 'package:ebpco_user_app/core/providers/electronics_permit_provider.dart';
import 'package:ebpco_user_app/core/providers/interior_design_permit_provider.dart';
import 'package:ebpco_user_app/core/providers/mechanical_permit_provider.dart';
import 'package:ebpco_user_app/core/providers/plumbing_permit_provider.dart';
import 'package:ebpco_user_app/core/providers/renovation_permit_provider.dart';
import 'package:ebpco_user_app/core/providers/sanitary_plumbing_permit_provider.dart';
import 'package:ebpco_user_app/features/applications/presentation/addition_extension_permit/addition_extension_permit_wizard_screen.dart';
import 'package:ebpco_user_app/features/applications/presentation/applications_screen.dart';
import 'package:ebpco_user_app/features/applications/presentation/architectural_permit/architectural_permit_wizard_screen.dart';
import 'package:ebpco_user_app/features/applications/presentation/building_permit/building_permit_wizard_screen.dart';
import 'package:ebpco_user_app/features/applications/presentation/civil_structural_permit/civil_structural_permit_wizard_screen.dart';
import 'package:ebpco_user_app/features/applications/presentation/demolition_permit/demolition_permit_wizard_screen.dart';
import 'package:ebpco_user_app/features/applications/presentation/electrical_permit/electrical_permit_wizard_screen.dart';
import 'package:ebpco_user_app/features/applications/presentation/electronics_permit/electronics_permit_wizard_screen.dart';
import 'package:ebpco_user_app/features/applications/presentation/interior_design_permit/interior_design_permit_wizard_screen.dart';
import 'package:ebpco_user_app/features/applications/presentation/mechanical_permit/mechanical_permit_wizard_screen.dart';
import 'package:ebpco_user_app/features/applications/presentation/plumbing_permit/plumbing_permit_wizard_screen.dart';
import 'package:ebpco_user_app/features/applications/presentation/renovation_permit/renovation_permit_wizard_screen.dart';
import 'package:ebpco_user_app/features/applications/presentation/sanitary_plumbing_permit/sanitary_plumbing_permit_wizard_screen.dart';

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
      GoRoute(
        path: '/applications/new/renovation-permit',
        builder: (context, state) => const RenovationPermitWizardScreen(),
      ),
      GoRoute(
        path: '/applications/new/addition-extension-permit',
        builder: (context, state) =>
            const AdditionExtensionPermitWizardScreen(),
      ),
      GoRoute(
        path: '/applications/new/demolition-permit',
        builder: (context, state) => const DemolitionPermitWizardScreen(),
      ),
      GoRoute(
        path: '/applications/new/architectural-permit',
        builder: (context, state) => const ArchitecturalPermitWizardScreen(),
      ),
      GoRoute(
        path: '/applications/new/civil-structural-permit',
        builder: (context, state) =>
            const CivilStructuralPermitWizardScreen(),
      ),
      GoRoute(
        path: '/applications/new/electrical-permit',
        builder: (context, state) => const ElectricalPermitWizardScreen(),
      ),
      GoRoute(
        path: '/applications/new/mechanical-permit',
        builder: (context, state) => const MechanicalPermitWizardScreen(),
      ),
      GoRoute(
        path: '/applications/new/sanitary-plumbing-permit',
        builder: (context, state) =>
            const SanitaryPlumbingPermitWizardScreen(),
      ),
      GoRoute(
        path: '/applications/new/plumbing-permit',
        builder: (context, state) => const PlumbingPermitWizardScreen(),
      ),
      GoRoute(
        path: '/applications/new/electronics-permit',
        builder: (context, state) => const ElectronicsPermitWizardScreen(),
      ),
      GoRoute(
        path: '/applications/new/interior-design-permit',
        builder: (context, state) =>
            const InteriorDesignPermitWizardScreen(),
      ),
    ],
  );
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AuthProvider>(create: (_) => AuthProvider()),
      ChangeNotifierProvider<BuildingPermitProvider>(
        create: (_) => BuildingPermitProvider(),
      ),
      ChangeNotifierProvider<RenovationPermitProvider>(
        create: (_) => RenovationPermitProvider(),
      ),
      ChangeNotifierProvider<AdditionExtensionPermitProvider>(
        create: (_) => AdditionExtensionPermitProvider(),
      ),
      ChangeNotifierProvider<DemolitionPermitProvider>(
        create: (_) => DemolitionPermitProvider(),
      ),
      ChangeNotifierProvider<ArchitecturalPermitProvider>(
        create: (_) => ArchitecturalPermitProvider(),
      ),
      ChangeNotifierProvider<CivilStructuralPermitProvider>(
        create: (_) => CivilStructuralPermitProvider(),
      ),
      ChangeNotifierProvider<ElectricalPermitProvider>(
        create: (_) => ElectricalPermitProvider(),
      ),
      ChangeNotifierProvider<MechanicalPermitProvider>(
        create: (_) => MechanicalPermitProvider(),
      ),
      ChangeNotifierProvider<SanitaryPlumbingPermitProvider>(
        create: (_) => SanitaryPlumbingPermitProvider(),
      ),
      ChangeNotifierProvider<PlumbingPermitProvider>(
        create: (_) => PlumbingPermitProvider(),
      ),
      ChangeNotifierProvider<ElectronicsPermitProvider>(
        create: (_) => ElectronicsPermitProvider(),
      ),
      ChangeNotifierProvider<InteriorDesignPermitProvider>(
        create: (_) => InteriorDesignPermitProvider(),
      ),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

/// Every placeholder entry across all four catalog sections — none of
/// these should navigate anywhere.
const _placeholderPermits = [
  // Other Permits section
  'Fencing',
  'Sign Permit',
  'Excavation',
  // Certificates section
  'Certificate of Occupancy',
];

void main() {
  // The Applications page's content is much taller than the default
  // 800x600 test canvas now that it lists every permit catalog entry.
  Future<void> useTallSurface(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 4000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
  }

  testWidgets(
    'Applications page renders all four catalog sections and their entries',
    (tester) async {
      await useTallSurface(tester);
      await tester.pumpWidget(_wrapWithRouter());
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      expect(find.text('Applications'), findsOneWidget);

      // Section titles.
      expect(find.text('Building Permit'), findsOneWidget);
      expect(find.text('Ancillary Permits'), findsOneWidget);
      expect(find.text('Other Permits'), findsOneWidget);
      expect(find.text('Certificates'), findsOneWidget);

      // A sample entry from each section.
      expect(find.text('New Construction'), findsOneWidget);
      expect(find.text('Architectural'), findsOneWidget);
      expect(find.text('Fencing'), findsOneWidget);
      expect(find.text('Certificate of Occupancy'), findsOneWidget);
    },
  );

  testWidgets('New Construction opens the Building Permit wizard at Step 1', (
    tester,
  ) async {
    await useTallSurface(tester);
    await tester.pumpWidget(_wrapWithRouter());
    await tester.pumpAndSettle();

    await tester.tap(find.text('New Construction'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    expect(find.widgetWithText(AppBar, 'Building Permit'), findsOneWidget);
    expect(find.text('Step 1 of 9'), findsOneWidget);
    expect(find.text('Applicant Information'), findsOneWidget);
    expect(find.text('New Application'), findsOneWidget);
  });

  testWidgets('Renovation opens the Renovation Permit wizard at Step 1', (
    tester,
  ) async {
    await useTallSurface(tester);
    await tester.pumpWidget(_wrapWithRouter());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Renovation'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    expect(find.widgetWithText(AppBar, 'Renovation Permit'), findsOneWidget);
    expect(find.text('Step 1 of 9'), findsOneWidget);
    expect(find.text('Applicant Information'), findsOneWidget);
    expect(find.text('Renovation'), findsWidgets);
  });

  testWidgets(
    'Addition / Extension opens the Addition / Extension Permit wizard at Step 1',
    (tester) async {
      await useTallSurface(tester);
      await tester.pumpWidget(_wrapWithRouter());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Addition / Extension'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      expect(
        find.widgetWithText(AppBar, 'Addition / Extension Permit'),
        findsOneWidget,
      );
      expect(find.text('Step 1 of 9'), findsOneWidget);
      expect(find.text('Applicant Information'), findsOneWidget);
      expect(find.text('Addition / Extension'), findsWidgets);
    },
  );

  testWidgets('Demolition opens the Demolition Permit wizard at Step 1', (
    tester,
  ) async {
    await useTallSurface(tester);
    await tester.pumpWidget(_wrapWithRouter());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Demolition'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    expect(find.widgetWithText(AppBar, 'Demolition Permit'), findsOneWidget);
    expect(find.text('Step 1 of 9'), findsOneWidget);
    expect(find.text('Applicant Information'), findsOneWidget);
    expect(find.text('Demolition'), findsWidgets);
  });

  testWidgets(
    'Architectural opens the Architectural Permit wizard at Step 1',
    (tester) async {
      await useTallSurface(tester);
      await tester.pumpWidget(_wrapWithRouter());
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Architectural'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Architectural'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      expect(
        find.widgetWithText(AppBar, 'Architectural Permit'),
        findsOneWidget,
      );
      expect(find.text('Step 1 of 9'), findsOneWidget);
      expect(find.text('Applicant Information'), findsOneWidget);
      expect(find.text('Architectural Permit'), findsWidgets);
    },
  );

  testWidgets(
    'Civil / Structural opens the Civil / Structural Permit wizard at Step 1',
    (tester) async {
      await useTallSurface(tester);
      await tester.pumpWidget(_wrapWithRouter());
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Civil / Structural'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Civil / Structural'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      expect(
        find.widgetWithText(AppBar, 'Civil / Structural Permit'),
        findsOneWidget,
      );
      expect(find.text('Step 1 of 9'), findsOneWidget);
      expect(find.text('Applicant Information'), findsOneWidget);
      expect(find.text('Civil / Structural Permit'), findsWidgets);
    },
  );

  testWidgets(
    'Electrical opens the Electrical Permit wizard at Step 1',
    (tester) async {
      await useTallSurface(tester);
      await tester.pumpWidget(_wrapWithRouter());
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Electrical'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Electrical'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      expect(
        find.widgetWithText(AppBar, 'Electrical Permit'),
        findsOneWidget,
      );
      expect(find.text('Step 1 of 9'), findsOneWidget);
      expect(find.text('Applicant Information'), findsOneWidget);
      expect(find.text('Electrical Permit'), findsWidgets);
    },
  );

  testWidgets(
    'Mechanical opens the Mechanical Permit wizard at Step 1',
    (tester) async {
      await useTallSurface(tester);
      await tester.pumpWidget(_wrapWithRouter());
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Mechanical'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Mechanical'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      expect(
        find.widgetWithText(AppBar, 'Mechanical Permit'),
        findsOneWidget,
      );
      expect(find.text('Step 1 of 9'), findsOneWidget);
      expect(find.text('Applicant Information'), findsOneWidget);
      expect(find.text('Mechanical Permit'), findsWidgets);
    },
  );

  testWidgets(
    'Sanitary / Plumbing opens the Sanitary / Plumbing Permit wizard at Step 1',
    (tester) async {
      await useTallSurface(tester);
      await tester.pumpWidget(_wrapWithRouter());
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Sanitary / Plumbing'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sanitary / Plumbing'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      expect(
        find.widgetWithText(AppBar, 'Sanitary / Plumbing Permit'),
        findsOneWidget,
      );
      expect(find.text('Step 1 of 9'), findsOneWidget);
      expect(find.text('Applicant Information'), findsOneWidget);
      expect(find.text('Sanitary / Plumbing Permit'), findsWidgets);
    },
  );

  testWidgets(
    'Plumbing opens the Plumbing Permit wizard at Step 1, not the Sanitary / Plumbing wizard',
    (tester) async {
      await useTallSurface(tester);
      await tester.pumpWidget(_wrapWithRouter());
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Plumbing'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Plumbing'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      expect(
        find.widgetWithText(AppBar, 'Plumbing Permit'),
        findsOneWidget,
      );
      expect(
        find.widgetWithText(AppBar, 'Sanitary / Plumbing Permit'),
        findsNothing,
      );
      expect(find.text('Step 1 of 9'), findsOneWidget);
      expect(find.text('Applicant Information'), findsOneWidget);
      expect(find.text('Plumbing Permit'), findsWidgets);
    },
  );

  testWidgets(
    'Electronics opens the Electronics Permit wizard at Step 1',
    (tester) async {
      await useTallSurface(tester);
      await tester.pumpWidget(_wrapWithRouter());
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Electronics'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Electronics'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      expect(
        find.widgetWithText(AppBar, 'Electronics Permit'),
        findsOneWidget,
      );
      expect(find.text('Step 1 of 9'), findsOneWidget);
      expect(find.text('Applicant Information'), findsOneWidget);
      expect(find.text('Electronics Permit'), findsWidgets);
    },
  );

  testWidgets(
    'Interior opens the Interior Design Permit wizard at Step 1',
    (tester) async {
      await useTallSurface(tester);
      await tester.pumpWidget(_wrapWithRouter());
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Interior'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Interior'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      expect(
        find.widgetWithText(AppBar, 'Interior Design Permit'),
        findsOneWidget,
      );
      expect(find.text('Step 1 of 9'), findsOneWidget);
      expect(find.text('Applicant Information'), findsOneWidget);
      expect(find.text('Interior Design Permit'), findsWidgets);
    },
  );

  testWidgets(
    'every placeholder permit shows the "coming soon" message and does not navigate',
    (tester) async {
      await useTallSurface(tester);
      await tester.pumpWidget(_wrapWithRouter());
      await tester.pumpAndSettle();

      for (final label in _placeholderPermits) {
        await tester.ensureVisible(find.text(label));
        await tester.pumpAndSettle();
        await tester.tap(find.text(label));
        await tester.pump();
        expect(tester.takeException(), isNull, reason: 'tapping "$label"');

        expect(
          find.text('This permit will be available in a future update.'),
          findsOneWidget,
          reason: '"$label" should show the coming-soon message',
        );

        // Still on the Applications page — no wizard, no other screen.
        expect(
          find.text('Applications'),
          findsOneWidget,
          reason: '"$label" should not navigate away from Applications',
        );
        expect(
          find.widgetWithText(AppBar, 'Renovation Permit'),
          findsNothing,
          reason: '"$label" should not open the Renovation Permit wizard',
        );
        expect(
          find.widgetWithText(AppBar, 'Building Permit'),
          findsNothing,
          reason: '"$label" should not open the Building Permit wizard',
        );
        expect(
          find.widgetWithText(AppBar, 'Addition / Extension Permit'),
          findsNothing,
          reason:
              '"$label" should not open the Addition / Extension Permit wizard',
        );
        expect(find.text('New Application Screen'), findsNothing);

        // Let the SnackBar clear before checking the next entry.
        await tester.pump(const Duration(seconds: 5));
        await tester.pumpAndSettle();
      }
    },
  );
}
