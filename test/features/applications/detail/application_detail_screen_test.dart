import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ebpco_user_app/core/models/application_detail.dart';
import 'package:ebpco_user_app/core/models/application_model.dart';
import 'package:ebpco_user_app/core/models/document_model.dart';
import 'package:ebpco_user_app/core/models/lifecycle_status.dart';
import 'package:ebpco_user_app/core/models/payment_assessment_model.dart';
import 'package:ebpco_user_app/core/models/permit_classification.dart';
import 'package:ebpco_user_app/core/providers/applications_provider.dart';
import 'package:ebpco_user_app/core/providers/notifications_provider.dart';
import 'package:ebpco_user_app/core/repositories/applications_repository.dart';
import 'package:ebpco_user_app/features/applications/presentation/detail/application_detail_screen.dart';
import 'package:ebpco_user_app/features/applications/presentation/detail/application_outcome_screen.dart';
import 'package:ebpco_user_app/features/applications/presentation/detail/digital_permit_screen.dart';
import 'package:ebpco_user_app/features/applications/presentation/detail/letter_of_instruction_screen.dart';
import 'package:ebpco_user_app/features/applications/presentation/building_permit/widgets/mock_upload.dart';
import 'package:ebpco_user_app/features/documents/presentation/widgets/attach_document_sheet.dart';

class _FakeRepository implements ApplicationsRepository {
  _FakeRepository(this.applications);
  final List<ApplicationModel> applications;

  @override
  Future<List<ApplicationModel>> fetchAll() async => applications;

  @override
  Future<ApplicationModel> submitApplication({
    required String businessId,
    required String businessName,
    required ApplicationType type,
    required List<DocumentModel> documents,
  }) => throw UnimplementedError();

  @override
  Future<ApplicationModel> attachPayment(
    String applicationId, {
    required PaymentMethod method,
    DocumentModel? proof,
  }) => throw UnimplementedError();

  @override
  Future<ApplicationModel> advanceStatus(String applicationId) =>
      throw UnimplementedError();
}

final _filed = DateTime(2026, 8, 3);

ApplicationModel _application({
  ApplicationLifecycleStatus lifecycleStatus =
      ApplicationLifecycleStatus.underEvaluation,
  List<TimelineEntry> timeline = const [],
  List<EvaluationRecord> evaluations = const [],
  List<LetterOfInstruction> instructions = const [],
  InspectionRecord? inspection,
  GeneratedPermit? permit,
  ReleaseRecord? release,
}) {
  var open = 0;
  for (final letter in instructions) {
    open += letter.openCount;
  }
  return ApplicationModel(
    id: 'app-1',
    applicationNumber: 'E-BPCO-2026-000145',
    businessId: 'biz-1',
    businessName: "Juan's General Merchandise",
    type: ApplicationType.newPermit,
    status: lifecycleStatus.applicantStatus,
    submittedDate: _filed,
    lifecycleStatus: lifecycleStatus,
    classification: PermitClassification.highlyTechnical,
    permitTypeLabel: 'New Construction',
    openInstructionCount: open,
    timeline: timeline,
    evaluations: evaluations,
    instructions: instructions,
    inspection: inspection,
    permit: permit,
    release: release,
  );
}

Widget _wrap(ApplicationModel application, {String initial = '/detail'}) {
  final router = GoRouter(
    initialLocation: initial,
    routes: [
      GoRoute(
        path: '/detail',
        builder: (_, _) => const ApplicationDetailScreen(applicationId: 'app-1'),
      ),
      GoRoute(
        path: '/applications/:id/instructions',
        builder: (_, _) =>
            const LetterOfInstructionScreen(applicationId: 'app-1'),
      ),
      GoRoute(
        path: '/applications/:id/permit',
        builder: (_, _) => const DigitalPermitScreen(applicationId: 'app-1'),
      ),
      GoRoute(
        path: '/applications/:id/outcome',
        builder: (_, _) =>
            const ApplicationOutcomeScreen(applicationId: 'app-1'),
      ),
      GoRoute(path: '/applications/:id/pay', builder: (_, _) => const Scaffold()),
      GoRoute(path: '/applications/new', builder: (_, _) => const Scaffold()),
    ],
  );

  return MultiProvider(
    providers: [
      ChangeNotifierProvider<NotificationsProvider>(
        create: (_) => NotificationsProvider(),
      ),
      ChangeNotifierProvider<ApplicationsProvider>(
        create: (context) => ApplicationsProvider(
          notifications: context.read<NotificationsProvider>(),
          repository: _FakeRepository([application]),
          clock: () => DateTime(2026, 8, 18),
        ),
      ),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(seconds: 3));
}

/// The detail screen is a lazily-built ListView, so sections below the fold
/// are never instantiated on a phone-sized surface. A tall surface renders the
/// whole record at once, which is what these tests are asserting about.
Future<void> _useTallSurface(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(400, 3000));
  addTearDown(() => tester.binding.setSurfaceSize(null));
}

void main() {
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

  group('header and sections', () {
    testWidgets('shows the applicant headline with the admin sub-line', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(_application()));
      await _settle(tester);

      expect(find.text('Under Review'), findsOneWidget);
      expect(find.text('Technical evaluation in progress.'), findsOneWidget);
      expect(find.textContaining('Highly Technical application'), findsOneWidget);
    });

    testWidgets('renders every evaluation stage, including unreached ones', (
      tester,
    ) async {
      await _useTallSurface(tester);
      await tester.pumpWidget(
        _wrap(
          _application(
            evaluations: [
              EvaluationRecord(
                stage: EvaluationStage.initial,
                result: EvaluationResult.passed,
                evaluatedAt: _filed,
              ),
            ],
          ),
        ),
      );
      await _settle(tester);

      // All five stages appear so the applicant can see what is still ahead.
      for (final stage in EvaluationStage.values) {
        expect(find.text(stage.label), findsWidgets, reason: stage.label);
      }
      expect(find.text('Passed'), findsOneWidget);
      expect(find.text('Pending'), findsNWidgets(4));
    });

    testWidgets('renders a joint inspection as one event with many offices', (
      tester,
    ) async {
      await _useTallSurface(tester);
      await tester.pumpWidget(
        _wrap(
          _application(
            inspection: InspectionRecord(
              scheduledAt: DateTime(2026, 8, 20, 9),
              offices: const [
                'Office of the Building Official',
                'Bureau of Fire Protection',
                'City Planning and Development Office',
              ],
              preparationChecklist: const ['Approved plans on site'],
            ),
          ),
        ),
      );
      await _settle(tester);

      expect(find.text('Inspection'), findsOneWidget);
      expect(find.text('Bureau of Fire Protection'), findsOneWidget);
      expect(find.text('Approved plans on site'), findsOneWidget);
    });
  });

  group('timeline', () {
    testWidgets('shows steps not yet reached rather than hiding them', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          _application(
            timeline: [
              TimelineEntry(
                status: ApplicationLifecycleStatus.submitted,
                occurredAt: _filed,
              ),
            ],
          ),
        ),
      );
      await _settle(tester);

      expect(find.text('Submitted'), findsWidgets);
      expect(find.text('Ready for Release'), findsWidgets);
      expect(find.text('Not yet reached'), findsWidgets);
    });

    testWidgets('a revision loop does not duplicate or reorder earlier steps', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          _application(
            timeline: [
              TimelineEntry(
                status: ApplicationLifecycleStatus.submitted,
                occurredAt: _filed,
              ),
              TimelineEntry(
                status: ApplicationLifecycleStatus.underEvaluation,
                occurredAt: _filed.add(const Duration(days: 1)),
              ),
              TimelineEntry(
                status: ApplicationLifecycleStatus.revisionRequired,
                occurredAt: _filed.add(const Duration(days: 2)),
                remarks: 'Structural plan lacks the engineer’s dry seal.',
              ),
              // Re-entered evaluation after the correction.
              TimelineEntry(
                status: ApplicationLifecycleStatus.underEvaluation,
                occurredAt: _filed.add(const Duration(days: 4)),
              ),
            ],
          ),
        ),
      );
      await _settle(tester);

      // Visited twice, rendered once.
      expect(find.text('Under Evaluation'), findsOneWidget);
      // The loop is shown as a branch, with the remark verbatim.
      expect(find.text('Returned for revision'), findsOneWidget);
      expect(
        find.text('Structural plan lacks the engineer’s dry seal.'),
        findsOneWidget,
      );
      // Order preserved: Submitted still precedes Under Evaluation.
      expect(
        tester.getTopLeft(find.text('Submitted').first).dy,
        lessThan(tester.getTopLeft(find.text('Under Evaluation')).dy),
      );
    });
  });

  group('letter of instruction', () {
    LetterOfInstruction letter() => LetterOfInstruction(
      id: 'loi-1',
      issuedAt: _filed.add(const Duration(days: 2)),
      issuedBy: 'Legal Evaluator',
      items: const [
        InstructionItem(
          id: 'i1',
          subject: 'Transfer Certificate of Title',
          remark: 'Submit a Certified True Copy issued within six months.',
        ),
        InstructionItem(
          id: 'i2',
          subject: 'Structural plan',
          remark: 'Must carry the dry seal of the civil engineer in charge.',
        ),
      ],
    );

    testWidgets('an open letter is always reachable from the detail', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(_application(instructions: [letter()])),
      );
      await _settle(tester);

      expect(find.text('Letter of Instruction outstanding'), findsOneWidget);
      expect(find.text('Open the letter'), findsOneWidget);

      await tester.tap(find.text('Open the letter'));
      await tester.pumpAndSettle();

      expect(find.text('What must be corrected'), findsOneWidget);
      expect(
        find.text('Submit a Certified True Copy issued within six months.'),
        findsOneWidget,
      );
    });

    testWidgets('resubmit stays disabled until every item is addressed', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          _application(instructions: [letter()]),
          initial: '/applications/app-1/instructions',
        ),
      );
      await _settle(tester);

      ElevatedButton resubmit() => tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Resubmit application'),
      );

      expect(resubmit().onPressed, isNull);
      expect(find.text('2 of 2 item(s) still outstanding.'), findsOneWidget);

      await tester.tap(find.text('Transfer Certificate of Title'));
      await tester.pumpAndSettle();
      expect(
        resubmit().onPressed,
        isNull,
        reason: 'one item resolved is not all items resolved',
      );

      await tester.tap(find.text('Structural plan'));
      await tester.pumpAndSettle();
      expect(resubmit().onPressed, isNotNull);
      expect(find.text('All items addressed. You can resubmit.'), findsOneWidget);
    });
  });

  group('permit', () {
    testWidgets('states the PD 1096 commencement deadline on its face', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          _application(
            lifecycleStatus: ApplicationLifecycleStatus.released,
            permit: GeneratedPermit(
              permitNumber: 'BP-2026-0001',
              issuedDate: DateTime(2026, 5, 4),
            ),
          ),
          initial: '/applications/app-1/permit',
        ),
      );
      await _settle(tester);

      expect(find.text('BP-2026-0001'), findsOneWidget);
      expect(find.text('Work must commence by May 4, 2027'), findsOneWidget);
      expect(find.textContaining('null and void'), findsOneWidget);
    });

    testWidgets('downloading makes the permit available offline', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          _application(
            lifecycleStatus: ApplicationLifecycleStatus.released,
            permit: GeneratedPermit(
              permitNumber: 'BP-2026-0001',
              issuedDate: DateTime(2026, 5, 4),
            ),
          ),
          initial: '/applications/app-1/permit',
        ),
      );
      await _settle(tester);

      expect(find.textContaining('Download to keep a copy'), findsOneWidget);

      await tester.tap(find.text('Download permit'));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Available without a connection'),
        findsOneWidget,
      );
      expect(find.text('Share a copy'), findsOneWidget);
    });
  });

  group('outcome', () {
    testWidgets('a rejection gives the verbatim reason and real options', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          _application(
            lifecycleStatus: ApplicationLifecycleStatus.rejected,
            evaluations: [
              EvaluationRecord(
                stage: EvaluationStage.obo,
                result: EvaluationResult.rejected,
                evaluator: 'Engr. R. Villanueva',
                evaluatedAt: _filed.add(const Duration(days: 5)),
                remarks:
                    'Proposed setback does not meet the minimum required for '
                    'this occupancy classification.',
              ),
            ],
          ),
          initial: '/applications/app-1/outcome',
        ),
      );
      await _settle(tester);

      expect(find.text('Not approved'), findsOneWidget);
      expect(
        find.textContaining('Proposed setback does not meet'),
        findsOneWidget,
      );
      expect(find.textContaining('Decided at the OBO stage'), findsOneWidget);
      expect(find.text('File again'), findsOneWidget);
      expect(find.text('Appeal to the Building Official'), findsOneWidget);
    });
  });
}
