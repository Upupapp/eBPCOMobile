import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app.dart';
import 'core/config/app_config.dart';

void main() {
  // **The app must never fetch its typeface.** M-51.
  //
  // `google_fonts` downloads the family from `fonts.gstatic.com` on first use
  // unless told otherwise — a request to a third party carrying the device's
  // IP address, made on behalf of every applicant before they have agreed to
  // anything, that neither the Privacy Policy nor `PrivacyInfo.xcprivacy`
  // declared. It also made the typeface non-deterministic: an applicant whose
  // first launch was offline got the platform font and kept it until a fetch
  // happened to succeed, in an app whose 6.6 MB of blank forms are bundled
  // precisely so it works away from a connection.
  //
  // Poppins is bundled instead — `assets/fonts/`, declared in `pubspec.yaml`
  // at the five weights the design uses. `GoogleFonts.poppins()` resolves
  // against those, so the ~90 call sites did not have to change.
  //
  // This line is what makes the guarantee, rather than the bundling: with
  // fetching left on, a weight the bundle happened to miss would still go to
  // the network. Off, a miss falls back to the platform font — visible, local,
  // and not a disclosure.
  GoogleFonts.config.allowRuntimeFetching = false;

  // Refuses to start a release build that has no backend, because that build
  // ships a fabricated application and a shared password. See
  // `AppConfig.assertShippable` — it is an exception rather than a warning
  // because a warning has already been looked past once.
  AppConfig.assertShippable();

  runApp(const EbpcoApp());
}
