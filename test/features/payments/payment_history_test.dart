import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ebpco_user_app/core/repositories/notifications_repository.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ebpco_user_app/core/models/application_model.dart';
import 'package:ebpco_user_app/core/models/document_model.dart';
import 'package:ebpco_user_app/core/models/lifecycle_status.dart';
import 'package:ebpco_user_app/core/models/order_of_payment.dart';
import 'package:ebpco_user_app/core/models/payment_assessment_model.dart';
import 'package:ebpco_user_app/core/models/payment_history.dart';
import 'package:ebpco_user_app/core/providers/applications_provider.dart';
import 'package:ebpco_user_app/core/providers/notifications_provider.dart';
import 'package:ebpco_user_app/core/repositories/applications_repository.dart';
import 'package:ebpco_user_app/core/theme/app_theme.dart';
import 'package:ebpco_user_app/features/payments/presentation/payment_history_screen.dart';

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

ApplicationModel _application({
  required String id,
  required String business,
  required String businessId,
  required DateTime assessedAt,
  required int centavos,
  PaymentAssessmentStatus status = PaymentAssessmentStatus.paid,
  String permitType = 'New Construction',
  String? orNumber,
  bool assessed = true,
}) => ApplicationModel(
  id: id,
  applicationNumber: 'E-BPCO-${assessedAt.year}-$id',
  businessId: businessId,
  businessName: business,
  type: ApplicationType.newPermit,
  status: ApplicationStatus.paymentVerification,
  submittedDate: assessedAt,
  lifecycleStatus: ApplicationLifecycleStatus.assessed,
  permitTypeLabel: permitType,
  payment: assessed
      ? PaymentAssessmentModel(
          status: status,
          officialReceiptNumber: orNumber,
          orderOfPayment: OrderOfPayment(
            number: 'OP-$id',
            assessedAt: assessedAt,
            fees: AssessmentFees(filing: centavos),
          ),
        )
      : null,
);

Widget _wrap(List<ApplicationModel> applications) {
  final router = GoRouter(
    initialLocation: '/history',
    routes: [
      GoRoute(path: '/history', builder: (_, _) => const PaymentHistoryScreen()),
      GoRoute(
        path: '/applications/:id/pay',
        builder: (_, _) => const Scaffold(),
      ),
    ],
  );

  return MultiProvider(
    providers: [
      ChangeNotifierProvider<NotificationsProvider>(
        create: (_) => NotificationsProvider(repository: MockNotificationsRepository()),
      ),
      ChangeNotifierProvider<ApplicationsProvider>(
        create: (context) => ApplicationsProvider(
          notifications: context.read<NotificationsProvider>(),
          repository: _FakeRepository(applications),
          clock: () => DateTime(2026, 8, 18),
        ),
      ),
    ],
    child: MaterialApp.router(
      theme: AppTheme.lightTheme,
      routerConfig: router,
    ),
  );
}

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(seconds: 3));
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('building the history', () {
    test('flattens assessed applications into transactions, newest first', () {
      final entries = PaymentHistoryEntry.from([
        _application(
          id: 'a',
          business: 'Juan Merchandise',
          businessId: 'biz-1',
          assessedAt: DateTime(2025, 3, 2),
          centavos: 100000,
        ),
        _application(
          id: 'b',
          business: 'Juan Merchandise',
          businessId: 'biz-1',
          assessedAt: DateTime(2026, 5, 4),
          centavos: 250000,
        ),
      ]);

      expect(entries.map((e) => e.orderOfPaymentNumber).toList(), [
        'OP-b',
        'OP-a',
      ]);
    });

    test('skips applications with no Order of Payment', () {
      // Listing one with a blank amount would imply a charge that does not
      // exist.
      final entries = PaymentHistoryEntry.from([
        _application(
          id: 'a',
          business: 'Juan Merchandise',
          businessId: 'biz-1',
          assessedAt: DateTime(2026, 5, 4),
          centavos: 0,
          assessed: false,
        ),
      ]);

      expect(entries, isEmpty);
    });
  });

  group('CSV export', () {
    final entries = PaymentHistoryEntry.from([
      _application(
        id: 'a',
        business: 'Juan Merchandise, Inc.',
        businessId: 'biz-1',
        assessedAt: DateTime(2026, 5, 4),
        centavos: 934825,
        orNumber: 'OR-8891234',
      ),
    ]);

    test('quotes a value containing a comma', () {
      // "Juan Merchandise, Inc." unquoted would shift every later column.
      final csv = PaymentHistoryCsv.render(
        entries,
        generatedAt: DateTime(2026, 8, 18),
      );

      expect(csv, contains('"Juan Merchandise, Inc."'));
    });

    test('writes the amount as a bare decimal a spreadsheet can sum', () {
      final csv = PaymentHistoryCsv.render(
        entries,
        generatedAt: DateTime(2026, 8, 18),
      );

      expect(csv, contains('9348.25'));
      expect(csv, isNot(contains('PHP 9,348.25')));
    });

    test('says it is not an official receipt', () {
      final csv = PaymentHistoryCsv.render(
        entries,
        generatedAt: DateTime(2026, 8, 18),
      );

      // A printed copy must not be mistakable for something the LGU issued.
      expect(csv, contains('Not an official receipt'));
    });

    test('has a header row and one row per transaction', () {
      final csv = PaymentHistoryCsv.render(
        entries,
        generatedAt: DateTime(2026, 8, 18),
      );
      final lines = csv.trim().split('\n');

      expect(lines.first, startsWith('#'));
      expect(lines[1], startsWith('Assessed,Business,Permit type'));
      expect(lines, hasLength(3));
    });
  });

  group('screen', () {
    final applications = [
      _application(
        id: 'a',
        business: 'Juan Merchandise',
        businessId: 'biz-1',
        assessedAt: DateTime(2025, 3, 2),
        centavos: 100000,
      ),
      _application(
        id: 'b',
        business: 'Juan Merchandise',
        businessId: 'biz-1',
        assessedAt: DateTime(2026, 5, 4),
        centavos: 250000,
      ),
      _application(
        id: 'c',
        business: 'Santos Hardware',
        businessId: 'biz-2',
        assessedAt: DateTime(2026, 6, 1),
        centavos: 500000,
        status: PaymentAssessmentStatus.notYetAvailable,
        permitType: 'Electrical',
      ),
    ];

    testWidgets('lists every transaction across applications', (tester) async {
      await tester.pumpWidget(_wrap(applications));
      await _settle(tester);

      expect(find.text('PHP 1,000.00'), findsOneWidget);
      expect(find.text('PHP 2,500.00'), findsOneWidget);
      expect(find.text('PHP 5,000.00'), findsOneWidget);
    });

    testWidgets('totals only what has actually been paid', (tester) async {
      await tester.pumpWidget(_wrap(applications));
      await _settle(tester);

      // 1,000 + 2,500 verified; the 5,000 is assessed but unpaid, and
      // counting it would overstate what the applicant has spent.
      expect(find.text('PHP 3,500.00'), findsOneWidget);
      expect(find.text('2 verified payments'), findsOneWidget);
    });

    testWidgets('filters by year', (tester) async {
      await tester.pumpWidget(_wrap(applications));
      await _settle(tester);

      await tester.tap(find.text('All years'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('2025').last);
      await tester.pumpAndSettle();

      // The remaining row and the total are both 1,000, so both match.
      expect(find.text('PHP 1,000.00'), findsNWidgets(2));
      expect(find.text('PHP 2,500.00'), findsNothing);
      expect(find.text('1 verified payment'), findsOneWidget);
    });

    testWidgets('filters by business', (tester) async {
      await tester.pumpWidget(_wrap(applications));
      await _settle(tester);

      await tester.tap(find.text('All'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Santos Hardware').last);
      await tester.pumpAndSettle();

      expect(find.text('PHP 5,000.00'), findsOneWidget);
      expect(find.text('PHP 1,000.00'), findsNothing);
    });

    testWidgets('exports the current selection to the clipboard', (
      tester,
    ) async {
      final copied = <String>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            copied.add((call.arguments as Map)['text'] as String);
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );

      await tester.pumpWidget(_wrap(applications));
      await _settle(tester);

      await tester.tap(find.byTooltip('Export as CSV'));
      await tester.pumpAndSettle();

      expect(copied, hasLength(1));
      expect(copied.single, contains('Juan Merchandise'));
      expect(copied.single, contains('Santos Hardware'));
      expect(find.textContaining('copied as CSV'), findsOneWidget);
    });

    testWidgets('an applicant with no assessments sees why, not a blank', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(const []));
      await _settle(tester);

      expect(find.text('No payments yet'), findsOneWidget);
      // IconButton contains the Tooltip, not the other way round, so find the
      // button by its icon rather than through the tooltip.
      final exportButton = tester.widget<IconButton>(
        find.widgetWithIcon(IconButton, Icons.ios_share),
      );
      expect(
        exportButton.onPressed,
        isNull,
        reason: 'there is nothing to export',
      );
    });
  });
}
