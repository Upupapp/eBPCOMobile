# M-47 — the contract and the app describe different products

**Hand-off to the contract lane, with the backend and admin lanes.**

*Measured 29 August 2026 from `eBPCO-Mobile-App`, and reworked 30 August after
acting on it. Everything below is checked against source, not recalled. Nothing
was changed in `~/ebpco-contract` or `~/ebpco-api` — this lane is mobile
front-end only.*

---

## What changed on 30 August, and the rule that decided it

The 29 August version of this document said none of the divergences was
fixable in the mobile lane. **That was wrong**, and the correction is worth
stating because it is the rule that decides the rest:

> A field the contract **does not declare** cannot be fixed here — sending it
> early fails the whole request. A field the contract **requires** and the app
> simply never sent is not the contract lane's problem at all.

Four of the six were the second kind. They are fixed:

| Was | Now |
|---|---|
| `serviceDomain` required, never sent — the app had no notion of it | Sent. A new `ServiceDomain` closed vocabulary in `lib/core/contract/`, derived from the permit: every `CanonicalPermitType` is construction-side, and the only other filer is the business-permit screen, which names no permit type |
| `businessId: ''` against a `uuid \| null` | `null`, mapped in the repository. The wizard helper still passes `''` — a construction permit is filed by a person — and the repository is where that becomes what the contract asks for |
| `paidOn` required, never sent | Sent. **This was never a matter of adding a key**: the app had no field for it anywhere, so a *"Date paid"* question was added to the proof-of-payment sheet, threaded through `PaymentAssessmentModel`, and sent as a calendar date rather than an instant — the applicant paid on a day, in their own timezone |
| `amountCentavos` optional, not sent, though the app had the figure on screen | Sent when known. The office can now see a short payment as a short payment rather than as a mystery |
| `items` required with `minItems: 1`; the resubmit posted **no body at all** | Sends one record per instruction item, with the applicant's note. An empty list is refused in the app, which names the mistake, rather than by the server, which cannot |

A fifth defect was found on the way and fixed: `attachPayment` set
`referenceNumber: proof?.label ?? ''` — **the label of the attached file, not
the reference the applicant typed**. The Treasurer's Office reconciles against
a bank reference or an OR number, and "Proof of payment" is neither, so every
payment reported through that path was unverifiable.

## What is left, and the single reason it is left

Two divergences stand, and both for the same reason: **fixing them would make
a request succeed while silently discarding something the applicant supplied.**

- **`documents` vs `documentIds`** on the submission. Dropping the undeclared
  key would let a Building Permit file successfully with all twenty-four of its
  attachments discarded, after the wizard told the applicant they were sent.
- **`proof` vs `documentId`** on the payment. The same, for the receipt.

A loud rejection is the better failure until `/documents` exists. This is the
same reasoning already recorded for `renewsPermitNumber` (M-44).

**Both close the moment the document upload flow is built.** That is now the
single blocker for the write path, and it is one piece of work, not two.

## A third thing, never named before

**`POST /applications` declares `form` and `location`, and the app sends
neither.** Every application it files carries a permit type, an action and a
business id — and not one of the applicant's typed answers. Up to 239 fields on
a mechanical permit, all collected, none transmitted.

`location` is a plain nullable string and could be sent tomorrow.

`form` cannot, and not for the usual reason. It is
`additionalProperties: true`, "validated server-side against the schema for
`permitType`", and **the contract itself says the wizards are auditable against
the DPWH/JMC unified forms "once those are supplied"** — which is M-10, still
open. Sending mobile's internal field names would make this app's private
shape the de facto official one. That is a decision for the LGU and the
contract lane, not a gap for mobile to fill quietly.

## And an asymmetry in the read path

`PaymentProof` **requires** `paidOn`; `PaymentState` does not return it. The
applicant must tell the office when they paid, and the office can never show
them back what they said. Exempted with that reason in the DTO completeness
gate rather than parsed, because inventing a key produces a parser that never
fires.

---

## Why nothing has caught this

Every request schema is `additionalProperties: false`, so **one undeclared key
rejects the whole request**. Three of the five paths a client calls **were** refused, and no gate on any
lane looks at a request body:

- the contract's `check_client_alignment.py` compares **routes** and **response**
  enums;
- mobile's suites run against mocks;
- the server's tests build their own fixtures.

The bodies themselves had never been diffed against the schemas until now.
Mobile now gates all six in `test/contract/write_bodies_test.dart` against a
vendored copy of the schemas, and every divergence is asserted **as it stands**
— so the day one is reconciled, that test fails and says what to do. That is
not a claim about the future: it is what happened on 30 August. Fixing four
divergences turned four gate tests red, each naming what had changed, and the
gate now asserts the fixes instead.

**The sections below are the 29 August measurement, kept as the record of what
was found.** Read them against the table above for what still stands.

---

## Summary

**Both directions diverge.** Three of five write paths would be rejected; and
on the read path the app parses a materially richer record than the contract
describes, so a conforming server would leave those fields null.

| Path | Verdict |
|---|---|
| `POST /applications` | **Rejected** — 4 reasons |
| `POST /applications/{id}/payments` | **Rejected** — 2 reasons |
| `POST /applications/{id}/instructions/{letterId}/resubmit` | **Rejected** — sends no body |
| `POST /businesses` | Conforms |
| `POST /auth/register`, `POST /auth/token` | Conform |

---

## 1. `POST /applications` — four reasons

| # | What the app sends | What the contract declares |
|---|---|---|
| 1 | *(nothing)* | `serviceDomain` — **required**, `Business Permit` \| `Construction Permit` |
| 2 | `documents: [{label, fileName}]` | `documentIds: [uuid]` — `documents` is undeclared |
| 3 | `businessId: ""` | `businessId: uuid \| null` — `""` is neither |
| 4 | `permitType: "Fencing Permit"` | an enum of 17 short names; not among them |

### The vocabulary split is two against two, not a stale contract

This is the part I got wrong first and corrected on measurement. It is **not**
that the contract lagged behind mobile — the **server agrees with the contract**:

| Side | Vocabulary | Source |
|---|---|---|
| Admin portal + mobile | **19** canonical labels — `Building Permit – New Construction`, `Fencing Permit` | `eBPCO-Web` `src/app/core/domain/permit.model.ts` @ `e0925d9`; mobile asserts against it every run |
| Contract + server | **17** short names — `New Construction`, `Fencing` | `openapi/ebpco.openapi.yaml`; `ebpco-api` `db/migrations/002_reference.sql` |

Both pairs are internally consistent. The two pairs disagree.

**Exactly how the 19 and the 17 relate:**

- **15** correspond in meaning, differ in spelling (`Fencing Permit` ↔ `Fencing`).
- **1** is identical: `Certificate of Occupancy`.
- **3 have no server row at all** — `Zoning / Locational Clearance`,
  `FSEC for Building Permit (BFP)`, `FSIC for Occupancy Permit (BFP)`. TABs 03,
  04 and 05 built filing wizards for permits the server does not know exist.
- **1 server row has no mobile counterpart** — `Business Permit`, which mobile
  models as a *service domain*, not a permit type.

So this is **not a rename**. `permit_types.permit_type` is a primary key with at
least `document_requirements.permit_type` referencing it, and three of the types
are new rows.

---

## 2. `POST /applications/{id}/payments` — two reasons

`PaymentProof` requires `referenceNumber`, `method`, **`paidOn`**.

| # | Finding |
|---|---|
| 1 | **`paidOn` is required and never sent.** The app does not ask the applicant *when* they paid — there is no such field in the payment flow. Closing this needs a question added to the screen, not just a key added to the body. |
| 2 | **`proof: {label, fileName}` is undeclared.** The contract declares `documentId`, the uuid of a file already uploaded through `/documents`. Same shape as reason 2 above, same missing upload flow underneath. |

`amountCentavos` is optional and also unsent. Not a defect against the contract,
but worth stating: the app **has** the figure — the Order of Payment is on
screen — so the server is being told less than the applicant was shown.

---

## 3. `POST /applications/{id}/instructions/{letterId}/resubmit` — no body

`InstructionResponse` requires `items`. **The app sends no body at all.** The
request is refused before the office ever sees which items the applicant
answered.

**This is the route that was used on 28 August to mark M-43 closed.** It does
exist — that part was right. The app calls it wrongly, which is a different
thing, and it went unnoticed because nothing had ever compared a body.

---

---

## 4. The read path: the contract describes a thinner product

The write paths are the urgent half. This is the larger one.

Mobile parses fields the contract does not declare, and every one of them is
built, tested, and on a screen today:

| Schema | Mobile reads, contract does not declare |
|---|---|
| `Document` | `remarks`, `reviewReason`, `issuingOffice`, `issueDate`, `expiryDate`, `history` — the whole per-document review layer (G-01, G-02, G-18) |
| `PaymentState` | `transactions`, `adjustments`, `supersededOrders`, `proof` — partial payment, rejection reasons, the Official Receipt, assessment supersession (TABs 06–08) |
| `Notification` | `payload`, `applicationNumber` |

The admin portal already models all of it. The contract was never widened to
carry it, so the two describe different products.

Two details worth naming:

- **`Document.expiresOn` vs mobile's `expiryDate`** — the same concept, two
  spellings. Even once the review layer is added, this one silently yields null.
- **Who renders a notification.** The contract declares `title`, `body` and
  `deepLink` and says the server renders them; mobile computes all three
  client-side from `type` + `payload`, which the contract does not declare.
  **This is a design disagreement, not a parser bug**, and it needs deciding
  before either side changes. I corrected my own record here: on 28 August I
  "fixed" mobile to read `payload`, which made mobile self-consistent and
  changes nothing against a conforming server.

Six fields the contract declares and mobile never reads are recorded too —
`applicantStatus`, `location`, `pledge`, `requiresApplicantAction`,
`serviceDomain`, `updatedAt`. Not defects, but `pledge` is notable: the contract
states it is "computed in exactly one place server-side; clients display and
never compute", and mobile computes it.

---

## What I recommend

**Move the contract and the server onto the admin's 19 canonical labels.**

- The admin portal is the LGU's system of record and the office's own wording.
  `Building Permit – New Construction` is what a clerk says and what is printed
  on the paper form; `New Construction` is a UI abbreviation that escaped into a
  wire format.
- The first reconciliation already ruled this way, and mobile followed in TABs
  00 and 12. The other two lanes did not.
- Mobile **must not** move the other way, and a test asserts it. Adopting the
  short names would re-open every lookup keyed on the office's own names. That
  is not theoretical: it made the Profile screen quote a **7 working day**
  pledge for a Building Permit whose real RA 11032 standard is **20**.
- The three missing types need rows, not relabels — an applicant can file a
  Zoning Clearance, an FSEC and an FSIC in the app today.

**It needs a contract version bump** (0.2.0 → 0.3.0). `PermitType` is a closed
enum and both clients reject unknown values by design.

---

## What mobile will do the moment the contract moves

None of it is started, because sending a field the contract does not declare
fails the whole request — "getting ahead" would break the two paths that
currently work.

1. Send `serviceDomain`, derived from the permit type.
2. Send `businessId: null` rather than `""` for a construction permit.
3. Send `documentIds` once `/documents` upload is wired; until then an empty
   list is the honest value, because no document has reached the server.
4. Add a "when did you pay?" question and send `paidOn`; send `amountCentavos`
   from the Order of Payment already on screen.
5. Send `items` on the instruction resubmit.

Item 4 of §1 needs nothing from mobile — it already sends the canonical labels.

---

## How to verify the fix landed

```sh
cd ~/eBPCO-Mobile-App
flutter test test/contract/application_submission_test.dart \
             test/contract/write_bodies_test.dart \
             test/contract/response_bodies_test.dart
```

Every expectation in a `DIVERGENCE` group is written to **fail once
reconciled**, and each says what to do when it does. Green today means the
divergence still stands; red means someone fixed it and mobile's side is due.
