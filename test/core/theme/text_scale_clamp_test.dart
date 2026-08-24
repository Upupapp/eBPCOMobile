import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ebpco_user_app/core/theme/text_scale_clamp.dart';

/// One line decides how much of the app's text-scale work reaches a user, and
/// it had no test — it was a literal inside a builder in `app.dart`, so it
/// could have been changed, or quietly drifted away from what the
/// accessibility suites render at, without anything failing.

double _effective(WidgetTester tester) {
  final context = tester.element(find.byKey(const Key('probe')));
  return MediaQuery.textScalerOf(context).scale(1.0);
}

Future<void> _pump(WidgetTester tester, double systemScale) async {
  await tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(textScaler: TextScaler.linear(systemScale)),
      child: const TextScaleClamp(
        child: SizedBox(key: Key('probe')),
      ),
    ),
  );
}

void main() {
  test('the ceiling matches what the accessibility suites assert at', () {
    // Those suites render every screen at 2.0. If this ever exceeds that, the
    // app is promising a scale nothing has been checked at.
    expect(TextScaleClamp.maxScale, 2.0);
  });

  testWidgets('passes ordinary scales through untouched', (tester) async {
    await _pump(tester, 1.0);
    expect(_effective(tester), 1.0);

    await _pump(tester, 1.5);
    expect(_effective(tester), 1.5);
  });

  testWidgets('allows the full 2.0 a user may have asked for', (tester) async {
    // The regression this guards is the old 1.3 cap, which silently gave
    // someone who set 200% only 130%.
    await _pump(tester, 2.0);
    expect(_effective(tester), 2.0);
  });

  testWidgets('holds the line above the ceiling', (tester) async {
    await _pump(tester, 3.5);
    expect(_effective(tester), TextScaleClamp.maxScale);
  });

  testWidgets('will not let text shrink below legibility', (tester) async {
    await _pump(tester, 0.5);
    expect(_effective(tester), TextScaleClamp.minScale);
  });
}
