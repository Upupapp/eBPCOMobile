/// Which of the LGU's two services an application belongs to.
///
/// **A required field on `POST /applications` that this app never sent.** The
/// contract declares `serviceDomain` in `ApplicationSubmission.required`, and
/// `additionalProperties: false` means the body is refused outright without
/// it — so, measured on 29 August 2026, no application this app files could be
/// accepted by a conforming server at all. `grep -rn serviceDomain lib`
/// returned nothing.
///
/// It is derivable rather than a decision, which is why it can be fixed in
/// this lane: the app knows which wizard filed the application. Every one of
/// the nineteen `CanonicalPermitType`s is a construction-side permit; the only
/// other filing path is the business-permit screen, which names no permit type
/// because [ApplicationType] — New / Renewal / Amendment — is the whole of
/// what a business permit needs.
///
/// Stated here as a closed vocabulary with its wire form beside it, the way
/// every other closed vocabulary in this app states its own, so that a
/// mismatch is a compile error rather than a rejected filing.
enum ServiceDomain { businessPermit, constructionPermit }

extension ServiceDomainWire on ServiceDomain {
  /// The exact string the contract's `ServiceDomain` enum declares.
  String get wire => switch (this) {
    ServiceDomain.businessPermit => 'Business Permit',
    ServiceDomain.constructionPermit => 'Construction Permit',
  };

  /// How an applicant would name it.
  String get label => switch (this) {
    ServiceDomain.businessPermit => 'Business Permit',
    ServiceDomain.constructionPermit => 'Construction Permit',
  };
}

/// The domain an application belongs to, from the permit it names.
///
/// [permitTypeLabel] is the permit's own name — "Fencing", "Certificate of
/// Occupancy" — and is null exactly when the business-permit screen is the
/// filer. Deliberately a total function over that one input: anything that
/// names a permit is a construction filing, because this app has no other kind
/// of permit to name.
ServiceDomain serviceDomainFor(String? permitTypeLabel) =>
    permitTypeLabel == null
    ? ServiceDomain.businessPermit
    : ServiceDomain.constructionPermit;
