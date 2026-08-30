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
/// includes a real number and a real email. They were **in the repository the
/// whole time**, in the footer of the OBO's own bundled documentary checklist.
/// The first version of this class said the office had published no contact
/// details; that was a statement about what had been looked at.
///
/// **Corrected 31 August 2026:** this comment used to say a real *address*
/// too, and so did [dataProtectionOfficerPending]'s. Re-reading the checklist
/// to answer M-11 showed it carries no street address at all — only the
/// letterhead (Municipality of Castilla, Province of Sorsogon, Office of the
/// Municipal Engineer) and a phone and email in the footer. The office is
/// named; the door is not. See [addressPending].
///
/// Still genuinely unpublished: a named Data Protection Officer, a street
/// address, and the office's opening hours.
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
  /// The checklist gives the office's number and email, which is what an
  /// applicant needs for an application. RA 10173 rights are a different
  /// channel and the LGU has not named one — so the Privacy Policy says the
  /// office, and says plainly that no DPO has been published. M-16.
  /// The office's street address, which nothing in this repository records.
  ///
  /// M-11. The checklist's letterhead names the municipality, the province and
  /// the office; there is no street, no building, no room. An applicant who
  /// has to walk in is told what is known and told plainly what is not,
  /// rather than being given a plausible municipal hall — this app printed
  /// "City Hall Building, Quezon City" once already.
  static const String addressPending =
      'The office has not published a street address. Call or email before '
      'travelling.';

  /// The office's opening hours, which are likewise unpublished.
  ///
  /// Philippine government offices are commonly open 8:00am–5:00pm on
  /// weekdays, and RA 11032 requires service without a noon break — but
  /// "commonly" is not Castilla, and the hours an applicant plans a trip
  /// around are exactly the kind of fact this app has been wrong about
  /// before. Not stated.
  static const String officeHoursPending =
      'The office has not published its hours. Call before travelling.';

  static const String dataProtectionOfficerPending =
      'The LGU has not published a named Data Protection Officer for this '
      'app. Send data privacy requests to the office above, and ask for the '
      'Data Protection Officer.';
}

/// How a permit is claimed, as far as the repository records it.
///
/// M-11 — the claim location, office hours and bring-with-you list — was filed
/// as needing the LGU. Part of it did not: the bundled documentary checklist
/// prints a three-step procedure, and its third step is the claim.
///
/// **Why this exists at all.** `ReleaseRecord.claimLocation`, `.officeHours`
/// and `.bringWithYou` come from the backend, and the contract's own
/// reconciliation note (R-13) says those values "are LGU-specific (M-11 /
/// decision E-15) and are omitted rather than guessed". So in production they
/// arrive null — while the app pushes the applicant at them hard: a
/// `readyForRelease` application sets `requiresApplicantAction`, which drives
/// the Home action stack, the tab badge and push priority, under a
/// notification reading "Tap for claim instructions and requirements", to a
/// section headed **Claim instructions**.
///
/// Every field on that section was null-guarded, so what an applicant reached
/// was a heading and a paragraph about Special Powers of Attorney. An action
/// item that points at nothing is worse than no action item: it spends the
/// applicant's trip.
///
/// These are the fallback, used only when the backend sends nothing. They say
/// what the checklist says and name what it does not.
class ClaimProcedure {
  const ClaimProcedure._();

  /// Step 3 of the checklist's three steps, in its own words:
  /// *"Claiming the Building Permit and Ancillary Permits."*
  ///
  /// The ancillary permits are claimed **with** the building permit, not
  /// separately — which matches the way they are filed, as one submission,
  /// and is worth saying because this app models each ancillary as its own
  /// application.
  static const String claimedTogether =
      'The building permit and its ancillary permits are claimed together, in '
      'one visit.';

  /// Where, at the granularity the checklist actually supports.
  static const String location =
      '${OfficeContact.engineeringOffice}, '
      '${OfficeContact.localGovernment}';

  /// The step this belongs to, so the screen can say where it came from.
  static const String source =
      'From the office’s own Building Permit documentary checklist, step 3.';
}
