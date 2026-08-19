import 'dart:async';

import '../services/secure_session_store.dart';

/// Keeps the access token fresh, and gives up cleanly when it cannot.
///
/// The single-flight guard is the point. An applicant opening the app after a
/// while has a home screen that fires several requests at once — applications,
/// notifications, profile — and every one of them gets a 401 at the same
/// moment. Without a guard, each retries by refreshing, and because refresh
/// tokens rotate and a replay revokes the whole family (TAB 03), the second
/// refresh to land would sign the applicant out and look, from the server, like
/// a stolen token.
///
/// So concurrent refreshes share one in-flight future. Ten 401s produce one
/// refresh call and ten retries with the same new token.
class SessionManager {
  /// Positional rather than named: Dart forbids a named parameter beginning
  /// with an underscore, so named parameters here would mean either public
  /// fields or a lint suppression. Three collaborators, one construction site.
  SessionManager(this._store, this._refresh, this._onSignedOut);

  final SessionStore _store;
  /// Exchanges a refresh token for a new pair, or null when the session is over.
  final Future<RefreshedTokens?> Function(String refreshToken) _refresh;
  /// Called once the session has ended, to clear everything else.
  final Future<void> Function() _onSignedOut;

  Future<String?>? _inFlight;

  /// How many refresh calls have actually been made. Test-visible, because the
  /// property under test is "exactly one", and counting is the only way to
  /// assert it.
  int refreshCallCount = 0;

  Future<String?> currentAccessToken() => _store.accessToken();

  /// Obtains a fresh access token, refreshing at most once concurrently.
  ///
  /// Returns null when the session is over. The caller must not retry on null:
  /// there is nothing left to retry with.
  Future<String?> refreshAccessToken() {
    // A refresh already running: join it rather than starting another.
    final existing = _inFlight;
    if (existing != null) return existing;

    final attempt = _performRefresh();
    _inFlight = attempt;
    // Cleared in a `whenComplete` rather than after the await, so a thrown
    // refresh does not leave a completed future latched here forever — which
    // would make every subsequent request reuse a dead result.
    attempt.whenComplete(() {
      if (identical(_inFlight, attempt)) _inFlight = null;
    });
    return attempt;
  }

  Future<String?> _performRefresh() async {
    final refreshToken = await _store.refreshToken();
    if (refreshToken == null) {
      await _endSession();
      return null;
    }

    refreshCallCount += 1;

    RefreshedTokens? tokens;
    try {
      tokens = await _refresh(refreshToken);
    } catch (_) {
      // A network failure is not a revoked session, but it is not a usable one
      // either. Signing out is the safe reading: the alternative is an app that
      // silently retries forever behind a spinner.
      await _endSession();
      return null;
    }

    if (tokens == null) {
      await _endSession();
      return null;
    }

    await _store.save(
      accessToken: tokens.accessToken,
      refreshToken: tokens.refreshToken,
    );
    return tokens.accessToken;
  }

  /// Ends the session locally. Called on refresh failure and on sign-out.
  Future<void> _endSession() async {
    await _store.clear();
    await _onSignedOut();
  }

  Future<void> signOut() => _endSession();
}

class RefreshedTokens {
  const RefreshedTokens({required this.accessToken, required this.refreshToken});

  final String accessToken;
  final String refreshToken;
}
