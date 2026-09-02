import 'package:flutter_test/flutter_test.dart';

import 'package:ebpco_user_app/core/api/api_exception.dart';
import 'package:ebpco_user_app/core/models/application_detail.dart';
import 'package:ebpco_user_app/core/models/application_lineage.dart';
import 'package:ebpco_user_app/core/models/application_model.dart';
import 'package:ebpco_user_app/core/models/document_model.dart';
import 'package:ebpco_user_app/core/models/lifecycle_status.dart';
import 'package:ebpco_user_app/core/models/money.dart';
import 'package:ebpco_user_app/core/models/payment_assessment_model.dart';
import 'package:ebpco_user_app/core/providers/applications_provider.dart';
import 'package:ebpco_user_app/core/providers/notifications_provider.dart';
import 'package:ebpco_user_app/core/repositories/applications_repository.dart';
import 'package:ebpco_user_app/core/repositories/notifications_repository.dart';

/// Answering a Letter of Instruction has to reach the office.
///
/// It did not. `resubmitAfterInstruction` was local and synchronous: it moved
/// the application to Under Evaluation, wrote a timeline entry attributed to
/// the Office of the Building Official, and cleared the outstanding action —
/// with no request of any kind. `HttpApplicationsRepository` had carried a
/// complete, careful implementation of the endpoint the whole time, and it was
/// absent from the interface the provider holds, so nothing could call it.
///
/// The citizen was told "Corrections submitted. The OBO will re-evaluate your
/// application", the screen popped, and the action item disappeared. The office
/// was still waiting, and the deadline in the letter kept running.

final _now = DateTime(2026, 9, 3, 9);

ApplicationModel _application() => ApplicationModel(
  id: 'app-1',
  applicationNumber: 'E-BPCO-2026-000145',
  businessId: '',
  businessName: 'Juan dela Cruz',
  type: ApplicationType.newPermit,
  status: ApplicationStatus.submitted,
  submittedDate: DateTime(2026, 8, 1),
  lifecycleStatus: ApplicationLifecycleStatus.revisionRequired,
  instructions: [
    LetterOfInstruction(
      id: 'loi-1',
      issuedAt: DateTime(2026, 8, 20),
      items: [
        InstructionItem(
          id: 'item-1',
          subject: 'Lot Plan',
          remark: 'Illegible signature',
          resolvedAt: _now,
        ),
        InstructionItem(
          id: 'item-2',
          subject: 'Structural Plan',
          remark: 'Missing seal',
          resolvedAt: _now,
        ),
      ],
    ),
  ],
);

class _Repository implements ApplicationsRepository {
  _Repository({this.fails = false});

  final bool fails;
  final List<({String applicationId, String letterId, List<String> itemIds})>
  calls = [];

  @override
  Future<ApplicationModel> resubmitInstruction(
    String applicationId,
    String letterId, {
    required List<String> itemIds,
    Map<String, String> responses = const {},
  }) async {
    calls.add((
      applicationId: applicationId,
      letterId: letterId,
      itemIds: itemIds,
    ));
    if (fails) throw const ApiException(ApiFailure.network, 'offline');
    return _application();
  }

  @override
  Future<List<ApplicationModel>> fetchAll() async => [_application()];

  @override
  Future<ApplicationModel> fetchDetail(String id) async => _application();

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
  }) => throw UnimplementedError();

  @override
  Future<ApplicationModel> advanceStatus(String id) =>
      throw UnimplementedError();
}

Future<ApplicationsProvider> _provider(_Repository repository) async {
  final provider = ApplicationsProvider(
    notifications: NotificationsProvider(
      repository: MockNotificationsRepository(),
    ),
    repository: repository,
    clock: () => _now,
  );
  await Future.delayed(const Duration(milliseconds: 400));
  return provider;
}

void main() {
  test('answering a letter actually sends it, naming every item', () async {
    final repository = _Repository();
    final provider = await _provider(repository);

    await provider.resubmitAfterInstruction('app-1');

    expect(repository.calls, hasLength(1));
    expect(repository.calls.single.letterId, 'loi-1');
    expect(repository.calls.single.itemIds, [
      'item-1',
      'item-2',
    ], reason: 'the endpoint requires minItems 1 and refuses an empty list');
  });

  test('a failed send moves nothing and does not clear the action', () async {
    // The defect, inverted. Before, none of this depended on a request at all.
    final repository = _Repository(fails: true);
    final provider = await _provider(repository);
    final before = provider.byId('app-1')!;

    await expectLater(
      provider.resubmitAfterInstruction('app-1'),
      throwsA(isA<ApiException>()),
    );

    final after = provider.byId('app-1')!;
    expect(
      after.lifecycleStatus,
      before.lifecycleStatus,
      reason: 'the office never heard, so nothing about it has changed',
    );
    expect(after.status, ApplicationStatus.submitted);
    expect(
      after.timeline.length,
      before.timeline.length,
      reason:
          'no timeline entry attributed to the OBO for something the OBO '
          'has not received',
    );
  });
}
