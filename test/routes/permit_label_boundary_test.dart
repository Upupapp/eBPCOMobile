import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ebpco_user_app/core/constants/app_strings.dart';
import 'package:ebpco_user_app/core/contract/admin_vocabulary.dart';
import 'package:ebpco_user_app/core/models/citizens_charter.dart';
import 'package:ebpco_user_app/core/providers/applications_provider.dart';
import 'package:ebpco_user_app/core/providers/auth_provider.dart';
import 'package:ebpco_user_app/core/providers/business_provider.dart';
import 'package:ebpco_user_app/core/providers/contact_verification_provider.dart';
import 'package:ebpco_user_app/core/providers/documents_provider.dart';
import 'package:ebpco_user_app/core/providers/navigation_provider.dart';
import 'package:ebpco_user_app/core/providers/notifications_provider.dart';
import 'package:ebpco_user_app/core/providers/professionals_provider.dart';
import 'package:ebpco_user_app/core/providers/settings_provider.dart';
import 'package:ebpco_user_app/core/repositories/applications_repository.dart';
import 'package:ebpco_user_app/core/repositories/business_repository.dart';
import 'package:ebpco_user_app/core/repositories/contact_verification_repository.dart';
import 'package:ebpco_user_app/core/repositories/notifications_repository.dart';
import 'package:ebpco_user_app/core/theme/app_theme.dart';
import 'package:ebpco_user_app/routes/app_router.dart';

import '../support/wizard_providers.dart';

/// Permit-type labels crossing a route boundary.
///
/// Sibling of `permit_type_routes_test.dart`, which was written after the
/// charter route double-decoded its path parameter and died on the app's three
/// most common filings. This covers the rest of that class: a label that
/// arrives in a form the destination does not recognise.
///
/// It is a quieter failure than the decode one and a worse one. A decode
/// throws. A wrong label **resolves** — `charterFor` falls through to a
/// generic ancillary entry, and the applicant is shown a real-looking charter
/// for a different service. That is what the Profile screen was doing: it
/// linked to 'New Construction', the catalog card's short name, while the
/// charter is keyed on the office's own 'Building Permit – New Construction'.
/// The generic entry pledges **7 working days** against the Building Permit's
/// **20**, and under RA 11032 that number is the published service standard an
/// applicant holds the office to.

Widget _app(AuthProvider auth, GoRouter router) => MultiProvider(
  providers: [
    ChangeNotifierProvider<AuthProvider>.value(value: auth),
    ChangeNotifierProvider<NavigationProvider>(
      create: (_) => NavigationProvider(),
    ),
    ChangeNotifierProvider<SettingsProvider>(create: (_) => SettingsProvider()),
    ChangeNotifierProvider<ContactVerificationProvider>(
      create: (_) => ContactVerificationProvider(
        repository: MockContactVerificationRepository(),
      ),
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

Future<GoRouter> _signedIn(WidgetTester tester) async {
  tester.view.physicalSize = const Size(400, 3000);
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
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('the charter an applicant is actually shown', () {
    testWidgets('Profile opens the Building Permit charter, not the generic', (
      tester,
    ) async {
      final router = await _signedIn(tester);
      router.go('/app/profile');
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));

      await tester.tap(find.text('Citizen’s Charter'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));

      // 20, the Building Official's own pledge. 7 is the generic ancillary
      // entry, and the number the app quoted before this was fixed.
      // The charter heads its pledge with the classification, so the day
      // count is asserted by containment rather than by an exact string.
      expect(
        find.textContaining('20 working days'),
        findsOneWidget,
        reason:
            'the Profile charter link resolved to the generic entry, quoting '
            'a service standard for a different service',
      );
      expect(find.textContaining('7 working days'), findsNothing);
      // And it is the right permit, not merely the right number.
      expect(
        find.text(CanonicalPermitType.buildingPermitNewConstruction.wire),
        findsWidgets,
      );
    });

    test(
      'the two entries really do differ, or the test above proves nothing',
      () {
        // Guards the guard. If the generic entry ever moves to 20 days this
        // assertion goes off, rather than the test above passing vacuously.
        final generic = charterFor('New Construction');
        final real = charterFor(
          CanonicalPermitType.buildingPermitNewConstruction.wire,
        );
        expect(generic.pledgedWorkingDays, 7);
        expect(real.pledgedWorkingDays, 20);
      },
    );
  });

  group('labels carried as query parameters', () {
    // The catalog reaches every wizard through `/applications/pre-flight`
    // with the permit type in the query string. Never tested with a real
    // permit type: the cold-entry sweep visits the bare path.
    for (final type in CanonicalPermitType.values) {
      testWidgets('pre-flight receives ${type.wire} intact', (tester) async {
        final router = await _signedIn(tester);
        router.go(
          '/applications/pre-flight'
          '?permitType=${Uri.encodeQueryComponent(type.wire)}'
          '&next=${Uri.encodeQueryComponent('/applications/new')}',
        );
        await tester.pump();
        await tester.pump(const Duration(seconds: 2));

        expect(tester.takeException(), isNull);
        // The screen prints the label it received. If the query string mangled
        // it — the EN DASH, the slashes, the `+`-for-space rule — this is
        // where it shows.
        expect(
          find.text(type.wire),
          findsOneWidget,
          reason: '${type.wire} did not survive the query string',
        );
      });
    }
  });

  test('no screen builds a permit-type route from a non-canonical literal', () {
    // A source scan, and it knows it: it cannot see a label that is computed
    // rather than written. It exists to catch the specific mistake that has
    // now happened twice — someone reaching for the catalog card's short
    // display name because that is what is on screen in front of them.
    final canonical = CanonicalPermitType.values.map((t) => t.wire).toSet();
    final offenders = <String>[];

    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final source = entity.readAsStringSync();
      for (final match in RegExp(
        r"/(charter|forms)/\$\{Uri\.encodeComponent\('([^']*)'\)\}",
      ).allMatches(source)) {
        final literal = match.group(2)!;
        if (!canonical.contains(literal)) {
          offenders.add('${entity.path}: "$literal"');
        }
      }
    }

    expect(
      offenders,
      isEmpty,
      reason:
          'these build a permit-type route from a name the lookups do not '
          'know, and will resolve to a generic entry rather than fail: '
          '$offenders',
    );
  });
}
