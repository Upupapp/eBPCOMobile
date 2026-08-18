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

  /// A one-line description of where this build points, for the About screen
  /// and for bug reports — an applicant reporting a problem should not have to
  /// know which environment they were on.
  static String get backendDescription =>
      useLiveBackend ? 'Connected to $apiBaseUrl' : 'Offline demo data';
}
