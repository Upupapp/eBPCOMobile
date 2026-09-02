import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:ebpco_user_app/core/providers/auth_provider.dart';
import 'package:ebpco_user_app/core/providers/fencing_permit_provider.dart';
import 'package:ebpco_user_app/features/applications/presentation/fencing_permit/fencing_application_submitted_screen.dart';
import 'package:ebpco_user_app/features/applications/presentation/fencing_permit/fencing_permit_wizard_screen.dart';
import 'package:ebpco_user_app/features/applications/presentation/building_permit/widgets/mock_upload.dart';
import 'package:ebpco_user_app/features/documents/presentation/widgets/attach_document_sheet.dart';
import 'package:ebpco_user_app/core/repositories/notifications_repository.dart';
import 'package:ebpco_user_app/core/repositories/applications_repository.dart';
import 'package:ebpco_user_app/core/providers/notifications_provider.dart';
import 'package:ebpco_user_app/core/sync/offline_queue.dart';
import 'package:ebpco_user_app/core/sync/sync_provider.dart';
import 'package:ebpco_user_app/core/providers/applications_provider.dart';
import 'package:ebpco_user_app/features/applications/presentation/application_list_screen.dart';
import 'package:ebpco_user_app/core/models/notification_event.dart';

import '../../../support/wizard_providers.dart';
import 'package:ebpco_user_app/shared/widgets/uploads/document_upload_tile.dart';

/// End-to-end coverage of the Fencing Permit wizard — fully separate from
/// every other permit wizard in this app, driven the same way those
/// wizards' tests drive them. Unlike other permits' Professionals step,
/// this permit's Design Professional (Step 5) and Supervisor (Step 6) are
/// two separate wizard pages, so their field labels never collide within
/// a single screen (except in Step 7, where the Applicant and Lot Owner
/// sections can be visible together).
Widget _wrap() {
  final router = GoRouter(
    initialLocation: '/back',
    routes: [
      GoRoute(
        path: '/back',
        builder: (context, state) => Scaffold(
          body: Center(
            child: TextButton(
              onPressed: () => context.push('/wizard'),
              child: const Text('Back Screen'),
            ),
          ),
        ),
      ),
      GoRoute(
        path: '/wizard',
        builder: (context, state) => const FencingPermitWizardScreen(),
      ),
      GoRoute(
        path: '/applications/new/fencing-permit/submitted',
        builder: (context, state) {
          final extra = state.extra as Map<String, Object?>?;
          return FencingApplicationSubmittedScreen(
            applicationId: extra?['applicationId'] as String?,
            referenceNumber: extra?['referenceNumber'] as String? ?? 'FNC-X',
            submissionDate:
                extra?['submissionDate'] as DateTime? ?? DateTime.now(),
            relatedBuildingPermitNumber:
                extra?['relatedBuildingPermitNumber'] as String? ?? '',
            relatedBuildingPermitStatus:
                extra?['relatedBuildingPermitStatus'] as String? ?? 'Pending',
          );
        },
      ),
      // The two destinations the confirmation screen's buttons actually use.
      // Registering the real screen, rather than a stub, is what makes the
      // end-to-end assertion below mean anything.
      GoRoute(
        path: '/app/applications',
        builder: (context, state) => const ApplicationListScreen(),
      ),
      GoRoute(
        path: '/applications/:id',
        builder: (context, state) =>
            Scaffold(body: Text('detail:${state.pathParameters['id']}')),
      ),
    ],
  );
  return MultiProvider(
    providers: [
      // The applications list shows the pending-work banner, which reads the
      // offline queue through SyncProvider.
      ChangeNotifierProvider<SyncProvider>(
        create: (_) => SyncProvider(queue: OfflineQueue(InMemoryQueueStore())),
      ),
      ChangeNotifierProvider<NotificationsProvider>(
        create: (_) =>
            NotificationsProvider(repository: MockNotificationsRepository()),
      ),
      // The wizard now records the submission as a real application, so the
      // provider that holds them has to be here.
      ChangeNotifierProvider<ApplicationsProvider>(
        create: (context) => ApplicationsProvider(
          notifications: context.read<NotificationsProvider>(),
          repository: MockApplicationsRepository(),
        ),
      ),
      ChangeNotifierProvider<AuthProvider>(create: (_) => AuthProvider()),
      ChangeNotifierProvider<FencingPermitProvider>(
        create: (_) => FencingPermitProvider(),
      ),
      // Everything DraftRegistry looks up, for the Drafts segment.
      ...wizardProviders(),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

Finder _continueButton() => find.widgetWithText(ElevatedButton, 'Continue');
Finder _submitButton() =>
    find.widgetWithText(ElevatedButton, 'Submit Application');

Future<void> _useTallSurface(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(400, 8000));
  addTearDown(() => tester.binding.setSurfaceSize(null));
}

Future<void> _openWizard(WidgetTester tester) async {
  await tester.pumpWidget(_wrap());
  await tester.pumpAndSettle();
  await tester.tap(find.text('Back Screen'));
  await tester.pumpAndSettle();
}

Future<void> _pickToday(
  WidgetTester tester,
  String label, [
  int index = 0,
]) async {
  final target = find.text(label).at(index);
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  await tester.tap(target);
  await tester.pumpAndSettle();
  await tester.tap(find.text('OK'));
  await tester.pumpAndSettle();
}

/// Leaves the Related Building Permit at its default "Pending" status,
/// which is already a valid state (no Building Permit Number required),
/// so Step 1 needs no input at all before continuing.
Future<void> _completeStep1(WidgetTester tester) async {
  await tester.tap(_continueButton());
  await tester.pumpAndSettle();
}

Future<void> _completeStep2(WidgetTester tester) async {
  await tester.enterText(
    find.widgetWithText(TextFormField, 'Last Name *'),
    'Dela Cruz',
  );
  await tester.enterText(
    find.widgetWithText(TextFormField, 'First Name *'),
    'Juan',
  );
  await tester.enterText(
    find.widgetWithText(TextFormField, 'Street *'),
    'Rizal St.',
  );
  await tester.enterText(
    find.widgetWithText(TextFormField, 'Barangay *'),
    'San Isidro',
  );
  await tester.enterText(
    find.widgetWithText(TextFormField, 'City / Municipality *'),
    'Quezon City',
  );
  await tester.pump();
  await tester.tap(_continueButton());
  await tester.pumpAndSettle();
}

Future<void> _completeStep3(WidgetTester tester) async {
  await tester.enterText(
    find.widgetWithText(TextFormField, 'Lot Number *'),
    '12',
  );
  await tester.enterText(
    find.widgetWithText(TextFormField, 'Street *'),
    'Rizal St.',
  );
  await tester.enterText(
    find.widgetWithText(TextFormField, 'Barangay *'),
    'San Isidro',
  );
  await tester.enterText(
    find.widgetWithText(TextFormField, 'City / Municipality *'),
    'Quezon City',
  );
  await tester.pump();
  // Site and ownership documents, added when this wizard was reconciled
  // against the requirements catalog. They gate step 3, so the flow cannot
  // advance without them.
  for (final label in const [
    'Land Title or Tax Declaration',
    'Barangay Clearance',
    'Locational Clearance / Zoning Certification',
    'Valid Government-Issued ID',
  ]) {
    final tile = find.widgetWithText(DocumentUploadTile, label);
    await tester.ensureVisible(tile);
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: tile,
        matching: find.widgetWithText(OutlinedButton, 'Upload'),
      ),
    );
    await tester.pump();
  }
  await tester.pump();

  await tester.tap(_continueButton());
  await tester.pumpAndSettle();
}

Future<void> _completeStep4(WidgetTester tester) async {
  await tester.tap(find.text('New Construction'));
  await tester.pump();
  await tester.tap(_continueButton());
  await tester.pumpAndSettle();
}

Future<void> _fillProfessionalFields(
  WidgetTester tester, {
  required String fullName,
  required String profession,
  required String address,
  required String prcNumber,
  required String ptrNumber,
  required String ptrPlaceIssued,
}) async {
  await tester.enterText(
    find.widgetWithText(TextFormField, 'Full Name *'),
    fullName,
  );
  await tester.enterText(
    find.widgetWithText(TextFormField, 'Professional Address *'),
    address,
  );
  await tester.enterText(
    find.widgetWithText(TextFormField, 'PRC Number *'),
    prcNumber,
  );
  await tester.enterText(
    find.widgetWithText(TextFormField, 'PTR Number *'),
    ptrNumber,
  );
  await tester.enterText(
    find.widgetWithText(TextFormField, 'PTR Place Issued *'),
    ptrPlaceIssued,
  );
  await tester.pump();
  await tester.tap(find.byWidgetPredicate((w) => w is DropdownButtonFormField));
  await tester.pumpAndSettle();
  await tester.tap(find.text(profession).last);
  await tester.pumpAndSettle();
  await _pickToday(tester, 'PRC Validity *');
  await _pickToday(tester, 'PTR Date Issued *');
}

Future<void> _completeStep5(WidgetTester tester) async {
  await _fillProfessionalFields(
    tester,
    fullName: 'Arch. Maria Santos',
    profession: 'Architect',
    address: '123 Kalayaan Ave., Quezon City',
    prcNumber: 'PRC-0001',
    ptrNumber: 'PTR-0001',
    ptrPlaceIssued: 'Quezon City',
  );
  await tester.ensureVisible(
    find.widgetWithText(OutlinedButton, 'Upload').first,
  );
  await tester.pumpAndSettle();
  await tester.tap(find.widgetWithText(OutlinedButton, 'Upload').first);
  await tester.pump();
  await tester.tap(_continueButton());
  await tester.pumpAndSettle();
}

Future<void> _completeStep6(WidgetTester tester) async {
  await _fillProfessionalFields(
    tester,
    fullName: 'Engr. Pedro Reyes',
    profession: 'Civil Engineer',
    address: '456 Kalayaan Ave., Quezon City',
    prcNumber: 'PRC-0002',
    ptrNumber: 'PTR-0002',
    ptrPlaceIssued: 'Quezon City',
  );
  await tester.ensureVisible(
    find.widgetWithText(OutlinedButton, 'Upload').first,
  );
  await tester.pumpAndSettle();
  await tester.tap(find.widgetWithText(OutlinedButton, 'Upload').first);
  await tester.pump();
  await tester.tap(_continueButton());
  await tester.pumpAndSettle();
}

/// Leaves Lot Ownership at "Yes" (the Applicant is also the Lot Owner),
/// which is a valid state that skips the separate Lot Owner section.
Future<void> _completeStep7(WidgetTester tester) async {
  await tester.enterText(
    find.widgetWithText(TextFormField, 'Printed Name *'),
    'Juan Dela Cruz',
  );
  await tester.enterText(
    find.widgetWithText(TextFormField, 'Address *'),
    '789 Kalayaan Ave., Quezon City',
  );
  await tester.enterText(
    find.widgetWithText(TextFormField, 'Community Tax Certificate Number *'),
    'CTC-0001',
  );
  await tester.enterText(
    find.widgetWithText(TextFormField, 'Place Issued *'),
    'Quezon City',
  );
  await tester.pump();
  await _pickToday(tester, 'Date Issued *');

  await tester.ensureVisible(
    find.widgetWithText(OutlinedButton, 'Upload').first,
  );
  await tester.pumpAndSettle();
  await tester.tap(find.widgetWithText(OutlinedButton, 'Upload').first);
  await tester.pump();

  final yesButton = find.text('Yes');
  await tester.ensureVisible(yesButton);
  await tester.pumpAndSettle();
  await tester.tap(yesButton);
  await tester.pump();

  await tester.tap(_continueButton());
  await tester.pumpAndSettle();
}

Future<void> _completeStep8(WidgetTester tester) async {
  await tester.enterText(
    find.widgetWithText(TextFormField, 'Fence Length (meters) *'),
    '45.5',
  );
  await tester.enterText(
    find.widgetWithText(TextFormField, 'Fence Height (meters) *'),
    '2',
  );
  await tester.pump();
  await tester.tap(find.text('Reinforced Concrete (R.C.)'));
  await tester.pump();
  await tester.tap(_continueButton());
  await tester.pumpAndSettle();
}

Future<void> _checkAllDeclarations(WidgetTester tester) async {
  for (final label in [
    'I certify that the information provided in this application is '
        'true and accurate.',
    'I understand that fence construction must follow the approved '
        'plans and applicable regulations.',
    'I understand that this Fencing Permit is null and void unless '
        'accompanied by a valid related Building Permit, when '
        'applicable.',
    'I understand that all required signed and sealed professional '
        'documents must be authentic.',
  ]) {
    await tester.ensureVisible(find.text(label));
    await tester.pumpAndSettle();
    await tester.tap(find.text(label));
    await tester.pump();
  }
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
  testWidgets('Step 1 renders with Permit Information heading', (tester) async {
    await _useTallSurface(tester);
    await _openWizard(tester);
    expect(tester.takeException(), isNull);

    expect(find.text('Step 1 of 9'), findsOneWidget);
    expect(find.text('Permit Information'), findsWidgets);
  });

  testWidgets(
    'Continue navigates Step 1 through Step 9, and Submit Application opens the confirmation screen with the pending Building Permit warning',
    (tester) async {
      await _useTallSurface(tester);
      await _openWizard(tester);
      await _completeStep1(tester);
      expect(find.text('Step 2 of 9'), findsOneWidget);

      await _completeStep2(tester);
      expect(find.text('Step 3 of 9'), findsOneWidget);

      await _completeStep3(tester);
      expect(find.text('Step 4 of 9'), findsOneWidget);

      await _completeStep4(tester);
      expect(find.text('Step 5 of 9'), findsOneWidget);

      await _completeStep5(tester);
      expect(find.text('Step 6 of 9'), findsOneWidget);

      await _completeStep6(tester);
      expect(find.text('Step 7 of 9'), findsOneWidget);

      await _completeStep7(tester);
      expect(find.text('Step 8 of 9'), findsOneWidget);

      await _completeStep8(tester);
      expect(find.text('Step 9 of 9'), findsOneWidget);

      expect(
        tester.widget<ElevatedButton>(_submitButton()).onPressed,
        isNull,
        reason: 'declarations have not been checked yet',
      );
      await _checkAllDeclarations(tester);
      expect(
        tester.widget<ElevatedButton>(_submitButton()).onPressed,
        isNotNull,
      );

      await tester.tap(_submitButton());
      // The submission is recorded through the mock repository first, and its
      // delay is a Future.delayed — which pumpAndSettle does not drain.
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Fencing Application Submitted!'), findsOneWidget);
      expect(find.textContaining('FNC-'), findsOneWidget);
    },
  );

  testWidgets(
    'a submitted permit reaches the applications list, and the confirmation '
    'screen links to it',
    (tester) async {
      // The pieces of this are unit-tested elsewhere. This is the whole path
      // an applicant actually walks, because the defect it guards was not in
      // any one piece: every wizard submitted happily, the confirmation screen
      // rendered happily, and the application simply was not anywhere
      // afterwards. Nothing failed — it just did not exist.
      await _useTallSurface(tester);
      await _openWizard(tester);
      await _completeStep1(tester);
      await _completeStep2(tester);
      await _completeStep3(tester);
      await _completeStep4(tester);
      await _completeStep5(tester);
      await _completeStep6(tester);
      await _completeStep7(tester);
      await _completeStep8(tester);
      await _checkAllDeclarations(tester);

      await tester.tap(_submitButton());
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();

      final reference = (tester
          .widgetList<Text>(find.byType(Text))
          .map((t) => t.data)
          .firstWhere((d) => d != null && d.startsWith('FNC-')))!;

      // The submission is now a record, and the notification that announces
      // it was posted — both come from ApplicationsProvider.submitApplication,
      // which nothing used to reach.
      final context = tester.element(find.byType(Scaffold).first);
      final applications = context.read<ApplicationsProvider>();
      final notifications = context.read<NotificationsProvider>();

      expect(
        applications.applications.map((a) => a.applicationNumber),
        contains(reference),
        reason: 'the reference on screen should name a real application',
      );
      expect(
        notifications.events.any(
          (e) => e.type == NotificationType.applicationSubmitted,
        ),
        isTrue,
        reason: 'submitting should announce itself',
      );

      // Return to Applications is the button most applicants press, so that
      // is the path this walks.
      await tester.ensureVisible(find.text('Return to Applications'));
      await tester.tap(find.text('Return to Applications'));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();

      expect(find.byType(ApplicationListScreen), findsOneWidget);
      expect(
        find.textContaining(reference),
        findsOneWidget,
        reason: 'the permit just filed should be in the applicant\'s list',
      );
      expect(find.textContaining('Fencing Permit'), findsWidgets);
    },
  );

  testWidgets(
    'Selecting "Approved" status requires a Building Permit Number in Step 1',
    (tester) async {
      await _useTallSurface(tester);
      await _openWizard(tester);

      expect(
        tester.widget<ElevatedButton>(_continueButton()).onPressed,
        isNotNull,
        reason: 'Pending does not require a Building Permit number',
      );

      await tester.tap(
        find.byWidgetPredicate((w) => w is DropdownButtonFormField),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Approved').last);
      await tester.pumpAndSettle();

      expect(
        tester.widget<ElevatedButton>(_continueButton()).onPressed,
        isNull,
        reason: 'Approved status requires a Building Permit number',
      );

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Building Permit Number *'),
        'BP-2026-999999',
      );
      await tester.pump();
      expect(
        tester.widget<ElevatedButton>(_continueButton()).onPressed,
        isNotNull,
      );
    },
  );

  testWidgets(
    'Selecting "Others" scope requires a specification before continuing',
    (tester) async {
      await _useTallSurface(tester);
      await _openWizard(tester);
      await _completeStep1(tester);
      await _completeStep2(tester);
      await _completeStep3(tester);

      await tester.tap(find.text('Others').first);
      await tester.pump();
      expect(
        tester.widget<ElevatedButton>(_continueButton()).onPressed,
        isNull,
        reason: 'Others requires a specification',
      );

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Specify Other Scope *'),
        'Temporary construction barrier.',
      );
      await tester.pump();
      expect(
        tester.widget<ElevatedButton>(_continueButton()).onPressed,
        isNotNull,
      );
    },
  );

  testWidgets(
    '"Use the same information as the Design Professional" copies Step 5 values into Step 6',
    (tester) async {
      await _useTallSurface(tester);
      await _openWizard(tester);
      await _completeStep1(tester);
      await _completeStep2(tester);
      await _completeStep3(tester);
      await _completeStep4(tester);
      await _completeStep5(tester);

      final checkbox = find.text(
        'Use the same information as the Design Professional',
      );
      await tester.ensureVisible(checkbox);
      await tester.pumpAndSettle();
      await tester.tap(checkbox);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      expect(
        find.widgetWithText(TextFormField, 'Arch. Maria Santos'),
        findsOneWidget,
        reason: 'Full Name was copied from the Design Professional',
      );
      expect(
        find.widgetWithText(TextFormField, 'PRC-0001'),
        findsOneWidget,
        reason: 'PRC Number was copied from the Design Professional',
      );
    },
  );

  testWidgets('Lot Ownership "No" reveals a separate Lot Owner section', (
    tester,
  ) async {
    await _useTallSurface(tester);
    await _openWizard(tester);
    await _completeStep1(tester);
    await _completeStep2(tester);
    await _completeStep3(tester);
    await _completeStep4(tester);
    await _completeStep5(tester);
    await _completeStep6(tester);

    expect(tester.widget<ElevatedButton>(_continueButton()).onPressed, isNull);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Printed Name *'),
      'Juan Dela Cruz',
    );
    await tester.pump();

    final noButton = find.text('No');
    await tester.ensureVisible(noButton);
    await tester.pumpAndSettle();
    await tester.tap(noButton);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(
      find.widgetWithText(TextFormField, 'Printed Name *'),
      findsNWidgets(2),
      reason: 'the Lot Owner now has its own Printed Name field',
    );
    expect(find.text('Lot Owner Consent'), findsOneWidget);
  });

  testWidgets('Fence length and height reject non-positive values', (
    tester,
  ) async {
    await _useTallSurface(tester);
    await _openWizard(tester);
    await _completeStep1(tester);
    await _completeStep2(tester);
    await _completeStep3(tester);
    await _completeStep4(tester);
    await _completeStep5(tester);
    await _completeStep6(tester);
    await _completeStep7(tester);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Fence Length (meters) *'),
      '0',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Fence Height (meters) *'),
      '2',
    );
    await tester.pump();
    await tester.tap(find.text('Reinforced Concrete (R.C.)'));
    await tester.pump();

    expect(
      tester.widget<ElevatedButton>(_continueButton()).onPressed,
      isNull,
      reason: 'fence length must be greater than zero',
    );

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Fence Length (meters) *'),
      '45.5',
    );
    await tester.pump();
    expect(
      tester.widget<ElevatedButton>(_continueButton()).onPressed,
      isNotNull,
    );
  });

  testWidgets('Save as Draft works and preserves values', (tester) async {
    await _useTallSurface(tester);
    await _openWizard(tester);

    await tester.tap(_continueButton());
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Last Name *'),
      'Dela Cruz',
    );
    await tester.pump();

    await tester.tap(find.text('Save Draft'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Draft saved successfully.'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Dela Cruz'), findsOneWidget);
  });
}
