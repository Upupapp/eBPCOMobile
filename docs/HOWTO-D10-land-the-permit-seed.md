# How to land the permit vocabulary — a walkthrough for the backend lane

D-10 was ruled on 31 August: **the office's 19 names are canonical**, and
**eBPCO accepts the three clearances another office issues**. This is what
applying that looks like, written after reading the schema rather than
guessing at it.

**Not a patch to apply blind.** Two of the fifteen renames are judgement calls,
flagged below.

---

## The thing that makes this more than a seed edit

`002_reference.sql` is already applied everywhere it has ever run, so it cannot
be edited — the change is a **new migration**.

And `permit_types.permit_type` is a **text primary key referenced by five
tables**, every one of them `ON UPDATE NO ACTION`:

```
applications.permit_type            applications_permit_type_fkey
charter_entries.permit_type         charter_entries_permit_type_fkey
document_requirements.permit_type   document_requirements_permit_type_fkey
fee_schedule_entries.permit_type    fee_schedule_entries_permit_type_fkey
staff_permit_access.permit_type     staff_permit_access_permit_type_fkey
```

*(Queried from a live database, not read off the migrations —
`fee_schedule_entries` does not appear in a grep of
`references permit_types` in `002`/`003`/`007`/`022`/`032`, and would have been
missed.)*

So a bare `update permit_types set permit_type = …` **fails on the foreign
keys**. And `staff_permit_access` is not empty: `032` populates it with a row
per staff account per permit type — a freshly seeded super admin has 17.

---

## The migration

```sql
-- 033_permit_vocabulary.sql
--
-- D-10. The office's own forms say "Fencing Permit Application"; this table
-- said "Fencing". The admin portal and both citizen clients use the office's
-- names, so the table moves rather than three front ends.

begin;

-- 1. The five foreign keys are ON UPDATE NO ACTION, so a rename would violate
--    them. Re-created with ON UPDATE CASCADE, preserving each one's existing
--    ON DELETE rule — document_requirements and staff_permit_access are
--    RESTRICT and must stay that way.

alter table applications
  drop constraint applications_permit_type_fkey,
  add  constraint applications_permit_type_fkey
       foreign key (permit_type) references permit_types (permit_type)
       on update cascade;

alter table charter_entries
  drop constraint charter_entries_permit_type_fkey,
  add  constraint charter_entries_permit_type_fkey
       foreign key (permit_type) references permit_types (permit_type)
       on update cascade;

alter table fee_schedule_entries
  drop constraint fee_schedule_entries_permit_type_fkey,
  add  constraint fee_schedule_entries_permit_type_fkey
       foreign key (permit_type) references permit_types (permit_type)
       on update cascade;

alter table document_requirements
  drop constraint document_requirements_permit_type_fkey,
  add  constraint document_requirements_permit_type_fkey
       foreign key (permit_type) references permit_types (permit_type)
       on update cascade on delete restrict;

alter table staff_permit_access
  drop constraint staff_permit_access_permit_type_fkey,
  add  constraint staff_permit_access_permit_type_fkey
       foreign key (permit_type) references permit_types (permit_type)
       on update cascade on delete restrict;

-- 2. Fifteen renames. The cascade carries every referencing row with them.
--    NOTE the EN DASH (–, U+2013) in the three building-permit names: it is
--    what the admin portal uses, and a hyphen here is a different string that
--    the clients will not match.

update permit_types set permit_type = 'Building Permit – New Construction'        where permit_type = 'New Construction';
update permit_types set permit_type = 'Building Permit – Renovation / Alteration' where permit_type = 'Renovation';
update permit_types set permit_type = 'Building Permit – Addition / Extension'    where permit_type = 'Addition/Extension';
update permit_types set permit_type = 'Demolition Permit'                         where permit_type = 'Demolition';
update permit_types set permit_type = 'Architectural Permit'                      where permit_type = 'Architectural';
update permit_types set permit_type = 'Civil / Structural Permit'                 where permit_type = 'Civil/Structural';
update permit_types set permit_type = 'Electrical Permit'                         where permit_type = 'Electrical';
update permit_types set permit_type = 'Mechanical Permit'                         where permit_type = 'Mechanical';
update permit_types set permit_type = 'Sanitary Permit'                           where permit_type = 'Sanitary/Plumbing';
update permit_types set permit_type = 'Plumbing Permit'                           where permit_type = 'Plumbing';
update permit_types set permit_type = 'Electronics Permit'                        where permit_type = 'Electronics';
update permit_types set permit_type = 'Interior Design Permit'                    where permit_type = 'Interior Design';
update permit_types set permit_type = 'Fencing Permit'                            where permit_type = 'Fencing';
update permit_types set permit_type = 'Sign Permit'                               where permit_type = 'Sign';
update permit_types set permit_type = 'Excavation Permit'                         where permit_type = 'Excavation';

-- 3. Three genuinely new rows — the scope half of the ruling. These are
--    issued by the MPDC and the Bureau of Fire Protection, not the OBO, and
--    the citizen clients already have wizards for all three.

insert into permit_types (permit_type, service_domain) values
  ('Zoning / Locational Clearance',   'Construction Permit'),
  ('FSEC for Building Permit (BFP)',  'Construction Permit'),
  ('FSIC for Occupancy Permit (BFP)', 'Construction Permit');

commit;
```

`Certificate of Occupancy` already matches and is untouched.
`Business Permit` stays as it is — it is **not** one of the office's 19, and
the clients' legacy business-permit flow is a separate open question.

## The two judgement calls

* **`Sanitary/Plumbing` → `Sanitary Permit`.** The server has both
  `Sanitary/Plumbing` and `Plumbing`; the office has both `Sanitary Permit`
  and `Plumbing Permit`. Mapping them one-to-one is the only reading that
  leaves neither orphaned, but the office's own **form** is titled
  *"Sanitary Permit"*, so it is worth one look.
* **`Renovation` → `Building Permit – Renovation / Alteration`.** The office
  treats the three building-permit variants as one form with a scope, which is
  why its names share a prefix.

## Then the contract

`PermitType` in `openapi/ebpco.openapi.yaml` takes the same 19 values. They are
listed, generated rather than retyped, in `HANDOFF-D10-ruled.md`.

## How to know it worked

One command, from the mobile repo, against the running server:

```
flutter test test/live/all_permit_types_live.dart
```

It registers a citizen and files one application of **every** type the app
offers.

* **Today it prints `1 of 19`** — only `Certificate of Occupancy`.
* **After this migration it should print `19 of 19`.**

All eighteen refusals today share one cause, so there is no second layer of
problems behind them: this migration is the whole fix, and that script is how
to see it rather than believe it.
