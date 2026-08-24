# iOS build log — Mac lane

Newest first. One entry per build that leaves the simulator; simulator runs
are not logged.

---

## 2026-08-19 — lane established, no build

`release/ios/` created and ownership recorded in `LANES.md`. No archive has
ever been made.

Observed while running on the simulator: the plugin set raised
`IPHONEOS_DEPLOYMENT_TARGET` from 13.0 to 15.0 across three build
configurations. That change is still uncommitted in the working tree,
deliberately — dropping iOS 13 and 14 is an audience decision (M-38), not a
build detail, and it should not ride along in an unrelated commit.

Version at this point: `1.0.0+1` in `pubspec.yaml`, untouched since the
project was generated.
