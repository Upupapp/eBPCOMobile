# iOS build log — Mac lane

Newest first. One entry per build that leaves the simulator; simulator runs
are not logged.

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
