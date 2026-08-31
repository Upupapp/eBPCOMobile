# The first time this app spoke to a server

31 August 2026. The mobile app had never made a request to the eBPCO API in the
whole programme. It has now.

**Two blocking defects in the first ten minutes**, neither of which any gate on
either side could have found, because each lives in the gap between two things
that were separately correct. And two false alarms, which are recorded here
because their cause is worth more than the findings.

## Corrected 31 August, after the backend lane replied

Two claims in the first version of this document were wrong, and both were
wrong in the direction that flattered this lane.

**1. I did not stand up the server I tested against.** I started a PostgreSQL
instance on **5432** and ran 31 migrations into it — that part is true, and it
was my own database. But my API process never bound port 3000: it failed with
`EADDRINUSE` because the backend lane's instance was already there. `lsof`
settles it — port 3000 is held by a process started before this session's
attempt. **Every request below went to their server, backed by their database
on 5433.** The findings stand; the authorship did not.

Worse, it cuts the other way too: their runbook notes they chose 5433 because
"another agent's session already held 5432". **That agent was me.** They were
right to avoid it — running 31 migrations into someone else's database is
destructive, and they checked rather than assumed.

**2. `serviceDomain` is output, not input — and the client fix was harmful.**
See D-1 below, now rewritten. The server derives it from `permitType` and
returns it in the 201; sending it is a 400. The change this lane made on 30
August to *start* sending it would have refused every filing. That is corrected
in `http_applications_repository.dart`, and the gate that enforced it is
inverted.

**3. Account deletion exists.** Filed here as a certain App Store rejection on
the grounds that the contract declares no DELETE operation. `DELETE /me`
answers 202 and invalidates the session — measured. The contract is the stale
party, and the client now implements it.

## How it was reached

B-1 said "a backend exists and is reachable by nobody". That was true of
production and not of a laptop. Standing one up needed no hosting decision:

* **PostgreSQL 18** via `@electric-sql/pglite` + `pglite-socket`, serving the
  wire protocol on 5432 from the scratchpad. An unchanged `DATABASE_URL`
  connects; no Docker, no Homebrew, nothing added to any repo.
* `npm run migrate` — **31 migrations applied**.
* `npm run start:dev` with `OBJECT_STORE_DRIVER=filesystem` and
  `MALWARE_SCANNER_DRIVER=local`, both of which the service's own
  `.env.example` marks development-only and refuses in production.

`GET /ready` → `{"status":"ready","checks":[{"database":"up"},
{"objectStore":"up"},{"malwareScanner":"up"}]}`.

**No backend source was changed.** The only file written into `ebpco-api` was
`.env`, which is gitignored.

## What was exercised

The app's **own repositories** — `HttpAuthRepository`, then
`HttpApplicationsRepository` — not hand-rolled requests. That distinction cost
one false alarm and is worth recording: the first attempt posted `/auth/token`
directly, got a 400 for a missing `grantType`, and looked like a client defect.
It was not. The repository has sent `grantType: 'password'` all along. **A
hand-rolled request tests nothing the app does.**

## D-1 — `serviceDomain` travels the other way

```
POST /applications
{"serviceDomain":"Construction Permit", …}
→ 400  {"pointer":"/","message":"Unrecognized key(s) in object: 'serviceDomain'"}
```

The contract declares it **required** on `ApplicationSubmission`. The server's
submission schema is `.strict()` and does not declare it at all; it **derives**
the value from `permitType` and returns it in the 201. It is output.

This app was changed on 30 August to start sending it, on the reasoning that
the contract types the field and the client was not supplying it. That
reasoning was sound and the conclusion was wrong, because **the contract does
not say which direction a field travels** — and nothing but a real server can.

**Fixed here:** the key is no longer sent, and
`application_submission_test.dart` now asserts its absence, with the contract
divergence recorded rather than silently accommodated. `serviceDomainFor` stays
— it is still how this app labels a filing for its own screens.

**Left for whoever owns the contract:** the request schema still requires a
field the server rejects.

## D-2 — a precondition no client can satisfy

With `serviceDomain` removed, the body validates and the filing still fails:

```
→ 422  "This account has no applicant profile. Complete your profile before filing."
```

`submission.service.ts:132`, and the server has a test asserting it *"refuses
an account with no applicant profile, rather than inventing one"* — which is
the right call.

**There is no way to create one.** The contract has no `/applicants` route;
`/me` is **GET only**, with no PATCH or POST; and registration does not insert
an `applicants` row. So the sequence a citizen actually performs — register,
sign in, file — dead-ends at the third step, through any client, for everyone.

This is a hole in the contract rather than a bug in either implementation, and
it explains why nobody hit it: the server tests it by inserting the row
directly.

## Not a defect — and the reason it looked like one

The run also showed `authenticate()` returning **null** while the token was
issued and stored. Null is how this app says "those credentials were refused",
so it read as a citizen being told their password was wrong at the moment it
was accepted.

**It was the harness.** The `ApiClient` had been built without an `authToken`
provider, so `GET /me` went out unauthenticated, returned 401, and
`authenticate()` correctly reported null. `RepositoryFactory` builds it with
`authToken: _session.accessToken`; composed the same way, sign-in returns
`citizen.live@example.ph`.

That is the second false alarm this session, and both had one cause: **the
harness did not reproduce the app's own composition.** The first posted
`/auth/token` by hand and blamed the client for a `grantType` the repository
had been sending all along. A live harness that builds its own client tests
something the app never runs, and manufactures faults that cost someone a day.

Both are now written into the script as comments, next to the lines that
caused them.

## What this cost, and what it bought

An afternoon of operating someone else's service, no code written on either
side, and two defects that between them mean **no citizen could have filed a
permit through this app** — after a week in which every gate was green, 2,218
tests passed, and the write path was asserted over a socket against a stub that
answered from the contract.

The stub was right about the contract. The contract is wrong about the server.


---

# The filing succeeded — 31 August, later the same day

D-10 is ruled but the seed has not moved, so eighteen of the nineteen permit
types are still refused. **`Certificate of Occupancy` is spelled identically in
both vocabularies**, so it files today — and using it measured everything past
submission without waiting for anything.

Through the app's own repositories, end to end:

```
register                          202
sign in                           user + token
GET  /me                          200
POST /applications                201  E-BPCO-2026-000005
GET  /applications                1 row, parsed
GET  /applications/{id}           parsed
```

**`serviceDomain` comes back in the 201**, derived from `permitType`, which is
the backend lane's account of it confirmed rather than taken on trust. **`form`
comes back in the detail response**, so the wizard's field set is stored and
returned, not merely accepted.

## What the round trip found

Diffing the server's response keys against the ones `ApplicationDto.parse`
actually reads: **six fields are served and ignored.** Five are deliberate and
recorded. One was not worth the omission.

**`location`.** The app has sent the site line on every filing since 31 August
and had no field for it coming back. So a citizen opening their own application
saw the permit type, the reference number and the status — **and not where the
work was.** The office knew; their own record did not say.

It is now on `ApplicationModel`, parsed by the DTO, and shown as a **Site**
section on the detail screen.

### How it hid, which is the part worth keeping

**It was already recorded.** `response_bodies_test.dart` has listed `location`
among "six declared fields mobile never reads" since that gate was written —
read from the contract, agreed to on paper, and wrong. The gate was doing
exactly what it was built to do and could not have caught this, because it
asked *"is this omission deliberate?"* and never *"what does the omission
cost?"*

Seeing the field come back in a real response made the answer obvious in a way
the schema never did. **A list of accepted omissions is worth keeping and worth
re-reading against something real.**

## Left as an observation, not a change

`requiresApplicantAction` is served by the server and computed independently by
the client from `lifecycleStatus` and `openInstructionCount`. They agree today
because they are computed from the same inputs. Two authorities for one fact is
a risk rather than a defect, and the client's derivation is deliberate,
documented and tested — so it is recorded here rather than quietly switched.
