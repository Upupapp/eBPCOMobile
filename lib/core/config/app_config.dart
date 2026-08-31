import 'package:flutter/foundation.dart';

/// How this build talks to the outside world.
///
/// Read from compile-time environment values rather than a checked-in
/// constant, so no LGU's hostname is baked into the repository and a build
/// cannot accidentally ship pointed at someone's staging server:
///
/// ```
/// flutter run --dart-define=EBPCO_API_BASE_URL=https://ebpco.example.gov.ph/api
/// ```
///
/// **The default is the mock backend.** Live mode is opt-in and requires a
/// base URL, because a build that silently tried to reach a server that does
/// not exist would look like an outage to whoever ran it.
class AppConfig {
  const AppConfig._();

  /// Root of the API, without a trailing slash. Empty when unset.
  static const String apiBaseUrl = String.fromEnvironment('EBPCO_API_BASE_URL');

  /// Whether to use the real backend. True only when a base URL was supplied.
  static bool get useLiveBackend => apiBaseUrl.isNotEmpty;

  /// Request timeout, overridable for networks slower than the default
  /// assumption.
  static const int apiTimeoutSeconds = int.fromEnvironment(
    'EBPCO_API_TIMEOUT_SECONDS',
    defaultValue: 20,
  );

  /// Whether this build is a demo that must never reach a citizen.
  ///
  /// **True is a release build with no backend**, and that combination is what
  /// the submission sweep of 31 August 2026 found in the binary. Without a
  /// base URL the app serves `MockAuthRepository`, which accepts one hardcoded
  /// account — so `strings` on the release framework still found
  /// `password123` after the sign-in banner advertising it had been confined
  /// to debug. The banner was the visible half; the shipped account was the
  /// real one.
  ///
  /// It also serves `MockApplicationsRepository`, seeded with a fabricated
  /// application — "Under Review, 40% complete" — presented to whoever opens
  /// the app as their own filing.
  ///
  /// Neither is a bug in the mocks. They are correct, and they are for
  /// development. What was missing was anything that noticed the combination.
  /// [assertShippable] is that, and it fails the build rather than the review.
  static bool get isUnshippableDemo => kReleaseMode && !useLiveBackend;

  /// Throws when a build would ship fabricated data and a shared password.
  ///
  /// Called from `main()`. Deliberately an exception rather than a banner: a
  /// warning is something a release process can look past, and this one has
  /// already been looked past once — the app has carried a working
  /// `user@ebpco.com` / `password123` in every release artefact built to date.
  ///
  /// The fix is not to weaken this. It is B-1: give the build a backend
  /// (`--dart-define=EBPCO_API_BASE_URL=…`). Until then a release build is a
  /// demo, and the sweep's verdict is that a demo cannot go to the App Store.
  static void assertShippable() {
    if (!isUnshippableDemo) return;
    throw StateError(
      'This is a RELEASE build with no EBPCO_API_BASE_URL, so it would ship '
      'the mock repositories: a fabricated application shown to the citizen '
      'as their own, and a hardcoded account that anyone can sign in with. '
      'Build with --dart-define=EBPCO_API_BASE_URL=<the API root>, or build '
      'in debug/profile. See docs/APP-STORE-SUBMISSION-SWEEP.md.',
    );
  }

  /// A one-line description of where this build points, for the About screen
  /// and for bug reports — a citizen reporting a problem should not have to
  /// know which environment they were on.
  static String get backendDescription =>
      useLiveBackend ? 'Connected to $apiBaseUrl' : 'Offline demo data';
}
