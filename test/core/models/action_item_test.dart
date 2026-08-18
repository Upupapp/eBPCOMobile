import 'package:flutter_test/flutter_test.dart';

import 'package:ebpco_user_app/core/models/action_item.dart';
import 'package:ebpco_user_app/core/models/application_model.dart';
import 'package:ebpco_user_app/core/models/lifecycle_status.dart';
import 'package:ebpco_user_app/core/models/order_of_payment.dart';
import 'package:ebpco_user_app/core/models/payment_assessment_model.dart';

ApplicationModel _application({
  String id = 'app-1',
  ApplicationLifecycleStatus? lifecycleStatus,
  int openInstructionCount = 0,
  PaymentAssessmentModel? payment,
  String? permitNumber,
  DateTime? issuedDate,
}) {
  return ApplicationModel(
    id: id,
    applicationNumber: 'E-BPCO-2026-000145',
    businessId: 'biz-1',
    businessName: "Juan's General Merchandise",
    type: ApplicationType.newPermit,
    status: lifecycleStatus?.applicantStatus ?? ApplicationStatus.underReview,
    submittedDate: DateTime(2026, 8, 1),
    lifecycleStatus: lifecycleStatus,
    permitTypeLabel: 'New Construction',
    openInstructionCount: openInstructionCount,
    payment: payment,
    permitNumber: permitNumber,
    issuedDate: issuedDate,
  );
}

void main() {
  const builder = ActionItemBuilder();
  final asOf = DateTime(2026, 8, 18);

  test('a quiet application produces no action items', () {
    final items = builder.build([
      _application(lifecycleStatus: ApplicationLifecycleStatus.underEvaluation),
    ], asOf: asOf);

    expect(items, isEmpty);
  });

  test('an open Letter of Instruction produces one item', () {
    final items = builder.build([
      _application(
        lifecycleStatus: ApplicationLifecycleStatus.documentVerification,
        openInstructionCount: 3,
      ),
    ], asOf: asOf);

    expect(items, hasLength(1));
    expect(items.single.kind, ActionItemKind.letterOfInstruction);
    expect(items.single.detail, contains('3 items'));
  });

  test('a single deficiency is described in the singular', () {
    final items = builder.build([
      _application(openInstructionCount: 1),
    ], asOf: asOf);

    expect(items.single.detail, contains('1 item must'));
  });

  test('Revision Required produces an item despite a passive headline', () {
    final application = _application(
      lifecycleStatus: ApplicationLifecycleStatus.revisionRequired,
    );

    // The applicant-visible headline gives no hint that the applicant is the
    // one holding this up — which is exactly why the action flag exists.
    expect(application.applicantStatus, ApplicationStatus.underReview);
    expect(application.requiresApplicantAction, isTrue);

    final items = builder.build([application], asOf: asOf);
    expect(items.single.kind, ActionItemKind.revisionRequired);
  });

  test('Assessed produces a payment-due item', () {
    final items = builder.build([
      _application(lifecycleStatus: ApplicationLifecycleStatus.assessed),
    ], asOf: asOf);

    expect(items.single.kind, ActionItemKind.paymentDue);
    expect(items.single.route, '/applications/app-1/pay');
  });

  test('an overdue assessment outranks a merely due one', () {
    final items = builder.build([
      _application(
        id: 'app-due',
        lifecycleStatus: ApplicationLifecycleStatus.assessed,
      ),
      _application(
        id: 'app-overdue',
        lifecycleStatus: ApplicationLifecycleStatus.assessed,
        payment: PaymentAssessmentModel(
          status: PaymentAssessmentStatus.overdue,
          orderOfPayment: OrderOfPayment(
            number: 'OP-2026-000001',
            assessedAt: DateTime(2026, 8, 10),
            fees: const AssessmentFees(filing: 50000, processing: 475000),
          ),
        ),
      ),
    ], asOf: asOf);

    expect(items.first.kind, ActionItemKind.overduePayment);
    expect(items.first.applicationId, 'app-overdue');
  });

  test('Ready for Release produces a claim item', () {
    final items = builder.build([
      _application(
        lifecycleStatus: ApplicationLifecycleStatus.readyForRelease,
        permitNumber: 'BP-2026-0001',
      ),
    ], asOf: asOf);

    expect(items.single.kind, ActionItemKind.readyForRelease);
    expect(items.single.detail, contains('BP-2026-0001'));
  });

  group('PD 1096 commencement deadline', () {
    test('is silent while the permit has more than 60 days left', () {
      final items = builder.build([
        _application(
          lifecycleStatus: ApplicationLifecycleStatus.released,
          permitNumber: 'BP-2026-0001',
          issuedDate: DateTime(2026, 6, 1),
        ),
      ], asOf: asOf);

      expect(items, isEmpty);
    });

    test('warns inside 60 days of the one-year lapse', () {
      // Issued 1 Oct 2025 → must commence by 1 Oct 2026, 44 days after asOf.
      final items = builder.build([
        _application(
          lifecycleStatus: ApplicationLifecycleStatus.released,
          permitNumber: 'BP-2025-0900',
          issuedDate: DateTime(2025, 10, 1),
        ),
      ], asOf: asOf);

      expect(items.single.kind, ActionItemKind.commencementWarning);
      expect(items.single.detail, contains('44 day'));
    });

    test('reports a permit whose deadline has already passed', () {
      final items = builder.build([
        _application(
          lifecycleStatus: ApplicationLifecycleStatus.released,
          permitNumber: 'BP-2025-0001',
          issuedDate: DateTime(2025, 1, 1),
        ),
      ], asOf: asOf);

      expect(items.single.title, 'Permit may have lapsed');
    });
  });

  test('items sort by regulatory urgency, not by application order', () {
    final items = builder.build([
      _application(
        id: 'app-release',
        lifecycleStatus: ApplicationLifecycleStatus.readyForRelease,
      ),
      _application(id: 'app-loi', openInstructionCount: 2),
      _application(
        id: 'app-overdue',
        lifecycleStatus: ApplicationLifecycleStatus.assessed,
        payment: PaymentAssessmentModel(
          status: PaymentAssessmentStatus.overdue,
          orderOfPayment: OrderOfPayment(
            number: 'OP-2026-000001',
            assessedAt: DateTime(2026, 8, 10),
            fees: const AssessmentFees(filing: 50000, processing: 475000),
          ),
        ),
      ),
    ], asOf: asOf);

    expect(items.map((i) => i.kind).toList(), [
      ActionItemKind.overduePayment,
      ActionItemKind.letterOfInstruction,
      ActionItemKind.readyForRelease,
    ]);
  });
}
