import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:ebpco_user_app/core/contract/admin_vocabulary.dart';

/// The one body every application is filed through, against the contract.
///
/// The read path has a completeness gate; this is the write path's, and it
/// found something worse. `POST /applications` declares
/// `additionalProperties: false`, so a single undeclared key rejects the whole
/// submission — and the body this app builds would be refused by a conforming
/// server on **four** independent counts.
///
/// None of them is fixable here, and that is why they are asserted rather than
/// patched: three are the contract lane's, and the fourth cannot be fixed
/// without breaking the admin parity the whole programme established.
///
/// Recorded as M-47. Each expectation below documents the divergence as it
/// stands, so the day it is reconciled **this test fails and says so** rather
/// than the app quietly continuing to send something the server rejects.

void main() {
  final schema =
      jsonDecode(
            File(
              'test/contract/application-submission.json',
            ).readAsStringSync(),
          )
          as Map<String, dynamic>;

  List<String> listOf(String key) => (schema[key] as List).cast<String>();

  /// The body `HttpApplicationsRepository.submitApplication` actually builds,
  /// read from the source rather than restated, so it cannot drift from it.
  Set<String> bodyKeys() {
    final source = File(
      'lib/core/repositories/http_applications_repository.dart',
    ).readAsStringSync();
    final start = source.indexOf("'/applications',");
    expect(start, greaterThan(0), reason: 'the submit call moved');
    final body = source.substring(start, source.indexOf('return', start));
    return RegExp(r"'(\w+)':").allMatches(body).map((m) => m.group(1)!).toSet()
      ..removeAll({'label', 'fileName'}); // nested inside the documents list
  }

  test('the vendored schema is not empty', () {
    // An extraction that silently returned nothing would make every assertion
    // below pass. This bit twice while writing the fixture.
    expect(listOf('required'), isNotEmpty);
    expect(listOf('properties'), isNotEmpty);
    expect(listOf('serviceDomain'), hasLength(2));
    expect(listOf('permitType'), hasLength(17));
    expect(schema['additionalPropertiesAllowed'], isFalse);
  });

  group('DIVERGENCE — the app cannot file against a conforming server', () {
    test('1. a required field is never sent: serviceDomain', () {
      // 'Business Permit' | 'Construction Permit'. The app has no notion of it
      // at all — `grep -rn serviceDomain lib` returns nothing — so every
      // submission is missing a required property.
      expect(listOf('required'), contains('serviceDomain'));
      expect(
        bodyKeys(),
        isNot(contains('serviceDomain')),
        reason:
            'if this now fails, serviceDomain is being sent — good; '
            'delete this expectation and close that part of M-47',
      );
    });

    test('2. an undeclared key is sent: documents', () {
      // The contract declares `documentIds` — uuids of documents already
      // uploaded through /documents. The app sends `documents`, a list of
      // local labels and filenames, because the separate upload flow is not
      // built. With additionalProperties false this alone rejects the body.
      expect(listOf('properties'), contains('documentIds'));
      expect(listOf('properties'), isNot(contains('documents')));
      expect(bodyKeys(), contains('documents'));
    });

    test('3. businessId is sent as an empty string, not a uuid or null', () {
      // Every construction wizard files through `submitPermitApplication`,
      // which passes `businessId: ''` because a construction permit is filed
      // by a person rather than a business. The contract types it as a uuid or
      // null; '' is neither.
      final helper = File(
        'lib/features/applications/presentation/widgets/'
        'submit_permit_application.dart',
      ).readAsStringSync();
      expect(helper, contains("businessId: ''"));
      expect(bodyKeys(), contains('businessId'));
    });

    test('4. NO permit type the app sends is in the contract enum', () {
      // The sharpest of the four, and the one I first described wrongly.
      //
      // It is NOT a stale contract that mobile has outrun. `ebpco-api`'s
      // `permit_types` table carries the same 17 short names, so the split is
      // admin + mobile (19 canonical labels) against contract + server (17
      // short names): two internally consistent pairs that disagree with each
      // other.
      //
      // 15 pairs differ only in spelling; one — Certificate of Occupancy — is
      // identical; and 3 mobile types have NO server row at all (Zoning /
      // Locational Clearance, FSEC, FSIC), so TABs 03, 04 and 05 built filing
      // wizards for permits the server does not know exist. Reconciling is
      // therefore not a rename: `permit_types.permit_type` is a primary key
      // with `document_requirements` referencing it.
      //
      // Full measurement and recommendation:
      // docs/HANDOFF-M-47-permit-vocabulary.md
      final contractTypes = listOf('permitType').toSet();
      final sent = CanonicalPermitType.values.map((t) => t.wire).toSet();

      final acceptable = sent.intersection(contractTypes);
      expect(
        acceptable,
        // 'Certificate of Occupancy' is spelled the same in both.
        hasLength(1),
        reason:
            'the contract accepts $acceptable of the ${sent.length} types this '
            'app files. If this number has grown, the contract is being '
            'reconciled — re-measure M-47 rather than editing this figure',
      );
    });
  });

  test('the fix is NOT to adopt the contract spelling', () {
    // Stated as an assertion so nobody "fixes" M-47 by changing this app.
    // Mobile matches the admin exactly, proven by the standing vocabulary
    // gate; the contract is the stale party. Adopting its 17 short names
    // would break that gate and re-open every lookup keyed on the office's
    // own names — the exact defect TAB 12 closed.
    final admin =
        jsonDecode(
              File('test/contract/admin-vocabulary.json').readAsStringSync(),
            )
            as Map<String, dynamic>;
    expect(
      CanonicalPermitType.values.map((t) => t.wire).toList(),
      (admin['permitTypes'] as List).cast<String>(),
      reason: 'mobile must keep matching the ADMIN, whatever the contract says',
    );
  });
}
