# App Store submission — sweep, stitch, test

31 August 2026. **iOS only**, by standing rule: `android/`, the Play Console and
Android signing belong to the Windows lane and are filed here, not fixed.

**Verdict: NOT SUBMITTABLE.** One blocker is outside this lane and two are
decisions. Everything that was fixable here is fixed, and the binary was
re-measured afterwards rather than assumed.

---

## The finding that justified the sweep

The sign-in screen printed **working credentials** — *"Prototype access — use
`user@ebpco.com` / `password123` to explore the app"* — in every build,
including anything that would go to the App Store. Apple asks for review
credentials in App Store Connect's review notes, not on the screen a citizen
sees, and an LGU permit app advertising a shared password teaches exactly the
habit it can least afford.

Confining the banner to `kDebugMode` was the obvious fix. **Then the release
binary was checked, and the password was still in it:**

```
$ flutter build ios --release --no-codesign
$ strings build/ios/iphoneos/Runner.app/Frameworks/App.framework/App \
    | grep -c password123
1
```

The banner was the visible half. The credential shipped because
`MockAuthRepository` ships: with no `EBPCO_API_BASE_URL`, it is the default,
and it accepts exactly that pair. **Anyone could have signed into the shipped
app with it, banner or no banner.**

Same build, same reason: `MockApplicationsRepository` is seeded with a
fabricated application — *"Under Review, 40% complete"* — shown to whoever
opens the app as their own filing.

Neither is a bug in the mocks. They are correct, and they are for development.
What was missing was anything that noticed the *combination*: **release build +
no backend**.

### Fixed, and measured

* `AppStrings.mockEmail` / `mockPassword` are now `kReleaseMode ? '' : …`.
  `kReleaseMode` is a compile-time constant, so a release build compiles `''`
  and the literal is not in the binary. Re-measured: **1 → 0** for
  `password123`, **1 → 0** for `user@ebpco.com`.
* `AppConfig.assertShippable()`, called from `main()`, **throws** on a release
  build with no base URL. An exception rather than a banner, because a warning
  is something a release process can look past — and this one already was.
  Note honestly: it is a **runtime** guard. It stops such a build running; it
  cannot stop it compiling.

---

## The rest of the sweep

| Check | State |
|---|---|
| Bundle identifier | `ph.gov.castillasorsogon.ebpco` — real, no `com.example` |
| Display name / version | `E-BPCO`, `1.0.0+1` |
| Deployment target | iOS 15.0 |
| App icon | 21 sizes present; 1024×1024 marketing icon is RGB with **no alpha** |
| Launch screen | Castilla seal on brand red, matching the Flutter splash |
| Privacy manifest | `PrivacyInfo.xcprivacy` present **and shipped in the built bundle** |
| Camera / photo usage strings | present, specific, name the app |
| App Transport Security | no exceptions; no `http://` anywhere in `lib/` |
| Export compliance | **added** — `ITSAppUsesNonExemptEncryption = false`. The app speaks TLS, which is exempt; declaring it removes the question App Store Connect asks on every upload |
| Release build | succeeds, 35.9 MB |

### Still open, and not this lane's to close

* **B-1 — no backend.** The blocker under everything above. Until a base URL
  exists, a release build is a demo, and the guard now refuses to run it.
* **Account deletion.** Apple **Guideline 5.1.1(v)** requires any app offering
  account creation to offer in-app account deletion. This app creates accounts
  and has no deletion anywhere — and the contract declares **no DELETE
  operation at all**, so it cannot be built client-side. **This is a certain
  rejection.** Backend lane.
* **Orientation.** Portrait, landscape-left and landscape-right are all
  declared; nothing has been designed or tested in landscape. Not a rejection,
  but a reviewer rotating an iPad will see it. A decision, not a defect.

### App Store Connect metadata, which lives outside the repository

Needed at submission and not derivable from here: the **privacy label**
(answers prepared in `M-50-app-store-privacy-label.md`), a **support URL**, a
**privacy policy URL**, screenshots, the age rating, and **review notes with
credentials** — which is where `user@ebpco.com` belongs, now that it no longer
appears on screen.

---

## The gate

`test/architecture/release_readiness_test.dart`, 8 tests: no credentials in a
release build and none hardcoded outside the constants file; the compile-away
guard is in place; a backend-less release build refuses to start; export
compliance is declared; the bundle identity is real and not the Flutter
template's; the 1024 icon is square and alpha-free; and every permission the
app requests explains itself in more than a few words.

Run from a detached worktree at the SHA this document names, not from the tree
it was written in.
