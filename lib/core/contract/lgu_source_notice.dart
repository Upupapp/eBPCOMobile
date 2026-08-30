import 'requirements_catalog.dart';

/// What the app is allowed to claim about where its LGU-specific facts came
/// from.
///
/// **The defect this exists to close.** The requirements catalogue records, per
/// permit type, whether an entry was built from an actual Castilla or BFP form
/// (`verified`) or from a national-law baseline. Fifteen of the nineteen are
/// **not** verified. `RequirementSource` even says so in its own doc comment —
/// *"Carry this to the applicant. A requirement the LGU has not confirmed must
/// not be shown in the same voice as PD 1096."*
///
/// The pre-flight screen carried it. **The Citizen's Charter screen did not**,
/// and that is the surface where it matters most: it is titled with the name
/// of a statutory document the LGU is required to publish, and it lists which
/// offices are involved, what to bring, and *where to secure each item*. An
/// applicant makes trips on the strength of that column. Presenting a national
/// compilation under the LGU's own masthead, with no note, is the same defect
/// as the fabricated support address — see [OfficeContact] — and larger,
/// because it costs the applicant a journey rather than an email.
///
/// One notice, used by every surface that shows this data, so two screens
/// cannot disagree about it. This repository has twice corrected one surface
/// and missed its sibling.
class LguSourceNotice {
  const LguSourceNotice._();

  /// Whether this permit's requirements were built from Castilla's own form.
  ///
  /// Delegates to the requirements catalogue rather than holding a second
  /// opinion: the catalogue already made this judgement per permit type, and
  /// two answers to one question is how they drift apart.
  static bool isConfirmedForPermit(String permitTypeLabel) =>
      requirementsForLabel(permitTypeLabel)?.verified ?? false;

  /// Shown wherever an unconfirmed permit's requirements appear.
  ///
  /// Deliberately concrete about the consequence — "before securing anything
  /// costly" — because "this information may be inaccurate" tells an applicant
  /// nothing they can act on.
  static const String unconfirmedRequirements =
      'These requirements follow national practice and are still being '
      'confirmed against the LGU’s own form. Check with the office before '
      'securing anything costly.';

  /// Shown on the Citizen's Charter screen, always.
  ///
  /// Not conditional on [isConfirmedForPermit]: even the four permits built
  /// from a genuine Castilla form have no *charter* entry sourced from
  /// Castilla's published charter. The offices, the where-to-secure column and
  /// the fee basis are a national compilation for every one of the nineteen.
  /// That is M-08, and until it is closed this sentence is the difference
  /// between a helpful guide and a false claim of authority.
  static const String charterProvenance =
      'This is compiled from national practice under RA 11032 and PD 1096. '
      'The Municipality of Castilla’s own published Citizen’s Charter has not '
      'been supplied to this app, so treat the offices and the “where to '
      'secure” notes as a guide and confirm them with the office.';

  /// The one part of the charter that IS national law, and may be stated
  /// plainly: RA 11032's 3 / 7 / 20 working-day ceilings.
  static const String pledgeIsStatutory =
      'Maximum processing time under RA 11032, counted from the day the office '
      'receives a complete application.';
}
