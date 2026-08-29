# M-47 — `POST /applications` cannot succeed. Hand-off to the contract lane.

*Measured 29 August 2026 from `eBPCO-Mobile-App`. Everything below is checked
against source, not recalled. Nothing has been changed in `~/ebpco-contract` or
`~/ebpco-api` — this lane is mobile front-end only.*

**No application can be filed against a conforming server today.** Not one
permit type, not one wizard. This is invisible to every gate currently running:
the contract's `check_client_alignment.py` compares *routes* and *response*
enums, never a request body, and mobile's own suites test against mocks.

---

## The four reasons, in the order a server would reject them

`ApplicationSubmission` is `additionalProperties: false`, so any one of these is
fatal on its own.

| # | What the app sends | What the contract declares |
|---|---|---|
| 1 | *(nothing)* | `serviceDomain` — **required**, `Business Permit` \| `Construction Permit` |
| 2 | `documents: [{label, fileName}]` | `documentIds: [uuid]` — `documents` is undeclared |
| 3 | `businessId: ""` | `businessId: uuid \| null` — `""` is neither |
| 4 | `permitType: "Fencing Permit"` | enum of 17 short names; `Fencing Permit` is not among them |

---

## The vocabulary split is two against two, not a stale contract

This is the part I got wrong first and corrected on measurement. It is **not**
that the contract lagged behind mobile. The **server agrees with the contract**:

| Side | Vocabulary | Source |
|---|---|---|
| Admin portal + mobile | **19** canonical labels — `Building Permit – New Construction`, `Fencing Permit` | `eBPCO-Web` `src/app/core/domain/permit.model.ts` @ `e0925d9`; mobile asserts against it every run |
| Contract + server | **17** short names — `New Construction`, `Fencing` | `openapi/ebpco.openapi.yaml`; `ebpco-api` `db/migrations/002_reference.sql` |

Both pairs are internally consistent. The two pairs disagree.

**How the 19 and the 17 relate, exactly:**

- **15** correspond in meaning but differ in spelling (`Fencing Permit` ↔
  `Fencing`, `Sanitary Permit` ↔ `Sanitary/Plumbing`).
- **1** is spelled identically: `Certificate of Occupancy`.
- **3 have no server row at all** — `Zoning / Locational Clearance`,
  `FSEC for Building Permit (BFP)`, `FSIC for Occupancy Permit (BFP)`. TABs 03,
  04 and 05 built filing wizards for permits the server does not know exist.
- **1 server row has no mobile counterpart** — `Business Permit`, which mobile
  models as a *service domain*, not a permit type.

So this is not a rename. `permit_types.permit_type` is a **primary key** with at
least `document_requirements.permit_type` referencing it, and the three missing
types are new rows, not relabelled ones.

---

## What I recommend, and why

**Move the contract and the server onto the admin's 19 canonical labels.**

- The admin portal is the LGU's system of record and the office's own wording.
  `Building Permit – New Construction` is what a clerk says and what appears on
  the paper form; `New Construction` is a UI abbreviation that escaped into a
  wire format.
- The first reconciliation already ruled this way — permit types were to be the
  admin's — and mobile followed in TABs 00 and 12. The other two lanes did not.
- Mobile **must not** move the other way, and there is a test asserting it
  (`application_submission_test.dart`). Adopting the short names would re-open
  every lookup keyed on the office's own names. That defect is not theoretical:
  it made the Profile screen quote a **7 working day** pledge for a Building
  Permit whose real RA 11032 standard is **20**.

**It needs a contract version bump** (0.2.0 → 0.3.0) — `PermitType` is a closed
enum and both clients reject unknown values by design.

---

## What mobile will do the moment the contract moves

Three of the four are then trivial here, and none is started, because sending a
field the contract does not declare fails the whole submission:

1. Send `serviceDomain`, derived from the permit type.
2. Send `businessId: null` rather than `""` for a construction permit.
3. Send `documentIds` once `/documents` upload is wired — until then, an empty
   list is the honest value, since no document has reached the server.

Item 4 needs nothing from mobile: it already sends the canonical labels.

---

## How to verify the fix landed

```sh
cd ~/eBPCO-Mobile-App
flutter test test/contract/application_submission_test.dart
```

Every expectation in its `DIVERGENCE` group is written to **fail once
reconciled**, and each says what to do when it does. A green run there today
means the divergence still stands; a red one means someone fixed it and mobile's
side is now due.
