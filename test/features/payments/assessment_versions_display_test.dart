import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ebpco_user_app/core/contract/admin_vocabulary.dart';
import 'package:ebpco_user_app/core/models/application_lineage.dart';
import 'package:ebpco_user_app/core/models/application_model.dart';
import 'package:ebpco_user_app/core/models/document_model.dart';
import 'package:ebpco_user_app/core/models/lifecycle_status.dart';
import 'package:ebpco_user_app/core/models/money.dart';
import 'package:ebpco_user_app/core/models/notification_event.dart';
import 'package:ebpco_user_app/core/models/order_of_payment.dart';
import 'package:ebpco_user_app/core/models/payment_assessment_model.dart';
import 'package:ebpco_user_app/core/providers/applications_provider.dart';
import 'package:ebpco_user_app/core/providers/notifications_provider.dart';
import 'package:ebpco_user_app/core/repositories/applications_repository.dart';
import 'package:ebpco_user_app/core/repositories/notifications_repository.dart';
import 'package:ebpco_user_app/core/theme/app_theme.dart';
import 'package:ebpco_user_app/features/payments/presentation/order_of_payment_screen.dart';

/// A reassessment as the applicant meets it.
///
/// The model tests prove the figures. This proves the screen says so — the
/// distinction that has mattered repeatedly in this sweep, where a suite has
/// passed on values the running app never produced.

class _Repo implements ApplicationsRepository {
  _Repo(this.applications);
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
    Map<String, Object?>? form,
  }) => throw UnimplementedError();
  @override
  Future<ApplicationModel> resubmitDocument(
    String applicationId, {
    required String documentId,
    required DocumentModel replacement,
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
  Future<ApplicationModel> advanceStatus(String id) =>
      throw UnimplementedError();
}

class _Notifs implements NotificationsRepository {
  @override
  Future<List<NotificationEvent>> fetchAll() async => const [];
}

OrderOfPayment _order({
  required int filing,
  required int version,
  AssessmentStatus status = AssessmentStatus.issued,
  String? revisionReason,
}) => OrderOfPayment(
  number: 'OP-2026-000$version',
  assessedAt: DateTime(2026, 8, version),
  fees: AssessmentFees(filing: filing),
  version: version,
  status: status,
  revisionReason: revisionReason,
);

ApplicationModel _application() => ApplicationModel(
  id: 'app-1',
  applicationNumber: 'E-BPCO-2026-000145',
  businessId: 'biz-1',
  businessName: 'Dela Cruz Construction',
  type: ApplicationType.newPermit,
  status: ApplicationStatus.paymentVerification,
  submittedDate: DateTime(2026, 8, 1),
  lifecycleStatus: ApplicationLifecycleStatus.assessed,
  payment: PaymentAssessmentModel(
    status: PaymentAssessmentStatus.pending,
    orderOfPayment: _order(
      filing: 320000,
      version: 2,
      revisionReason: 'Floor area corrected after evaluation.',
    ),
    supersededOrders: [
      _order(filing: 250000, version: 1, status: AssessmentStatus.superseded),
    ],
  ),
);

Future<void> _open(WidgetTester tester) async {
  tester.view.physicalSize = const Size(400, 3200);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final router = GoRouter(
    initialLocation: '/pay',
    routes: [
      GoRoute(
        path: '/pay',
        builder: (_, _) => const OrderOfPaymentScreen(applicationId: 'app-1'),
      ),
      GoRoute(path: '/:a', builder: (_, _) => const Scaffold()),
      GoRoute(path: '/:a/:b', builder: (_, _) => const Scaffold()),
    ],
  );

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<NotificationsProvider>(
          create: (_) => NotificationsProvider(repository: _Notifs()),
        ),
        ChangeNotifierProvider<ApplicationsProvider>(
          create: (context) => ApplicationsProvider(
            notifications: context.read<NotificationsProvider>(),
            repository: _Repo([_application()]),
          ),
        ),
      ],
      child: MaterialApp.router(
        theme: AppTheme.lightTheme,
        routerConfig: router,
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(seconds: 2));
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('says the assessment was replaced, and which one to pay', (
    tester,
  ) async {
    await _open(tester);

    expect(find.text('This assessment was reassessed'), findsOneWidget);
    expect(find.textContaining('version 2'), findsOneWidget);
    expect(find.textContaining('Pay against this one'), findsOneWidget);
  });

  testWidgets('gives the office\'s reason for the change', (tester) async {
    await _open(tester);
    expect(
      find.text('Floor area corrected after evaluation.'),
      findsOneWidget,
      reason: 'a total that changed without explanation reads as an app bug',
    );
  });

  testWidgets('keeps the superseded figure visible', (tester) async {
    await _open(tester);

    // The applicant was quoted ₱2,500.00 before. Being able to see that is
    // the difference between a correction and an unexplained change.
    expect(find.textContaining('v1'), findsOneWidget);
    expect(find.text(const PesoAmount(250000).formatted), findsWidgets);
  });
}
