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
import 'package:ebpco_user_app/core/models/notification_event.dart';
import 'package:ebpco_user_app/core/models/order_of_payment.dart';
import 'package:ebpco_user_app/core/models/payment_assessment_model.dart';
import 'package:ebpco_user_app/core/models/permit_classification.dart';
import 'package:ebpco_user_app/core/models/professional_model.dart';
import 'package:ebpco_user_app/core/providers/applications_provider.dart';
import 'package:ebpco_user_app/core/providers/documents_provider.dart';
import 'package:ebpco_user_app/core/providers/notifications_provider.dart';
import 'package:ebpco_user_app/core/providers/professionals_provider.dart';
import 'package:ebpco_user_app/core/repositories/applications_repository.dart';
import 'package:ebpco_user_app/core/repositories/notifications_repository.dart';
import 'package:ebpco_user_app/core/theme/app_theme.dart';
import 'package:ebpco_user_app/features/applications/presentation/application_list_screen.dart';
import 'package:ebpco_user_app/features/applications/presentation/detail/application_detail_screen.dart';
import 'package:ebpco_user_app/features/applications/presentation/pre_flight_screen.dart';
import 'package:ebpco_user_app/features/payments/presentation/order_of_payment_screen.dart';
import 'package:ebpco_user_app/features/payments/presentation/payment_history_screen.dart';
import 'package:ebpco_user_app/features/profile/presentation/privacy_data_screen.dart';
import 'package:ebpco_user_app/features/profile/presentation/professionals_screen.dart';

import 'support/clipping.dart';

import 'support/wizard_providers.dart';

/// The seven screens the accessibility suites did not reach. The shared-widget
/// suite covers their building blocks; this covers the composition, which is
/// where both overflows found so far actually lived.
///
/// Content is deliberately the demanding end of realistic: the longest permit
/// name, a business with a comma in it, an evaluator's remark of the length
/// they actually write.

const _longBusiness = "Juan Dela Cruz General Merchandise, Incorporated";
const _longPermit = 'Sanitary / Plumbing';
const _longRemark =
    'The structural plan submitted does not carry the dry seal of the civil '
    'engineer in charge, and the bill of materials omits the reinforcing '
    'steel schedule required for the second floor slab.';

class _Applications implements ApplicationsRepository {
  _Applications(this.applications);
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
  }) async => throw UnimplementedError();

  @override
  Future<ApplicationModel> advanceStatus(String applicationId) =>
      throw UnimplementedError();
}

class _Notifications implements NotificationsRepository {
  @override
  Future<List<NotificationEvent>> fetchAll() async => const [];
}

final _now = DateTime(2026, 8, 19);

ApplicationModel _application() => ApplicationModel(
  id: 'app-1',
  applicationNumber: 'E-BPCO-2026-000145',
  businessId: 'biz-1',
  businessName: _longBusiness,
  type: ApplicationType.newPermit,
  status: ApplicationStatus.paymentVerification,
  submittedDate: DateTime(2026, 8, 3),
  lifecycleStatus: ApplicationLifecycleStatus.assessed,
  classification: PermitClassification.highlyTechnical,
  permitTypeLabel: _longPermit,
  openInstructionCount: 2,
  evaluations: [
    EvaluationRecord(
      stage: EvaluationStage.obo,
      result: EvaluationResult.revisionRequired,
      evaluator: 'Engr. R. Villanueva',
      evaluatedAt: DateTime(2026, 8, 10),
      remarks: _longRemark,
    ),
  ],
  instructions: [
    LetterOfInstruction(
      id: 'loi-1',
      issuedAt: DateTime(2026, 8, 10),
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
          remark: _longRemark,
        ),
      ],
    ),
  ],
  timeline: [
    TimelineEntry(
      status: ApplicationLifecycleStatus.submitted,
      occurredAt: DateTime(2026, 8, 3),
      office: 'Office of the Building Official',
    ),
  ],
  payment: PaymentAssessmentModel(
    status: PaymentAssessmentStatus.notYetAvailable,
    orderOfPayment: OrderOfPayment(
      number: 'OP-2026-004821',
      assessedAt: DateTime(2026, 8, 12),
      assessedBy: 'Assessment Section, Office of the Building Official',
      dueDate: DateTime(2026, 9, 11),
      fees: const AssessmentFees(
        filing: 50000,
        processing: 120000,
        architectural: 285050,
        structural: 341275,
        electrical: 96500,
        others: 42000,
      ),
    ),
  ),
);

ProfessionalModel _professional() => ProfessionalModel(
  id: 'pro-1',
  fullName: 'Engr. Maria Concepcion Santos-Villanueva',
  discipline: ProfessionalDiscipline.electronicsEngineer,
  prcNumber: 'PRC-0000001',
  prcValidityDate: DateTime(2026, 10, 1),
  ptrNumber: 'PTR-0000001',
  ptrDateIssued: DateTime(2025, 1, 10),
  ptrPlaceIssued: 'Quezon City',
);

Widget _host(String initial, double textScale) {
  final router = GoRouter(
    initialLocation: initial,
    routes: [
      GoRoute(path: '/list', builder: (_, _) => const ApplicationListScreen()),
      GoRoute(
        path: '/detail',
        builder: (_, _) =>
            const ApplicationDetailScreen(applicationId: 'app-1'),
      ),
      GoRoute(
        path: '/pay',
        builder: (_, _) => const OrderOfPaymentScreen(applicationId: 'app-1'),
      ),
      GoRoute(
        path: '/history',
        builder: (_, _) => const PaymentHistoryScreen(),
      ),
      GoRoute(path: '/pros', builder: (_, _) => const ProfessionalsScreen()),
      GoRoute(path: '/privacy', builder: (_, _) => const PrivacyDataScreen()),
      GoRoute(
        path: '/preflight',
        builder: (_, _) => const PreFlightScreen(
          permitType: 'Certificate of Occupancy',
          wizardRoute: '/list',
        ),
      ),
      GoRoute(path: '/applications/:id', builder: (_, _) => const Scaffold()),
      GoRoute(
        path: '/applications/:id/pay',
        builder: (_, _) => const Scaffold(),
      ),
      GoRoute(path: '/applications/new', builder: (_, _) => const Scaffold()),
      GoRoute(path: '/charter/:t', builder: (_, _) => const Scaffold()),
      GoRoute(path: '/profile/documents', builder: (_, _) => const Scaffold()),
    ],
  );

  return MultiProvider(
    providers: [
      ChangeNotifierProvider<NotificationsProvider>(
        create: (_) => NotificationsProvider(
          repository: _Notifications(),
          clock: () => _now,
        ),
      ),
      ChangeNotifierProvider<ApplicationsProvider>(
        create: (context) => ApplicationsProvider(
          notifications: context.read<NotificationsProvider>(),
          repository: _Applications([_application()]),
          clock: () => _now,
        ),
      ),
      ChangeNotifierProvider<ProfessionalsProvider>(
        create: (_) => ProfessionalsProvider(
          professionals: [_professional()],
          representatives: const [
            AuthorizedRepresentative(
              id: 'rep-1',
              fullName: 'Pedro Santos-Villanueva',
              relationship: 'Brother-in-law',
            ),
          ],
          clock: () => _now,
        ),
      ),
      ChangeNotifierProvider<DocumentsProvider>(
        create: (_) => DocumentsProvider(),
      ),
      // Everything DraftRegistry looks up, for the Drafts segment.
      ...wizardProviders(),
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

const _screens = {
  'ApplicationList': '/list',
  'ApplicationDetail': '/detail',
  'OrderOfPayment': '/pay',
  'PaymentHistory': '/history',
  'Professionals': '/pros',
  'PrivacyData': '/privacy',
  'PreFlight': '/preflight',
};

Future<void> _open(
  WidgetTester tester,
  String route, {
  required double textScale,
  double width = 360,
  double height = 2600,
}) async {
  tester.view.physicalSize = Size(width, height);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(_host(route, textScale));
  await tester.pump();
  await tester.pump(const Duration(seconds: 3));
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('render without overflowing at 100%', () {
    _screens.forEach((name, route) {
      testWidgets(name, (tester) async {
        await _open(tester, route, textScale: 1.0);
        expect(tester.takeException(), isNull);
      });
    });
  });

  group('render without overflowing at 200% text scale', () {
    _screens.forEach((name, route) {
      testWidgets(name, (tester) async {
        await _open(tester, route, textScale: 2.0);
        expect(tester.takeException(), isNull);
      });
    });
  });

  group('render without overflowing at 320dp', () {
    _screens.forEach((name, route) {
      testWidgets(name, (tester) async {
        await _open(tester, route, textScale: 1.0, width: 320);
        expect(tester.takeException(), isNull);
      });
    });
  });

  group('controls meet the 48dp floor', () {
    _screens.forEach((name, route) {
      testWidgets(name, (tester) async {
        await _open(tester, route, textScale: 1.0);

        for (final button in find.byType(IconButton).evaluate()) {
          final size = tester.getSize(find.byWidget(button.widget));
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
