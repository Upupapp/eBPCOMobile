import 'package:flutter_test/flutter_test.dart';

import 'package:ebpco_user_app/core/contract/admin_vocabulary.dart';
import 'package:ebpco_user_app/core/models/application_model.dart';
import 'package:ebpco_user_app/core/models/document_model.dart';
import 'package:ebpco_user_app/core/models/lifecycle_status.dart';
import 'package:ebpco_user_app/core/models/notification_event.dart';
import 'package:ebpco_user_app/core/models/money.dart';
import 'package:ebpco_user_app/core/models/order_of_payment.dart';
import 'package:ebpco_user_app/core/models/payment_assessment_model.dart';
import 'package:ebpco_user_app/core/notifications/notification_evaluator.dart';

/// The four states TABs 02, 06, 07 and 09 gave the applicant, and nobody had a
/// way to announce.
///
/// Each is something the office decides and the applicant must act on. Before
/// contract 0.2.0 they existed in the models, rendered on the detail screen,
/// and reached the applicant only if they happened to open the app and look.

const _evaluator = NotificationEvaluator();
final _asOf = DateTime(2026, 8, 18, 10);

DocumentModel _document({
  String id = 'doc-1',
  String label = 'Certified True Copy of Title',
  DocumentStatus? status,
  String? remarks,
  List<DocumentSubmission> history = const [],
}) => DocumentModel(
  id: id,
  label: label,
  fileName: 'title.pdf',
  uploadedAt: DateTime(2026, 8, 1),
  status: status,
  remarks: remarks,
  history: history,
);

PaymentTransactionRecord _transaction({
  String id = 'txn-1',
  PaymentTransactionStatus status = PaymentTransactionStatus.rejected,
  String? rejectionReason = 'Deposit slip is illegible.',
}) => PaymentTransactionRecord(
  id: id,
  amount: const PesoAmount(250000),
  method: PaymentMethod.bankTransfer,
  reference: 'DEP-0001',
  status: status,
  submittedAt: DateTime(2026, 8, 10),
  rejectionReason: rejectionReason,
  agency: CollectingAgency.oboLgu,
);

ApplicationModel _application({
  List<DocumentModel> documents = const [],
  PaymentAssessmentModel? payment,
  String permitType = 'Fencing Permit',
  String? permitNumber,
  DateTime? issuedDate,
  ApplicationLifecycleStatus lifecycleStatus =
      ApplicationLifecycleStatus.underEvaluation,
}) => ApplicationModel(
  id: 'app-1',
  applicationNumber: 'E-BPCO-2026-000145',
  businessId: 'biz-1',
  businessName: 'Dela Cruz Construction',
  type: ApplicationType.newPermit,
  status: lifecycleStatus.applicantStatus,
  submittedDate: DateTime(2026, 8, 1),
  lifecycleStatus: lifecycleStatus,
  classification: null,
  permitTypeLabel: permitType,
  permitNumber: permitNumber,
  issuedDate: issuedDate,
  documents: documents,
  payment: payment,
);

List<DerivedNotification> _derive(ApplicationModel application) =>
    _evaluator.evaluate(applications: [application], asOf: _asOf);

Iterable<DerivedNotification> _of(
  List<DerivedNotification> all,
  NotificationType type,
) => all.where((d) => d.type == type);

void main() {
  group('a document the office turned back', () {
    test('raises one notice carrying the remarks', () {
      final derived = _derive(
        _application(
          documents: [
            _document(
              status: DocumentStatus.rejected,
              remarks: 'The title is not a certified true copy.',
            ),
          ],
        ),
      );

      final notice = _of(derived, NotificationType.documentRejected).single;
      expect(notice.payload['document'], 'Certified True Copy of Title');
      expect(
        notice.payload['remarks'],
        'The title is not a certified true copy.',
      );
    });

    test('one notice per document, not one per application', () {
      // Merging them into "3 documents need attention" throws away the
      // remarks, which are the only part that says what to do.
      final derived = _derive(
        _application(
          documents: [
            _document(id: 'a', label: 'Title', status: DocumentStatus.rejected),
            _document(
              id: 'b',
              label: 'Lot Plan',
              status: DocumentStatus.revisionRequired,
            ),
            _document(id: 'c', label: 'Cedula'),
          ],
        ),
      );

      final notices = _of(derived, NotificationType.documentRejected).toList();
      expect(notices, hasLength(2));
      expect(
        notices.map((n) => n.payload['document']),
        containsAll(['Title', 'Lot Plan']),
      );
      // Each keyed on its own document, or the second would dedupe away.
      expect(notices.map((n) => n.dedupeKey).toSet(), hasLength(2));
    });

    test('an accepted document raises nothing', () {
      final derived = _derive(
        _application(
          documents: [
            _document(status: DocumentStatus.accepted),
            _document(id: 'b', status: DocumentStatus.submitted),
            _document(id: 'c'),
          ],
        ),
      );
      expect(_of(derived, NotificationType.documentRejected), isEmpty);
    });

    test('a corrected copy turned back again raises a fresh notice', () {
      // The key carries the attempt count, so the second rejection is not
      // swallowed by the first notice having been resolved.
      final first = _derive(
        _application(documents: [_document(status: DocumentStatus.rejected)]),
      );
      final second = _derive(
        _application(
          documents: [
            _document(
              status: DocumentStatus.rejected,
              history: [
                DocumentSubmission(
                  fileName: 'title-v1.pdf',
                  submittedAt: DateTime(2026, 8, 1),
                  status: DocumentStatus.rejected,
                ),
              ],
            ),
          ],
        ),
      );

      expect(
        _of(first, NotificationType.documentRejected).single.dedupeKey,
        isNot(_of(second, NotificationType.documentRejected).single.dedupeKey),
      );
    });

    test('the same rejection twice is the same key', () {
      final application = _application(
        documents: [_document(status: DocumentStatus.rejected)],
      );
      expect(
        _of(
          _derive(application),
          NotificationType.documentRejected,
        ).single.dedupeKey,
        _of(
          _derive(application),
          NotificationType.documentRejected,
        ).single.dedupeKey,
      );
    });
  });

  group('a payment the office refused', () {
    test('raises a notice carrying the reason', () {
      final derived = _derive(
        _application(
          payment: PaymentAssessmentModel(
            status: PaymentAssessmentStatus.pending,
            transactions: [_transaction()],
          ),
        ),
      );

      final notice = _of(derived, NotificationType.paymentRejected).single;
      expect(notice.payload['reason'], 'Deposit slip is illegible.');
      // Action, not information: the amount is still owed.
      expect(notice.type.priority, NotificationPriority.action);
    });

    test('one per refused attempt', () {
      final derived = _derive(
        _application(
          payment: PaymentAssessmentModel(
            status: PaymentAssessmentStatus.pending,
            transactions: [
              _transaction(id: 'txn-1'),
              _transaction(id: 'txn-2', rejectionReason: 'Amount short.'),
              _transaction(
                id: 'txn-3',
                status: PaymentTransactionStatus.verified,
                rejectionReason: null,
              ),
            ],
          ),
        ),
      );

      expect(_of(derived, NotificationType.paymentRejected), hasLength(2));
    });
  });

  group('a superseded assessment', () {
    PaymentAssessmentModel reassessed() => PaymentAssessmentModel(
      status: PaymentAssessmentStatus.pending,
      orderOfPayment: OrderOfPayment(
        number: 'OP-2026-0002',
        assessedAt: DateTime(2026, 8, 12),
        dueDate: DateTime(2026, 8, 30),
        fees: const AssessmentFees(filing: 50000),
        version: 2,
        revisionReason: 'Floor area corrected after ocular inspection',
      ),
      supersededOrders: [
        OrderOfPayment(
          number: 'OP-2026-0001',
          assessedAt: DateTime(2026, 8, 5),
          dueDate: DateTime(2026, 8, 25),
          fees: const AssessmentFees(filing: 30000),
          status: AssessmentStatus.superseded,
        ),
      ],
    );

    test('is announced with the reason it was revised', () {
      final notice = _of(
        _derive(_application(payment: reassessed())),
        NotificationType.assessmentSuperseded,
      ).single;

      expect(
        notice.payload['reason'],
        'Floor area corrected after ocular inspection',
      );
      expect(notice.dedupeKey, contains('v2'));
    });

    test('is progress, not an action', () {
      // The replacement order raises its own orderOfPaymentIssued with the new
      // total. Two action notices disagreeing about what is owed is worse than
      // one saying less.
      expect(
        NotificationType.assessmentSuperseded.priority,
        NotificationPriority.progress,
      );
    });

    test('a first assessment is not a supersession', () {
      final derived = _derive(
        _application(
          payment: PaymentAssessmentModel(
            status: PaymentAssessmentStatus.pending,
            orderOfPayment: OrderOfPayment(
              number: 'OP-2026-0001',
              assessedAt: DateTime(2026, 8, 5),
              dueDate: DateTime(2026, 8, 25),
              fees: const AssessmentFees(filing: 30000),
            ),
          ),
        ),
      );
      expect(_of(derived, NotificationType.assessmentSuperseded), isEmpty);
    });
  });

  group('a permit running out of validity', () {
    ApplicationModel issued(String type, DateTime issuedDate) => _application(
      permitType: type,
      permitNumber: 'BP-2026-000145',
      issuedDate: issuedDate,
      lifecycleStatus: ApplicationLifecycleStatus.released,
    );

    test('warns on the validity date, not the commencement date', () {
      // A six-month permit issued 1 Jul 2026 is valid to 1 Jan 2027 and
      // commencable to 1 Jul 2027. Only the first is anywhere near.
      final derived = _derive(
        issued(CanonicalPermitType.fencingPermit.wire, DateTime(2026, 4, 1)),
      );

      final notice = _of(derived, NotificationType.permitExpiryWarning).single;
      expect(notice.payload['date'], '2026-10-01');
      expect(notice.payload['days'], '44');
      expect(
        _of(derived, NotificationType.permitCommencementWarning),
        isEmpty,
        reason: 'commencement is still eight months away',
      );
    });

    test('both are raised when both are near, under separate keys', () {
      // A twelve-month permit's two dates coincide. They are still two
      // obligations, and one key namespace would silence one of them.
      final derived = _derive(
        issued(
          CanonicalPermitType.buildingPermitNewConstruction.wire,
          DateTime(2025, 9, 1),
        ),
      );

      expect(_of(derived, NotificationType.permitExpiryWarning), hasLength(1));
      expect(
        _of(derived, NotificationType.permitCommencementWarning),
        hasLength(1),
      );
      final keys = derived.map((d) => d.dedupeKey).toSet();
      expect(keys, hasLength(derived.length));
    });

    test('a Certificate of Occupancy never expires, so is never warned', () {
      final derived = _derive(
        issued(
          CanonicalPermitType.certificateOfOccupancy.wire,
          DateTime(2025, 9, 1),
        ),
      );
      expect(_of(derived, NotificationType.permitExpiryWarning), isEmpty);
    });

    test('the warning buckets rather than repeating daily', () {
      final sixty = _of(
        _derive(
          issued(CanonicalPermitType.fencingPermit.wire, DateTime(2026, 4, 1)),
        ),
        NotificationType.permitExpiryWarning,
      ).single;
      final thirty = _of(
        _derive(
          issued(CanonicalPermitType.fencingPermit.wire, DateTime(2026, 3, 1)),
        ),
        NotificationType.permitExpiryWarning,
      ).single;

      expect(sixty.dedupeKey, endsWith(':60'));
      expect(thirty.dedupeKey, endsWith(':30'));
    });
  });

  test('every new type deep-links somewhere it can be dealt with', () {
    const cases = {
      NotificationType.documentRejected: '/applications/app-1',
      NotificationType.paymentRejected: '/applications/app-1/pay',
      NotificationType.assessmentSuperseded: '/applications/app-1/pay',
      NotificationType.permitExpiryWarning: '/applications/app-1/permit',
    };
    cases.forEach((type, link) {
      final event = NotificationEvent(
        id: 'n-1',
        type: type,
        createdAt: _asOf,
        applicationId: 'app-1',
      );
      expect(event.deepLink, link, reason: type.name);
    });
  });

  test('the new codes do not renumber the existing catalog', () {
    // `code` is derived from the enum index, and the code is what an applicant
    // is quoted. Inserting anywhere earlier would silently rewrite them.
    expect(NotificationType.applicationSubmitted.code, 'N-01');
    expect(NotificationType.occupancyNowPossible.code, 'N-24');
    expect(NotificationType.documentRejected.code, 'N-25');
    expect(NotificationType.permitExpiryWarning.code, 'N-28');
    expect(NotificationType.accountUpdate.code, isNull);
  });
}
