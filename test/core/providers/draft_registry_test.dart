import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:ebpco_user_app/core/models/draft_summary.dart';

void main() {
  group('DraftSummary', () {
    DraftSummary summary({DateTime? saved, int completed = 3, int total = 9}) =>
        DraftSummary(
          permitTypeLabel: 'New Construction',
          lastSavedAt: saved,
          completedSteps: completed,
          totalSteps: total,
          route: '/applications/new/building-permit',
        );

    final asOf = DateTime(2026, 8, 19);

    test('reports progress as a whole percentage', () {
      expect(summary(completed: 3, total: 9).percentComplete, 33);
      expect(summary(completed: 9, total: 9).percentComplete, 100);
      expect(summary(completed: 0, total: 9).percentComplete, 0);
      // The Certificate of Occupancy wizard is five steps, not nine.
      expect(summary(completed: 1, total: 5).percentComplete, 20);
    });

    test('a never-saved draft is not idle', () {
      // It cannot be stale, because it has never been anything else.
      final fresh = summary(saved: null);
      expect(fresh.daysSinceSaved(asOf), isNull);
      expect(fresh.isIdle(asOf), isFalse);
    });

    test('a draft saved today is not idle', () {
      expect(summary(saved: asOf).isIdle(asOf), isFalse);
    });

    test('six days is not idle, seven is', () {
      // Seven rather than one or two: an applicant is usually waiting on a
      // professional, a clearance, or a notary, and a few days is the normal
      // shape of the task rather than neglect.
      expect(summary(saved: DateTime(2026, 8, 13)).isIdle(asOf), isFalse);
      expect(summary(saved: DateTime(2026, 8, 12)).isIdle(asOf), isTrue);
    });

    test('ignores the time of day', () {
      expect(
        summary(saved: DateTime(2026, 8, 12, 23, 59)).daysSinceSaved(asOf),
        7,
      );
    });
  });

  group('the registry cannot go stale', () {
    // Provider resolves by type, so the sixteen wizard providers have to be
    // named in DraftRegistry by hand. This is the guard: adding a permit
    // provider that implements DraftSource without registering it fails here
    // rather than silently never producing an idle-draft nudge.
    test('every provider implementing DraftSource is registered', () {
      final providerDir = Directory('lib/core/providers');
      final implementers = <String>{};

      for (final file in providerDir.listSync().whereType<File>()) {
        if (!file.path.endsWith('_provider.dart')) continue;
        final source = file.readAsStringSync();
        if (!source.contains('implements DraftSource')) continue;
        final match = RegExp(
          r'class (\w+) extends ChangeNotifier implements DraftSource',
        ).firstMatch(source);
        if (match != null) implementers.add(match.group(1)!);
      }

      final registry = File(
        'lib/core/providers/draft_registry.dart',
      ).readAsStringSync();

      // Nineteen: the sixteen original wizards plus Zoning, FSEC and FSIC — the
      // three permit types the admin portal recognised and this app could not
      // file.
      expect(
        implementers,
        hasLength(19),
        reason: 'every wizard provider should expose its draft',
      );

      final unregistered = implementers
          .where((name) => !registry.contains('context.read<$name>()'))
          .toList();

      expect(
        unregistered,
        isEmpty,
        reason:
            'these implement DraftSource but are missing from DraftRegistry, '
            'so their drafts would never be seen: $unregistered',
      );
    });

    test('the registry names nothing that does not exist', () {
      final registry = File(
        'lib/core/providers/draft_registry.dart',
      ).readAsStringSync();
      final named = RegExp(
        r'context\.read<(\w+)>\(\)',
      ).allMatches(registry).map((m) => m.group(1)!).toList();

      expect(named, hasLength(19));
      expect(named.toSet(), hasLength(19), reason: 'no duplicates');
    });
  });
}
