import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// "Citizen" is the word, and these are the places it must NOT be swept into.
///
/// Owner ruling, 31 August 2026: *"lets use citizen from now on for citizen,
/// business owner and applicant."* The system has three user types — PUBLIC on
/// the website, **CITIZEN**, and ADMIN with sub-roles.
///
/// **This file exists because the obvious way to obey that instruction would
/// break the app.** Three categories of "applicant" are load bearing, and a
/// find-and-replace would take all three:
///
///  1. **Draft snapshot keys** — `applicant.firstName` and its siblings are a
///     storage surface AND, since `form` is sent on submission, a wire surface.
///     Renaming one orphans every draft on every device and changes what the
///     office receives.
///  2. **NBC form labels** — "Applicant Information", "Applicant Address",
///     "Valid ID of Applicant and Owner of Lot". The wizards mirror the
///     Municipality's own forms box for box, verified field-for-field on 31
///     August, so a citizen holding the paper sees the same words on screen.
///  3. **Quoted sources** — the checklist's ownership clause and the RA 9514
///     citation are transcriptions, not prose.
///
/// What DID change is the app's own voice, which now says **citizen** where it
/// said applicant. "Citizen details" and "citizen address" are the same
/// noun-modifier construction "applicant details" and "applicant address"
/// were, so the sentences keep their shape.
///
/// An earlier pass rewrote these into second person — "Provide your address…"
/// — on the argument that the app is addressing the person it names. The owner
/// asked for the noun, and the noun is what the rest of the system uses:
/// PUBLIC, CITIZEN, ADMIN. One word for one user type, in the UI as in the
/// architecture.

String _lib(String path) => File('lib/$path').readAsStringSync();

void main() {
  group('the app says citizen where it said applicant', () {
    test('wizard subtitles name the citizen', () {
      const reworded = {
        'features/applications/presentation/fencing_permit/'
                'fencing_permit_wizard_screen.dart':
            'Provide the citizen details',
        'features/applications/presentation/sign_permit/'
                'sign_permit_wizard_screen.dart':
            'Provide the citizen details',
        'features/applications/presentation/building_permit/'
                'building_permit_wizard_screen.dart':
            'identify the citizen',
        'features/applications/presentation/mechanical_permit/'
                'mechanical_permit_wizard_screen.dart':
            'Provide the citizen address',
      };
      reworded.forEach((path, phrase) {
        expect(_lib(path), contains(phrase), reason: '$path was not reworded');
      });
    });

    test('and none of them slipped back into second person', () {
      // The shape an earlier pass used — "Provide your address…" — on the
      // argument that the app is addressing the person it names. The owner
      // asked for the noun, and the noun is what the rest of the system uses:
      // PUBLIC, CITIZEN, ADMIN. Held as an assertion so the two readings
      // cannot coexist across nineteen wizards.
      final offenders = <String>[];
      for (final entity in Directory(
        'lib/features/applications/presentation',
      ).listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        final source = entity.readAsStringSync();
        if (source.contains('Provide your address and') ||
            source.contains('Provide your details for')) {
          offenders.add(entity.path);
        }
      }
      expect(offenders, isEmpty);
    });

    test('and no wizard subtitle still names the applicant', () {
      final offenders = <String>[];
      for (final entity in Directory(
        'lib/features/applications/presentation',
      ).listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        for (final match in RegExp(
          r"subtitle:\s*\n?\s*'([^']*)'",
        ).allMatches(entity.readAsStringSync())) {
          if (match.group(1)!.toLowerCase().contains('applicant')) {
            offenders.add('${entity.path}: ${match.group(1)}');
          }
        }
      }
      expect(offenders, isEmpty, reason: 'subtitles are the app\'s own voice');
    });

    test('third-person prose says citizen', () {
      expect(
        _lib('core/providers/applications_provider.dart'),
        contains('Corrections resubmitted by the citizen.'),
      );
    });
  });

  group('the product is Building Permit and Certificate of Occupancy', () {
    // A separate ruling from the citizen one, and it collided with it: the
    // strings that named the user also named the wrong product. E-BPCO is the
    // Electronic Building Permit and Certificate of Occupancy system, and the
    // sign-in screen told a citizen it managed their BUSINESS permits.

    test('the sign-in and sign-up copy says building', () {
      expect(
        _lib('features/authentication/presentation/login_screen.dart'),
        contains('manage your building permits'),
      );
      expect(
        _lib(
          'features/authentication/presentation/registration_success_screen.dart',
        ),
        contains('building permits and clearances'),
      );
    });

    test('and the eligibility clause names citizens', () {
      final terms = _lib(
        'features/profile/presentation/terms_conditions_screen.dart',
      );
      expect(terms, contains('intended for citizens filing for a permit'));
      // The three legally distinct parties survive the rewrite: the citizen,
      // whoever they authorise, and the professional who prepares the plans.
      expect(terms, contains('authorized representatives'));
      expect(terms, contains('licensed professionals'));
    });

    test('but "Business Permit" the DOMAIN and the FORM survive', () {
      // The trap this ruling carries. `Business Permit` is one of the
      // contract's two serviceDomain values, the app still has a legacy
      // business-permit flow at its own route, and "Group E — Business and
      // Mercantile" is an NBC occupancy classification. A blanket replacement
      // takes all three.
      expect(
        _lib('core/contract/service_domain.dart'),
        contains("'Business Permit'"),
        reason:
            'the contract enum was rewritten — every filing now declares a '
            'serviceDomain no server accepts',
      );
      expect(
        File('lib/routes/app_router.dart').readAsStringSync(),
        contains('/applications/new/business-permit'),
      );
      expect(
        _lib('core/models/sign_permit_model.dart'),
        contains('Business and Mercantile'),
        reason: 'an NBC occupancy classification was reworded',
      );
    });
  });

  group('and these three categories are deliberately untouched', () {
    test('draft snapshot keys still say applicant', () {
      // Storage AND wire. See docs/M-47-form-payload.md: rename Dart fields,
      // never these keys.
      final codec = _lib('core/drafts/fencing_permit_draft_codec.dart');
      expect(codec, contains("'applicant.firstName'"));
      expect(
        codec,
        isNot(contains("'citizen.firstName'")),
        reason:
            'a snapshot key was renamed — every draft on every device is '
            'orphaned and the office receives different field names',
      );
    });

    test('NBC form labels still say Applicant', () {
      // The forms say APPLICANT. The wizards mirror them so a citizen can
      // match screen to paper — that alignment was measured field-for-field.
      var mirrored = 0;
      for (final entity in Directory(
        'lib/features/applications/presentation',
      ).listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        final source = entity.readAsStringSync();
        if (source.contains("'Applicant Information'")) mirrored++;
        if (source.contains("'Applicant Address'")) mirrored++;
      }
      expect(
        mirrored,
        greaterThan(20),
        reason:
            'the form-mirroring labels have been swept. The wizards no longer '
            'match the paper forms they were built from',
      );
    });

    test('quoted sources are still quotations', () {
      final catalog = _lib('core/contract/requirements_catalog.dart');
      expect(
        catalog,
        contains('if the applicant is not the registered owner'),
        reason:
            "the checklist's own ownership clause was reworded. It is a "
            'transcription, not prose',
      );
    });
  });
}
