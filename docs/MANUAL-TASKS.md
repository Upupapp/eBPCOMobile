# Master TODO — Manual Tasks Only

Items here **cannot be completed by the coding agent**. They need a human,
production access, an external party, or a decision that is not mine to make.
Anything I can do locally is not listed here — it is done, or it is in the TAB
backlog.

Last updated: 20 August 2026 — TAB 21, the closing readiness review. The register below is now a subset of
a larger programme: see `docs/eBPCO-Production-Master-Command.pdf`, which maps every
item here onto one of 21 TABs and adds the backend work none of these items covered.

**That finding is now closed.** When this list was written there was no backend at
all: the admin made zero HTTP calls, mobile targeted a contract it had invented, and
the two had never been compared. There is now a backend of record with 41 routes, a
contract enforced by automated check against recorded server responses, and both
clients verified against it. M-02 and M-21 are closed below.

**What replaces it as the framing:** nothing has been deployed. The verdict of the
TAB 21 readiness review is **NOT CERTIFIED**, and the single item blocking the most
is E-1/M-27 — hosting and who operates it. See
`ebpco-api/docs/READINESS-REVIEW.md` for the scoring and the critical path.

---

## Blocking for any pilot with real applicant data

| # | Task | Why manual | Raised in |
|---|---|---|---|
| M-01 | Move authentication to a server-issued session token held in the platform keychain/keystore | Needs an auth backend to issue tokens. **Partially closed in TAB 5**: the password is no longer stored at all (PBKDF2 verifier + salt), so nothing recoverable remains on disk. What is left is genuinely server-dependent | TAB 1 · §10.1 |
| M-31 | **Run both clients against a deployed server.** Mobile takes `EBPCO_API_BASE_URL` at build time and defaults to mock; the admin reads a `window` global. Both switches exist and neither has ever been thrown, so no client has spoken to the server. This is the single largest available reduction in risk | Needs a deployed environment |
| M-32 | **Replace the two columns that store secrets unencrypted under an encrypted name** — `devices.push_token_encrypted` and `accounts.totp_secret_encrypted`. Both hold their bytes unchanged because no key-management service has been chosen. Recorded rather than described as encryption, and must not ship as is | Blocked on E-1 |
| M-33 | **Commission a penetration test and assemble the ASVS L2 / MASVS evidence packs.** Needs a deployed target | External party |
| M-34 | **Load, spike and soak.** `DB_POOL_MAX`, `RATE_LIMIT_MAX` and both shutdown timings are reasoned defaults, not measured ones | Needs a deployed environment |
| M-35 | **Wire log aggregation and alerting**, starting with `scheduled_jobs.consecutive_failures` and readiness. Both are recorded and nothing watches them, so a job failing for a week looks like one that is working | Needs a deployed environment |
| M-36 | **Write and rehearse a backup and restore procedure.** An untested restore is not a backup | Needs a deployed environment |
| M-02 | Stand up the backend for the admin-authoritative fields — `lifecycleStatus`, `classification`, `openInstructionCount`, Orders of Payment, evaluations, Letters of Instruction, inspections, release records | Server-side work. **The client is now built and tested against the §7.2 contract** (`lib/core/api/`), so this is the server half only. See M-21 for the endpoints it expects | TABs 1–3 |
| M-21 | **Confirm or correct the assumed API contract.** The client is now wired and will call these the moment a base URL is supplied: `GET /applications`, `GET /applications/:id`, `POST /applications`, `POST /applications/:id/payments`, `POST /applications/:id/instructions/:letterId/resubmit`; bearer-token auth; the §7.2 JSON shape with admin-vocabulary enum labels and fees as integer centavos. **Every one of these is my assumption, not an agreed contract** — treat this as a proposal to review, not a spec to build to | API layer |
| M-22 | Decide the token storage and refresh mechanism. `LocalStorageService.sessionToken()` is the read point and returns null today, so the client sends no Authorization header. Note it currently reads SharedPreferences, which is **unencrypted and not where a session token belongs** — see M-01 | API layer |
| M-03 | NPC-compliant privacy notice text and retention policy, reviewed by counsel | Legal text under RA 10173. TAB 5 ships a plain-language disclosure and working access/correct/export/delete controls; the formal notice still needs review | TAB 5 |
| M-16 | Publish the LGU's Data Protection Officer contact so applicants can exercise rights over what the LGU holds | LGU-specific; the Privacy & Data screen currently names the role without contact details | TAB 5 |
| M-17 | Raise the PBKDF2 iteration count and move derivation off the main isolate | Needs device profiling on the target mid-range Android hardware | TAB 5 |
| M-18 | Run the app on a physical mid-range Android device on a throttled connection | X4 verifies text scale, touch targets, and screen-reader labels under test; real-device performance cannot be asserted in a widget test | §11 · X4 |
| M-19 | Confirm colour contrast meets WCAG AA against the brand palette | Needs a contrast audit tool against rendered output; the palette is fixed by brand and any failure is a brand decision, not a code fix | §11 · X4 |

## Repository and delivery

| # | Task | Why manual |
|---|---|---|
| M-04 | ~~Push `main` to **`https://github.com/Upupapp/eBPCOMobile`**.~~ **DONE 28 August 2026 — the owner authorised it and it was run from here.** 81 commits, initial push to an empty public repository, `origin/main` now at `b25f2a7`. Two things recorded rather than assumed, because both changed how the push was run: the repository was **empty**, so there was no upstream to merge and the standing five-step procedure collapsed to sweep, test, push; and it is **public**, so the full history was swept for credentials first — credential-shaped filenames in the tree and in all 81 commits, secret-shaped strings across the whole history, assignment-shaped secrets in source, real personal data in the seed fixtures, and the 18 bundled LGU PDFs, which are blank official forms already published in the public `Upupapp/eBPCO-Web` and so added no exposure. Nothing is tracked under `.github/workflows/`, so no CI can fire on push | Closed by the agent on explicit authorisation. `.gitignore` carries no key/env/secret coverage — worth adding before anyone commits a signing artefact |
| M-05 | Decide whether to keep or revert the `analysis_options.yaml` / `pubspec.lock` changes `flutter pub get` made on the SDK bump | Owner call on toolchain policy |
| M-06 | Remove or relocate `flutter_01.png` … `flutter_06.png` at the repo root | Owner call; they are project artefacts, not mine to delete |
| M-07 | Authorize the `claude.ai` and `Canva` MCP connectors | Requires an interactive OAuth flow this session cannot run |

## Requires an external party or authoritative document

| # | Task | Why manual |
|---|---|---|
| M-08 | Supply the LGU's Citizen's Charter entry per permit type — classification, pledged days, fee schedule, requirements | LGU-published data; must not be invented |
| M-09 | Confirm which payment channels the LGU formally accepts before any e-wallet is added | Offering an unaccepted channel would strand an applicant's money |
| M-10 | Provide the Unified Building Permit Application Form and Unified Application Form for Certificate of Occupancy so wizard fields can be audited field-for-field | Needs the actual DPWH/JMC forms |
| M-11 | Supply the LGU's claim location, office hours, and bring-with-you list for permit release | LGU-specific operational detail |
| M-12 | Amend the holiday calendar when Eidul Fitr and Eidul Adha 2026 are proclaimed, and again for the 2027 proclamation | Proclamations are issued during the year; dates cannot be derived |

## Known unbuilt scope

| # | Item | Status |
|---|---|---|
| M-24 | **Appointment booking** (§3.1 benchmark) | Not built and not in the §7.1 screens table, so arguably out of scope. QC e-Services treats a confirmed online appointment as the *first* basic requirement, so if this LGU does the same it belongs in TAB 2 |
| M-25 | **Share-sheet export.** Payment history exports to the clipboard as CSV, which pastes into a spreadsheet or an email. A real share sheet or file save needs a platform plugin (`share_plus`) this app does not carry — a deliberate omission, not an oversight | Adding a plugin is a dependency decision |
| M-26 | **Confirm the CSV export is fit for purpose.** Format was my call: CSV over a PDF receipt, since the destination is almost always a spreadsheet or an accountant. If applicants actually want a printable receipt, this needs redoing | Product decision |

## Raised by the second 19 August sweep

| # | Decision | Why yours |
|---|---|---|
| M-39 | **Are the four dormant subsystems staged or forgotten?** `CertificatePinner`, `SessionManager`, `SyncEngine`, and `OfflineQueue` are built and tested but called by nothing — `ApiClient` holds a plain `http.Client`, so there is no certificate pinning in effect. Very likely deliberate, since pinning needs the real host's certificate and sync needs a server; but nothing in the repo says so, and dormant security code reads as protection that is not there. Android lane's code to answer for; the pinning half also waits on M-21 | Other lane's code, and depends on the backend |

## Raised by the 19 August front-end sweep

| # | Decision | Why yours |
|---|---|---|
| M-37 | **Rename in the other lane.** The ruled name has not been applied to the monorepo's `docs/README.md` or the web admin's `auth-layout.html` tagline, both of which still say "Electronic Business Permit and Clearance Office". Out of scope here under the mobile-only rule | Different repository |
| M-38 | ~~Accept or reject dropping iOS 13 and 14~~ — **CLOSED 19 Aug 2026, not a decision.** Flutter 3.47's `ios_deployment_target_migration` rewrites any target below 15.0 on every build; it is the SDK's floor, not a plugin's. Holding 13.0 would mean downgrading Flutter. No device is lost — iOS 15 runs on every iPhone that ran iOS 13 (6s and later); only users who declined a free OS update are affected | Closed, no action |

## Product decisions I have deliberately left open

| # | Decision | Why yours |
|---|---|---|
| M-13 | Localisation: implement Filipino (and which other languages), or reduce the picker to what is supported | Scope and budget call. **Still open** — the Language screen remains display-only |
| M-14 | Whether applicants may cancel their own application | Policy question with regulatory consequences |
| M-15 | Retention period for uploaded documents after an application closes | Data-minimisation policy under RA 10173 |

---

## Raised by the 19 August 2026 sweep

| # | Task | Why manual |
|---|---|---|
| M-27 | **Decide the backend technology, hosting, and who operates it.** Master Command decisions E-1 and E-2. Constrained by the LGU's procurement rules and the DICT Cloud First Policy, not by engineering preference | Owner and LGU call |
| M-28 | **Establish production Android signing keys.** `android/app/build.gradle` still signs release builds with the debug key and carries the generated TODO. A key set up late cannot be changed later without every user reinstalling — this blocks even internal pilot distribution | Requires key custody decisions and a Play publisher account |
| M-29 | **Confirm final bundle identifiers.** `com.ebpco.ebpco_user_app` / `com.ebpco.ebpcoUserApp` are development placeholders. They cannot be changed after publication without losing the listing | Owner call; likely LGU-branded |
| M-30 | **Resolve the uncommitted iOS project changes.** `ios/Runner.xcodeproj/project.pbxproj` is modified and two SwiftPM `xcshareddata` directories are untracked. Not mine to commit or discard without knowing whether they were intentional | Owner call |
| M-40 | **Decide whether to `dart format` the whole tree, and when.** The repo is not formatted to the current `dart format` style: running it over `lib/` rewrites ~230 files, most of them the Android lane's. Doing it needs both lanes to land it at the same moment or it becomes an unmergeable diff. Until then, format single files only | Needs coordination between the iOS and Android lanes |
| M-41 | ~~Decide whether to raise the 1.3x text-scale clamp.~~ **DONE 24 Aug 2026 — raised to 2.0x.** It turned out to be actionable rather than a judgement call: the clamp's own comment named three things built for 1.0x, and two were already fixed and guarded. The third — the bottom navigation bar — was clipping "Applications" at 2.0x on a 320dp screen, silently, on every primary screen. Fixed, then the clamp was raised. The ceiling now lives in `TextScaleClamp.maxScale` with a test tying it to what the accessibility suites render at | Closed by the agent; worth a look on a real device at 200% before release |
| M-42 | ~~Decide what "View Application" should do on the submitted screens.~~ **DONE 24 Aug 2026 — and the premise was worse than recorded.** There was no id to pass because the sixteen permit wizards were not creating an application at all: submit flipped the wizard's own draft status and navigated, and `ApplicationsProvider` — the only thing the applications list reads — never heard about it. The applicant submitted and found their list as empty as before, with no notification either. Wizards now record the submission; "View Application" opens it | Closed by the agent. `businessName` carries the applicant's name for a construction permit, which the backend should confirm |
| M-43 | **Provide the document-resubmission route.** The app offers a Replace action on any document the office rejected or sent back, and posts to `POST /applications/:id/documents/:documentId/resubmit`. **That route still does not exist**, and resubmission works against the mock only, failing loudly on a live build rather than reporting a success that did not happen.<br><br>**Diagnosis, 28 Aug 2026 — the earlier "CLOSED" was wrong.** It matched `POST /applications/:id/instructions/:letterId/resubmit`, which exists and is the *Letter of Instruction* loop. These are different operations: a document can be rejected with remarks when no letter exists at all. `~/ebpco-contract/tools/verify.sh` has reported the gap throughout.<br><br>**Owner's design decision, 28 Aug 2026:** a document is turned back **on its own record**, carrying a **standard reusable reason** *and* **custom feedback** — not only through a Letter of Instruction.<br><br>**Do not widen `documents.status`.** It belongs to the malware scanner (`applyVerdict` writes `status='Rejected', scan_cleared=false`; `retrieve()` refuses bytes on that value). The review needs its own columns, or an officer's rejection makes a file unretrievable as though it carried a virus. A worked schema encoding this — review columns, a `document_review_reasons` catalogue, an adverse-verdict-must-say-why constraint, and a supersession chain — sits **unpushed** on `~/ebpco-api` as `8d83860`, written before the front-end-only rule was stated. **The backend developer's to take, amend or drop.** | Backend lane, and NOT this one — see the mobile front-end-only rule |
| M-44 | **Carry the renewal / amendment reference on the wire.** The app now files renewals and amendments with the action the contract already carries (`applicationAction: New \| Renewal \| Amendment`) and a local record of *what* is being renewed or amended. Neither the admin's `ApplicationRecord` nor the contract's `POST /applications` body has a field for that reference, so it is deliberately not sent: an undeclared field against a strict server fails the whole submission, costing the applicant their filing to gain a field the office cannot read. The office therefore receives "this is a renewal" without "of permit BP-2026-000145". Needs `priorApplicationId` and `priorPermitNumber` on the contract, the admin model, and the portal's intake view | Backend + admin lanes; contract change, so a version bump |
| M-45 | **Send and check the verification link and the one-time code.** The app now shows per-channel contact verification with the admin's four statuses, offers the two applicant-driven methods, queues a request that fails on a dropped connection, and records a rejected code as `Verification Failed` with the office's reason. Neither half of the actual verification can be done here: a code this app generated and then checked against itself would verify nothing except that the applicant can read their own screen. So `MockContactVerificationRepository.confirm` throws rather than returning `verified`, and the screen says the office has not switched this on. Needs the send and confirm endpoints, plus `POST` for the queued `contactVerificationRequest` operation | Backend lane; also a product decision — whether verification ever becomes a precondition for filing is deliberately left open |
| M-46 | **Provide the app's `PrivacyInfo.xcprivacy`.** Measured 29 Aug 2026: the manifest exists only inside third-party bundles (`flutter_secure_storage_darwin`, `TOCropViewController`, `SDWebImage`); the app has none. Apple rejects an app that uses required-reason APIs without one, and this app does — `shared_preferences` (UserDefaults), `path_provider`, file access. Deliberately not drafted by the agent: the manifest's `NSPrivacyCollectedDataTypes` is a factual claim about what the LGU collects, and this app takes government IDs and proof-of-ownership documents, so a guessed or empty section would be a misrepresentation rather than a placeholder. The required-reason half is mechanical and can be written once the collection half is stated | Owner + legal: what is collected, for what purpose, and whether it is linked to identity |
| M-47 | **Reconcile `POST /applications` between the contract and this app.** Measured 29 Aug 2026 by diffing the request body against the contract's `ApplicationSubmission` schema, which is `additionalProperties: false` — so one undeclared key rejects the whole submission. The app would be refused on **four** counts: (a) the required `serviceDomain` is never sent and the app has no notion of it; (b) it sends `documents` (local labels and filenames) where the contract declares `documentIds` (uuids of files already uploaded via `/documents`, a flow that is not built); (c) `businessId` is `''` for every construction permit, and the contract types it as a uuid or null; (d) **not one of the 19 permit types the app files is in the contract's enum** — the contract still carries the app's OLD short names (`New Construction`, `Fencing`) while TABs 00 and 12 moved this app onto the admin's canonical labels, which is what the reconciliation asked for. Only `Certificate of Occupancy` matches. **The fix is not to change this app**: mobile matches the admin exactly, proven by the standing vocabulary gate, and adopting the contract's spelling would re-open every lookup keyed on the office's own names. Asserted in `test/contract/application_submission_test.dart`, which fails the day it is reconciled | Contract lane, with the backend and admin lanes; a contract change, so a version bump |

## Closed

- **M-02 / M-21 — "there is no backend".** Closed by TABs 01–20. There is a
  contract (46 paths, 54 operations, 97 schemas), a backend of record (41
  routes, 12 migrations, 979 tests), and a gate that validates recorded server
  responses against the contract and both clients against the server's real
  route table. The contract stays at **0.1.0**: it is enforced, and it is not
  ratified. Ratification is a signature, not a passing script.
- **G3 — the admin lost an officer's work on refresh.** The store is a cache of
  the server's answer; writes go to the server first and the cache changes only
  after it commits.
- **Plain-text password storage** (was blocking). TAB 5 replaced it with a
  PBKDF2-HMAC-SHA256 verifier and per-account salt, and purges the legacy key
  on upgrade. A test asserts no stored value anywhere in SharedPreferences
  contains the password. The remaining server-side half is M-01.
- **Notification preferences that changed nothing.** TAB 4 and TAB 5 made the
  switches gate delivery, with a test proving a toggle changes the outcome.
- **Eleven wizards fabricating mock documents.** X2 migrated all 134 upload
  slots to the real attach-document sheet and added the test stub to every
  wizard suite in the same change.
- **No consent gate before document capture.** X3 puts an RA 10173 consent
  dialog in front of the first attachment, records when it was given, and
  allows withdrawal from Privacy & Data.
- **Pre-flight check and document expiry** (§7.1 and §10.1), both listed in
  TAB scope tables but never built until the scope audit.
- **Two sources of truth for "today"** (19 August 2026 sweep). `professionals_screen`
  and `notifications_screen` read `DateTime.now()` while their providers carried
  injectable clocks. The professionals test pinned the clock and asserted a day count
  the screen never honoured, so the suite began failing when the date rolled over.
  Both providers now expose `now`; both screens read it.
- **Dead `quick_action_card.dart`**, unreferenced since Quick Actions was cut from Home.
- **No offline submission queue** (M-20). TAB 12 ships a durable queue in the
  platform keychain with idempotent replay, dependency-aware ordering, jittered
  backoff, and honest status — a queued submission reads "Queued", never
  "Submitted". Two things remain and are TAB work rather than manual: wiring the
  wizards to enqueue instead of calling the API directly, and a
  connectivity-triggered flush (needs `connectivity_plus` and a
  background-execution decision).
- **Payment history with filtering and export** (§8.1), the last of the four
  audit findings. Export format was decided rather than deferred — see M-26.
