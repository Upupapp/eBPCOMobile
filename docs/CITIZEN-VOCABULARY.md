# "Citizen" — what changed, and the three things that did not

Owner ruling, 31 August 2026: *"lets use citizen from now on for citizen,
business owner and applicant."* The system has three user types — **PUBLIC** on
the website, **CITIZEN**, and **ADMIN** with sub-roles by accessibility.

## What the sweep found

**2,989 lines in `lib/` mention "applicant"**, 104 of them inside string
literals. The obvious way to obey the instruction — replace the word — would
have broken the app in three separate ways, so the sweep classified before it
changed anything.

| Category | Count | Verdict |
|---|---|---|
| Draft snapshot keys (`applicant.firstName`, …) | most of the 104 | **Frozen** |
| NBC form labels ("Applicant Information", "Applicant Address", …) | ~45 occurrences across 19 wizards | **Frozen** |
| Quoted sources (the checklist's ownership clause, the RA 9514 citation) | 2 | **Frozen** |
| The app's own voice — wizard subtitles and status prose | 13 files | **Changed** |

## Why three categories are frozen

**Snapshot keys are a storage surface and a wire surface.** They are what a
saved draft is written under, and — since `form` began being sent on submission
— what the Office of the Building Official receives. Renaming one orphans every
draft on every device *and* changes the field names arriving at the office. The
rule stands: rename Dart fields, never these keys.

**Form labels are the whole point of the field-parity work.** The wizards
mirror the Municipality's own forms box for box, verified field-for-field on 31
August against the bundled PDFs. The forms say **APPLICANT**. A citizen holding
the paper form and the phone should see the same words in the same order;
changing one side breaks the thing that audit was for.

**Quoted sources are transcriptions.** *"Or, if the applicant is not the
registered owner: Deed of Sale, Deed of Donation, Lease Contract…"* is the
checklist's sentence, not ours.

## What changed

Where the app **spoke about the person in the third person while addressing
them**, it now uses second person — which is better copy than any noun would
be, and is what the ruling is really after:

| Before | After |
|---|---|
| "Tell us about yourself so we can identify the applicant." | "…so we can identify you." |
| "Provide the applicant details for the Fencing Permit." | "Provide your details for the Fencing Permit." |
| "Provide the applicant address and location of the electrical work." | "Provide your address and the location of the electrical work." |
| "Confirm the applicant and lot owner information." | "Confirm your details and the lot owner's." |

Eight address prompts, three detail prompts, two confirmations, one
introduction.

And where the app **describes the person to someone else**, it says citizen:
the timeline remark an evaluator reads is now *"Corrections resubmitted by the
citizen."*

## Second person, not "citizen", inside the wizards

Worth stating because it looks like a dodge and is not. "Provide the citizen
details for the Sign Permit" is bad English, and the app is talking **to** that
person. `you`/`your` is the accurate and natural form, and it stays correct
whoever is at the keyboard — the account holder is the applicant, whether or
not they own the building, which is exactly what the wizards go on to ask.

"Citizen" is the right word for the **user type**: in architecture, in
permissions, in prose about the system, and in anything an ADMIN reads.

## The gate

`test/features/citizen_vocabulary_test.dart`, 6 tests. Three assert the
rewording landed and that **no wizard subtitle still names the applicant** —
scanned, not listed, so a new wizard cannot reintroduce it. Three assert the
frozen categories are still frozen: a snapshot key still reads
`applicant.firstName`, the form-mirroring labels still appear more than twenty
times, and the checklist's ownership clause is still quoted verbatim.

Falsified by renaming `applicant.firstName` to `citizen.firstName`: the frozen
guard goes red and names the consequence.
