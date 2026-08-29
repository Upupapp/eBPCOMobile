# M-47 — three of five client write paths cannot succeed

**Hand-off to the contract lane, with the backend and admin lanes.**

*Measured 29 August 2026 from `eBPCO-Mobile-App`. Everything below is checked
against source, not recalled. Nothing was changed in `~/ebpco-contract` or
`~/ebpco-api` — this lane is mobile front-end only.*

---

## Why nothing has caught this

Every request schema is `additionalProperties: false`, so **one undeclared key
rejects the whole request**. Three of the five paths a client calls would be
refused today, and no gate on any lane looks at a request body:

- the contract's `check_client_alignment.py` compares **routes** and **response**
  enums;
- mobile's suites run against mocks;
- the server's tests build their own fixtures.

The bodies themselves had never been diffed against the schemas until now.
Mobile now gates all six in `test/contract/write_bodies_test.dart` against a
vendored copy of the schemas, and every divergence below is asserted **as it
stands** — so the day one is reconciled, that test fails and says what to do.

---

## Summary

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
             test/contract/write_bodies_test.dart
```

Every expectation in a `DIVERGENCE` group is written to **fail once
reconciled**, and each says what to do when it does. Green today means the
divergence still stands; red means someone fixed it and mobile's side is due.
