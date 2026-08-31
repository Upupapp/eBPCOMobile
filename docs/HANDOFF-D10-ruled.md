# D-10 — ruled: the office's 19 names, and eBPCO accepts all of them

Ruled by the owner, 31 August 2026, on the brief in
`DECISION-D10-permit-vocabulary.md`. Two answers:

1. **The office's 19 names are canonical** — what the LGU prints on its own
   forms and what its admin portal uses.
2. **eBPCO accepts filings for permits another office issues** — Zoning /
   Locational Clearance (MPDC), FSEC and FSIC (BFP). The citizen files in one
   place; eBPCO routes.

**Mobile changes nothing.** Its vocabulary is extracted mechanically from the
admin portal and already matches. This document exists so the backend does not
have to re-derive the list.

---

## The seed

Replaces the 17 short names in `db/migrations/002_reference.sql`. Generated
from `test/contract/admin-vocabulary.json`, which is itself extracted from the
admin portal's `src/app/core/domain/` — not typed by hand.

```sql
insert into permit_types (permit_type, service_domain) values
  ('Building Permit – New Construction', 'Construction Permit'),
  ('Building Permit – Renovation / Alteration', 'Construction Permit'),
  ('Building Permit – Addition / Extension', 'Construction Permit'),
  ('Demolition Permit', 'Construction Permit'),
  ('Zoning / Locational Clearance', 'Construction Permit'),
  ('Architectural Permit', 'Construction Permit'),
  ('Civil / Structural Permit', 'Construction Permit'),
  ('Electrical Permit', 'Construction Permit'),
  ('Mechanical Permit', 'Construction Permit'),
  ('Sanitary Permit', 'Construction Permit'),
  ('Plumbing Permit', 'Construction Permit'),
  ('Electronics Permit', 'Construction Permit'),
  ('Interior Design Permit', 'Construction Permit'),
  ('Fencing Permit', 'Construction Permit'),
  ('Sign Permit', 'Construction Permit'),
  ('Excavation Permit', 'Construction Permit'),
  ('FSEC for Building Permit (BFP)', 'Construction Permit'),
  ('Certificate of Occupancy', 'Construction Permit'),
  ('FSIC for Occupancy Permit (BFP)', 'Construction Permit');
```

Three of these are new rows rather than renames, and they are the scope
decision: **Zoning / Locational Clearance**, **FSEC for Building Permit
(BFP)**, **FSIC for Occupancy Permit (BFP)**. The mobile app already has
wizards for all three — closed as certification gaps G-06, G-07 and G-08 —
which until now a citizen could fill in and not file.

`Business Permit` is deliberately absent from the list above: it is not one of
the office's 19 construction permits, and the app's legacy business-permit
flow is a separate open question. **Keep the existing row** unless that flow is
retired.

## The contract enum

`PermitType` in `openapi/ebpco.openapi.yaml`:

```yaml
        PermitType:
          type: string
          enum:
            - Building Permit – New Construction
            - Building Permit – Renovation / Alteration
            - Building Permit – Addition / Extension
            - Demolition Permit
            - Zoning / Locational Clearance
            - Architectural Permit
            - Civil / Structural Permit
            - Electrical Permit
            - Mechanical Permit
            - Sanitary Permit
            - Plumbing Permit
            - Electronics Permit
            - Interior Design Permit
            - Fencing Permit
            - Sign Permit
            - Excavation Permit
            - FSEC for Building Permit (BFP)
            - Certificate of Occupancy
            - FSIC for Occupancy Permit (BFP)
```

## What "done" looks like

`test/contract/application_submission_test.dart` in the mobile repo asserts how
many of the 19 the contract accepts. It reads **1** today — only
`Certificate of Occupancy` is spelled the same in both. **It should read 19.**
That number is the measure of this ruling, and mobile will flip it in one
commit once the contract moves.

## The one rule either way

**No cast.** The admin portal already converts between the two vocabularies
unchecked. Adding a mapping anywhere else — server, contract or client — would
make a third spelling with no authority, and a defect that shows up only on the
surface nobody tested.

## Still open, separately

* **D-8** — `POST /applications/{id}/documents/{documentId}/resubmit` returns
  404. Different operation from the Letter of Instruction resubmit.
* **`serviceDomain`** — the contract still marks it required on
  `ApplicationSubmission`; the server rejects it as unrecognised and derives it
  for the response. The client no longer sends it.
