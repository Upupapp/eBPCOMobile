import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ebpco_user_app/core/constants/app_strings.dart';
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
import 'package:ebpco_user_app/routes/app_router.dart';

import '../support/wizard_providers.dart';

/// Every route, entered cold.
///
/// A route is normally reached by tapping through the app, which hands it
/// `extra` — a reference number, a submission date, a draft. It can also be
/// reached with none of that: from a notification, a restored session, a deep
/// link, or the router rebuilding after a hot restart. Nothing had ever
/// checked what happens then, and the fifteen confirmation screens each read
/// four or five values out of `extra`.
///
/// Path parameters get ids that do not exist, which is the realistic failure —
/// a notification about an application the server has since dropped, or a link
/// shared from another account.

/// Routes a signed-in applicant can reach. The auth routes are not among
/// them: the router deliberately bounces a signed-in user off /login and
/// friends to /app/home, which is correct and is asserted separately below.
const _paths = <String>[
  '/business',
  '/business/register',
  '/business/does-not-exist',
  '/applications/new',
  '/applications/pre-flight',
  '/applications/new/business-permit',
  '/applications/new/building-permit/submitted',
  '/applications/new/renovation-permit/submitted',
  '/applications/new/addition-extension-permit/submitted',
  '/applications/new/demolition-permit/submitted',
  '/applications/new/architectural-permit/submitted',
  '/applications/new/civil-structural-permit/submitted',
  '/applications/new/electrical-permit/submitted',
  '/applications/new/mechanical-permit/submitted',
  '/applications/new/electronics-permit/submitted',
  '/applications/new/interior-design-permit/submitted',
  '/applications/new/fencing-permit/submitted',
  '/applications/new/sign-permit/submitted',
  '/applications/new/excavation-permit/submitted',
  '/applications/new/certificate-of-occupancy/submitted',
  '/applications/new/plumbing-permit/submitted',
  '/applications/new/sanitary-plumbing-permit/submitted',
  '/applications/does-not-exist',
  '/applications/does-not-exist/instructions',
  '/applications/does-not-exist/permit',
  '/applications/does-not-exist/outcome',
  '/applications/does-not-exist/pay',
  '/payments/history',
  '/profile/edit',
  '/profile/change-password',
  '/profile/documents',
  '/profile/language',
  '/profile/notifications',
  '/profile/help',
  '/profile/terms',
  '/profile/professionals',
  '/profile/privacy-data',
  '/profile/privacy',
  '/charter/building-permit',
  '/forms/Fencing%20Permit',
  '/forms/Fencing%20Permit/checklist',
  '/app/home',
  '/app/applications',
  '/app/payments',
  '/app/profile',
  '/app/notifications',
];

Widget _app(AuthProvider auth, GoRouter router) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AuthProvider>.value(value: auth),
      ChangeNotifierProvider<NavigationProvider>(
        create: (_) => NavigationProvider(),
      ),
      ChangeNotifierProvider<SettingsProvider>(
        create: (_) => SettingsProvider(),
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
}

/// Routes reachable only before signing in — onboarding done, no session.
const _preAuthPaths = <String>[
  '/login',
  '/register',
  '/forgot-password',
  '/registration-success',
];

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  for (final path in _paths) {
    testWidgets('$path renders with no extra', (tester) async {
      tester.view.physicalSize = const Size(400, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final auth = AuthProvider();
      final router = AppRouter.build(auth);

      // Mounted first, then signed in. The router redirects every location to
      // /splash while AuthStatus is unknown, so without a session the whole
      // sweep renders the splash screen fifty times and passes no matter what
      // is behind those routes.
      //
      // The sign-in has to be pumped rather than plainly awaited: the mock
      // repository answers after a Future.delayed, and awaiting one inside
      // testWidgets without advancing the test clock hangs for ever.
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

      expect(auth.isLoggedIn, isTrue, reason: 'the sweep needs a session');

      router.go(path);
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));

      // Assert we actually arrived. A redirect back to /splash or /login would
      // otherwise make every case below pass without rendering the screen.
      final landed = router.routerDelegate.currentConfiguration.uri.path;
      expect(
        landed,
        path,
        reason: 'expected to land on $path, ended on $landed',
      );

      expect(
        tester.takeException(),
        isNull,
        reason: '$path threw when entered without extra',
      );
    });
  }
  for (final path in _preAuthPaths) {
    testWidgets('$path renders for a signed-out applicant', (tester) async {
      tester.view.physicalSize = const Size(400, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final auth = AuthProvider();
      final router = AppRouter.build(auth);
      await tester.pumpWidget(_app(auth, router));
      await tester.pump();

      // Onboarding done, but no session — the state the sign-in screens exist
      // for. Without completing onboarding the router sends everything to
      // /onboarding instead.
      await auth.loadSession();
      await auth.completeOnboarding();
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));

      router.go(path);
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));

      expect(
        router.routerDelegate.currentConfiguration.uri.path,
        path,
        reason: '$path should be reachable when signed out',
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('a signed-in applicant is kept out of the sign-in screens', (
    tester,
  ) async {
    // The other half of the contract, and the reason the auth routes are not
    // in the main sweep: a session should send them to the app, not the login
    // form. Asserted rather than assumed, because it is also what made an
    // earlier version of this sweep vacuous.
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

    for (final path in [..._preAuthPaths, '/splash', '/onboarding']) {
      router.go(path);
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
      expect(
        router.routerDelegate.currentConfiguration.uri.path,
        '/app/home',
        reason: '$path should redirect a signed-in applicant to the app',
      );
    }
  });
}
