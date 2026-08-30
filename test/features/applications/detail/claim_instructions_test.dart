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

/// What an applicant reads when the app tells them their permit is ready.
///
/// M-11. `ReleaseRecord.claimLocation`, `.officeHours` and `.bringWithYou`
/// come from the backend, and the contract omits them on purpose — R-13:
/// "the logistics values are LGU-specific (M-11 / decision E-15) and are
/// omitted rather than guessed". Every one of them was null-guarded on the
/// screen, so with the contract behaving exactly as specified the section
/// headed **Claim instructions** rendered a heading and a paragraph about
/// Special Powers of Attorney.
///
/// That is not a cosmetic gap. `readyForRelease` sets
/// `requiresApplicantAction`, which drives the Home action stack, the tab
/// badge and push priority, and the notification says "Tap for claim
/// instructions and requirements". The app spends an applicant's trip.

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
  ReleaseRecord? release,
}) {
  final issued = issuedDate ?? DateTime(2026, 3, 1);
  return ApplicationModel(
    release: release,
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

ApplicationModel _readyToClaim({ReleaseRecord? release}) => _released(
  type: CanonicalPermitType.buildingPermitNewConstruction,
  release:
      release ??
      const ReleaseRecord(status: PermitReleaseStatus.readyForRelease),
);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('with the contract omitting everything, it still says where', (
    tester,
  ) async {
    // The production case, not an edge case: this is what the contract
    // specifies the backend sends.
    await _open(tester, _readyToClaim());

    expect(find.text('Claim instructions'), findsOneWidget);
    expect(find.text('Where to claim'), findsOneWidget);
    expect(
      find.textContaining('Office of the Municipal Engineer'),
      findsWidgets,
      reason:
          'the office is named on the checklist letterhead. Without this the '
          'applicant is told to claim their permit and not told where',
    );
    expect(find.textContaining('Municipality of Castilla'), findsWidgets);
  });

  testWidgets('it does not invent the hours or the street', (tester) async {
    await _open(tester, _readyToClaim());

    // Philippine offices commonly open 8-5 on weekdays. "Commonly" is not
    // Castilla, and this app has printed a plausible-and-wrong address before
    // — a Quezon City hall for a Sorsogon municipality.
    expect(find.textContaining('8:00'), findsNothing);
    expect(find.textContaining('Monday to Friday'), findsNothing);
    expect(find.textContaining('has not published its hours'), findsOneWidget);
    expect(
      find.textContaining('has not published a street address'),
      findsOneWidget,
    );
    // And it gives them the channel that IS published, so the trip is not
    // wasted either way.
    expect(find.textContaining('0905 481 8572'), findsOneWidget);
  });

  testWidgets('it says the ancillary permits are claimed together', (
    tester,
  ) async {
    // Step 3 of the checklist. This app models each ancillary permit as its
    // own application, so an applicant holding six of them has no reason to
    // expect one visit rather than six.
    await _open(tester, _readyToClaim());

    expect(find.textContaining('claimed together'), findsOneWidget);
    expect(
      find.textContaining('documentary checklist, step 3'),
      findsOneWidget,
      reason:
          'an applicant deciding whether to trust this is owed its source. '
          'The last set of contact details in this app was invented',
    );
  });

  testWidgets('and the backend still wins when it sends real values', (
    tester,
  ) async {
    // The fallback must not mask an LGU that has supplied its logistics.
    await _open(
      tester,
      _readyToClaim(
        release: const ReleaseRecord(
          status: PermitReleaseStatus.readyForRelease,
          claimLocation: 'Ground floor, Municipal Hall, Castilla',
          officeHours: 'Monday to Friday, 8:00am - 5:00pm',
          bringWithYou: ['One valid government ID.', 'The Official Receipt.'],
        ),
      ),
    );

    expect(find.text('Ground floor, Municipal Hall, Castilla'), findsOneWidget);
    expect(find.text('Monday to Friday, 8:00am - 5:00pm'), findsOneWidget);
    expect(find.textContaining('One valid government ID.'), findsOneWidget);
    expect(
      find.textContaining('has not published its hours'),
      findsNothing,
      reason: 'the caveat is for the gap, not for every applicant',
    );
    expect(
      find.textContaining('has not published a street address'),
      findsNothing,
    );
  });
}
