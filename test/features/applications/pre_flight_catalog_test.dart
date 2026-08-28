import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ebpco_user_app/core/contract/admin_vocabulary.dart';
import 'package:ebpco_user_app/core/theme/app_theme.dart';
import 'package:ebpco_user_app/features/applications/presentation/pre_flight_screen.dart';

/// Pre-flight is where an applicant decides whether to start. It used to say
/// only how many documents the Citizen's Charter listed, for the five permit
/// types the charter covered.
///
/// It now answers the office's own questions — which official form, how many
/// documents are actually required, how long the permit lasts — from the
/// catalog mirrored off the admin portal.

Future<void> _open(WidgetTester tester, String permitType) async {
  tester.view.physicalSize = const Size(400, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final router = GoRouter(
    initialLocation: '/pre-flight',
    routes: [
      GoRoute(
        path: '/pre-flight',
        builder: (_, _) =>
            PreFlightScreen(permitType: permitType, wizardRoute: '/wizard'),
      ),
      GoRoute(path: '/:a', builder: (_, _) => const Scaffold()),
      GoRoute(path: '/:a/:b', builder: (_, _) => const Scaffold()),
    ],
  );

  await tester.pumpWidget(
    MaterialApp.router(theme: AppTheme.lightTheme, routerConfig: router),
  );
  await tester.pump();
  await tester.pump(const Duration(seconds: 2));
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('names the official form for a Castilla-verified permit', (
    tester,
  ) async {
    await _open(tester, CanonicalPermitType.zoningLocationalClearance.wire);

    expect(find.text('Official form'), findsOneWidget);
    // The real MPDO form, by its own number.
    expect(find.textContaining('FM-MPD-12'), findsOneWidget);
    expect(find.text('Valid for'), findsOneWidget);
    expect(find.textContaining('12 months'), findsOneWidget);
  });

  testWidgets('separates required documents from conditional ones', (
    tester,
  ) async {
    await _open(tester, CanonicalPermitType.zoningLocationalClearance.wire);

    // 16 documents, 13 required — the other three are "if applicable" and
    // must not be presented as owed.
    expect(find.textContaining('13 required'), findsOneWidget);
    expect(find.textContaining('more if they apply'), findsOneWidget);
  });

  testWidgets('says a Certificate of Occupancy has no fixed expiry', (
    tester,
  ) async {
    await _open(tester, CanonicalPermitType.certificateOfOccupancy.wire);
    expect(find.text('No fixed expiry'), findsOneWidget);
  });

  testWidgets('marks provisional requirements as still being confirmed', (
    tester,
  ) async {
    // Architectural is sourced from a national-law baseline rather than a
    // Castilla form. Telling an applicant to secure something costly on that
    // basis, in the same voice as PD 1096, is the thing to avoid.
    await _open(tester, CanonicalPermitType.architecturalPermit.wire);
    expect(find.textContaining('still being confirmed'), findsOneWidget);
  });

  testWidgets('renders for a permit the catalog does not name', (tester) async {
    // A display lookup returns null rather than throwing, so the screen says
    // less instead of failing.
    await _open(tester, 'Some Permit The Admin Never Heard Of');
    expect(tester.takeException(), isNull);
    expect(find.text('Official form'), findsNothing);
  });

  testWidgets('the catalog facts appear for what the app actually passes', (
    tester,
  ) async {
    // The regression that made this worth asserting: the catalog screen
    // navigated with its own short display title ('New Construction'), while
    // the catalog is keyed on the office's name. Every lookup missed, so these
    // facts were invisible in the running app while this suite passed — it had
    // been fed canonical strings the app never produced.
    //
    // _PermitOption.lookupKey now supplies the canonical name. This asserts the
    // pairing at the value the navigation actually carries.
    await _open(tester, CanonicalPermitType.buildingPermitNewConstruction.wire);

    expect(find.text('Official form'), findsOneWidget);
    expect(find.textContaining('Unified Building Permit Form'), findsOneWidget);
    expect(find.textContaining('14 required'), findsOneWidget);
  });

  group('the blank official form', () {
    testWidgets('every catalog type offers its form from pre-flight', (
      tester,
    ) async {
      // The entry point has to exist for all nineteen, because the pre-flight
      // gate is the one screen every catalog card routes through.
      for (final type in CanonicalPermitType.values) {
        await _open(tester, type.wire);
        final official = find.text('View the official form');
        final reference = find.text('View the reference form');
        expect(
          official.evaluate().length + reference.evaluate().length,
          1,
          reason: '${type.wire} offers no way to see its form',
        );
      }
    });

    testWidgets('a Castilla form is offered as the official one', (
      tester,
    ) async {
      await _open(tester, CanonicalPermitType.fencingPermit.wire);
      expect(find.text('View the official form'), findsOneWidget);
      expect(find.text('View the reference form'), findsNothing);
    });

    testWidgets('a stand-in template is not called official', (tester) async {
      // Architectural is one of the five the LGU has not published a form
      // for. Calling it "the official form" here would send someone to the
      // counter with the wrong paper.
      await _open(tester, CanonicalPermitType.architecturalPermit.wire);
      expect(find.text('View the reference form'), findsOneWidget);
      expect(find.text('View the official form'), findsNothing);
    });

    testWidgets('the office checklist appears for the four types it covers', (
      tester,
    ) async {
      for (final type in [
        CanonicalPermitType.buildingPermitNewConstruction,
        CanonicalPermitType.buildingPermitRenovationAlteration,
        CanonicalPermitType.buildingPermitAdditionExtension,
        CanonicalPermitType.certificateOfOccupancy,
      ]) {
        await _open(tester, type.wire);
        expect(
          find.text('View the office checklist'),
          findsOneWidget,
          reason: type.wire,
        );
      }
    });

    testWidgets('and not for the fifteen it does not', (tester) async {
      await _open(tester, CanonicalPermitType.electricalPermit.wire);
      expect(find.text('View the office checklist'), findsNothing);
    });

    testWidgets('a permit type outside the catalog offers neither', (
      tester,
    ) async {
      // The legacy Business Permit flow has no entry in the construction
      // catalog. No form, so no button — rather than a button to nothing.
      await _open(tester, 'Business Permit');
      expect(find.text('View the official form'), findsNothing);
      expect(find.text('View the reference form'), findsNothing);
      expect(find.text('View the office checklist'), findsNothing);
    });
  });
}
