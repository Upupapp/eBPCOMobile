# M-50 — the App Store Connect privacy label

The label is a **separate declaration of the same facts** as
`ios/Runner/PrivacyInfo.xcprivacy`. Only the manifest was updated when the app
began transmitting the wizard contents on 31 August 2026; the label can only be
edited in Apple's web console, so this is what to transcribe.

Prepared from the shipped manifest and the bytes the wire test observes, so it
is a reading of this build rather than a recollection.

## App Privacy → Data Collection

**"Do you or your third-party partners collect data from this app?" → Yes.**

Nine types. For **every one**: *Used for Tracking* → **No**; *Linked to the
user's identity* → **Yes**; purpose → **App Functionality** only. Nothing here
is used for analytics, personalisation, or any kind of advertising, and the
manifest says so — `NSPrivacyTracking` is `false` with an empty
`NSPrivacyTrackingDomains`.

| Apple's category | Apple's type | Manifest key | What it is |
|---|---|---|---|
| Contact Info | Name | `Name` | The applicant, and **the professionals they name** |
| Contact Info | Email Address | `EmailAddress` | Account and notices |
| Contact Info | Phone Number | `PhoneNumber` | Account, and the contact number on the forms |
| Contact Info | Physical Address | `PhysicalAddress` | The applicant's address and the construction site |
| Identifiers | User ID | `UserID` | The account the filing belongs to |
| Financial Info | Other Financial Info | `OtherFinancialInfo` | Payments reported to the LGU: method, reference, amount, date |
| User Content | Photos or Videos | `PhotosorVideos` | Uploaded plans, titles, IDs, structure photographs |
| User Content | Other User Content | `OtherUserContent` | The documents that are not images |
| Other Data | Other Data Types | `OtherDataTypes` | The application itself — permit type, scope, occupancy, costs, licence numbers. Apple has no category for a building permit |

**What changed, and why the label is stale.** Until 31 August a filing carried
the permit type, the applicant's name and a site line. It now carries the whole
wizard — up to 239 fields — **including other people's details**: every
construction wizard collects the designing professional and the full-time
supervisor by name, PRC licence, PTR, address and contact number. Apple's
questionnaire has no axis for whose data it is, so the *types* are unchanged and
the four Contact Info answers now cover people who are not the account holder.
That is worth knowing before answering, not after.

**Not collected**, and each checked rather than assumed:

* **Location** — no location plugin is in `pubspec.yaml`. The `location` field
  on a filing is a typed address string, not a device reading.
* **Device ID** — no push plugin, no Firebase, no APNs registration. The app's
  notifications are in-app.
* **Sensitive Info** — Apple defines this narrowly (race, sexual orientation,
  pregnancy, disability, religious or political belief, trade union membership,
  genetic, biometric). A government ID number is not in that list; it is Other
  Data Types.
* **Contacts, Browsing History, Search History, Purchases, Diagnostics,
  Advertising Data** — none.

## App Privacy → Tracking

**"Does this app track users?" → No.** No IDFA, no ATT prompt, no advertising
SDK, no third-party analytics. `NSPrivacyAccessedAPITypes` is empty on purpose:
the required-reason APIs the app relies on are called by Flutter plugins, which
ship their own manifests, not by this binary. See `docs/M-46-privacy-manifest.md`.

---

## One thing to decide before you answer

**The app fetches its typeface from a Google server at runtime, and nothing
declares it.**

`pubspec.yaml` depends on `google_fonts`, `app_theme.dart` and
`app_typography.dart` call `GoogleFonts.poppins()`, **no Poppins files are
bundled** — the `fonts:` block in `pubspec.yaml` is still commented out — and
`GoogleFonts.config.allowRuntimeFetching` is never set, so it keeps its default
of `true`.

So on first use the package downloads Poppins from `fonts.gstatic.com`. That is
a request to a third party carrying the device's IP address, made on behalf of
every applicant, before they have agreed to anything.

Three consequences, in order of how much they matter:

1. **The in-app Privacy Policy does not mention it.** It says information "may
   be shared with other government offices" and that the LGU does not sell
   personal information. Both true. Neither describes a connection to Google.
2. **The typeface is non-deterministic.** An applicant who first opens the app
   online gets Poppins; one who opens it offline gets the platform font, and
   keeps it until a fetch succeeds. The app is explicitly built for offline
   preparation — `pubspec.yaml` says the 6.6 MB of blank forms are bundled
   "because the point of them is offline preparation" — and the typeface is the
   one asset that contradicts that.
3. **It bears on the label.** Apple asks whether *you or your third-party
   partners* collect data. A font CDN receiving an IP address is a thin case,
   and it is not one to answer from a guess.

**Two ways out, and both are the owner's call:**

* **Bundle Poppins.** It is under the SIL Open Font License, so redistributing
  it in the app is permitted. Add the `.ttf` files to `assets/fonts/`, declare
  them under `fonts:`, and set `GoogleFonts.config.allowRuntimeFetching = false`.
  The app looks the same, always, offline included, and makes no third-party
  request. Costs a few hundred kilobytes against the 6.6 MB already bundled.
* **Drop the runtime fetch and accept the platform font.** One line
  (`allowRuntimeFetching = false`), no new assets, and the app looks different.

**Not taken here**, because it changes either what ships in the binary or how
every screen looks, and neither is a decision this lane gets to make quietly.
Recorded as M-51.

---

## The gate

`test/architecture/privacy_label_test.dart` asserts this document against the
shipped manifest: the nine types listed here are exactly the nine the manifest
declares, the tracking answers agree, and the runtime-font finding stays stated
until either fonts are bundled or fetching is turned off. If the manifest gains
a type, this checklist fails and names it — which is the failure that should
have happened when `form` started being transmitted.
