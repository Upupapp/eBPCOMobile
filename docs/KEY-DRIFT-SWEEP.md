# String keys written in one place and matched in another — a sweep

31 August 2026. Prompted by the sign-out defect: `SessionCleaner.kept` held
`'onboarding_completed'` while the app writes `'onboardingCompleted'`, so the
allow-list did not protect the key it was named for and every sign-out sent a
returning applicant back through the three-page introduction.

The question this sweep asked: **where else does one part of the code write a
string that another part has to match, with nothing connecting the two?**

## The five key surfaces in this app

| Surface | Result |
|---|---|
| **Preference keys** | **Clean in `lib/`** — every read and write goes through `AppConstants`; there is not one literal preference key in production code. The drift was in the *cleaner's* allow-list and in the *test fixture*, both now on constants |
| **Secure storage keys** | Clean — every call passes a private `static const`, never a literal |
| **Draft storage keys** (`permitKey`) | Clean — 19 wizards, 19 distinct keys, no duplicates, and nothing compares against a literal. A collision here would restore one wizard's draft into another |
| **Snapshot field paths** | Frozen by design and now a **wire** surface as well as a storage one, since `form` is sent on submission. Guarded by the round-trip tests |
| **Route paths** | **Clean — and now gated.** 80 navigation targets, 77 declared routes, no mismatch |

## Why routes were worth gating

A misspelled route is the same defect wearing different clothes, and the cost
lands on the same person. The Home action stack tells an applicant *"3 items
must be corrected"* and sends them somewhere; if that string and the router's
disagreed by one character they would arrive nowhere, and the only evidence
would be an applicant unable to act on their own application. That is the
promise-and-destination fault from `PROMISE-DESTINATION-SWEEP.md`, reached by a
typo instead of a missing fetch.

`test/architecture/route_targets_test.dart` reads both sides from source —
`path:` declarations from `app_router.dart`, and `context.push/go/
pushReplacement` targets from every file under `lib/` — normalises parameters
and interpolations to one shape, and asserts every target is declared. It also
asserts no path is declared twice, since the second declaration of a duplicate
never runs.

**Two false positives found it before it found anything**, and both are worth
recording because they are how a scanner like this lies:

* **Adjacent string literals.** Dart concatenates `'/charter/'` and
  `'${...}'` written on consecutive lines. A scanner reading one literal at a
  time sees a route ending in a slash and reports a defect that is not there.
* **Query strings.** `/applications/pre-flight?permitType=…&next=…` is the
  route `/applications/pre-flight`; the query is not part of what go_router
  matches.

Both are handled, and both are commented in the test, because the next person
to extend it will hit them again.

## The rule that comes out of it

**A deny-list that misspells a key fails loudly** — the thing you meant to
remove stays, and you see it. **An allow-list fails by forgetting**, quietly, in
a path nobody watches. So wherever one side of a boundary writes a string and
the other matches it, take the spelling from the same constant, and gate the
pair.

## Cross-lane

The admin portal, the business-owner web portal and the website each have their
own storage keys, their own route tables and their own sign-out. **Not audited
here** — they are other lanes ([[ebpco-web-frontend-only]]). This is filed so
those lanes can run the same five checks; the routes one is a fifty-line test.
