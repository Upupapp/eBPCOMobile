import '../core/models/application_detail.dart';
import '../core/models/order_of_payment.dart';
import '../core/models/application_model.dart';
import '../core/models/document_model.dart';
import '../core/models/lifecycle_status.dart';
import '../core/models/payment_assessment_model.dart';
import '../core/models/permit_classification.dart';

/// Seed data for [MockApplicationsRepository] — one in-progress application
/// against the seed business so the dashboard isn't empty on first login.
ApplicationModel buildSeedApplication() {
  final submitted = DateTime.now().subtract(const Duration(days: 3));
  return ApplicationModel(
    id: 'app-seed-1',
    applicationNumber: 'E-BPCO-2026-000145',
    businessId: 'biz-seed-1',
    businessName: "Juan's General Merchandise",
    type: ApplicationType.newPermit,
    status: ApplicationStatus.underReview,
    // The admin's finer-grained state. `status` above is its projection and
    // stays in place for screens that still bind to it directly.
    lifecycleStatus: ApplicationLifecycleStatus.underEvaluation,
    // A New Construction building permit is classified highly technical, so
    // RA 11032 allows 20 working days.
    classification: PermitClassification.highlyTechnical,
    permitTypeLabel: 'New Construction',
    submittedDate: submitted,
    documents: [
      DocumentModel(
        id: 'doc-seed-1',
        label: 'Valid Government ID',
        fileName: 'valid_id.jpg',
        uploadedAt: submitted,
      ),
      DocumentModel(
        id: 'doc-seed-2',
        label: 'Barangay Clearance',
        fileName: 'barangay_clearance.pdf',
        uploadedAt: submitted,
      ),
    ],
    statusHistory: [
      StatusHistoryEntry(status: ApplicationStatus.submitted, timestamp: submitted),
      StatusHistoryEntry(
        status: ApplicationStatus.underReview,
        timestamp: submitted.add(const Duration(hours: 5)),
      ),
    ],
    timeline: [
      TimelineEntry(
        status: ApplicationLifecycleStatus.submitted,
        occurredAt: submitted,
        office: 'eBPCO Mobile',
      ),
      TimelineEntry(
        status: ApplicationLifecycleStatus.received,
        occurredAt: submitted.add(const Duration(hours: 2)),
        office: 'Office of the Building Official',
      ),
      TimelineEntry(
        status: ApplicationLifecycleStatus.documentVerification,
        occurredAt: submitted.add(const Duration(hours: 5)),
        office: 'Office of the Building Official',
      ),
      TimelineEntry(
        status: ApplicationLifecycleStatus.underEvaluation,
        occurredAt: submitted.add(const Duration(days: 1)),
        office: 'Office of the Building Official',
      ),
    ],
    // An Order of Payment already assessed but not yet settled — the state
    // the Payments tab exists to handle.
    payment: PaymentAssessmentModel(
      status: PaymentAssessmentStatus.notYetAvailable,
      orderOfPayment: OrderOfPayment(
        number: 'OP-2026-004821',
        assessedAt: submitted.add(const Duration(days: 2)),
        assessedBy: 'Assessment Section, OBO',
        dueDate: submitted.add(const Duration(days: 32)),
        fees: const AssessmentFees(
          filing: 50000,
          processing: 120000,
          architectural: 285050,
          structural: 341275,
          electrical: 96500,
          others: 42000,
        ),
      ),
    ),
    evaluations: [
      EvaluationRecord(
        stage: EvaluationStage.initial,
        result: EvaluationResult.passed,
        evaluator: 'Engr. R. Villanueva',
        evaluatedAt: submitted.add(const Duration(hours: 6)),
      ),
      EvaluationRecord(
        stage: EvaluationStage.zoning,
        result: EvaluationResult.passed,
        evaluator: 'Arch. L. Bautista',
        evaluatedAt: submitted.add(const Duration(days: 1)),
      ),
      const EvaluationRecord(
        stage: EvaluationStage.fireSafety,
        result: EvaluationResult.pending,
      ),
    ],
  );
}
