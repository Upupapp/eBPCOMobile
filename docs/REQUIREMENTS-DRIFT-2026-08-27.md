# Wizard upload slots vs the requirements catalog — 27 August 2026

> **CORRECTION, same day. The per-wizard slot counts below are wrong and are
> retained only as a record of how.** Counting upload slots by grepping for
> `DocumentUploadTile(` undercounts every wizard that wraps the widget in a
> local helper and calls that — the widget appears once in the source while
> the slots number a dozen. Building Permit was reported as 5 slots; rendering
> the step shows 12 in that step alone. A second attempt, following helper call
> sites, over-counted just as badly (87 slots for Mechanical) by picking up
> unrelated `label:` arguments.
>
> **Three static counts, three wrong answers.** The reliable method is the one
> used for the catalog itself: render the widgets and count them.
> `test/features/applications/building_permit/required_documents_reconciliation_test.dart`
> does that for Building Permit. The rest of this table needs the same
> treatment before any of its numbers are acted on.
>
> What survives the correction is the *shape* of the finding — the app and the
> checklist disagree, in both directions, per permit type — and the conclusion
> that reconciling is a per-document decision rather than a merge. Building
> Permit has now been reconciled properly; see below.

Produced during TAB 01, by comparing every `DocumentUploadTile` in each wizard
against the admin's `REQUIREMENTS_CATALOG` for that permit type.

The catalog figures come from **executing** the admin's own
`requirements-catalog.ts` (bundled with esbuild, run under node), not from
reading it. Two earlier attempts to parse that file with regular expressions
mis-assigned documents across spec boundaries and undercounted six permit
types.

| Wizard | Upload slots | Catalog documents | of which required | Gap |
|---|---|---|---|---|
| `building_permit` | 5 | 22 | 14 | +17 |
| `certificate_of_occupancy` | 2 | 9 | 8 | +7 |
| `excavation_permit` | 4 | 8 | 6 | +4 |
| `interior_design_permit` | 4 | 7 | 6 | +3 |
| `sign_permit` | 4 | 7 | 5 | +3 |
| `fencing_permit` | 4 | 6 | 5 | +2 |
| `addition_extension_permit` | 8 | 9 | 8 | +1 |
| `renovation_permit` | 8 | 9 | 7 | +1 |
| `demolition_permit` | 13 | 9 | 7 | -4 |
| `architectural_permit` | 12 | 7 | 6 | -5 |
| `civil_structural_permit` | 13 | 8 | 7 | -5 |
| `electronics_permit` | 13 | 7 | 6 | -6 |
| `mechanical_permit` | 13 | 7 | 6 | -6 |
| `plumbing_permit` | 13 | 7 | 6 | -6 |
| `sanitary_plumbing_permit` | 13 | 7 | 6 | -6 |
| `electrical_permit` | 16 | 7 | 6 | -9 |
| **Total** | **145** | **136** | | |

## The totals agree and the details do not

145 slots against 136 catalog documents looks like near-parity. Per
permit type it is nothing of the sort, and **the drift runs in both
directions**.

**The app asks for far less than the checklist.** Building Permit – New
Construction has 5 upload slots against a 22-document official Castilla
checklist, 14 of them required. Certificate of Occupancy has 2 against 9. An
applicant who supplies everything the app asks for has not supplied everything
the office needs, and will learn that after filing.

**The app asks for more than the catalog lists.** Electrical has 16 slots
against a 7-document entry; Mechanical, Plumbing, Sanitary, Electronics and
Civil / Structural each have 13 against 7 or 8. Several of those wizards were
built from the real trade-permit forms, which are more specific than the
catalog's generic per-discipline entry.

## Why this was not fixed mechanically

TAB 01 says the wizards should derive their upload slots from the catalog. The
catalog is now mirrored, tested and driving pre-flight — but rewiring the
sixteen upload steps to it would, on these numbers, **delete real upload slots
from nine wizards** and add unexplained ones to the rest.

Neither side is simply right:

- Where the app asks for less (Building Permit, Certificate of Occupancy,
  Excavation, Fencing, Sign, Interior Design), the catalog is transcribed from
  the LGU's own checklist and the app is under-collecting.
- Where the app asks for more (the six trade permits), the app was built from
  the actual trade-permit forms and the catalog's entry is the generic
  template — `verified: false` on most of them says so.

Reconciling a permit type means deciding, per document, which source is right.
That is a question for the office, not a merge. Doing it silently would either
drop documents an applicant must supply or demand ones they do not owe.

## What to do with this

One TAB per permit type, starting with the two where the app under-collects
most — Building Permit (+17) and Certificate of Occupancy (+7) — each
reconciling its slots against the catalog entry and recording the decision per
document. The catalog's `verified` flag says which entries were built from a
real Castilla form and can be trusted as-is.

---

## Building Permit – New Construction — RECONCILED, 27 August 2026

Measured by rendering, not grepping. Step 5 offers 3 professional-document
slots, step 6 offers 2 that appear only when the applicant is not the owner,
and step 7 — the Unified Application Form's documentary annex — offered 12.

Against the catalog's 22-document checklist (14 required), **seven required
documents had no slot anywhere**:

| Checklist document | Decision |
|---|---|
| Unified Building Permit Form (signed) | **Added** to step 7 |
| Survey Plan | **Added** to step 7 |
| Cost Estimate (signed and sealed) | **Added** — distinct from the Bill of Materials already collected |
| Structural Design and Analysis | **Added** |
| Soil Analysis / Plate Load Test / Seismic Analysis | **Added** |
| Approved Construction Safety and Health Program (DOLE) | **Added** — submitted to OBO, as the checklist itself directs |
| Road Clearance (DPWH / PEO) | **Added** — same |

Step 7 now offers 19 slots, and all 19 gate Continue through
`RequiredDocuments.isValid`.

### Decisions taken and not taken

**The eight ancillary permit forms stay out.** The checklist lists Electrical,
Fencing, Architectural, Sanitary/Plumbing, Mechanical, Civil/Structural,
Excavation and Electronics permit *application forms* as conditional uploads.
This app files each of those as its own application through its own wizard,
which is better than asking an applicant to upload a form. Recorded as a
deliberate divergence rather than a gap.

**Three app-only documents stay in.** Tax Declaration, Real Property Tax
Receipt and Barangay Clearance are collected by the app and are not on the OME
checklist. Barangay Clearance in particular is real Castilla practice. Kept,
and flagged for the office to confirm.

**The PRC ID / PTR duplication is not a defect.** Those appear in both step 5
and step 7, which looks like double-asking. The model says why: step 7 "is the
consolidated document-checklist annex from the Unified Application Form …
tracked independently from any similarly-named uploads collected earlier",
because the annex is a checklist in its own right. Left alone.

### What this cost to get right

The first count said 5 slots. The second said 17. Rendering said 15, of which
step 7 held 12. The reconciliation only became possible once the measurement
was taken from the running widget rather than from the source text — the same
lesson the requirements catalog itself taught two hours earlier, learned again.
