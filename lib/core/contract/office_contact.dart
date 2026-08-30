/// How an applicant reaches the office, and what this app is allowed to say
/// about it.
///
/// **Every contact detail in this app used to be fabricated, and pointed at the
/// wrong province.** Measured 30 August 2026, in the three screens that print
/// them — Help & Support, the Privacy Policy and the Terms:
///
/// - `support@ebpco.gov.ph` — a `.gov.ph` domain is issued to a government
///   entity, and "ebpco" is this product's name, not an agency. Nothing in the
///   repository records the address as real.
/// - `(02) 8988-4242` — area code 02 is Metro Manila. Castilla is in Sorsogon,
///   area code 056, about 500km away.
/// - "City Hall Building, Quezon City, Metro Manila" — Quezon City was the
///   structural reference this app's requirements were modelled on (QC
///   e-Services), and its address survived into the shipping copy.
///
/// They were scaffolding. What made them a defect rather than untidiness is
/// where they are printed: the Privacy Policy names that address as the
/// channel for **exercising data privacy rights under RA 10173**. An applicant
/// whose documents were mishandled was being sent to a mailbox that does not
/// exist and a phone in the wrong region.
///
/// So this app now says only what is recorded. The office is named, the
/// municipality's own website is given as the one thing the repository does
/// record, and the direct line and address are stated as not yet published —
/// which is M-16, and is the LGU's to supply.
class OfficeContact {
  const OfficeContact._();

  /// The office an applicant is dealing with.
  static const String office = 'Office of the Building Official';

  static const String localGovernment = 'Municipality of Castilla, Sorsogon';

  /// The municipality's official website, as recorded in
  /// `requirements_catalog.dart`.
  ///
  /// Recorded there with `verificationStatus: PENDING_CASTILLA_VERIFICATION`
  /// and a note that it was not reachable by automated research on 20 August
  /// 2026. Presented as *where to look*, never as a verified address, and
  /// never as an email domain — see `docs/DECISION-M-29-bundle-identifier.md`,
  /// where the same unverified status is why the bundle identifier is still
  /// open.
  static const String website = 'castillasorsogon.gov.ph';

  /// What to show where a phone number or an email address would go.
  ///
  /// One sentence, used identically in all three screens, so that the day the
  /// LGU publishes its details there is exactly one place to change and no
  /// chance of correcting two screens and missing the third — which is a
  /// mistake this repository has already made once with the draft copy.
  static const String detailsPending =
      'The office has not yet published a direct line or email address for '
      'this app. Until it does, contact the $office at the $localGovernment, '
      'or see $website.';
}
