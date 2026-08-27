import 'package:flutter/foundation.dart';

import '../models/draft_summary.dart';
import '../models/zoning_permit_model.dart';

/// Holds the single in-progress Zoning / Locational Clearance draft for the
/// current app session (frontend-only: nothing here is persisted to disk or a
/// server). Mirrors the other permit providers' shape exactly, but is a fully
/// separate provider so this draft can never be overwritten by, or overwrite,
/// any other permit's draft.
class ZoningPermitProvider extends ChangeNotifier implements DraftSource {
  ZoningPermitDraft? _draft;
  int _currentStep = 0;

  ZoningPermitDraft? get draft => _draft;
  int get currentStep => _currentStep;

  /// Whether there is an unsubmitted draft the wizard can resume into.
  bool get hasResumableDraft =>
      _draft != null && _draft!.status == ZoningPermitDraftStatus.draft;

  /// Returns the resumable draft if one exists, otherwise starts a fresh one
  /// (replacing any already-submitted draft from a prior session run).
  ZoningPermitDraft resumeOrStart() {
    if (hasResumableDraft) return _draft!;
    return startNew();
  }

  /// Does not call `notifyListeners()`: this is invoked from the wizard
  /// screen's own `initState()` when it first mounts, and Flutter forbids
  /// notifying an already-built ancestor `Provider` while a new route is still
  /// in the middle of its initial build.
  ZoningPermitDraft startNew() {
    final draft = ZoningPermitDraft();
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
    draft.status = ZoningPermitDraftStatus.draft;
    draft.lastSavedAt = DateTime.now();
    notifyListeners();
  }

  /// Marks the current draft as submitted. The draft stays in memory so the
  /// confirmation screen can still read it, but [hasResumableDraft] reports
  /// false afterwards, so reopening the wizard starts a fresh application.
  void submitApplication() {
    final draft = _draft;
    if (draft == null) return;
    draft.status = ZoningPermitDraftStatus.submitted;
    notifyListeners();
  }

  void discardDraft() {
    _draft = null;
    _currentStep = 0;
    notifyListeners();
  }

  /// What this wizard's unfinished draft looks like from outside.
  ///
  /// The label is the bare permit name, matching the other fifteen — the
  /// Drafts segment lists these side by side, where an odd one out reads as a
  /// mistake.
  @override
  DraftSummary? get draftSummary {
    final draft = _draft;
    if (draft == null || !hasResumableDraft) return null;
    return DraftSummary(
      permitTypeLabel: 'Zoning / Locational Clearance',
      lastSavedAt: draft.lastSavedAt,
      completedSteps: draft.completedSteps,
      totalSteps: 5,
      route: '/applications/new/zoning-clearance',
    );
  }
}
