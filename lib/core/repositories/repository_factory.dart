import '../api/api_client.dart';
import '../config/app_config.dart';
import '../services/local_storage_service.dart';
import 'applications_repository.dart';
import 'http_applications_repository.dart';

/// Chooses between the mock repositories and the live API, in one place.
///
/// The choice lives here rather than at each provider so there is a single
/// answer to "what is this build talking to" — and so flipping a build to live
/// cannot half-happen, with applications coming from a server while payments
/// still come from seed data.
class RepositoryFactory {
  RepositoryFactory({ApiClient? apiClient, LocalStorageService? storage})
    : _storage = storage ?? LocalStorageService(),
      _injectedClient = apiClient;

  final LocalStorageService _storage;
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
      authToken: _storage.sessionToken,
    );
  }

  ApplicationsRepository applications() {
    final api = client;
    return api == null
        ? MockApplicationsRepository()
        : HttpApplicationsRepository(api);
  }

  void dispose() => _client?.close();
}
