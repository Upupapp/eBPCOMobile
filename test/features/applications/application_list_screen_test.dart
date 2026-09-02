import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ebpco_user_app/core/models/money.dart';
import 'package:ebpco_user_app/core/repositories/notifications_repository.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ebpco_user_app/core/models/application_lineage.dart';
import 'package:ebpco_user_app/core/models/application_model.dart';
import 'package:ebpco_user_app/core/models/document_model.dart';
import 'package:ebpco_user_app/core/models/lifecycle_status.dart';
import 'package:ebpco_user_app/core/models/payment_assessment_model.dart';
import 'package:ebpco_user_app/core/models/permit_classification.dart';
import 'package:ebpco_user_app/core/providers/applications_provider.dart';
import 'package:ebpco_user_app/core/providers/notifications_provider.dart';
import 'package:ebpco_user_app/core/sync/offline_queue.dart';
import 'package:ebpco_user_app/core/sync/queued_operation.dart';
import 'package:ebpco_user_app/core/sync/sync_provider.dart';
import 'package:ebpco_user_app/core/repositories/applications_repository.dart';
import 'package:ebpco_user_app/features/applications/presentation/application_list_screen.dart';
import 'package:ebpco_user_app/features/applications/presentation/building_permit/widgets/mock_upload.dart';
import 'package:ebpco_user_app/features/documents/presentation/widgets/attach_document_sheet.dart';

import '../../support/wizard_providers.dart';
import 'package:ebpco_user_app/core/providers/fencing_permit_provider.dart';

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
  }) async => throw UnimplementedError();

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
  required String id,
  required String number,
  required ApplicationLifecycleStatus lifecycleStatus,
  String permitType = 'New Construction',
  int openInstructionCount = 0,
}) {
  return ApplicationModel(
    id: id,
    applicationNumber: number,
    businessId: 'biz-1',
    businessName: "Juan's General Merchandise",
    type: ApplicationType.newPermit,
    status: lifecycleStatus.applicantStatus,
    submittedDate: DateTime(2026, 8, 3),
    lifecycleStatus: lifecycleStatus,
    classification: PermitClassification.complex,
    permitTypeLabel: permitType,
    openInstructionCount: openInstructionCount,
  );
}

Widget _wrap(
  List<ApplicationModel> applications, {
  FencingPermitProvider? fencing,

  /// Work this device is still holding. The screen shows the pending banner
  /// above the list, so the tests need a real SyncProvider over a real queue.
  SyncProvider? sync,
}) {
  final router = GoRouter(
    initialLocation: '/list',
    routes: [
      GoRoute(path: '/list', builder: (_, _) => const ApplicationListScreen()),
      GoRoute(path: '/applications/new', builder: (_, _) => const Scaffold()),
      GoRoute(path: '/applications/:id', builder: (_, _) => const Scaffold()),
    ],
  );

  return MultiProvider(
    providers: [
      ChangeNotifierProvider<NotificationsProvider>(
        create: (_) =>
            NotificationsProvider(repository: MockNotificationsRepository()),
      ),
      ChangeNotifierProvider<SyncProvider>.value(
        value: sync ?? SyncProvider(queue: OfflineQueue(InMemoryQueueStore())),
      ),
      ChangeNotifierProvider<ApplicationsProvider>(
        create: (context) => ApplicationsProvider(
          notifications: context.read<NotificationsProvider>(),
          repository: _FakeRepository(applications),
          clock: () => DateTime(2026, 8, 18),
        ),
      ),
      // Everything DraftRegistry looks up, for the Drafts segment. A caller
      // that wants a real draft passes its own fencing provider, which
      // replaces the empty one.
      ...wizardProviders(),
      if (fencing != null)
        ChangeNotifierProvider<FencingPermitProvider>.value(value: fencing),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(seconds: 3));
}

/// The search field debounces by 300ms in a plain Timer, which pumpAndSettle
/// does not advance because no frame is scheduled against it.
Future<void> _search(WidgetTester tester, String query) async {
  await tester.enterText(find.byType(TextField).first, query);
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pumpAndSettle();
}

void main() {
  _draftsGroup();
  // These wizards now attach documents through the real chooser sheet, which
  // reaches for the camera, gallery, and system file picker — none of them
  // available under `flutter test`. Swap it for a stub that returns a
  // fabricated document so the upload slots behave the way the steps'
  // validation expects.
  setUp(() {
    debugAttachDocumentOverride = (context, {required label}) async =>
        createMockDocument(label);
  });

  tearDown(() => debugAttachDocumentOverride = null);
  setUp(() => SharedPreferences.setMockInitialValues({}));

  final inProgress = _application(
    id: 'a1',
    number: 'E-BPCO-2026-000145',
    lifecycleStatus: ApplicationLifecycleStatus.underEvaluation,
  );
  final needsAction = _application(
    id: 'a2',
    number: 'E-BPCO-2026-000146',
    lifecycleStatus: ApplicationLifecycleStatus.assessed,
    permitType: 'Electrical',
  );
  final released = _application(
    id: 'a3',
    number: 'E-BPCO-2026-000100',
    lifecycleStatus: ApplicationLifecycleStatus.released,
    permitType: 'Fencing',
  );

  testWidgets('opens on In Progress and counts every segment', (tester) async {
    await tester.pumpWidget(_wrap([inProgress, needsAction, released]));
    await _settle(tester);

    expect(find.text('Drafts (0)'), findsOneWidget);
    expect(find.text('In Progress (1)'), findsOneWidget);
    expect(find.text('Needs Action (1)'), findsOneWidget);
    expect(find.text('Completed (1)'), findsOneWidget);

    expect(find.text('E-BPCO-2026-000145'), findsOneWidget);
    expect(find.text('E-BPCO-2026-000146'), findsNothing);
  });

  testWidgets('an application needing action is excluded from In Progress', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap([needsAction]));
    await _settle(tester);

    // It is Payment Verification, which would otherwise read as in progress —
    // but the applicant is the one holding it up.
    expect(find.text('In Progress (0)'), findsOneWidget);
    expect(find.text('Needs Action (1)'), findsOneWidget);
  });

  testWidgets('switching segment shows that slice', (tester) async {
    await tester.pumpWidget(_wrap([inProgress, needsAction, released]));
    await _settle(tester);

    await tester.tap(find.text('Needs Action (1)'));
    await tester.pumpAndSettle();

    expect(find.text('E-BPCO-2026-000146'), findsOneWidget);
    expect(find.text('Needs your action'), findsOneWidget);
  });

  testWidgets('search matches reference, business, and permit type', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap([inProgress, needsAction, released]));
    await _settle(tester);

    await tester.tap(find.text('Completed (1)'));
    await tester.pumpAndSettle();
    expect(find.text('E-BPCO-2026-000100'), findsOneWidget);

    await _search(tester, 'Fencing');
    expect(find.text('E-BPCO-2026-000100'), findsOneWidget);

    await _search(tester, 'Mechanical');
    expect(find.text('No matches'), findsOneWidget);

    // Reference and business name match too, not just permit type.
    await _search(tester, '000100');
    expect(find.text('E-BPCO-2026-000100'), findsOneWidget);
    await _search(tester, 'Juan');
    expect(find.text('E-BPCO-2026-000100'), findsOneWidget);
  });

  testWidgets('each empty segment explains itself rather than sharing one', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(const []));
    await _settle(tester);

    expect(find.text('Nothing in progress'), findsOneWidget);

    await tester.tap(find.text('Needs Action (0)'));
    await tester.pumpAndSettle();
    expect(find.text('Nothing needs you right now'), findsOneWidget);

    await tester.tap(find.text('Drafts (0)'));
    await tester.pumpAndSettle();
    expect(find.text('No drafts'), findsOneWidget);
  });
}

/// Drafts live in the sixteen wizard providers, not in `ApplicationsProvider`.
///
/// Nothing in this app ever creates an application with
/// `ApplicationStatus.draft`, so the Drafts segment — which filtered for
/// exactly that — read "Drafts (0)" however many half-finished applications
/// the applicant had. Their drafts were known: `MainShell` reads the same
/// registry to nudge them about idle ones. The app was notifying people about
/// work it gave them nowhere to see.
void _draftsGroup() {
  group('the Drafts segment', () {
    testWidgets('shows a wizard draft, and counts it', (tester) async {
      final fencing = FencingPermitProvider();
      fencing.startNew();
      fencing.saveAsDraft();

      await tester.pumpWidget(_wrap(const [], fencing: fencing));
      await _settle(tester);

      expect(
        find.textContaining('Drafts (1)'),
        findsOneWidget,
        reason: 'the chip counts drafts from the wizards',
      );

      await tester.tap(find.textContaining('Drafts ('));
      await tester.pumpAndSettle();

      expect(find.text('Fencing'), findsOneWidget);
      expect(find.textContaining('% complete'), findsOneWidget);
    });

    testWidgets('resumes the wizard when tapped', (tester) async {
      final fencing = FencingPermitProvider();
      fencing.startNew();
      fencing.saveAsDraft();

      await tester.pumpWidget(_wrap(const [], fencing: fencing));
      await _settle(tester);
      await tester.tap(find.textContaining('Drafts ('));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Fencing'));
      await tester.pumpAndSettle();

      // The draft's own route, not the applications list.
      expect(find.byType(ApplicationListScreen), findsNothing);
    });

    testWidgets('still says nothing when there are no drafts', (tester) async {
      await tester.pumpWidget(_wrap(const []));
      await _settle(tester);

      expect(find.textContaining('Drafts (0)'), findsOneWidget);
    });
  });

  testWidgets('queued work is named on the list screen, and never as filed', (
    tester,
  ) async {
    // The wiring. SyncProvider counted queued work, flushed it on resume and
    // recorded the outcome since it was written, and no widget read any of
    // it — so a citizen whose upload failed had their file kept, retried and
    // sent with no sign that any of it had happened.
    final queue = OfflineQueue(InMemoryQueueStore());
    await queue.enqueue(
      QueuedOperation(
        id: 'upload-1',
        kind: QueuedOperationKind.documentUpload,
        idempotencyKey: 'k1',
        enqueuedAt: DateTime(2026, 9, 2),
        payload: const {'filePath': '/tmp/a.pdf', 'label': 'Lot Plan'},
      ),
    );
    await queue.enqueue(
      QueuedOperation(
        id: 'verify-1',
        kind: QueuedOperationKind.contactVerificationRequest,
        idempotencyKey: 'k2',
        enqueuedAt: DateTime(2026, 9, 2),
        payload: const {'channel': 'mobile', 'value': '09171234567'},
      ),
    );
    final sync = SyncProvider(queue: queue);
    await sync.refresh();

    await tester.pumpWidget(_wrap(const [], sync: sync));
    await _settle(tester);

    expect(find.text('Waiting to reach the office'), findsOneWidget);
    expect(
      find.text('1 file and 1 verification request waiting to be sent.'),
      findsOneWidget,
      reason: 'a count with no noun tells the citizen nothing they can act on',
    );
    expect(
      find.textContaining('The office does not have these yet'),
      findsOneWidget,
      reason: 'the sentence the whole banner exists for',
    );
  });

  testWidgets('nothing waiting shows no banner at all', (tester) async {
    // It must not become a permanent fixture people learn to ignore.
    await tester.pumpWidget(_wrap(const []));
    await _settle(tester);

    expect(find.text('Waiting to reach the office'), findsNothing);
  });
}
