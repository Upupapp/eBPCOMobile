# Lane ownership

Two agents work on this repository on different machines. This file says who
owns what, so neither has to guess and neither edits the other's files.

**Read this before touching anything under `android/`, `ios/`, or `release/`.**

| Lane | Machine | Owns | Store |
|---|---|---|---|
| **iOS / Mac** | macOS | `ios/`, `release/ios/`, Xcode project and signing, CocoaPods and Swift Package Manager, simulator and device runs | Apple App Store |
| **Android / Windows** | Windows | `android/`, `release/android/`, Gradle, keystores and signing config, emulator and device runs | Google Play |

Everything else — `lib/`, `test/`, `docs/`, `pubspec.yaml`, `web/`, `macos/`,
`linux/`, `windows/` — is **shared**. Either lane may change it. The rules for
shared code are at the bottom.

---

## Why the split exists

iOS builds, signing, and App Store submission need macOS and Xcode; they
cannot be done from Windows. Android release signing needs the keystore, which
lives with whoever holds it. Neither lane can verify the other's platform
build, so neither should change it blind — a plausible-looking edit to
`android/app/build.gradle.kts` from a Mac is a change nobody can test until it
breaks someone else's release.

## The iOS lane's path

```
release/ios/
├── README.md            what this directory is and how to use it
├── NOTES.md             running log: build numbers, submission outcomes
└── ExportOptions.plist  archive export configuration (added when first needed)
```

`release/ios/` is the iOS lane's working area. Anything about building,
signing, archiving, or submitting the iOS app belongs there and nowhere else.

The Android lane's equivalent is `release/android/`, created by that lane when
it needs one. **Neither lane creates or edits the other's directory.**

## Current platform state

**iOS.** Bundle identifier `com.ebpco.ebpcoUserApp`, automatic signing, no
development team set. Deployment target is 15.0 — raised from 13.0 by the
plugin set during the first build rather than by decision, which is M-38 and
is the iOS lane's to resolve. Runs on the simulator; never archived, never
submitted, no distribution certificate or provisioning profile.

**Android.** Application ID is the generated default and release builds are
signed with the **debug key** — `android/app/build.gradle.kts` still carries
the generated TODOs. That is M-28 and M-29, and it is the Android lane's to
resolve. Not mine to touch.

## Rules for shared code

1. **Run the full suite before committing.** `flutter analyze` clean and
   `flutter test` green. Both lanes depend on it, and a broken `lib/` blocks
   the other lane's platform work as surely as its own.
2. **`pubspec.yaml` is shared and load-bearing.** A dependency added for one
   platform is compiled by both, and plugins routinely raise a platform's
   minimum OS version as a side effect — that is exactly how the iOS floor
   moved to 15.0. Adding a dependency means checking what it does to *both*
   floors and saying so in the commit.
3. **`docs/MANUAL-TASKS.md` is append-only and shared.** Read the highest
   `M-##` **at the moment you write**, not when you started. Ids were
   collided once already by picking them from a stale read.
4. **Say which lane a commit is from** when it touches platform files, so the
   other lane can skip it when scanning history.
5. **Neither lane pushes.** Preparing a push is fine; running it is the
   owner's.
