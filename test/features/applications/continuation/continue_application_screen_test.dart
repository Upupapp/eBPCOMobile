import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ebpco_user_app/core/models/money.dart';
import 'package:ebpco_user_app/core/contract/admin_vocabulary.dart';
import 'package:ebpco_user_app/core/models/application_detail.dart';
import 'package:ebpco_user_app/core/models/application_lineage.dart';
import 'package:ebpco_user_app/core/models/application_model.dart';
import 'package:ebpco_user_app/core/models/document_model.dart';
import 'package:ebpco_user_app/core/models/lifecycle_status.dart';
import 'package:ebpco_user_app/core/models/payment_assessment_model.dart';
import 'package:ebpco_user_app/core/providers/application_intent_provider.dart';
import 'package:ebpco_user_app/core/providers/applications_provider.dart';
import 'package:ebpco_user_app/core/providers/notifications_provider.dart';
import 'package:ebpco_user_app/core/repositories/applications_repository.dart';
import 'package:ebpco_user_app/core/repositories/notifications_repository.dart';
import 'package:ebpco_user_app/core/theme/app_theme.dart';
import 'package:ebpco_user_app/features/applications/presentation/continuation/continue_application_screen.dart';
import 'package:ebpco_user_app/features/applications/presentation/detail/digital_permit_screen.dart';

/// Starting a renewal or an amendment from the record it continues.

class _FakeRepository implements ApplicationsRepository {
  _FakeRepository(this.applications);
  final List<ApplicationModel> applications;

  @override
  Future<ApplicationModel> fetchDetail(String applicationId) async =>
      applications.firstWhere((a) => a.id == applicationId);

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
    Map<String, Object?>? form,
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
  }) => throw UnimplementedError();

  @override
  Future<ApplicationModel> advanceStatus(String applicationId) =>
      throw UnimplementedError();

  @override
  Future<ApplicationModel> resubmitInstruction(
    String applicationId,
    String letterId, {
    required List<String> itemIds,
    Map<String, String> responses = const {},
  }) async => throw UnimplementedError();
}

ApplicationModel _application({
  String? permitTypeLabel = 'Fencing Permit',
  String? permitNumber = 'BP-2026-000145',
  DateTime? issuedDate,
  ApplicationLifecycleStatus lifecycleStatus =
      ApplicationLifecycleStatus.released,
}) {
  final issued = issuedDate ?? DateTime(2026, 4, 1);
  return ApplicationModel(
    id: 'app-1',
    applicationNumber: 'E-BPCO-2026-000145',
    businessId: 'biz-1',
    businessName: 'Dela Cruz Construction',
    type: ApplicationType.newPermit,
    status: lifecycleStatus.applicantStatus,
    submittedDate: DateTime(2026, 1, 5),
    lifecycleStatus: lifecycleStatus,
    permitTypeLabel: permitTypeLabel,
    permitNumber: permitNumber,
    issuedDate: permitNumber == null ? null : issued,
    permit: permitNumber == null
        ? null
        : GeneratedPermit(permitNumber: permitNumber, issuedDate: issued),
  );
}

late ApplicationIntentProvider intent;

Widget _wrap(ApplicationModel application, {required String initial}) {
  intent = ApplicationIntentProvider();
  final router = GoRouter(
    initialLocation: initial,
    routes: [
      GoRoute(
        path: '/applications/:applicationId/renew',
        builder: (_, s) => ContinueApplicationScreen(
          applicationId: s.pathParameters['applicationId']!,
          kind: ContinuationKind.renewal,
        ),
      ),
      GoRoute(
        path: '/applications/:applicationId/amend',
        builder: (_, s) => ContinueApplicationScreen(
          applicationId: s.pathParameters['applicationId']!,
          kind: ContinuationKind.amendment,
        ),
      ),
      GoRoute(
        path: '/applications/:applicationId/permit',
        builder: (_, s) => DigitalPermitScreen(
          applicationId: s.pathParameters['applicationId']!,
        ),
      ),
      GoRoute(
        path: '/applications/new/fencing-permit',
        builder: (_, _) => const Scaffold(body: Text('FENCING WIZARD')),
      ),
      GoRoute(path: '/forms/:permitType', builder: (_, _) => const Scaffold()),
      GoRoute(
        path: '/charter/:permitType',
        builder: (_, _) => const Scaffold(),
      ),
    ],
  );

  return MultiProvider(
    providers: [
      ChangeNotifierProvider<ApplicationIntentProvider>.value(value: intent),
      ChangeNotifierProvider<NotificationsProvider>(
        create: (_) =>
            NotificationsProvider(repository: MockNotificationsRepository()),
      ),
      ChangeNotifierProvider<ApplicationsProvider>(
        create: (context) => ApplicationsProvider(
          notifications: context.read<NotificationsProvider>(),
          repository: _FakeRepository([application]),
          clock: () => DateTime(2026, 8, 18),
        ),
      ),
    ],
    child: MaterialApp.router(theme: AppTheme.lightTheme, routerConfig: router),
  );
}

Future<void> _open(
  WidgetTester tester,
  ApplicationModel application, {
  String initial = '/applications/app-1/renew',
}) async {
  await tester.binding.setSurfaceSize(const Size(400, 3000));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(_wrap(application, initial: initial));
  await tester.pump();
  await tester.pump(const Duration(seconds: 3));
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('renewal', () {
    testWidgets('names the permit and when it stops being valid', (
      tester,
    ) async {
      await _open(tester, _application());

      expect(
        find.textContaining('Renewing permit BP-2026-000145'),
        findsOneWidget,
      );
      expect(find.text('Valid until Oct 1, 2026'), findsOneWidget);
    });

    testWidgets('does not invent a shorter requirements list', (tester) async {
      // The LGU publishes none. Guessing at one sends someone to the counter
      // under-prepared, which is the specific harm this screen exists around.
      await _open(tester, _application());

      expect(
        find.text('The office decides what it still needs'),
        findsOneWidget,
      );
      expect(
        find.textContaining('has not published a shorter requirements list'),
        findsOneWidget,
      );
    });

    testWidgets('starting it sets the lineage and opens the right wizard', (
      tester,
    ) async {
      await _open(tester, _application());

      await tester.tap(find.text('Start the renewal'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));

      expect(find.text('FENCING WIZARD'), findsOneWidget);

      final pending = intent.pending!;
      expect(pending.action, ApplicationType.renewal);
      expect(pending.priorPermitNumber, 'BP-2026-000145');
      expect(pending.priorApplicationId, 'app-1');
      expect(pending.permitTypeLabel, 'Fencing Permit');
    });

    testWidgets(
      'an application with no permit says there is nothing to renew',
      (tester) async {
        await _open(
          tester,
          _application(
            permitNumber: null,
            lifecycleStatus: ApplicationLifecycleStatus.underEvaluation,
          ),
        );

        expect(find.text('No permit to renew yet'), findsOneWidget);
        expect(find.text('Start the renewal'), findsNothing);
      },
    );

    testWidgets('a permit filed under an unknown label offers no path', (
      tester,
    ) async {
      // The legacy Business Permit flow. Saying the counter can take it beats
      // a button that opens the error page.
      await _open(tester, _application(permitTypeLabel: 'Business Permit'));

      expect(find.text('Not available for this permit'), findsOneWidget);
    });

    testWidgets('an unknown application id is reported, not crashed', (
      tester,
    ) async {
      await _open(
        tester,
        _application(),
        initial: '/applications/does-not-exist/renew',
      );

      expect(find.text('Application not found'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('amendment', () {
    testWidgets('names the application being amended', (tester) async {
      await _open(
        tester,
        _application(
          lifecycleStatus: ApplicationLifecycleStatus.underEvaluation,
        ),
        initial: '/applications/app-1/amend',
      );

      expect(
        find.textContaining('Amending application E-BPCO-2026-000145'),
        findsOneWidget,
      );
    });

    testWidgets(
      'starting it references the application and carries no permit',
      (tester) async {
        await _open(
          tester,
          _application(
            lifecycleStatus: ApplicationLifecycleStatus.underEvaluation,
          ),
          initial: '/applications/app-1/amend',
        );

        await tester.tap(find.text('Start the amendment'));
        await tester.pump();
        await tester.pump(const Duration(seconds: 2));

        final pending = intent.pending!;
        expect(pending.action, ApplicationType.amendment);
        expect(pending.priorApplicationId, 'app-1');
        expect(pending.priorPermitNumber, isNull);
      },
    );
  });

  group('reachability', () {
    testWidgets('renewal is offered on the permit itself', (tester) async {
      // The acceptance criterion: reachable from the expiring permit, not only
      // from the catalog. TABs 09 and 13 both warn about expiry; until this
      // existed neither warning had an answer.
      await _open(
        tester,
        _application(),
        initial: '/applications/app-1/permit',
      );

      expect(find.text('Renew this permit'), findsOneWidget);

      await tester.tap(find.text('Renew this permit'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));

      expect(find.textContaining('Renewing permit'), findsOneWidget);
    });

    testWidgets('a Certificate of Occupancy is not offered a renewal', (
      tester,
    ) async {
      // Its validity is null, so there is nothing to renew.
      await _open(
        tester,
        _application(
          permitTypeLabel: CanonicalPermitType.certificateOfOccupancy.wire,
        ),
        initial: '/applications/app-1/permit',
      );

      expect(find.text('Renew this permit'), findsNothing);
    });
  });
}
