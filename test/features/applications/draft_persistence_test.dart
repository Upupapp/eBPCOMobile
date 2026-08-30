import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ebpco_user_app/core/drafts/draft_persistence_barrel.dart';
import 'package:ebpco_user_app/core/models/draft_summary.dart';
import 'package:ebpco_user_app/core/providers/building_permit_provider.dart';
import 'package:ebpco_user_app/core/providers/fencing_permit_provider.dart';
import 'package:ebpco_user_app/core/providers/zoning_permit_provider.dart';

/// What an applicant actually keeps when the app is killed mid-filing.
///
/// **This file used to prove the opposite.** Nineteen wizards offered *Save as
/// Draft*, the Applications tab listed drafts with a "Last saved" time, and
/// nothing reached disk: every draft lived in a `ChangeNotifier` and died with
/// the process. That was measured here, the applicant-facing copy was narrowed
/// to match, and M-48 was raised.
///
/// **Two of the nineteen now persist** — Building Permit and Fencing, through
/// `lib/core/drafts/`. Seventeen do not. The file is rewritten rather than
/// deleted because the honest statement of a half-finished migration is worth
/// more than either half alone, and because the copy may only change when the
/// count does.
///
/// The round trip itself is proven in `test/features/drafts/`; this states the
/// boundary.

/// A provider constructed the way every widget test constructs one: no store.
///
/// The seventeen unconverted wizards have no other mode. It matters that this
/// mode still behaves exactly as it did before M-48, because that is what
/// leaves the rest of the suite untouched by the change.
BuildingPermitProvider _withoutAStore() => BuildingPermitProvider();

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('the seventeen that do not persist', () {
    test('a saved draft still dies with the process', () {
      final before = ZoningPermitProvider()..startNew();
      before.saveAsDraft();
      expect(before.draftSummary, isNotNull);

      // The applicant force-quits, or the OS reclaims the app.
      expect(
        ZoningPermitProvider().draftSummary,
        isNull,
        reason:
            'if this now fails, Zoning has been converted — move it out of '
            'this group and into the round-trip suite',
      );
    });

    test('exactly which wizards are converted, counted from source', () {
      // Scanned rather than listed by hand, because a hand-written list would
      // go on claiming "two of nineteen" the day the third landed — and the
      // applicant-facing copy is gated on this count.
      final converted = <String>[];
      final all = <String>[];
      for (final entity in Directory('lib/core/providers').listSync()) {
        if (entity is! File) continue;
        if (!entity.path.endsWith('_permit_provider.dart') &&
            !entity.path.endsWith('certificate_of_occupancy_provider.dart')) {
          continue;
        }
        final name = entity.path.split('/').last;
        all.add(name);
        if (entity.readAsStringSync().contains('with PersistentDraft')) {
          converted.add(name);
        }
      }

      expect(all, hasLength(19), reason: 'nineteen wizards');
      expect(converted..sort(), [
        'building_permit_provider.dart',
        'fencing_permit_provider.dart',
      ]);
    });

    test('the Drafts list still empties for an unconverted wizard', () {
      final zoning = ZoningPermitProvider()..startNew();
      zoning.saveAsDraft();
      expect(<DraftSummary?>[zoning.draftSummary].nonNulls, hasLength(1));
      expect(<DraftSummary?>[ZoningPermitProvider().draftSummary].nonNulls, isEmpty);
    });
  });

  group('the two that do', () {
    test('nothing is written when there is no store', () async {
      // Every widget test in this repository builds providers this way. If
      // persistence ever became mandatory, hundreds of them would start
      // touching a keychain that does not exist under `flutter test`.
      final before = _withoutAStore()..startNew();
      before.saveAsDraft();
      await before.pendingWrite;

      expect(_withoutAStore().hasResumableDraft, isFalse);
      expect(before.documentsToReattach, isEmpty);
    });

    test('with a store, the draft outlives the provider', () async {
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

    test('"Last saved" is now a durable timestamp for these two', () async {
      // The Drafts row shows it, which reads as a promise that something was
      // written somewhere. For Building Permit and Fencing, it now was.
      final persistence = DraftPersistence(InMemoryDraftStore());
      final before = FencingPermitProvider(persistence: persistence)..startNew();
      before.saveAsDraft();
      await before.pendingWrite;
      final saved = before.draft!.lastSavedAt;
      expect(saved, isNotNull);

      final after = FencingPermitProvider(persistence: persistence);
      await after.restoreFromStore();
      expect(after.draft!.lastSavedAt, saved);
    });
  });

  test('the narrowed copy stands while any wizard is unconverted', () {
    // The copy was narrowed to "only while the app stays open" because that
    // was true of all nineteen. It is now true of seventeen, which is still
    // the sentence an applicant must be shown — a promise that holds for two
    // wizards out of nineteen is not a promise.
    final card = File(
      'lib/features/applications/presentation/widgets/'
      'before_you_start_card.dart',
    ).readAsStringSync();
    expect(
      card.contains('only while the app stays open'),
      isTrue,
      reason:
          'the caveat was removed. It may only go when every wizard persists '
          '— check the converted count in this file first',
    );
  });
}
