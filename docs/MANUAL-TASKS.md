# Master TODO — Manual Tasks Only

Items here **cannot be completed by the coding agent**. They need a human,
production access, an external party, or a decision that is not mine to make.
Anything I can do locally is not listed here — it is done, or it is in the TAB
backlog.

Last updated: TAB 5 (Profile) — all five TABs complete, 18 August 2026.

---

## Blocking for any pilot with real applicant data

| # | Task | Why manual | Raised in |
|---|---|---|---|
| M-01 | Move authentication to a server-issued session token held in the platform keychain/keystore | Needs an auth backend to issue tokens. **Partially closed in TAB 5**: the password is no longer stored at all (PBKDF2 verifier + salt), so nothing recoverable remains on disk. What is left is genuinely server-dependent | TAB 1 · §10.1 |
| M-02 | Stand up the backend for the admin-authoritative fields — `lifecycleStatus`, `classification`, `openInstructionCount`, Orders of Payment, evaluations, Letters of Instruction, inspections, release records | Server-side work; the app builds against repository interfaces ready to swap | TABs 1–3 |
| M-03 | NPC-compliant privacy notice text and retention policy, reviewed by counsel | Legal text under RA 10173. TAB 5 ships a plain-language disclosure and working access/correct/export/delete controls; the formal notice still needs review | TAB 5 |
| M-16 | Publish the LGU's Data Protection Officer contact so applicants can exercise rights over what the LGU holds | LGU-specific; the Privacy & Data screen currently names the role without contact details | TAB 5 |
| M-17 | Raise the PBKDF2 iteration count and move derivation off the main isolate | Needs device profiling on the target mid-range Android hardware | TAB 5 |

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
