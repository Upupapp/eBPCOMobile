import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The iOS privacy manifest, held to what the app actually does.
///
/// M-46. Apple requires `PrivacyInfo.xcprivacy` for App Store submission, and
/// the declaration is made under penalty of rejection — but nothing about it
/// is checked by the compiler, so it goes stale the first time someone adds a
/// field to a request body. This is the check.
///
/// Three claims are worth failing over, and each has its own test below:
/// the manifest ships (a file not in the build phase reaches nobody), it
/// accounts for everything the app transmits, and its two empty arrays —
/// tracking domains and required-reason APIs — are still empty for the reason
/// they were emptied.
///
/// **What this cannot do**: it matches text, it does not parse a plist. A
/// malformed manifest is caught by `plutil -lint`, not here. What it catches
/// is drift between the declaration and the code, which is the failure that
/// actually happens.

const _manifest = 'ios/Runner/PrivacyInfo.xcprivacy';

/// Which Apple data type covers each key the app puts in a request body.
///
/// A key with no entry fails the test rather than defaulting to anything: a
/// new field in a request body is exactly the moment this manifest needs
/// re-reading, and a default would let that moment pass silently.
const Map<String, String> _declaredFor = {
  'firstName': 'NSPrivacyCollectedDataTypeName',
  'lastName': 'NSPrivacyCollectedDataTypeName',
  'email': 'NSPrivacyCollectedDataTypeEmailAddress',
  'mobileNumber': 'NSPrivacyCollectedDataTypePhoneNumber',
  'street': 'NSPrivacyCollectedDataTypePhysicalAddress',
  'barangay': 'NSPrivacyCollectedDataTypePhysicalAddress',
  'city': 'NSPrivacyCollectedDataTypePhysicalAddress',
  'province': 'NSPrivacyCollectedDataTypePhysicalAddress',
  // The construction site, as one line, sent on every filing since 31 August
  // 2026. A physical address like any other — it is where the applicant is
  // building, and for a house that is where they will live.
  'location': 'NSPrivacyCollectedDataTypePhysicalAddress',
  // The application, the business it is filed for, and the credential that
  // authenticates it. All "Other Data Types" in Apple's vocabulary, which has
  // no category for a building permit.
  'password': 'NSPrivacyCollectedDataTypeOtherDataTypes',
  'name': 'NSPrivacyCollectedDataTypeOtherDataTypes',
  'category': 'NSPrivacyCollectedDataTypeOtherDataTypes',
  'businessId': 'NSPrivacyCollectedDataTypeOtherDataTypes',
  'permitType': 'NSPrivacyCollectedDataTypeOtherDataTypes',
  'applicationAction': 'NSPrivacyCollectedDataTypeOtherDataTypes',
  'documents': 'NSPrivacyCollectedDataTypeOtherDataTypes',
  'label': 'NSPrivacyCollectedDataTypeOtherDataTypes',
  'fileName': 'NSPrivacyCollectedDataTypeOtherDataTypes',
  'proof': 'NSPrivacyCollectedDataTypeOtherDataTypes',
  // The ids that came back from /documents. The FILES themselves are what is
  // really being declared — see the user-content entries in the manifest — and
  // these keys are how a filing points at them.
  'documentIds': 'NSPrivacyCollectedDataTypePhotosorVideos',
  'documentId': 'NSPrivacyCollectedDataTypePhotosorVideos',
  // The applicant's answer to a Letter of Instruction: which deficiency, and
  // what they wrote back about it. Application content.
  'items': 'NSPrivacyCollectedDataTypeOtherDataTypes',
  'itemId': 'NSPrivacyCollectedDataTypeOtherDataTypes',
  'response': 'NSPrivacyCollectedDataTypeOtherDataTypes',
  // **A compound, and by far the largest thing this app sends.** `form` is the
  // whole wizard: every answer the applicant typed, sent since 1 September
  // 2026 and sent as nothing before it. One key in the body, up to 239 fields
  // inside it on a mechanical permit.
  //
  // Its contents fall under types already declared above and already in the
  // manifest — names, a physical address, phone numbers, and the application
  // details Apple has no category for. It introduces no NEW type, which is
  // why one entry is honest here; what it does introduce is volume, and one
  // fact worth naming:
  //
  //   **It carries other people's data, not only the applicant's.** Every
  //   construction wizard collects the designing professional and the
  //   full-time supervisor — name, PRC licence, PTR, address, contact number.
  //   Those are third parties to this app's account holder. Apple's manifest
  //   has no axis for a data subject, so the types are unchanged; the App
  //   Store Connect privacy label and the in-app Privacy Policy are where
  //   that has to be visible, and both were written when the app transmitted
  //   none of it.
  'form': 'NSPrivacyCollectedDataTypeOtherDataTypes',
  // A payment the applicant made to the LGU: how, when, how much, and the
  // bank reference or OR number. Apple has a category for exactly this, and
  // it is not "other" — folding it in with the permit details would understate
  // what is being sent.
  'method': 'NSPrivacyCollectedDataTypeOtherFinancialInfo',
  'referenceNumber': 'NSPrivacyCollectedDataTypeOtherFinancialInfo',
  'paidOn': 'NSPrivacyCollectedDataTypeOtherFinancialInfo',
  'amountCentavos': 'NSPrivacyCollectedDataTypeOtherFinancialInfo',
};

/// Keys that carry nothing about the applicant.
const Map<String, String> _notPersonalData = {
  'serviceDomain':
      'Which of the LGU\'s two services the application belongs to — Business '
      'Permit or Construction Permit. A property of the filing, not of the '
      'person filing it, and the same for every applicant who files one.',
  'grantType':
      'A protocol constant. The app sends the literal string "password" to '
      'name the OAuth grant it is using; it says nothing about who is using '
      'it and describes no person.',
};

/// Every key inside a `body: {...}` in the HTTP repositories.
///
/// Brace-matched from `body: {`, so a key that only appears in a response
/// parser or a log line is not mistaken for something the app sends. The
/// question Apple asks is about transmission.
Set<String> _transmittedKeys() {
  final keys = <String>{};
  for (final entity in Directory('lib/core/repositories').listSync()) {
    if (entity is! File || !entity.path.contains('/http_')) continue;
    final source = entity.readAsStringSync();
    for (final start in RegExp(r'body: \{').allMatches(source)) {
      var depth = 1;
      var i = start.end;
      while (i < source.length && depth > 0) {
        if (source[i] == '{') depth++;
        if (source[i] == '}') depth--;
        i++;
      }
      keys.addAll(
        RegExp(
          r"'(\w+)':",
        ).allMatches(source.substring(start.end, i)).map((m) => m.group(1)!),
      );
    }
  }
  return keys;
}

void main() {
  final raw = File(_manifest).readAsStringSync();

  /// The manifest with its XML comments removed.
  ///
  /// The comments in that file explain what to add WHEN the app starts
  /// uploading files, and name the exact Apple constants to add. A scan over
  /// the raw text therefore found `NSPrivacyCollectedDataTypePhotosorVideos`
  /// in a sentence saying it is deliberately absent, and concluded it was
  /// declared. A file that documents the strings a test looks for will do this
  /// every time.
  final manifest = raw.replaceAll(RegExp(r'<!--[\s\S]*?-->'), '');
  final project = File(
    'ios/Runner.xcodeproj/project.pbxproj',
  ).readAsStringSync();

  test('the scan is not vacuous', () {
    // Every assertion below is a `contains` over these two strings. If either
    // came back empty they would all pass against nothing.
    expect(raw.length, greaterThan(1000));
    expect(
      manifest.length,
      greaterThan(800),
      reason: 'stripping comments left almost nothing — the regex overreached',
    );
    expect(
      manifest,
      isNot(contains('Required-reason APIs are declared')),
      reason: 'a comment survived the strip',
    );
    expect(manifest, contains('NSPrivacyCollectedDataTypes'));
    expect(
      _transmittedKeys(),
      contains('firstName'),
      reason: 'the body scan found nothing it should certainly have found',
    );
  });

  test('the manifest is part of the Runner build, not just on disk', () {
    // The failure this exists for: a manifest that is present in the
    // repository, correct in every detail, and in no build phase — so it never
    // reaches the app bundle and Apple never sees it. Nothing else would say
    // so until a submission was rejected.
    expect(
      project,
      contains('PrivacyInfo.xcprivacy in Resources'),
      reason: 'the manifest is not in any Resources build phase',
    );
    // The section DEFINITION, not the target's `buildPhases` list, which
    // names the same id two hundred lines earlier and would slice the wrong
    // block entirely.
    final runnerResources = project.substring(
      project.indexOf('97C146EC1CF9000F007C117D /* Resources */ = {'),
    );
    expect(
      runnerResources.substring(0, runnerResources.indexOf(');')),
      contains('PrivacyInfo.xcprivacy'),
      reason:
          'the manifest is in a build phase, but not the Runner target\'s — '
          'RunnerTests would ship it nowhere',
    );
  });

  test('everything the app transmits is accounted for', () {
    final unaccounted = <String>[];
    for (final key in _transmittedKeys()) {
      if (_notPersonalData.containsKey(key)) continue;
      final type = _declaredFor[key];
      if (type == null || !manifest.contains(type)) unaccounted.add(key);
    }
    expect(
      unaccounted,
      isEmpty,
      reason:
          'these are sent to the server and the privacy manifest does not '
          'account for them: $unaccounted. Add the field to _declaredFor with '
          'the Apple data type that covers it, add that type to the manifest '
          'if it is not there, and check the App Store Connect privacy label '
          'still matches — it is a separate declaration of the same facts',
    );
  });

  test(
    'no file bytes leave the device, which is why no user content is declared',
    () {
      // The document upload flow is not built: the app sends a label and a
      // filename, never the file. The manifest says so, and says what to do when
      // that changes. This is the trigger.
      final sources = Directory('lib/core')
          .listSync(recursive: true)
          .whereType<File>()
          .where(
            (f) => f.path.endsWith('.dart') && !f.path.contains('services/'),
          )
          .map((f) => f.readAsStringSync())
          .join();
      // `lib/core/services/` is excluded: the PBKDF2 verifier base64-encodes a
      // password hash on the device and sends nothing, and a scan that counted
      // it would report an upload path that does not exist.
      final uploads = [
        for (final marker in const [
          'MultipartRequest',
          'MultipartFile',
          'readAsBytes',
          'base64Encode',
        ])
          if (sources.contains(marker)) marker,
      ];
      if (uploads.isEmpty) {
        expect(
          manifest,
          isNot(contains('NSPrivacyCollectedDataTypePhotosorVideos')),
          reason:
              'nothing uploads a file, so declaring photo collection would be a '
              'false statement in the other direction',
        );
        return;
      }
      expect(
        manifest,
        anyOf(
          contains('NSPrivacyCollectedDataTypePhotosorVideos'),
          contains('NSPrivacyCollectedDataTypeOtherUserContent'),
        ),
        reason:
            'the app now sends file content ($uploads) and the manifest still '
            'declares only labels and filenames',
      );
    },
  );

  test('the empty required-reason list is still true of this binary', () {
    // Apple requires the binary that CALLS a required-reason API to declare
    // it. The app's own native code is two files and calls none; every plugin
    // ships its own manifest. If first-party native code starts calling one,
    // the empty array becomes a false statement.
    expect(manifest, contains('<key>NSPrivacyAccessedAPITypes</key>'));
    final native = Directory('ios/Runner')
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.swift') || f.path.endsWith('.m'))
        .map((f) => f.readAsStringSync())
        .join();
    expect(native, isNotEmpty, reason: 'no native sources were read at all');

    final used = [
      for (final api in const [
        'UserDefaults',
        'NSUserDefaults',
        'creationDate',
        'modificationDate',
        'systemUptime',
        'mach_absolute_time',
        'volumeAvailableCapacity',
        'activeInputModes',
      ])
        if (native.contains(api)) api,
    ];
    expect(
      used,
      isEmpty,
      reason:
          'first-party native code now calls $used, which is a required-reason '
          'API. NSPrivacyAccessedAPITypes must declare it with a reason code',
    );
  });

  test('the app still has nothing that could track', () {
    // NSPrivacyTracking false is a claim about the whole app, and the way it
    // stops being true is a dependency, not a line of code.
    expect(manifest, contains('<key>NSPrivacyTracking</key>'));
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final trackers = [
      for (final sdk in const [
        'firebase_analytics',
        'google_mobile_ads',
        'facebook_app_events',
        'appsflyer',
        'app_tracking_transparency',
        'amplitude',
        'mixpanel',
        'sentry',
        'firebase_crashlytics',
      ])
        if (pubspec.contains(sdk)) sdk,
    ];
    expect(
      trackers,
      isEmpty,
      reason:
          '$trackers was added. NSPrivacyTracking, NSPrivacyTrackingDomains '
          'and the collected-data purposes all have to be revisited, and so '
          'does the App Store Connect privacy label',
    );
  });
}
