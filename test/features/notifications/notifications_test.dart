import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ebpco_user_app/core/models/notification_event.dart';
import 'package:ebpco_user_app/core/models/notification_preferences_model.dart';
import 'package:ebpco_user_app/core/providers/notifications_provider.dart';
import 'package:ebpco_user_app/core/repositories/notifications_repository.dart';
import 'package:ebpco_user_app/features/notifications/presentation/notifications_screen.dart';

class _FakeRepository implements NotificationsRepository {
  _FakeRepository(this.events);
  final List<NotificationEvent> events;

  @override
  Future<List<NotificationEvent>> fetchAll() async => events;
}

final _now = DateTime(2026, 8, 18, 10);

NotificationEvent _event(
  NotificationType type, {
  String id = 'e1',
  DateTime? createdAt,
  DateTime? readAt,
  DateTime? resolvedAt,
}) => NotificationEvent(
  id: id,
  type: type,
  applicationId: 'app-1',
  applicationNumber: 'E-BPCO-2026-000145',
  payload: const {'count': '2', 'stage': 'Zoning'},
  createdAt: createdAt ?? _now,
  readAt: readAt,
  resolvedAt: resolvedAt,
);

Widget _wrap(List<NotificationEvent> events) {
  final router = GoRouter(
    initialLocation: '/notifications',
    routes: [
      GoRoute(
        path: '/notifications',
        builder: (_, _) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/applications/:id/instructions',
        builder: (_, _) => const Scaffold(body: Text('LOI screen')),
      ),
      GoRoute(path: '/applications/:id', builder: (_, _) => const Scaffold()),
      GoRoute(
        path: '/applications/:id/pay',
        builder: (_, _) => const Scaffold(),
      ),
    ],
  );

  return ChangeNotifierProvider<NotificationsProvider>(
    create: (_) => NotificationsProvider(
      repository: _FakeRepository(events),
      clock: () => _now,
    ),
    child: MaterialApp.router(routerConfig: router),
  );
}

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(seconds: 3));
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('work queue ordering', () {
    testWidgets('an old action outranks a fresh update', (tester) async {
      await tester.pumpWidget(
        _wrap([
          _event(
            NotificationType.evaluationStagePassed,
            id: 'fresh',
            createdAt: _now,
          ),
          _event(
            NotificationType.letterOfInstructionIssued,
            id: 'old',
            createdAt: _now.subtract(const Duration(days: 12)),
          ),
        ]),
      );
      await _settle(tester);

      final actionY = tester
          .getTopLeft(find.text('Letter of Instruction issued'))
          .dy;
      final updateY = tester.getTopLeft(find.text('Zoning passed')).dy;

      expect(
        actionY,
        lessThan(updateY),
        reason: 'resolution, not chronology, orders this screen',
      );
      expect(find.text('Needs your action (1)'), findsOneWidget);
      expect(find.text('Updates (1)'), findsOneWidget);
    });

    testWidgets('a resolved action drops out of the action section', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap([
          _event(
            NotificationType.letterOfInstructionIssued,
            resolvedAt: _now,
          ),
        ]),
      );
      await _settle(tester);

      expect(find.text('Needs your action'), findsNothing);
      expect(find.text('Earlier (1)'), findsOneWidget);
    });
  });

  group('reading is not resolving', () {
    testWidgets('mark all read leaves outstanding actions in place', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap([
          _event(NotificationType.letterOfInstructionIssued, id: 'a'),
          _event(NotificationType.orderOfPaymentIssued, id: 'b'),
          _event(NotificationType.evaluationStagePassed, id: 'c'),
        ]),
      );
      await _settle(tester);

      final provider = Provider.of<NotificationsProvider>(
        tester.element(find.byType(NotificationsScreen)),
        listen: false,
      );
      expect(provider.actionBadgeCount, 2);

      await tester.tap(find.byTooltip('Mark all read'));
      await tester.pumpAndSettle();

      expect(provider.unreadCount, 0);
      expect(
        provider.actionBadgeCount,
        2,
        reason: 'the badge counts things you must do, not things unread',
      );
      expect(find.text('Needs your action (2)'), findsOneWidget);
    });

    testWidgets('tapping marks read and opens where it can be dealt with', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap([_event(NotificationType.letterOfInstructionIssued)]),
      );
      await _settle(tester);

      final provider = Provider.of<NotificationsProvider>(
        tester.element(find.byType(NotificationsScreen)),
        listen: false,
      );

      await tester.tap(find.text('Letter of Instruction issued'));
      await tester.pumpAndSettle();

      expect(find.text('LOI screen'), findsOneWidget);
      expect(provider.events.single.isRead, isTrue);
      expect(
        provider.events.single.isOutstandingAction,
        isTrue,
        reason: 'opening it corrects nothing',
      );
    });
  });

  group('delivery rules', () {
    test('muting a category suppresses push but still records the entry', () {
      final provider = NotificationsProvider(
        repository: _FakeRepository(const []),
        clock: () => _now,
        preferences: const NotificationPreferences(
          paymentNotifications: false,
        ),
      );

      final event = provider.record(
        NotificationType.orderOfPaymentIssued,
        applicationId: 'app-1',
        applicationNumber: 'E-BPCO-2026-000145',
      );

      expect(event.pushSuppressed, isTrue);
      expect(provider.events, contains(event));
      expect(
        provider.actionBadgeCount,
        1,
        reason: 'muting reduces interruption, not the record',
      );
    });

    test('an unmuted category pushes', () {
      final provider = NotificationsProvider(
        repository: _FakeRepository(const []),
        clock: () => _now,
      );
      final event = provider.record(NotificationType.orderOfPaymentIssued);
      expect(event.pushSuppressed, isFalse);
    });

    test('ambient events never push, whatever the preferences', () {
      final provider = NotificationsProvider(
        repository: _FakeRepository(const []),
        clock: () => _now,
      );
      expect(
        provider.shouldPush(NotificationType.draftIdle, at: _now),
        isFalse,
      );
    });

    test('quiet hours hold progress events but not urgent ones', () {
      final provider = NotificationsProvider(
        repository: _FakeRepository(const []),
      );
      final night = DateTime(2026, 8, 18, 22, 30);
      final morning = DateTime(2026, 8, 18, 9);

      expect(provider.isQuietHour(night), isTrue);
      expect(provider.isQuietHour(morning), isFalse);

      expect(
        provider.shouldPush(NotificationType.evaluationStagePassed, at: night),
        isFalse,
      );
      // A deficiency or an overdue payment can cost the applicant their
      // application; it is allowed through.
      expect(
        provider.shouldPush(NotificationType.paymentOverdue, at: night),
        isTrue,
      );
    });

    test('the master push switch overrides everything', () {
      final provider = NotificationsProvider(
        repository: _FakeRepository(const []),
        preferences: const NotificationPreferences(pushNotifications: false),
      );
      expect(
        provider.shouldPush(NotificationType.paymentOverdue, at: _now),
        isFalse,
      );
    });
  });

  group('filters', () {
    testWidgets('unread-only hides what has been read', (tester) async {
      await tester.pumpWidget(
        _wrap([
          _event(NotificationType.evaluationStagePassed, id: 'read', readAt: _now),
          _event(
            NotificationType.approved,
            id: 'unread',
            createdAt: _now.subtract(const Duration(hours: 1)),
          ),
        ]),
      );
      await _settle(tester);

      expect(find.text('Zoning passed'), findsOneWidget);
      expect(find.text('Application approved'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.filter_alt_outlined));
      await tester.pumpAndSettle();

      expect(find.text('Zoning passed'), findsNothing);
      expect(find.text('Application approved'), findsOneWidget);
    });
  });
}
