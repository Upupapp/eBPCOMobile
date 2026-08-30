import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

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

  test('no applicant-facing screen invents an email address or a phone', () {
    // The shape, not the specific value. A gate that only knew the old strings
    // would pass the moment somebody wrote a different plausible one.
    final email = RegExp(r'[a-z0-9._%+-]+@[a-z0-9.-]+\.[a-z]{2,}');
    final phone = RegExp(r'\(0\d{1,2}\)\s?\d{3,4}-\d{4}');
    for (final entity in Directory('lib/features').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final source = _code(entity.path);
      // Only what the applicant is shown: a Dart string literal.
      for (final literal in RegExp(r"'([^']{4,})'").allMatches(source)) {
        final text = literal.group(1)!;
        if (text.contains('@example') || text.contains('juan.delacruz')) {
          continue; // seed data and form hints, clearly not the office
        }
        expect(
          email.hasMatch(text) || phone.hasMatch(text),
          isFalse,
          reason:
              '${entity.path} shows "$text". If this is the office\'s real, '
              'published contact detail, put it in OfficeContact with the '
              'source that verifies it — not in a screen',
        );
      }
    }
  });

  test('the pending sentence is written once and used three times', () {
    // The mistake this repository has already made once, with the draft copy:
    // two surfaces made the same promise, one was corrected, and the other was
    // missed. One constant, three uses.
    final contact = _read('lib/core/contract/office_contact.dart');
    expect(contact, contains('static const String detailsPending'));
    for (final path in _surfaces) {
      expect(
        _read(path),
        contains('OfficeContact.detailsPending'),
        reason: '$path states it in its own words instead',
      );
    }
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
