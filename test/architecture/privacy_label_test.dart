import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The App Store Connect privacy label, checked against the binary it describes.
///
/// The label is a **second declaration of the same facts** as
/// `PrivacyInfo.xcprivacy`, kept in Apple's web console where no test can read
/// it. That is exactly how it went stale: the manifest was updated when the app
/// began transmitting the wizard contents on 31 August 2026, and the label was
/// not, because nothing failed.
///
/// So the checklist an operator transcribes lives in the repository, and this
/// asserts it against the manifest. If the manifest gains a data type, the
/// checklist fails and names it — the failure that should have happened when
/// `form` started being sent.

String _manifest() =>
    File('ios/Runner/PrivacyInfo.xcprivacy').readAsStringSync();

String _checklist() =>
    File('docs/M-50-app-store-privacy-label.md').readAsStringSync();

void main() {
  test('the scan reads something', () {
    // Both files are read by every assertion below; a moved path would make
    // them pass against nothing.
    expect(_manifest(), contains('NSPrivacyCollectedDataTypes'));
    expect(_checklist(), contains('App Privacy'));
  });

  test('the checklist names every type the manifest declares', () {
    // Matched as the VALUE of the NSPrivacyCollectedDataType key, not as any
    // string containing that prefix — `NSPrivacyCollectedDataTypePurposes`
    // and its `...PurposeAppFunctionality` entries share it, and a looser
    // pattern counted ten types where there are nine.
    final declared = RegExp(
      r'<key>NSPrivacyCollectedDataType</key>\s*'
      r'<string>NSPrivacyCollectedDataType(\w+)</string>',
    ).allMatches(_manifest()).map((m) => m.group(1)!).toSet();

    expect(
      declared,
      hasLength(9),
      reason:
          'the manifest declares ${declared.length} data types, and the '
          'checklist is written for nine. If a type was added, the App Store '
          'Connect label needs another answer: $declared',
    );

    final checklist = _checklist();
    for (final type in declared) {
      expect(
        checklist,
        contains('`$type`'),
        reason:
            '$type is transmitted and the label checklist does not mention '
            'it. An operator transcribing this would under-declare',
      );
    }
  });

  test('and claims nothing the manifest does not', () {
    // The other direction. A checklist listing a type the app does not collect
    // is an over-declaration, which Apple treats as seriously as the reverse.
    const notCollected = {
      'PreciseLocation': 'Location',
      'CoarseLocation': 'Location',
      'DeviceID': 'Device ID',
      'SensitiveInfo': 'Sensitive Info',
      'Contacts': 'Contacts',
      'BrowsingHistory': 'Browsing History',
      'SearchHistory': 'Search History',
      'AdvertisingData': 'Advertising Data',
    };
    notCollected.forEach((key, human) {
      expect(
        _manifest(),
        isNot(contains('NSPrivacyCollectedDataType$key')),
        reason:
            '$key is now in the manifest and the checklist says it is not '
            'collected',
      );
      expect(
        _checklist(),
        contains(human),
        reason: '$human is not accounted for in the "Not collected" list',
      );
    });
  });

  test('the tracking answers agree', () {
    expect(_manifest(), contains('<key>NSPrivacyTracking</key>'));
    expect(_manifest(), contains('<false/>'));
    expect(_checklist(), contains('Does this app track users?'));
    expect(_checklist(), contains('→ No.'));
  });

  test('the runtime font fetch is still true, and still stated', () {
    // M-51. The app calls GoogleFonts.poppins() with no bundled Poppins and no
    // `allowRuntimeFetching = false`, so it downloads the typeface from
    // fonts.gstatic.com — a third-party request carrying the device's IP,
    // made for every applicant, that nothing in the app discloses.
    //
    // This test is written to FAIL when the finding stops being true, so the
    // checklist cannot go on warning an operator about something that has
    // been fixed. Either bundle the fonts or turn fetching off; then delete
    // the M-51 section.
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final usesPackage = pubspec.contains('google_fonts:');
    final bundlesFonts = RegExp(
      r'^\s{2}fonts:',
      multiLine: true,
    ).hasMatch(pubspec);
    final fetchDisabled = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        .any((f) => f.readAsStringSync().contains('allowRuntimeFetching'));

    if (!usesPackage || bundlesFonts || fetchDisabled) {
      fail(
        'the runtime font fetch has been addressed — remove the M-51 section '
        'from docs/M-50-app-store-privacy-label.md and delete this test',
      );
    }
    expect(
      _checklist(),
      contains('fonts.gstatic.com'),
      reason:
          'the app still fetches its typeface from a third party and the '
          'checklist no longer says so',
    );
  });
}
