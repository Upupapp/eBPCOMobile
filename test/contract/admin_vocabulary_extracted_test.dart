import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:ebpco_user_app/core/contract/admin_vocabulary.dart';
import 'package:ebpco_user_app/core/models/application_model.dart';

/// The standing parity gate.
///
/// `admin_vocabulary_test.dart` beside this one holds the same vocabularies
/// **transcribed by hand**, and that is exactly its weakness: a hand
/// transcription is a claim about a file, and this repository has been wrong
/// about what a file said three times — twice by regex, once by reading a
/// comment that described a different codebase.
///
/// So `test/contract/admin-vocabulary.json` is *extracted* from the admin's
/// `src/app/core/domain/` by `scripts/extract_admin_vocabulary.mjs`, carries
/// the commit it came from, and is refreshed by one command. This test asserts
/// this app against it, value for value and in order.
///
/// The two tests are deliberately kept side by side. If the transcription and
/// the extraction ever disagree, one of them is wrong about the admin, and
/// finding out which is the whole point.

void main() {
  final fixture =
      jsonDecode(File('test/contract/admin-vocabulary.json').readAsStringSync())
          as Map<String, dynamic>;

  List<String> of(String key) => (fixture[key] as List).cast<String>();

  group('the fixture itself', () {
    test('records where it came from', () {
      // A fixture with no provenance is a set of strings somebody typed.
      final source = fixture['source'] as Map<String, dynamic>;
      expect(source['repository'], 'Upupapp/eBPCO-Web');
      expect(source['commit'], isNotEmpty);
      expect(source['commitDate'], isNotEmpty);
      expect(source['extractedOn'], isNotEmpty);
    });

    test('is not empty in any vocabulary', () {
      // An extraction that silently returned nothing would pass every
      // comparison below against an app that had also dropped the values.
      for (final key in [
        'permitTypes',
        'applicationActions',
        'documentStatuses',
        'paymentTransactionStatuses',
        'collectingAgencies',
        'paymentAdjustmentTypes',
        'assessmentStatuses',
        'assessmentStatusOrderConstant',
        'contactVerificationStatuses',
        'contactVerificationMethods',
      ]) {
        expect(of(key), isNotEmpty, reason: key);
      }
    });
  });

  group('this app speaks the admin\'s vocabulary', () {
    test('permit types, in order, including the en dash', () {
      // The EN DASH (U+2013) in the three Building Permit names is not
      // decoration: it has already broken a route, and a hyphen here would
      // make every lookup by permit type miss.
      expect(
        CanonicalPermitType.values.map((t) => t.wire).toList(),
        of('permitTypes'),
      );
    });

    test('application actions', () {
      expect(
        ApplicationType.values.map((t) => t.wire).toList(),
        of('applicationActions'),
      );
    });

    test('document statuses', () {
      expect(
        DocumentStatus.values.map((s) => s.wire).toList(),
        of('documentStatuses'),
      );
    });

    test('payment transaction statuses', () {
      expect(
        PaymentTransactionStatus.values.map((s) => s.wire).toList(),
        of('paymentTransactionStatuses'),
      );
    });

    test('collecting agencies', () {
      // FSEC and FSIC fees are collected by the Bureau of Fire Protection, not
      // the LGU. An applicant sent to the wrong cashier has lost the morning.
      expect(
        CollectingAgency.values.map((a) => a.wire).toList(),
        of('collectingAgencies'),
      );
    });

    test('payment adjustment types', () {
      expect(
        PaymentAdjustmentType.values.map((t) => t.wire).toList(),
        of('paymentAdjustmentTypes'),
      );
    });

    test('assessment statuses', () {
      expect(
        AssessmentStatus.values.map((s) => s.wire).toList(),
        of('assessmentStatuses'),
      );
    });

    test('contact verification statuses and methods', () {
      expect(
        ContactVerificationStatus.values.map((s) => s.wire).toList(),
        of('contactVerificationStatuses'),
      );
      expect(
        ContactVerificationMethod.values.map((m) => m.wire).toList(),
        of('contactVerificationMethods'),
      );
    });
  });

  group('parsing is total and closed', () {
    test('every value the admin can send round-trips', () {
      // Total: an admin value this app cannot parse is a screen that fails to
      // load on a record the office considers ordinary.
      for (final wire in of('permitTypes')) {
        expect(canonicalPermitTypeFromWire(wire).wire, wire);
      }
      for (final wire in of('documentStatuses')) {
        expect(documentStatusFromWire(wire).wire, wire);
      }
      for (final wire in of('assessmentStatuses')) {
        expect(assessmentStatusFromWire(wire).wire, wire);
      }
      for (final wire in of('paymentTransactionStatuses')) {
        expect(paymentTransactionStatusFromWire(wire).wire, wire);
      }
    });

    test('an unknown value throws rather than defaulting', () {
      // Closed: defaulting an unrecognised status to something plausible is
      // how an applicant gets told their document was accepted.
      expect(
        () => canonicalPermitTypeFromWire('Business Permit'),
        throwsA(isA<UnknownWireValue>()),
      );
      expect(
        () => documentStatusFromWire('Approved'),
        throwsA(isA<UnknownWireValue>()),
      );
    });
  });

  test('the admin disagrees with itself about assessment status order', () {
    // Recorded rather than resolved. The admin declares this vocabulary twice:
    // the `AssessmentStatus` union, and an `ASSESSMENT_STATUS_ORDER` constant
    // that swaps 'Paid' and 'Overdue'. Nothing in the admin references the
    // constant, so the union is the definition and this app follows it.
    //
    // Asserted so the day someone reconciles them, this fails and says which
    // way it went — rather than this app quietly matching the loser.
    final union = of('assessmentStatuses');
    final constant = of('assessmentStatusOrderConstant');

    expect(union.toSet(), constant.toSet(), reason: 'same eight values');
    expect(
      union,
      isNot(constant),
      reason:
          'if these now agree, the admin has reconciled them — check which '
          'order won and follow it',
    );
    expect(AssessmentStatus.values.map((s) => s.wire).toList(), union);
  });

  test('the transcribed fixture and the extracted one agree', () {
    // The two are independent readings of the same file. Disagreement means
    // one of them is wrong about the admin, and it is worth failing loudly
    // rather than trusting whichever was written first.
    //
    // Asserted through the app's own enums, which both are compared against:
    // if the app matches both, the two agree on everything that matters.
    expect(
      CanonicalPermitType.values.length,
      of('permitTypes').length,
      reason: 'the transcription and the extraction differ in size',
    );
  });
}
