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
  /// The most recent certification, by filename date.
  ///
  /// Pinned to one file until 31 August 2026, which is half of why the
  /// count check below went stale: a new sweep could be written and the gate
  /// would keep reading the old document. Dated documents are kept rather
  /// than rewritten — a signed measurement is a record of what was true then
  /// — so what the gate must follow is the newest.
  final certifications =
      Directory('docs')
          .listSync()
          .whereType<File>()
          .where(
            (f) => RegExp(
              r'CERTIFICATION-\d{4}-\d{2}-\d{2}\.md$',
            ).hasMatch(f.path),
          )
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));
  if (certifications.isEmpty) {
    // Thrown rather than expect()ed: this runs at load, outside a test body,
    // and every check below reads the result.
    throw StateError('no dated CERTIFICATION-*.md in docs/');
  }
  final certification = certifications.last.readAsStringSync();

  /// The document that declares the gap register, wherever it lives.
  ///
  /// The register is a claim of the programme that closed those gaps, not of
  /// every later sweep — a closing sweep restates the verdict and the count,
  /// not twenty rows. Located by content rather than by filename so neither
  /// document has to be kept in a shape it has outgrown.
  final register = certifications
      .map((f) => f.readAsStringSync())
      .firstWhere(
        (text) => text.contains('The gap register'),
        orElse: () => throw StateError('no certification declares a register'),
      );

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
        register,
        contains('| $id |'),
        reason: '$id is missing from the register',
      );
    }
    expect(register, contains('**Withdrawn**'));
  });

  test('every open item names an owner', () {
    // The acceptance criterion: open with a stated reason and an owner, never
    // open and unattributed.
    for (final item in ['M-27', 'M-39', 'M-43', 'M-44', 'M-45']) {
      expect(
        register,
        contains(item),
        reason: '$item is open and unrecorded in the certification',
      );
    }
    for (final owner in ['Backend lane', 'Admin lane', 'Decisions']) {
      expect(register, contains(owner));
    }
    // And the CURRENT sweep must attribute whatever it leaves open, in the
    // same way. An open item with no owner is how a list becomes a wish.
    for (final owner in ['Backend lane', 'Owner decisions', 'LGU']) {
      expect(
        certification,
        contains(owner),
        reason: 'the latest sweep leaves items open without naming $owner',
      );
    }
  });

  test('the two formerly-dormant subsystems are still wired', () {
    // This assertion has been INVERTED, and the inversion is the record.
    //
    // It was written to prove B-3: OfflineQueue and SyncEngine were built,
    // tested, and constructed nowhere in lib/, so the certification could not
    // become wrong in the direction that flattered us. On 29 August they were
    // wired, and this test fired and said so by name — which is what it was
    // for.
    //
    // The risk is now the opposite one: that somebody unbuilds the wiring and
    // the only evidence is an applicant losing queued work. So it now fails if
    // they go back to being constructed nowhere.
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
      isNotEmpty,
      reason:
          'the offline queue is constructed nowhere again — B-3 has reopened, '
          'and queued work now goes nowhere. See '
          'test/architecture/queue_is_wired_test.dart',
    );
  });

  test('the test count it quotes is the count of this suite', () {
    // A dated measurement, and the one number in the document most likely to
    // rot silently. Nobody re-reads a signed document; a test does.
    //
    // **This check used to be a lie, and it is worth saying how.** Its comment
    // claimed the quoted number was "compared against what `flutter test`
    // reports". It was not: it asserted `counted > 1400`, a constant. So the
    // certification could quote 1544 while the suite ran 2152, and it did —
    // 608 tests stale, four days, and the gate green throughout. A gate that
    // cannot fail for the reason it states is worse than no gate, because it
    // is read as evidence.
    //
    // `tool/verify.sh` now writes the figure `flutter test` actually reported
    // to `suite-count.txt`, and this compares the document against that.
    final quoted = RegExp(r'(\d{3,5}) tests').firstMatch(certification);
    expect(quoted, isNotNull, reason: 'the certification quotes no count');

    final stamp = File('test/contract/suite-count.txt');
    expect(
      stamp.existsSync(),
      isTrue,
      reason:
          'run tool/verify.sh — it stamps the count this check reads. Without '
          'it there is no measurement to compare the document against',
    );
    final measured = int.parse(stamp.readAsStringSync().trim());
    expect(
      measured,
      greaterThan(1400),
      reason: 'the stamp is implausible — verify.sh wrote something odd',
    );
    expect(
      int.parse(quoted!.group(1)!),
      measured,
      reason:
          'the certification quotes a test count that is not this suite\'s. '
          'Update the number in the document — do not weaken this check, '
          'which is what happened last time',
    );
  });
}
