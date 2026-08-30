import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:ebpco_user_app/core/contract/admin_vocabulary.dart';
import 'package:ebpco_user_app/core/contract/service_domain.dart';

/// The one body every application is filed through, against the contract.
///
/// The read path has a completeness gate; this is the write path's, and it
/// found something worse. `POST /applications` declares
/// `additionalProperties: false`, so a single undeclared key rejects the whole
/// submission — and the body this app builds would be refused by a conforming
/// server on **four** independent counts.
///
/// **Two of the four are fixed as of 30 August 2026**, and this file says so
/// rather than being deleted: the day a divergence is reconciled these
/// expectations fail and name what changed, which is exactly how the two
/// fixes below were prompted.
///
/// What is fixed is what could be fixed WITHOUT silently dropping something
/// the applicant supplied. `serviceDomain` was derivable and required;
/// `businessId: ''` was simply the wrong shape for a nullable uuid.
///
/// What stands is the rest: `documents` cannot become `documentIds` until the
/// upload flow exists, and removing it would let a submission succeed while
/// discarding every attachment the applicant made — a silent loss worse than
/// the loud rejection it replaces. The permit vocabulary is not this app's to
/// change. M-47.

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

  group('FIXED — what could be reconciled without losing anything', () {
    test('1. serviceDomain is required, and is now sent', () {
      // Was never sent at all: `grep -rn serviceDomain lib` returned nothing,
      // so a conforming server refused every filing this app made. Derivable
      // rather than a decision — every CanonicalPermitType is a construction
      // permit, and the only other filer is the business-permit screen, which
      // names no permit type.
      expect(listOf('required'), contains('serviceDomain'));
      expect(bodyKeys(), contains('serviceDomain'));
    });

    test('the two values it can send are the two the contract declares', () {
      expect(
        ServiceDomain.values.map((d) => d.wire).toList(),
        listOf('serviceDomain'),
        reason: 'a value the contract does not know fails the whole filing',
      );
      expect(
        serviceDomainFor('Fencing'),
        ServiceDomain.constructionPermit,
        reason: 'anything naming a permit is a construction filing',
      );
      expect(
        serviceDomainFor(null),
        ServiceDomain.businessPermit,
        reason: 'the business-permit screen names no permit type',
      );
    });

    test(
      '3. businessId is null on a construction permit, not an empty string',
      () {
        // The contract types it as a uuid or null; '' is neither. The wizard
        // helper still passes '' — a construction permit is filed by a person
        // and has no business to name — and the repository is where that
        // becomes the null the contract asks for.
        final helper = File(
          'lib/features/applications/presentation/widgets/'
          'submit_permit_application.dart',
        ).readAsStringSync();
        expect(helper, contains("businessId: ''"));

        final repository = File(
          'lib/core/repositories/http_applications_repository.dart',
        ).readAsStringSync();
        expect(
          repository,
          contains("'businessId': businessId.isEmpty ? null : businessId"),
          reason:
              'if this moved, check '
              ' is still not reaching the wire',
        );
      },
    );
  });

  group('DIVERGENCE — what is left, and why it is left', () {
    test('documentIds is sent when the files could be uploaded', () {
      // Added 30 August 2026 with `POST /documents`. This is the declared
      // key, and the one a conforming server accepts.
      expect(listOf('properties'), contains('documentIds'));
      expect(bodyKeys(), contains('documentIds'));
    });

    test('and the undeclared key is still the fallback, on purpose', () {
      // The contract declares `documentIds` — uuids of documents already
      // uploaded through /documents. The app sends `documents`, a list of
      // local labels and filenames, because the separate upload flow is not
      // built. With additionalProperties false this alone rejects the body.
      //
      // LEFT DELIBERATELY, and it is no longer the only path: `documentIds`
      // goes when the files were uploaded. This branch is what happens when
      // documents were attached and NONE could be uploaded — a mock build, or
      // a server that refused every file. Dropping the key there would make
      // the filing succeed while discarding every attachment the applicant
      // made, on a Building Permit twenty-four of them, after the wizard told
      // them their documents were sent. A loud rejection is the better
      // failure.
      expect(listOf('properties'), contains('documentIds'));
      expect(listOf('properties'), isNot(contains('documents')));
      expect(bodyKeys(), contains('documents'));

      final repository = File(
        'lib/core/repositories/http_applications_repository.dart',
      ).readAsStringSync();
      expect(
        repository,
        contains("if (documentIds.isNotEmpty)"),
        reason:
            'the two keys must be mutually exclusive — sending both would be '
            'refused for the undeclared one, which is the worst of both',
      );
    });

    test('NO permit type the app sends is in the contract enum', () {
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

  test('DIVERGENCE — the application still carries no form data', () {
    // Found 30 August 2026 and never named before: the contract declares
    // `form` (the permit-type-specific field set) and `location`, and the app
    // sent NEITHER. `location` is sent as of 31 August. Every application it files therefore carries a permit
    // type, an action and a business id, and not one of the applicant's typed
    // answers — up to 239 fields on a mechanical permit.
    //
    // Not fixable here, and not for the usual reason. `form` is
    // `additionalProperties: true` and "validated server-side against the
    // schema for permitType", and the contract itself says the wizards are
    // auditable against the DPWH/JMC unified forms "once those are supplied".
    // They have not been — that is M-10. Sending mobile's internal field names
    // would make this app's private shape the de facto official one.
    expect(listOf('properties'), containsAll(['form', 'location']));
    expect(bodyKeys(), isNot(contains('form')));
    // `location` closed on 31 August 2026 — it is a plain nullable string and
    // needed no form schema, only for somebody to join the address parts the
    // wizards already collect. `form` is what is left, and it is blocked on
    // M-10 rather than on effort.
    expect(bodyKeys(), contains('location'));
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
