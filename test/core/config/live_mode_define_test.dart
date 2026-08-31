import 'package:flutter_test/flutter_test.dart';

import 'package:ebpco_user_app/core/config/app_config.dart';
import 'package:ebpco_user_app/core/repositories/repository_factory.dart';

/// Does `--dart-define=EBPCO_API_BASE_URL` actually reach the repositories?
///
/// **Nobody had ever checked, and B-1 depends on it.** `live_graph_test`
/// proves the graph is all-Http when a client is INJECTED — the right test of
/// the factory, and silent about the switch that will actually be thrown: a
/// compile-time `String.fromEnvironment` read by `AppConfig` and consulted by
/// `RepositoryFactory.client`.
///
/// A build where the define is misspelled, dropped from the build command, or
/// read under a different key would pass every existing test and still ship
/// fabricated data — the failure `AppConfig.assertShippable()` exists to
/// prevent, arriving through the one door that guard does not watch.
///
/// The assertions compare the two halves against each other, so the file is
/// meaningful in both modes:
///
/// ```
/// flutter test test/core/config/live_mode_define_test.dart
/// flutter test test/core/config/live_mode_define_test.dart \
///   --dart-define=EBPCO_API_BASE_URL=https://api.example.gov.ph
/// ```
///
/// The second belongs in whatever pipeline eventually produces a release.

void main() {
  test('the define and the factory agree on this build\'s mode', () {
    final factory = RepositoryFactory();
    addTearDown(factory.dispose);

    expect(
      factory.isLive,
      AppConfig.useLiveBackend,
      reason:
          'AppConfig says useLiveBackend=${AppConfig.useLiveBackend} and the '
          'factory says isLive=${factory.isLive}. One is reading a different '
          'switch from the other, and a release would ship whichever is wrong',
    );
  });

  test('and the mode follows the base URL, not a default', () {
    expect(
      AppConfig.useLiveBackend,
      AppConfig.apiBaseUrl.isNotEmpty,
      reason: 'live mode must follow the supplied URL and nothing else',
    );
  });

  test('a build WITH a URL resolves every domain to the wire', () {
    if (!AppConfig.useLiveBackend) return;
    final factory = RepositoryFactory();
    addTearDown(factory.dispose);

    expect(factory.client, isNotNull);
    expect(factory.client!.baseUrl, AppConfig.apiBaseUrl);
    expect(
      factory.applications().runtimeType.toString(),
      startsWith('Http'),
      reason: 'a live build resolved a domain to a mock repository',
    );
    expect(
      AppConfig.apiBaseUrl,
      startsWith('https://'),
      reason:
          'the app declares no App Transport Security exceptions, so iOS '
          'refuses a cleartext base URL at RUNTIME rather than at build time '
          "— a release shipping one fails in a citizen's hands, not here",
    );
  });

  test('a build WITHOUT one constructs no HTTP client', () {
    if (AppConfig.useLiveBackend) return;
    final factory = RepositoryFactory();
    addTearDown(factory.dispose);
    expect(factory.client, isNull);
  });
}
