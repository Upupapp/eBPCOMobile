import 'package:flutter/material.dart';

import '../models/building_permit_model.dart';
import 'notifications_provider.dart';

/// Holds the single in-progress Building Permit application draft for the
/// current app session (frontend-only: nothing here is persisted to disk
/// or a server). Lets the wizard resume from where the user left off if
/// they navigate away and reopen the Building Permit flow before
/// submitting.
class BuildingPermitProvider extends ChangeNotifier {
  BuildingPermitProvider({required NotificationsProvider notifications})
    : _notifications = notifications;

  final NotificationsProvider _notifications;

  BuildingPermitDraft? _draft;
  int _currentStep = 0;
  final Set<int> _completedSteps = {};

  BuildingPermitDraft? get draft => _draft;
  int get currentStep => _currentStep;
  Set<int> get completedSteps => _completedSteps;

  /// Whether there is an unsubmitted draft the wizard can resume into.
  bool get hasResumableDraft =>
      _draft != null && _draft!.status == BuildingPermitSubmissionStatus.draft;

  /// Returns the resumable draft if one exists, otherwise starts a fresh
  /// one (replacing any already-submitted draft from a prior session run).
  BuildingPermitDraft resumeOrStart({
    BuildingPermitProjectScope? projectScope,
  }) {
    if (hasResumableDraft) return _draft!;
    return startNew(projectScope: projectScope);
  }

  BuildingPermitDraft startNew({BuildingPermitProjectScope? projectScope}) {
    final draft = BuildingPermitDraft(projectScope: projectScope);
    _draft = draft;
    _currentStep = 0;
    _completedSteps.clear();
    notifyListeners();
    return draft;
  }

  void goToStep(int step) {
    if (_currentStep == step) return;
    _currentStep = step;
    notifyListeners();
  }

  void markStepCompleted(int step) {
    if (_completedSteps.add(step)) notifyListeners();
  }

  /// Triggers a rebuild for anything watching this provider after the
  /// wizard mutates draft fields directly (draft fields are written
  /// through immediately so Save as Draft never loses data).
  void touch() => notifyListeners();

  void saveAsDraft() {
    final draft = _draft;
    if (draft == null) return;
    draft.status = BuildingPermitSubmissionStatus.draft;
    draft.lastSavedAt = DateTime.now();
    notifyListeners();
  }

  /// Finalizes submission for assessment and returns the mock reference
  /// number. Does not mark the application as paid or approved — only the
  /// Office of the Building Official's mock review can do that, which this
  /// frontend-only prototype does not simulate further.
  String submitForAssessment() {
    final draft = _draft;
    if (draft == null) {
      throw StateError('No active Building Permit draft to submit.');
    }
    final now = DateTime.now();
    final reference =
        'BP-${now.year}-${now.microsecondsSinceEpoch.toString().substring(7)}';
    draft.status = BuildingPermitSubmissionStatus.submittedForAssessment;
    draft.referenceNumber = reference;
    draft.submittedDate = now;
    notifyListeners();
    _notifications.addNotification(
      title: 'Building permit application submitted',
      message:
          'Your application $reference has been submitted for assessment '
          'by the Office of the Building Official.',
      icon: Icons.check_circle_outline,
    );
    return reference;
  }

  void discardDraft() {
    _draft = null;
    _currentStep = 0;
    _completedSteps.clear();
    notifyListeners();
  }
}
