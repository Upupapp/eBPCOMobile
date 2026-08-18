import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ebpco_user_app/core/models/document_model.dart';
import 'package:ebpco_user_app/core/models/notification_event.dart';
import 'package:ebpco_user_app/core/models/professional_model.dart';
import 'package:ebpco_user_app/core/providers/notifications_provider.dart';
import 'package:ebpco_user_app/core/repositories/notifications_repository.dart';
import 'package:ebpco_user_app/features/profile/presentation/notification_preferences_screen.dart';

class _EmptyRepository implements NotificationsRepository {
  @override
  Future<List<NotificationEvent>> fetchAll() async => const [];
}

Widget _wrap(NotificationsProvider provider) => ChangeNotifierProvider.value(
  value: provider,
  child: const MaterialApp(home: NotificationPreferencesScreen()),
);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('preferences genuinely gate delivery', () {
    testWidgets('turning Payment Notifications off suppresses its push', (
      tester,
    ) async {
      final provider = NotificationsProvider(repository: _EmptyRepository());
      await tester.pumpWidget(_wrap(provider));
      await tester.pump(const Duration(seconds: 3));

      // Before: an Order of Payment would reach the applicant.
      expect(
        provider.record(NotificationType.orderOfPaymentIssued).pushSuppressed,
        isFalse,
      );

      await tester.tap(
        find.ancestor(
          of: find.text('Payment Notifications'),
          matching: find.byType(SwitchListTile),
        ),
      );
      await tester.pumpAndSettle();

      // After: the push is suppressed and the feed entry is still recorded.
      final after = provider.record(NotificationType.orderOfPaymentIssued);
      expect(after.pushSuppressed, isTrue);
      expect(provider.events, contains(after));

      // And an unrelated category is untouched.
      expect(
        provider.record(NotificationType.approved).pushSuppressed,
        isFalse,
      );
    });

    testWidgets('the screen reflects the delivering provider, not a copy', (
      tester,
    ) async {
      final provider = NotificationsProvider(repository: _EmptyRepository());
      await tester.pumpWidget(_wrap(provider));
      await tester.pump(const Duration(seconds: 3));

      await tester.tap(
        find.ancestor(
          of: find.text('Application Updates'),
          matching: find.byType(SwitchListTile),
        ),
      );
      await tester.pumpAndSettle();

      expect(provider.preferences.applicationUpdates, isFalse);
      expect(
        provider.shouldPush(
          NotificationType.applicationSubmitted,
          at: DateTime(2026, 8, 18, 10),
        ),
        isFalse,
      );
    });
  });

  group('professional credentials', () {
    ProfessionalModel professional({
      required DateTime prcValidity,
      required DateTime ptrIssued,
    }) => ProfessionalModel(
      id: 'pro-1',
      fullName: 'Arch. Maria Santos',
      discipline: ProfessionalDiscipline.architect,
      prcNumber: 'PRC-0001',
      prcValidityDate: prcValidity,
      ptrNumber: 'PTR-0001',
      ptrDateIssued: ptrIssued,
      ptrPlaceIssued: 'Quezon City',
    );

    final asOf = DateTime(2026, 8, 18);

    test('a PRC lapsing inside 60 days needs attention before it expires', () {
      final soon = professional(
        prcValidity: DateTime(2026, 10, 1),
        ptrIssued: DateTime(2026, 1, 10),
      );

      expect(soon.isPrcExpired(asOf), isFalse);
      expect(soon.prcDaysRemaining(asOf), 44);
      expect(
        soon.prcNeedsAttention(asOf),
        isTrue,
        reason: 'there must be time to renew before the next filing',
      );
    });

    test('a PRC with plenty of time left is quiet', () {
      final fine = professional(
        prcValidity: DateTime(2027, 6, 1),
        ptrIssued: DateTime(2026, 1, 10),
      );
      expect(fine.prcNeedsAttention(asOf), isFalse);
    });

    test('an expired PRC reports as expired, not merely due', () {
      final expired = professional(
        prcValidity: DateTime(2026, 5, 1),
        ptrIssued: DateTime(2026, 1, 10),
      );
      expect(expired.isPrcExpired(asOf), isTrue);
      expect(expired.prcDaysRemaining(asOf), lessThan(0));
    });

    test('a PTR from last year is stale', () {
      // A Professional Tax Receipt covers the calendar year it was issued in,
      // so last year's will not be accepted on a new filing.
      final stale = professional(
        prcValidity: DateTime(2027, 6, 1),
        ptrIssued: DateTime(2025, 1, 10),
      );
      expect(stale.isPtrStale(asOf), isTrue);

      final current = professional(
        prcValidity: DateTime(2027, 6, 1),
        ptrIssued: DateTime(2026, 1, 10),
      );
      expect(current.isPtrStale(asOf), isFalse);
    });
  });

  group('authorised representatives', () {
    final asOf = DateTime(2026, 8, 18);

    test('cannot act without both the SPA and a valid ID', () {
      const bare = AuthorizedRepresentative(
        id: 'rep-1',
        fullName: 'Pedro Santos',
        relationship: 'Brother',
      );

      expect(bare.canAct, isFalse);
      expect(
        bare.blockingReason(asOf),
        'Needs a notarised Special Power of Attorney and a valid ID.',
      );
    });

    test('names the one thing still missing', () {
      final idOnly = AuthorizedRepresentative(
        id: 'rep-1',
        fullName: 'Pedro Santos',
        relationship: 'Brother',
        validId: _document(),
      );
      expect(
        idOnly.blockingReason(asOf),
        'Needs a notarised Special Power of Attorney.',
      );
    });

    test('a complete, current representative can act', () {
      final complete = AuthorizedRepresentative(
        id: 'rep-1',
        fullName: 'Pedro Santos',
        relationship: 'Brother',
        specialPowerOfAttorney: _document(),
        validId: _document(),
        authorizedUntil: DateTime(2026, 12, 31),
      );
      expect(complete.canAct, isTrue);
      expect(complete.blockingReason(asOf), isNull);
    });

    test('a lapsed authorisation blocks even a complete record', () {
      final lapsed = AuthorizedRepresentative(
        id: 'rep-1',
        fullName: 'Pedro Santos',
        relationship: 'Brother',
        specialPowerOfAttorney: _document(),
        validId: _document(),
        authorizedUntil: DateTime(2026, 6, 30),
      );
      expect(lapsed.isExpired(asOf), isTrue);
      expect(lapsed.blockingReason(asOf), 'Their authorisation has lapsed.');
    });
  });
}

DocumentModel _document() => DocumentModel(
  id: 'doc-1',
  label: 'Attachment',
  fileName: 'attachment.pdf',
  uploadedAt: DateTime(2026, 8, 1),
);
