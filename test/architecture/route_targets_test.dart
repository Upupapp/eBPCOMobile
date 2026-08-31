import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Every place the app navigates to must be a route it declares.
///
/// The same defect class as the sign-out allow-list that misspelled its key:
/// **one part of the code writes a string and another matches it**, and
/// nothing connects the two. There it cost a returning applicant the whole
/// introduction; here it would cost them the screen they were sent to.
///
/// This app has already been bitten by the family. The Home action stack
/// promises "3 items must be corrected" and routes somewhere; if that route
/// were misspelled the applicant would land nowhere, and the only evidence
/// would be an applicant who could not act on their own application.
///
/// Measured 31 August 2026: 80 navigation targets, 77 declared routes, no
/// mismatch.

/// Dart concatenates adjacent string literals, and the charter route is
/// written that way — `'/charter/'` on one line and the interpolation on the
/// next. A scanner that misses that reports a false positive, which is how
/// this check first "found" a defect that was not one.
String _joinAdjacentLiterals(String source) =>
    source.replaceAll(RegExp(r"'\s*\n\s*'"), '');

/// A path with every parameter and interpolation reduced to one placeholder,
/// so `/applications/:applicationId` and `/applications/${a.id}` compare
/// equal.
String _shape(String path) => path
    // Query strings are not part of the path go_router matches. The
    // pre-flight route carries two encoded parameters, and treating them as
    // path segments was this check's second false positive.
    .replaceAll(RegExp(r'\?.*$'), '')
    .replaceAll(RegExp(r'\$\{[^}]*\}'), ':x')
    .replaceAll(RegExp(r'\$[A-Za-z_][A-Za-z0-9_]*'), ':x')
    .replaceAll(RegExp(r':[A-Za-z_][A-Za-z0-9_]*'), ':x')
    .replaceAll(RegExp(r'/+$'), '');

void main() {
  final router = _joinAdjacentLiterals(
    File('lib/routes/app_router.dart').readAsStringSync(),
  );

  final declared = RegExp(
    r"path: '([^']+)'",
  ).allMatches(router).map((m) => m.group(1)!).toList();

  final navigations = <String, String>{};
  for (final entity in Directory('lib').listSync(recursive: true)) {
    if (entity is! File || !entity.path.endsWith('.dart')) continue;
    final source = _joinAdjacentLiterals(entity.readAsStringSync());
    for (final match in RegExp(
      r"(?:context\.(?:push|go|pushReplacement)|route:\s*)\(?\s*'([^']+)'",
    ).allMatches(source)) {
      navigations.putIfAbsent(match.group(1)!, () => entity.path);
    }
  }

  test('the scan finds routes and navigations at all', () {
    // Both sides are read from source; a rename on either would otherwise
    // make the comparison below pass against nothing.
    expect(
      declared.length,
      greaterThan(60),
      reason: 'app_router.dart declares far fewer paths than expected',
    );
    expect(
      navigations.length,
      greaterThan(50),
      reason: 'almost no navigation calls found — the pattern stopped matching',
    );
  });

  test('every navigation target is a declared route', () {
    final shapes = declared.map(_shape).toSet();
    final missing = <String, String>{};
    navigations.forEach((path, file) {
      if (!shapes.contains(_shape(path))) missing[path] = file;
    });

    expect(
      missing,
      isEmpty,
      reason:
          'these send an applicant to a route the router does not declare, '
          'which lands them nowhere: $missing',
    );
  });

  test('and no two routes are declared twice', () {
    // A duplicate path is a route whose second declaration never runs — the
    // builder that gets used is whichever go_router matches first, which is
    // not necessarily the one being edited.
    final seen = <String>{};
    final duplicates = declared.where((p) => !seen.add(p)).toList();
    expect(duplicates, isEmpty, reason: 'declared more than once: $duplicates');
  });
}
