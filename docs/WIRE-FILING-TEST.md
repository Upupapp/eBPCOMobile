# One filing, watched over a socket

31 August 2026. The closing sweep recommended *"one filing against a staging
server, watched end to end"*, on the grounds that every defect found that week
lived between the wizard and the wire and survived a green suite because
nothing on the other side could contradict it.

**A staging server is blocked on B-1. A socket is not.**

`test/contract/wire_filing_test.dart` binds a real `HttpServer` on the loopback
interface, points the real `ApiClient` at it, files through the real
`HttpApplicationsRepository`, and inspects the bytes that actually arrive.
Twelve tests, covering the write path and the read path.

## Why the existing gate was not this

`application_submission_test.dart` has caught four divergences and is a good
gate. It is also a **source scan**: it opens
`http_applications_repository.dart`, runs a regular expression over the body
literal, and compares the quoted keys against the vendored schema.

That cannot see:

* **a header** — and `Idempotency-Key` is required on eight operations. A
  missing required header is the third divergence class, invisible to any
  body-diff gate;
* **a serialisation** — whether `businessId: ''` becomes `null` or `""` on the
  wire;
* **a response** — whether what the office sends back parses into a record at
  all;
* **a sequence** — whether the list read and the detail read are two different
  requests, which is the whole of the fault fixed the same day.

It asserts what the source looks like. This asserts what happens.

## What it would have caught

Each of these shipped, and each is now asserted over a socket:

| Defect | Shipped until |
|---|---|
| `serviceDomain` absent — a conforming server refused every filing | 30 Aug |
| `businessId` sent as `''` where the contract types a uuid or null | 30 Aug |
| `Idempotency-Key` never sent | 30 Aug |
| `location` absent — the office knew the permit type and not the site | 31 Aug |
| `form` absent — **no filing carried anything the applicant typed** | 31 Aug |
| The detail read never made, so every screen ran on the list payload | 31 Aug |

## The read path

Three of the twelve tests exercise the summary-versus-detail split directly,
because that is where the promises are cashed.

The stub answers `GET /applications` with a row carrying `openInstructionCount:
3` and **no** `instructions` array — which a conforming server is entitled to
do, since every sub-object is optional on the shared schema. The test asserts
that the parsed record therefore has `openInstruction == null`, which is
precisely the state in which Home promised *"3 items must be corrected"* and
the banner that routes to the letter did not render.

Then `GET /applications/{id}` answers with the letters, and the test asserts
they arrive and parse. Then it asserts the two are **different requests to
different paths** — the thing that was not happening at all, because
`fetchDetail` was undeclared on the interface every caller holds.

## Falsified

* Removing `'form': ?form` from the request body → *"the applicant's answers
  arrive"* fails.
* Removing `'Idempotency-Key'` from `ApiClient` → *"the required header
  arrives"* and *"a fresh filing gets a fresh key"* both fail.

The first test in the file is a vacuity guard: everything else reads
`stub.received.single`, so a repository that threw before sending would make
them all pass against nothing.

## What this is not

It is not a staging run. The server on the other end is a stub that answers
from the contract, so it proves the app is **self-consistent with the
contract** — not that a real backend agrees with the contract, or exists. B-1
is unchanged and the closing sweep's recommendation still stands.

What has changed is the cost of the next real defect at this seam: it now has
to get past a test that watches the wire rather than the file.
