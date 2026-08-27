import 'package:flutter_test/flutter_test.dart';

import 'package:ebpco_user_app/core/models/application_model.dart';
import 'package:ebpco_user_app/core/models/draft_summary.dart';
import 'package:ebpco_user_app/core/models/lifecycle_status.dart';
import 'package:ebpco_user_app/core/models/notification_event.dart';
import 'package:ebpco_user_app/core/models/permit_classification.dart';
import 'package:ebpco_user_app/core/models/professional_model.dart';
import 'package:ebpco_user_app/core/notifications/notification_evaluator.dart';
import 'package:ebpco_user_app/core/providers/notifications_provider.dart';
import 'package:ebpco_user_app/core/repositories/notifications_repository.dart';

class _EmptyRepository implements NotificationsRepository {
  @override
  Future<List<NotificationEvent>> fetchAll() async => const [];
}

const _evaluator = NotificationEvaluator();
final _asOf = DateTime(2026, 8, 18, 10);

ApplicationModel _application({
  String id = 'app-1',
  ApplicationLifecycleStatus lifecycleStatus =
      ApplicationLifecycleStatus.underEvaluation,
  PermitClassification? classification = PermitClassification.simple,
  DateTime? filedOn,
  String? permitNumber,
  DateTime? issuedDate,
  String permitType = 'New Construction',
}) => ApplicationModel(
  id: id,
  applicationNumber: 'E-BPCO-2026-000145',
  businessId: 'biz-1',
  businessName: "Juan's General Merchandise",
  type: ApplicationType.newPermit,
  status: lifecycleStatus.applicantStatus,
  submittedDate: filedOn ?? DateTime(2026, 8, 17),
  lifecycleStatus: lifecycleStatus,
  classification: classification,
  permitTypeLabel: permitType,
  permitNumber: permitNumber,
  issuedDate: issuedDate,
);

ProfessionalModel _professional({DateTime? prcValidity, String id = 'pro-1'}) =>
    ProfessionalModel(
      id: id,
      fullName: 'Arch. Maria Santos',
      discipline: ProfessionalDiscipline.architect,
      prcNumber: 'PRC-0001',
      prcValidityDate: prcValidity ?? DateTime(2027, 6, 1),
      ptrNumber: 'PTR-0001',
      ptrDateIssued: DateTime(2026, 1, 10),
      ptrPlaceIssued: 'Quezon City',
    );

List<NotificationType> _types(List<DerivedNotification> d) =>
    d.map((e) => e.type).toList();

void main() {
  group('service pledge', () {
    test('a lapsed pledge is derived', () {
      // Simple: 3 working days from Mon 3 Aug is Wed 5 Aug; by 18 Aug it has
      // long gone.
      final derived = _evaluator.evaluate(
        applications: [_application(filedOn: DateTime(2026, 8, 3))],
        asOf: _asOf,
      );

      expect(_types(derived), contains(NotificationType.pledgeLapsed));
      expect(
        derived.first.type.priority,
        NotificationPriority.action,
        reason: 'a breached service pledge is something to act on',
      );
    });

    test('an approaching pledge is derived, and only one of the two', () {
      // Filed Mon 17 Aug, simple, so due Wed 19 Aug — one working day left on
      // Tue 18th.
      final derived = _evaluator.evaluate(
        applications: [_application(filedOn: DateTime(2026, 8, 17))],
        asOf: _asOf,
      );

      expect(_types(derived), [NotificationType.pledgeApproaching]);
      expect(
        _types(derived),
        isNot(contains(NotificationType.pledgeLapsed)),
        reason: 'a pledge cannot be both approaching and lapsed',
      );
    });

    test('an unclassified application yields no pledge notification', () {
      // No classification means no pledge, so nothing to be early or late
      // against — the same rule Home follows when it shows "Awaiting
      // classification".
      final derived = _evaluator.evaluate(
        applications: [
          _application(classification: null, filedOn: DateTime(2026, 1, 5)),
        ],
        asOf: _asOf,
      );

      expect(derived, isEmpty);
    });

    test('a finished application yields no pledge notification', () {
      final derived = _evaluator.evaluate(
        applications: [
          _application(
            lifecycleStatus: ApplicationLifecycleStatus.completed,
            filedOn: DateTime(2026, 1, 5),
            permitType: 'Certificate of Occupancy',
          ),
        ],
        asOf: _asOf,
      );

      expect(_types(derived), isNot(contains(NotificationType.pledgeLapsed)));
    });
  });

  group('PD 1096 commencement', () {
    List<DerivedNotification> forIssue(DateTime issued) => _evaluator.evaluate(
      applications: [
        _application(
          lifecycleStatus: ApplicationLifecycleStatus.released,
          classification: null,
          permitNumber: 'BP-2026-0001',
          issuedDate: issued,
        ),
      ],
      asOf: _asOf,
    );

    test('silent while more than 60 days remain', () {
      // Issued 1 Jun 2026 → commence by 1 Jun 2027, ~287 days out.
      final derived = forIssue(DateTime(2026, 6, 1));
      expect(
        _types(derived),
        isNot(contains(NotificationType.permitCommencementWarning)),
      );
    });

    test('warns inside 60 days', () {
      // Issued 1 Oct 2025 → commence by 1 Oct 2026, 44 days out.
      final derived = forIssue(DateTime(2025, 10, 1));
      final warning = derived.firstWhere(
        (d) => d.type == NotificationType.permitCommencementWarning,
      );

      expect(warning.payload['days'], '44');
      expect(warning.payload['permitNumber'], 'BP-2026-0001');
    });

    test('buckets 60, 30, and lapsed so it is said three times, not daily', () {
      // The evaluator runs on every load; without bucketing an applicant
      // would collect one of these per launch for two months.
      String keyFor(DateTime issued) => forIssue(issued)
          .firstWhere(
            (d) => d.type == NotificationType.permitCommencementWarning,
          )
          .dedupeKey;

      final sixty = keyFor(DateTime(2025, 10, 1)); // 44 days
      final thirty = keyFor(DateTime(2025, 9, 1)); // 14 days
      final lapsed = keyFor(DateTime(2025, 1, 1)); // long gone

      expect(sixty, endsWith(':60'));
      expect(thirty, endsWith(':30'));
      expect(lapsed, endsWith(':lapsed'));
      expect({sixty, thirty, lapsed}, hasLength(3));
    });
  });

  group('occupancy', () {
    test('a released construction permit invites an occupancy filing', () {
      final derived = _evaluator.evaluate(
        applications: [
          _application(
            lifecycleStatus: ApplicationLifecycleStatus.released,
            classification: null,
            permitNumber: 'BP-2026-0001',
            issuedDate: DateTime(2026, 6, 1),
          ),
        ],
        asOf: _asOf,
      );

      expect(_types(derived), contains(NotificationType.occupancyNowPossible));
    });

    test('a released Certificate of Occupancy does not invite another', () {
      // Otherwise the app tells the applicant to file the thing it has just
      // told them they were granted.
      final derived = _evaluator.evaluate(
        applications: [
          _application(
            lifecycleStatus: ApplicationLifecycleStatus.released,
            classification: null,
            permitType: 'Certificate of Occupancy',
            permitNumber: 'CO-2026-0001',
            issuedDate: DateTime(2026, 6, 1),
          ),
        ],
        asOf: _asOf,
      );

      expect(
        _types(derived),
        isNot(contains(NotificationType.occupancyNowPossible)),
      );
    });
  });

  group('professional credentials', () {
    test('a PRC lapsing inside 60 days is derived', () {
      final derived = _evaluator.evaluate(
        applications: const [],
        professionals: [_professional(prcValidity: DateTime(2026, 10, 1))],
        asOf: _asOf,
      );

      expect(_types(derived), [
        NotificationType.professionalCredentialExpiring,
      ]);
      expect(derived.single.payload['professional'], 'Arch. Maria Santos');
    });

    test('a current PRC is silent', () {
      final derived = _evaluator.evaluate(
        applications: const [],
        professionals: [_professional()],
        asOf: _asOf,
      );

      expect(derived, isEmpty);
    });

    test('renewing re-arms the warning rather than silencing it forever', () {
      String keyFor(DateTime validity) => _evaluator
          .evaluate(
            applications: const [],
            professionals: [_professional(prcValidity: validity)],
            asOf: _asOf,
          )
          .single
          .dedupeKey;

      // Same professional, a renewed licence, a later expiry — a new key, so
      // the next expiry is announced too.
      expect(
        keyFor(DateTime(2026, 10, 1)),
        isNot(keyFor(DateTime(2026, 9, 20))),
      );
    });
  });

  group('idle drafts', () {
    DraftSummary draft({
      required DateTime? saved,
      String route = '/w/building',
    }) => DraftSummary(
      permitTypeLabel: 'New Construction',
      lastSavedAt: saved,
      completedSteps: 3,
      totalSteps: 9,
      route: route,
    );

    test('an untouched draft is nudged with its progress', () {
      final derived = _evaluator.evaluate(
        applications: const [],
        drafts: [draft(saved: DateTime(2026, 8, 5))],
        asOf: _asOf,
      );

      expect(_types(derived), [NotificationType.draftIdle]);
      expect(derived.single.payload['percent'], '33');
      expect(derived.single.payload['days'], '13');
    });

    test('a recently-saved draft is left alone', () {
      final derived = _evaluator.evaluate(
        applications: const [],
        drafts: [draft(saved: DateTime(2026, 8, 17))],
        asOf: _asOf,
      );

      expect(derived, isEmpty);
    });

    test('it links back into the wizard, not the catalog', () {
      // Making someone re-pick a permit they are part-way through is how a
      // draft gets abandoned for good.
      final derived = _evaluator.evaluate(
        applications: const [],
        drafts: [draft(saved: DateTime(2026, 8, 5), route: '/w/fencing')],
        asOf: _asOf,
      );

      final event = NotificationEvent(
        id: 'e',
        type: derived.single.type,
        payload: derived.single.payload,
        createdAt: _asOf,
      );
      expect(event.deepLink, '/w/fencing');
    });

    test('editing and abandoning again re-arms the nudge', () {
      String keyFor(DateTime saved) => _evaluator
          .evaluate(
            applications: const [],
            drafts: [draft(saved: saved)],
            asOf: _asOf,
          )
          .single
          .dedupeKey;

      // Same draft, touched on a later day and abandoned again — a new key,
      // so the applicant is nudged about the new lapse rather than never
      // again.
      expect(keyFor(DateTime(2026, 8, 5)), isNot(keyFor(DateTime(2026, 8, 8))));
    });
  });

  group('recording into the feed', () {
    NotificationsProvider provider() => NotificationsProvider(
      repository: _EmptyRepository(),
      clock: () => _asOf,
    );

    test('a derived condition reaches the feed once, not once per load', () {
      final notifications = provider();
      final applications = [_application(filedOn: DateTime(2026, 8, 3))];

      List<DerivedNotification> run() =>
          _evaluator.evaluate(applications: applications, asOf: _asOf);

      expect(notifications.recordDerived(run()), 1);
      // The condition still holds, so the evaluator still derives it. The feed
      // must not grow.
      expect(notifications.recordDerived(run()), 0);
      expect(notifications.recordDerived(run()), 0);

      expect(
        notifications.events.where(
          (e) => e.type == NotificationType.pledgeLapsed,
        ),
        hasLength(1),
      );
    });

    test('a lapsed pledge shows up as an outstanding action', () {
      final notifications = provider();
      notifications.recordDerived(
        _evaluator.evaluate(
          applications: [_application(filedOn: DateTime(2026, 8, 3))],
          asOf: _asOf,
        ),
      );

      expect(notifications.actionBadgeCount, 1);
      expect(notifications.needsAction.single.body, contains('service pledge'));
    });

    test('two different conditions both land', () {
      final notifications = provider();
      final added = notifications.recordDerived(
        _evaluator.evaluate(
          applications: [_application(filedOn: DateTime(2026, 8, 3))],
          professionals: [_professional(prcValidity: DateTime(2026, 10, 1))],
          asOf: _asOf,
        ),
      );

      expect(added, 2);
      expect(notifications.events, hasLength(2));
    });

    test('derived events still obey the delivery rules', () {
      // Quiet hours apply to a derived progress event exactly as to a
      // server-sent one; deriving something locally is not a licence to
      // interrupt.
      final night = DateTime(2026, 8, 18, 23);
      final notifications = NotificationsProvider(
        repository: _EmptyRepository(),
        clock: () => night,
      );

      notifications.recordDerived(
        _evaluator.evaluate(
          applications: const [],
          professionals: [_professional(prcValidity: DateTime(2026, 10, 1))],
          asOf: night,
        ),
      );

      expect(notifications.events.single.pushSuppressed, isTrue);
    });
  });
}
