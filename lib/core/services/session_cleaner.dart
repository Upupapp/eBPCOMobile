import '../constants/app_constants.dart';
import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';

import 'secure_session_store.dart';

/// Removes every trace of the previous applicant on sign-out.
///
/// "Sign out" that only forgets the token leaves the next person to hold the
/// phone looking at the last one's permit application. On a shared or handed-on
/// device — which in this context is common, not exotic — that is a disclosure
/// of somebody's address, their business, and their identity documents.
///
/// So the sweep is: tokens, cached documents on disk, and the preference keys
/// that carry personal data. What it deliberately does NOT clear is the two
/// settings that are about the device rather than the person — whether
/// onboarding has been seen, and the chosen language — because wiping those
/// makes every sign-out feel like a factory reset without protecting anyone.
class SessionCleaner {
  /// Positional for the same reason as [SessionManager]: Dart forbids a named
  /// parameter beginning with an underscore.
  SessionCleaner(
    this._store,
    this._documentCache, [
    Future<SharedPreferences> Function()? preferences,
  ]) : _preferences = preferences ?? SharedPreferences.getInstance;

  final SessionStore _store;
  final Directory _documentCache;
  final Future<SharedPreferences> Function() _preferences;

  /// Preference keys that survive. Everything else goes.
  ///
  /// An allow-list, not a deny-list: a key added later is cleared by default,
  /// and the thing that would otherwise be forgotten is somebody's data.
  ///
  /// **Written as constants, not literals, since 31 August 2026 — and that is
  /// the bug this fixes.** The list held `'onboarding_completed'` in snake
  /// case while the app writes `'onboardingCompleted'`. The allow-list
  /// therefore did not match the key it was meant to protect, so **signing out
  /// deleted it**, and the next launch showed a returning applicant the
  /// three-page introduction as though they had never used the app.
  ///
  /// A deny-list would have failed loudly. An allow-list fails by forgetting,
  /// which is why the spelling has to come from the same place the writer
  /// takes it from.
  static const kept = <String>{
    AppConstants.prefOnboardingCompleted,
    // Nothing writes a language preference yet — `language_screen.dart` does
    // not persist. Kept so the choice survives the moment it does, and named
    // here rather than left to be discovered later.
    'preferred_language',
  };

  Future<void> signOut() async {
    await _store.clear();
    await _clearPreferences();
    await _clearCachedDocuments();
  }

  Future<void> _clearPreferences() async {
    final prefs = await _preferences();
    for (final key in prefs.getKeys().toList()) {
      if (kept.contains(key)) continue;
      await prefs.remove(key);
    }
  }

  /// Deletes downloaded permits and attachments.
  ///
  /// These are the most sensitive thing the app holds locally: a title deed, a
  /// government ID, a signed permit. Leaving them behind because the token is
  /// gone confuses "cannot fetch it again" with "no longer has it".
  Future<void> _clearCachedDocuments() async {
    if (!_documentCache.existsSync()) return;
    for (final entity in _documentCache.listSync()) {
      try {
        entity.deleteSync(recursive: true);
      } on FileSystemException {
        // A file the OS is still holding must not abort the rest of the sweep;
        // stopping early would leave more behind than it removed.
        continue;
      }
    }
  }
}
