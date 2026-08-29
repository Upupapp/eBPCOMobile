# iOS build log — Mac lane

Newest first. One entry per build that leaves the simulator; simulator runs
are not logged.

---

## 2026-08-29 — readiness measured; two recorded facts were wrong

No archive made, and deliberately so — see the bundle identifier below.

**Toolchain, all present:** Xcode 26.6 (17F113), CocoaPods 1.17.0,
Flutter 3.47.0. `flutter build ios --release --no-codesign` → **exit 0,
`Runner.app` 33.9 MB in 91.8s**. The app archives; nothing in the build is the
blocker.

### The signing claim in README.md was misleading

It read "there is no distribution certificate, no provisioning profile", and
listed that as the blocker. Measured:

```
security find-identity -v -p codesigning
  1) Apple Development: paul espinas (JVV577Q92N)   — 1 valid identity
~/Library/MobileDevice/Provisioning Profiles/       — 0 profiles
```

That is exactly the reading which was **wrong** on `ServanaWorkerAPP`, where the
same "no distribution identity" conclusion produced an owner task list and a
hunt for a `.p12` that was never needed. Xcode signs with a **cloud-managed**
distribution certificate: Apple holds the private key and signs server-side, so
it never appears in the local keychain and `find-identity` will always look
like this.

Xcode here is signed into **UPUP TECHNOLOGIES PTE. LTD (`2K2SF7NRQP`)**, a
Company team — the same team that produced signed Servana builds from this Mac.
So the team's distribution capability exists.

### What is actually blocking, and it is not a certificate

1. **`DEVELOPMENT_TEAM` is unset** in `ios/Runner.xcodeproj/project.pbxproj` —
   grep returns nothing. Nothing tells a build which team to sign for.
2. **The bundle identifier is still a placeholder**, `com.ebpco.ebpcoUserApp`
   (M-29). This is why no archive was attempted: `-allowProvisioningUpdates`
   would register that identifier against the company team and may consume one
   of the team's capped distribution certificate slots — a real, outward action
   taken on an identifier the owner has not chosen and cannot change after
   publication.

### A blocker that was not recorded anywhere: no app privacy manifest

`PrivacyInfo.xcprivacy` exists only inside third-party bundles
(`flutter_secure_storage_darwin`, `TOCropViewController`, `SDWebImage`). There
is **none for the app**, and Apple rejects an app that uses required-reason
APIs without one. This app uses `shared_preferences` (UserDefaults),
`path_provider` and file access, so it does.

It is deliberately **not drafted here**. The manifest has two halves: the
required-reason API declarations, which are mechanical, and
`NSPrivacyCollectedDataTypes`, which is a factual claim about what the LGU
collects — and this app takes government IDs and proof-of-ownership documents,
so an empty or guessed collection section would be a misrepresentation, not a
placeholder. Writing half of it would ship a manifest asserting the app
collects nothing. Recorded as M-46 instead.

### Verified good

- Marketing icon `Icon-App-1024x1024@1x.png`: 1024×1024, **no alpha** — what
  Apple requires, and the thing that most often bounces a first upload.
- `IPHONEOS_DEPLOYMENT_TARGET = 15.0` across all three configurations,
  unchanged and consistent with the 19 August entry.
- Version still `1.0.0+1`; no build number has ever been consumed on either
  store, so nothing is at risk of collision with the Android lane yet.

---

## 2026-08-19 — lane established, no build

`release/ios/` created and ownership recorded in `LANES.md`. No archive has
ever been made.

`IPHONEOS_DEPLOYMENT_TARGET` moved from 13.0 to 15.0 across three build
configurations, and it is now committed. I first recorded this as a plugin
raising the floor and therefore an audience decision. It is neither: Flutter
3.47 rewrites any target below 15.0 on every build, from
`ios_deployment_target_migration.dart`. Reverting the file and rebuilding
put it straight back.

Verified by `flutter build ios --simulator --no-codesign` — exit 0, built
successfully, with the migration message in the log.

No device is lost: iOS 15 runs on every iPhone that ran iOS 13, 6s onward.

Version at this point: `1.0.0+1` in `pubspec.yaml`, untouched since the
project was generated.
