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
import 'package:ebpco_user_app/core/models/order_of_payment.dart';
import 'package:ebpco_user_app/core/models/payment_assessment_model.dart';
import 'package:ebpco_user_app/core/providers/applications_provider.dart';
import 'package:ebpco_user_app/core/providers/notifications_provider.dart';
import 'package:ebpco_user_app/core/repositories/applications_repository.dart';
import 'package:ebpco_user_app/features/documents/presentation/widgets/attach_document_sheet.dart';
import 'package:ebpco_user_app/features/applications/presentation/building_permit/widgets/mock_upload.dart';
import 'package:ebpco_user_app/features/payments/presentation/order_of_payment_screen.dart';
import 'package:ebpco_user_app/features/payments/presentation/payments_screen.dart';

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
    String? permitTypeLabel,
    String? applicationNumber,
    ApplicationLineage? lineage,
    List<String> documentIds = const [],
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

OrderOfPayment _order() => OrderOfPayment(
  number: 'OP-2026-004821',
  assessedAt: DateTime(2026, 8, 10),
  assessedBy: 'Assessment Section, OBO',
  dueDate: DateTime(2026, 9, 9),
  fees: const AssessmentFees(
    filing: 50000,
    processing: 120000,
    architectural: 285050,
    structural: 341275,
    electrical: 96500,
    others: 42000,
  ),
);

ApplicationModel _application({
  String id = 'app-1',
  String number = 'E-BPCO-2026-000145',
  PaymentAssessmentModel? payment,
}) {
  return ApplicationModel(
    id: id,
    applicationNumber: number,
    businessId: 'biz-1',
    businessName: "Juan's General Merchandise",
    type: ApplicationType.newPermit,
    status: ApplicationStatus.paymentVerification,
    submittedDate: DateTime(2026, 8, 3),
    lifecycleStatus: ApplicationLifecycleStatus.assessed,
    permitTypeLabel: 'New Construction',
    payment: payment,
  );
}

Widget _wrap(List<ApplicationModel> applications, {String initial = '/pay'}) {
  final router = GoRouter(
    initialLocation: initial,
    routes: [
      GoRoute(path: '/payments', builder: (_, _) => const PaymentsScreen()),
      GoRoute(
        path: '/pay',
        builder: (_, _) => const OrderOfPaymentScreen(applicationId: 'app-1'),
      ),
      GoRoute(
        path: '/applications/:id/pay',
        builder: (_, _) => const OrderOfPaymentScreen(applicationId: 'app-1'),
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
          repository: _FakeRepository(applications),
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

Future<void> _tall(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(400, 3000));
  addTearDown(() => tester.binding.setSurfaceSize(null));
}

/// Picks a "Date paid", which the sheet has required since M-47.
///
/// The contract makes `paidOn` a required field of `PaymentProof` and the app
/// had no field for it anywhere, so closing that gap needed a question added
/// to the flow rather than a key added to a body.
Future<void> _pickPaidOn(WidgetTester tester) async {
  await tester.tap(find.text('Date paid *'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('OK'));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    debugAttachDocumentOverride = (context, {required label}) async =>
        createMockDocument(label);
  });
  tearDown(() => debugAttachDocumentOverride = null);

  group('Order of Payment', () {
    testWidgets('itemises every fee and totals them exactly', (tester) async {
      await _tall(tester);
      await tester.pumpWidget(
        _wrap([
          _application(
            payment: PaymentAssessmentModel(
              status: PaymentAssessmentStatus.notYetAvailable,
              orderOfPayment: _order(),
            ),
          ),
        ]),
      );
      await _settle(tester);

      expect(find.text('O.P. No. OP-2026-004821'), findsOneWidget);
      expect(find.text('Filing fee'), findsOneWidget);
      expect(find.text('PHP 500.00'), findsOneWidget);
      expect(find.text('Civil / structural fee'), findsOneWidget);
      expect(find.text('PHP 3,412.75'), findsOneWidget);
      // 500.00 + 1,200.00 + 2,850.50 + 3,412.75 + 965.00 + 420.00
      expect(find.text('PHP 9,348.25'), findsOneWidget);
      expect(find.textContaining('Pay on or before'), findsOneWidget);
    });

    testWidgets('a fee explains itself on demand', (tester) async {
      await _tall(tester);
      await tester.pumpWidget(
        _wrap([
          _application(
            payment: PaymentAssessmentModel(
              status: PaymentAssessmentStatus.notYetAvailable,
              orderOfPayment: _order(),
            ),
          ),
        ]),
      );
      await _settle(tester);

      expect(find.textContaining('accepts your application'), findsNothing);
      await tester.tap(find.text('Filing fee'));
      await tester.pumpAndSettle();
      expect(find.textContaining('accepts your application'), findsOneWidget);
    });

    testWidgets('shows no amount at all when nothing has been assessed', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap([
          _application(
            payment: const PaymentAssessmentModel(
              status: PaymentAssessmentStatus.notYetAvailable,
            ),
          ),
        ]),
      );
      await _settle(tester);

      expect(find.text('Not yet available'), findsOneWidget);
      expect(find.textContaining('PHP'), findsNothing);
      // And no way to pay something that has not been assessed.
      expect(find.text('Submit proof of payment'), findsNothing);
    });

    testWidgets('offers only the two channels the LGU accepts', (tester) async {
      await _tall(tester);
      await tester.pumpWidget(
        _wrap([
          _application(
            payment: PaymentAssessmentModel(
              status: PaymentAssessmentStatus.notYetAvailable,
              orderOfPayment: _order(),
            ),
          ),
        ]),
      );
      await _settle(tester);

      expect(find.text('Bank Transfer'), findsOneWidget);
      expect(find.text('Onsite'), findsOneWidget);
      for (final unaccepted in ['GCash', 'Maya', 'Credit Card', 'PayPal']) {
        expect(find.text(unaccepted), findsNothing, reason: unaccepted);
      }
    });

    testWidgets('an overdue assessment says what is at stake', (tester) async {
      await _tall(tester);
      await tester.pumpWidget(
        _wrap([
          _application(
            payment: PaymentAssessmentModel(
              status: PaymentAssessmentStatus.overdue,
              orderOfPayment: _order(),
            ),
          ),
        ]),
      );
      await _settle(tester);

      expect(find.text('Overdue'), findsOneWidget);
      expect(find.textContaining('may lapse'), findsOneWidget);
      expect(find.text('Submit proof of payment'), findsOneWidget);
    });

    testWidgets('a verified payment shows its official receipt', (
      tester,
    ) async {
      await _tall(tester);
      await tester.pumpWidget(
        _wrap([
          _application(
            payment: PaymentAssessmentModel(
              status: PaymentAssessmentStatus.paid,
              orderOfPayment: _order(),
              officialReceiptNumber: 'OR-8891234',
              verifiedAt: DateTime(2026, 8, 15),
              referenceNumber: 'BT-99881',
            ),
          ),
        ]),
      );
      await _settle(tester);

      expect(find.text('Paid'), findsOneWidget);
      expect(find.textContaining('OR-8891234'), findsOneWidget);
      // Nothing left to pay, so no payment actions.
      expect(find.text('Submit proof of payment'), findsNothing);
    });
  });

  group('proof of payment', () {
    testWidgets('requires a reference number, a date and an attachment', (
      tester,
    ) async {
      await _tall(tester);
      await tester.pumpWidget(
        _wrap([
          _application(
            payment: PaymentAssessmentModel(
              status: PaymentAssessmentStatus.notYetAvailable,
              orderOfPayment: _order(),
            ),
          ),
        ]),
      );
      await _settle(tester);

      await tester.tap(find.text('Submit proof of payment'));
      await tester.pumpAndSettle();

      ElevatedButton submit() => tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Submit for verification'),
      );

      expect(submit().onPressed, isNull);

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Bank reference number *'),
        'BT-99881',
      );
      await tester.pumpAndSettle();
      expect(
        submit().onPressed,
        isNull,
        reason: 'a reference with no receipt cannot be verified',
      );

      await tester.tap(find.widgetWithText(OutlinedButton, 'Upload'));
      await tester.pumpAndSettle();
      expect(
        submit().onPressed,
        isNull,
        reason:
            'the Treasurer\'s Office reconciles against the date the money '
            'moved, and the server requires it',
      );

      await _pickPaidOn(tester);
      expect(submit().onPressed, isNotNull);
    });

    testWidgets('submitting moves the record to Pending Verification', (
      tester,
    ) async {
      await _tall(tester);
      await tester.pumpWidget(
        _wrap([
          _application(
            payment: PaymentAssessmentModel(
              status: PaymentAssessmentStatus.notYetAvailable,
              orderOfPayment: _order(),
            ),
          ),
        ]),
      );
      await _settle(tester);

      await tester.tap(find.text('Submit proof of payment'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Bank reference number *'),
        'BT-99881',
      );
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(OutlinedButton, 'Upload'));
      await tester.pumpAndSettle();
      await _pickPaidOn(tester);
      await tester.tap(find.text('Submit for verification'));
      await tester.pumpAndSettle();

      // The applicant reports paying; only the Treasurer's Office marks Paid.
      expect(find.text('Pending Verification'), findsOneWidget);
      expect(find.textContaining('BT-99881'), findsOneWidget);
      expect(find.text('Paid'), findsNothing);
    });
  });

  group('payments list', () {
    testWidgets('groups by obligation and pins the total due', (tester) async {
      await _tall(tester);
      await tester.pumpWidget(
        _wrap([
          _application(
            payment: PaymentAssessmentModel(
              status: PaymentAssessmentStatus.notYetAvailable,
              orderOfPayment: _order(),
            ),
          ),
          _application(
            id: 'app-2',
            number: 'E-BPCO-2026-000146',
            payment: PaymentAssessmentModel(
              status: PaymentAssessmentStatus.pending,
              orderOfPayment: _order(),
            ),
          ),
          _application(
            id: 'app-3',
            number: 'E-BPCO-2026-000147',
            payment: PaymentAssessmentModel(
              status: PaymentAssessmentStatus.paid,
              orderOfPayment: _order(),
            ),
          ),
        ], initial: '/payments'),
      );
      await _settle(tester);

      expect(find.text('Due Now (1)'), findsOneWidget);
      expect(find.text('Awaiting Verification (1)'), findsOneWidget);
      expect(find.text('Paid (1)'), findsOneWidget);
      // Only what is actually due is totalled.
      expect(find.text('Total due'), findsOneWidget);
      expect(find.text('PHP 9,348.25'), findsWidgets);
    });

    testWidgets('unassessed applications are not listed', (tester) async {
      await tester.pumpWidget(
        _wrap([
          _application(
            payment: const PaymentAssessmentModel(
              status: PaymentAssessmentStatus.notYetAvailable,
            ),
          ),
        ], initial: '/payments'),
      );
      await _settle(tester);

      expect(find.text('Nothing to pay yet'), findsOneWidget);
      expect(find.textContaining('PHP'), findsNothing);
    });
  });
}
