# Master TODO — Manual Tasks Only

Items here **cannot be completed by the coding agent**. They need a human,
production access, an external party, or a decision that is not mine to make.
Anything I can do locally is not listed here — it is done, or it is in the TAB
backlog.

Last updated: scope audit — three unbuilt rows closed, one outstanding. 18 August 2026.

---

## Blocking for any pilot with real applicant data

| # | Task | Why manual | Raised in |
|---|---|---|---|
| M-01 | Move authentication to a server-issued session token held in the platform keychain/keystore | Needs an auth backend to issue tokens. **Partially closed in TAB 5**: the password is no longer stored at all (PBKDF2 verifier + salt), so nothing recoverable remains on disk. What is left is genuinely server-dependent | TAB 1 · §10.1 |
| M-02 | Stand up the backend for the admin-authoritative fields — `lifecycleStatus`, `classification`, `openInstructionCount`, Orders of Payment, evaluations, Letters of Instruction, inspections, release records | Server-side work. **The client is now built and tested against the §7.2 contract** (`lib/core/api/`), so this is the server half only. See M-21 for the endpoints it expects | TABs 1–3 |
| M-21 | **Confirm or correct the assumed API contract.** The client is now wired and will call these the moment a base URL is supplied: `GET /applications`, `GET /applications/:id`, `POST /applications`, `POST /applications/:id/payments`, `POST /applications/:id/instructions/:letterId/resubmit`; bearer-token auth; the §7.2 JSON shape with admin-vocabulary enum labels and fees as integer centavos. **Every one of these is my assumption, not an agreed contract** — treat this as a proposal to review, not a spec to build to | API layer |
| M-22 | Decide the token storage and refresh mechanism. `LocalStorageService.sessionToken()` is the read point and returns null today, so the client sends no Authorization header. Note it currently reads SharedPreferences, which is **unencrypted and not where a session token belongs** — see M-01 | API layer |
| M-03 | NPC-compliant privacy notice text and retention policy, reviewed by counsel | Legal text under RA 10173. TAB 5 ships a plain-language disclosure and working access/correct/export/delete controls; the formal notice still needs review | TAB 5 |
| M-16 | Publish the LGU's Data Protection Officer contact so applicants can exercise rights over what the LGU holds | LGU-specific; the Privacy & Data screen currently names the role without contact details | TAB 5 |
| M-17 | Raise the PBKDF2 iteration count and move derivation off the main isolate | Needs device profiling on the target mid-range Android hardware | TAB 5 |
| M-18 | Run the app on a physical mid-range Android device on a throttled connection | X4 verifies text scale, touch targets, and screen-reader labels under test; real-device performance cannot be asserted in a widget test | §11 · X4 |
| M-19 | Confirm colour contrast meets WCAG AA against the brand palette | Needs a contrast audit tool against rendered output; the palette is fixed by brand and any failure is a brand decision, not a code fix | §11 · X4 |
| M-20 | Implement a real offline submission queue once a backend exists | X5 ships staleness stamping and non-destructive degradation; queueing a submission requires something to submit to | §11 · X5 |

## Repository and delivery

| # | Task | Why manual |
|---|---|---|
| M-04 | Create `Upupapp/eBPCO-Mobile-App` on GitHub and push `main` | I am barred from remote/push operations. Commands are in the TAB 2 report |
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
| M-23 | **Payment history with filtering and export** (§8.1, listed EXTEND) | Not built. Found by a self-audit after TAB 3 was certified — the §8.3 acceptance criteria did not cover it, which is how it was missed. Needs a decision on export format (CSV? PDF receipt?) and whether history spans businesses |
| M-24 | **Appointment booking** (§3.1 benchmark) | Not built and not in the §7.1 screens table, so arguably out of scope. QC e-Services treats a confirmed online appointment as the *first* basic requirement, so if this LGU does the same it belongs in TAB 2 |

## Product decisions I have deliberately left open

| # | Decision | Why yours |
|---|---|---|
| M-13 | Localisation: implement Filipino (and which other languages), or reduce the picker to what is supported | Scope and budget call. **Still open** — the Language screen remains display-only |
| M-14 | Whether applicants may cancel their own application | Policy question with regulatory consequences |
| M-15 | Retention period for uploaded documents after an application closes | Data-minimisation policy under RA 10173 |

---

## Closed

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
