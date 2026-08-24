import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Nineteen async provider methods call `notifyListeners()` after an `await`,
/// and none of them check whether the provider has been disposed first.
///
/// That is safe today for one reason only: every provider in this app is
/// created once in `app.dart`, at the root of the tree, so none is disposed
/// until the app itself goes away. A `notifyListeners()` landing after
/// disposal cannot happen if disposal only happens at teardown.
///
/// The moment a provider is created inside a route or a screen instead, that
/// stops being true — the applicant navigates away mid-load, the provider is
/// disposed, the repository answers, and `ChangeNotifier` throws on a disposed
/// instance. The nineteen sites become live defects at once, and nothing else
/// in the codebase would say so.
///
/// So the invariant the safety argument rests on is asserted rather than
/// assumed. If this fails, either move the provider back to the root or give
/// the affected notifiers a disposed guard.
void main() {
  test('providers are created only at the root, in app.dart', () {
    final offenders = <String>[];

    for (final file in Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))) {
      if (file.path.endsWith('lib/app.dart')) continue;

      final lines = file.readAsStringSync().split('\n');
      for (var i = 0; i < lines.length; i++) {
        if (RegExp(r'\bChangeNotifierProvider(\.value)?\s*[(<]').hasMatch(lines[i])) {
          offenders.add('${file.path}:${i + 1}');
        }
      }
    }

    expect(
      offenders,
      isEmpty,
      reason:
          'A provider created outside app.dart can be disposed while an async '
          'load is still running, which makes the unguarded notifyListeners() '
          'calls reachable. Found at:\n  ${offenders.join('\n  ')}',
    );
  });
}
