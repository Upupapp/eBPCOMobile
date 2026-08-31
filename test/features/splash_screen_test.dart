import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ebpco_user_app/core/constants/app_colors.dart';
import 'package:ebpco_user_app/core/constants/app_constants.dart';
import 'package:ebpco_user_app/core/providers/auth_provider.dart';
import 'package:ebpco_user_app/features/splash/presentation/splash_screen.dart';

/// The splash, and the four rules it borrows from the Servana apps.
///
/// See `ServanaWorkerAPP/docs/SPLASH_MOTION_SPEC.md`. Each rule below is one
/// that app learned by getting it wrong first, which is why they are asserted
/// here rather than left as intentions in a comment.

Widget _wrap({double textScale = 1.0, bool reduceMotion = false}) =>
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>(create: (_) => AuthProvider()),
      ],
      child: MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(
            size: const Size(390, 844),
            textScaler: TextScaler.linear(textScale),
            disableAnimations: reduceMotion,
          ),
          child: const SplashScreen(),
        ),
      ),
    );

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  _nativeHandoff();

  testWidgets('it shows the Municipality of Castilla\'s seal', (tester) async {
    await tester.pumpWidget(_wrap());
    await tester.pump(AppConstants.splashRevealDuration);

    final image = tester.widget<Image>(find.byType(Image));
    expect(
      (image.image as AssetImage).assetName,
      'assets/images/castilla-seal.png',
    );
  });

  testWidgets('the mark is present from the first frame, not popped in', (
    tester,
  ) async {
    // Rule 2's companion: the seal is always in the tree, and only its opacity
    // and scale move. A mark built into existence partway through cannot be
    // matched by the native launch screen, which has no animation at all.
    await tester.pumpWidget(_wrap());
    await tester.pump();
    expect(find.byType(Image), findsOneWidget);
  });

  testWidgets('reduced motion gets the assembled mark, not no mark', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(reduceMotion: true));
    await tester.pump();

    // Fully opaque immediately: the controller is jumped to its end rather
    // than left at zero, which would hide the seal from the users most likely
    // to need a clear one.
    final opacities = tester
        .widgetList<Opacity>(find.byType(Opacity))
        .map((o) => o.opacity)
        .toList();
    expect(opacities, isNotEmpty);
    expect(opacities.first, 1.0);
  });

  testWidgets('the status cue is invisible while startup is quick', (
    tester,
  ) async {
    // Rule 3. A start that resolves in 300ms should show a clean brand
    // moment, not a spinner flickering on and off inside a third of a second.
    // This screen used to show one unconditionally.
    await tester.pumpWidget(_wrap());
    await tester.pump(const Duration(milliseconds: 300));

    final spinner = tester.widget<Opacity>(
      find
          .ancestor(
            of: find.byType(CircularProgressIndicator),
            matching: find.byType(Opacity),
          )
          .first,
    );
    expect(spinner.opacity, 0.0);

    // And it does arrive if startup is still going late in the reveal.
    await tester.pump(AppConstants.splashRevealDuration);
    final later = tester.widget<Opacity>(
      find
          .ancestor(
            of: find.byType(CircularProgressIndicator),
            matching: find.byType(Opacity),
          )
          .first,
    );
    expect(later.opacity, greaterThan(0.0));
  });

  testWidgets('it sits on the brand ground the launch screen paints', (
    tester,
  ) async {
    // Rule 1's visual half: the native LaunchScreen.storyboard is set to the
    // same red. It was white until 31 August 2026, so every launch flashed
    // white and then red the instant Flutter drew.
    await tester.pumpWidget(_wrap());
    await tester.pump();

    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
    expect(scaffold.backgroundColor, AppColors.primary);
  });

  testWidgets('nothing overflows at 200% text scale', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(_wrap(textScale: 2.0));
    await tester.pump(AppConstants.splashRevealDuration);

    expect(tester.takeException(), isNull);
  });
}

/// The native handoff, asserted from the files that produce it.
///
/// Rule 1's other half. The Flutter splash cannot see the native launch
/// screen, and the native launch screen cannot animate — so the only way they
/// agree is if something checks that they were built to the same numbers.
void _nativeHandoff() {
  group('the native launch screen and the splash agree', () {
    test('they paint the same ground', () {
      // AppColors.primary is #C81E2C. The storyboard stores components as
      // fractions, so the check is on the bytes those fractions round to.
      final storyboard = File(
        'ios/Runner/Base.lproj/LaunchScreen.storyboard',
      ).readAsStringSync();
      final match = RegExp(
        r'<color key="backgroundColor" red="([\d.]+)" green="([\d.]+)" '
        r'blue="([\d.]+)"',
      ).firstMatch(storyboard);
      expect(
        match,
        isNotNull,
        reason: 'no background colour in the storyboard',
      );

      int byte(String s) => (double.parse(s) * 255).round();
      expect(
        [byte(match!.group(1)!), byte(match.group(2)!), byte(match.group(3)!)],
        [
          (AppColors.primary.r * 255).round(),
          (AppColors.primary.g * 255).round(),
          (AppColors.primary.b * 255).round(),
        ],
        reason:
            'the launch screen and the splash paint different grounds, so '
            'every launch flashes one colour and then the other',
      );
    });

    test('the native mark is a real image at all three scales', () {
      // It was a 1x1 transparent pixel — Flutter's default placeholder — so
      // the native window showed nothing and the mark appeared only once
      // Flutter had drawn.
      for (final entry in {
        'LaunchImage.png': 132,
        'LaunchImage@2x.png': 264,
        'LaunchImage@3x.png': 396,
      }.entries) {
        final file = File(
          'ios/Runner/Assets.xcassets/LaunchImage.imageset/${entry.key}',
        );
        expect(file.existsSync(), isTrue, reason: '${entry.key} is missing');
        final bytes = file.readAsBytesSync();
        expect(bytes.take(8).toList(), [
          0x89,
          0x50,
          0x4E,
          0x47,
          0x0D,
          0x0A,
          0x1A,
          0x0A,
        ], reason: '${entry.key} is not a PNG');
        // PNG IHDR: width and height are big-endian uint32 at bytes 16 and 20.
        int dim(int at) =>
            (bytes[at] << 24) |
            (bytes[at + 1] << 16) |
            (bytes[at + 2] << 8) |
            bytes[at + 3];
        expect(dim(16), entry.value, reason: '${entry.key} is the wrong width');
        expect(
          dim(20),
          entry.value,
          reason: '${entry.key} is the wrong height',
        );
      }
    });
  });
}
