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

/// Every wizard that persists. All nineteen, since M-48 part 2.
///
/// Adding a wizard here before writing its codec is the intended order: the
/// gate then fails until the codec is complete, rather than after.
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
  (
    model: 'lib/core/models/addition_extension_permit_model.dart',
    codec: 'lib/core/drafts/addition_extension_permit_draft_codec.dart',
    root: 'AdditionExtensionPermitDraft',
  ),
  (
    model: 'lib/core/models/architectural_permit_model.dart',
    codec: 'lib/core/drafts/architectural_permit_draft_codec.dart',
    root: 'ArchitecturalPermitDraft',
  ),
  (
    model: 'lib/core/models/certificate_of_occupancy_model.dart',
    codec: 'lib/core/drafts/certificate_of_occupancy_draft_codec.dart',
    root: 'CertificateOfOccupancyDraft',
  ),
  (
    model: 'lib/core/models/civil_structural_permit_model.dart',
    codec: 'lib/core/drafts/civil_structural_permit_draft_codec.dart',
    root: 'CivilStructuralPermitDraft',
  ),
  (
    model: 'lib/core/models/demolition_permit_model.dart',
    codec: 'lib/core/drafts/demolition_permit_draft_codec.dart',
    root: 'DemolitionPermitDraft',
  ),
  (
    model: 'lib/core/models/electrical_permit_model.dart',
    codec: 'lib/core/drafts/electrical_permit_draft_codec.dart',
    root: 'ElectricalPermitDraft',
  ),
  (
    model: 'lib/core/models/electronics_permit_model.dart',
    codec: 'lib/core/drafts/electronics_permit_draft_codec.dart',
    root: 'ElectronicsPermitDraft',
  ),
  (
    model: 'lib/core/models/excavation_permit_model.dart',
    codec: 'lib/core/drafts/excavation_permit_draft_codec.dart',
    root: 'ExcavationPermitDraft',
  ),
  (
    model: 'lib/core/models/fsec_permit_model.dart',
    codec: 'lib/core/drafts/fsec_permit_draft_codec.dart',
    root: 'FsecPermitDraft',
  ),
  (
    model: 'lib/core/models/fsic_permit_model.dart',
    codec: 'lib/core/drafts/fsic_permit_draft_codec.dart',
    root: 'FsicPermitDraft',
  ),
  (
    model: 'lib/core/models/interior_design_permit_model.dart',
    codec: 'lib/core/drafts/interior_permit_draft_codec.dart',
    root: 'InteriorPermitDraft',
  ),
  (
    model: 'lib/core/models/mechanical_permit_model.dart',
    codec: 'lib/core/drafts/mechanical_permit_draft_codec.dart',
    root: 'MechanicalPermitDraft',
  ),
  (
    model: 'lib/core/models/plumbing_permit_model.dart',
    codec: 'lib/core/drafts/plumbing_permit_draft_codec.dart',
    root: 'PlumbingPermitDraft',
  ),
  (
    model: 'lib/core/models/renovation_permit_model.dart',
    codec: 'lib/core/drafts/renovation_permit_draft_codec.dart',
    root: 'RenovationPermitDraft',
  ),
  (
    model: 'lib/core/models/sanitary_plumbing_permit_model.dart',
    codec: 'lib/core/drafts/sanitary_permit_draft_codec.dart',
    root: 'SanitaryPermitDraft',
  ),
  (
    model: 'lib/core/models/sign_permit_model.dart',
    codec: 'lib/core/drafts/sign_permit_draft_codec.dart',
    root: 'SignPermitDraft',
  ),
  (
    model: 'lib/core/models/zoning_permit_model.dart',
    codec: 'lib/core/drafts/zoning_permit_draft_codec.dart',
    root: 'ZoningPermitDraft',
  ),
];

const String _officeOnly =
    'Office-controlled: the paper form\'s processing and notarial blocks, '
    'filled by a staff surface that does not exist yet and read-only to the '
    'applicant. Every field is unset in every draft this app can produce, so '
    'persisting them would store nothing, forever.';

const String _fixedByTheWizard =
    'A `final` field fixed at construction — which wizard this is, not '
    'anything the applicant entered. It cannot be assigned on restore and '
    'cannot have changed since capture, so storing it would be storing a '
    'constant and reading it back would not compile.';

/// Paths a codec is right not to persist, per wizard. A path exempts its whole
/// subtree.
///
/// Keyed by wizard rather than shared, and that is not tidiness. A flat map
/// would have let `scopeOfWork` — genuinely fixed on the Addition/Extension
/// draft — silently exempt the scope of every other wizard, including the two
/// where it is the applicant's own answer.
const Map<String, Map<String, String>> _exemptFromCapture = {
  'AdditionExtensionPermitDraft': {'scopeOfWork': _fixedByTheWizard},
  'ArchitecturalPermitDraft': {'applicant.permitType': _fixedByTheWizard},
  'CivilStructuralPermitDraft': {'applicant.permitType': _fixedByTheWizard},
  'DemolitionPermitDraft': {'applicant.permitType': _fixedByTheWizard},
  'ElectricalPermitDraft': {'applicant.permitType': _fixedByTheWizard},
  'ElectronicsPermitDraft': {
    'processingInfo': _officeOnly,
    'applicant.permitType': _fixedByTheWizard,
  },
  'ExcavationPermitDraft': {'processingInfo': _officeOnly},
  'FencingPermitDraft': {
    'notarialAcknowledgment': _officeOnly,
    'processingInfo': _officeOnly,
  },
  'InteriorPermitDraft': {
    'processingInfo': _officeOnly,
    'applicant.permitType': _fixedByTheWizard,
  },
  'MechanicalPermitDraft': {'applicant.permitType': _fixedByTheWizard},
  'PlumbingPermitDraft': {'applicant.permitType': _fixedByTheWizard},
  'SanitaryPermitDraft': {'applicant.permitType': _fixedByTheWizard},
  'SignPermitDraft': {'processingInfo': _officeOnly},
};

/// Captured but deliberately not read back. Shared: `status` is the same field
/// at the root of all nineteen drafts.
const Map<String, String> _exemptFromRestore = {
  'status':
      'A restored draft is always a draft. Only submitApplication() may set '
      'submitted, and honouring a stored value would resurrect an already '
      'filed application as editable. Asserted in draft_round_trip_test.',
};

/// The body of `class <name>`, bounded by its own closing brace.
///
/// Brace-matched rather than "up to the next class", which is what this did
/// first. Several models declare top-level helper functions BETWEEN two
/// classes — `String? _nonNegativeWholeNumber(...)` in the electrical,
/// plumbing and sanitary models — and those fell inside the preceding class's
/// slice, so a `final parsed = int.tryParse(...)` local read as a declared
/// field named `parsed`. Three phantom fields, each of which would have needed
/// a phantom exemption to silence.
String? _classBody(String source, String name) {
  final start = RegExp(
    r'^(?:abstract\s+)?class\s+' + name + r'\b',
    multiLine: true,
  ).firstMatch(source);
  if (start == null) return null;
  final open = source.indexOf('{', start.start);
  if (open < 0) return null;
  var depth = 0;
  for (var i = open; i < source.length; i++) {
    if (source[i] == '{') depth++;
    if (source[i] == '}') {
      depth--;
      if (depth == 0) return source.substring(start.start, i + 1);
    }
  }
  return source.substring(start.start);
}

/// Instance fields declared directly on a class, as (type, name).
///
/// Only at brace depth 1 — a local inside a method is not a field. Getters,
/// statics and methods are excluded too: a getter is derived from fields that
/// are themselves captured, so persisting one would store the same value twice
/// and let the two disagree after a restore.
List<(String, String)> _fields(String body) {
  final fields = <(String, String)>[];
  var depth = 0;
  for (final line in body.split('\n')) {
    final wasTopLevel = depth == 1;
    for (final rune in line.runes) {
      if (rune == 0x7B) depth++;
      if (rune == 0x7D) depth--;
    }
    if (!wasTopLevel) continue;
    if (line.contains(' get ') || line.contains('static')) continue;
    final match = RegExp(
      r'^  (?:final\s+)?([A-Za-z_][\w<>?, ]*?)\s+([a-z_]\w*)\s*(?:=|;)',
    ).firstMatch(line);
    if (match == null) continue;
    final type = match.group(1)!.trim();
    if (type == 'void' || type == 'return' || type == 'final') continue;
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

  // `accessor \s* . \s*`, not `accessor .`. dart format breaks a long
  // assignment after the receiver — `= input\n    .boolean('a.very.long.path')`
  // — and the strict form stopped seeing those calls entirely. It reported
  // eleven fields across four wizards as captured-but-never-restored when
  // every one of them was restored correctly.
  Set<String> pathsIn(String body) => RegExp(
    accessor + r"\s*\.\s*\w+\(\s*'([^']+)'",
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

bool _exempt(Map<String, String> exemptions, String path) =>
    exemptions.keys.any((key) => path == key || path.startsWith('$key.'));

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
      final exempt =
          _exemptFromCapture[wizard.root] ?? const <String, String>{};

      test('every field is captured, or exempted with a reason', () {
        final captured = _touchedPaths(codec, capturing: true);
        final dropped = [
          for (final path in expected.keys)
            if (!captured.contains(path) && !_exempt(exempt, path)) path,
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
                !_exempt(exempt, entry.key) &&
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
                !_exempt(exempt, entry.key))
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
    test('each names a path that exists on the wizard it is filed under', () {
      // Filed under the wrong wizard, an exemption exempts nothing there and
      // may silently cover a live field here. Checked against the wizard's own
      // paths rather than a union of all nineteen, which would hide exactly
      // that.
      for (final wizard in _wizards) {
        final paths = _expectedPaths(
          File(wizard.model).readAsStringSync(),
          wizard.root,
        ).keys;
        for (final key in (_exemptFromCapture[wizard.root] ?? const {}).keys) {
          expect(
            paths.any((path) => path == key || path.startsWith('$key.')),
            isTrue,
            reason:
                '"$key" exempts nothing on ${wizard.root} — the field was '
                'renamed or removed, or the exemption is filed under the '
                'wrong wizard',
          );
        }
        for (final key in _exemptFromRestore.keys) {
          expect(paths, contains(key), reason: '$key on ${wizard.root}');
        }
      }
    });

    test('each carries a real reason', () {
      final reasons = <String, String>{
        for (final wizard in _exemptFromCapture.entries)
          for (final entry in wizard.value.entries)
            '${wizard.key}.${entry.key}': entry.value,
        ..._exemptFromRestore,
      };
      expect(reasons, isNotEmpty);
      for (final entry in reasons.entries) {
        expect(
          entry.value.length,
          greaterThanOrEqualTo(40),
          reason: '${entry.key}: a name is not a reason',
        );
      }
    });
  });
}
