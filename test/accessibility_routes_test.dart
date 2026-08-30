import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ebpco_user_app/core/models/money.dart';
import 'package:ebpco_user_app/core/constants/app_constants.dart';
import 'package:ebpco_user_app/core/models/application_detail.dart';
import 'package:ebpco_user_app/core/models/application_lineage.dart';
import 'package:ebpco_user_app/core/models/application_model.dart';
import 'package:ebpco_user_app/core/models/document_model.dart';
import 'package:ebpco_user_app/core/models/lifecycle_status.dart';
import 'package:ebpco_user_app/core/models/payment_assessment_model.dart';
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
import 'package:ebpco_user_app/features/applications/presentation/continuation/continue_application_screen.dart';
import 'package:ebpco_user_app/features/documents/presentation/official_form_screen.dart';
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
  // Added 29 August. Both were built this week and neither was in an
  // accessibility suite — the same debt this sweep exists to stop
  // accumulating, and the suite has already caught two real overflows
  // in this week's own work.
  'OfficialForm': () => const OfficialFormScreen(
    permitType: 'Building Permit – New Construction',
  ),
  'OfficialFormChecklist': () => const OfficialFormScreen(
    permitType: 'Building Permit – New Construction',
    checklist: true,
  ),
  // The reference-only variant renders an extra caveat panel that the
  // official one does not, so it is a different layout.
  'OfficialFormReference': () =>
      const OfficialFormScreen(permitType: 'Architectural Permit'),
  'RenewPermit': () => const ContinueApplicationScreen(
    applicationId: 'app-seed-1',
    kind: ContinuationKind.renewal,
  ),
  'AmendApplication': () => const ContinueApplicationScreen(
    applicationId: 'app-seed-1',
    kind: ContinuationKind.amendment,
  ),
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
          repository: _RichApplications(),
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

/// An application rich enough that the screens under test render their REAL
/// layouts.
///
/// The seeded `MockApplicationsRepository` application carries no permit, so
/// `DigitalPermitScreen` rendered "No permit yet" and the renewal screen
/// rendered "No permit to renew yet" — both empty states. Measuring text
/// clipping on an empty state proves nothing about the screen that ships, and
/// this suite was doing exactly that until 29 August.
class _RichApplications implements ApplicationsRepository {
  static final _issued = DateTime(2026, 4, 1);

  static final ApplicationModel application = ApplicationModel(
    id: 'app-seed-1',
    applicationNumber: 'E-BPCO-2026-000145',
    businessId: 'biz-seed-1',
    businessName: 'Dela Cruz Construction and Supply Corporation',
    type: ApplicationType.newPermit,
    status: ApplicationStatus.released,
    submittedDate: DateTime(2026, 1, 5),
    lifecycleStatus: ApplicationLifecycleStatus.released,
    permitTypeLabel: 'Fencing Permit',
    permitNumber: 'BP-2026-000145',
    issuedDate: _issued,
    permit: GeneratedPermit(
      permitNumber: 'BP-2026-000145',
      issuedDate: _issued,
      scope: 'Perimeter fence, 42 linear metres, concrete hollow block',
    ),
  );

  @override
  Future<List<ApplicationModel>> fetchAll() async => [application];

  @override
  Future<ApplicationModel> submitApplication({
    required String businessId,
    required String businessName,
    required ApplicationType type,
    required List<DocumentModel> documents,
    String? permitTypeLabel,
    String? applicationNumber,
    ApplicationLineage? lineage,
  }) => throw UnimplementedError();

  @override
  Future<ApplicationModel> attachPayment(
    String applicationId, {
    required PaymentMethod method,
    required String referenceNumber,
    required DateTime paidOn,
    PesoAmount? amountPaid,
    DocumentModel? proof,
  }) => throw UnimplementedError();

  @override
  Future<ApplicationModel> resubmitDocument(
    String applicationId, {
    required String documentId,
    required DocumentModel replacement,
  }) => throw UnimplementedError();

  @override
  Future<ApplicationModel> advanceStatus(String applicationId) =>
      throw UnimplementedError();
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    // Without this the bundle and cache-directory channels never answer, the
    // screen stays in its loading state, and this suite measures an AppBar
    // with an empty body.
    debugOfficialFormResolver = (assetPath) async => '/tmp/$assetPath';
  });
  tearDown(() => debugOfficialFormResolver = null);

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

  group('the suite is measuring the real screen, not an empty state', () {
    // Added 29 August, after finding this suite had been measuring empty
    // states without noticing. `DigitalPermitScreen` rendered "No permit yet"
    // and the renewal screen rendered "No permit to renew yet", because the
    // seeded application carried no permit; `OfficialFormScreen` rendered an
    // AppBar and an empty body, because its platform channels never answered
    // and it stayed in its loading state.
    //
    // An empty state cannot overflow and cannot clip. Every assertion in the
    // groups below passed on all three, and proved nothing about the layouts
    // that ship.

    const emptyStateTitles = [
      'No permit yet',
      'No permit to renew yet',
      'Application not found',
      'No form for this permit',
      'No checklist for this permit',
      'Form could not be opened',
      'Not available for this permit',
    ];

    _screens.forEach((name, screen) {
      testWidgets('$name renders content, not a placeholder', (tester) async {
        await _open(tester, screen, textScale: 1.0);

        for (final title in emptyStateTitles) {
          expect(
            find.text(title),
            findsNothing,
            reason:
                '$name fell back to "$title", so every accessibility '
                'assertion about it is vacuous. Give the fixture what the '
                'screen needs rather than deleting this check.',
          );
        }

        // A screen showing almost nothing is the same problem wearing a
        // different shape — a bare AppBar clips and overflows just as little.
        final rendered = find
            .byType(Text)
            .evaluate()
            .map((e) => (e.widget as Text).data)
            .whereType<String>()
            .where((t) => t.trim().isNotEmpty)
            .length;
        expect(
          rendered,
          greaterThan(2),
          reason:
              '$name rendered only $rendered strings — is it still loading?',
        );
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
