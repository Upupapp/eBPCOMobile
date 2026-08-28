import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:ebpco_user_app/core/providers/application_intent_provider.dart';
import 'package:ebpco_user_app/core/providers/applications_provider.dart';
import 'package:ebpco_user_app/core/providers/notifications_provider.dart';
import 'package:ebpco_user_app/core/repositories/applications_repository.dart';
import 'package:ebpco_user_app/core/repositories/notifications_repository.dart';
import 'package:ebpco_user_app/core/theme/app_theme.dart';
import 'package:ebpco_user_app/features/applications/presentation/widgets/application_submitted_view.dart';
import 'package:ebpco_user_app/features/applications/presentation/widgets/submit_permit_application.dart';

/// Submitting a permit used to change nothing outside the wizard's own draft.
/// The applicant filled in nine steps, read a reference number, and found the
/// applications list exactly as empty as before — no record, and no
/// notification either, because the submitted notification is posted by
/// `ApplicationsProvider.submitApplication` and nothing reached it.
///
/// These cover the two halves of the fix: the record gets created, and the
/// confirmation screen can now point at it.

void main() {
  group('recording the submission', () {
    testWidgets('adds an application the list can show', (tester) async {
      late ApplicationsProvider applications;
      late BuildContext ctx;

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            // Every wizard's submit handler reads this to pick up a pending
            // renewal or amendment.
            ChangeNotifierProvider<ApplicationIntentProvider>(
              create: (_) => ApplicationIntentProvider(),
            ),
            ChangeNotifierProvider<NotificationsProvider>(
              create: (_) => NotificationsProvider(
                repository: MockNotificationsRepository(),
              ),
            ),
            ChangeNotifierProvider<ApplicationsProvider>(
              create: (context) => ApplicationsProvider(
                notifications: context.read<NotificationsProvider>(),
                repository: MockApplicationsRepository(),
              ),
            ),
          ],
          child: MaterialApp(
            home: Builder(
              builder: (context) {
                ctx = context;
                applications = context.read<ApplicationsProvider>();
                return const SizedBox();
              },
            ),
          ),
        ),
      );
      await tester.pump(const Duration(seconds: 1));
      final before = applications.applications.length;

      // Start it, then advance the fake clock. Awaiting directly would hang:
      // the repository's delay is a Future.delayed, and nothing moves the
      // test clock unless the tester pumps.
      final pending = submitPermitApplication(
        ctx,
        referenceNumber: 'FNC-2026-123456',
        permitTypeLabel: 'Fencing Permit',
        applicantName: 'Dela Cruz Construction Services',
      );
      await tester.pump(const Duration(seconds: 1));
      final created = await pending;
      expect(
        created,
        isNotNull,
        reason: 'a successful submit returns the record',
      );
      await tester.pump();

      expect(applications.applications.length, before + 1);
      expect(applications.applications.last.id, created!.id);

      // The number the applicant was shown is the number that was stored —
      // not a second one invented by the repository.
      expect(created.applicationNumber, 'FNC-2026-123456');
      expect(created.permitTypeLabel, 'Fencing Permit');
      expect(created.businessName, 'Dela Cruz Construction Services');
    });
  });

  group('naming the applicant', () {
    test('prefers the enterprise when there is one', () {
      expect(
        applicantDisplayName(
          enterpriseName: 'Dela Cruz Construction Services',
          firstName: 'Juan',
          lastName: 'Dela Cruz',
        ),
        'Dela Cruz Construction Services',
      );
    });

    test('falls back to the person', () {
      expect(
        applicantDisplayName(
          enterpriseName: '   ',
          firstName: 'Juan',
          lastName: 'Dela Cruz',
        ),
        'Juan Dela Cruz',
      );
    });
  });

  group('the confirmation screen', () {
    Future<String?> tapViewApplication(
      WidgetTester tester, {
      String? applicationId,
    }) async {
      String? landedOn;
      final router = GoRouter(
        initialLocation: '/submitted',
        routes: [
          GoRoute(
            path: '/submitted',
            builder: (_, _) => ApplicationSubmittedView(
              headline: 'Fencing Application Submitted!',
              body: 'Your application has been submitted.',
              referenceNumber: 'FNC-2026-123456',
              submissionDate: DateTime(2026, 8, 24),
              facts: const [],
              applicationId: applicationId,
              primaryLabel: 'Return to Applications',
              primaryRoute: '/app/applications',
            ),
          ),
          GoRoute(
            path: '/app/applications',
            builder: (_, state) {
              landedOn = state.uri.path;
              return const Scaffold();
            },
          ),
          GoRoute(
            path: '/applications/:id',
            builder: (_, state) {
              landedOn = state.uri.path;
              return const Scaffold();
            },
          ),
        ],
      );

      tester.view.physicalSize = const Size(400, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp.router(theme: AppTheme.lightTheme, routerConfig: router),
      );
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('View Application'));
      await tester.tap(find.text('View Application'));
      await tester.pumpAndSettle();
      return landedOn;
    }

    testWidgets('opens the application it just created', (tester) async {
      expect(
        await tapViewApplication(tester, applicationId: 'app-42'),
        '/applications/app-42',
      );
    });

    testWidgets('falls back to the list when there is no record', (
      tester,
    ) async {
      // Entering the route directly, with no `extra`, still has to work.
      expect(await tapViewApplication(tester), '/app/applications');
    });
  });
}
