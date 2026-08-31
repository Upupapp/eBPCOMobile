# eBPCO Mobile — closing sweep before the next release attempt

**Verdict: NOT CERTIFIED.** Unchanged from 28 August, and for a reason that
document could not have stated.

*Measured 31 August 2026 against this repository at `89b6000`, gated from a
**detached worktree at that SHA** — `flutter analyze` clean, 2152 tests passed,
0 layout overflows, 1358s — rather than from the working tree it was written
in. The admin line is unchanged at `e0925d9`.*

**Suite at publication: 2218 tests.**

*That second number is not decoration. §4 records a check that could not fail,
and its replacement asserts this line equals the figure `tool/verify.sh` last
measured. It fired within hours of being written — the wire-filing test added
twelve tests the same day, this line still said 2152, and the gate refused.
That is the behaviour the old one only claimed to have.*

*A note on dates. Everything in this repository stamped "1 September 2026" was
written on **31 August** and has been corrected. The datelines were a day ahead
of the clock, which is the sort of error a document about measurement should
not contain.*

---

## 1. The twenty gaps are still closed

Every artefact named in the 28 August gap register is present at `89b6000`.
`DocumentStatus`, `remarks`, `rejectionReason`, `partiallyPaid`, `orNumber`,
`expiryDate`, `CollectingAgency`, `supersededOrders`, `OrderOfPayment`,
`ContactVerification`, `PaymentAdjustmentRecord`, `ApplicationLineage`; the
three clearance wizards; the requirements catalogue; the eighteen bundled PDFs.
Nineteen permit types, asserted by `certification_claims_test.dart`.

Nothing regressed. That is the smaller half of this sweep.

## 2. The three blockers, re-measured

| | State on 31 August |
|---|---|
| **B-1** — a backend exists and is reachable by nobody | **Unchanged.** Backend lane |
| **B-2** — routes the app calls that do not exist | **Still open.** The app calls `POST /applications/{id}/documents/{documentId}/resubmit` at `http_applications_repository.dart:139`; the contract does not declare it, and no server implements it |
| **B-3** — the offline queue's two triggers | **Unchanged.** Both are owner decisions: a `connectivity_plus` dependency, and a background-execution entitlement |

## 3. What the August certification did not know

This is the sweep's real finding, and it is uncomfortable.

The 28 August document certified parity against the admin portal, vocabulary
for vocabulary, and closed twenty gaps. Every claim in it was true. In the four
days since, working through the front-end programme, **eight defects were found
that it could not see**, because none of them is a parity question:

| Found | Defect |
|---|---|
| 1 Sep | **Applications carried nothing the applicant typed.** `POST /applications` sent the permit type, the action and a site line. Up to 239 fields per filing — owner, lot, title, scope, cost, professionals, supervisor — were collected, validated, reviewed and dropped at the wire |
| 1 Sep | **Four of six Home promises led to screens that could render empty.** The promises are computed from list scalars; their destinations are guarded on detail objects the list may omit — and `fetchDetail` was uncallable because the interface never declared it, so every screen in the app ran on the list payload |
| 1 Sep | **Claim instructions rendered a heading and one unrelated paragraph** at `readyForRelease`, by contract design, behind an action item, a tab badge and a push notification |
| 31 Aug | **Permit conditions misstated the applicant's obligations** in nine wizards: an unconditional "shall" softened to "when required" in six, a ₱50,000 cash bond with a forfeiture rule reduced to *"larger excavations may require a cash bond"*, Article 1723 reduced to "remains professionally accountable", and a condition invented in four models that appears on no form |
| 31 Aug | **The Certificate of Occupancy wizard asked for five documents Castilla does not list** and lacked five it does — including the Certificate of Completion, which had no slot at all — and asked for an FSIC where Castilla asks for an FSCCR |
| 31 Aug | **The building permit demanded a Land Title** where the checklist accepts a deed, a lease or any valid proof — an applicant on leased land could not file |
| 30–31 Aug | **Every contact detail in the app was fabricated**, pointing at Quezon City and a Metro Manila landline for a Sorsogon municipality, printed as the channel for exercising RA 10173 rights |
| 30–31 Aug | **Drafts dropped every attachment**; there was **no privacy manifest**; documents **could not be uploaded** at all |

These are not regressions. They were all true on 28 August, under a green suite
and a signed parity certification.

**What they have in common** is that each sits at a seam a parity comparison
does not look at: between the wizard and the wire, between a promise and its
destination, between what a form says and what a screen repeats. Parity with the
admin portal was the wrong instrument for finding them, and it did not claim
otherwise — but a reader of that document would not have guessed how much was
left.

## 4. A gate that could not fail

Found while running this sweep, and the most important process finding in it.

`certification_claims_test.dart` carried a check called *"the test count it
quotes is the count of this suite"*, whose comment read:

> Read from the certification and compared against what `flutter test` reports,
> which is what `tool/verify.sh` prints. If this fails, the document is stale —
> update the number, do not delete the check.

It did not do that. It asserted `counted > 1400` — a constant. So the
certification could quote **1544** while the suite ran **2152**, and it did:
608 tests stale, four days, green throughout.

A gate that cannot fail for the reason it states is worse than no gate, because
it is read as evidence. This is the fourth time this repository has been bitten
by that shape.

Fixed properly: `tool/verify.sh` now writes the figure `flutter test` actually
reported to `test/contract/suite-count.txt`, and the check compares the
**Suite at publication** line above against that measurement — exactly, with no
tolerance, because a tolerance is how `> 1400` happened. It reads a labelled
line rather than the first number followed by the word "tests", so the dateline
can go on quoting the measurement taken at `89b6000` without the two claims
fighting. It also follows the **newest** dated
certification rather than a pinned filename — the other half of why it went
stale, since a new sweep could be written and the gate would keep reading the
old one.

## 5. Why still NOT CERTIFIED

The August reasons stand, and one more is now measurable.

**Nothing has ever been run against a server.** Both the August document and
this one record that. What the last four days show is the cost of it: every
defect in §3 sits between the wizard and the wire, and every one of them
survived a green suite because there was nothing on the other side to
contradict it. `form` was not sent, and no server complained. The detail
endpoint was never called, and no screen came back empty in a test, because the
fake repository returned the same object for both reads.

So the sweep's recommendation is narrower than "fix the list": **the next
release attempt should not be a release. It should be one filing, against a
staging server, watched end to end.** Everything found this week would have
been found in that one run, and cheaper.

## 6. What is open, by owner

**Backend lane.** B-1 (hosting, and who operates it); B-2 (the document
resubmission route); the `assessed`-with-no-Order-of-Payment contradiction, where
Home says fees are due and the screen says not yet available.

**Owner decisions.** B-3's two triggers; the Android and Linux halves of the
bundle identifier (M-29), which belong to the Windows lane; the App Store
Connect privacy label (M-50), which cannot be edited from here and is now stale
because the app began transmitting the wizard contents — the answers to
transcribe are written out in `docs/M-50-app-store-privacy-label.md`. M-51 — how the app gets its
typeface — was decided and closed the same day: Poppins is bundled and runtime
fetching is off, so the app no longer reaches `fonts.gstatic.com`.

**LGU.** The office's street address, its opening hours and a bring-with-you
list (M-11); the published Citizen's Charter per permit type (M-08); the
DPWH/JMC unified forms (M-10).

**This lane.** Nothing outstanding from the register. The excavation and sign
wizards' conditions — including the ₱50,000 cash bond — reached a screen on
31 August, on the final review step rather than through a cloned evaluation
step full of placeholder statuses.
