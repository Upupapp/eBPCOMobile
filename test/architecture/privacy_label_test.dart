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

  test('the app makes no third-party request for its typeface', () {
    // **This test used to assert the opposite.** It was written on 31 August
    // 2026 to hold a finding open — the app fetched Poppins from
    // fonts.gstatic.com at runtime, undeclared — and to FAIL the moment the
    // finding was fixed, so the label checklist could not go on warning an
    // operator about something already addressed. It fired the same day.
    //
    // The finding was not theoretical. Five hashed Poppins files were found in
    // the iOS Simulator's app container under Library/Application Support —
    // google_fonts' download cache, one file per weight. The app had been
    // making the request.
    //
    // Inverted now, in the direction that matters: this fails if the fetch
    // comes back.
    expect(
      File('lib/main.dart').readAsStringSync(),
      contains('GoogleFonts.config.allowRuntimeFetching = false'),
      reason:
          'the app may reach fonts.gstatic.com again — an undeclared '
          'third-party request carrying every applicant\'s IP, and the App '
          'Store label answers in this checklist become wrong',
    );
    expect(
      File('pubspec.yaml').readAsStringSync(),
      contains('family: Poppins'),
      reason:
          'the bundled family is gone, so a fetch is the only way to get '
          'the typeface back',
    );
    // Not "the checklist must not mention fonts.gstatic.com". It explains
    // what was fixed, so it names it — and banning the string is the
    // gate-tripped-by-its-own-explanation trap, which has caught this
    // repository four times. What must be true is that it reads as resolved.
    expect(
      _checklist(),
      contains('no longer does'),
      reason:
          'the checklist must state the fetch is gone. An operator reading a '
          'live warning about a request the app no longer makes would answer '
          'the third-party question wrongly',
    );
    expect(
      _checklist(),
      isNot(contains('One thing to decide before you answer')),
      reason: 'the open-decision section is still there',
    );
  });
}
