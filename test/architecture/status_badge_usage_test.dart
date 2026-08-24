import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// A status pill hand-rolled beside an `Expanded` title is the single defect
/// this codebase has repeated most: five screens had written their own
/// `Container` + pill radius + `Text` instead of using `StatusBadge`, and
/// every one of them put it in a `Row` as an unbounded sibling of an
/// `Expanded`.
///
/// That shape always overflows eventually. `Row` lays the unbounded child out
/// first at its natural width and gives `Expanded` whatever is left, so a long
/// status label, a narrow phone, or a large text scale takes the space the
/// title needed. `StatusBadge` inside a `Flexible` is the form that survives,
/// and it carries the `Semantics(label: 'Status: …')` that every hand-rolled
/// copy was missing.
///
/// Scanning the source is blunt, but the alternative is a widget test per
/// screen at every viewport, and the four that existed did not catch these —
/// they only fail when a fixture happens to be long enough.
void main() {
  test('no screen hand-rolls a status pill beside an Expanded', () {
    final offenders = <String>[];

    for (final file in Directory('lib/features')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))) {
      final source = file.readAsStringSync();

      // Each `Row(` and the block that follows it, bounded so a match cannot
      // run away into an unrelated part of the file.
      for (final match in RegExp(
        r'Row\((.{0,1200}?)\n\s*\],',
        dotAll: true,
      ).allMatches(source)) {
        final body = match.group(1)!;
        final isPill = body.contains('borderRadiusPill');
        final crowdsATitle = body.contains('Expanded(');
        final usesSharedWidget = body.contains('StatusBadge');

        if (isPill && crowdsATitle && !usesSharedWidget) {
          final line = '\n'.allMatches(source.substring(0, match.start)).length + 1;
          offenders.add('${file.path}:$line');
        }
      }
    }

    expect(
      offenders,
      isEmpty,
      reason:
          'Use StatusBadge inside a Flexible instead of building the pill by '
          'hand. Found at:\n  ${offenders.join('\n  ')}',
    );
  });
}
