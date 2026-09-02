import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:ebpco_user_app/core/contract/admin_vocabulary.dart';

/// The permit names, compared **code point by code point**.
///
/// Prompted by the citizen web portal lane, who gated the same strings against
/// the server's keys byte-exactly and passed on the reason: *"a wrong dash is
/// invisible in review."*
///
/// It is. Three of the nineteen names contain **U+2013 EN DASH**, and a
/// hyphen-minus substituted for one is indistinguishable at a glance, survives
/// code review, and fails at the wire — where the office is told the LGU does
/// not issue that permit. Dart's `==` already compares code points; what was
/// missing is a test that *says so when it differs*, rather than printing two
/// strings that look identical.
///
/// Four names contain a **forward slash**, which is a different hazard: it is
/// a path separator, so a name pushed into a route without encoding splits
/// into segments and matches nothing.

String _codePoints(String s) => s.runes
    .map((r) => 'U+${r.toRadixString(16).toUpperCase().padLeft(4, '0')}')
    .join(' ');

void main() {
  final fixture =
      jsonDecode(File('test/contract/admin-vocabulary.json').readAsStringSync())
          as Map<String, dynamic>;

  List<String> adminNames() {
    List<String>? found;
    void walk(dynamic node) {
      if (found != null) return;
      if (node is Map) {
        for (final entry in node.entries) {
          if (entry.key == 'permitTypes' && entry.value is List) {
            found = (entry.value as List).cast<String>();
            return;
          }
          walk(entry.value);
        }
      }
    }

    walk(fixture);
    return found!;
  }

  test('the scan reads a real vocabulary', () {
    expect(adminNames(), hasLength(19));
  });

  test('every name matches the admin fixture code point for code point', () {
    // The comparison Dart already makes. What this adds is the FAILURE: when
    // two strings differ by one invisible character, the message has to show
    // which, or the next person spends an afternoon on it.
    final admin = adminNames();
    final app = CanonicalPermitType.values.map((t) => t.wire).toList();

    expect(app, hasLength(admin.length));
    for (var i = 0; i < admin.length; i++) {
      expect(
        app[i],
        admin[i],
        reason:
            'permit name $i differs from the admin portal.\n'
            '  app:   ${_codePoints(app[i])}\n'
            '  admin: ${_codePoints(admin[i])}',
      );
    }
  });

  test('the three en-dashed names still carry U+2013, not a hyphen', () {
    // The substitution a find-and-replace, an editor's autocorrect or a
    // copy-paste through a plain-text field makes silently.
    final dashed = CanonicalPermitType.values
        .map((t) => t.wire)
        .where((n) => n.contains('–'))
        .toList();

    expect(
      dashed,
      hasLength(3),
      reason:
          'three Building Permit names use an EN DASH. If this is not three, '
          'one has been replaced with a hyphen-minus and the server will '
          'refuse it: ${CanonicalPermitType.values.map((t) => t.wire).where((n) => n.contains('-')).toList()}',
    );
    for (final name in dashed) {
      expect(
        name.contains('-'),
        isFalse,
        reason: 'both a hyphen and an en dash in "$name" — one is a typo',
      );
    }
  });

  test('the four slashed names are pushed into routes encoded', () {
    // A forward slash is a PATH SEPARATOR. `/charter/Civil / Structural
    // Permit` is three segments, matches no route, and the citizen lands on
    // the not-found screen with no idea why — for four of nineteen permits.
    final slashed = CanonicalPermitType.values
        .map((t) => t.wire)
        .where((n) => n.contains('/'))
        .toList();
    expect(slashed, hasLength(4));

    final offenders = <String>[];
    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final source = entity.readAsStringSync();
      for (final match in RegExp(
        r"'/(?:charter|forms)/\$\{([^}]*)\}",
      ).allMatches(source)) {
        if (!match.group(1)!.contains('Uri.encode')) {
          offenders.add('${entity.path}: ${match.group(0)}');
        }
      }
    }
    expect(
      offenders,
      isEmpty,
      reason:
          'these push a permit name into a path without encoding it, so the '
          'four names containing a slash will match no route: $offenders',
    );
  });

  test('the two literal tables in that file agree', () {
    // `wire` and `canonicalPermitTypeFromWire` are TWO independent lists of
    // the same nineteen strings — one to emit, one to parse. Correct a dash in
    // one and not the other and the app files under the fixed name while
    // refusing to read it back, throwing UnknownWireValue on the office's own
    // response.
    //
    // The round trip is the only check that sees both tables at once.
    for (final type in CanonicalPermitType.values) {
      expect(
        canonicalPermitTypeFromWire(type.wire),
        type,
        reason:
            'the emit and parse tables disagree for $type.\n'
            '  wire emits: ${_codePoints(type.wire)}',
      );
    }
  });

  test('and encoding actually makes them safe', () {
    // Asserted rather than assumed: %2F for the slash, and the en dash
    // percent-encoded rather than passed through.
    expect(Uri.encodeComponent('Civil / Structural Permit'), contains('%2F'));
    expect(
      Uri.encodeComponent('Building Permit – New Construction'),
      contains('%E2%80%93'),
    );
  });
}
