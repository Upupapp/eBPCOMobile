import 'package:flutter/foundation.dart';

import '../models/draft_summary.dart';
import '../models/renovation_permit_model.dart';

/// Holds the single in-progress Renovation Permit application draft for
/// the current app session (frontend-only: nothing here is persisted to
/// disk or a server). Mirrors [BuildingPermitProvider]'s shape exactly,
/// but is a fully separate provider/class so Renovation and New
/// Construction drafts can never overwrite one another.
class RenovationPermitProvider extends ChangeNotifier implements DraftSource {
  RenovationPermitDraft? _draft;
  int _currentStep = 0;

  RenovationPermitDraft? get draft => _draft;
  int get currentStep => _currentStep;

  /// Whether there is an unsubmitted draft the wizard can resume into.
  bool get hasResumableDraft =>
      _draft != null && _draft!.status == RenovationPermitDraftStatus.draft;

  /// Returns the resumable draft if one exists, otherwise starts a fresh
  /// one (replacing any already-submitted draft from a prior session run).
  RenovationPermitDraft resumeOrStart() {
    if (hasResumableDraft) return _draft!;
    return startNew();
  }

  /// Does not call `notifyListeners()`: this is invoked from the wizard
  /// screen's own `initState()` (via [resumeOrStart]) when it first
  /// mounts, and Flutter forbids notifying an already-built ancestor
  /// `Provider` while a new route is still in the middle of its initial
  /// build. Nothing currently watches this provider — the wizard manages
  /// its own rebuilds via local `setState` — so no listener is missed.
  RenovationPermitDraft startNew() {
    final draft = RenovationPermitDraft();
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
    draft.status = RenovationPermitDraftStatus.draft;
    draft.lastSavedAt = DateTime.now();
    notifyListeners();
  }

  /// Marks the current draft as submitted (Step 9 → Application
  /// Submitted). The draft stays in memory so the confirmation screen can
  /// still read it, but [hasResumableDraft] will report false since its
  /// status is no longer `draft`, so reopening the wizard starts a fresh
  /// application.
  void submitApplication() {
    final draft = _draft;
    if (draft == null) return;
    draft.status = RenovationPermitDraftStatus.submitted;
    notifyListeners();
  }

  void discardDraft() {
    _draft = null;
    _currentStep = 0;
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
      permitTypeLabel: 'Renovation',
      lastSavedAt: draft.lastSavedAt,
      completedSteps: (draft.isStep1Valid ? 1 : 0) +
      (draft.isStep2Valid ? 1 : 0) +
      (draft.isStep3Valid ? 1 : 0) +
      (draft.isStep4Valid ? 1 : 0) +
      (draft.isStep5Valid ? 1 : 0) +
      (draft.isStep6Valid ? 1 : 0) +
      (draft.isStep7Valid ? 1 : 0) +
      (draft.isStep8Valid ? 1 : 0) +
      (draft.isStep9Valid ? 1 : 0),
      totalSteps: 9,
      route: '/applications/new/renovation-permit',
    );
  }
}
