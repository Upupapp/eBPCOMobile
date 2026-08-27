import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// `ResponsiveCardGrid` was written because `GridView`'s fixed cell sizing
/// overflows: `childAspectRatio` and `mainAxisExtent` both pin every cell to a
/// height derived from one phone at one font size, and content that needs a
/// few more pixels has nowhere to go. Its own doc comment records the
/// dashboard overflows that prompted it.
///
/// The applications screen then used a raw `GridView(mainAxisExtent: 214)`
/// anyway and overflowed by 8px at 320dp — the shared fix existed for two
/// screens and only one of them had it. This keeps the next one from being
/// written.
///
/// Scrolling grids of unknown length are a legitimate use of `GridView`; what
/// is not legitimate is pinning cell height. So the check is on the fixed
/// extent, not on `GridView` itself.
void main() {
  test('no feature grid pins its cell height', () {
    final offenders = <String>[];

    for (final file
        in Directory('lib/features')
            .listSync(recursive: true)
            .whereType<File>()
            .where((f) => f.path.endsWith('.dart'))) {
      final lines = file.readAsStringSync().split('\n');
      for (var i = 0; i < lines.length; i++) {
        if (RegExp(
          r'\b(mainAxisExtent|childAspectRatio):',
        ).hasMatch(lines[i])) {
          offenders.add('${file.path}:${i + 1}  ${lines[i].trim()}');
        }
      }
    }

    expect(
      offenders,
      isEmpty,
      reason:
          'Use ResponsiveCardGrid, which takes each row\'s height from its '
          'tallest card, instead of pinning cell height. Found at:\n  '
          '${offenders.join('\n  ')}',
    );
  });
}
