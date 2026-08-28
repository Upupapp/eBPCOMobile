# eBPCO Mobile — Admin-Portal Parity Programme

## Closing certification

**Verdict: NOT CERTIFIED.**

Every one of the sixteen build TABs is complete, all twenty standing gaps are
closed in this repository, and the suite is green at 1462 tests. The programme
is not certified because certification is a claim about a working system, and
three things stand between this repository and one. None of them is code in
this repository, and none of them can be closed by this lane.

*Measured 28 August 2026 against the admin portal at `Upupapp/eBPCO-Web`
`e0925d9` (26 August 2026), and this repository at the commit that carries this
document.*

---

## 1. What was measured

The comparison that produced the master command was re-run against the admin
line as it stands today, mechanically rather than by reading.

`scripts/extract_admin_vocabulary.mjs` reads the admin's
`src/app/core/domain/` and prints its nine closed vocabularies — 56 values — as
JSON. `scripts/sync_admin_vocabulary.sh` stamps the admin's current commit and
date onto the result and vendors it at `test/contract/admin-vocabulary.json`.
`test/contract/admin_vocabulary_extracted_test.dart` asserts this app against
it, value for value and in order.

This matters because the fixtures that existed before today were **transcribed
by hand**. A hand transcription is a claim about a file, and this programme was
wrong about what a file said three times: twice by regex over
`requirements-catalog.ts`, and once by quoting an admin comment that described
the vendor's mobile copy rather than this one. The transcribed fixture is kept
beside the extracted one deliberately. If the two ever disagree, one of them is
wrong about the admin, and finding out which is the point.

### Drift since 25 August

The admin moved from `e3cd7c3` to `e0925d9` — one commit, "Correct the product
name to Building Permit and Certificate of Occupancy", 26 August.
`git diff e3cd7c3..e0925d9 -- src/app/core/domain/` is empty: **no vocabulary
drifted.** All nine vocabularies extract identically to the transcription made
on 27 August.

### One divergence found, in the admin

The admin declares the assessment-status vocabulary twice, and the two
declarations disagree:

| Declaration | Order |
|---|---|
| `type AssessmentStatus` | … Partially Paid, **Paid, Overdue**, Superseded … |
| `const ASSESSMENT_STATUS_ORDER` | … Partially Paid, **Overdue, Paid**, Superseded … |

Nothing in the admin references `ASSESSMENT_STATUS_ORDER`. The union is the
definition, and this app follows it. Both are now extracted into the fixture so
the contradiction is visible rather than hidden by whichever one a script
happened to read, and a test asserts that they still disagree — so the day
someone reconciles them, it fails and says which order won, rather than this
app quietly matching the loser.

**Owner: admin lane.** Cosmetic today; it becomes a real defect the moment
anything sorts by it.

---

## 2. The gap register

Twenty gaps stood when the programme began; one more was withdrawn on
inspection. All twenty are closed in this repository.

| ID | Gap | Closed by | Artefact |
|---|---|---|---|
| G-01 | Per-document review status absent | TAB 02 | `DocumentModel.status` |
| G-02 | Document rejection remarks never reach the applicant | TAB 02 | `DocumentModel.remarks` |
| G-03 | Payment rejection reason has nowhere to display | TAB 06 | `PaymentTransactionRecord.rejectionReason` |
| G-04 | "Partially Paid" unrepresentable | TAB 06 | `PaymentAssessmentStatus.partiallyPaid` |
| G-05 | Official Receipt not modelled | TAB 07 | `orNumber` / `orDate` / `orIssuedBy` |
| G-06 | Zoning / Locational Clearance cannot be filed | TAB 03 | `zoning_clearance/`, 5 steps, 16 documents |
| G-07 | FSEC cannot be filed | TAB 04 | `fsec_clearance/`, 4 steps, 9 documents |
| G-08 | FSIC cannot be filed | TAB 05 | `fsic_clearance/`, 4 steps, 10 documents |
| G-09 | No requirements catalog | TAB 01 | `requirements_catalog.dart`, 19 types, 171 documents |
| G-10 | Permit validity / expiry absent | TAB 09 | `ApplicationModel.expiryDate` |
| G-11 | Release method & claimant not modelled | — | **Withdrawn**: the admin comment described the vendor's mobile copy |
| G-12 | Collecting agency not distinguished | TAB 07 | `CollectingAgency` |
| G-13 | Assessment supersession invisible | TAB 08 | `supersededOrders`, `wasReassessed` |
| G-14 | Fee line items not itemised from a versioned assessment | TAB 08 | `OrderOfPayment.version` + `AssessmentFees` |
| G-15 | Official blank forms & checklists unavailable | TAB 10 | 18 bundled PDFs, ~6.6 MB |
| G-16 | Contact verification absent | TAB 11 | `ContactVerification`, per channel |
| G-17 | Citizen's Charter covers 5 types of 19 | TAB 12 | all 19, asserted |
| G-18 | Document issuing office / issue & expiry dates not captured | TAB 02 | `issuingOffice`, `issueDate`, `expiryDate` |
| G-19 | Payment adjustments not modelled | TAB 06 | `PaymentAdjustmentRecord` |
| G-20 | No renewal or amendment flow | TAB 14 | `ApplicationLineage` |

---

## 3. Why NOT CERTIFIED

### B-1 — There is no backend. *Owner: backend lane.*

The app has never spoken to a server. `RepositoryFactory` returns the mock
implementations because no API is configured; `HttpApplicationsRepository`
exists, is tested, and is reached by nothing in a running build. Everything
below follows from this, and nothing above can be verified against a live
system until it is answered. This is M-27, and it is a decision as much as a
task: technology, hosting, and who operates it.

### B-2 — Three routes the app calls do not exist. *Owner: backend lane.*

| | Route | Recorded |
|---|---|---|
| Document resubmission | `POST /applications/:id/documents/:documentId/resubmit` | M-43 |
| Renewal / amendment reference | field on `POST /applications` | M-44 |
| Contact verification | send and confirm, per channel | M-45 |

Each fails loudly rather than quietly on a live build, deliberately. The
resubmission route is additionally the one thing failing the contract
repository's own client-alignment check, and has been since before this
programme.

### B-3 — Two subsystems are built, tested, and wired to nothing.

`OfflineQueue` and `SyncEngine` are constructed **nowhere** in `lib/`.
Measured, not assumed: `grep -rn "OfflineQueue(" lib` outside its own file
returns nothing.

This has a consequence the acceptance criteria did not anticipate. TAB 11's
criterion — *"verification requests survive a failed network call"* — is
satisfied by the provider, which enqueues on failure, and is proven by a test
that hands it a queue. In the running app the provider is constructed with no
queue, because there is none to give it. **The behaviour is real code with no
live wiring.** Saying it is done would be true of the unit and false of the
product.

This is M-39, and it is the one open item that is neither purely backend nor
purely a decision: wiring it needs `connectivity_plus`, a background-execution
decision, and a server to flush to.

---

## 4. What is open, and who owns it

### Backend lane

| Item | What it needs |
|---|---|
| M-27 | Decide the backend technology, hosting, and operator |
| M-43 | Provide the document-resubmission route |
| M-44 | Carry `priorApplicationId` / `priorPermitNumber` on `POST /applications` — a contract change, so a version bump |
| M-45 | Send and check the email link and the mobile OTP |

Contract `0.2.0` was published from this programme (TAB 13): four notification
types for states the applicant could reach and nobody could announce. Its
client-alignment check reports three problems, all predating it.

### Admin lane

| Item | What it needs |
|---|---|
| Assessment status order | Reconcile the union with `ASSESSMENT_STATUS_ORDER`, or delete the unused constant |
| Requirements catalog enrichment | Twelve trade wizards collect more than the catalog lists. The wizards are not wrong — the catalog is thin. Recorded in `docs/REQUIREMENTS-DRIFT-2026-08-27.md` |
| Renewal requirements | The LGU publishes no shorter list for renewals. This app deliberately does not invent one; the office must state it |

### Decisions, deliberately not taken

| Item | Why it is not this lane's |
|---|---|
| Whether contact verification ever gates filing | A product decision for the LGU. TAB 11 surfaces the state and gates nothing |
| M-40 — formatting the whole tree | Needs both platform lanes to land it in the same moment |
| M-04 — pushing `main` to `Upupapp/eBPCOMobile` | The owner's to run |

---

## 5. What this programme is confident about

Against the admin's own source, extracted today:

- **All 19 permit types are filable**, with the office's exact names — including
  the EN DASH that has already broken one route.
- **Nine closed vocabularies match**, in order, and parsing is total and closed:
  every value the admin can send round-trips, and an unrecognised one throws
  rather than defaulting to something plausible.
- **1462 tests**, `flutter analyze` clean, zero layout overflows at 2.0× text
  scale across every routable screen.

And one habit, worth more than any of them: **a green result is a claim that
must be falsified before it is believed.** This programme produced eight
confident claims that did not survive measurement — five wizards filing the
wrong permit type, a route sweep that rendered the splash screen fifty times, a
scanner blind to 127 anonymous closures, three wrong counts of the same upload
slots, a charter route dead on the app's three most common filings. Each was
found by trying to break the thing that had just passed.

The gates added along the way exist so the next one fails a test instead of
reaching an applicant.
