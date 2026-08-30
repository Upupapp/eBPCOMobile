# The promise and its destination — a sweep

31 August 2026. Prompted by M-11, where the app sent an applicant to a
section headed *Claim instructions* that rendered a heading and one unrelated
paragraph. The question this sweep asked: **where else does the app promise
something and navigate to a place that can be empty?**

It found one root cause under four of the six promises, which is a better
answer than six fixes.

## The promises

Six action items on Home, four banner branches on the detail screen, and the
deep links from push notifications.

| Promise | Destination | Verdict |
|---|---|---|
| "Letter of Instruction issued — 3 items must be corrected" → *View instructions* | detail screen → banner → `/instructions` | **Defect** |
| "Revision required" → *See remarks* | detail screen → banner | **Defect** |
| "Order of Payment ready" → *View Order of Payment* | `/pay` | **Defect**, plus a contradiction |
| "Permit ready to claim" → *Claim instructions* | detail screen → banner → `/permit` | **Defect** (M-11 was its second half) |
| "Permit expiring" → *View permit* | detail screen | Same cause |
| "Renew permit" → wizard | `/renew` | Sound — no data guard |

## The one cause

**The promise and the destination are fed by different payloads.**

The Home action stack is computed from **scalars a list payload carries** —
`openInstructionCount`, `lifecycleStatus`, `permitNumber`. So the promises
appear reliably.

Everything they point at lives in **sub-objects a list payload may omit** —
`instructions`, `evaluations`, `permit`, `release`, `inspection`, `payment` —
and every one of those is behind a null guard on the destination.

The contract is explicit that these are two different reads. `GET /applications`
returns a page; `GET /applications/{applicationId}` is described as *"One
application **in full**. Carries the timeline, evaluations, open Letters of
Instruction, inspection, permit, release and payment."* The sub-objects are
optional on the shared schema, so a conforming list may omit all of them — and
`ApplicationDto.parse` already said so in its own comment: *"a summary payload
may omit the letters themselves"*.

**The app never made the second read.** `HttpApplicationsRepository.fetchDetail`
was written when that class was written, and nothing could call it: callers
hold `ApplicationsRepository`, and the interface did not declare the method. It
sat there, correct and unreachable, while every screen in the app was built
from the list.

So an applicant could be told *"3 items must be corrected or supplied"*, tap
**View instructions**, and arrive at a screen with no letter, no banner and no
route to one — while Home went on saying three items needed correcting.

## The fix

`fetchDetail` is declared on the interface, `ApplicationsProvider.loadDetail`
replaces the summary record with the full one, and **`ApplicationDetailGate`
wraps all five routes at the router**.

At the router rather than in the screens, because four of those five — the
letter, the permit, the outcome and the Order of Payment — are reachable
**directly from a push notification's deep link**, without passing through the
detail screen. A fetch on the detail screen alone would have left four ways in
uncovered, which is the same tested-pieces-untested-wiring shape this repo has
been caught by three times.

Failure is silent by design: the summary stays on screen, which is what the
applicant had, and the id never enters `_detailed`, so the next visit retries.

## What was already sound

* **The detail action banner hides its action label when it has no route.**
  `actionLabel` is only rendered inside `if (onTap != null)`, so the
  revision-required branch — which has no destination — shows text and no dead
  button.
* **The Order of Payment screen has a real empty state**, explaining that fees
  are assessed after evaluation, rather than a blank page.
* **The banner falls back to a plain sentence** when an evaluator's remarks are
  missing, rather than showing an empty quote.

## One thing left open

The Order of Payment promise and its destination **contradict each other** when
the assessment is missing. Home says *"Fees have been assessed and are now
due"*; the screen says *"Not yet available — fees are assessed after your
documents pass evaluation."* The gate now fetches the detail on that route, so
the common case resolves; but if the office moves an application to `assessed`
before issuing the Order of Payment, the applicant reads two opposite
statements. Which of the two is wrong is a question for the backend lane —
filed, not guessed.

## The gate

`test/features/applications/detail/summary_to_detail_test.dart`, 5 tests: the
screen asks for the full record; the promised letter becomes reachable; without
the fetch it does not; it is fetched once rather than on every rebuild; and a
source scan that **all five routes are built inside the gate**, checking the
gate is the wrapper rather than merely present somewhere above in the file.

Falsified by unwrapping the Order of Payment route — the router scan goes red.
