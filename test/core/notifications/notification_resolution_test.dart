import 'package:flutter_test/flutter_test.dart';

import 'package:ebpco_user_app/core/models/money.dart';
import 'package:ebpco_user_app/core/models/application_lineage.dart';
import 'package:ebpco_user_app/core/models/application_model.dart';
import 'package:ebpco_user_app/core/models/document_model.dart';
import 'package:ebpco_user_app/core/models/notification_event.dart';
import 'package:ebpco_user_app/core/models/payment_assessment_model.dart';
import 'package:ebpco_user_app/core/notifications/notification_evaluator.dart';
import 'package:ebpco_user_app/core/providers/applications_provider.dart';
import 'package:ebpco_user_app/core/providers/notifications_provider.dart';
import 'package:ebpco_user_app/core/repositories/applications_repository.dart';
import 'package:ebpco_user_app/core/repositories/notifications_repository.dart';

/// Reading is not resolving, and resolving one thing is not resolving three.
///
/// The first half was already the app's rule and is asserted here for the new
/// types. The second is new: `resolveFor` clears every notice of a type on an
/// application, which is right for an Order of Payment — there is one — and
/// wrong for a turned-back document, because an application can carry several
/// and each is its own obligation.

class _EmptyRepository implements NotificationsRepository {
  @override
  Future<List<NotificationEvent>> fetchAll() async => const [];
}

final _now = DateTime(2026, 8, 18, 10);

NotificationsProvider _provider() =>
    NotificationsProvider(repository: _EmptyRepository(), clock: () => _now);

DerivedNotification _rejection(String documentId, {int attempt = 0}) =>
    DerivedNotification(
      type: NotificationType.documentRejected,
      dedupeKey: 'documentRejected:app-1:$documentId:$attempt',
      applicationId: 'app-1',
      payload: {'document': documentId},
    );

void main() {
  test('a rejection notice survives being read', () {
    final provider = _provider();
    provider.recordDerived([_rejection('doc-1')]);

    provider.markAllAsRead();

    final event = provider.events.single;
    expect(event.isRead, isTrue);
    expect(
      event.isResolved,
      isFalse,
      reason: 'opening a rejection has not corrected the document',
    );
    expect(event.isOutstandingAction, isTrue);
  });

  test('resubmitting one document resolves only its own notice', () {
    final provider = _provider();
    provider.recordDerived([
      _rejection('doc-1'),
      _rejection('doc-2'),
      _rejection('doc-3'),
    ]);
    expect(provider.needsAction, hasLength(3));

    provider.resolveByDedupeKeyPrefix('documentRejected:app-1:doc-2:');

    final outstanding = provider.needsAction
        .map((e) => e.payload['document'])
        .toSet();
    expect(outstanding, {
      'doc-1',
      'doc-3',
    }, reason: 'correcting one document does not correct the other two');
  });

  test(
    'the prefix matches whatever attempt the standing notice was raised on',
    () {
      // The derived key carries the submission count, so by the time the
      // applicant resubmits, the key the caller would compute has moved on from
      // the one on the notice that is actually outstanding.
      final provider = _provider();
      provider.recordDerived([_rejection('doc-1', attempt: 2)]);

      provider.resolveByDedupeKeyPrefix('documentRejected:app-1:doc-1:');

      expect(provider.needsAction, isEmpty);
    },
  );

  test('a prefix does not reach a different document that starts the same', () {
    // 'doc-1' must not swallow 'doc-10'. The trailing colon is what keeps them
    // apart, and it is easy to leave off.
    final provider = _provider();
    provider.recordDerived([_rejection('doc-1'), _rejection('doc-10')]);

    provider.resolveByDedupeKeyPrefix('documentRejected:app-1:doc-1:');

    expect(provider.needsAction.map((e) => e.payload['document']), ['doc-10']);
  });

  test('an already-resolved notice is not re-stamped', () {
    final provider = _provider();
    provider.recordDerived([_rejection('doc-1')]);
    provider.resolveByDedupeKeyPrefix('documentRejected:app-1:');
    final first = provider.events.single.resolvedAt;

    provider.resolveByDedupeKeyPrefix('documentRejected:app-1:');

    expect(provider.events.single.resolvedAt, first);
  });

  group('quiet hours reach the new types too', () {
    test('a progress notice is held back at night', () {
      final night = NotificationsProvider(
        repository: _EmptyRepository(),
        clock: () => DateTime(2026, 8, 18, 22),
      );
      final event = night.record(NotificationType.assessmentSuperseded);
      expect(event.pushSuppressed, isTrue);
    });

    test('an action notice is not', () {
      // A payment refused is money still owed against a deadline. The app's
      // existing rule is that P1 overrides quiet hours, and the new types
      // inherit it rather than restating it.
      final night = NotificationsProvider(
        repository: _EmptyRepository(),
        clock: () => DateTime(2026, 8, 18, 22),
      );
      expect(
        night.record(NotificationType.paymentRejected).pushSuppressed,
        isFalse,
      );
      expect(
        night.record(NotificationType.permitExpiryWarning).pushSuppressed,
        isFalse,
      );
      expect(
        night.record(NotificationType.documentRejected).pushSuppressed,
        isFalse,
      );
    });
  });

  test('muting a category still records the feed entry', () {
    final provider = _provider();
    provider.updatePreferences(
      provider.preferences.copyWith(paymentNotifications: false),
    );

    final event = provider.record(NotificationType.paymentRejected);

    expect(event.pushSuppressed, isTrue);
    expect(
      provider.events,
      hasLength(1),
      reason: 'the LGU must be able to show it told the applicant',
    );
  });

  test('the wiring holds end to end: resubmitting through the provider '
      'resolves that document and no other', () async {
    // The prefix is built in two places — the evaluator when it derives the
    // key, and ApplicationsProvider when it resolves — and a test of either
    // alone would pass while the two disagreed about the shape.
    final notifications = _provider();
    // The provider's constructor kicks off a fetch that replaces the feed
    // wholesale, so anything recorded before it settles is wiped. The
    // synchronous tests above never yield and so never see it; this one
    // awaits, and would otherwise assert against an empty feed and pass for
    // the wrong reason.
    await Future<void>.delayed(Duration.zero);

    final applications = ApplicationsProvider(
      notifications: notifications,
      repository: _ResubmitRepository(),
      clock: () => _now,
    );

    notifications.recordDerived([_rejection('doc-1'), _rejection('doc-2')]);

    await applications.resubmitDocument(
      'app-1',
      documentId: 'doc-1',
      replacement: DocumentModel(
        id: 'doc-1',
        label: 'Title',
        fileName: 'title-v2.pdf',
        uploadedAt: _now,
      ),
    );

    expect(notifications.needsAction.map((e) => e.payload['document']), [
      'doc-2',
    ]);
  });
}

/// Answers the resubmission without needing the seeded fixture, so the test is
/// about the notification wiring rather than about what the mock contains.
class _ResubmitRepository implements ApplicationsRepository {
  @override
  Future<List<ApplicationModel>> fetchAll() async => const [];

  @override
  Future<ApplicationModel> resubmitDocument(
    String applicationId, {
    required String documentId,
    required DocumentModel replacement,
  }) async => ApplicationModel(
    id: applicationId,
    applicationNumber: 'E-BPCO-2026-000145',
    businessId: 'biz-1',
    businessName: 'Dela Cruz Construction',
    type: ApplicationType.newPermit,
    status: ApplicationStatus.underReview,
    submittedDate: DateTime(2026, 8, 1),
    documents: [replacement],
  );

  @override
  Future<ApplicationModel> submitApplication({
    required String businessId,
    required String businessName,
    required ApplicationType type,
    required List<DocumentModel> documents,
    String? permitTypeLabel,
    String? applicationNumber,
    ApplicationLineage? lineage,
  }) => throw UnimplementedError();

  @override
  Future<ApplicationModel> attachPayment(
    String applicationId, {
    required PaymentMethod method,
    required String referenceNumber,
    required DateTime paidOn,
    PesoAmount? amountPaid,
    DocumentModel? proof,
  }) => throw UnimplementedError();

  @override
  Future<ApplicationModel> advanceStatus(String applicationId) =>
      throw UnimplementedError();
}
