import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ebpco_user_app/core/constants/app_strings.dart';
import 'package:ebpco_user_app/core/providers/application_intent_provider.dart';
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
import 'package:ebpco_user_app/core/contract/admin_vocabulary.dart';
import 'package:ebpco_user_app/routes/wizard_routes.dart';

import 'support/clipping.dart';
import 'support/wizard_providers.dart';

/// The 38 screens the accessibility suite never reached.
///
/// `accessibility_routes_test.dart` covers 34 screens by constructing them
/// directly. The nineteen permit wizards and their nineteen confirmation
/// screens were outside it — half the app's screens, and the half an applicant
/// spends the most time in.
///
/// They are driven **through the router** rather than constructed, for two
/// reasons. Nineteen confirmation screens have nineteen different constructors
/// (one to five required arguments each), while the router builds every one of
/// them from a single `extra` map — so this stays one list instead of nineteen
/// bespoke entries that would rot independently. And it is what production
/// does: a wizard reached by tapping the catalog goes through exactly this
/// path.
///
/// Every case asserts the screen is actually rendered before measuring it. An
/// empty state cannot overflow and cannot clip, and this suite has already been
/// caught measuring three of them.

/// Everything any confirmation route reads, in one map. A screen ignores what
/// it does not need, so one map serves all nineteen — and passing values means
/// each renders its populated layout rather than its `?? 'UNKNOWN'` fallbacks,
/// which are shorter and would hide a clipping defect.
final _extra = <String, Object?>{
  'referenceNumber': 'E-BPCO-2026-000145',
  'applicationId': 'app-seed-1',
  'submissionDate': DateTime(2026, 8, 29),
  'relatedBuildingPermitNumber': 'BP-2026-000145',
  'relatedBuildingPermitStatus': 'Approved and released',
  'buildingPermitNumber': 'BP-2026-000145',
  'certificateType': 'New Certificate of Occupancy',
  'electricalContractorRequired': true,
};

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
    ChangeNotifierProvider<ApplicationIntentProvider>(
      create: (_) => ApplicationIntentProvider(),
    ),
    ...wizardProviders(),
  ],
  child: MaterialApp.router(theme: AppTheme.lightTheme, routerConfig: router),
);

Future<void> _open(
  WidgetTester tester,
  String path, {
  required double textScale,
  Object? extra,
}) async {
  tester.view.physicalSize = const Size(360, 3000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final auth = AuthProvider();
  final router = AppRouter.build(auth);

  await tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
      child: _app(auth, router),
    ),
  );
  await tester.pump();

  // The router redirects everything to /splash until a session exists, so
  // without this the whole sweep measures the splash screen thirty-eight
  // times. The sign-in is pumped rather than awaited: the mock repository
  // answers after a Future.delayed, and awaiting one inside testWidgets
  // without advancing the clock hangs for ever.
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

  router.go(path, extra: extra);
  await tester.pump();
  await tester.pump(const Duration(seconds: 2));

  expect(
    router.routerDelegate.currentConfiguration.uri.path,
    path,
    reason: 'never arrived at $path, so nothing below measures it',
  );
}

/// Proof the screen rendered, before anything is concluded from it not
/// overflowing.
void _expectRendered(WidgetTester tester, String label) {
  final strings = find
      .byType(Text)
      .evaluate()
      .map((e) => (e.widget as Text).data)
      .whereType<String>()
      .where((t) => t.trim().isNotEmpty)
      .length;
  expect(
    strings,
    greaterThan(3),
    reason:
        '$label rendered only $strings strings — still loading, or an '
        'empty state, in which case it cannot clip and proves nothing',
  );
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  final wizards = permitWizardRoutes.map(
    (type, route) => MapEntry(type.wire, route),
  );

  group('the nineteen permit wizards', () {
    for (final entry in wizards.entries) {
      for (final scale in [1.0, 2.0]) {
        testWidgets('${entry.key} at ${scale}x', (tester) async {
          await _open(tester, entry.value, textScale: scale);
          _expectRendered(tester, entry.key);
          expect(tester.takeException(), isNull);
          expectNoClippedText(tester, context: '${entry.key} @$scale');
        });
      }
    }
  });

  group('the nineteen confirmation screens', () {
    for (final entry in wizards.entries) {
      for (final scale in [1.0, 2.0]) {
        testWidgets('${entry.key} submitted at ${scale}x', (tester) async {
          final path = '${entry.value}/submitted';
          await _open(tester, path, textScale: scale, extra: _extra);
          _expectRendered(tester, '${entry.key} submitted');
          expect(tester.takeException(), isNull);
          expectNoClippedText(
            tester,
            context: '${entry.key} submitted @$scale',
          );
        });
      }
    }
  });
}
