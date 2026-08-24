import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ebpco_user_app/core/constants/app_constants.dart';
import 'package:ebpco_user_app/core/providers/auth_provider.dart';
import 'package:ebpco_user_app/core/providers/documents_provider.dart';
import 'package:ebpco_user_app/core/theme/app_theme.dart';

import 'package:ebpco_user_app/features/applications/presentation/addition_extension_permit/addition_extension_application_submitted_screen.dart';
import 'package:ebpco_user_app/features/applications/presentation/architectural_permit/architectural_application_submitted_screen.dart';
import 'package:ebpco_user_app/features/applications/presentation/building_permit/application_submitted_screen.dart';
import 'package:ebpco_user_app/features/applications/presentation/certificate_of_occupancy/certificate_of_occupancy_submitted_screen.dart';
import 'package:ebpco_user_app/features/applications/presentation/civil_structural_permit/civil_structural_application_submitted_screen.dart';
import 'package:ebpco_user_app/features/applications/presentation/demolition_permit/demolition_application_submitted_screen.dart';
import 'package:ebpco_user_app/features/applications/presentation/electrical_permit/electrical_application_submitted_screen.dart';
import 'package:ebpco_user_app/features/applications/presentation/electronics_permit/electronics_application_submitted_screen.dart';
import 'package:ebpco_user_app/features/applications/presentation/excavation_permit/excavation_application_submitted_screen.dart';
import 'package:ebpco_user_app/features/applications/presentation/fencing_permit/fencing_application_submitted_screen.dart';
import 'package:ebpco_user_app/features/applications/presentation/interior_design_permit/interior_design_application_submitted_screen.dart';
import 'package:ebpco_user_app/features/applications/presentation/mechanical_permit/mechanical_application_submitted_screen.dart';
import 'package:ebpco_user_app/features/applications/presentation/plumbing_permit/plumbing_application_submitted_screen.dart';
import 'package:ebpco_user_app/features/applications/presentation/renovation_permit/renovation_application_submitted_screen.dart';
import 'package:ebpco_user_app/features/applications/presentation/sanitary_plumbing_permit/sanitary_plumbing_application_submitted_screen.dart';
import 'package:ebpco_user_app/features/applications/presentation/sign_permit/sign_application_submitted_screen.dart';
import 'package:ebpco_user_app/features/documents/presentation/document_preview_screen.dart';
import 'package:ebpco_user_app/features/splash/presentation/splash_screen.dart';

import 'support/clipping.dart';

/// The last screens with no accessibility coverage: the sixteen terminal
/// confirmation pages one per permit type, plus splash and document preview.
///
/// The confirmation screens are near-copies of one another, so a defect in one
/// is a defect in most. That makes covering all sixteen worth more than it
/// looks — and it is also the safety net for consolidating them, which is the
/// obvious next move on this file.
///
/// Values are the demanding end of realistic: a long reference number, a
/// related permit that has not been assigned yet (the empty-string branch),
/// and a status long enough to test the row that carries it.

final _submissionDate = DateTime(2026, 8, 24);
const _reference = 'EBPCO-QC-2026-08-000145-R2';
const _relatedNumber = 'BP-2026-QC-0004821';
const _relatedStatus = 'Pending initial evaluation';

final _screens = <String, Widget Function()>{
  'AdditionExtension': () => AdditionExtensionApplicationSubmittedScreen(
    referenceNumber: _reference,
    submissionDate: _submissionDate,
  ),
  'Architectural': () => ArchitecturalApplicationSubmittedScreen(
    referenceNumber: _reference,
    submissionDate: _submissionDate,
    relatedBuildingPermitNumber: _relatedNumber,
    relatedBuildingPermitStatus: _relatedStatus,
  ),
  'BuildingPermit': () => const ApplicationSubmittedScreen(
    trackingId: _reference,
  ),
  'CertificateOfOccupancy': () => CertificateOfOccupancySubmittedScreen(
    referenceNumber: _reference,
    submissionDate: _submissionDate,
    buildingPermitNumber: _relatedNumber,
    certificateType: 'Full Certificate of Occupancy',
  ),
  'CivilStructural': () => CivilStructuralApplicationSubmittedScreen(
    referenceNumber: _reference,
    submissionDate: _submissionDate,
    relatedBuildingPermitNumber: _relatedNumber,
    relatedBuildingPermitStatus: _relatedStatus,
  ),
  'Demolition': () => DemolitionApplicationSubmittedScreen(
    referenceNumber: _reference,
    submissionDate: _submissionDate,
  ),
  'Electrical': () => ElectricalApplicationSubmittedScreen(
    referenceNumber: _reference,
    submissionDate: _submissionDate,
    relatedBuildingPermitNumber: _relatedNumber,
    relatedBuildingPermitStatus: _relatedStatus,
    electricalContractorRequired: true,
  ),
  'Electronics': () => ElectronicsApplicationSubmittedScreen(
    referenceNumber: _reference,
    submissionDate: _submissionDate,
    relatedBuildingPermitNumber: _relatedNumber,
    relatedBuildingPermitStatus: _relatedStatus,
  ),
  'Excavation': () => ExcavationApplicationSubmittedScreen(
    referenceNumber: _reference,
    submissionDate: _submissionDate,
    // The unassigned branch: these screens substitute "Not yet assigned",
    // which is longer than most real permit numbers.
    relatedBuildingPermitNumber: '',
    relatedBuildingPermitStatus: _relatedStatus,
  ),
  'Fencing': () => FencingApplicationSubmittedScreen(
    referenceNumber: _reference,
    submissionDate: _submissionDate,
    relatedBuildingPermitNumber: _relatedNumber,
    relatedBuildingPermitStatus: _relatedStatus,
  ),
  'InteriorDesign': () => InteriorDesignApplicationSubmittedScreen(
    referenceNumber: _reference,
    submissionDate: _submissionDate,
    relatedBuildingPermitNumber: _relatedNumber,
    relatedBuildingPermitStatus: _relatedStatus,
  ),
  'Mechanical': () => MechanicalApplicationSubmittedScreen(
    referenceNumber: _reference,
    submissionDate: _submissionDate,
    relatedBuildingPermitNumber: _relatedNumber,
    relatedBuildingPermitStatus: _relatedStatus,
  ),
  'Plumbing': () => PlumbingApplicationSubmittedScreen(
    referenceNumber: _reference,
    submissionDate: _submissionDate,
    relatedBuildingPermitNumber: _relatedNumber,
    relatedBuildingPermitStatus: _relatedStatus,
  ),
  'Renovation': () => RenovationApplicationSubmittedScreen(
    referenceNumber: _reference,
    submissionDate: _submissionDate,
  ),
  'SanitaryPlumbing': () => SanitaryPlumbingApplicationSubmittedScreen(
    referenceNumber: _reference,
    submissionDate: _submissionDate,
    relatedBuildingPermitNumber: _relatedNumber,
    relatedBuildingPermitStatus: _relatedStatus,
  ),
  'Sign': () => SignApplicationSubmittedScreen(
    referenceNumber: _reference,
    submissionDate: _submissionDate,
    relatedBuildingPermitNumber: _relatedNumber,
    relatedBuildingPermitStatus: _relatedStatus,
  ),
  'Splash': () => const SplashScreen(),
  'DocumentPreview': () => const DocumentPreviewScreen(documentId: 'doc-seed-1'),
};

Widget _host(Widget Function() build, double textScale) {
  final router = GoRouter(
    initialLocation: '/subject',
    routes: [
      GoRoute(path: '/subject', builder: (_, _) => build()),
      GoRoute(path: '/:a', builder: (_, _) => const Scaffold()),
      GoRoute(path: '/:a/:b', builder: (_, _) => const Scaffold()),
      GoRoute(path: '/:a/:b/:c', builder: (_, _) => const Scaffold()),
    ],
  );

  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AuthProvider>(create: (_) => AuthProvider()),
      ChangeNotifierProvider<DocumentsProvider>(
        create: (_) => DocumentsProvider(),
      ),
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

Future<void> _open(
  WidgetTester tester,
  Widget Function() screen, {
  required double textScale,
  double width = 360,
  double height = 3000,
}) async {
  tester.view.physicalSize = Size(width, height);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(_host(screen, textScale));
  await tester.pump();
  await tester.pump(const Duration(seconds: 3));
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('render without overflowing at 100%', () {
    _screens.forEach((name, screen) {
      testWidgets(name, (tester) async {
        await _open(tester, screen, textScale: 1.0);
        expect(tester.takeException(), isNull);
      });
    });
  });

  group('render without overflowing at 200% text scale', () {
    _screens.forEach((name, screen) {
      testWidgets(name, (tester) async {
        await _open(tester, screen, textScale: 2.0);
        expect(tester.takeException(), isNull);
      });
    });
  });

  group('render without overflowing at 320dp', () {
    _screens.forEach((name, screen) {
      testWidgets(name, (tester) async {
        await _open(tester, screen, textScale: 1.0, width: 320);
        expect(tester.takeException(), isNull);
      });
    });
  });

  group('controls meet the 48dp floor', () {
    _screens.forEach((name, screen) {
      testWidgets(name, (tester) async {
        await _open(tester, screen, textScale: 1.0);

        for (final element in find.byType(IconButton).evaluate()) {
          final size = tester.getSize(find.byWidget(element.widget));
          expect(
            size.height,
            greaterThanOrEqualTo(AppConstants.minTouchTarget - 0.5),
            reason: '$name: an IconButton is only ${size.height}dp tall',
          );
        }
        for (final type in [ElevatedButton, OutlinedButton, TextButton]) {
          for (final element in find.byType(type).evaluate()) {
            final size = tester.getSize(find.byWidget(element.widget));
            if (size.isEmpty) continue;
            expect(
              size.height,
              greaterThanOrEqualTo(AppConstants.minTouchTarget - 0.5),
              reason: '$name: a $type is only ${size.height}dp tall',
            );
          }
        }
      });
    });
  });

  group('no text is cut off by a fixed-height box', () {
    // Distinct from the overflow groups above: a box that pins its height does
    // not report an overflow when its text outgrows it, the text just stops
    // rendering. That is how the bottom navigation bar clipped "Applications"
    // on every screen while three scales of render tests passed.
    for (final scale in [1.0, 2.0]) {
      _screens.forEach((name, screen) {
        testWidgets('$name at ${scale}x', (tester) async {
          await _open(tester, screen, textScale: scale);
          expectNoTextClippedByFixedHeight(tester, context: name);
        });
      });
    }
  });

}
