import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ebpco_user_app/core/drafts/draft_persistence_barrel.dart';
import 'package:ebpco_user_app/core/providers/building_permit_provider.dart';
import 'package:ebpco_user_app/core/providers/fencing_permit_provider.dart';
import 'package:ebpco_user_app/core/providers/mechanical_permit_provider.dart';
import 'package:ebpco_user_app/core/providers/zoning_permit_provider.dart';

/// What an applicant actually keeps when the app is killed mid-filing.
///
/// **This file has said three different things, and each was true when
/// written.** On 29 August it proved that nineteen wizards offered *Save as
/// Draft* and nothing reached disk — every draft lived in a `ChangeNotifier`
/// and died with the process — which is how M-48 was raised and why the
/// applicant-facing copy was narrowed. On 30 August it recorded two wizards
/// converted and seventeen not. It now records the finished state: **all
/// nineteen persist.**
///
/// Kept rather than deleted because the boundary is the thing worth stating,
/// and because a wizard added later starts out on the wrong side of it. The
/// round trip itself is proven in `test/features/drafts/`.

/// A provider constructed the way every widget test constructs one: no store.
///
/// It matters that this still behaves as it did before M-48, because that is
/// what leaves the rest of the suite untouched by the change.
BuildingPermitProvider _withoutAStore() => BuildingPermitProvider();

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('every wizard provider is converted, counted from source', () {
    // Scanned rather than listed by hand: a hand-written list would go on
    // claiming nineteen the day a twentieth wizard was added without a codec.
    final converted = <String>[];
    final all = <String>[];
    for (final entity in Directory('lib/core/providers').listSync()) {
      if (entity is! File) continue;
      final name = entity.path.split('/').last;
      final source = entity.readAsStringSync();
      if (!source.contains('implements DraftSource')) continue;
      all.add(name);
      if (source.contains('with PersistentDraft')) converted.add(name);
    }

    expect(all, hasLength(19), reason: 'nineteen wizards expose a draft');
    expect(
      all.toSet().difference(converted.toSet()),
      isEmpty,
      reason:
          'a wizard exposes a draft to the Drafts list and does not persist '
          'it. The applicant is now told drafts survive closing the app, so '
          'this one would lie to them — give it a codec, or take it out of '
          'DraftRegistry',
    );
  });

  test('every wizard is wired to the store in the running app', () {
    // Converting a provider is half of it. A provider built with no
    // persistence is silently in-memory, and the failure would be invisible
    // until an applicant lost a draft.
    // Whitespace-normalised: dart format wraps `X _x = X(persistence:
    // _drafts);` across three lines, and a raw `contains` would then find
    // nothing and report every provider as unwired — a false alarm that
    // teaches people to widen the test rather than fix the code.
    final app = File(
      'lib/app.dart',
    ).readAsStringSync().replaceAll(RegExp(r'\s+'), ' ');
    for (final entity in Directory('lib/core/providers').listSync()) {
      if (entity is! File) continue;
      if (!entity.readAsStringSync().contains('with PersistentDraft')) continue;
      final cls = RegExp(
        r'class (\w+) extends ChangeNotifier',
      ).firstMatch(entity.readAsStringSync())!.group(1)!;
      expect(
        app,
        matches(
          RegExp(
            '$cls'
            r'\( ?persistence: _drafts,? ?\)',
          ),
        ),
        reason: '$cls is persistable and the app builds it without a store',
      );
      expect(
        app,
        contains('ChangeNotifierProvider<$cls>.value'),
        reason:
            '$cls is built eagerly but handed to the tree through a `create` '
            'callback, which would construct a SECOND one — two providers '
            'over one keychain key, each overwriting the other',
      );
    }
  });

  test('the app starts a restore for every wizard it builds', () {
    final app = File(
      'lib/app.dart',
    ).readAsStringSync().replaceAll(RegExp(r'\s+'), ' ');
    final built = RegExp(
      r'late final (\w+) (_\w+) = \1\( ?persistence: _drafts,? ?\);',
    ).allMatches(app).map((m) => m.group(2)!).toList();
    expect(built, hasLength(19));
    for (final field in built) {
      expect(
        app,
        contains('$field.restoreFromStore();'),
        reason:
            '$field is built with a store and never asked to read it, so its '
            'draft would sit on disk and never come back',
      );
    }
  });

  group('with no store, a draft still dies with the process', () {
    test('nothing is written', () async {
      final before = _withoutAStore()..startNew();
      before.saveAsDraft();
      await before.pendingWrite;

      expect(_withoutAStore().hasResumableDraft, isFalse);
      expect(before.documentsToReattach, isEmpty);
    });

    test('the Drafts list is empty', () {
      final zoning = ZoningPermitProvider()..startNew();
      zoning.saveAsDraft();
      expect(zoning.draftSummary, isNotNull);
      expect(ZoningPermitProvider().draftSummary, isNull);
    });
  });

  group('with a store, the draft outlives the provider', () {
    test('for the wizard an applicant is most likely to file', () async {
      final persistence = DraftPersistence(InMemoryDraftStore());
      final before = BuildingPermitProvider(persistence: persistence);
      before.startNew().applicant.firstName = 'Maria';
      before.saveAsDraft();
      await before.pendingWrite;

      final after = BuildingPermitProvider(persistence: persistence);
      expect(await after.restoreFromStore(), isTrue);
      expect(after.draft!.applicant.firstName, 'Maria');
      expect(after.draftSummary, isNotNull);
    });

    test('and for the largest one, which was the last converted', () async {
      final persistence = DraftPersistence(InMemoryDraftStore());
      final before = MechanicalPermitProvider(persistence: persistence);
      before.startNew().applicant.firstName = 'Engr. Santos';
      before.goToStep(6);
      before.saveAsDraft();
      await before.pendingWrite;

      final after = MechanicalPermitProvider(persistence: persistence);
      expect(await after.restoreFromStore(), isTrue);
      expect(after.draft!.applicant.firstName, 'Engr. Santos');
      expect(after.currentStep, 6);
    });

    test('"Last saved" is now a durable timestamp', () async {
      // The Drafts row shows it, which reads as a promise that something was
      // written somewhere. It now was.
      final persistence = DraftPersistence(InMemoryDraftStore());
      final before = FencingPermitProvider(persistence: persistence)
        ..startNew();
      before.saveAsDraft();
      await before.pendingWrite;
      final saved = before.draft!.lastSavedAt;
      expect(saved, isNotNull);

      final after = FencingPermitProvider(persistence: persistence);
      await after.restoreFromStore();
      expect(after.draft!.lastSavedAt, saved);
    });

    test('nineteen drafts coexist, none overwriting another', () async {
      // They share one keychain record. Two saves racing over one map is how
      // the second silently erases the first.
      final persistence = DraftPersistence(InMemoryDraftStore());
      final zoning = ZoningPermitProvider(persistence: persistence);
      final mechanical = MechanicalPermitProvider(persistence: persistence);
      final building = BuildingPermitProvider(persistence: persistence);
      zoning.startNew().applicant.firstName = 'Zoning';
      mechanical.startNew().applicant.firstName = 'Mechanical';
      building.startNew().applicant.firstName = 'Building';
      zoning.saveAsDraft();
      mechanical.saveAsDraft();
      building.saveAsDraft();
      await Future.wait([
        zoning.pendingWrite,
        mechanical.pendingWrite,
        building.pendingWrite,
      ]);

      final z = ZoningPermitProvider(persistence: persistence);
      final m = MechanicalPermitProvider(persistence: persistence);
      final b = BuildingPermitProvider(persistence: persistence);
      await Future.wait([
        z.restoreFromStore(),
        m.restoreFromStore(),
        b.restoreFromStore(),
      ]);
      expect(z.draft!.applicant.firstName, 'Zoning');
      expect(m.draft!.applicant.firstName, 'Mechanical');
      expect(b.draft!.applicant.firstName, 'Building');
    });
  });
}
