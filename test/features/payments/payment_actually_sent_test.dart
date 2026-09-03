import 'package:flutter_test/flutter_test.dart';

import 'package:ebpco_user_app/core/api/api_exception.dart';
import 'package:ebpco_user_app/core/models/application_lineage.dart';
import 'package:ebpco_user_app/core/models/application_model.dart';
import 'package:ebpco_user_app/core/models/document_model.dart';
import 'package:ebpco_user_app/core/models/money.dart';
import 'package:ebpco_user_app/core/models/notification_event.dart';
import 'package:ebpco_user_app/core/models/order_of_payment.dart';
import 'package:ebpco_user_app/core/models/payment_assessment_model.dart';
import 'package:ebpco_user_app/core/providers/applications_provider.dart';
import 'package:ebpco_user_app/core/providers/notifications_provider.dart';
import 'package:ebpco_user_app/core/repositories/applications_repository.dart';
import 'package:ebpco_user_app/core/repositories/notifications_repository.dart';

/// A payment the office never heard about must not look paid.
///
/// The proof-of-payment sheet called `submitProofOfPayment`: synchronous,
/// local-only, uploading nothing and reporting nothing. It set the payment to
/// Pending on the device, recorded a `paymentReceived` notification, and
/// resolved the Order of Payment, Overdue and Rejected reminders — then said
/// "Proof of payment submitted. The Treasurer's Office will verify it."
///
/// A citizen who had genuinely paid at the bank sent their receipt nowhere,
/// lost every reminder that would have told them, and waited on an office
/// holding no record of the payment. A correct `attachPayment` — receipt
/// uploaded first, then reported — sat beside it and nothing called it.

final _paidOn = DateTime(2026, 9, 1);

DocumentModel _receipt() => DocumentModel(
  id: 'receipt',
  label: 'Deposit slip',
  fileName: 'receipt.jpg',
  uploadedAt: _paidOn,
  filePath: '/tmp/receipt.jpg',
);

ApplicationModel _application() => ApplicationModel(
  id: 'app-1',
  applicationNumber: 'E-BPCO-2026-000145',
  businessId: '',
  businessName: 'Juan dela Cruz',
  type: ApplicationType.newPermit,
  status: ApplicationStatus.paymentVerification,
  submittedDate: DateTime(2026, 8, 1),
  payment: PaymentAssessmentModel(
    status: PaymentAssessmentStatus.notYetAvailable,
    orderOfPayment: OrderOfPayment(
      number: 'OP-2026-004821',
      assessedAt: DateTime(2026, 8, 10),
      assessedBy: 'Assessment Section, OBO',
      dueDate: DateTime(2026, 9, 9),
      fees: const AssessmentFees(filing: 50000, processing: 120000),
    ),
  ),
);

class _Repository implements ApplicationsRepository {
  _Repository({this.fails = false});
  final bool fails;
  int calls = 0;

  @override
  Future<ApplicationModel> attachPayment(
    String applicationId, {
    required PaymentMethod method,
    required String referenceNumber,
    required DateTime paidOn,
    PesoAmount? amountPaid,
    DocumentModel? proof,
    String? documentId,
  }) async {
    calls++;
    if (fails) throw const ApiException(ApiFailure.network, 'offline');
    final application = _application();
    return application.copyWith(
      payment: application.payment!.copyWith(
        status: PaymentAssessmentStatus.pending,
        referenceNumber: referenceNumber,
        proof: proof,
        paidOn: paidOn,
      ),
    );
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
  Future<ApplicationModel> resubmitDocument(
    String applicationId, {
    required String documentId,
    required DocumentModel replacement,
  }) => throw UnimplementedError();
  @override
  Future<ApplicationModel> resubmitInstruction(
    String applicationId,
    String letterId, {
    required List<String> itemIds,
    Map<String, String> responses = const {},
  }) => throw UnimplementedError();
  @override
  Future<ApplicationModel> advanceStatus(String id) =>
      throw UnimplementedError();
}

Future<(ApplicationsProvider, NotificationsProvider)> _build(
  _Repository repository,
) async {
  final notifications = NotificationsProvider(
    repository: MockNotificationsRepository(),
  );
  final provider = ApplicationsProvider(
    notifications: notifications,
    repository: repository,
  );
  await Future.delayed(const Duration(milliseconds: 400));
  return (provider, notifications);
}

void main() {
  test('reporting a payment reaches the office', () async {
    final repository = _Repository();
    final (provider, _) = await _build(repository);

    await provider.attachPayment(
      'app-1',
      method: PaymentMethod.bankTransfer,
      referenceNumber: 'BT-99881',
      paidOn: _paidOn,
      proof: _receipt(),
    );

    expect(repository.calls, 1);
    expect(
      provider.byId('app-1')!.payment!.status,
      PaymentAssessmentStatus.pending,
    );
  });

  test('a payment the office refused clears no reminder', () async {
    // The heart of it. The local-only version resolved Order of Payment,
    // Overdue and Rejected unconditionally — so a citizen whose report never
    // left the phone also lost every prompt that would have told them.
    final repository = _Repository(fails: true);
    final (provider, notifications) = await _build(repository);
    notifications.record(
      NotificationType.orderOfPaymentIssued,
      applicationId: 'app-1',
      applicationNumber: 'E-BPCO-2026-000145',
    );
    final before = notifications.events
        .where((n) => n.type == NotificationType.orderOfPaymentIssued)
        .length;

    await expectLater(
      provider.attachPayment(
        'app-1',
        method: PaymentMethod.bankTransfer,
        referenceNumber: 'BT-99881',
        paidOn: _paidOn,
        proof: _receipt(),
      ),
      throwsA(isA<ApiException>()),
    );

    expect(
      provider.byId('app-1')!.payment!.status,
      PaymentAssessmentStatus.notYetAvailable,
      reason: 'the office never heard, so nothing about it has changed',
    );
    expect(
      notifications.events
          .where((n) => n.type == NotificationType.orderOfPaymentIssued)
          .length,
      before,
      reason: 'the citizen still owes this money and must still be told',
    );
  });
}
