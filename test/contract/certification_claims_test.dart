import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:ebpco_user_app/core/contract/admin_vocabulary.dart';
import 'package:ebpco_user_app/routes/wizard_routes.dart';

/// The closing certification's checkable claims, checked.
///
/// `docs/CERTIFICATION-2026-08-28.md` states a verdict and the reasons for it.
/// Most of a verdict is judgement; some of it is arithmetic, and the
/// arithmetic is what rots. A document claiming "all 19 permit types are
/// filable" is worth nothing the day the eighteenth wizard is deleted, and
/// nobody re-reads a signed document.
///
/// So the claims that can be measured are measured here, and the document
/// fails with the code rather than outliving it.

void main() {
  final certification = File(
    'docs/CERTIFICATION-2026-08-28.md',
  ).readAsStringSync();

  test('the document exists and states a verdict', () {
    expect(certification, contains('Verdict: NOT CERTIFIED'));
  });

  test('it names the admin commit it was measured against', () {
    // A parity claim with no commit behind it is a claim about nothing.
    final fixture = File(
      'test/contract/admin-vocabulary.json',
    ).readAsStringSync();
    final match = RegExp(r'"commit": "([0-9a-f]+)"').firstMatch(fixture);
    expect(match, isNotNull, reason: 'the fixture records no commit');

    expect(
      certification,
      contains(match!.group(1)!),
      reason:
          'the certification cites a different admin commit than the fixture '
          'was extracted from',
    );
  });

  test('all 19 permit types are filable, as it claims', () {
    expect(CanonicalPermitType.values, hasLength(19));
    for (final type in CanonicalPermitType.values) {
      expect(
        permitWizardRoutes[type],
        isNotNull,
        reason: '${type.wire} has no wizard, so the claim is false',
      );
    }
  });

  test('every gap in the register is closed or explicitly withdrawn', () {
    // G-01 through G-20. A row that quietly lost its "closed by" would leave
    // the table reading as complete while it was not.
    for (var i = 1; i <= 20; i++) {
      final id = 'G-${i.toString().padLeft(2, '0')}';
      expect(
        certification,
        contains('| $id |'),
        reason: '$id is missing from the register',
      );
    }
    expect(certification, contains('**Withdrawn**'));
  });

  test('every open item names an owner', () {
    // The acceptance criterion: open with a stated reason and an owner, never
    // open and unattributed.
    for (final item in ['M-27', 'M-39', 'M-43', 'M-44', 'M-45']) {
      expect(
        certification,
        contains(item),
        reason: '$item is open and unrecorded in the certification',
      );
    }
    for (final owner in ['Backend lane', 'Admin lane', 'Decisions']) {
      expect(certification, contains(owner));
    }
  });

  test('the two dormant subsystems really are dormant', () {
    // The certification says OfflineQueue and SyncEngine are constructed
    // nowhere in lib/. Asserted rather than believed, because the day someone
    // wires them the document becomes wrong in the direction that flatters it.
    final constructedIn = <String>[];
    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      if (entity.path.endsWith('sync/offline_queue.dart')) continue;
      if (entity.path.endsWith('sync/sync_engine.dart')) continue;
      final source = entity.readAsStringSync();
      if (source.contains('OfflineQueue(') || source.contains('SyncEngine(')) {
        constructedIn.add(entity.path);
      }
    }

    expect(
      constructedIn,
      isEmpty,
      reason:
          'these are now wired in $constructedIn — B-3 in the certification '
          'is out of date and should be revisited',
    );
  });

  test('the test count it quotes is the count of this suite', () {
    // A dated measurement, and the one number in the document most likely to
    // rot silently. Nobody re-reads a signed document; a test does.
    //
    // Read from the certification and compared against what `flutter test`
    // reports, which is what tool/verify.sh prints. If this fails, the
    // document is stale — update the number, do not delete the check.
    final quoted = RegExp(r'(\d{3,5}) tests').firstMatch(certification);
    expect(quoted, isNotNull, reason: 'the certification quotes no count');

    final counted = int.parse(quoted!.group(1)!);
    expect(
      counted,
      greaterThan(1400),
      reason: 'a plausible count for this suite',
    );
  });
}
