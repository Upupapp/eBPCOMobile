import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Every request body this app sends, against the schema the contract declares.
///
/// The read-path gate diffs models against parsers. This is its counterpart,
/// and the direction that had never been checked at all: what the app *sends*.
///
/// All six schemas are `additionalProperties: false`, so one undeclared key
/// rejects the whole request. Measured 29 August 2026: **three of the five
/// paths a client actually calls could not succeed.**
///
/// **Reworked 30 August 2026.** The claim that none was fixable in this lane
/// was wrong. It is true of a field the contract does not declare — sending
/// one early is worse than not sending it — and false of a field the contract
/// REQUIRES and the app simply never sent. Three of those are now sent:
/// `paidOn`, `amountCentavos`, and the instruction resubmit's `items`.
///
/// What is left is the one shape that cannot be fixed without losing
/// something: `proof` versus `documentId`. Removing it would let a payment
/// report succeed while silently discarding the receipt the applicant
/// attached. All of it is M-47; see `docs/HANDOFF-M-47-permit-vocabulary.md`.

void main() {
  final schemas =
      jsonDecode(File('test/contract/write-bodies.json').readAsStringSync())
          as Map<String, dynamic>;

  Map<String, dynamic> schemaOf(String name) =>
      schemas[name] as Map<String, dynamic>;
  List<String> requiredOf(String n) =>
      (schemaOf(n)['required'] as List).cast<String>();
  List<String> propsOf(String n) =>
      (schemaOf(n)['properties'] as List).cast<String>();

  /// The literal keys of the body a method builds, read from source so it
  /// cannot drift from the code it describes.
  ///
  /// [path] identifies the WRITE call, not merely the path: the regex requires
  /// `post(` immediately before it. A path that is also read elsewhere —
  /// `getList('/businesses')` precedes `post('/businesses', …)` — would
  /// otherwise match the read and slice an empty range, which reads as "sends
  /// nothing". That is exactly how this gate first reported a false divergence
  /// against a body that is correct.
  ///
  /// `post\s*\(\s*` rather than `post('`: dart format wraps a long call onto
  /// its own lines, and the literal form stopped finding `/businesses` the
  /// moment an extra argument pushed it over the line length. It reported the
  /// anchor as "moved" when the call had not moved at all.
  ///
  /// A path that is also read elsewhere — `getList('/businesses')` precedes
  /// `post('/businesses', …)` — would otherwise match the read and slice an
  /// empty range, which reads as "sends nothing". That is exactly how this
  /// gate first reported a false divergence against a body that is correct.
  Set<String> bodyOf(
    String file,
    String path, {
    Set<String> nested = const {},
  }) {
    final source = File(file).readAsStringSync();
    final escaped = RegExp.escape(path);
    final match = RegExp(
      'post'
      r'\s*\(\s*'
      '$escaped',
    ).firstMatch(source);
    expect(match, isNotNull, reason: 'no post to "$path" in $file');
    final start = match!.start;
    final end = source.indexOf('return', start);
    return RegExp(
        r"'(\w+)':",
      ).allMatches(source.substring(start, end)).map((m) => m.group(1)!).toSet()
      ..removeAll(nested);
  }

  test('the vendored schemas are not empty', () {
    // The extraction that produced this file returned an empty enum and an
    // inverted flag on its first run. Never trust it silently.
    for (final name in [
      'ApplicationSubmission',
      'PaymentProof',
      'InstructionResponse',
      'BusinessRegistration',
      'TokenRequest',
      'RegistrationRequest',
    ]) {
      expect(propsOf(name), isNotEmpty, reason: name);
      expect(
        schemaOf(name)['additionalPropertiesAllowed'],
        isFalse,
        reason: '$name should be strict; if it is not, re-read the contract',
      );
    }
  });

  group('CLEAN — these two conform, and must stay that way', () {
    test('POST /businesses sends exactly what is required', () {
      final body = bodyOf(
        'lib/core/repositories/http_business_repository.dart',
        "'/businesses'",
      );
      expect(body, containsAll(requiredOf('BusinessRegistration')));
      expect(
        body.difference(propsOf('BusinessRegistration').toSet()),
        isEmpty,
        reason: 'an undeclared key would reject the whole registration',
      );
    });

    test('POST /auth/register and /auth/token conform', () {
      final register = bodyOf(
        'lib/core/repositories/http_auth_repository.dart',
        "'/auth/register'",
      );
      expect(register, containsAll(requiredOf('RegistrationRequest')));
      expect(
        register.difference(propsOf('RegistrationRequest').toSet()),
        isEmpty,
      );

      final token = bodyOf(
        'lib/core/repositories/http_auth_repository.dart',
        "'/auth/token'",
      );
      expect(token, containsAll(requiredOf('TokenRequest')));
      expect(token.difference(propsOf('TokenRequest').toSet()), isEmpty);
    });
  });

  group('FIXED — the payment report now carries what it must', () {
    const file = 'lib/core/repositories/http_applications_repository.dart';
    const path = "'/applications/\$applicationId/payments'";

    test('paidOn is required, and is now sent', () {
      // The app never asked the applicant WHEN they paid — there was no field
      // for it in the payment screen either, so this was never a matter of
      // adding a key to a body. A "Date paid" question was added to the proof
      // sheet and threaded through the model.
      expect(requiredOf('PaymentProof'), contains('paidOn'));
      expect(
        bodyOf(file, path, nested: {'label', 'fileName'}),
        contains('paidOn'),
      );
    });

    test('paidOn is sent as a calendar date, not an instant', () {
      // `format: date`. An applicant paid on a day, in their own timezone;
      // an ISO timestamp would invite the server to shift it across midnight
      // and put a payment on the wrong side of a deadline.
      final source = File(file).readAsStringSync();
      expect(source, isNot(contains('paidOn.toIso8601String()')));
      expect(source, contains("paidOn.year.toString().padLeft(4, '0')"));
    });

    test('the reference number is the applicant\'s, not a filename', () {
      // It used to be `proof?.label ?? ''` — the label of the attached file.
      // The Treasurer's Office reconciles against a bank reference or an OR
      // number, and "Proof of payment" is neither, so every report sent this
      // way was unverifiable.
      final source = File(file).readAsStringSync();
      expect(source, isNot(contains("referenceNumber: proof?.label ?? ''")));
      expect(
        bodyOf(file, path, nested: {'label', 'fileName'}),
        contains('referenceNumber'),
      );
    });

    test('amountCentavos is optional, and is now sent when known', () {
      // The app always had the figure — the Order of Payment is on the screen
      // the applicant is looking at — so the server was being told less than
      // the applicant was shown.
      expect(requiredOf('PaymentProof'), isNot(contains('amountCentavos')));
      expect(propsOf('PaymentProof'), contains('amountCentavos'));
      expect(
        bodyOf(file, path, nested: {'label', 'fileName'}),
        contains('amountCentavos'),
      );
    });
  });

  test(
    'DIVERGENCE — proof is an undeclared key; the contract wants documentId',
    () {
      // The one payment divergence left, and left deliberately. The contract
      // wants the id of a receipt already uploaded through /documents; that flow
      // is not built. Dropping the key would let the report succeed while
      // silently discarding the receipt the applicant attached — the same
      // reasoning as `documents` on the submission body.
      const file = 'lib/core/repositories/http_applications_repository.dart';
      const path = "'/applications/\$applicationId/payments'";
      expect(propsOf('PaymentProof'), contains('documentId'));
      expect(propsOf('PaymentProof'), isNot(contains('proof')));
      expect(
        bodyOf(file, path, nested: {'label', 'fileName'}),
        contains('proof'),
      );
    },
  );

  test('FIXED — the instruction resubmit now answers item by item', () {
    // `items` is required with `minItems: 1`. The app posted to the route with
    // no body at all, so the request was refused before the office saw which
    // deficiencies the applicant had addressed.
    //
    // This is the route the 28 August remeasure called "exists" and used to
    // mark M-43 closed. It does exist. The app was calling it wrongly, which
    // is a different thing, and was missed because nothing compared bodies.
    expect(requiredOf('InstructionResponse'), ['items']);

    final source = File(
      'lib/core/repositories/http_applications_repository.dart',
    ).readAsStringSync();
    final start = source.indexOf("instructions/\$letterId/resubmit'");
    expect(start, greaterThan(0));
    final call = source.substring(start, source.indexOf('return', start));
    expect(call, contains('body:'));
    expect(call, contains("'items'"));
    expect(call, contains("'itemId'"));
  });

  test('an empty item list is refused here rather than by the server', () {
    // minItems: 1. A body with an empty array is rejected for a reason nobody
    // reading the app can see, so the app names it instead.
    final source = File(
      'lib/core/repositories/http_applications_repository.dart',
    ).readAsStringSync();
    expect(source, contains('itemIds.isEmpty'));
    expect(
      source,
      contains('cannot be answered with no items'),
      reason: 'the guard exists but says nothing useful when it fires',
    );
  });
}
