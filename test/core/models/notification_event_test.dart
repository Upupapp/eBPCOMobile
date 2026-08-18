import 'package:flutter_test/flutter_test.dart';

import 'package:ebpco_user_app/core/models/notification_event.dart';

NotificationEvent _event(
  NotificationType type, {
  String? applicationId = 'app-1',
  Map<String, String> payload = const {},
}) => NotificationEvent(
  id: 'e-${type.name}',
  type: type,
  applicationId: applicationId,
  applicationNumber: 'E-BPCO-2026-000145',
  payload: payload,
  createdAt: DateTime(2026, 8, 18, 10),
);

/// The 24 numbered catalog entries. accountUpdate sits outside it by design.
final _catalog = NotificationType.values
    .where((t) => t != NotificationType.accountUpdate)
    .toList();

void main() {
  test('the catalog holds exactly 24 numbered entries', () {
    expect(_catalog, hasLength(24));
    expect(_catalog.first.code, 'N-01');
    expect(_catalog.last.code, 'N-24');
  });

  test('codes are unique and contiguous', () {
    final codes = _catalog.map((t) => t.code).toList();
    expect(codes.toSet(), hasLength(24));
    for (var i = 0; i < 24; i++) {
      expect(codes[i], 'N-${(i + 1).toString().padLeft(2, '0')}');
    }
  });

  test('every catalog entry renders a title, a body, and a deep link', () {
    for (final type in _catalog) {
      final event = _event(type);
      expect(event.title, isNotEmpty, reason: '${type.code} has no title');
      expect(event.body, isNotEmpty, reason: '${type.code} has no body');
      expect(
        event.deepLink,
        isNotEmpty,
        reason: '${type.code} has no destination',
      );
    }
  });

  test('every application-related body names its application reference', () {
    for (final type in _catalog) {
      final event = _event(type);
      final namesIt =
          event.body.contains('E-BPCO-2026-000145') ||
          // Three are genuinely not about one filed application: a
          // professional's credential, an unfinished draft, and the
          // invitation to start an occupancy filing.
          const {
            NotificationType.professionalCredentialExpiring,
            NotificationType.draftIdle,
            NotificationType.occupancyNowPossible,
          }.contains(type);
      expect(namesIt, isTrue, reason: '${type.code} does not name its subject');
    }
  });

  test('no deep link points at a bare tab root when an application is known', () {
    const tabRoots = {
      '/app/home',
      '/app/applications',
      '/app/payments',
      '/app/notifications',
      '/app/profile',
    };
    for (final type in _catalog) {
      final link = _event(type).deepLink;
      expect(
        tabRoots.contains(link),
        isFalse,
        reason: '${type.code} deep-links to the tab root $link',
      );
    }
  });

  test('the nine action-priority events are the ones demanding a response', () {
    final action = _catalog
        .where((t) => t.priority == NotificationPriority.action)
        .toSet();

    expect(action, {
      NotificationType.letterOfInstructionIssued,
      NotificationType.revisionRequired,
      NotificationType.orderOfPaymentIssued,
      NotificationType.paymentOverdue,
      NotificationType.readyForRelease,
      NotificationType.rejected,
      NotificationType.inspectionScheduled,
      NotificationType.pledgeLapsed,
      NotificationType.permitCommencementWarning,
    });
  });

  test('ambient events never push', () {
    for (final type in _catalog) {
      if (type.priority == NotificationPriority.ambient) {
        expect(type.priority.pushesByDefault, isFalse, reason: '${type.code}');
      }
    }
  });

  test('an action event is outstanding until resolved, not until read', () {
    final event = _event(NotificationType.letterOfInstructionIssued);
    expect(event.isOutstandingAction, isTrue);

    final read = event.copyWith(readAt: DateTime(2026, 8, 18, 11));
    expect(read.isRead, isTrue);
    expect(
      read.isOutstandingAction,
      isTrue,
      reason: 'opening a letter corrects nothing',
    );

    final resolved = read.copyWith(resolvedAt: DateTime(2026, 8, 18, 12));
    expect(resolved.isOutstandingAction, isFalse);
  });

  test('progress and ambient events are never outstanding actions', () {
    for (final type in _catalog) {
      if (type.priority == NotificationPriority.action) continue;
      expect(_event(type).isOutstandingAction, isFalse, reason: '${type.code}');
    }
  });

  test('remarks are carried verbatim into the body', () {
    final event = _event(
      NotificationType.revisionRequired,
      payload: const {
        'stage': 'OBO',
        'remarks': 'Structural plan lacks the engineer’s dry seal.',
      },
    );
    expect(
      event.body,
      contains('Structural plan lacks the engineer’s dry seal.'),
    );
  });
}
