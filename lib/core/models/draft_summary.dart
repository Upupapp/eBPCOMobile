/// What every wizard can say about its unfinished draft.
///
/// The sixteen wizard providers each hold a differently-shaped draft — a
/// building permit draft and a fencing permit draft share no fields — but they
/// all answer the same three questions: which permit, when it was last
/// touched, and how far through it is. That is the whole of what anything
/// outside a wizard needs, so it is the whole of this type.
///
/// Deliberately a value object rather than a view onto the draft. Handing the
/// draft itself to a notification evaluator would let anything reach into
/// sixteen unrelated models, and the coupling would be permanent.
class DraftSummary {
  /// The permit as the applicant would name it — "New Construction".
  final String permitTypeLabel;

  /// When the applicant last saved. Null for a draft begun and never saved,
  /// which cannot be stale because it has never been anything else.
  final DateTime? lastSavedAt;

  /// Steps whose validation currently passes.
  final int completedSteps;
  final int totalSteps;

  /// Where to resume. Always a wizard route, never a tab root.
  final String route;

  /// Documents that were attached when this draft was saved and are no longer
  /// held, by name.
  ///
  /// M-48 persists a draft's typing but never its files: a `DocumentModel`
  /// points at a path the OS may have reclaimed, and a draft claiming to hold
  /// a document it cannot open is a worse failure than one that says plainly
  /// what to re-attach. Empty for the seventeen wizards that do not persist at
  /// all, and for any draft restored with nothing attached.
  final List<String> documentsToReattach;

  const DraftSummary({
    required this.permitTypeLabel,
    required this.lastSavedAt,
    required this.completedSteps,
    required this.totalSteps,
    required this.route,
    this.documentsToReattach = const [],
  });

  /// Progress as a whole percentage, for the applicant rather than for maths.
  int get percentComplete =>
      totalSteps == 0 ? 0 : ((completedSteps / totalSteps) * 100).round();

  /// Days since the applicant last touched this.
  int? daysSinceSaved(DateTime asOf) {
    final saved = lastSavedAt;
    if (saved == null) return null;
    return DateTime(asOf.year, asOf.month, asOf.day)
        .difference(DateTime(saved.year, saved.month, saved.day))
        .inDays;
  }

  /// Worth a nudge — untouched for a week or more.
  ///
  /// Seven days rather than one or two: an applicant assembling a permit
  /// application is usually waiting on a professional, a clearance, or a
  /// notary, and a draft sitting for a few days is the normal shape of the
  /// task, not neglect.
  bool isIdle(DateTime asOf) {
    final days = daysSinceSaved(asOf);
    return days != null && days >= idleAfterDays;
  }

  static const int idleAfterDays = 7;
}

/// Implemented by each wizard provider so its draft can be seen from outside
/// without exposing the draft itself.
///
/// One getter per provider. The alternative — a registry listing all sixteen
/// by hand — would need editing every time a permit is added, and would go
/// stale silently the first time someone forgot.
abstract interface class DraftSource {
  /// The current draft, or null when there is nothing resumable.
  DraftSummary? get draftSummary;
}
