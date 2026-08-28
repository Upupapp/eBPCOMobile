import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ebpco_user_app/core/contract/admin_vocabulary.dart';
import 'package:ebpco_user_app/core/theme/app_theme.dart';
import 'package:ebpco_user_app/features/documents/presentation/official_form_screen.dart';

/// What the screen says about the paper it is showing.
///
/// Two of its jobs cannot be checked by looking at the PDF: naming the office
/// that issues the form, and admitting when the document is a generic
/// reference rather than a Castilla one. The admin portal records the second
/// fact in a source comment, where it reaches nobody.

Future<void> _open(
  WidgetTester tester,
  String permitType, {
  bool checklist = false,
  bool resolverFails = false,
}) async {
  tester.view.physicalSize = const Size(400, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  debugOfficialFormResolver = resolverFails
      ? (_) async => throw Exception('no cache directory')
      : (assetPath) async => '/tmp/$assetPath';

  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.lightTheme,
      home: OfficialFormScreen(permitType: permitType, checklist: checklist),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(seconds: 2));
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  tearDown(() => debugOfficialFormResolver = null);

  testWidgets('names the document and the office that issues it', (
    tester,
  ) async {
    await _open(tester, CanonicalPermitType.fsecForBuildingPermitBfp.wire);

    expect(
      find.text('Application for Fire Safety Evaluation Clearance'),
      findsOneWidget,
    );
    // The BFP, not the Building Official — an applicant who takes this to the
    // wrong counter has lost the morning.
    expect(find.text('Bureau of Fire Protection – Castilla'), findsOneWidget);
  });

  testWidgets('the MPDO owns the zoning form', (tester) async {
    await _open(tester, CanonicalPermitType.zoningLocationalClearance.wire);
    expect(
      find.text('Municipal Planning and Development Office'),
      findsOneWidget,
    );
  });

  testWidgets('a real Castilla form carries no disclaimer', (tester) async {
    await _open(tester, CanonicalPermitType.fencingPermit.wire);
    expect(find.textContaining('Reference only'), findsNothing);
  });

  group('reference templates say so', () {
    for (final type in [
      CanonicalPermitType.architecturalPermit,
      CanonicalPermitType.interiorDesignPermit,
      CanonicalPermitType.signPermit,
      CanonicalPermitType.demolitionPermit,
      CanonicalPermitType.certificateOfOccupancy,
    ]) {
      testWidgets('${type.wire} is labelled a stand-in', (tester) async {
        await _open(tester, type.wire);

        expect(
          find.text('Reference only — not the official form'),
          findsOneWidget,
        );
        expect(
          find.textContaining('ask the office for the form they accept'),
          findsOneWidget,
        );
        // Named inside the notice, so the applicant knows which filing the
        // caveat is about. `findsWidgets` rather than `findsOneWidget`: the
        // heading names the document too, and that second match is correct.
        expect(
          find.textContaining(
            'has not published its own blank form for ${type.wire}',
          ),
          findsOneWidget,
        );
      });
    }
  });

  testWidgets('the three building sub-types share one form, named once', (
    tester,
  ) async {
    for (final type in [
      CanonicalPermitType.buildingPermitNewConstruction,
      CanonicalPermitType.buildingPermitRenovationAlteration,
      CanonicalPermitType.buildingPermitAdditionExtension,
    ]) {
      await _open(tester, type.wire);
      expect(
        find.text('Unified Application Form for Building Permit'),
        findsOneWidget,
        reason: '${type.wire} should open the one physical form',
      );
    }
  });

  testWidgets('the checklist is shown as a checklist, not as the form', (
    tester,
  ) async {
    await _open(
      tester,
      CanonicalPermitType.buildingPermitNewConstruction.wire,
      checklist: true,
    );
    expect(find.text('Requirements checklist'), findsOneWidget);
    expect(find.textContaining('Documentary Requirements'), findsOneWidget);
  });

  group('honest failure', () {
    testWidgets('an unreadable bundle is reported, not left spinning', (
      tester,
    ) async {
      await _open(
        tester,
        CanonicalPermitType.fencingPermit.wire,
        resolverFails: true,
      );

      expect(find.text('Form could not be opened'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      // The heading still names the document, so the applicant can ask for it
      // by name at the office.
      expect(find.text('Fencing Permit Application'), findsOneWidget);
    });

    testWidgets('a type with no bundled form explains rather than breaks', (
      tester,
    ) async {
      await _open(tester, 'Business Permit');
      expect(find.text('No form for this permit'), findsOneWidget);
    });

    testWidgets('a type outside the checklist says which types it covers', (
      tester,
    ) async {
      await _open(
        tester,
        CanonicalPermitType.electricalPermit.wire,
        checklist: true,
      );
      expect(find.text('No checklist for this permit'), findsOneWidget);
      expect(
        find.textContaining(
          'building permits and the Certificate of '
          'Occupancy',
        ),
        findsOneWidget,
      );
    });
  });
}
