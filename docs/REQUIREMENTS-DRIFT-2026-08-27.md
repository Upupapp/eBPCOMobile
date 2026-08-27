# Wizard upload slots vs the requirements catalog — 27 August 2026

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
