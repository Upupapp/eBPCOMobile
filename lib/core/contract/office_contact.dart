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
/// So this app says only what is recorded — and, since 31 August 2026, that
/// includes a real number and a real address. They were **in the repository
/// the whole time**, in the footer of the OBO's own bundled documentary
/// checklist. The first version of this class said the office had published
/// no contact details; that was a statement about what had been looked at.
///
/// What is still genuinely unpublished is a named Data Protection Officer.
class OfficeContact {
  const OfficeContact._();

  /// The office an applicant is dealing with.
  static const String office = 'Office of the Building Official';

  static const String localGovernment = 'Municipality of Castilla, Sorsogon';

  /// The office that actually answers, as its own checklist names it.
  ///
  /// The Office of the Building Official is the statutory role under PD 1096;
  /// in Castilla it sits with the **Municipal Engineer's Office**, which is
  /// what the OBO's own documentary checklist and the Excavation permit form
  /// are both headed. An applicant is looking for a door, so both are said.
  static const String engineeringOffice = 'Office of the Municipal Engineer';

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

  /// The office's own published mobile number.
  ///
  /// **Found 31 August 2026 in this repository**, not supplied by anyone. The
  /// footer of `assets/permits/Building-Permit-and-Occupancy-Checklist.pdf` —
  /// the Municipality of Castilla's own documentary checklist, under its seal
  /// — reads: *"For updates and inquiries, please call MEO at 09054818572
  /// (cellphone) or send an email at meocastilla@gmail.com within 3 working
  /// days."*
  ///
  /// That file has been bundled with the app all along. This class was written
  /// earlier the same day saying the office had published no contact details,
  /// which was a statement about what had been looked at rather than about
  /// what existed.
  static const String phone = '0905 481 8572';

  /// The number as printed, for `tel:` and for anyone comparing with the form.
  static const String phoneDigits = '09054818572';

  static const String email = 'meocastilla@gmail.com';

  /// The office's own turnaround promise for an enquiry, in its own words.
  ///
  /// Distinct from the RA 11032 processing pledge, which is about the
  /// application. This one is about the question.
  static const String replyPledge = 'within 3 working days';

  /// Where these came from, shown beside them.
  ///
  /// An applicant deciding whether to trust a phone number is owed its
  /// provenance, and this app has been wrong about contact details once
  /// already — it printed an invented address at a domain no government
  /// entity holds, and a Metro Manila landline for a Sorsogon municipality.
  static const String contactSource =
      'From the office’s own Building Permit documentary checklist.';

  /// What is still not published: a named Data Protection Officer.
  ///
  /// The checklist gives the office's number and address, which is what an
  /// applicant needs for an application. RA 10173 rights are a different
  /// channel and the LGU has not named one — so the Privacy Policy says the
  /// office, and says plainly that no DPO has been published. M-16.
  static const String dataProtectionOfficerPending =
      'The LGU has not published a named Data Protection Officer for this '
      'app. Send data privacy requests to the office above, and ask for the '
      'Data Protection Officer.';
}
