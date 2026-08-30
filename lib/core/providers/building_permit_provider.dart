import 'package:flutter/foundation.dart';

import '../models/draft_summary.dart';
import '../models/building_permit_model.dart';
import '../drafts/building_permit_draft_codec.dart';
import '../drafts/draft_persistence_barrel.dart';
import '../drafts/persistent_draft.dart';

/// Holds the single in-progress Building Permit application draft.
///
/// Lets the wizard resume from where the applicant left off — and, since
/// M-48, from where they left off in a *previous run of the app*. The typed
/// fields are written to the keychain on every Save as Draft and read back on
/// launch; the attachments are not, and are named back to the applicant to
/// re-attach. See `lib/core/drafts/` and `docs/SCOPING-M-48-draft-
/// persistence.md`.
///
/// Nothing here reaches a server. The draft becomes an application only when
/// the wizard files it.
class BuildingPermitProvider extends ChangeNotifier
    with PersistentDraft<BuildingPermitDraft>
    implements DraftSource {
  /// Null everywhere except the running app. A provider built without a store
  /// behaves exactly as it did before M-48 — in memory, dying with the
  /// process — which is what leaves every existing widget test unchanged.
  BuildingPermitProvider({this.persistence});

  @override
  final DraftPersistence? persistence;

  @override
  DraftCodec<BuildingPermitDraft> get codec => const BuildingPermitDraftCodec();

  @override
  BuildingPermitDraft? get resumableDraft => hasResumableDraft ? _draft : null;

  @override
  BuildingPermitDraft beginRestoredDraft() => startNew();

  @override
  void seekRestoredStep(int step) => _currentStep = step;

  BuildingPermitDraft? _draft;
  int _currentStep = 0;

  BuildingPermitDraft? get draft => _draft;
  int get currentStep => _currentStep;

  /// Whether there is an unsubmitted draft the wizard can resume into.
  bool get hasResumableDraft =>
      _draft != null && _draft!.status == BuildingPermitDraftStatus.draft;

  /// Returns the resumable draft if one exists, otherwise starts a fresh
  /// one (replacing any already-submitted draft from a prior session run).
  BuildingPermitDraft resumeOrStart() {
    if (hasResumableDraft) return _draft!;
    return startNew();
  }

  /// Does not call `notifyListeners()`: this is invoked from the wizard
  /// screen's own `initState()` (via [resumeOrStart]) when it first mounts,
  /// and Flutter forbids notifying an already-built ancestor `Provider`
  /// while a new route is still in the middle of its initial build. Nothing
  /// currently watches this provider — the wizard manages its own
  /// rebuilds via local `setState` — so no listener is missed.
  BuildingPermitDraft startNew() {
    final draft = BuildingPermitDraft();
    _draft = draft;
    _currentStep = 0;
    return draft;
  }

  void goToStep(int step) {
    if (_currentStep == step) return;
    _currentStep = step;
    notifyListeners();
  }

  void saveAsDraft() {
    final draft = _draft;
    if (draft == null) return;
    draft.status = BuildingPermitDraftStatus.draft;
    draft.lastSavedAt = DateTime.now();
    // The whole of M-48 for this wizard. Fire-and-forget: the applicant taps
    // Save as Draft and leaves, and a keychain write must not hold the tap.
    persistDraft(_currentStep);
    notifyListeners();
  }

  /// Marks the current draft as submitted (Step 9 → Application Submitted).
  /// The draft stays in memory so the confirmation screen can still read
  /// it, but [hasResumableDraft] will report false since its status is no
  /// longer `draft`, so reopening the wizard starts a fresh application.
  void submitApplication() {
    final draft = _draft;
    if (draft == null) return;
    draft.status = BuildingPermitDraftStatus.submitted;
    // A filed application is not an unfinished one. Leaving it on disk would
    // resurrect it as an editable draft on the next launch.
    forgetPersistedDraft();
    notifyListeners();
  }

  void discardDraft() {
    _draft = null;
    _currentStep = 0;
    forgetPersistedDraft();
    notifyListeners();
  }

  /// What this wizard's unfinished draft looks like from outside.
  ///
  /// Null when there is nothing to resume, which is also what stops a
  /// just-submitted application from being reported as an idle draft.
  @override
  DraftSummary? get draftSummary {
    final draft = _draft;
    if (draft == null || !hasResumableDraft) return null;
    return DraftSummary(
      permitTypeLabel: 'New Construction',
      lastSavedAt: draft.lastSavedAt,
      completedSteps:
          (draft.isStep1Valid ? 1 : 0) +
          (draft.isStep2Valid ? 1 : 0) +
          (draft.isStep3Valid ? 1 : 0) +
          (draft.isStep4Valid ? 1 : 0) +
          (draft.isStep5Valid ? 1 : 0) +
          (draft.isStep6Valid ? 1 : 0) +
          (draft.isStep7Valid ? 1 : 0) +
          (draft.isStep8Valid ? 1 : 0) +
          (draft.isStep9Valid ? 1 : 0),
      totalSteps: 9,
      route: '/applications/new/building-permit',
      documentsToReattach: documentsToReattach,
    );
  }
}
