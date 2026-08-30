import 'draft_snapshot.dart';

/// The wizard's collected fields, shaped for `POST /applications` `form`.
///
/// **Until this existed the app sent no application data at all.** A filing
/// carried the permit type, the action, the applicant name, the site line and
/// the uploaded document ids — and nothing an applicant had typed. Nine or ten
/// steps of owner details, lot data, scope of work, professionals and
/// supervisors reached the Office of the Building Official only as whatever
/// the applicant had separately scanned and attached.
///
/// The contract has declared the field since it was written:
///
/// ```yaml
/// form:
///   type: object
///   description: The permit-type-specific field set. Validated server-side
///     against the schema for `permitType`; the wizards are auditable
///     field-for-field against the DPWH/JMC unified forms (decision E-14)
///     once those are supplied.
///   additionalProperties: true
/// ```
///
/// M-47 filed this as blocked on M-10 — the DPWH/JMC forms. **That premise is
/// spent.** The wizards were audited field-for-field on 31 August 2026 against
/// a better source than the national templates: Castilla's own bundled permit
/// forms, the ones the office actually issues. Nine of ten matched box for
/// box, the mismatches were fixed, and `form_field_parity_test.dart` pins the
/// counts. What decision E-14 was waiting for has happened.
///
/// **Why sending it cannot cost an applicant their filing.** Two properties of
/// the schema above, and they are the whole argument:
///
///   * `form` is **optional** — `required` is `[serviceDomain, permitType,
///     applicationAction]` — so adding it cannot fail a required-field check.
///   * `additionalProperties: true`, uniquely among this contract's request
///     schemas. Every other one is `false`, which is why an undeclared key
///     elsewhere costs the whole submission and why the lineage reference in
///     `http_applications_repository.dart` is deliberately still not sent.
///     Here the contract has explicitly opened the object.
///
/// So the reasoning that keeps M-44's reference unsent points the other way
/// for this field. The two cases look alike and are not.
///
/// **The keys are the draft snapshot's keys**, which makes them a wire surface
/// as well as a storage one. Deliberate, and the alternative is worse: a
/// second serialisation of nineteen wizards would drift from the first, and
/// the snapshot's is already round-trip tested for every wizard and already
/// frozen — renaming one orphans drafts on devices. It now also changes what
/// the office receives. Rename Dart fields; never these.
Map<String, Object?> permitFormPayload<T>(DraftCodec<T> codec, T draft) {
  final fields = codec.snapshot(draft, step: 0).fields;
  return {
    for (final entry in fields.entries)
      // Attachments are excluded. The snapshot records them as a map holding
      // `storedName` — the file's name inside this device's own app
      // container — which means nothing to a server and is not what carries a
      // document to the office. `documentIds`, from `/documents`, is.
      if (!_isAttachment(entry.value)) entry.key: entry.value,
  };
}

bool _isAttachment(Object? value) =>
    value is Map && value.containsKey('storedName');
