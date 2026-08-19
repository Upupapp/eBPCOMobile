import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:ebpco_user_app/core/models/application_model.dart';
import 'package:ebpco_user_app/core/models/lifecycle_status.dart';

/// Binds this client to the ratified contract's normative projection.
///
/// `reconciliation/lifecycle-projection.json` in the contract repository is the
/// single definition of how the admin's nineteen lifecycle statuses project
/// onto everything each surface shows. The server computes every column and
/// returns it; this app renders what it is given. But the app still carries its
/// own copy of the projection for the mock build and for the offline path, and
/// two implementations of one regulated mapping is exactly how the applicant
/// and the officer end up describing the same permit differently.
///
/// So: the contract file is vendored at `test/contract/` (refresh it with
/// `scripts/sync_contract_fixtures.sh`) and every row is asserted here. A drift
/// is a failed build rather than a wrong answer shown to an applicant.
///
/// The admin carries the mirror of this test in TAB 13, so all three tiers are
/// held to the same file.
void main() {
  final projectionFile = File('test/contract/lifecycle-projection.json');
  final contract =
      jsonDecode(projectionFile.readAsStringSync()) as Map<String, dynamic>;
  final rows = contract['projection'] as Map<String, dynamic>;

  /// The contract addresses statuses by the admin's label; this app addresses
  /// them by enum. `adminLabel` is the only bridge, so resolving through it
  /// also proves the spelling has not drifted.
  ApplicationLifecycleStatus byLabel(String label) =>
      ApplicationLifecycleStatus.values.firstWhere(
        (status) => status.adminLabel == label,
        orElse: () => throw StateError(
          'the contract names lifecycle status "$label", which this app cannot '
          'spell — the two have drifted',
        ),
      );

  group('contract: lifecycle projection', () {
    test('the vendored fixture is the one this test was written against', () {
      expect(
        contract['contractVersion'],
        '0.1.0',
        reason: 'the contract moved; re-run scripts/sync_contract_fixtures.sh '
            'and review what changed before updating this expectation',
      );
    });

    test('every status the contract defines exists in this app, and vice versa',
        () {
      final contractLabels = rows.keys.toSet();
      final appLabels =
          ApplicationLifecycleStatus.values.map((s) => s.adminLabel).toSet();

      expect(contractLabels.length, 19);
      expect(
        appLabels,
        contractLabels,
        reason: 'a status in only one of the two is a status the server can '
            'send and this app will reject at runtime',
      );
    });

    test('applicantStatus matches the contract for all 19 statuses', () {
      for (final entry in rows.entries) {
        final row = entry.value as Map<String, dynamic>;
        expect(
          byLabel(entry.key).applicantStatus.label,
          row['applicantStatus'],
          reason: '${entry.key} projects differently here than in the contract',
        );
      }
    });

    test('requiresApplicantAction matches the contract for all 19 statuses', () {
      for (final entry in rows.entries) {
        final row = entry.value as Map<String, dynamic>;
        expect(
          byLabel(entry.key).requiresApplicantAction,
          row['requiresApplicantAction'],
          reason: '${entry.key}: whether the applicant is the one holding this '
              'up is not a judgement two tiers may make separately',
        );
      }
    });

    test('terminal matches the contract for all 19 statuses', () {
      for (final entry in rows.entries) {
        final row = entry.value as Map<String, dynamic>;
        expect(byLabel(entry.key).isTerminal, row['terminal'],
            reason: '${entry.key} disagrees on whether processing has ended');
      }
    });

    test('pledgeApplies matches this app\'s isInFlight for all 19 statuses', () {
      for (final entry in rows.entries) {
        final row = entry.value as Map<String, dynamic>;
        expect(
          byLabel(entry.key).isInFlight,
          row['pledgeApplies'],
          reason: '${entry.key}: showing an RA 11032 countdown where the LGU no '
              'longer owes an act would assert a pledge that does not exist',
        );
      }
    });

    test('the seven applicant-visible statuses match the contract', () {
      final fromContract =
          (contract['applicantStatuses'] as List).cast<String>().toSet();
      final fromApp = ApplicationStatus.values.map((s) => s.label).toSet();

      expect(fromApp.length, 7);
      expect(fromApp, fromContract);
    });

    test('the happy-path sequence stays a subset of the projection', () {
      // `lifecycleSequence` omits Revision Required and the terminal exits on
      // purpose: it renders a timeline, and a revision is a loop rather than a
      // position in the sequence.
      for (final status in lifecycleSequence) {
        expect(rows.containsKey(status.adminLabel), isTrue,
            reason: '${status.adminLabel} is in the timeline sequence but has '
                'no projection row');
      }
      expect(
        lifecycleSequence.map((s) => s.adminLabel),
        isNot(contains('Revision Required')),
        reason: 'a revision loops back into evaluation; putting it in the '
            'sequence would draw it as another step forward',
      );
    });

    test('every legal transition names statuses both tiers know', () {
      final transitions =
          contract['validTransitions'] as Map<String, dynamic>;
      expect(transitions.keys.toSet(), rows.keys.toSet());

      for (final entry in transitions.entries) {
        byLabel(entry.key);
        for (final target in (entry.value as List).cast<String>()) {
          byLabel(target);
        }
      }
    });

    test('terminal statuses have no onward transition', () {
      final transitions =
          contract['validTransitions'] as Map<String, dynamic>;
      for (final entry in rows.entries) {
        final row = entry.value as Map<String, dynamic>;
        if (row['terminal'] == true) {
          expect(
            transitions[entry.key],
            isEmpty,
            reason: '${entry.key} is terminal but the contract permits a move '
                'out of it',
          );
        }
      }
    });
  });
}
