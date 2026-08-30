import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ebpco_user_app/core/models/money.dart';
import 'package:ebpco_user_app/core/contract/admin_vocabulary.dart';
import 'package:ebpco_user_app/core/models/application_detail.dart';
import 'package:ebpco_user_app/core/models/application_lineage.dart';
import 'package:ebpco_user_app/core/models/application_model.dart';
import 'package:ebpco_user_app/core/models/document_model.dart';
import 'package:ebpco_user_app/core/models/lifecycle_status.dart';
import 'package:ebpco_user_app/core/models/payment_assessment_model.dart';
import 'package:ebpco_user_app/core/providers/applications_provider.dart';
import 'package:ebpco_user_app/core/providers/notifications_provider.dart';
import 'package:ebpco_user_app/core/repositories/applications_repository.dart';
import 'package:ebpco_user_app/core/repositories/notifications_repository.dart';
import 'package:ebpco_user_app/features/applications/presentation/detail/digital_permit_screen.dart';

/// What the issued permit says about its own two deadlines.
///
/// The face of the record has to carry both, distinctly: PD 1096's
/// commencement deadline (one year, every type) and the permit's own validity
/// (six months, twelve, or none). Before this the screen showed only the
/// first, so a six-month permit read as if it lasted a year.

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
}

ApplicationModel _released({
  required CanonicalPermitType type,
  DateTime? issuedDate,
}) {
  final issued = issuedDate ?? DateTime(2026, 3, 1);
  return ApplicationModel(
    id: 'app-1',
    applicationNumber: 'E-BPCO-2026-000145',
    businessId: 'biz-1',
    businessName: 'Dela Cruz Construction',
    type: ApplicationType.newPermit,
    status: ApplicationStatus.released,
    submittedDate: DateTime(2026, 1, 5),
    lifecycleStatus: ApplicationLifecycleStatus.released,
    permitTypeLabel: type.wire,
    permitNumber: 'BP-2026-000145',
    issuedDate: issued,
    permit: GeneratedPermit(
      permitNumber: 'BP-2026-000145',
      issuedDate: issued,
      scope: 'Two-storey residential',
    ),
  );
}

Widget _wrap(ApplicationModel application) {
  final router = GoRouter(
    initialLocation: '/permit',
    routes: [
      GoRoute(
        path: '/permit',
        builder: (_, _) => const DigitalPermitScreen(applicationId: 'app-1'),
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
          repository: _FakeRepository([application]),
          clock: () => DateTime(2026, 3, 10),
        ),
      ),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

Future<void> _open(WidgetTester tester, ApplicationModel application) async {
  await tester.binding.setSurfaceSize(const Size(400, 3000));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(_wrap(application));
  await tester.pump();
  await tester.pump(const Duration(seconds: 3));
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('a twelve-month permit shows its expiry date', (tester) async {
    await _open(
      tester,
      _released(type: CanonicalPermitType.buildingPermitNewConstruction),
    );

    expect(find.text('Valid until'), findsOneWidget);
    expect(find.text('Mar 1, 2027'), findsOneWidget);
  });

  testWidgets('a six-month permit shows the earlier of its two dates as the '
      'expiry, and the later as the commencement deadline', (tester) async {
    // The whole reason the two are modelled separately. If the screen were
    // reusing the commencement date both lines would read Mar 1, 2027.
    await _open(tester, _released(type: CanonicalPermitType.fencingPermit));

    expect(find.text('Sep 1, 2026'), findsOneWidget);
    expect(
      find.textContaining('Work must commence by Mar 1, 2027'),
      findsOneWidget,
    );
  });

  testWidgets('a Certificate of Occupancy says so rather than showing a date', (
    tester,
  ) async {
    await _open(
      tester,
      _released(type: CanonicalPermitType.certificateOfOccupancy),
    );

    expect(find.text('Valid until'), findsOneWidget);
    expect(find.text('No fixed expiry'), findsOneWidget);
    // Commencement still applies — it is a rule about the work, not the
    // certificate's own lifetime.
    expect(find.textContaining('Work must commence by'), findsOneWidget);
  });

  testWidgets('no expiry warning while the date is far off', (tester) async {
    await _open(
      tester,
      _released(
        type: CanonicalPermitType.buildingPermitNewConstruction,
        issuedDate: DateTime.now(),
      ),
    );
    expect(find.textContaining('This permit expires'), findsNothing);
  });

  testWidgets('the expiry warning appears inside the 60-day threshold', (
    tester,
  ) async {
    await _open(
      tester,
      _released(
        type: CanonicalPermitType.buildingPermitNewConstruction,
        issuedDate: DateTime.now().subtract(const Duration(days: 340)),
      ),
    );
    expect(find.textContaining('This permit expires'), findsOneWidget);
    expect(
      find.textContaining('Validity is separate from the commencement'),
      findsOneWidget,
    );
  });

  testWidgets('a lapsed permit is told in the past tense', (tester) async {
    await _open(
      tester,
      _released(
        type: CanonicalPermitType.fencingPermit,
        issuedDate: DateTime.now().subtract(const Duration(days: 200)),
      ),
    );
    expect(find.textContaining('This permit expired'), findsOneWidget);
    expect(find.textContaining('This permit expires '), findsNothing);
  });
}
