import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The one identifier this product ships under — except that it ships under
/// two.
///
/// M-29. Neither store lets an app change its bundle identifier after
/// publication: a new id is a new listing, losing reviews, ratings and
/// installed base. It also gates every remaining iOS step, because registering
/// a provisioning profile binds the id to the team.
///
/// **This file asserts the split AS IT STANDS**, deliberately, the way the
/// contract gates do. The reason is specific: the halves must change
/// *together*, and the failure mode is somebody fixing one of them. If either
/// side moves on its own, these tests fail and say so; when both move to the
/// same value, the last two tests fail and say to delete them.
///
/// The domain is not this lane's to choose. See
/// `docs/DECISION-M-29-bundle-identifier.md`.

/// What the Apple targets ship under today.
const _apple = 'com.ebpco.ebpcoUserApp';

/// What the Android and Linux targets ship under today.
const _android = 'com.ebpco.ebpco_user_app';

String _read(String path) => File(path).readAsStringSync();

/// A Dart file's code, with its comments removed.
///
/// `office_contact.dart` documents the fabricated address it replaced, so a
/// raw scan finds `ebpco.gov.ph` in the sentence explaining that it is gone.
/// That is the THIRD time in one day a source-scanning gate here has been
/// tripped by a file that documents the strings the gate looks for — the
/// privacy manifest and the office-contact gate hit it too. Strip first.
String _code(String path) => _read(path)
    .replaceAll(RegExp(r'/\*[\s\S]*?\*/'), '')
    .split('\n')
    .map((line) {
      final comment = line.indexOf('//');
      return comment >= 0 && line.substring(0, comment).trim().isEmpty
          ? ''
          : line;
    })
    .join('\n');

void main() {
  test('the scan finds the entries at all', () {
    // Every assertion below is a match count over these files. A path that
    // moved would make them all pass against nothing.
    final ios = _read('ios/Runner.xcodeproj/project.pbxproj');
    expect(
      RegExp('PRODUCT_BUNDLE_IDENTIFIER').allMatches(ios).length,
      6,
      reason:
          'six entries: three Runner configurations and three RunnerTests. '
          'If this changed, a build configuration was added or removed and '
          'the count below is measuring something else',
    );
    expect(_read('android/app/build.gradle.kts'), contains('applicationId'));
  });

  group('iOS — this machine owns it', () {
    test('all six Xcode entries agree', () {
      final ios = _read('ios/Runner.xcodeproj/project.pbxproj');
      final ids = RegExp(
        r'PRODUCT_BUNDLE_IDENTIFIER = ([^;]+);',
      ).allMatches(ios).map((m) => m.group(1)!).toSet();
      expect(ids, {_apple, '$_apple.RunnerTests'});
    });

    test('macOS carries the same spelling as iOS', () {
      // Not shipped, and still worth pinning: it is one of the two places the
      // Apple spelling is written down, and a change to only one of them is
      // the same class of split M-29 exists to close.
      expect(
        _read('macos/Runner/Configs/AppInfo.xcconfig'),
        contains('PRODUCT_BUNDLE_IDENTIFIER = $_apple'),
      );
    });
  });

  group('Android — the Windows lane owns it', () {
    test('the namespace and the application id agree', () {
      final gradle = _read('android/app/build.gradle.kts');
      expect(gradle, contains('namespace = "$_android"'));
      expect(gradle, contains('applicationId = "$_android"'));
    });

    test('MainActivity sits at the path the id derives', () {
      // The half that makes the Android change larger than the iOS one: the
      // Kotlin source lives at a directory path built from the identifier, so
      // changing it is a file move, not an edit.
      expect(
        File(
          'android/app/src/main/kotlin/'
          '${_android.replaceAll('.', '/')}/MainActivity.kt',
        ).existsSync(),
        isTrue,
      );
    });

    test('Linux carries the same spelling as Android', () {
      expect(
        _read('linux/CMakeLists.txt'),
        contains('set(APPLICATION_ID "$_android")'),
      );
    });
  });

  test('THE SPLIT — four targets, two spellings, one product', () {
    // The defect M-29 exists to close, held here so that it cannot be closed
    // by halves. iOS and macOS say one thing; Android and Linux say another.
    // They are separate namespaces, so nothing breaks today — which is exactly
    // why nobody had noticed — but both get quoted at Apple and Google as
    // though deliberate.
    expect(
      _apple,
      isNot(_android),
      reason:
          'the two halves now agree. Good — that is the point of M-29. Delete '
          'this expectation and the one below, and set both constants to the '
          'agreed identifier',
    );
    expect(
      _apple.toLowerCase(),
      _android.replaceAll('_', ''),
      reason:
          'they differ only in how the words are joined, which is what makes '
          'this a spelling split rather than two different products',
    );
  });

  test("the LGU's domain is recorded, and is a real .gov.ph zone", () {
    // **This corrects the M-29 decision note twice over.**
    //
    // The note first said no .gov.ph domain for Castilla appeared anywhere in
    // the repository. Wrong: the check looked at the docs and the platform
    // files, not at `lib`. `castillasorsogon.gov.ph` is recorded in the
    // requirements catalogue as the Municipality of Castilla, Sorsogon's
    // official site.
    //
    // It then said the domain was recorded but UNVERIFIED, on the strength of
    // the catalogue entry's own note that the site was "not accessible to
    // automated research". That conflated two different claims, and only one
    // of them is still open:
    //
    //   * Does the DOMAIN exist and belong to a government entity?
    //     Answered 31 August 2026 by DNS. It resolves; the zone is delegated
    //     to ns3/ns4/ns5.dns.gov.ph; the SOA responsible party is
    //     dns.dict.gov.ph — the Department of Information and Communications
    //     Technology, which administers the .gov.ph namespace. A .gov.ph zone
    //     is issued only to a Philippine government entity.
    //   * Is the CHARTER CONTENT in this catalogue Castilla's own?
    //     Still no. That is what PENDING_CASTILLA_VERIFICATION means, and it
    //     is why the Citizen's Charter screen carries its provenance notice.
    //     It says nothing about the domain.
    //
    // The page itself is still not machine-readable — it sits behind a
    // Cloudflare challenge and returns 403 — so what is verified is the zone,
    // not the wording on the site. That is enough for a reverse-DNS
    // identifier, which is a claim about a domain and not about a page.
    final catalog = File(
      'lib/core/contract/requirements_catalog.dart',
    ).readAsStringSync();
    expect(catalog, contains('castillasorsogon.gov.ph'));
    expect(catalog, contains('Municipality of Castilla, Sorsogon'));
    expect(
      catalog,
      contains('PENDING_CASTILLA_VERIFICATION'),
      reason:
          'the CHARTER CONTENT lost its unverified status. If Castilla '
          'supplied its published Citizen\'s Charter, M-08 can close and the '
          'provenance notice on that screen needs re-reading — this is not '
          'the same question as the domain',
    );
  });

  test('the recommended identifier follows from that domain', () {
    // Held here so the recommendation cannot drift from the evidence for it,
    // and so that applying it is a matter of changing two constants and
    // deleting the split expectation below rather than re-deriving anything.
    const recommended = 'ph.gov.castillasorsogon.ebpco';
    expect(
      recommended,
      startsWith('ph.gov.'),
      reason: 'reverse-DNS of a .gov.ph domain, most-significant label first',
    );
    expect(recommended.split('.').length, 4);
    expect(
      recommended,
      isNot(contains('_')),
      reason: 'Apple discourages an underscore in a bundle identifier',
    );
    expect(
      recommended,
      isNot(anyOf(contains('UserApp'), contains('user_app'))),
      reason:
          'both current spellings name an internal build target rather than '
          'the product an applicant installs',
    );
    expect(
      File('docs/DECISION-M-29-bundle-identifier.md').readAsStringSync(),
      contains(recommended),
      reason: 'the note and this test must recommend the same string',
    );
  });

  test('and no OTHER .gov.ph domain is invented anywhere in lib', () {
    // The fabrication this app shipped until 30 August 2026 was exactly this:
    // `support@ebpco.gov.ph`, a domain no government entity holds, printed as
    // the channel for exercising data privacy rights. See
    // `test/features/office_contact_test.dart`.
    const known = {
      'dpwh',
      'dilg',
      'arta',
      'privacy',
      'officialgazette',
      'elibrary',
      'dict',
      'dti',
      'prc',
      'bfp',
      'quezoncity',
      'qceservices',
      'example',
      'csc',
      'psa',
      'denr',
      'doh',
      'dole',
      'castillasorsogon',
    };
    final hits = <String>[];
    var scanned = 0;
    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      scanned++;
      for (final match in RegExp(
        r'\b([a-z0-9-]+)\.gov\.ph\b',
      ).allMatches(_code(entity.path))) {
        if (!known.contains(match.group(1))) {
          hits.add('${entity.path}: ${match.group(0)}');
        }
      }
    }
    expect(
      scanned,
      greaterThan(200),
      reason: 'the scan barely read anything — check the strip',
    );
    expect(
      hits,
      isEmpty,
      reason:
          'an unrecognised .gov.ph domain appears in the app: $hits. A '
          '.gov.ph domain is issued to a government entity — if this one is '
          "real, record where that was verified; if it is not, it is a "
          'fabrication an applicant will act on',
    );
  });
}
