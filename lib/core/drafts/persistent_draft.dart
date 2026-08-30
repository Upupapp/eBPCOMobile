import 'package:flutter/foundation.dart';

import 'draft_persistence_barrel.dart';

/// Gives a wizard provider a draft that survives a restart.
///
/// Mixed in rather than copied, because the remaining seventeen wizards are
/// meant to be repetition: a provider supplies its codec, says which draft is
/// resumable, and says how to install a restored one. Everything about
/// ordering, races and detached documents is decided once, here.
///
/// **Persistence is optional.** [persistence] is null in every widget test
/// that builds a provider directly, and in that state a provider behaves
/// exactly as it did before M-48 — in memory, dying with the process. That is
/// what keeps the seventeen unconverted wizards and hundreds of existing tests
/// unaffected by this change.
mixin PersistentDraft<T> on ChangeNotifier {
  /// Null when this provider is running without a store.
  DraftPersistence? get persistence;

  DraftCodec<T> get codec;

  /// The draft worth saving, or null when there is nothing resumable — a
  /// just-submitted application is not a draft.
  T? get resumableDraft;

  /// Installs a blank draft as the current one and returns it, so the codec
  /// can fill it. The provider owns its own fields; this mixin does not reach
  /// into them.
  T beginRestoredDraft();

  /// Moves the wizard to the step the applicant had reached.
  void seekRestoredStep(int step);

  List<String> _detached = const [];

  /// The documents that were attached when this draft was last saved, by
  /// name, and are no longer held. Empty except immediately after a restore.
  ///
  /// The applicant is shown this rather than left to discover it: a restored
  /// draft that silently forgot eleven attachments would be a worse failure
  /// than the one M-48 set out to fix.
  List<String> get documentsToReattach => _detached;

  Future<void> _write = Future.value();

  /// Completes when the last [persistDraft] has reached the store. Tests await
  /// it; nothing in the app does, because a save must never block a tap.
  Future<void> get pendingWrite => _write;

  /// Writes the current draft. Silent when there is no store or no draft.
  ///
  /// Fire-and-forget by design. A keychain write is fast but not instant, and
  /// "Save as Draft" is a button an applicant taps and immediately navigates
  /// away from.
  void persistDraft(int step) {
    final store = persistence;
    final draft = resumableDraft;
    if (store == null || draft == null) return;
    _write = store.write(codec.snapshot(draft, step: step));
  }

  /// Rehydrates a stored draft into this provider.
  ///
  /// Returns false, having changed nothing, when there is no store, nothing
  /// stored, or — the case worth stating — when a draft is already in memory.
  /// The applicant can reach a wizard before a keychain read finishes, and
  /// overwriting what they have just typed with what they typed last week is
  /// the one outcome worse than not restoring at all.
  Future<bool> restoreFromStore() async {
    final store = persistence;
    if (store == null || resumableDraft != null) return false;

    final snapshot = await store.read(codec.permitKey);
    if (snapshot == null) return false;
    // Typed while the keychain read was in flight.
    if (resumableDraft != null) {
      return false;
    }

    final reader = SnapshotReader(snapshot.fields);
    codec.restore(beginRestoredDraft(), reader);
    seekRestoredStep(snapshot.step);
    // Two different losses, and the applicant needs both. `detachedDocuments`
    // is what could not be KEPT when the draft was saved — a file outside the
    // app's own storage. `unresolvedDocuments` is what could not be GIVEN BACK
    // now — a file that has since been cleared, or a container path from
    // before an app update. Neither list subsumes the other.
    _detached = List.unmodifiable({
      ...snapshot.detachedDocuments,
      ...reader.unresolvedDocuments,
    });
    notifyListeners();
    return true;
  }

  /// Drops the stored copy. Called when the applicant discards a draft and
  /// when an application is submitted — a filed application is not an
  /// unfinished one, and leaving it on disk would resurrect it as editable on
  /// the next launch.
  Future<void> forgetPersistedDraft() {
    _detached = const [];
    final store = persistence;
    if (store == null) return Future.value();
    return _write = store.remove(codec.permitKey);
  }

  /// Clears the re-attach prompt once the applicant has seen it.
  void acknowledgeDetachedDocuments() {
    if (_detached.isEmpty) return;
    _detached = const [];
    notifyListeners();
  }
}
