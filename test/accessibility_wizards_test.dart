import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ebpco_user_app/core/constants/app_constants.dart';
import 'package:ebpco_user_app/core/providers/auth_provider.dart';
import 'package:ebpco_user_app/core/theme/app_theme.dart';
import 'package:ebpco_user_app/core/providers/addition_extension_permit_provider.dart';
import 'package:ebpco_user_app/core/providers/architectural_permit_provider.dart';
import 'package:ebpco_user_app/core/providers/building_permit_provider.dart';
import 'package:ebpco_user_app/core/providers/certificate_of_occupancy_provider.dart';
import 'package:ebpco_user_app/core/providers/civil_structural_permit_provider.dart';
import 'package:ebpco_user_app/core/providers/demolition_permit_provider.dart';
import 'package:ebpco_user_app/core/providers/electrical_permit_provider.dart';
import 'package:ebpco_user_app/core/providers/electronics_permit_provider.dart';
import 'package:ebpco_user_app/core/providers/excavation_permit_provider.dart';
import 'package:ebpco_user_app/core/providers/fencing_permit_provider.dart';
import 'package:ebpco_user_app/core/providers/interior_design_permit_provider.dart';
import 'package:ebpco_user_app/core/providers/mechanical_permit_provider.dart';
import 'package:ebpco_user_app/core/providers/plumbing_permit_provider.dart';
import 'package:ebpco_user_app/core/providers/renovation_permit_provider.dart';
import 'package:ebpco_user_app/core/providers/sanitary_plumbing_permit_provider.dart';
import 'package:ebpco_user_app/core/providers/sign_permit_provider.dart';
import 'package:ebpco_user_app/features/applications/presentation/addition_extension_permit/addition_extension_permit_wizard_screen.dart';
import 'package:ebpco_user_app/features/applications/presentation/architectural_permit/architectural_permit_wizard_screen.dart';
import 'package:ebpco_user_app/features/applications/presentation/building_permit/building_permit_wizard_screen.dart';
import 'package:ebpco_user_app/features/applications/presentation/certificate_of_occupancy/certificate_of_occupancy_wizard_screen.dart';
import 'package:ebpco_user_app/features/applications/presentation/civil_structural_permit/civil_structural_permit_wizard_screen.dart';
import 'package:ebpco_user_app/features/applications/presentation/demolition_permit/demolition_permit_wizard_screen.dart';
import 'package:ebpco_user_app/features/applications/presentation/electrical_permit/electrical_permit_wizard_screen.dart';
import 'package:ebpco_user_app/features/applications/presentation/electronics_permit/electronics_permit_wizard_screen.dart';
import 'package:ebpco_user_app/features/applications/presentation/excavation_permit/excavation_permit_wizard_screen.dart';
import 'package:ebpco_user_app/features/applications/presentation/fencing_permit/fencing_permit_wizard_screen.dart';
import 'package:ebpco_user_app/features/applications/presentation/interior_design_permit/interior_design_permit_wizard_screen.dart';
import 'package:ebpco_user_app/features/applications/presentation/mechanical_permit/mechanical_permit_wizard_screen.dart';
import 'package:ebpco_user_app/features/applications/presentation/plumbing_permit/plumbing_permit_wizard_screen.dart';
import 'package:ebpco_user_app/features/applications/presentation/renovation_permit/renovation_permit_wizard_screen.dart';
import 'package:ebpco_user_app/features/applications/presentation/sanitary_plumbing_permit/sanitary_plumbing_permit_wizard_screen.dart';
import 'package:ebpco_user_app/features/applications/presentation/sign_permit/sign_permit_wizard_screen.dart';

import 'support/clipping.dart';

/// Command X4 names the nine-step wizards as the highest-risk surfaces for
/// large text, and until now not one of the sixteen was asserted at any text
/// scale. These open each at step 1 and check nothing bursts.
///
/// Step 1 only: driving each wizard to step 5 costs far more than it returns,
/// and the header, stepper, and progress row that step 1 exercises are the
/// parts every step shares.
///
/// Each entry builds its own correctly-typed provider. Registering them
/// through a shared `ChangeNotifier` supertype does not work — the wizard
/// looks up its concrete provider type and would not find it.
final Map<String, Widget Function()> _wizards = {
  'AdditionExtensionPermit': () =>
      ChangeNotifierProvider<AdditionExtensionPermitProvider>(
        create: (_) => AdditionExtensionPermitProvider(),
        child: const AdditionExtensionPermitWizardScreen(),
      ),
  'ArchitecturalPermit': () =>
      ChangeNotifierProvider<ArchitecturalPermitProvider>(
        create: (_) => ArchitecturalPermitProvider(),
        child: const ArchitecturalPermitWizardScreen(),
      ),
  'BuildingPermit': () => ChangeNotifierProvider<BuildingPermitProvider>(
    create: (_) => BuildingPermitProvider(),
    child: const BuildingPermitWizardScreen(),
  ),
  'CertificateOfOccupancy': () =>
      ChangeNotifierProvider<CertificateOfOccupancyProvider>(
        create: (_) => CertificateOfOccupancyProvider(),
        child: const CertificateOfOccupancyWizardScreen(),
      ),
  'CivilStructuralPermit': () =>
      ChangeNotifierProvider<CivilStructuralPermitProvider>(
        create: (_) => CivilStructuralPermitProvider(),
        child: const CivilStructuralPermitWizardScreen(),
      ),
  'DemolitionPermit': () => ChangeNotifierProvider<DemolitionPermitProvider>(
    create: (_) => DemolitionPermitProvider(),
    child: const DemolitionPermitWizardScreen(),
  ),
  'ElectricalPermit': () => ChangeNotifierProvider<ElectricalPermitProvider>(
    create: (_) => ElectricalPermitProvider(),
    child: const ElectricalPermitWizardScreen(),
  ),
  'ElectronicsPermit': () => ChangeNotifierProvider<ElectronicsPermitProvider>(
    create: (_) => ElectronicsPermitProvider(),
    child: const ElectronicsPermitWizardScreen(),
  ),
  'ExcavationPermit': () => ChangeNotifierProvider<ExcavationPermitProvider>(
    create: (_) => ExcavationPermitProvider(),
    child: const ExcavationPermitWizardScreen(),
  ),
  'FencingPermit': () => ChangeNotifierProvider<FencingPermitProvider>(
    create: (_) => FencingPermitProvider(),
    child: const FencingPermitWizardScreen(),
  ),
  'InteriorDesignPermit': () =>
      ChangeNotifierProvider<InteriorDesignPermitProvider>(
        create: (_) => InteriorDesignPermitProvider(),
        child: const InteriorDesignPermitWizardScreen(),
      ),
  'MechanicalPermit': () => ChangeNotifierProvider<MechanicalPermitProvider>(
    create: (_) => MechanicalPermitProvider(),
    child: const MechanicalPermitWizardScreen(),
  ),
  'PlumbingPermit': () => ChangeNotifierProvider<PlumbingPermitProvider>(
    create: (_) => PlumbingPermitProvider(),
    child: const PlumbingPermitWizardScreen(),
  ),
  'RenovationPermit': () => ChangeNotifierProvider<RenovationPermitProvider>(
    create: (_) => RenovationPermitProvider(),
    child: const RenovationPermitWizardScreen(),
  ),
  'SanitaryPlumbingPermit': () =>
      ChangeNotifierProvider<SanitaryPlumbingPermitProvider>(
        create: (_) => SanitaryPlumbingPermitProvider(),
        child: const SanitaryPlumbingPermitWizardScreen(),
      ),
  'SignPermit': () => ChangeNotifierProvider<SignPermitProvider>(
    create: (_) => SignPermitProvider(),
    child: const SignPermitWizardScreen(),
  ),
};

/// Most wizards pre-fill the applicant's details, so they need AuthProvider
/// above them as well as their own.
Widget _host(Widget Function() build, double textScale) => MultiProvider(
  providers: [
    ChangeNotifierProvider<AuthProvider>(create: (_) => AuthProvider()),
  ],
  child: MaterialApp(
    theme: AppTheme.lightTheme,
    home: MediaQuery(
      data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
      child: build(),
    ),
  ),
);

Future<void> _pump(
  WidgetTester tester,
  Widget Function() build, {
  required double textScale,
  double width = 360,
}) async {
  tester.view.physicalSize = Size(width, 900);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(_host(build, textScale));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('wizards open without overflowing at 100%', () {
    _wizards.forEach((name, build) {
      testWidgets(name, (tester) async {
        await _pump(tester, build, textScale: 1.0);
        expect(tester.takeException(), isNull);
      });
    });
  });

  group('wizards open without overflowing at 200% text scale', () {
    _wizards.forEach((name, build) {
      testWidgets(name, (tester) async {
        await _pump(tester, build, textScale: 2.0);
        expect(tester.takeException(), isNull);
      });
    });
  });

  group('wizard controls meet the 48dp floor', () {
    _wizards.forEach((name, build) {
      testWidgets(name, (tester) async {
        await _pump(tester, build, textScale: 1.0);

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

  group('no wizard text is cut off', () {
    // Distinct from the overflow groups above. A box that pins its height, a
    // ClipRect, a Stack — none of them report an overflow when their text
    // outgrows them; the text just stops rendering. That is how the bottom
    // navigation bar clipped "Applications" on every screen while three
    // scales of render tests passed.
    for (final scale in [1.0, 2.0]) {
      _wizards.forEach((name, build) {
        testWidgets('$name at ${scale}x', (tester) async {
          await _pump(tester, build, textScale: scale);
          expectNoClippedText(tester, context: name);
        });
      });
    }
  });
}
