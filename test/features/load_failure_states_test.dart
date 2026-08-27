import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ebpco_user_app/core/models/application_model.dart';
import 'package:ebpco_user_app/core/models/business_model.dart';
import 'package:ebpco_user_app/core/models/document_model.dart';
import 'package:ebpco_user_app/core/models/notification_event.dart';
import 'package:ebpco_user_app/core/models/payment_assessment_model.dart';
import 'package:ebpco_user_app/core/providers/applications_provider.dart';
import 'package:ebpco_user_app/core/providers/business_provider.dart';
import 'package:ebpco_user_app/core/providers/notifications_provider.dart';
import 'package:ebpco_user_app/core/repositories/applications_repository.dart';
import 'package:ebpco_user_app/core/repositories/business_repository.dart';
import 'package:ebpco_user_app/core/repositories/notifications_repository.dart';
import 'package:ebpco_user_app/core/theme/app_theme.dart';
import 'package:ebpco_user_app/features/applications/presentation/application_list_screen.dart';
import 'package:ebpco_user_app/features/business/presentation/business_list_screen.dart';
import 'package:ebpco_user_app/features/notifications/presentation/notifications_screen.dart';
import 'package:ebpco_user_app/shared/widgets/states/load_failure_state.dart';

import '../support/wizard_providers.dart';

/// A list that could not load is not a list that is empty.
///
/// Every list screen branched `isLoading ? spinner : isEmpty ? empty : list`,
/// with no branch for failure. Once the providers stopped hanging on a thrown
/// fetch, that fell straight through to the empty state — so a timed-out
/// request produced "You have no applications yet", a confident and false
/// statement about the applicant's own filings.

class _Offline implements Exception {}

class _ThrowingApplications implements ApplicationsRepository {
  @override
  Future<List<ApplicationModel>> fetchAll() async => throw _Offline();
  @override
  Future<ApplicationModel> submitApplication({
    required String businessId,
    required String businessName,
    required ApplicationType type,
    required List<DocumentModel> documents,
    String? permitTypeLabel,
    String? applicationNumber,
  }) async => throw _Offline();
  @override
  Future<ApplicationModel> attachPayment(
    String applicationId, {
    required PaymentMethod method,
    DocumentModel? proof,
  }) async => throw _Offline();
  @override
  Future<ApplicationModel> resubmitDocument(
    String applicationId, {
    required String documentId,
    required DocumentModel replacement,
  }) async => throw UnimplementedError();

  @override
  Future<ApplicationModel> advanceStatus(String applicationId) async =>
      throw _Offline();
}

class _ThrowingBusinesses implements BusinessRepository {
  @override
  Future<List<BusinessModel>> fetchAll() async => throw _Offline();
  @override
  Future<BusinessModel> registerBusiness({
    required String name,
    required BusinessCategory category,
    required String street,
    required String barangay,
    required String city,
    required String province,
  }) async => throw _Offline();
}

class _ThrowingNotifications implements NotificationsRepository {
  @override
  Future<List<NotificationEvent>> fetchAll() async => throw _Offline();
}

Widget _host(Widget screen) {
  final router = GoRouter(
    initialLocation: '/subject',
    routes: [
      GoRoute(path: '/subject', builder: (_, _) => screen),
      GoRoute(path: '/:a', builder: (_, _) => const Scaffold()),
      GoRoute(path: '/:a/:b', builder: (_, _) => const Scaffold()),
    ],
  );

  return MultiProvider(
    providers: [
      ChangeNotifierProvider<NotificationsProvider>(
        create: (_) =>
            NotificationsProvider(repository: _ThrowingNotifications()),
      ),
      ChangeNotifierProvider<ApplicationsProvider>(
        create: (context) => ApplicationsProvider(
          notifications: context.read<NotificationsProvider>(),
          repository: _ThrowingApplications(),
        ),
      ),
      ChangeNotifierProvider<BusinessProvider>(
        create: (context) => BusinessProvider(
          notifications: context.read<NotificationsProvider>(),
          repository: _ThrowingBusinesses(),
        ),
      ),
      // Everything DraftRegistry looks up, for the Drafts segment.
      ...wizardProviders(),
    ],
    child: MaterialApp.router(theme: AppTheme.lightTheme, routerConfig: router),
  );
}

Future<void> _open(WidgetTester tester, Widget screen) async {
  tester.view.physicalSize = const Size(400, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(_host(screen));
  await tester.pump();
  await tester.pump(const Duration(seconds: 2));
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  final screens = <String, Widget>{
    'Applications': const ApplicationListScreen(),
    'Notifications': const NotificationsScreen(),
    'Businesses': const BusinessListScreen(),
  };

  screens.forEach((name, screen) {
    testWidgets('$name says it could not load, not that there is nothing', (
      tester,
    ) async {
      await _open(tester, screen);

      expect(
        find.byType(LoadFailureState),
        findsOneWidget,
        reason: '$name should report the failure',
      );
      expect(find.text('Try Again'), findsOneWidget);

      // The spinner must not still be up — that was the defect before the
      // providers cleared isLoading in a finally.
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });
  });

  testWidgets('the empty state is still used when there is genuinely nothing', (
    tester,
  ) async {
    // Same screen, a repository that succeeds with no rows.
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<NotificationsProvider>(
            create: (_) => NotificationsProvider(
              repository: MockNotificationsRepository(),
            ),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const NotificationsScreen(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));

    expect(find.byType(LoadFailureState), findsNothing);
  });
}
