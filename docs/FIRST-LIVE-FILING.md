# The first time this app spoke to a server

31 August 2026. The mobile app had never made a request to the eBPCO API in the
whole programme. It has now.

**Two blocking defects in the first ten minutes**, neither of which any gate on
either side could have found, because each lives in the gap between two things
that were separately correct. And two false alarms, which are recorded here
because their cause is worth more than the findings.

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

## D-1 — the server refuses the field the contract requires

```
POST /applications
{"serviceDomain":"Construction Permit", …}
→ 400  {"pointer":"/","message":"Unrecognized key(s) in object: 'serviceDomain'"}
```

The contract declares `serviceDomain` **required** on `ApplicationSubmission`.
The server's schema does not have it at all, and rejects it as unrecognised.
Drop the key and the body validates.

This app was changed on **30 August specifically to start sending it** — the
gate `application_submission_test.dart` asserts it is required, because a
conforming server would refuse a filing without it. The opposite is true of the
server that exists.

**So every application this app files is refused, and would have been refused
by the change that was made to make filing work.** Contract or server must
move; the client is following the contract and should not move first.

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
