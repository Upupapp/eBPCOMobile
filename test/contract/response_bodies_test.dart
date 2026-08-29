import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// What the app READS, against what the contract says a response contains.
///
/// The last of the three directions. The first gate diffs models against
/// parsers — does the parser fill everything the model holds? The second diffs
/// request bodies against the contract. This one asks the question neither
/// could: **does the server ever send what the parser reads?**
///
/// It found the mirror image of the write-path result, and a larger one.
/// Mobile parses a materially richer record than the contract describes. Every
/// field below is real, tested, and rendered on a screen — and against a
/// conforming server it would arrive `null` every time, because the contract
/// has nowhere to put it.
///
/// This is not a list of mobile's mistakes. TABs 02, 06, 07, 08 and 13 built
/// applicant-facing detail the admin portal already models — per-document
/// review, partial payment, official receipts, assessment supersession — and
/// the contract was never widened to carry it. That is the finding, and it is
/// M-47's read-path half.

void main() {
  final schemas =
      jsonDecode(File('test/contract/response-bodies.json').readAsStringSync())
          as Map<String, dynamic>;

  List<String> propsOf(String n) =>
      ((schemas[n] as Map<String, dynamic>)['properties'] as List)
          .cast<String>();

  final dto = File('lib/core/api/application_dto.dart').readAsStringSync();

  /// The JSON keys read inside one parser, by its definition — never its call
  /// site. Anchoring on the call site is how the first run of this diff
  /// reported a document parser reading `timeline` and `permit`.
  Set<String> keysIn(String definition) {
    final start = dto.indexOf(definition);
    expect(start, greaterThan(0), reason: 'definition moved: $definition');
    final after = dto.substring(start + definition.length);
    final next = RegExp(r'\n  static ').firstMatch(after);
    final body = definition + after.substring(0, next?.start ?? after.length);
    return {
      ...RegExp(r"row,\s*'(\w+)'\)").allMatches(body).map((m) => m.group(1)!),
      ...RegExp(r"row\['(\w+)'\]").allMatches(body).map((m) => m.group(1)!),
      ...RegExp(r"raw,\s*'(\w+)'\)").allMatches(body).map((m) => m.group(1)!),
      ...RegExp(r"raw\['(\w+)'\]").allMatches(body).map((m) => m.group(1)!),
    };
  }

  test('the vendored response schemas are not empty', () {
    for (final n in [
      'ApplicationCore',
      'Document',
      'PaymentState',
      'Notification',
      'Business',
    ]) {
      expect(propsOf(n), isNotEmpty, reason: n);
    }
  });

  group('DIVERGENCE — mobile parses more than the contract describes', () {
    test('the whole per-document review layer is undeclared', () {
      // TAB 02's work — G-01, G-02, G-18 — plus the review reason added on
      // 29 August. The contract's `Document` carries upload and scan facts
      // (byteSize, sha256, scanCleared) and a bare `status`; it has no notion
      // of an evaluator's remarks, a standard reason, an issuing office, or a
      // submission history.
      final undeclared = keysIn(
        'static List<DocumentModel> _documents(',
      ).difference(propsOf('Document').toSet())..removeAll({'status'});

      expect(undeclared, {
        'remarks',
        'reviewReason',
        'issuingOffice',
        'issueDate',
        'expiryDate',
        'history',
      });
    });

    test('and the contract spells the one shared date differently', () {
      // `expiresOn` against mobile's `expiryDate`, for the same concept. Even
      // if the review layer is added, this one silently yields null.
      expect(propsOf('Document'), contains('expiresOn'));
      expect(propsOf('Document'), isNot(contains('expiryDate')));
      expect(
        keysIn('static List<DocumentModel> _documents('),
        contains('expiryDate'),
      );
    });

    test('every payment collection is undeclared', () {
      // TABs 06, 07 and 08 — partial payment, rejection reasons, the Official
      // Receipt, the collecting agency, assessment supersession. `PaymentState`
      // describes a single payment and a balance.
      final undeclared = keysIn(
        'static PaymentAssessmentModel? _payment(',
      ).difference(propsOf('PaymentState').toSet());

      expect(undeclared, {
        'transactions',
        'adjustments',
        'supersededOrders',
        'proof',
      });
    });

    test('the notification payload does not exist in the contract', () {
      // The sharpest correction to my own recent work. On 28 August I fixed the
      // notification parser to read `payload`, on the reasoning that dropping
      // it made every server notification generic. That is true of the mock.
      // The contract does not declare `payload` OR `applicationNumber` — it
      // declares rendered `title`, `body` and `deepLink`, because the server
      // renders and the client displays.
      //
      // So the fix made mobile self-consistent and changes nothing against a
      // conforming server. The real question is which side renders, and that
      // is a design decision for the contract lane, not a parser bug.
      expect(propsOf('Notification'), isNot(contains('payload')));
      expect(propsOf('Notification'), isNot(contains('applicationNumber')));
      expect(
        propsOf('Notification'),
        containsAll(['title', 'body', 'deepLink']),
      );

      final parser = File(
        'lib/core/repositories/http_notifications_repository.dart',
      ).readAsStringSync();
      expect(parser, contains("json['payload']"));
      expect(
        parser,
        isNot(contains("json['title']")),
        reason: 'mobile computes the title locally from type + payload',
      );
    });
  });

  test('RECORDED — six declared fields mobile never reads', () {
    // Not defects: the app does not need all of them. Listed so the choice is
    // visible rather than accidental — `pledge` and `requiresApplicantAction`
    // in particular are computed client-side today, and the contract states
    // that the pledge is "computed in exactly one place server-side; clients
    // display and never compute".
    final topLevel = {
      ...RegExp(r"json,\s*'(\w+)'\)").allMatches(dto).map((m) => m.group(1)!),
      ...RegExp(r"json\['(\w+)'\]").allMatches(dto).map((m) => m.group(1)!),
    };
    final ignored = propsOf('ApplicationCore').toSet().difference(topLevel);

    expect(ignored, {
      'applicantStatus',
      'location',
      'pledge',
      'requiresApplicantAction',
      'serviceDomain',
      'updatedAt',
    });
  });
}
