# Wizard upload slots vs the requirements catalog — 27 August 2026

**Re-measured by rendering, 27 August.** Every earlier table in this file was
wrong; see "How this was got wrong three times" at the end.

Slot counts come from `test/features/applications/upload_slot_census_test.dart`,
which mounts every document-bearing step of every wizard and counts the
`DocumentUploadTile`s in the tree. Catalog counts come from executing the
admin's own `requirements-catalog.ts`. Both are now asserted by tests, so a
slot that disappears is a failure rather than a later discovery.

| Wizard | Upload slots | Catalog docs | of which required | Slots − required | Catalog from a real LGU form |
|---|---|---|---|---|---|
| `excavation_permit` | 3 | 8 | 6 | -3 | — |
| `fencing_permit` | 3 | 6 | 5 | -2 | — |
| `certificate_of_occupancy` | 8 | 9 | 8 | +0 | — |
| `building_permit` | 22 | 22 | 14 | +8 | yes |
| `sign_permit` | 12 | 7 | 5 | +7 | — |
| `electronics_permit` | 15 | 7 | 6 | +9 | — |
| `interior_design_permit` | 27 | 7 | 6 | +21 | — |
| `renovation_permit` | 30 | 9 | 7 | +23 | — |
| `architectural_permit` | 29 | 7 | 6 | +23 | — |
| `demolition_permit` | 33 | 9 | 7 | +26 | — |
| `addition_extension_permit` | 36 | 9 | 8 | +28 | — |
| `electrical_permit` | 51 | 7 | 6 | +45 | — |
| `civil_structural_permit` | 61 | 8 | 7 | +54 | — |
| `plumbing_permit` | 61 | 7 | 6 | +55 | — |
| `sanitary_plumbing_permit` | 62 | 7 | 6 | +56 | — |
| `mechanical_permit` | 78 | 7 | 6 | +72 | — |

## What the measurement says

**Three wizards ask for less than the office requires.**

- `excavation_permit` — 3 slots against 6 required documents
- `fencing_permit` — 3 against 5
- `certificate_of_occupancy` — 8 against 8 required, but 9 in the catalog

These are the real under-collections, and the same failure Building Permit had
before it was reconciled: an applicant supplies everything the app asks for and
still has not supplied everything the office needs.

**Building Permit now matches exactly** — 22 slots against a 22-document
checklist — following the reconciliation recorded below.

**The other twelve ask for far more than the catalog lists**, and mostly that
is the catalog being thin rather than the app being wrong. Mechanical offers 78
slots against a 7-document entry; Sanitary 62, Civil / Structural and Plumbing
61, Electrical 51. Those wizards were built from the actual Castilla trade
forms, which itemise per equipment type and per installation. The catalog's
entries for them are the generic template — and the rightmost column shows it:
only the entries built from a real LGU form are marked, and none of the trade
permits are.

## What to do about it

**Reconcile the three under-collectors first.** Those are cases where the app
is demonstrably short of a checklist that came from the LGU.

**Do not trim the over-collectors to match.** Where the catalog is unverified
and the wizard came from a real form, the wizard is the better record. What
those twelve need is the reverse flow: the catalog entry brought up to the
wizard's specificity, which is a change to the admin portal and belongs to that
lane.

## How this was got wrong three times

Worth keeping, because the pattern was the same each time and the cost was
real.

1. **Grepping `DocumentUploadTile(`** — undercounted every wizard that wraps
   the widget in a helper. Building Permit read as 5 slots; it had 15.
2. **Following helper call sites** — over-counted by picking up unrelated
   `label:` arguments from text fields nearby. Mechanical read as 87.
3. **Mounting the wizard and counting the tree** — returned 0 for everything,
   because a `PageView` builds only its visible page.

The method that worked was mounting each step individually and counting the
rendered widgets. The same lesson the requirements catalog itself taught two
hours earlier, when parsing its TypeScript twice gave two wrong answers and
executing it gave the right one: **when a number matters, run the thing that
produces it.**

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
