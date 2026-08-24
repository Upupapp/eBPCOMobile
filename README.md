# eBPCO Mobile

The Flutter mobile app for the **Electronic Building Permit and Certificate of
Occupancy (eBPCO)** system — letting applicants prepare, submit, and track
building permit applications and their supporting documents from a phone.

The companion Angular web admin lives in a separate repository.

> **Frontend-only prototype.** There is no backend, API, database, or real
> authentication. Every application, payment, and notification is mock data
> held in memory or in `SharedPreferences`. See
> [Prototype limitations](#prototype-limitations) before building on this.

> **Two agents work on this repository.** iOS and macOS belong to one lane,
> Android and Windows to the other. Read [`LANES.md`](LANES.md) before
> touching `android/`, `ios/`, or `release/`.

## Requirements

- Flutter 3.47.0 stable (Dart 3.13.0) — the SDK constraint is `^3.12.2`, so
  anything from that up should work
- Xcode for iOS, Android Studio / SDK for Android

## Getting started

```bash
flutter pub get
flutter run           # add -d <device_id> to pick a target
```

Sign in with the seeded account, or register a new one — registration saves
locally and can be used immediately.

```
Email:    user@ebpco.com
Password: password123
```

## Permit workflows

Sixteen application flows, grouped as they appear on the Applications tab.
Every one is a multi-step wizard with per-step validation, back navigation
that preserves entered data, a review step whose Edit buttons jump back to
the relevant step, and a submission confirmation screen with a tracking ID.
Progress survives leaving: a **Save Draft** button, a **Save & Exit**
prompt when backing out, and automatic resume of a saved draft on return.

| Group | Flows | Steps |
| --- | --- | --- |
| Building Permit | New Construction, Renovation, Addition / Extension, Demolition | 9 |
| Ancillary Permits | Architectural, Civil / Structural, Electrical, Mechanical, Sanitary / Plumbing, Plumbing, Electronics, Interior | 9 |
| Other Permits | Fencing, Sign, Excavation | 9–10 |
| Certificates | Certificate of Occupancy | 5 |

A typical 9-step wizard runs: applicant info → address & location → scope of
work → technical details → professional in charge → ownership & consent →
required documents → review & declaration → assessment & payment. Steps
adapt to earlier answers — selecting "Electrical System" as part of the
scope, for example, makes electrical plans a required upload later on.

## Other features

- **Onboarding & auth** — 3-page walkthrough, login, 3-step registration,
  forgot-password, all persisted through `SharedPreferences`
- **Dashboard** — greeting, active application progress, summary counters,
  quick actions, recent notifications
- **Businesses** — register, list, and view business details
- **My Documents** — import files from camera, gallery, or the system file
  picker; categorize them (government ID, proof of address, barangay
  clearance, tax and property documents, …); preview PDFs and images
  in-app; reuse a saved document to satisfy any permit upload slot
- **Payments** — assessment breakdown with Not Yet Available / Pending
  Verification / Paid / Overdue states and a mock payment flow
- **Notifications** — list with read/unread state and mark-all-as-read
- **Profile** — edit profile, profile photo capture, change password,
  notification preferences, help, terms, and privacy screens

## Project structure

```
lib/
  main.dart
  app.dart                 Root widget, provider registration
  routes/app_router.dart   go_router config, session/onboarding redirects
  core/
    constants/             Colors, strings, spacing, languages
    models/                Permit models — one per flow, plus shared models
    providers/             ChangeNotifier state, one per permit flow
    repositories/          Mock data sources
    services/              Local storage, document picker & storage,
                           permissions, profile photo
    theme/                 Typography, shadows, spacing, ThemeData
    utils/                 Form validators
  features/<feature>/presentation/    Screens and feature-local widgets
  shared/widgets/          Buttons, fields, cards, dialogs, states, uploads
  mock/                    Seed data
test/                      231 unit and widget tests
```

State is `provider` + `ChangeNotifier`; routing is `go_router` with a
`StatefulShellRoute.indexedStack` bottom nav that preserves per-tab state.

## Testing

```bash
flutter test
flutter analyze
```

Widget tests drive each wizard end to end, tapping through real form
fields. Because camera, gallery, and the system file picker have no
platform channels under `flutter test`, suites covering wizards that use
the real attach-document sheet stub it out:

```dart
setUp(() {
  debugAttachDocumentOverride = (context, {required label}) async =>
      createMockDocument(label);
});
tearDown(() => debugAttachDocumentOverride = null);
```

Wizards still using `createMockDocument` directly need no such setup. If
you migrate one to `showAttachDocumentOptions`, add the override to its
test file at the same time.

## Prototype limitations

- No backend, API, or database — all data is mock and local
- **Credentials are stored in plain text** in `SharedPreferences` purely to
  simulate login. This must never reach production.
- Only one registered account is tracked at a time; the most recent
  registration overwrites the previous one
- No real push notifications or payment processing
- Document uploads are real (files are copied into app-local storage) but
  are never transmitted anywhere
- The Language screen lists 20 Philippine languages but is display-only —
  selecting one does not localize the app

## Next steps

- Backend and API integration to replace mock data and mock auth
- Secure credential storage and a real session/token model
- Real application list with server-side filtering and search
- Payment gateway integration
- Push notification wiring
- Actual localization behind the existing language picker
