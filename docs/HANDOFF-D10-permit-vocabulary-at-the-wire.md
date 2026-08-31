# D-10 — the server issues none of the permits this app files

From the mobile lane, 31 August 2026. **The vocabulary divergence, measured at
the wire for the first time.** It has been reasoned about from documents since
M-47; it has now been refused by a running server.

## What happens

A freshly self-registered citizen, filing a fencing permit through the app's
own repository:

```
POST /applications
{"permitType":"Fencing Permit","applicationAction":"New", …}

422  "The LGU does not issue a \"Fencing Permit\" permit."
```

`db/migrations/002_reference.sql` seeds `permit_types` with **17 short names**:

```
New Construction · Renovation · Addition/Extension · Demolition ·
Architectural · Civil/Structural · Electrical · Mechanical ·
Sanitary/Plumbing · Plumbing · Electronics · Interior Design ·
Fencing · Sign · Excavation · Certificate of Occupancy · Business Permit
```

The app sends **19 long names** — `Fencing Permit`, `Architectural Permit`,
`Building Permit – New Construction`. **Only `Certificate of Occupancy` is
spelled the same in both**, so 18 of 19 permit types are refused. The one that
would go through is the one nobody files first.

## Why the client should not be the thing that moves

The app's vocabulary is not its own. It is extracted **mechanically** from the
admin portal — `scripts/extract_admin_vocabulary.mjs` reads
`src/app/core/domain/` and vendors the result at
`test/contract/admin-vocabulary.json`, and a standing gate asserts this app
against it value for value and in order.

The admin portal is the Office of the Building Official's own system, and those
19 names are the office's own words. So the disagreement is not
mobile-versus-server; it is **the office's vocabulary versus the contract's**,
with mobile on the office's side by construction.

Changing the client would break the admin-parity gate and re-open every lookup
keyed on the office's names — the defect TAB 12 closed.

## What would settle it

Someone with the authority to say which list is canonical. If it is the
office's 19, the `permit_types` seed and the contract's `PermitType` enum both
move, and mobile does nothing. If it is the contract's 17, the admin portal
moves first and mobile follows it, as it always has.

**What must not happen is a cast in the middle.** The admin already casts
between the two vocabularies unchecked (recorded as the two-vocabularies
finding); adding a second silent mapping on the mobile side would make three
spellings and no authority.

## Two notes from the same session

**D-9 is closed, and it was already closed before I re-tested it.** A fresh
self-registered account now gets past the applicant-profile check — the insert
is in `postgres-account.repository.ts:82`, in the registration transaction,
with the comment that says why: *"An account without a profile is an account
that exists and cannot act."* My report that registration creates no
`applicants` row was true when measured and is not true now.

**An unreproduced 500.** One `GET /applications` for a freshly registered
citizen returned 500; two subsequent attempts with fresh accounts returned 200.
Recorded as observed-once, not as a defect — a single observation of a
transient is not a finding, and the local Postgres bridge serves one connection
at a time, which is a plausible cause that has nothing to do with the server.
