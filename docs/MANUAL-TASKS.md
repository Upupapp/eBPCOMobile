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
| M-04 | Push `main` to **`https://github.com/Upupapp/eBPCOMobile`** — the designated repo, public and currently empty. `origin` is already configured locally; the push itself is barred to me | I am barred from remote/push operations |
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
