import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ebpco_user_app/shared/widgets/branding/app_logo.dart';

/// Whose seal the app signs itself with.
///
/// It used to be the **DILG** seal — the Department of the Interior and Local
/// Government. Changed 31 August 2026 at the owner's instruction, to the seal
/// the Municipality of Castilla publishes on its own website: the app is
/// Castilla's, so the mark it signs itself with should be too.
///
/// **This comment first called it a misattribution — "an issuer the app does
/// not have" — and compared it to the invented Quezon City address. That was
/// wrong.** The LGU is a partner with the DILG, which also co-issues the
/// DILG–DPWH–DICT–DTI Joint Memorandum Circular the Terms cite. A real
/// relationship, and a real seal. The change stands on identity, not on
/// impropriety, and the difference matters: one is a fabrication and the other
/// is the wrong mark in the wrong place.

void main() {
  test('the seal ships, and is the file the LGU publishes', () {
    final seal = File('assets/images/castilla-seal.png');
    expect(seal.existsSync(), isTrue);

    // Copied byte-for-byte from the LGU's own site rather than re-encoded
    // from a screenshot. If this ever fails, someone replaced it with a
    // different rendering and the provenance claim in app_logo.dart is stale.
    final bytes = seal.readAsBytesSync();
    expect(bytes.take(8).toList(), [
      0x89,
      0x50,
      0x4E,
      0x47,
      0x0D,
      0x0A,
      0x1A,
      0x0A,
    ], reason: 'not a PNG');
    expect(bytes.length, greaterThan(100000));
  });

  test('and it is declared in the bundle', () {
    // assets/images/ is declared as a directory, so a file added there ships.
    // Asserted anyway: an asset that is on disk and not in the bundle renders
    // as a grey box on a device and as nothing in a test.
    expect(File('pubspec.yaml').readAsStringSync(), contains('assets/images/'));
  });

  test('nothing renders the DILG seal, and it no longer ships', () {
    // Kept in the repository, moved OUT of the bundle on 31 August 2026.
    //
    // `assets/images/` is declared as a directory, so anything in it ships
    // whether referenced or not — the seal was still travelling in the iOS
    // binary as `DILG%20logo.png` (URL-encoded, which is why a check for the
    // literal filename first reported it absent). A municipal app should not
    // carry a national department's seal it does not display.
    expect(
      File('assets/images/DILG logo.png').existsSync(),
      isFalse,
      reason: 'back under assets/, so back in the binary',
    );
    expect(
      File('docs/reference-assets/DILG logo.png').existsSync(),
      isTrue,
      reason: 'kept for reference, outside the bundle',
    );
    final referencing = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        .where((f) => f.readAsStringSync().contains('DILG logo.png'))
        .map((f) => f.path)
        .toList();
    expect(
      referencing,
      isEmpty,
      reason:
          'these render the national department\'s seal as this app\'s mark: '
          '$referencing',
    );
  });

  testWidgets('the mark on screen is Castilla\'s', (tester) async {
    // AppLogo is used by the splash, onboarding and authentication screens —
    // three surfaces, one widget, which is why the change was made here.
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: Center(child: AppLogo())),
      ),
    );

    final image = tester.widget<Image>(find.byType(Image));
    final provider = image.image as AssetImage;
    expect(provider.assetName, 'assets/images/castilla-seal.png');
  });
}
