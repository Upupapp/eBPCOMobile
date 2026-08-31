import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:ebpco_user_app/core/config/app_config.dart';
import 'package:ebpco_user_app/core/constants/app_strings.dart';

/// What must be true of a build before it can go to the App Store.
///
/// Written 31 August 2026 for the submission sweep. **iOS only** — `android/`,
/// the Play Console and Android signing belong to the Windows lane, by
/// standing rule.
///
/// These are the checks a reviewer or the upload pipeline makes, asserted here
/// so they fail on this machine in seconds rather than after an upload and a
/// day of waiting.

String _plist(String key) => Process.runSync('/usr/libexec/PlistBuddy', [
  '-c',
  'Print :$key',
  'ios/Runner/Info.plist',
]).stdout.toString().trim();

void main() {
  test('no working credentials are printed in a release build', () {
    // The sign-in screen carried "Prototype access — use user@ebpco.com /
    // password123 to explore the app" in every build. Apple wants review
    // credentials in App Store Connect's review notes, not on the screen a
    // citizen sees, and an LGU permit app advertising a shared password
    // teaches the habit it can least afford.
    //
    // `kDebugMode` is a compile-time constant, so the strings are tree-shaken
    // out of a release binary rather than merely hidden behind a flag.
    final login = File(
      'lib/features/authentication/presentation/login_screen.dart',
    ).readAsStringSync();
    expect(
      login,
      contains('if (kDebugMode)'),
      reason: 'the credential banner is no longer confined to debug builds',
    );
    expect(
      login,
      isNot(contains('Prototype access')),
      reason: 'the release-facing wording is back',
    );
  });

  test('the credentials compile away in a release build', () {
    // Measured, not assumed. `strings` on
    // build/ios/iphoneos/Runner.app/Frameworks/App.framework found
    // `password123` ONCE before this change and ZERO times after — the
    // literal is not in the shipped binary, because `kReleaseMode` is a
    // compile-time constant and the release build compiles `''`.
    //
    // Re-measure with:
    //   flutter build ios --release --no-codesign
    //   strings build/ios/iphoneos/Runner.app/Frameworks/App.framework/App \
    //     | grep -c password123
    final strings = File(
      'lib/core/constants/app_strings.dart',
    ).readAsStringSync();
    expect(strings, contains("kReleaseMode ? '' : 'password123'"));
    expect(strings, contains("kReleaseMode ? '' : 'user@ebpco.com'"));
    // And in a test binary kReleaseMode is false, so the mock account still
    // works for the suite and for development.
    expect(AppStrings.mockPassword, 'password123');
  });

  test('and no credential is hardcoded outside the mock constants', () {
    // The mock account itself stays — it is how the wizards are exercised
    // with no backend. What must not spread is the literal.
    final offenders = <String>[];
    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      if (entity.path.endsWith('app_strings.dart')) continue;
      final source = entity.readAsStringSync();
      if (source.contains("'password123'") ||
          source.contains("'user@ebpco.com'")) {
        offenders.add(entity.path);
      }
    }
    expect(
      offenders,
      isEmpty,
      reason:
          'credential literals outside the '
          'constants file: $offenders',
    );
  });

  test('a release build with no backend refuses to start', () {
    // The finding that made this sweep worth running. `strings` on the
    // release framework still found `password123` after the sign-in banner
    // advertising it was confined to debug — because without a base URL the
    // app serves MockAuthRepository, and that account SHIPS. The banner was
    // the visible half; the working credential was the real one. The same
    // build also serves a fabricated application, shown to whoever opens the
    // app as their own filing.
    //
    // In a test binary kReleaseMode is false, so the guard is inert here and
    // this asserts it exists and is called rather than exercising it.
    expect(AppConfig.isUnshippableDemo, isFalse);
    expect(
      File('lib/main.dart').readAsStringSync(),
      contains('AppConfig.assertShippable()'),
      reason:
          'main() no longer refuses a backend-less release build, so the App '
          'Store artefact can once again carry a shared password',
    );
    expect(
      File('lib/core/config/app_config.dart').readAsStringSync(),
      contains('kReleaseMode && !useLiveBackend'),
      reason: 'the condition that defines an unshippable demo has changed',
    );
  });

  test('export compliance is declared', () {
    // The app speaks HTTPS and nothing else; TLS is exempt encryption. Saying
    // so here removes the question App Store Connect asks on every upload —
    // and an unanswered question holds a build out of review.
    expect(_plist('ITSAppUsesNonExemptEncryption'), 'false');
  });

  test('the bundle carries a real identity', () {
    expect(_plist('CFBundleDisplayName'), 'E-BPCO');
    final pbx = File('ios/Runner.xcodeproj/project.pbxproj').readAsStringSync();
    expect(pbx, contains('ph.gov.castillasorsogon.ebpco'));
    expect(
      pbx,
      isNot(contains('com.example')),
      reason: 'the Flutter template identifier would be rejected outright',
    );
  });

  test('the marketing icon exists and is 1024 square with no alpha', () {
    // Apple rejects a 1024 icon with an alpha channel, and the upload fails
    // before review rather than during it.
    final icon = File(
      'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png',
    );
    expect(icon.existsSync(), isTrue);
    final bytes = icon.readAsBytesSync();
    expect(bytes.take(8).toList(), [137, 80, 78, 71, 13, 10, 26, 10]);
    int dim(int at) =>
        (bytes[at] << 24) |
        (bytes[at + 1] << 16) |
        (bytes[at + 2] << 8) |
        bytes[at + 3];
    expect(dim(16), 1024);
    expect(dim(20), 1024);
    // IHDR colour type is byte 25: 2 = RGB, 6 = RGBA. Apple wants no alpha.
    expect(
      bytes[25],
      isNot(6),
      reason:
          'the 1024 icon has an alpha channel; App Store Connect refuses it',
    );
  });

  test('every permission the app requests explains itself', () {
    // A missing usage description is a crash on first use, not a warning.
    for (final key in const [
      'NSCameraUsageDescription',
      'NSPhotoLibraryUsageDescription',
    ]) {
      final value = _plist(key);
      expect(value, isNotEmpty, reason: '$key is missing');
      expect(
        value.length,
        greaterThan(30),
        reason: '$key is too terse to satisfy a reviewer: "$value"',
      );
      expect(value.toLowerCase(), contains('ebpco'));
    }
  });
}
