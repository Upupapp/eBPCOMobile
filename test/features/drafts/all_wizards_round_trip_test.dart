import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:ebpco_user_app/core/drafts/draft_persistence_barrel.dart';
import 'package:ebpco_user_app/core/drafts/addition_extension_permit_draft_codec.dart';
import 'package:ebpco_user_app/core/drafts/architectural_permit_draft_codec.dart';
import 'package:ebpco_user_app/core/drafts/building_permit_draft_codec.dart';
import 'package:ebpco_user_app/core/drafts/certificate_of_occupancy_draft_codec.dart';
import 'package:ebpco_user_app/core/drafts/civil_structural_permit_draft_codec.dart';
import 'package:ebpco_user_app/core/drafts/demolition_permit_draft_codec.dart';
import 'package:ebpco_user_app/core/drafts/electrical_permit_draft_codec.dart';
import 'package:ebpco_user_app/core/drafts/electronics_permit_draft_codec.dart';
import 'package:ebpco_user_app/core/drafts/excavation_permit_draft_codec.dart';
import 'package:ebpco_user_app/core/drafts/fencing_permit_draft_codec.dart';
import 'package:ebpco_user_app/core/drafts/fsec_permit_draft_codec.dart';
import 'package:ebpco_user_app/core/drafts/fsic_permit_draft_codec.dart';
import 'package:ebpco_user_app/core/drafts/interior_permit_draft_codec.dart';
import 'package:ebpco_user_app/core/drafts/mechanical_permit_draft_codec.dart';
import 'package:ebpco_user_app/core/drafts/plumbing_permit_draft_codec.dart';
import 'package:ebpco_user_app/core/drafts/renovation_permit_draft_codec.dart';
import 'package:ebpco_user_app/core/drafts/sanitary_permit_draft_codec.dart';
import 'package:ebpco_user_app/core/drafts/sign_permit_draft_codec.dart';
import 'package:ebpco_user_app/core/drafts/zoning_permit_draft_codec.dart';
import 'package:ebpco_user_app/core/models/addition_extension_permit_model.dart';
import 'package:ebpco_user_app/core/models/architectural_permit_model.dart';
import 'package:ebpco_user_app/core/models/building_permit_model.dart';
import 'package:ebpco_user_app/core/models/certificate_of_occupancy_model.dart';
import 'package:ebpco_user_app/core/models/civil_structural_permit_model.dart';
import 'package:ebpco_user_app/core/models/demolition_permit_model.dart';
import 'package:ebpco_user_app/core/models/electrical_permit_model.dart';
import 'package:ebpco_user_app/core/models/electronics_permit_model.dart';
import 'package:ebpco_user_app/core/models/excavation_permit_model.dart';
import 'package:ebpco_user_app/core/models/fencing_permit_model.dart';
import 'package:ebpco_user_app/core/models/fsec_permit_model.dart';
import 'package:ebpco_user_app/core/models/fsic_permit_model.dart';
import 'package:ebpco_user_app/core/models/interior_design_permit_model.dart';
import 'package:ebpco_user_app/core/models/mechanical_permit_model.dart';
import 'package:ebpco_user_app/core/models/plumbing_permit_model.dart';
import 'package:ebpco_user_app/core/models/renovation_permit_model.dart';
import 'package:ebpco_user_app/core/models/sanitary_plumbing_permit_model.dart';
import 'package:ebpco_user_app/core/models/sign_permit_model.dart';
import 'package:ebpco_user_app/core/models/zoning_permit_model.dart';

/// Every wizard's draft, round-tripped through a real encode and decode.
///
/// The completeness gate reads source: it proves each field is NAMED in the
/// codec. This one runs the codec. A path can be present in both directions
/// and still lose its value — a capture writing under one key and a restore
/// reading another, a value that does not survive JSON, a restore assigning
/// the wrong field. None of that is visible to a source scan; all of it is
/// visible here.
///
/// **How it works.** Capture a blank draft to learn the shape, read the codec
/// source to learn which accessor each path uses, mutate accordingly, encode
/// through JSON, apply to a FRESH draft, capture again, compare.
///
/// **What it does not cover, stated plainly.** Enum and collection fields: a
/// blank draft cannot tell this test what other values an enum has, and
/// inventing one would only prove the codec rejects nonsense. Those are
/// asserted by the source gate and by the concrete per-wizard tests in
/// `draft_round_trip_test.dart` and `draft_collections_test.dart`.

typedef _Wizard = ({
  DraftCodec<dynamic> codec,
  Object Function() blank,
  String source,
});

const List<_Wizard> _wizards = [
  (
    codec: AdditionExtensionPermitDraftCodec(),
    blank: AdditionExtensionPermitDraft.new,
    source: 'lib/core/drafts/addition_extension_permit_draft_codec.dart',
  ),
  (
    codec: ArchitecturalPermitDraftCodec(),
    blank: ArchitecturalPermitDraft.new,
    source: 'lib/core/drafts/architectural_permit_draft_codec.dart',
  ),
  (
    codec: BuildingPermitDraftCodec(),
    blank: BuildingPermitDraft.new,
    source: 'lib/core/drafts/building_permit_draft_codec.dart',
  ),
  (
    codec: CertificateOfOccupancyDraftCodec(),
    blank: CertificateOfOccupancyDraft.new,
    source: 'lib/core/drafts/certificate_of_occupancy_draft_codec.dart',
  ),
  (
    codec: CivilStructuralPermitDraftCodec(),
    blank: CivilStructuralPermitDraft.new,
    source: 'lib/core/drafts/civil_structural_permit_draft_codec.dart',
  ),
  (
    codec: DemolitionPermitDraftCodec(),
    blank: DemolitionPermitDraft.new,
    source: 'lib/core/drafts/demolition_permit_draft_codec.dart',
  ),
  (
    codec: ElectricalPermitDraftCodec(),
    blank: ElectricalPermitDraft.new,
    source: 'lib/core/drafts/electrical_permit_draft_codec.dart',
  ),
  (
    codec: ElectronicsPermitDraftCodec(),
    blank: ElectronicsPermitDraft.new,
    source: 'lib/core/drafts/electronics_permit_draft_codec.dart',
  ),
  (
    codec: ExcavationPermitDraftCodec(),
    blank: ExcavationPermitDraft.new,
    source: 'lib/core/drafts/excavation_permit_draft_codec.dart',
  ),
  (
    codec: FencingPermitDraftCodec(),
    blank: FencingPermitDraft.new,
    source: 'lib/core/drafts/fencing_permit_draft_codec.dart',
  ),
  (
    codec: FsecPermitDraftCodec(),
    blank: FsecPermitDraft.new,
    source: 'lib/core/drafts/fsec_permit_draft_codec.dart',
  ),
  (
    codec: FsicPermitDraftCodec(),
    blank: FsicPermitDraft.new,
    source: 'lib/core/drafts/fsic_permit_draft_codec.dart',
  ),
  (
    codec: InteriorPermitDraftCodec(),
    blank: InteriorPermitDraft.new,
    source: 'lib/core/drafts/interior_permit_draft_codec.dart',
  ),
  (
    codec: MechanicalPermitDraftCodec(),
    blank: MechanicalPermitDraft.new,
    source: 'lib/core/drafts/mechanical_permit_draft_codec.dart',
  ),
  (
    codec: PlumbingPermitDraftCodec(),
    blank: PlumbingPermitDraft.new,
    source: 'lib/core/drafts/plumbing_permit_draft_codec.dart',
  ),
  (
    codec: RenovationPermitDraftCodec(),
    blank: RenovationPermitDraft.new,
    source: 'lib/core/drafts/renovation_permit_draft_codec.dart',
  ),
  (
    codec: SanitaryPermitDraftCodec(),
    blank: SanitaryPermitDraft.new,
    source: 'lib/core/drafts/sanitary_permit_draft_codec.dart',
  ),
  (
    codec: SignPermitDraftCodec(),
    blank: SignPermitDraft.new,
    source: 'lib/core/drafts/sign_permit_draft_codec.dart',
  ),
  (
    codec: ZoningPermitDraftCodec(),
    blank: ZoningPermitDraft.new,
    source: 'lib/core/drafts/zoning_permit_draft_codec.dart',
  ),
];

/// Which writer method each path was captured with, read from the codec.
Map<String, String> _accessors(String path) {
  final source = File(path).readAsStringSync();
  final start = source.indexOf('void capture(');
  final end = source.indexOf('void restore(');
  return {
    for (final match in RegExp(
      r"out\s*\.\s*(\w+)\(\s*'([^']+)'",
    ).allMatches(source.substring(start, end)))
      match.group(2)!: match.group(1)!,
  };
}

DraftSnapshot _snapshot(String key, Map<String, Object?> fields) =>
    DraftSnapshot(
      permitKey: key,
      step: 3,
      savedAt: DateTime(2026, 8, 30),
      fields: fields,
    );

/// Through JSON, because that is what the keychain holds. A value that does
/// not serialise fails here rather than on a device.
DraftSnapshot _throughJson(DraftSnapshot snapshot) => DraftSnapshot.fromJson(
  jsonDecode(jsonEncode(snapshot.toJson())) as Map<String, Object?>,
);

void main() {
  test('all nineteen wizards are covered', () {
    expect(_wizards, hasLength(19));
    expect(
      _wizards.map((w) => w.codec.permitKey).toSet(),
      hasLength(19),
      reason:
          'two wizards sharing a storage key would each overwrite the '
          "other's draft, and the applicant would see one of them vanish",
    );
  });

  for (final wizard in _wizards) {
    group(wizard.codec.permitKey, () {
      Map<String, Object?> capture(Object draft) {
        final writer = SnapshotWriter();
        (wizard.codec as dynamic).capture(draft, writer);
        return writer.fields;
      }

      Map<String, Object?> restoreAndRecapture(Map<String, Object?> fields) {
        final draft = wizard.blank();
        (wizard.codec as dynamic).apply(
          draft,
          _throughJson(_snapshot(wizard.codec.permitKey, fields)),
        );
        return capture(draft);
      }

      test('the accessor scan found this codec', () {
        // Every assertion below is driven by it; an empty map would make them
        // all pass against nothing.
        expect(_accessors(wizard.source), isNotEmpty);
      });

      test('every scalar and date survives a full round trip', () {
        final blank = capture(wizard.blank());
        final accessors = _accessors(wizard.source);
        final mutated = <String, Object?>{};
        for (final entry in blank.entries) {
          final how = accessors[entry.key];
          if (how == 'date') {
            mutated[entry.key] = '2026-10-01T09:30:00.000';
          } else if (how == 'scalar') {
            final value = entry.value;
            if (value is String) mutated[entry.key] = 'v:${entry.key}';
            if (value is bool) mutated[entry.key] = !value;
          }
        }
        expect(
          mutated,
          isNotEmpty,
          reason: 'nothing was exercised — the scan matched no scalars',
        );

        final after = restoreAndRecapture({...blank, ...mutated});
        final lost = [
          for (final entry in mutated.entries)
            if (after[entry.key] != entry.value) entry.key,
        ];
        expect(
          lost,
          isEmpty,
          reason:
              'these were written and did not come back — the applicant '
              'retypes them after being told their progress was saved: $lost',
        );
      });

      test('a nullable scalar is either kept or cleanly refused', () {
        // A null in a blank capture is a String?, an int?, a double? or a
        // bool?, and nothing in the snapshot says which. Writing text into it
        // must either round-trip or come back null; anything else means
        // something reinterpreted the value.
        final blank = capture(wizard.blank());
        final accessors = _accessors(wizard.source);
        const probe = 'v:probe';
        final probed = [
          for (final entry in blank.entries)
            if (entry.value == null && accessors[entry.key] == 'scalar')
              entry.key,
        ];
        if (probed.isEmpty) return;

        final after = restoreAndRecapture({
          ...blank,
          for (final key in probed) key: probe,
        });
        for (final key in probed) {
          expect(
            after[key] == probe || after[key] == null,
            isTrue,
            reason: '$key came back as "${after[key]}"',
          );
        }
      });

      test('a blank draft asks for no attachments back', () {
        // The re-attach prompt must be driven by files the applicant actually
        // picked. A codec passing a non-null placeholder to out.document would
        // tell every applicant to re-attach documents they never had.
        final writer = SnapshotWriter();
        (wizard.codec as dynamic).capture(wizard.blank(), writer);
        expect(writer.detachedDocuments, isEmpty);
      });

      test('an empty snapshot restores without throwing', () {
        // What a draft written by an older release can look like. Losing the
        // typing is the accepted cost; crashing on launch is not.
        expect(
          () => (wizard.codec as dynamic).apply(
            wizard.blank(),
            _snapshot(wizard.codec.permitKey, const {}),
          ),
          returnsNormally,
        );
      });

      test('a snapshot full of nonsense restores without throwing', () {
        expect(
          () => (wizard.codec as dynamic).apply(
            wizard.blank(),
            _snapshot(wizard.codec.permitKey, {
              for (final key in capture(wizard.blank()).keys)
                key: 'not what this field holds',
            }),
          ),
          returnsNormally,
        );
      });
    });
  }
}
