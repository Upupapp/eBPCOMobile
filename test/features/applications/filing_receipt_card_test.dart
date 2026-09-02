import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:ebpco_user_app/core/models/application_model.dart';
import 'package:ebpco_user_app/core/models/document_model.dart';
import 'package:ebpco_user_app/core/models/filing_receipt.dart';
import 'package:ebpco_user_app/core/providers/applications_provider.dart';
import 'package:ebpco_user_app/core/providers/notifications_provider.dart';
import 'package:ebpco_user_app/core/repositories/applications_repository.dart';
import 'package:ebpco_user_app/core/repositories/notifications_repository.dart';
import 'package:ebpco_user_app/features/applications/presentation/widgets/application_submitted_view.dart';
import 'package:ebpco_user_app/features/applications/presentation/widgets/filing_receipt_card.dart';

/// What the citizen can read off the screen.

FilingReceipt _receipt({
  int offered = 2,
  List<String> issued = const ['a', 'b'],
  int answers = 12,
  String? location = 'Lot 4, Bagalayag, Castilla',
}) => FilingReceipt(
  applicationId: 'app-1',
  referenceNumber: 'E-BPCO-2026-000005',
  permitType: 'Demolition Permit',
  submittedAt: DateTime(2026, 9, 2),
  location: location,
  attachmentsOffered: offered,
  documentIdsIssued: issued,
  answersSent: answers,
);

Future<void> _pump(WidgetTester tester, FilingReceipt receipt) async {
  await tester.binding.setSurfaceSize(const Size(400, 1200));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(child: FilingReceiptCard(receipt: receipt)),
      ),
    ),
  );
}

void main() {
  testWidgets('a complete filing shows the site, the files and the answers', (
    tester,
  ) async {
    await _pump(tester, _receipt());

    expect(find.text('Lot 4, Bagalayag, Castilla'), findsOneWidget);
    expect(find.text('2 of 2'), findsOneWidget);
    expect(find.text('12'), findsOneWidget);
    expect(find.textContaining('did not receive'), findsNothing);
  });

  testWidgets('a filing the office received no files for says so', (
    tester,
  ) async {
    // The defect this card exists for. Every other screen in the app calls
    // this a completed submission, and each of them is telling the truth
    // about what it knows.
    await _pump(tester, _receipt(offered: 2, issued: const []));

    expect(find.text('0 of 2'), findsOneWidget);
    expect(
      find.textContaining('The office did not receive 2 of your files'),
      findsOneWidget,
    );
  });

  testWidgets('a filing carrying no answers warns rather than showing 0', (
    tester,
  ) async {
    await _pump(tester, _receipt(answers: 0));

    expect(
      find.textContaining('None of what you typed reached the office'),
      findsOneWidget,
    );
  });

  testWidgets('a clearance with no site of its own omits the row', (
    tester,
  ) async {
    // The two BFP clearances attach to a building permit that carries the
    // address. An empty Site row would read as a filing that lost it.
    await _pump(tester, _receipt(location: null));

    expect(find.text('Site on record'), findsNothing);
    expect(find.text('Attachments held'), findsOneWidget);
  });

  testWidgets('the card says who confirmed the numbers', (tester) async {
    await _pump(tester, _receipt());
    expect(
      find.textContaining('Confirmed by the office, not by this app'),
      findsOneWidget,
    );
  });

  testWidgets('the confirmation screen shows the receipt for what it filed', (
    tester,
  ) async {
    // The wiring, not the pieces. The view resolves the receipt through a
    // defensive lookup that treats a missing provider as "no receipt" — which
    // is right, and is also exactly how this feature would disappear without
    // one test failing. So: a real provider, a real filing, and the numbers
    // read off the rendered screen.
    tester.view.physicalSize = const Size(400, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    // Built and filed inside runAsync. The mock repositories wait on real
    // timers, and a bare `await` in a widget test hands them to fake async,
    // where nothing ever completes them — the test does not fail, it hangs.
    late final ApplicationsProvider provider;
    late final ApplicationModel filed;
    await tester.runAsync(() async {
      provider = ApplicationsProvider(
        notifications: NotificationsProvider(
          repository: MockNotificationsRepository(),
        ),
        repository: MockApplicationsRepository(),
      );
      await Future.delayed(const Duration(milliseconds: 1200));
      filed = await provider.submitApplication(
        businessId: '',
        businessName: 'Juan dela Cruz',
        type: ApplicationType.newPermit,
        documents: [
          DocumentModel(
            id: 'lot-plan',
            label: 'Lot Plan',
            fileName: 'lot-plan.pdf',
            uploadedAt: DateTime(2026, 9, 2),
            filePath: '/tmp/lot-plan.pdf',
          ),
        ],
        permitTypeLabel: 'Demolition Permit',
        location: 'Lot 4, Bagalayag, Castilla',
        form: {'applicant.name': 'Juan', 'site.barangay': 'Bagalayag'},
      );
    });

    await tester.pumpWidget(
      ChangeNotifierProvider<ApplicationsProvider>.value(
        value: provider,
        child: MaterialApp.router(
          routerConfig: GoRouter(
            routes: [
              GoRoute(
                path: '/',
                builder: (_, _) => ApplicationSubmittedView(
                  headline: 'Demolition Application Submitted!',
                  body: 'Your application has been submitted.',
                  referenceNumber: filed.applicationNumber,
                  submissionDate: filed.submittedDate,
                  facts: const [],
                  applicationId: filed.id,
                  primaryLabel: 'Return to Applications',
                  primaryRoute: '/app/applications',
                ),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 2));

    expect(find.text('What the office received'), findsOneWidget);
    expect(find.text('Lot 4, Bagalayag, Castilla'), findsOneWidget);
    expect(
      find.text('0 of 1'),
      findsOneWidget,
      reason:
          'this build has no upload repository, so the office holds none of '
          'the one file attached — and the screen has to say so',
    );
    expect(find.text('2'), findsOneWidget);
  });
}
