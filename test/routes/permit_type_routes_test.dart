import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ebpco_user_app/core/constants/app_strings.dart';
import 'package:ebpco_user_app/core/contract/admin_vocabulary.dart';
import 'package:ebpco_user_app/core/providers/applications_provider.dart';
import 'package:ebpco_user_app/core/providers/auth_provider.dart';
import 'package:ebpco_user_app/core/providers/business_provider.dart';
import 'package:ebpco_user_app/core/providers/documents_provider.dart';
import 'package:ebpco_user_app/core/providers/navigation_provider.dart';
import 'package:ebpco_user_app/core/providers/notifications_provider.dart';
import 'package:ebpco_user_app/core/providers/professionals_provider.dart';
import 'package:ebpco_user_app/core/providers/settings_provider.dart';
import 'package:ebpco_user_app/core/repositories/applications_repository.dart';
import 'package:ebpco_user_app/core/repositories/business_repository.dart';
import 'package:ebpco_user_app/core/repositories/notifications_repository.dart';
import 'package:ebpco_user_app/core/theme/app_theme.dart';
import 'package:ebpco_user_app/features/documents/presentation/official_form_screen.dart';
import 'package:ebpco_user_app/routes/app_router.dart';

import '../support/wizard_providers.dart';

/// The two routes that carry a permit type in the path, for all nineteen
/// types.
///
/// This exists because one of them was broken and nothing said so. The charter
/// route decoded `state.pathParameters` a second time, and `pathParameters`
/// arrives decoded — so `Uri.decodeComponent` was handed a string that was no
/// longer a URI component. For sixteen types that is a harmless no-op. The
/// three Building Permit sub-types carry an EN DASH (U+2013) in their names,
/// which is not legal in a URI component, and decoding threw
/// "Illegal percent encoding in URI" inside the route builder.
///
/// The applicant's route to it: pre-flight → "View the Citizen's Charter", on
/// the app's three most common filings.
///
/// The existing cold-entry sweep did not catch it because it visits
/// `/charter/building-permit` — a slug the app never actually produces. A
/// route parameterised by real data has to be tested with real data.

Widget _app(AuthProvider auth, GoRouter router) => MultiProvider(
  providers: [
    ChangeNotifierProvider<AuthProvider>.value(value: auth),
    ChangeNotifierProvider<NavigationProvider>(
      create: (_) => NavigationProvider(),
    ),
    ChangeNotifierProvider<SettingsProvider>(create: (_) => SettingsProvider()),
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
    ChangeNotifierProvider<BusinessProvider>(
      create: (context) => BusinessProvider(
        notifications: context.read<NotificationsProvider>(),
        repository: MockBusinessRepository(),
      ),
    ),
    ChangeNotifierProvider<DocumentsProvider>(
      create: (_) => DocumentsProvider(),
    ),
    ChangeNotifierProvider<ProfessionalsProvider>(
      create: (context) => ProfessionalsProvider(
        notifications: context.read<NotificationsProvider>(),
      ),
    ),
    ...wizardProviders(),
  ],
  child: MaterialApp.router(theme: AppTheme.lightTheme, routerConfig: router),
);

Future<GoRouter> _signedIn(WidgetTester tester) async {
  tester.view.physicalSize = const Size(400, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final auth = AuthProvider();
  final router = AppRouter.build(auth);
  await tester.pumpWidget(_app(auth, router));
  await tester.pump();

  await auth.loadSession();
  await auth.completeOnboarding();
  final signIn = auth.login(
    email: AppStrings.mockEmail,
    password: AppStrings.mockPassword,
    rememberMe: false,
  );
  await tester.pump(const Duration(seconds: 2));
  await signIn;
  await tester.pump();
  await tester.pump(const Duration(seconds: 2));
  expect(auth.isLoggedIn, isTrue);
  return router;
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    // The bundle and the cache directory are both platform channels with no
    // answer under `flutter test`; the screen's own resolver is the seam.
    debugOfficialFormResolver = (assetPath) async => '/dev/null/$assetPath';
  });
  tearDown(() => debugOfficialFormResolver = null);

  for (final type in CanonicalPermitType.values) {
    final encoded = Uri.encodeComponent(type.wire);

    testWidgets('charter opens for ${type.wire}', (tester) async {
      final router = await _signedIn(tester);
      router.go('/charter/$encoded');
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));

      expect(
        tester.takeException(),
        isNull,
        reason: 'the charter for ${type.wire} threw',
      );
      expect(find.text('Citizen\u2019s Charter'), findsWidgets);
    });

    testWidgets('the official form opens for ${type.wire}', (tester) async {
      final router = await _signedIn(tester);
      router.go('/forms/$encoded');
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));

      expect(
        tester.takeException(),
        isNull,
        reason: 'the form route for ${type.wire} threw',
      );
      expect(find.text('Official form'), findsOneWidget);
      // Every type has a bundled form, so none of them should reach the
      // "no form" state. If the admin ever drops one, this is where it shows.
      expect(find.text('No form for this permit'), findsNothing);
    });
  }

  testWidgets('the checklist route resolves separately from the form', (
    tester,
  ) async {
    final router = await _signedIn(tester);
    final encoded = Uri.encodeComponent(
      CanonicalPermitType.buildingPermitNewConstruction.wire,
    );
    router.go('/forms/$encoded/checklist');
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));

    expect(tester.takeException(), isNull);
    expect(find.text('Requirements checklist'), findsOneWidget);
    expect(find.text('No checklist for this permit'), findsNothing);
  });

  testWidgets('a type with no checklist says so rather than showing nothing', (
    tester,
  ) async {
    final router = await _signedIn(tester);
    router.go('/forms/${Uri.encodeComponent('Fencing Permit')}/checklist');
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));

    expect(tester.takeException(), isNull);
    expect(find.text('No checklist for this permit'), findsOneWidget);
  });

  testWidgets('an unknown permit type does not crash the form route', (
    tester,
  ) async {
    final router = await _signedIn(tester);
    router.go('/forms/${Uri.encodeComponent('Business Permit')}');
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));

    expect(tester.takeException(), isNull);
    expect(find.text('No form for this permit'), findsOneWidget);
  });
}
