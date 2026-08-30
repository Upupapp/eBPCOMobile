import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ebpco_user_app/core/models/money.dart';
import 'package:ebpco_user_app/core/contract/admin_vocabulary.dart';
import 'package:ebpco_user_app/core/models/application_lineage.dart';
import 'package:ebpco_user_app/core/models/application_model.dart';
import 'package:ebpco_user_app/core/models/document_model.dart';
import 'package:ebpco_user_app/core/models/document_review_reason.dart';
import 'package:ebpco_user_app/core/models/lifecycle_status.dart';
import 'package:ebpco_user_app/core/models/notification_event.dart';
import 'package:ebpco_user_app/core/models/payment_assessment_model.dart';
import 'package:ebpco_user_app/core/providers/applications_provider.dart';
import 'package:ebpco_user_app/core/providers/notifications_provider.dart';
import 'package:ebpco_user_app/core/repositories/applications_repository.dart';
import 'package:ebpco_user_app/core/repositories/notifications_repository.dart';
import 'package:ebpco_user_app/core/theme/app_theme.dart';
import 'package:ebpco_user_app/features/documents/presentation/widgets/attach_document_sheet.dart';
import 'package:ebpco_user_app/features/applications/presentation/detail/application_detail_screen.dart';

/// The applicant's side of a document review.
///
/// The office records a status and a reason against each document. This is the
/// screen where the applicant finds out — and until now it showed only a
/// filename and a generic icon, so a rejection with a written reason reached
/// them only if somebody separately raised a Letter of Instruction.

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
  }) async {
    final index = applications.indexWhere((a) => a.id == applicationId);
    final application = applications[index];
    final updated = application.copyWith(
      documents: [
        for (final document in application.documents)
          if (document.id == documentId)
            document.resubmittedWith(
              fileName: replacement.fileName,
              submittedAt: replacement.uploadedAt,
            )
          else
            document,
      ],
    );
    applications[index] = updated;
    return updated;
  }

  @override
  Future<ApplicationModel> advanceStatus(String id) =>
      throw UnimplementedError();
}

class _Notifs implements NotificationsRepository {
  @override
  Future<List<NotificationEvent>> fetchAll() async => const [];
}

DocumentModel _doc(
  String label, {
  DocumentStatus? status,
  String? remarks,
  DocumentReviewReason? reviewReason,
  String? issuingOffice,
  List<DocumentSubmission> history = const [],
}) => DocumentModel(
  id: label,
  label: label,
  fileName: '${label.toLowerCase().replaceAll(' ', '-')}.pdf',
  uploadedAt: DateTime(2026, 8, 1),
  status: status,
  remarks: remarks,
  reviewReason: reviewReason,
  issuingOffice: issuingOffice,
  history: history,
);

ApplicationModel _application() => ApplicationModel(
  id: 'app-1',
  applicationNumber: 'E-BPCO-2026-000145',
  businessId: 'biz-1',
  businessName: 'Dela Cruz Construction',
  type: ApplicationType.newPermit,
  status: ApplicationStatus.underReview,
  submittedDate: DateTime(2026, 8, 1),
  lifecycleStatus: ApplicationLifecycleStatus.documentVerification,
  documents: [
    _doc('Plans', status: DocumentStatus.accepted),
    _doc('Barangay Clearance', status: DocumentStatus.underReview),
    _doc(
      'Land Title',
      status: DocumentStatus.rejected,
      reviewReason: const DocumentReviewReason(
        code: 'not-certified-true-copy',
        label: 'Not a certified true copy',
      ),
      remarks: 'Submit a Certified True Copy issued within six months.',
      issuingOffice: 'Registry of Deeds',
      history: [
        DocumentSubmission(
          fileName: 'land-title-photocopy.pdf',
          submittedAt: DateTime(2026, 7, 20),
          status: DocumentStatus.rejected,
          remarks: 'Photocopy not acceptable.',
        ),
      ],
    ),
    // 'Other' carries no meaning without the remark beside it, so the screen
    // must not render it as though it were an answer.
    _doc(
      'Lot Plan',
      status: DocumentStatus.revisionRequired,
      reviewReason: const DocumentReviewReason(code: 'other', label: 'Other'),
      remarks: 'Wrong lot number throughout.',
    ),
  ],
);

Future<void> _open(WidgetTester tester) async {
  tester.view.physicalSize = const Size(400, 3000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final router = GoRouter(
    initialLocation: '/detail',
    routes: [
      GoRoute(
        path: '/detail',
        builder: (_, _) =>
            const ApplicationDetailScreen(applicationId: 'app-1'),
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

  testWidgets('a rejected document shows its status and the reason', (
    tester,
  ) async {
    await _open(tester);

    expect(find.text('Rejected'), findsOneWidget);
    expect(
      find.text('Submit a Certified True Copy issued within six months.'),
      findsOneWidget,
      reason: 'a status without the reason tells the applicant to guess',
    );
  });

  testWidgets('each document carries its own state', (tester) async {
    await _open(tester);

    expect(find.text('Accepted'), findsOneWidget);
    expect(find.text('Under review'), findsOneWidget);
    expect(find.text('Rejected'), findsOneWidget);
  });

  testWidgets('what needs action is listed first', (tester) async {
    await _open(tester);

    // Land Title is third in submission order and the only one turned back.
    final landTitle = tester.getRect(find.text('Land Title'));
    final plans = tester.getRect(find.text('Plans'));
    expect(
      landTitle.top,
      lessThan(plans.top),
      reason:
          'a rejected document eleventh in the list is one the applicant '
          'does not know about',
    );
  });

  testWidgets('earlier submissions are acknowledged', (tester) async {
    await _open(tester);
    expect(find.text('1 earlier submission'), findsOneWidget);
  });

  testWidgets('the issuing office is named where known', (tester) async {
    await _open(tester);
    expect(find.text('Issued by Registry of Deeds'), findsOneWidget);
  });

  testWidgets('a rejected document can be replaced, and the screen follows', (
    tester,
  ) async {
    // The whole point of surfacing the status: the applicant can do something
    // about it without leaving the screen that told them.
    debugAttachDocumentOverride = (context, {required String label}) async =>
        DocumentModel(
          id: 'replacement',
          label: label,
          fileName: 'land-title-certified.pdf',
          uploadedAt: DateTime(2026, 8, 25),
        );
    addTearDown(() => debugAttachDocumentOverride = null);

    await _open(tester);

    expect(find.text('Rejected'), findsOneWidget);
    // Two of the four documents are adverse — one Rejected, one Revision
    // Required — and both offer it. The other two (Accepted, Under Review) do
    // not, which is what this count discriminates.
    final replace = find.text('Replace this document');
    expect(replace, findsNWidgets(2), reason: 'both adverse ones offer it');

    await tester.ensureVisible(replace.first);
    await tester.tap(replace.first);
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    expect(find.text('land-title-certified.pdf'), findsOneWidget);
    expect(
      find.text('Rejected'),
      findsNothing,
      reason: 'the replacement is a new submission, not the rejected one',
    );
    expect(
      find.text('2 earlier submissions'),
      findsOneWidget,
      reason: 'the rejected version is kept, not overwritten',
    );
  });

  testWidgets('only documents needing action offer a replace action', (
    tester,
  ) async {
    // An accepted document with a Replace button invites an applicant to undo
    // work the office already signed off. Two of the four documents are
    // adverse; the Accepted and Under Review ones are not among them.
    await _open(tester);
    expect(find.text('Replace this document'), findsNWidgets(2));
  });

  group('the standard reason reaches the screen', () {
    testWidgets('a rejected document shows the reason AND the remark', (
      tester,
    ) async {
      // Owner decision, 2026-08-28: both halves. The category is what the
      // applicant quotes at the counter; the remark is what tells them which
      // page. A test that checked only the remark would have let the chip be
      // added and never rendered.
      await _open(tester);

      expect(find.text('Not a certified true copy'), findsOneWidget);
      expect(
        find.text('Submit a Certified True Copy issued within six months.'),
        findsOneWidget,
      );
    });

    testWidgets('"Other" is never shown on its own', (tester) async {
      // A filing category. Rendering it looks like an answer and tells the
      // applicant nothing; its remark carries the whole message.
      await _open(tester);

      expect(find.text('Other'), findsNothing);
      expect(find.text('Wrong lot number throughout.'), findsOneWidget);
    });

    testWidgets('an accepted document carries no reason', (tester) async {
      await _open(tester);
      // 'Plans' is accepted. No reason chip should exist anywhere for it, and
      // the two that do exist belong to the two adverse documents.
      expect(find.text('Not a certified true copy'), findsOneWidget);
    });
  });
}
