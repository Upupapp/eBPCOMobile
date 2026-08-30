import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:ebpco_user_app/core/contract/office_contact.dart';

/// The app may not invent a way to reach the office.
///
/// Every contact detail in this app was fabricated until 30 August 2026, and
/// all of it pointed at the wrong province: `support@ebpco.gov.ph` at a domain
/// no government entity holds, `(02) 8988-4242` on a Metro Manila area code,
/// and an office address in Quezon City — 500km from Castilla, Sorsogon, and
/// the structural reference this app's requirements were modelled on.
///
/// What made it a defect rather than untidiness is where it was printed: the
/// Privacy Policy named that address as the channel for exercising rights
/// under RA 10173. An applicant whose documents were mishandled was being sent
/// to a mailbox that does not exist.
///
/// This gate is deliberately blunt. It scans the applicant-facing screens for
/// the exact fabrications and for the shapes of new ones, because the failure
/// here is somebody adding a plausible-looking address to fill a gap.

const _surfaces = [
  'lib/features/profile/presentation/help_support_screen.dart',
  'lib/features/profile/presentation/privacy_policy_screen.dart',
  'lib/features/profile/presentation/terms_conditions_screen.dart',
];

String _read(String path) => File(path).readAsStringSync();

/// A file's code, with its comments removed.
///
/// The comment in `help_support_screen.dart` explains that the address used to
/// point at Quezon City — and a raw scan found "Quezon City" in the sentence
/// saying it is gone. The privacy manifest gate hit the identical trap the
/// same day, for the identical reason: **a file that documents the strings a
/// test looks for will fail that test every time.**
String _code(String path) => _read(path)
    .replaceAll(RegExp(r'/\*[\s\S]*?\*/'), '')
    .split('\n')
    .map((line) {
      final comment = line.indexOf('//');
      // Only a comment that starts the line, so a `//` inside a string literal
      // — a URL, say — is left alone.
      return comment >= 0 && line.substring(0, comment).trim().isEmpty
          ? ''
          : line;
    })
    .join('\n');

void main() {
  test('the scan reads real files, and strips only comments', () {
    for (final path in _surfaces) {
      expect(_read(path).length, greaterThan(500), reason: path);
      expect(
        _code(path).length,
        greaterThan(400),
        reason: '$path: stripping comments left almost nothing',
      );
      expect(
        _code(path),
        contains('Widget build'),
        reason: '$path: the strip ate code',
      );
    }
  });

  test('the three fabrications are gone from all three screens', () {
    for (final path in _surfaces) {
      final source = _code(path);
      expect(source, isNot(contains('ebpco.gov.ph')), reason: path);
      expect(source, isNot(contains('8988-4242')), reason: path);
      expect(source, isNot(contains('Quezon City')), reason: path);
    }
  });

  test('no applicant-facing screen holds its own email or phone literal', () {
    // The rule changed on 31 August, and why it changed is worth stating: the
    // office's real number and address turned out to be in this repository all
    // along, in the footer of its own bundled documentary checklist. So a
    // contact detail is no longer forbidden — an INVENTED one is.
    //
    // The shape, not the specific value. A gate that only knew the old strings
    // would pass the moment somebody wrote a different plausible one.
    final email = RegExp(r'[a-z0-9._%+-]+@[a-z0-9.-]+\.[a-z]{2,}');
    final phone = RegExp(r'\(0\d{1,2}\)\s?\d{3,4}-\d{4}|\b09\d{9}\b');
    for (final entity in Directory('lib/features').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final source = _code(entity.path);
      for (final literal in RegExp(r"'([^']{4,})'").allMatches(source)) {
        final text = literal.group(1)!;
        if (text.contains('@example') || text.contains('juan.delacruz')) {
          continue; // seed data and form hints, clearly not the office
        }
        expect(
          email.hasMatch(text) || phone.hasMatch(text),
          isFalse,
          reason:
              '${entity.path} writes out "$text". A real contact detail '
              'belongs in OfficeContact, which carries the document it came '
              'from; a screen literal carries nothing',
        );
      }
    }
  });

  test('the office\'s real details are shown, and sourced', () {
    // Found in assets/permits/Building-Permit-and-Occupancy-Checklist.pdf:
    // "please call MEO at 09054818572 (cellphone) or send an email at
    // meocastilla@gmail.com within 3 working days."
    expect(OfficeContact.phoneDigits, '09054818572');
    expect(OfficeContact.email, 'meocastilla@gmail.com');
    expect(OfficeContact.replyPledge, 'within 3 working days');
    expect(
      OfficeContact.contactSource,
      contains('documentary checklist'),
      reason: 'a number with no provenance is what this app printed before',
    );

    final help = _code(_surfaces.first);
    expect(help, contains('OfficeContact.phone'));
    expect(help, contains('OfficeContact.email'));
    expect(
      help,
      contains('OfficeContact.contactSource'),
      reason: 'the provenance belongs beside the details, not only in code',
    );
  });

  test('the checklist that supplies them is still bundled', () {
    // If the file goes, the citation above becomes a claim nobody can check.
    final checklist = File(
      'assets/permits/Building-Permit-and-Occupancy-Checklist.pdf',
    );
    expect(checklist.existsSync(), isTrue);
    expect(checklist.lengthSync(), greaterThan(1000));
  });

  test('the Data Protection Officer is still named as unpublished', () {
    // M-16's other half. The checklist gives the office; RA 10173 rights are a
    // different channel and the LGU has not named an officer for it.
    expect(
      OfficeContact.dataProtectionOfficerPending,
      contains('has not published a named Data Protection Officer'),
    );
    expect(
      _code('lib/features/profile/presentation/privacy_policy_screen.dart'),
      contains('OfficeContact.dataProtectionOfficerPending'),
    );
  });

  test('the website is presented as recorded, not as verified', () {
    // requirements_catalog.dart records castillasorsogon.gov.ph with
    // `PENDING_CASTILLA_VERIFICATION` and a note that it was not reachable by
    // automated research. The app may point at it; it may not vouch for it.
    final catalog = _read('lib/core/contract/requirements_catalog.dart');
    expect(catalog, contains('castillasorsogon.gov.ph'));
    expect(
      catalog,
      contains('PENDING_CASTILLA_VERIFICATION'),
      reason:
          'the domain lost its unverified status here. If it was verified, '
          'say so — and M-29, the bundle identifier, can then be decided',
    );
  });
}
