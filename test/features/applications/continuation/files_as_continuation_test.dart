import 'package:flutter_test/flutter_test.dart';

import 'package:ebpco_user_app/core/models/money.dart';
import 'package:ebpco_user_app/core/models/application_lineage.dart';
import 'package:ebpco_user_app/core/models/application_model.dart';
import 'package:ebpco_user_app/core/models/document_model.dart';
import 'package:ebpco_user_app/core/models/payment_assessment_model.dart';
import 'package:ebpco_user_app/core/providers/applications_provider.dart';
import 'package:ebpco_user_app/core/providers/notifications_provider.dart';
import 'package:ebpco_user_app/core/repositories/applications_repository.dart';
import 'package:ebpco_user_app/core/repositories/notifications_repository.dart';

/// The acceptance criteria, at the point the application is actually created.
///
/// The screen tests above prove the lineage is set. This proves it survives
/// into the record — which is a different claim, and the one the office
/// depends on.

class _RecordingRepository implements ApplicationsRepository {
  ApplicationType? sawType;
  ApplicationLineage? sawLineage;

  @override
  Future<ApplicationModel> fetchDetail(String applicationId) async =>
      throw UnimplementedError();

  @override
  Future<List<ApplicationModel>> fetchAll() async => const [];

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
  }) async {
    sawType = type;
    sawLineage = lineage;
    return ApplicationModel(
      id: 'app-2',
      applicationNumber: applicationNumber ?? 'E-BPCO-2026-000200',
      businessId: businessId,
      businessName: businessName,
      type: type,
      status: ApplicationStatus.submitted,
      submittedDate: DateTime(2026, 8, 18),
      permitTypeLabel: permitTypeLabel,
      lineage: lineage,
    );
  }

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
  Future<ApplicationModel> advanceStatus(String applicationId) =>
      throw UnimplementedError();

  @override
  Future<ApplicationModel> resubmitInstruction(
    String applicationId,
    String letterId, {
    required List<String> itemIds,
    Map<String, String> responses = const {},
  }) async => throw UnimplementedError();
}

ApplicationsProvider _provider(_RecordingRepository repository) =>
    ApplicationsProvider(
      notifications: NotificationsProvider(
        repository: MockNotificationsRepository(),
      ),
      repository: repository,
      clock: () => DateTime(2026, 8, 18),
    );

void main() {
  test(
    'a renewal files with action Renewal and references the prior permit',
    () async {
      final repository = _RecordingRepository();
      final applications = _provider(repository);

      final filed = await applications.submitApplication(
        businessId: '',
        businessName: 'Dela Cruz Construction',
        // Deliberately the default a wizard would pass. The lineage has to win,
        // or a renewal reaches the office as a first-time application against a
        // permit that already exists.
        type: ApplicationType.newPermit,
        documents: const [],
        permitTypeLabel: 'Fencing Permit',
        lineage: ApplicationLineage.renewal(
          priorApplicationId: 'app-1',
          priorPermitNumber: 'BP-2026-000145',
          priorApplicationNumber: 'E-BPCO-2026-000145',
          permitTypeLabel: 'Fencing Permit',
        ),
      );

      expect(repository.sawType, ApplicationType.renewal);
      expect(filed.type, ApplicationType.renewal);
      expect(filed.lineage!.priorPermitNumber, 'BP-2026-000145');
      expect(filed.lineage!.priorApplicationId, 'app-1');
    },
  );

  test('an amendment references the amended application', () async {
    final repository = _RecordingRepository();
    final applications = _provider(repository);

    final filed = await applications.submitApplication(
      businessId: '',
      businessName: 'Dela Cruz Construction',
      type: ApplicationType.newPermit,
      documents: const [],
      permitTypeLabel: 'Fencing Permit',
      lineage: ApplicationLineage.amendment(
        priorApplicationId: 'app-1',
        priorApplicationNumber: 'E-BPCO-2026-000145',
        permitTypeLabel: 'Fencing Permit',
      ),
    );

    expect(filed.type, ApplicationType.amendment);
    expect(filed.lineage!.priorApplicationId, 'app-1');
    expect(filed.lineage!.priorApplicationNumber, 'E-BPCO-2026-000145');
  });

  test('a first filing carries no lineage and stays New', () async {
    final repository = _RecordingRepository();
    final applications = _provider(repository);

    final filed = await applications.submitApplication(
      businessId: '',
      businessName: 'Dela Cruz Construction',
      type: ApplicationType.newPermit,
      documents: const [],
      permitTypeLabel: 'Fencing Permit',
    );

    expect(filed.type, ApplicationType.newPermit);
    expect(filed.lineage, isNull);
  });
}
