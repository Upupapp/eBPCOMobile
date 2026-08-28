import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ebpco_user_app/core/constants/app_constants.dart';
import 'package:ebpco_user_app/core/providers/applications_provider.dart';
import 'package:ebpco_user_app/core/providers/auth_provider.dart';
import 'package:ebpco_user_app/core/providers/contact_verification_provider.dart';
import 'package:ebpco_user_app/core/repositories/contact_verification_repository.dart';
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

import 'package:ebpco_user_app/features/applications/presentation/applications_screen.dart';
import 'package:ebpco_user_app/features/applications/presentation/detail/application_outcome_screen.dart';
import 'package:ebpco_user_app/features/applications/presentation/detail/digital_permit_screen.dart';
import 'package:ebpco_user_app/features/applications/presentation/detail/letter_of_instruction_screen.dart';
import 'package:ebpco_user_app/features/applications/presentation/new_application_screen.dart';
import 'package:ebpco_user_app/features/authentication/presentation/forgot_password_screen.dart';
import 'package:ebpco_user_app/features/authentication/presentation/login_screen.dart';
import 'package:ebpco_user_app/features/authentication/presentation/register_screen.dart';
import 'package:ebpco_user_app/features/authentication/presentation/registration_success_screen.dart';
import 'package:ebpco_user_app/features/business/presentation/business_details_screen.dart';
import 'package:ebpco_user_app/features/business/presentation/business_list_screen.dart';
import 'package:ebpco_user_app/features/business/presentation/register_business_screen.dart';
import 'package:ebpco_user_app/features/documents/presentation/my_documents_screen.dart';
import 'package:ebpco_user_app/features/onboarding/presentation/onboarding_screen.dart';
import 'package:ebpco_user_app/features/payments/presentation/payments_screen.dart';
import 'package:ebpco_user_app/features/profile/presentation/change_password_screen.dart';
import 'package:ebpco_user_app/features/profile/presentation/contact_verification_screen.dart';
import 'package:ebpco_user_app/features/profile/presentation/edit_profile_screen.dart';
import 'package:ebpco_user_app/features/profile/presentation/help_support_screen.dart';
import 'package:ebpco_user_app/features/profile/presentation/language_screen.dart';
import 'package:ebpco_user_app/features/profile/presentation/notification_preferences_screen.dart';
import 'package:ebpco_user_app/features/profile/presentation/privacy_policy_screen.dart';
import 'package:ebpco_user_app/features/profile/presentation/profile_screen.dart';
import 'package:ebpco_user_app/features/profile/presentation/terms_conditions_screen.dart';

import 'support/clipping.dart';

/// The rest of the routable app. `accessibility_screens_test.dart` took the
/// seven the second sweep named; this takes the twenty-three that were left.
///
/// Where that suite hand-built its fixtures, this one runs the app's own mock
/// repositories and real providers — the same objects `app.dart` wires up. The
/// pill defects the last pass found were latent precisely because a hand-made
/// fixture was shorter than the seed data a user actually sees, so here the
/// data is the seed data.

/// Builders rather than instances: each test gets a fresh widget, and
/// `ProfileScreen` has no const constructor.
final _screens = <String, Widget Function()>{
  // Authentication and first run
  'Login': () => LoginScreen(),
  'Register': () => RegisterScreen(),
  'ForgotPassword': () => ForgotPasswordScreen(),
  'RegistrationSuccess': () => RegistrationSuccessScreen(),
  'Onboarding': () => OnboardingScreen(),

  // Applications
  'Applications': () => ApplicationsScreen(),
  'NewApplication': () => NewApplicationScreen(),
  'LetterOfInstruction': () =>
      LetterOfInstructionScreen(applicationId: 'app-seed-1'),
  'DigitalPermit': () => DigitalPermitScreen(applicationId: 'app-seed-1'),
  'ApplicationOutcome': () =>
      ApplicationOutcomeScreen(applicationId: 'app-seed-1'),

  // Business
  'BusinessList': () => BusinessListScreen(),
  'BusinessDetails': () => BusinessDetailsScreen(businessId: 'biz-seed-1'),
  'RegisterBusiness': () => RegisterBusinessScreen(),

  // Documents and payments
  'MyDocuments': () => MyDocumentsScreen(),
  'Payments': () => PaymentsScreen(),

  // Profile and settings
  'Profile': () => ProfileScreen(),
  'EditProfile': () => EditProfileScreen(),
  'ChangePassword': () => ChangePasswordScreen(),
  'NotificationPreferences': () => NotificationPreferencesScreen(),
  'Language': () => LanguageScreen(),
  'HelpSupport': () => HelpSupportScreen(),
  'ContactVerification': () => const ContactVerificationScreen(),
  'PrivacyPolicy': () => PrivacyPolicyScreen(),
  'TermsConditions': () => TermsConditionsScreen(),
};

Widget _host(Widget Function() build, double textScale) {
  final router = GoRouter(
    initialLocation: '/subject',
    routes: [
      GoRoute(path: '/subject', builder: (_, _) => build()),
      // Everything a subject screen might navigate to. None of these are
      // entered; they exist so a `context.push` target resolves.
      GoRoute(path: '/:a', builder: (_, _) => const Scaffold()),
      GoRoute(path: '/:a/:b', builder: (_, _) => const Scaffold()),
      GoRoute(path: '/:a/:b/:c', builder: (_, _) => const Scaffold()),
    ],
  );

  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AuthProvider>(create: (_) => AuthProvider()),
      ChangeNotifierProvider<NavigationProvider>(
        create: (_) => NavigationProvider(),
      ),
      // The Profile screen shows a verification badge beside the email
      // address and the mobile number.
      ChangeNotifierProvider<ContactVerificationProvider>(
        create: (_) => ContactVerificationProvider(
          repository: MockContactVerificationRepository(),
        ),
      ),
      ChangeNotifierProvider<SettingsProvider>(
        create: (_) => SettingsProvider(),
      ),
      ChangeNotifierProvider<NotificationsProvider>(
        create: (_) =>
            NotificationsProvider(repository: MockNotificationsRepository()),
      ),
      ChangeNotifierProvider<BusinessProvider>(
        create: (context) => BusinessProvider(
          notifications: context.read<NotificationsProvider>(),
          repository: MockBusinessRepository(),
        ),
      ),
      ChangeNotifierProvider<ApplicationsProvider>(
        create: (context) => ApplicationsProvider(
          notifications: context.read<NotificationsProvider>(),
          repository: MockApplicationsRepository(),
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
  // The mock repositories answer after a delay, and several screens debounce.
  // `pumpAndSettle` does not drain either.
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

  group('no text is cut off', () {
    // Distinct from the overflow groups above. A box that pins its height, a
    // ClipRect, a Stack — none of them report an overflow when their text
    // outgrows them; the text just stops rendering. That is how the bottom
    // navigation bar clipped "Applications" on every screen while three
    // scales of render tests passed.
    for (final scale in [1.0, 2.0]) {
      _screens.forEach((name, screen) {
        testWidgets('$name at ${scale}x', (tester) async {
          await _open(tester, screen, textScale: scale);
          expectNoClippedText(tester, context: name);
        });
      });
    }
  });
}
