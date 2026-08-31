import 'package:flutter/foundation.dart';

/// Centralized user-facing copy for the E-BPCO User App.
class AppStrings {
  AppStrings._();

  static const String appName = 'E-BPCO';
  static const String appFullName =
      'Electronic Building Permit and Certificate of Occupancy';
  static const String appTagline =
      'Building Permit and Certificate of Occupancy';
  static const String splashSubtitle = 'Permits and occupancy, simplified.';

  // The mock account — development only, and **empty in a release binary**.
  //
  // `strings` on the release framework found `password123` in the shipped
  // App.framework on 31 August 2026, after the sign-in banner advertising it
  // had already been confined to debug builds. The banner was the visible
  // half. The credential shipped because `MockAuthRepository` ships: without
  // an API base URL it is the default, and it accepts exactly this pair.
  //
  // `kReleaseMode` is a compile-time constant, so a release build compiles
  // `''` here and the literal is not in the binary at all. `MockAuthRepository`
  // then authenticates nobody, which is the correct outcome — a release build
  // with no backend is a demo, and `AppConfig.assertShippable()` refuses to
  // start one.
  static const String mockEmail = kReleaseMode ? '' : 'user@ebpco.com';
  static const String mockPassword = kReleaseMode ? '' : 'password123';

  // Generic.
  static const String continueLabel = 'Continue';
  static const String cancel = 'Cancel';
  static const String next = 'Next';
  static const String back = 'Back';
  static const String skip = 'Skip';
  static const String getStarted = 'Get Started';
  static const String prototypeLabel = 'Prototype data';
}
