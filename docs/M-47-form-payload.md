# `form` — the applications this app filed carried nothing the applicant typed

Closed 1 September 2026. It was filed as blocked on M-10; **the premise had
already expired.**

## What was happening

`POST /applications` was built like this:

```
serviceDomain · permitType · applicationAction · businessId ·
location · documentIds
```

That is the whole body. An applicant walked nine or ten steps — owner details,
lot and title data, scope of work, occupancy classification, project cost, the
designing professional, the full-time supervisor — and **none of it was
transmitted**. Up to 239 fields on a mechanical permit, collected, validated,
shown back on a review step, saved to the keychain, and dropped at the wire.

The office received a permit type, a name, a site line and a pile of
attachments.

## Why it stood

The reason was a good one, which is why it lasted. From the gate that has been
asserting it since 30 August:

> Not fixable here… `form` is validated server-side against the schema for
> `permitType`, and the contract says the wizards are auditable against the
> DPWH/JMC unified forms "once those are supplied". They have not been — that
> is M-10. Sending mobile's internal field names would make this app's private
> shape the de facto official one.

## Why it stopped being a good one

**The audit happened, against a better source than the one it was waiting
for.** On 31 August every wizard was checked field-for-field against
Castilla's *own* bundled permit forms — the documents this office issues, under
its letterhead, signed by its Municipal Engineer. Nine of ten matched box for
box; the mismatches (a missing telephone field, a missing scope option, a CTC
asked for where the form says government ID, a missing storey count, one cost
line where the form prints six) were fixed, and `form_field_parity_test.dart`
pins the counts. What decision E-14 was waiting for has been done, and the
national templates would have been the weaker authority.

So these are not "mobile's internal field names" in the sense that mattered.
They are the audited field set of the forms themselves.

**And silence protected nothing.** Withholding the data did not keep the shape
open for a later decision; it meant the office received none of it. A shape the
office can read beats no data at all.

## Why sending it cannot cost an applicant their filing

Two properties of the schema, and they are the whole argument:

* `form` is **optional** — `required` is `[serviceDomain, permitType,
  applicationAction]` — so adding it cannot fail a required-field check.
* `additionalProperties: true`, **uniquely among this contract's request
  schemas**. Every other one is `false`, which is why an undeclared key
  elsewhere costs the whole submission, and why the M-44 lineage reference is
  still deliberately not sent. Here the contract has explicitly opened the
  object, and a server is free to ignore what it does not recognise.

The two cases look alike and are not. That is worth stating, because "we do not
send undeclared fields" was the right rule that would have produced the wrong
answer here.

## The keys

`permitFormPayload` asks the wizard's **draft codec** for its snapshot and
sends those keys. That makes them a wire surface as well as a storage one, on
purpose:

* a second serialisation of nineteen wizards would drift from the first;
* the snapshot's is round-trip tested for every wizard already;
* it is already frozen — renaming a key orphans drafts on devices.

It now also changes what the office receives. **Rename Dart fields; never these
keys.** If the DPWH/JMC forms ever dictate different names, that belongs in a
mapping layer, not a rename.

Attachments are stripped. The snapshot records one as a map holding
`storedName` — the file's name inside *this device's* app container — which
means nothing to a server and is not what carries a document to the office.
`documentIds`, from `/documents`, is.

## What this changed elsewhere

**The privacy manifest gate caught it, correctly.** `form` is one body key
carrying the largest payload the app sends, and the manifest test refuses any
transmitted key it cannot account for. Its contents fall under types already
declared — Name, PhysicalAddress, PhoneNumber, OtherDataTypes — so no new Apple
type was needed. One fact is worth naming and is recorded there:

> It carries **other people's** data, not only the applicant's. Every
> construction wizard collects the designing professional and the full-time
> supervisor — name, PRC licence, PTR, address, contact number. Those are third
> parties to this app's account holder.

Apple's manifest has no axis for a data subject, so the declared types are
unchanged. The in-app Privacy Policy was checked and already covers it: its
*Personal Information* section names "information about an authorized
representative or licensed professional acting on your behalf", and its
*Application Information* section names the property, scope, cost and schedule.
It said "collect" and was written when the app transmitted none of it; it is
accurate for both now. **The App Store Connect privacy label is a separate
declaration of the same facts and has not been re-read** — it is a manual task.

## The gates

* `test/core/api/form_payload_test.dart` — the payload carries what was typed,
  its keys are the codec's rather than a second list, attachments and device
  paths are excluded.
* `test/contract/application_submission_test.dart` — the divergence test
  flipped from asserting the gap to asserting the closure, and gained a sweep
  that **all nineteen wizards** send it. A payload builder that exists is not a
  field that is sent, and one wizard wired out of nineteen is a shape this repo
  has been bitten by three times.

That sweep's vacuity guard earned itself immediately: it counted twenty
wizards on the first run, because the file that *defines*
`submitPermitApplication` also contains the string.
