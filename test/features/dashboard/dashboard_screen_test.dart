import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ebpco_user_app/core/models/money.dart';
import 'package:ebpco_user_app/core/models/application_lineage.dart';
import 'package:ebpco_user_app/core/models/application_model.dart';
import 'package:ebpco_user_app/core/models/business_model.dart';
import 'package:ebpco_user_app/core/models/document_model.dart';
import 'package:ebpco_user_app/core/models/lifecycle_status.dart';
import 'package:ebpco_user_app/core/models/order_of_payment.dart';
import 'package:ebpco_user_app/core/models/payment_assessment_model.dart';
import 'package:ebpco_user_app/core/models/permit_classification.dart';
import 'package:ebpco_user_app/core/providers/applications_provider.dart';
import 'package:ebpco_user_app/core/providers/auth_provider.dart';
import 'package:ebpco_user_app/core/providers/business_provider.dart';
import 'package:ebpco_user_app/core/models/notification_event.dart';
import 'package:ebpco_user_app/core/providers/notifications_provider.dart';
import 'package:ebpco_user_app/core/repositories/notifications_repository.dart';
import 'package:ebpco_user_app/core/repositories/applications_repository.dart';
import 'package:ebpco_user_app/core/repositories/business_repository.dart';
import 'package:ebpco_user_app/features/dashboard/presentation/dashboard_screen.dart';

/// Serves a fixed set of applications with no network delay, so each Home
/// state can be set up exactly rather than approximated through the seed data.
class _FakeApplicationsRepository implements ApplicationsRepository {
  _FakeApplicationsRepository(this.applications);

  final List<ApplicationModel> applications;

  @override
  Future<List<ApplicationModel>> fetchAll() async => applications;

  @override
  Future<ApplicationModel> submitApplication({
    required String businessId,
    required String businessName,
    required ApplicationType type,
    required List<DocumentModel> documents,
    String? permitTypeLabel,
    String? applicationNumber,
    ApplicationLineage? lineage,
    List<String> documentIds = const [],
    String? location,
  }) => throw UnimplementedError();

  @override
  Future<ApplicationModel> attachPayment(
    String applicationId, {
    required PaymentMethod method,
    required String referenceNumber,
    required DateTime paidOn,
    PesoAmount? amountPaid,
    DocumentModel? proof,
    String? documentId,
  }) => throw UnimplementedError();
  @override
  Future<ApplicationModel> resubmitDocument(
    String applicationId, {
    required String documentId,
    required DocumentModel replacement,
  }) async => throw UnimplementedError();

  @override
  Future<ApplicationModel> advanceStatus(String applicationId) =>
      throw UnimplementedError();
}

/// Fails every fetch, to prove a broken backend degrades the tab rather than
/// blanking it.
class _FailingApplicationsRepository extends _FakeApplicationsRepository {
  _FailingApplicationsRepository() : super(const []);

  @override
  Future<List<ApplicationModel>> fetchAll() async =>
      throw StateError('backend unavailable');
}

/// Empty notification feed, so these tests isolate the applications-derived
/// action stack from whatever the seeded feed happens to contain. Both
/// surfaces legitimately mention the same obligation on the real screen.
class _EmptyNotificationsRepository implements NotificationsRepository {
  @override
  Future<List<NotificationEvent>> fetchAll() async => const [];
}

/// Succeeds once, then fails on demand — so a *refresh* failure can be told
/// apart from a cold-start failure.
class _FlakyApplicationsRepository extends _FakeApplicationsRepository {
  _FlakyApplicationsRepository(super.applications);

  bool failNext = false;

  @override
  Future<List<ApplicationModel>> fetchAll() async {
    if (failNext) throw StateError('network unreachable');
    return applications;
  }
}

class _FakeBusinessRepository implements BusinessRepository {
  _FakeBusinessRepository(this.businesses);

  final List<BusinessModel> businesses;

  @override
  Future<List<BusinessModel>> fetchAll() async => businesses;

  @override
  Future<BusinessModel> registerBusiness({
    required String name,
    required BusinessCategory category,
    required String street,
    required String barangay,
    required String city,
    required String province,
  }) => throw UnimplementedError();
}

final _now = DateTime(2026, 8, 18);

/// Providers hydrate through a simulated network delay held in a plain
/// `Future.delayed` timer, which `pumpAndSettle` does not drain because no
/// frame is scheduled against it. Advancing fake time past the delay is what
/// actually lets the tree settle.
Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(seconds: 3));
}

ApplicationModel _application({
  String id = 'app-1',
  ApplicationLifecycleStatus lifecycleStatus =
      ApplicationLifecycleStatus.underEvaluation,
  PermitClassification? classification = PermitClassification.highlyTechnical,
  int openInstructionCount = 0,
  PaymentAssessmentModel? payment,
  String? permitNumber,
  DateTime? issuedDate,
}) {
  return ApplicationModel(
    id: id,
    applicationNumber: 'E-BPCO-2026-000145',
    businessId: 'biz-1',
    businessName: "Juan's General Merchandise",
    type: ApplicationType.newPermit,
    status: lifecycleStatus.applicantStatus,
    submittedDate: DateTime(2026, 8, 12),
    lifecycleStatus: lifecycleStatus,
    classification: classification,
    permitTypeLabel: 'New Construction',
    openInstructionCount: openInstructionCount,
    payment: payment,
    permitNumber: permitNumber,
    issuedDate: issuedDate,
  );
}

Widget _wrap({
  List<ApplicationModel> applications = const [],
  List<BusinessModel> businesses = const [],
  ApplicationsRepository? applicationsRepository,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AuthProvider>(create: (_) => AuthProvider()),
      ChangeNotifierProvider<NotificationsProvider>(
        create: (_) =>
            NotificationsProvider(repository: _EmptyNotificationsRepository()),
      ),
      ChangeNotifierProvider<BusinessProvider>(
        create: (context) => BusinessProvider(
          notifications: context.read<NotificationsProvider>(),
          repository: _FakeBusinessRepository(businesses),
        ),
      ),
      ChangeNotifierProvider<ApplicationsProvider>(
        create: (context) => ApplicationsProvider(
          notifications: context.read<NotificationsProvider>(),
          repository:
              applicationsRepository ??
              _FakeApplicationsRepository(applications),
          clock: () => _now,
        ),
      ),
    ],
    child: const MaterialApp(home: DashboardScreen()),
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('empty states', () {
    testWidgets('first run with no business prompts profile setup', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap());
      await _settle(tester);

      expect(find.text('Set up your profile'), findsOneWidget);
      expect(find.text('Register a Business'), findsOneWidget);
      expect(find.text('Needs your action'), findsNothing);
    });

    testWidgets('a business with no application shows filing guidance', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          businesses: [
            BusinessModel(
              id: 'biz-1',
              name: "Juan's General Merchandise",
              category: BusinessCategory.retail,
              street: 'Rizal St.',
              barangay: 'San Isidro',
              city: 'Quezon City',
              province: 'Metro Manila',
              registrationNumber: 'BIZ-2026-0001',
              dateRegistered: DateTime(2026, 1, 5),
            ),
          ],
        ),
      );
      await _settle(tester);

      expect(find.text('Before you apply'), findsOneWidget);
      expect(find.text('Register a Business'), findsNothing);
      expect(
        find.textContaining('locational or zoning clearance'),
        findsWidgets,
      );
    });
  });

  group('in-flight application', () {
    testWidgets('shows the applicant headline, admin sub-line and countdown', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(applications: [_application()]));
      await _settle(tester);

      // Applicant-facing headline.
      expect(find.text('Under Review'), findsOneWidget);
      // The admin's finer state, which the headline alone throws away.
      expect(find.text('Technical evaluation in progress.'), findsOneWidget);
      // Filed Wed 12 Aug, highly technical (20 working days) → 16 consumed by
      // Tue 18 Aug, leaving 15... counted in working days, not calendar days.
      expect(find.textContaining('working days left'), findsOneWidget);
      expect(find.text('New Construction'), findsOneWidget);
      // Nothing outstanding, so the action region is absent entirely.
      expect(find.text('Needs your action'), findsNothing);
    });

    testWidgets('an unclassified application shows no invented countdown', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(applications: [_application(classification: null)]),
      );
      await _settle(tester);

      expect(find.text('Awaiting classification'), findsOneWidget);
      expect(find.textContaining('working days left'), findsNothing);
    });
  });

  group('action required', () {
    testWidgets('an outstanding Letter of Instruction leads the screen', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(applications: [_application(openInstructionCount: 2)]),
      );
      await _settle(tester);

      expect(find.text('Needs your action'), findsOneWidget);
      expect(find.text('Letter of Instruction issued'), findsOneWidget);
      expect(
        find.text('2 items must be corrected or supplied.'),
        findsOneWidget,
      );
      expect(find.text('View instructions'), findsOneWidget);
    });

    testWidgets('the action card renders above the active application', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(applications: [_application(openInstructionCount: 1)]),
      );
      await _settle(tester);

      final actionY = tester
          .getTopLeft(find.text('Letter of Instruction issued'))
          .dy;
      final cardY = tester.getTopLeft(find.text('Under Review')).dy;

      expect(
        actionY,
        lessThan(cardY),
        reason: 'what the applicant owes must outrank what is merely moving',
      );
    });

    testWidgets('an overdue payment is surfaced as critical', (tester) async {
      await tester.pumpWidget(
        _wrap(
          applications: [
            _application(
              lifecycleStatus: ApplicationLifecycleStatus.assessed,
              payment: PaymentAssessmentModel(
                status: PaymentAssessmentStatus.overdue,
                orderOfPayment: OrderOfPayment(
                  number: 'OP-2026-000001',
                  assessedAt: DateTime(2026, 8, 10),
                  fees: const AssessmentFees(filing: 50000, processing: 475000),
                ),
              ),
            ),
          ],
        ),
      );
      await _settle(tester);

      expect(find.text('Payment overdue'), findsOneWidget);
      expect(find.text('Unpaid applications may lapse.'), findsOneWidget);
    });

    testWidgets('several obligations sort by regulatory urgency', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          applications: [
            _application(
              id: 'app-release',
              lifecycleStatus: ApplicationLifecycleStatus.readyForRelease,
            ),
            _application(id: 'app-loi', openInstructionCount: 1),
          ],
        ),
      );
      await _settle(tester);

      final loiY = tester
          .getTopLeft(find.text('Letter of Instruction issued'))
          .dy;
      final releaseY = tester.getTopLeft(find.text('Permit ready to claim')).dy;

      expect(loiY, lessThan(releaseY));
      expect(find.text('Needs your action (2)'), findsOneWidget);
    });
  });

  group('resilience and layout', () {
    testWidgets('an unresolved action renders above the fold at 360x640', (
      tester,
    ) async {
      // The reference viewport from the acceptance criteria — a common
      // mid-range Android screen, which is the target device for this app.
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        _wrap(applications: [_application(openInstructionCount: 1)]),
      );
      await _settle(tester);

      final card = find.text('Letter of Instruction issued');
      expect(card, findsOneWidget);
      expect(
        tester.getBottomLeft(card).dy,
        lessThan(640),
        reason: 'the action must be visible without scrolling',
      );
    });

    testWidgets(
      'a failing repository degrades the tab instead of blanking it',
      (tester) async {
        await tester.pumpWidget(
          _wrap(applicationsRepository: _FailingApplicationsRepository()),
        );
        await _settle(tester);

        // The tab still renders its own furniture rather than hanging on a
        // spinner or throwing.
        expect(find.text('Apply for Permit'), findsWidgets);
        expect(find.text('Application Summary'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('a failed refresh keeps the data and labels it as stale', (
      tester,
    ) async {
      final repository = _FlakyApplicationsRepository([_application()]);
      await tester.pumpWidget(_wrap(applicationsRepository: repository));
      await _settle(tester);

      // First load succeeded, so there is no stamp yet.
      expect(find.textContaining('showing saved data'), findsNothing);
      expect(find.text('Under Review'), findsOneWidget);

      repository.failNext = true;
      await tester
          .element(find.byType(DashboardScreen))
          .read<ApplicationsProvider>()
          .refresh();
      await _settle(tester);

      // The application is still on screen, now stamped rather than withheld.
      expect(find.text('Under Review'), findsOneWidget);
      expect(find.textContaining('showing saved data'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });
  });

  group('counters and permits', () {
    testWidgets('counters report the four Home groupings', (tester) async {
      await tester.pumpWidget(_wrap(applications: [_application()]));
      await _settle(tester);

      expect(find.text('In Progress'), findsOneWidget);
      expect(find.text('Action Needed'), findsOneWidget);
      expect(find.text('Approved'), findsOneWidget);
      expect(find.text('Released'), findsOneWidget);
    });

    testWidgets('a released permit shows its PD 1096 commencement date', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          applications: [
            _application(
              lifecycleStatus: ApplicationLifecycleStatus.released,
              permitNumber: 'BP-2026-0001',
              issuedDate: DateTime(2026, 3, 2),
            ),
          ],
        ),
      );
      await _settle(tester);

      expect(find.text('My Permits'), findsOneWidget);
      expect(find.text('BP-2026-0001'), findsOneWidget);
      expect(find.text('Work must start by Mar 2, 2027'), findsOneWidget);
    });
  });
}
