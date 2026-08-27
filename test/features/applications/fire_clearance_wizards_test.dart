import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ebpco_user_app/core/contract/admin_vocabulary.dart';
import 'package:ebpco_user_app/core/contract/requirements_catalog.dart';
import 'package:ebpco_user_app/core/models/document_model.dart';
import 'package:ebpco_user_app/core/providers/applications_provider.dart';
import 'package:ebpco_user_app/core/providers/auth_provider.dart';
import 'package:ebpco_user_app/core/providers/fsec_permit_provider.dart';
import 'package:ebpco_user_app/core/providers/fsic_permit_provider.dart';
import 'package:ebpco_user_app/core/providers/notifications_provider.dart';
import 'package:ebpco_user_app/core/repositories/applications_repository.dart';
import 'package:ebpco_user_app/core/repositories/notifications_repository.dart';
import 'package:ebpco_user_app/core/theme/app_theme.dart';
import 'package:ebpco_user_app/features/applications/presentation/fsec_clearance/fsec_clearance_wizard_screen.dart';
import 'package:ebpco_user_app/features/applications/presentation/fsic_clearance/fsic_clearance_wizard_screen.dart';
import 'package:ebpco_user_app/features/documents/presentation/widgets/attach_document_sheet.dart';
import 'package:ebpco_user_app/shared/widgets/uploads/document_upload_tile.dart';

/// The two fire clearances, driven end to end.
///
/// Both are preconditions under RA 9514 — the FSEC before a Building Permit is
/// issued, the FSIC before a Certificate of Occupancy — and until these
/// wizards existed the app asked applicants to hold clearances it gave them no
/// way to obtain. The Certificate of Occupancy wizard has an upload slot for
/// an FSIC to this day.

Widget _wrap(Widget wizard) {
  final router = GoRouter(
    initialLocation: '/wizard',
    routes: [
      GoRoute(path: '/wizard', builder: (_, _) => wizard),
      GoRoute(path: '/:a', builder: (_, _) => const Scaffold()),
      GoRoute(path: '/:a/:b', builder: (_, _) => const Scaffold()),
      GoRoute(path: '/:a/:b/:c', builder: (_, _) => const Scaffold()),
      GoRoute(path: '/:a/:b/:c/:d', builder: (_, _) => const Scaffold()),
    ],
  );

  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AuthProvider>(create: (_) => AuthProvider()),
      ChangeNotifierProvider<FsecPermitProvider>(
        create: (_) => FsecPermitProvider(),
      ),
      ChangeNotifierProvider<FsicPermitProvider>(
        create: (_) => FsicPermitProvider(),
      ),
      ChangeNotifierProvider<NotificationsProvider>(
        create: (_) =>
            NotificationsProvider(repository: MockNotificationsRepository()),
      ),
      ChangeNotifierProvider<ApplicationsProvider>(
        create: (context) => ApplicationsProvider(
          notifications: context.read<NotificationsProvider>(),
          repository: MockApplicationsRepository(),
        ),
      ),
    ],
    child: MaterialApp.router(theme: AppTheme.lightTheme, routerConfig: router),
  );
}

Future<void> _type(WidgetTester tester, String label, String value) async {
  final field = find.widgetWithText(TextFormField, label);
  await tester.ensureVisible(field);
  await tester.pumpAndSettle();
  await tester.enterText(field, value);
  await tester.pump();
}

Finder _continue() => find.widgetWithText(ElevatedButton, 'Continue');

Future<void> _open(WidgetTester tester, Widget wizard) async {
  tester.view.physicalSize = const Size(420, 3000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(_wrap(wizard));
  await tester.pump();
  await tester.pumpAndSettle();
}

/// Walks steps 1 and 2 so a test can reach the documents step.
Future<void> _reachDocuments(WidgetTester tester) async {
  await _type(tester, 'First Name *', 'Juan');
  await _type(tester, 'Last Name *', 'Dela Cruz');
  await _type(tester, 'Contact Number *', '09171234567');
  await _type(tester, 'Address *', '12 Rizal St.');
  await tester.tap(_continue());
  await tester.pumpAndSettle();

  await _type(tester, 'Project Name *', 'Dela Cruz Residence');
  await _type(tester, 'Project Address *', '12 Rizal St., San Isidro');
  await _type(tester, 'Occupancy Type *', 'Residential');
  await tester.tap(_continue());
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    debugAttachDocumentOverride = (context, {required String label}) async =>
        DocumentModel(
          id: label,
          label: label,
          fileName: '${label.hashCode}.pdf',
          uploadedAt: DateTime(2026, 8, 28),
        );
  });
  tearDown(() => debugAttachDocumentOverride = null);

  group('FSEC', () {
    testWidgets('says the Bureau reviews it, not the Building Office', (
      tester,
    ) async {
      await _open(tester, const FsecClearanceWizardScreen());
      expect(find.text('Fire Safety Evaluation Clearance'), findsOneWidget);
      expect(
        find.textContaining('Bureau of Fire Protection'),
        findsWidgets,
        reason: 'an applicant must know which counter this is',
      );
    });

    testWidgets('offers one slot per catalog document', (tester) async {
      await _open(tester, const FsecClearanceWizardScreen());
      await _reachDocuments(tester);

      final catalog = requirementsCatalog[
        CanonicalPermitType.fsecForBuildingPermitBfp
      ]!;
      expect(
        find.byType(DocumentUploadTile, skipOffstage: false).evaluate().length,
        catalog.documents.length,
      );
    });

    testWidgets('will not continue until the required documents are in', (
      tester,
    ) async {
      await _open(tester, const FsecClearanceWizardScreen());
      await _reachDocuments(tester);
      expect(find.text('Step 3 of 4'), findsOneWidget);
      expect(tester.widget<ElevatedButton>(_continue()).onPressed, isNull);
    });
  });

  group('FSIC', () {
    testWidgets('names the OBO endorsement it needs', (tester) async {
      // The one document that makes this permit awkward: the applicant has to
      // get an endorsement from the building office before the fire office
      // will inspect.
      await _open(tester, const FsicClearanceWizardScreen());
      await _reachDocuments(tester);
      expect(
        find.text('Endorsement from the Office of the Building Official'),
        findsOneWidget,
      );
    });

    testWidgets('offers one slot per catalog document', (tester) async {
      await _open(tester, const FsicClearanceWizardScreen());
      await _reachDocuments(tester);

      final catalog = requirementsCatalog[
        CanonicalPermitType.fsicForOccupancyPermitBfp
      ]!;
      expect(
        find.byType(DocumentUploadTile, skipOffstage: false).evaluate().length,
        catalog.documents.length,
      );
    });
  });

  test('both fire clearances are the Bureau\'s, per the catalog', () {
    for (final type in [
      CanonicalPermitType.fsecForBuildingPermitBfp,
      CanonicalPermitType.fsicForOccupancyPermitBfp,
    ]) {
      expect(requirementsCatalog[type]!.responsibleDepartmentId, 'bfp');
    }
  });
}
