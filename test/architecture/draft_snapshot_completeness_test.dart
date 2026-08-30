import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Every field a persisted draft declares is either written to the snapshot
/// and read back from it, or exempted here with a reason.
///
/// **Why this gate exists before the seventeen remaining wizards, not after.**
/// M-48 means hand-writing a capture and a restore for 2,624 typed fields
/// across 236 classes. Every one of them is a chance to silently drop a field,
/// and that is not a hypothetical defect class in this repository — it is the
/// one the read-path gate was built for after `application_dto.dart` was found
/// dropping a document's whole review layer, an assessment's payments, a
/// payment state, a notification's payload and ten of fourteen profile fields.
/// A dropped field here is worse than a dropped field there: the applicant
/// retypes it, having been told their progress was saved.
///
/// So the seventeen are gated before they are written. A wizard added to
/// [_wizards] must be complete on the day it is added.
///
/// **What it cannot see**, stated plainly because a source scan that oversells
/// itself is worse than none: it reads text, not types. A field reached
/// through a getter, or captured by a helper this file cannot expand, reads as
/// dropped — which is why exemptions exist and why each carries a reason
/// rather than a name alone.

/// The wizards that persist. Two of nineteen; see `docs/MANUAL-TASKS.md`.
const _wizards = [
  (
    model: 'lib/core/models/building_permit_model.dart',
    codec: 'lib/core/drafts/building_permit_draft_codec.dart',
    root: 'BuildingPermitDraft',
  ),
  (
    model: 'lib/core/models/fencing_permit_model.dart',
    codec: 'lib/core/drafts/fencing_permit_draft_codec.dart',
    root: 'FencingPermitDraft',
  ),
];

/// Paths a codec is right not to persist. A path exempts its whole subtree.
const Map<String, String> _exemptFromCapture = {
  'notarialAcknowledgment':
      'The paper form\'s notarial block. Office-controlled and never exposed '
      'as applicant-editable UI, so every field is unset in every draft this '
      'app can produce — persisting them would store nothing, forever.',
  'processingInfo':
      'Boxes 7-8: review stage, assessed fees, official receipt, issuance. '
      'Office-controlled, filled by a staff surface that does not exist yet, '
      'and read-only to the applicant. A draft never holds a value here.',
};

/// Paths that are captured but deliberately not read back.
const Map<String, String> _exemptFromRestore = {
  'status':
      'A restored draft is always a draft. Only submitApplication() may set '
      'submitted, and honouring a stored value would resurrect an already '
      'filed application as editable. Asserted in draft_round_trip_test.',
};

/// The body of `class <name>`, bounded by the next top-level declaration.
String? _classBody(String source, String name) {
  final start = RegExp(
    r'^(?:abstract\s+)?class\s+' + name + r'\b',
    multiLine: true,
  ).firstMatch(source);
  if (start == null) return null;
  final next = RegExp(r'^(?:abstract\s+)?(?:class|enum)\s+\w+', multiLine: true)
      .allMatches(source)
      .map((m) => m.start)
      .firstWhere((s) => s > start.start, orElse: () => source.length);
  return source.substring(start.start, next);
}

/// Instance fields declared directly on a class, as (type, name).
///
/// Getters, statics and methods are excluded: a getter is derived from fields
/// that are themselves captured, so persisting one would store the same value
/// twice and let the two disagree after a restore.
List<(String, String)> _fields(String body) {
  final fields = <(String, String)>[];
  for (final line in body.split('\n')) {
    if (!line.startsWith('  ') || line.startsWith('   ')) continue;
    if (line.contains(' get ') || line.contains('static')) continue;
    final match = RegExp(
      r'^  (?:final\s+)?([A-Za-z_][\w<>?, ]*?)\s+([a-z_]\w*)\s*(?:=|;)',
    ).firstMatch(line);
    if (match == null) continue;
    final type = match.group(1)!.trim();
    if (type == 'void' || type == 'return') continue;
    fields.add((type, match.group(2)!));
  }
  return fields;
}

/// Every path a snapshot of [root] must contain, and whether it is a document.
///
/// Walks the draft's object graph rather than listing leaf names, so a
/// `street` on the applicant's address and a `street` on the construction
/// location are two different paths. Matching on leaf names alone would let
/// one stand in for the other — the same shape of vacuity that made an earlier
/// gate in this repository pass against an empty slice.
Map<String, bool> _expectedPaths(String source, String root) {
  final paths = <String, bool>{};

  void walk(String className, String prefix, List<String> seen) {
    if (seen.contains(className)) return; // a self-referential model, one deep
    final body = _classBody(source, className);
    if (body == null) return;
    for (final (type, name) in _fields(body)) {
      final path = prefix.isEmpty ? name : '$prefix.$name';
      final bare = type.replaceAll('?', '').trim();
      if (bare == 'DocumentModel') {
        paths[path] = true;
      } else if (_classBody(source, bare) != null) {
        walk(bare, path, [...seen, className]);
      } else {
        paths[path] = false;
      }
    }
  }

  walk(root, '', const []);
  return paths;
}

/// The paths a codec's `capture`/`restore` actually touch.
///
/// Expands the two shared helpers. `_captureProfessional('professionals.
/// supervisor', ...)` writes `'$prefix.fullName'`, and without expansion every
/// field of both professionals and both consent parties would read as dropped
/// — which would push a correct codec into needing eighteen false exemptions,
/// and false exemptions are how a gate stops meaning anything.
Set<String> _touchedPaths(String codec, {required bool capturing}) {
  final accessor = capturing ? 'out' : 'input';
  final helperPrefix = capturing ? '_capture' : '_restore';

  final bodies = <String, String>{};
  final starts = RegExp(
    r'^  (?:@override\n  )?(?:void|[\w<>]+) (\w+)\(',
    multiLine: true,
  ).allMatches(codec).toList();
  for (var i = 0; i < starts.length; i++) {
    final end = i + 1 < starts.length ? starts[i + 1].start : codec.length;
    bodies[starts[i].group(1)!] = codec.substring(starts[i].start, end);
  }

  String literalsOf(String body) => body;
  final entry = bodies[capturing ? 'capture' : 'restore'];
  expect(entry, isNotNull, reason: 'no ${capturing ? 'capture' : 'restore'}()');

  Set<String> pathsIn(String body) => RegExp(
    accessor + r"\.\w+\(\s*'([^']+)'",
  ).allMatches(body).map((m) => m.group(1)!).toSet();

  final touched = pathsIn(literalsOf(entry!));

  // Expand each helper invocation against the leaves that helper writes.
  for (final call in RegExp(
    helperPrefix + r"(\w+)\(\s*'([^']+)'",
  ).allMatches(entry)) {
    final body = bodies['$helperPrefix${call.group(1)}'];
    if (body == null) continue;
    for (final leaf in pathsIn(body)) {
      if (!leaf.startsWith(r'$prefix.')) continue;
      touched.add('${call.group(2)}.${leaf.substring(8)}');
    }
  }
  return touched;
}

bool _exempt(Map<String, String> exemptions, String path) => exemptions.keys.any(
  (key) => path == key || path.startsWith('$key.'),
);

void main() {
  test('the parse is not vacuous', () {
    // Every assertion below passes trivially against an empty expectation set.
    // This is the guard against that, with figures measured on 30 August 2026.
    final building = _expectedPaths(
      File(_wizards.first.model).readAsStringSync(),
      'BuildingPermitDraft',
    );
    expect(building.length, greaterThan(70));
    expect(
      building.values.where((isDocument) => isDocument).length,
      24,
      reason:
          'the Building Permit carries 24 attachment slots. If this changed, '
          'the re-attach list an applicant is shown changed with it',
    );
    expect(building['applicant.firstName'], isFalse);
    expect(building['requiredDocuments.landTitleUpload'], isTrue);
    expect(
      building.keys.where((p) => p.endsWith('.street')).length,
      2,
      reason:
          'the applicant\'s street and the construction location\'s — two '
          'different paths sharing one leaf name, which is the case a '
          'leaf-name match would collapse. (Written as 3 first, and this '
          'guard is what caught it.)',
    );
  });

  for (final wizard in _wizards) {
    group(wizard.root, () {
      final model = File(wizard.model).readAsStringSync();
      final codec = File(wizard.codec).readAsStringSync();
      final expected = _expectedPaths(model, wizard.root);

      test('every field is captured, or exempted with a reason', () {
        final captured = _touchedPaths(codec, capturing: true);
        final dropped = [
          for (final path in expected.keys)
            if (!captured.contains(path) &&
                !_exempt(_exemptFromCapture, path))
              path,
        ];
        expect(
          dropped,
          isEmpty,
          reason:
              'these fields are declared on the draft and never written to '
              'the snapshot, so an applicant retypes them after being told '
              'their progress was saved: $dropped',
        );
      });

      test('every field is read back, except the documents', () {
        final restored = _touchedPaths(codec, capturing: false);
        final dropped = [
          for (final entry in expected.entries)
            if (!entry.value &&
                !restored.contains(entry.key) &&
                !_exempt(_exemptFromCapture, entry.key) &&
                !_exempt(_exemptFromRestore, entry.key))
              entry.key,
        ];
        expect(
          dropped,
          isEmpty,
          reason:
              'these are saved and never read back — the worst of the three '
              'outcomes, because the data is on disk and still lost: $dropped',
        );
      });

      test('no document is restored', () {
        // The whole design rests on this. A path into a picked file is not
        // reliably readable after a restart, and a draft that claims to hold a
        // document it cannot open is a worse failure than one that asks.
        final restored = _touchedPaths(codec, capturing: false);
        final documents = expected.entries
            .where((e) => e.value)
            .map((e) => e.key)
            .where(restored.contains)
            .toList();
        expect(documents, isEmpty);
      });

      test('every document is named for the applicant to re-attach', () {
        final captured = _touchedPaths(codec, capturing: true);
        final missing = [
          for (final entry in expected.entries)
            if (entry.value &&
                !captured.contains(entry.key) &&
                !_exempt(_exemptFromCapture, entry.key))
              entry.key,
        ];
        expect(
          missing,
          isEmpty,
          reason:
              'a document slot not passed to out.document() is dropped '
              'SILENTLY — the applicant is not told to re-attach it: $missing',
        );
      });

      test('the codec invents no path the draft does not declare', () {
        // The other direction. A path with a typo writes a key nothing ever
        // reads, and the field it was meant for reads as captured.
        final captured = _touchedPaths(codec, capturing: true)
          ..removeWhere((p) => p.startsWith(r'$prefix.'));
        expect(
          captured.difference(expected.keys.toSet()),
          isEmpty,
          reason: 'captured under a path no field declares',
        );
      });
    });
  }

  group('the exemptions themselves', () {
    test('each names a path that exists', () {
      final all = <String>{};
      for (final wizard in _wizards) {
        all.addAll(
          _expectedPaths(
            File(wizard.model).readAsStringSync(),
            wizard.root,
          ).keys,
        );
      }
      for (final key in [..._exemptFromCapture.keys, ..._exemptFromRestore.keys]) {
        expect(
          all.any((path) => path == key || path.startsWith('$key.')),
          isTrue,
          reason:
              '"$key" exempts nothing — the field was renamed or removed and '
              'the exemption now silently covers a live field instead',
        );
      }
    });

    test('each carries a real reason', () {
      for (final entry in [
        ..._exemptFromCapture.entries,
        ..._exemptFromRestore.entries,
      ]) {
        expect(
          entry.value.length,
          greaterThanOrEqualTo(40),
          reason: '${entry.key}: a name is not a reason',
        );
      }
    });
  });
}
