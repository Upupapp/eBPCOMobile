import '../api/api_client.dart';
import '../config/app_config.dart';
import '../services/secure_session_store.dart';
import 'applications_repository.dart';
import 'auth_repository.dart';
import 'business_repository.dart';
import 'http_applications_repository.dart';
import 'http_auth_repository.dart';
import 'http_business_repository.dart';
import 'http_notifications_repository.dart';
import 'notifications_repository.dart';

/// Chooses between the mock repositories and the live API, in one place.
///
/// The choice lives here rather than at each provider so there is a single
/// answer to "what is this build talking to" — and so flipping a build to live
/// cannot half-happen, with applications coming from a server while payments
/// still come from seed data.
class RepositoryFactory {
  RepositoryFactory({
    ApiClient? apiClient,
    SessionStore? session,
  })  : _session = session ?? SecureSessionStore(),
        _injectedClient = apiClient;

  /// The keychain, not SharedPreferences. The token used to be read from an
  /// unencrypted preferences file; it now comes from the platform keystore, and
  /// it is asked for per request so a token issued after sign-in is picked up
  /// without rebuilding anything.
  final SessionStore _session;
  final ApiClient? _injectedClient;

  ApiClient? _client;

  bool get isLive => _injectedClient != null || AppConfig.useLiveBackend;

  /// The API client, or null on a mock build.
  ///
  /// Built lazily and once: the underlying http.Client pools connections, and
  /// a fresh one per request would throw that away.
  ApiClient? get client {
    if (_injectedClient != null) return _injectedClient;
    if (!AppConfig.useLiveBackend) return null;
    return _client ??= ApiClient(
      baseUrl: AppConfig.apiBaseUrl,
      timeout: const Duration(seconds: AppConfig.apiTimeoutSeconds),
      // Asked for per request, so a token issued after sign-in is picked up
      // without rebuilding anything.
      authToken: _session.accessToken,
    );
  }

  // ── the domains ─────────────────────────────────────────────────────────
  //
  // Every one goes through this class. That is what makes the guarantee in the
  // comment above a fact rather than an intention: there is one `client` and
  // one decision, so a build cannot end up with applications from the server
  // and notifications from seed data. `test/core/repositories/live_graph_test`
  // asserts it by walking the whole graph.

  ApplicationsRepository applications() {
    final api = client;
    return api == null ? MockApplicationsRepository() : HttpApplicationsRepository(api);
  }

  AuthRepository auth() {
    final api = client;
    return api == null ? MockAuthRepository() : HttpAuthRepository(api, _session);
  }

  BusinessRepository businesses() {
    final api = client;
    return api == null ? MockBusinessRepository() : HttpBusinessRepository(api);
  }

  NotificationsRepository notifications() {
    final api = client;
    return api == null ? MockNotificationsRepository() : HttpNotificationsRepository(api);
  }

  void dispose() => _client?.close();
}
