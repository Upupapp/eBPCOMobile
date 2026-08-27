import 'package:flutter/foundation.dart';

import '../models/draft_summary.dart';
import '../models/fsec_permit_model.dart';

/// Holds the single in-progress FSEC draft for the
/// current app session (frontend-only: nothing here is persisted to disk or a
/// server). Mirrors the other permit providers' shape exactly, but is a fully
/// separate provider so this draft can never be overwritten by, or overwrite,
/// any other permit's draft.
class FsecPermitProvider extends ChangeNotifier implements DraftSource {
  FsecPermitDraft? _draft;
  int _currentStep = 0;

  FsecPermitDraft? get draft => _draft;
  int get currentStep => _currentStep;

  /// Whether there is an unsubmitted draft the wizard can resume into.
  bool get hasResumableDraft =>
      _draft != null && _draft!.status == FSECPermitDraftStatus.draft;

  /// Returns the resumable draft if one exists, otherwise starts a fresh one
  /// (replacing any already-submitted draft from a prior session run).
  FsecPermitDraft resumeOrStart() {
    if (hasResumableDraft) return _draft!;
    return startNew();
  }

  /// Does not call `notifyListeners()`: this is invoked from the wizard
  /// screen's own `initState()` when it first mounts, and Flutter forbids
  /// notifying an already-built ancestor `Provider` while a new route is still
  /// in the middle of its initial build.
  FsecPermitDraft startNew() {
    final draft = FsecPermitDraft();
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
    draft.status = FSECPermitDraftStatus.draft;
    draft.lastSavedAt = DateTime.now();
    notifyListeners();
  }

  /// Marks the current draft as submitted. The draft stays in memory so the
  /// confirmation screen can still read it, but [hasResumableDraft] reports
  /// false afterwards, so reopening the wizard starts a fresh application.
  void submitApplication() {
    final draft = _draft;
    if (draft == null) return;
    draft.status = FSECPermitDraftStatus.submitted;
    notifyListeners();
  }

  void discardDraft() {
    _draft = null;
    _currentStep = 0;
    notifyListeners();
  }

  /// What this wizard's unfinished draft looks like from outside.
  ///
  /// The label is the admin's own name for this permit. Unlike the OBO
  /// permits it keeps the "(BFP)" suffix, because which office issues it is
  /// the thing an applicant most needs to know about it.
  @override
  DraftSummary? get draftSummary {
    final draft = _draft;
    if (draft == null || !hasResumableDraft) return null;
    return DraftSummary(
      permitTypeLabel: 'FSEC for Building Permit (BFP)',
      lastSavedAt: draft.lastSavedAt,
      completedSteps: draft.completedSteps,
      totalSteps: 4,
      route: '/applications/new/fsec-clearance',
    );
  }
}
