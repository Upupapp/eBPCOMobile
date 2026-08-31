import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:ebpco_user_app/core/theme/app_typography.dart';

/// The app must never fetch its typeface. M-51.
///
/// `google_fonts` downloads the family from `fonts.gstatic.com` on first use
/// unless it is turned off — a third-party request carrying the device's IP,
/// made for every applicant before they have agreed to anything, that nothing
/// in the app declared. It also made the typeface **non-deterministic**: a
/// first launch offline got the platform font and kept it.
///
/// Found on 31 August 2026 while preparing the App Store privacy label
/// answers, which is the kind of place it hides: nothing about the code looked
/// wrong, and the dependency's default did the rest.

void main() {
  test('every weight the design uses is bundled', () {
    // 400/500/600/700/800 — the weights `app_typography.dart` asks for, and
    // the ones the Web Admin's brand typeface is loaded at. A missing weight
    // is not a crash; with fetching off it silently falls back to the
    // platform font for that one style.
    const weights = {
      400: 'Poppins-Regular.ttf',
      500: 'Poppins-Medium.ttf',
      600: 'Poppins-SemiBold.ttf',
      700: 'Poppins-Bold.ttf',
      800: 'Poppins-ExtraBold.ttf',
    };
    final pubspec = File('pubspec.yaml').readAsStringSync();

    weights.forEach((weight, file) {
      expect(
        File('assets/fonts/$file').existsSync(),
        isTrue,
        reason: '$file is not in assets/fonts',
      );
      expect(
        pubspec,
        contains('assets/fonts/$file'),
        reason:
            '$file is on disk but not declared in pubspec.yaml, so it is '
            'not in the bundle',
      );
      expect(pubspec, contains('weight: $weight'));
    });
  });

  test('and the font files are fonts, not error pages', () {
    // They were downloaded. A 404 saved to disk is still a file, and a
    // pubspec that lists it still builds — the app just renders in the
    // fallback font, which is exactly the outcome this whole change exists to
    // prevent, arrived at silently.
    for (final file in Directory('assets/fonts').listSync().whereType<File>()) {
      if (!file.path.endsWith('.ttf')) continue;
      final header = file.readAsBytesSync().take(4).toList();
      expect(
        header,
        anyOf(
          // 0x00010000 — TrueType outlines.
          equals([0x00, 0x01, 0x00, 0x00]),
          // 'true' / 'OTTO', the other two sfnt signatures.
          equals([0x74, 0x72, 0x75, 0x65]),
          equals([0x4F, 0x54, 0x54, 0x4F]),
        ),
        reason: '${file.path} is not an sfnt font file',
      );
      expect(file.lengthSync(), greaterThan(50000));
    }
  });

  test('the licence ships beside them, because the OFL requires it', () {
    // SIL Open Font License 1.1 permits redistribution — and conditions it on
    // the licence travelling with the font.
    final ofl = File('assets/fonts/OFL.txt');
    expect(ofl.existsSync(), isTrue);
    final text = ofl.readAsStringSync();
    expect(text, contains('SIL Open Font License'));
    expect(text, contains('Poppins Project Authors'));
  });

  test('runtime fetching is off, which is what makes the guarantee', () {
    // Bundling alone does not prevent a fetch: a weight the bundle happened to
    // miss would still go to the network. This line is the guarantee.
    expect(
      File('lib/main.dart').readAsStringSync(),
      contains('GoogleFonts.config.allowRuntimeFetching = false'),
      reason:
          'without this the app may still reach fonts.gstatic.com, and the '
          'privacy label answers in docs/M-50 are wrong again',
    );
    expect(
      GoogleFonts.config.allowRuntimeFetching,
      isTrue,
      reason:
          'a sanity check on the default — the package ships with fetching '
          'ON, which is why main.dart has to turn it off. If this ever '
          'fails, the default changed and the comment in main.dart should '
          'say so',
    );
  });

  testWidgets('and the typography still asks for Poppins', (tester) async {
    // The call sites did not change, and this is what proves that was safe:
    // GoogleFonts.poppins() resolves against the bundle.
    late TextStyle style;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            style = AppTypography.pageTitle;
            return Text('Building Permit', style: style);
          },
        ),
      ),
    );
    expect(style.fontFamily, contains('Poppins'));
    expect(style.fontWeight, FontWeight.w800);
  });
}
