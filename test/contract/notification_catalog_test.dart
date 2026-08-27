import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:ebpco_user_app/core/models/notification_event.dart';

/// Binds this app's notification catalog to the server's.
///
/// This test exists because the reconciliation it performs was skipped. TAB 01
/// compared the lifecycle vocabulary across both tiers and did not compare the
/// notification catalog — at that point this app's `NotificationType` had no
/// wire form at all, so there was nothing to compare against. The server then
/// invented one: twenty-four types with different names and five categories of
/// its own, against the twenty-five types and six categories already shipped
/// here with applicant-facing copy and a Settings screen the applicant uses to
/// mute them.
///
/// The server now adopts this app's vocabulary, mechanically: the wire name is
/// the kebab-case of the enum constant. This asserts it, and asserts that every
/// deep link the server will send is a route this app actually has — the
/// failure that guards against is silent and infuriating, because a
/// notification that goes nowhere when tapped is not something anyone files a
/// bug for. They just stop trusting notifications.
void main() {
  final contract =
      jsonDecode(
            File('test/contract/notification-catalog.json').readAsStringSync(),
          )
          as Map<String, dynamic>;
  final catalog = (contract['catalog'] as List).cast<Map<String, dynamic>>();

  /// kebab-case of a lowerCamelCase enum constant.
  String wireNameOf(String constant) => constant
      .replaceAllMapped(RegExp('(?<!^)([A-Z])'), (m) => '-${m[1]}')
      .toLowerCase();

  /// The application-scoped routes this app declares, read from the router
  /// itself — a hand-listed copy would drift the first time someone adds a
  /// screen.
  Set<String> declaredRoutes() {
    final source = File('lib/routes/app_router.dart').readAsStringSync();
    return RegExp(
      r"path: '(/applications/:applicationId[^']*)'",
    ).allMatches(source).map((match) => match.group(1)!).toSet();
  }

  group('contract: notification catalog', () {
    test('the vendored fixture is the one this test was written against', () {
      expect(contract['contractVersion'], '0.1.0');
    });

    test('the server carries exactly this app’s types', () {
      final fromContract = catalog
          .map((entry) => entry['type'] as String)
          .toSet();
      final fromApp = NotificationType.values
          .map((type) => wireNameOf(type.name))
          .toSet();

      expect(fromApp, hasLength(25));
      expect(
        fromContract,
        fromApp,
        reason:
            'a type in only one of the two is a notification one side can send '
            'and the other will reject',
      );
    });

    test('every type carries the same category the app assigns it', () {
      // The categories are the mute buckets in Settings. If the server groups a
      // notification differently, muting one thing silences another.
      final byWire = {
        for (final entry in catalog) entry['type'] as String: entry,
      };

      for (final type in NotificationType.values) {
        final entry = byWire[wireNameOf(type.name)];
        expect(
          entry,
          isNotNull,
          reason: '${type.name} is missing from the contract',
        );
        expect(
          entry!['category'],
          type.category.name,
          reason:
              '${type.name} is ${type.category.name} here and ${entry['category']} on the server',
        );
      }
    });

    test('requiresAction matches this app’s action priority', () {
      // The server derives `statutory` from this, and `statutory` decides
      // whether a notice is additionally sent by SMS. If the two disagree, an
      // applicant either misses a deadline or is texted about nothing.
      final byWire = {
        for (final entry in catalog) entry['type'] as String: entry,
      };

      for (final type in NotificationType.values) {
        expect(
          byWire[wireNameOf(type.name)]!['requiresAction'],
          type.priority == NotificationPriority.action,
          reason:
              '${type.name} disagrees with the server on whether it needs an act',
        );
      }
    });

    test('every deep link resolves to a route this app declares', () {
      final routes = declaredRoutes();

      // A test that found no routes would pass vacuously.
      expect(routes, isNotEmpty);

      final dead = <String>[];
      for (final entry in catalog) {
        final link = entry['deepLink'] as String;
        if (!routes.contains(link)) dead.add('${entry['type']} -> $link');
      }

      expect(
        dead,
        isEmpty,
        reason: 'these notifications would arrive and go nowhere when tapped',
      );
    });

    test(
      'an action-required notification points at the screen that resolves it',
      () {
        final byWire = {
          for (final entry in catalog) entry['type'] as String: entry,
        };

        expect(
          byWire['order-of-payment-issued']!['deepLink'],
          contains('/pay'),
        );
        expect(
          byWire['revision-required']!['deepLink'],
          contains('/instructions'),
        );
        expect(
          byWire['letter-of-instruction-issued']!['deepLink'],
          contains('/instructions'),
        );
        expect(byWire['ready-for-release']!['deepLink'], contains('/permit'));
      },
    );

    test(
      'the two this app derives locally are marked as never sent by the server',
      () {
        // A draft is local until it is filed, and a credential expiry is computed
        // from records held on the device.
        final clientOnly =
            catalog
                .where((entry) => entry['serverGenerated'] == false)
                .map((entry) => entry['type'] as String)
                .toList()
              ..sort();

        expect(clientOnly, ['draft-idle', 'professional-credential-expiring']);
      },
    );
  });
}
