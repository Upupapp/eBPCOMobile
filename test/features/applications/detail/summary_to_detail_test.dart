import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ebpco_user_app/core/models/application_lineage.dart';
import 'package:ebpco_user_app/core/models/application_model.dart';
import 'package:ebpco_user_app/core/models/document_model.dart';
import 'package:ebpco_user_app/core/models/application_detail.dart';
import 'package:ebpco_user_app/core/models/lifecycle_status.dart';
import 'package:ebpco_user_app/core/models/money.dart';
import 'package:ebpco_user_app/core/models/payment_assessment_model.dart';
import 'package:ebpco_user_app/core/providers/applications_provider.dart';
import 'package:ebpco_user_app/core/providers/notifications_provider.dart';
import 'package:ebpco_user_app/core/repositories/applications_repository.dart';
import 'package:ebpco_user_app/core/repositories/notifications_repository.dart';
import 'package:ebpco_user_app/features/applications/presentation/detail/application_detail_gate.dart';
import 'package:ebpco_user_app/features/applications/presentation/detail/application_detail_screen.dart';

/// The promise and its destination are fed by different payloads.
///
/// **The systemic form of the defect M-11 was one instance of.** The Home
/// action stack is computed from SCALARS a list payload carries —
/// `openInstructionCount`, `lifecycleStatus` — so the app promises "3 items
/// must be corrected" and offers "View instructions". Everything those
/// promises point at lives in sub-objects the list may omit: `instructions`,
/// `evaluations`, `permit`, `release`, `inspection`. The contract keeps
/// `GET /applications/{id}` as a separate operation, "One application in
/// full", precisely because the list need not carry them, and
/// `ApplicationDto.parse` already said so in a comment: "a summary payload may
/// omit the letters themselves".
///
/// Every destination is behind a null guard on one of those objects. So an
/// applicant arrived at a screen with no letter, no banner, and no route to
/// one — while Home kept telling them three things needed correcting.
///
/// `fetchDetail` existed on the HTTP repository the whole time. It was
/// unreachable because the interface every caller holds did not declare it.

class _SummaryThenDetail implements ApplicationsRepository {
  _SummaryThenDetail({required this.summary, required this.detail});

  final ApplicationModel summary;
  final ApplicationModel detail;
  int detailCalls = 0;

  @override
  Future<List<ApplicationModel>> fetchAll() async => [summary];

  @override
  Future<ApplicationModel> fetchDetail(String applicationId) async {
    detailCalls++;
    return detail;
  }

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
}

ApplicationModel _base({List<LetterOfInstruction> instructions = const []}) =>
    ApplicationModel(
      id: 'app-1',
      applicationNumber: 'E-BPCO-2026-000145',
      businessId: 'biz-1',
      businessName: 'Dela Cruz Construction',
      type: ApplicationType.newPermit,
      status: ApplicationStatus.underReview,
      submittedDate: DateTime(2026, 8, 1),
      lifecycleStatus: ApplicationLifecycleStatus.revisionRequired,
      // The scalar a LIST payload carries, and what the Home action item is
      // computed from. Three items must be corrected — says the summary.
      openInstructionCount: 3,
      instructions: instructions,
    );

Widget _wrap(ApplicationsRepository repository) {
  final router = GoRouter(
    initialLocation: '/applications/app-1',
    routes: [
      GoRoute(
        path: '/applications/:applicationId',
        // As the real router builds it. The gate is what fetches, and
        // testing the screen without it would test a wiring the app does not
        // have — the shape this repo has been bitten by three times.
        builder: (_, state) => ApplicationDetailGate(
          applicationId: state.pathParameters['applicationId']!,
          child: ApplicationDetailScreen(
            applicationId: state.pathParameters['applicationId']!,
          ),
        ),
      ),
    ],
  );
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<NotificationsProvider>(
        create: (_) =>
            NotificationsProvider(repository: MockNotificationsRepository()),
      ),
      ChangeNotifierProvider<ApplicationsProvider>(
        create: (context) => ApplicationsProvider(
          notifications: context.read<NotificationsProvider>(),
          repository: repository,
        ),
      ),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  _routerGate();

  final letter = LetterOfInstruction(
    id: 'loi-1',
    issuedAt: DateTime(2026, 8, 20),
    items: const [
      InstructionItem(
        id: 'item-1',
        subject: 'Structural computations',
        remark: 'Unsigned and unsealed. Resubmit signed and sealed.',
      ),
    ],
  );

  testWidgets('opening the screen asks for the full record', (tester) async {
    final repository = _SummaryThenDetail(
      summary: _base(),
      detail: _base(instructions: [letter]),
    );
    await tester.binding.setSurfaceSize(const Size(400, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(_wrap(repository));
    await tester.pump();
    await tester.pump(const Duration(seconds: 3));

    expect(
      repository.detailCalls,
      greaterThan(0),
      reason:
          'without this the screen is built from the list payload, and every '
          'section an applicant is sent here to read is behind a null guard '
          'on an object the list may omit',
    );
  });

  testWidgets('and the letter it promised becomes reachable', (tester) async {
    final repository = _SummaryThenDetail(
      summary: _base(),
      detail: _base(instructions: [letter]),
    );
    await tester.binding.setSurfaceSize(const Size(400, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(_wrap(repository));
    await tester.pump();
    await tester.pump(const Duration(seconds: 3));

    // The banner is the ONLY route from this screen to the Letter of
    // Instruction, and it is guarded on `openInstruction` — derived from the
    // `instructions` list, not from the count the summary carries.
    expect(find.text('Letter of Instruction outstanding'), findsOneWidget);
    expect(find.text('Open the letter'), findsOneWidget);
  });

  testWidgets('without the fetch, the promise leads nowhere', (tester) async {
    // The state the app shipped in: the summary IS the detail, because
    // nothing ever asked for more.
    final repository = _SummaryThenDetail(summary: _base(), detail: _base());
    await tester.binding.setSurfaceSize(const Size(400, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(_wrap(repository));
    await tester.pump();
    await tester.pump(const Duration(seconds: 3));

    expect(find.text('Open the letter'), findsNothing);
    // And this is what makes it a defect rather than a blank space: the app
    // still believes three items need correcting, and still says so on Home.
    expect(_base().requiresApplicantAction, isTrue);
    expect(_base().openInstructionCount, 3);
  });

  testWidgets('it is fetched once, not on every rebuild', (tester) async {
    final repository = _SummaryThenDetail(
      summary: _base(),
      detail: _base(instructions: [letter]),
    );
    await tester.binding.setSurfaceSize(const Size(400, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(_wrap(repository));
    await tester.pump();
    await tester.pump(const Duration(seconds: 3));
    // loadDetail notifies, which rebuilds this screen. If the guard were
    // missing that rebuild would fetch again, and so would the one after it.
    await tester.pump(const Duration(seconds: 3));

    expect(repository.detailCalls, 1);
  });
}

/// Every route that reads a sub-object must go through the gate.
///
/// Four of these screens are reachable directly from a push notification's
/// deep link, without passing the detail screen. Gating only the detail screen
/// would have left four ways in uncovered — and a source scan is the cheapest
/// way to keep that true as routes are added.
void _routerGate() {
  test('all five detail routes are gated', () {
    final router = File('lib/routes/app_router.dart').readAsStringSync();
    const screens = [
      'ApplicationDetailScreen',
      'LetterOfInstructionScreen',
      'DigitalPermitScreen',
      'ApplicationOutcomeScreen',
      'OrderOfPaymentScreen',
    ];
    for (final screen in screens) {
      final at = router.indexOf('child: $screen(');
      expect(
        at,
        greaterThan(0),
        reason:
            '$screen is not built inside ApplicationDetailGate. It reads a '
            'sub-object the list payload may omit, so without the gate an '
            'applicant sent here by a notification finds an empty screen',
      );
      // The gate must be the thing wrapping it, not merely present somewhere
      // above in the file.
      final gate = router.lastIndexOf('ApplicationDetailGate(', at);
      expect(gate, greaterThan(0));
      expect(
        router.substring(gate, at),
        isNot(contains('GoRoute(')),
        reason: '$screen sits in a different route from the gate above it',
      );
    }
  });
}
