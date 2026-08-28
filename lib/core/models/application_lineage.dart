import 'application_model.dart';

/// What an application is a continuation of.
///
/// Both lines have carried New / Renewal / Amendment as an action since the
/// first reconciliation, and the app filed all three as New — every permit
/// except the Certificate of Occupancy expires at six or twelve months, and an
/// applicant with a lapsing permit had nowhere to go but the catalog, where
/// they would file a fresh first-time application for work already approved.
///
/// The action alone is not enough. "Renewal" without saying *of what* leaves
/// the office to guess which permit is being renewed, which is the same
/// position the applicant was in. So the action and the reference travel
/// together, in one object, and the constructor will not build a renewal that
/// names no permit.
///
/// **The admin has no field for this.** `ApplicationRecord.applicationAction`
/// exists; nothing on it points at a prior application or permit. Recorded for
/// the backend lane rather than assumed — see `docs/MANUAL-TASKS.md`.
class ApplicationLineage {
  /// Renewal or amendment. A first filing has no lineage at all, so
  /// [ApplicationType.newPermit] is rejected rather than represented.
  final ApplicationType action;

  /// The application this one continues.
  final String priorApplicationId;

  /// Its human reference, for anything the applicant is shown or quotes.
  final String? priorApplicationNumber;

  /// The permit being renewed. Required on a renewal and meaningless without
  /// one: renewing an application that never became a permit is refiling, not
  /// renewing.
  final String? priorPermitNumber;

  /// The permit type, carried so a stale intent cannot be applied to a filing
  /// of some other type. See [appliesTo].
  final String permitTypeLabel;

  ApplicationLineage.renewal({
    required this.priorApplicationId,
    required String this.priorPermitNumber,
    required this.permitTypeLabel,
    this.priorApplicationNumber,
  }) : action = ApplicationType.renewal;

  ApplicationLineage.amendment({
    required this.priorApplicationId,
    required this.permitTypeLabel,
    this.priorApplicationNumber,
  }) : action = ApplicationType.amendment,
       priorPermitNumber = null;

  /// Whether this lineage belongs to a filing of [label].
  ///
  /// The intent is held across a screen transition into a wizard, and a
  /// renewal the applicant abandoned must not attach itself to whatever they
  /// file next. Matching on the permit type is the cheap half of that guard;
  /// clearing the intent is the other half.
  bool appliesTo(String? label) => label != null && label == permitTypeLabel;

  /// One line naming what this continues, for the record and the screen.
  String get description => switch (action) {
    ApplicationType.renewal => 'Renewal of permit $priorPermitNumber',
    ApplicationType.amendment =>
      'Amendment of ${priorApplicationNumber ?? 'an earlier application'}',
    ApplicationType.newPermit => '',
  };
}
