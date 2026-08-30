# M-29 — the bundle identifier. One decision, then a mechanical change.

*Measured 29 August 2026. Front-end lane; the Android half is the Windows
lane's and is described, not changed.*

---

## Where it stands

**The two stores already disagree**, which is a defect on its own:

| Target | Identifier |
|---|---|
| iOS | `com.ebpco.ebpcoUserApp` |
| Android | `com.ebpco.ebpco_user_app` |

They are separate namespaces, so nothing *breaks* today — but they are meant to
name one product, and two spellings will be quoted at Apple and Google as though
they were deliberate. Settling M-29 is the moment to reconcile them.

`com.ebpco` is a placeholder. Reverse-DNS convention expects a domain the
publisher controls, and this app is published by the Municipality of Castilla.

## Everywhere it is written

Twelve files, across six platform targets and the documentation:

| Owner | Files |
|---|---|
| **This lane (iOS)** | `ios/Runner.xcodeproj/project.pbxproj` — 3 `Runner` + 3 `RunnerTests` entries |
| **Windows lane (Android)** | `android/app/build.gradle.kts` (`namespace`, `applicationId`) and `android/app/src/main/kotlin/com/ebpco/ebpco_user_app/MainActivity.kt` — **whose directory path is derived from the identifier**, so their change moves a folder |
| Neither, in practice | `macos/`, `linux/`, `windows/` — Flutter desktop scaffolding this product does not ship. Worth aligning for tidiness, not worth blocking on |
| Documentation | `LANES.md`, `release/ios/README.md`, `release/ios/NOTES.md`, `docs/MANUAL-TASKS.md`, the production master command |

## Why it cannot wait, and cannot be undone

- **It is permanent after publication.** Neither store lets an app change its
  identifier; a new one is a new listing, losing reviews, ratings and installed
  base.
- **It blocks every remaining iOS step.** Registering a provisioning profile
  binds the identifier to the team — which is exactly why no archive has been
  attempted (see `release/ios/NOTES.md`). Registering the placeholder would
  consume a slot on `2K2SF7NRQP` for a name nobody chose.

## What I recommend

**A single identifier, in reverse-DNS on a domain the LGU controls, identical
on both stores.** Shape, not a specific string:

```
ph.gov.<lgu-domain>.ebpco
```

### Correction, 30 August 2026 — there IS a candidate domain

This note said no `.gov.ph` domain for Castilla was recorded anywhere in the
repository, and that a chosen one would therefore be invented. **That was
wrong.** The check behind it looked at the documents and the platform files and
not at `lib`.

`lib/core/contract/requirements_catalog.dart` records
**`castillasorsogon.gov.ph`** as the *"Municipality of Castilla, Sorsogon —
official Citizen's Charter / OBO documentary checklist"*.

It carries `verificationStatus: PENDING_CASTILLA_VERIFICATION` and a note that
the site was *"not accessible to automated research as of 2026-08-20"*. So the
domain is **recorded but unverified**, which is a materially better position
than nothing: it is a candidate the LGU can confirm or correct in one sentence,
rather than a blank the LGU has to fill.

That makes the recommendation concrete:

```
ph.gov.castillasorsogon.ebpco
```

— on one condition, which is the whole of what is still needed: **somebody
confirms the municipality actually holds that domain.** A bundle identifier
cannot be changed after publication, so an unverified domain baked into one is
the single worst place for this particular uncertainty.

Two things I still deliberately have not decided:

- **Whether the domain is real.** See above. It is recorded, not verified.
- **Whether to keep `com.ebpco`.** If the domain cannot be confirmed, keeping
  it is defensible for a pilot — but then it must be spelled *identically*
  everywhere, which today it is not.

Avoid: `_` in the iOS identifier (Apple discourages it), and the
`UserApp`/`user_app` suffix, which describes an internal build target rather
than the product an applicant installs.

## What happens once you decide

**My half is three lines** — six `PRODUCT_BUNDLE_IDENTIFIER` entries in one
Xcode project file, of which three are the test target. No code references it;
nothing in `lib/` reads it.

**The Windows lane's half is larger**: two Gradle values plus a package
directory move for `MainActivity.kt`.

### It is a four-target split, not a two-target one

Measured 30 August: **macOS carries the iOS spelling and Linux carries the
Android one.** Two camps, four files, one product. macOS and Linux are not
shipped, and they are still two more places the wrong spelling is written down
and can be copied from.

`test/architecture/bundle_identifier_test.dart` now pins all four and asserts
the split *as it stands*, so it cannot be closed by halves: change one side and
the test fails; change both to the same value and it fails too, and says to
delete itself.

Say the identifier and I will apply the iOS half, update the four documents, and
leave the Android half stated for that lane.
