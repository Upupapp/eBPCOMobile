import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ebpco_user_app/core/models/draft_summary.dart';
import 'package:ebpco_user_app/core/providers/building_permit_provider.dart';
import 'package:ebpco_user_app/core/providers/fencing_permit_provider.dart';
import 'package:ebpco_user_app/core/providers/zoning_permit_provider.dart';

/// What an applicant actually keeps when the app is killed mid-filing.
///
/// Nineteen wizards each offer **Save as Draft**, nineteen providers implement
/// [DraftSource], the Applications tab has a **Drafts** segment listing them,
/// and the Before-you-start card tells the applicant *"You can save your
/// progress as a draft."*
///
/// **Nothing is written to disk.** Every draft lives in a `ChangeNotifier` and
/// dies with the process. Only `AuthProvider` persists anything at all.
///
/// These tests exist to hold that as a measured fact rather than an assumption,
/// and to fail the day persistence is added — at which point the copy this
/// programme corrected can be put back.

/// A process restart, as far as the app is concerned: the providers are gone
/// and rebuilt from nothing. There is no store to rehydrate from, which is the
/// whole point.
BuildingPermitProvider _afterRestart() => BuildingPermitProvider();

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('a saved draft does not survive a restart', () {
    final before = BuildingPermitProvider();
    before.startNew();
    before.saveAsDraft();

    expect(
      before.hasResumableDraft,
      isTrue,
      reason: 'the draft exists in this session',
    );
    expect(before.draftSummary, isNotNull);

    // The applicant force-quits, or the OS reclaims the app.
    final after = _afterRestart();

    expect(
      after.hasResumableDraft,
      isFalse,
      reason:
          'if this now passes, drafts persist — update the Before-you-start '
          'copy, which was narrowed because they did not',
    );
    expect(after.draftSummary, isNull);
  });

  test('the Drafts list is empty after a restart, however much was typed', () {
    // Not one wizard: the segment is assembled from all nineteen, so a restart
    // empties the list rather than losing one row.
    final zoning = ZoningPermitProvider()..startNew();
    final fencing = FencingPermitProvider()..startNew();
    zoning.saveAsDraft();
    fencing.saveAsDraft();

    expect([zoning.draftSummary, fencing.draftSummary].nonNulls, hasLength(2));

    final summaries = <DraftSummary?>[
      ZoningPermitProvider().draftSummary,
      FencingPermitProvider().draftSummary,
    ].nonNulls;

    expect(summaries, isEmpty);
  });

  test('"Last saved" is a within-session timestamp, not a durable one', () {
    // The Drafts row shows it, which reads as a promise that something was
    // written somewhere. It was not.
    final provider = FencingPermitProvider()..startNew();
    provider.saveAsDraft();

    expect(provider.draft!.lastSavedAt, isNotNull);
    expect(FencingPermitProvider().draft, isNull);
  });

  test('no wizard provider writes to any store', () {
    // Scanned rather than asserted from a list I typed, because a list I typed
    // would go on saying "no persistence" the day someone adds it. If this
    // fails, persistence has arrived: revisit the Before-you-start copy, the
    // pending register, and the two tests above.
    final offenders = <String>[];
    for (final entity in Directory('lib/core/providers').listSync()) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      if (entity.path.endsWith('auth_provider.dart')) continue; // the session
      final source = entity.readAsStringSync();
      for (final store in const [
        'SharedPreferences',
        'LocalStorageService',
        'FlutterSecureStorage',
        'SecureQueueStore',
      ]) {
        if (source.contains(store)) {
          offenders.add('${entity.path.split('/').last} → $store');
        }
      }
    }

    expect(
      offenders,
      isEmpty,
      reason:
          'a provider now persists something: $offenders. If it is a wizard '
          'draft, the app can finally keep the promise it makes on the '
          'Before-you-start card.',
    );
  });
}
