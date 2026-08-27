import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ebpco_user_app/core/models/citizens_charter.dart';
import 'package:ebpco_user_app/features/profile/presentation/citizens_charter_screen.dart';

/// Every permit the catalog offers. Kept as a literal list rather than read
/// from the catalog widget so a permit added to one and not the other shows up
/// as a failure here.
const _catalogPermits = <String>[
  'New Construction',
  'Renovation',
  'Addition / Extension',
  'Demolition',
  'Architectural',
  'Civil / Structural',
  'Electrical',
  'Mechanical',
  'Sanitary / Plumbing',
  'Plumbing',
  'Electronics',
  'Interior',
  'Fencing',
  'Sign Permit',
  'Excavation',
  'Certificate of Occupancy',
];

void main() {
  group('charter data', () {
    test('every permit type in the catalog has a reachable entry', () {
      for (final permit in _catalogPermits) {
        final entry = charterFor(permit);
        expect(entry.permitType, permit, reason: permit);
        expect(entry.requirements, isNotEmpty, reason: permit);
        expect(entry.offices, isNotEmpty, reason: permit);
        expect(entry.feeBasis, isNotEmpty, reason: permit);
      }
    });

    test('every entry states a classification and a pledged period', () {
      for (final permit in _catalogPermits) {
        final entry = charterFor(permit);
        expect(
          const [3, 7, 20].contains(entry.pledgedWorkingDays),
          isTrue,
          reason:
              '$permit pledges ${entry.pledgedWorkingDays} days, which is '
              'not one of the RA 11032 periods',
        );
      }
    });

    test('every requirement names where to secure it', () {
      for (final permit in _catalogPermits) {
        for (final requirement in charterFor(permit).requirements) {
          expect(
            requirement.whereToSecure,
            isNotEmpty,
            reason: '$permit: "${requirement.item}" has no issuing office',
          );
        }
      }
    });

    test('no entry quotes a fee amount', () {
      // The app never states a figure the LGU has not assessed for the
      // specific application; the charter describes the basis only.
      for (final permit in _catalogPermits) {
        final basis = charterFor(permit).feeBasis;
        expect(basis, isNot(contains('PHP')), reason: permit);
        expect(
          RegExp(r'\d{3,}').hasMatch(basis),
          isFalse,
          reason: '$permit fee basis appears to quote an amount',
        );
      }
    });

    test(
      'notarised requirements are flagged as needing a wet-signed original',
      () {
        final application = charterFor(
          'New Construction',
        ).requirements.firstWhere((r) => r.item.contains('Unified Building'));
        expect(application.requiresNotarisation, isTrue);
      },
    );

    test('the occupancy entry reflects what an LGU actually asks for', () {
      final items = charterFor(
        'Certificate of Occupancy',
      ).requirements.map((r) => r.item).join(' ');

      // Drawn from a published LGU occupancy checklist: the shape of the
      // submission is a compilation task, not a short form.
      expect(items, contains('Certificate of Completion'));
      expect(items, contains('logbook'));
      expect(items, contains('Fire Safety Inspection Certificate'));
      expect(items, contains('Photographs'));
    });

    test(
      'an unlisted permit falls back to an ancillary entry, not an error',
      () {
        final entry = charterFor('Some Future Permit');
        expect(entry.permitType, 'Some Future Permit');
        expect(entry.requirements, isNotEmpty);
      },
    );
  });

  group('charter screen', () {
    testWidgets('renders the pledge, the fee basis, and where to secure', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(400, 3000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        const MaterialApp(
          home: CitizensCharterScreen(permitType: 'New Construction'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('New Construction'), findsOneWidget);
      expect(find.text('Highly Technical · 20 working days'), findsOneWidget);
      expect(find.textContaining('schedule of fees'), findsWidgets);
      expect(find.textContaining('Land Registration Authority'), findsWidgets);
      expect(
        find.textContaining('Anti-Red Tape Authority'),
        findsOneWidget,
        reason: 'the applicant needs to know what recourse exists',
      );
    });

    testWidgets('flags requirements needing a notarised original', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(400, 3000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        const MaterialApp(
          home: CitizensCharterScreen(permitType: 'New Construction'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Wet-signed notarised original required'), findsWidgets);
    });
  });
}
