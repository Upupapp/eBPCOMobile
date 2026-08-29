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
/// paths a client actually calls cannot succeed.** Two more are clean, and
/// this asserts that too, so a regression in them fails here.
///
/// Divergences are asserted as they stand rather than patched, because none is
/// fixable in this lane — a field the contract does not declare fails the whole
/// request, so sending it "early" is worse than not sending it. Each
/// expectation fails the day it is reconciled and says what to do. All of it is
/// M-47; see `docs/HANDOFF-M-47-permit-vocabulary.md`.

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
  /// [anchor] must identify the WRITE call, not merely the path.
  ///
  /// A path that is also read elsewhere — `getList('/businesses')` precedes
  /// `post('/businesses', …)` — would otherwise match the read and slice an
  /// empty range, which reads as "sends nothing". That is exactly how this
  /// gate first reported a false divergence against a body that is correct.
  Set<String> bodyOf(
    String file,
    String anchor, {
    Set<String> nested = const {},
  }) {
    final source = File(file).readAsStringSync();
    final start = source.indexOf(anchor);
    expect(start, greaterThan(0), reason: 'anchor "$anchor" moved in $file');
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
        "post('/businesses'",
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
        "'/auth/register',",
      );
      expect(register, containsAll(requiredOf('RegistrationRequest')));
      expect(
        register.difference(propsOf('RegistrationRequest').toSet()),
        isEmpty,
      );

      final token = bodyOf(
        'lib/core/repositories/http_auth_repository.dart',
        "'/auth/token',",
      );
      expect(token, containsAll(requiredOf('TokenRequest')));
      expect(token.difference(propsOf('TokenRequest').toSet()), isEmpty);
    });
  });

  group('DIVERGENCE — reporting a payment would be rejected', () {
    const file = 'lib/core/repositories/http_applications_repository.dart';
    const anchor = "'/applications/\$applicationId/payments'";

    test('paidOn is required and never sent', () {
      // The app never asks the applicant WHEN they paid. Not a wire problem —
      // there is no field for it in the payment screen either, so closing this
      // needs a question added to the flow, not just a key added to the body.
      expect(requiredOf('PaymentProof'), contains('paidOn'));
      expect(
        bodyOf(file, anchor, nested: {'label', 'fileName'}),
        isNot(contains('paidOn')),
      );
    });

    test('proof is an undeclared key; the contract declares documentId', () {
      // Same shape as `documents` on the submission: the contract wants the id
      // of a file already uploaded through /documents, and that flow is not
      // built, so the app inlines a label and a filename instead.
      expect(propsOf('PaymentProof'), contains('documentId'));
      expect(propsOf('PaymentProof'), isNot(contains('proof')));
      expect(
        bodyOf(file, anchor, nested: {'label', 'fileName'}),
        contains('proof'),
      );
    });

    test('amountCentavos is optional, and also not sent', () {
      // Recorded rather than asserted as a defect: the contract does not
      // require it. Worth stating because the app HAS the figure — the Order
      // of Payment is on screen — so the server is being told less than the
      // applicant was shown.
      expect(requiredOf('PaymentProof'), isNot(contains('amountCentavos')));
      expect(
        bodyOf(file, anchor, nested: {'label', 'fileName'}),
        isNot(contains('amountCentavos')),
      );
    });
  });

  test('DIVERGENCE — the instruction resubmit sends no body at all', () {
    // `items` is required. The app posts to the route with no body, so the
    // request is rejected before the office ever sees which items the
    // applicant answered.
    //
    // This is the route the 28 August remeasure called "exists" and used to
    // mark M-43 closed. It does exist. The app calls it wrongly, which is a
    // different thing and was missed because nothing compared bodies.
    expect(requiredOf('InstructionResponse'), ['items']);

    final source = File(
      'lib/core/repositories/http_applications_repository.dart',
    ).readAsStringSync();
    final start = source.indexOf("instructions/\$letterId/resubmit'");
    expect(start, greaterThan(0));
    final call = source.substring(start, source.indexOf('return', start));
    expect(
      call,
      isNot(contains('body:')),
      reason:
          'if a body is now sent, check it carries `items` and close that part '
          'of M-47',
    );
  });
}
