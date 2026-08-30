import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'draft_snapshot.dart';

/// Durable storage for unfinished applications.
///
/// **The keychain, not SharedPreferences.** A draft holds the applicant's
/// name, address, TIN and the names of their identity and ownership documents.
/// That is the same class of content the offline queue holds, and TAB 11
/// settled where it belongs — see `SecureQueueStore`, whose reasoning this
/// follows deliberately rather than inventing a second answer. M-01 and M-32
/// are the same argument applied to the session token and to the two columns
/// that store secrets unencrypted.
///
/// Document *bytes* are not here and never will be: [DraftSnapshot] drops the
/// file and keeps the label. A keychain is built for secrets, not for
/// megabytes of scanned plans, and would fail on size.
abstract class DraftStore {
  Future<Map<String, DraftSnapshot>> load();
  Future<void> save(Map<String, DraftSnapshot> drafts);
}

/// How long an abandoned draft is kept.
///
/// Ninety days rather than the queue's thirty. An applicant assembling a
/// building permit waits on a professional, a clearance and a notary, and a
/// draft untouched for a month is the normal shape of that task rather than
/// neglect — `DraftSummary.isIdle` already treats a week as merely worth a
/// nudge. It expires at all because a draft is personal data under RA 10173
/// and keeping it forever on a device is not minimisation; the applicant is
/// warned by the idle nudge long before anything is dropped.
const Duration draftRetention = Duration(days: 90);

/// Decodes a stored blob into snapshots, dropping what must not come back.
///
/// A free function rather than a method so it can be tested against real
/// input. The alternative — reaching it only through [SecureDraftStore] — would
/// mean mocking the keychain to test a rule that has nothing to do with the
/// keychain, and a rule tested only through a mock is a rule nobody has run.
Map<String, DraftSnapshot> decodeDrafts(String raw, {required DateTime now}) {
  if (raw.isEmpty) return {};
  final drafts = <String, DraftSnapshot>{};
  final Object? decoded;
  try {
    decoded = jsonDecode(raw);
  } on FormatException {
    // A corrupt store must not brick the app on every launch. Dropped rather
    // than retried forever.
    return {};
  }
  if (decoded is! Map) return {};
  for (final entry in decoded.entries) {
    final value = entry.value;
    if (value is! Map) continue;
    // Contained per record: one draft written by a release whose shape has
    // since changed must not take the other eighteen down with it.
    try {
      final snapshot = DraftSnapshot.fromJson(Map<String, Object?>.from(value));
      if (now.difference(snapshot.savedAt) <= draftRetention) {
        drafts['${entry.key}'] = snapshot;
      }
    } on FormatException {
      continue;
    } on TypeError {
      continue;
    }
  }
  return drafts;
}

String encodeDrafts(Map<String, DraftSnapshot> drafts) => jsonEncode({
  for (final entry in drafts.entries) entry.key: entry.value.toJson(),
});

class SecureDraftStore implements DraftStore {
  SecureDraftStore({FlutterSecureStorage? storage, DateTime Function()? clock})
    : _storage =
          storage ??
          const FlutterSecureStorage(
            iOptions: IOSOptions(
              accessibility: KeychainAccessibility.first_unlock_this_device,
              synchronizable: false,
            ),
          ),
      _clock = clock ?? DateTime.now;

  final FlutterSecureStorage _storage;
  final DateTime Function() _clock;

  /// Versioned in the key itself. A future shape change writes to
  /// `ebpco.drafts.v2` and leaves v1 to expire, rather than trying to migrate
  /// a record whose meaning changed.
  static const String storageKey = 'ebpco.drafts.v1';

  @override
  Future<Map<String, DraftSnapshot>> load() async =>
      decodeDrafts(await _storage.read(key: storageKey) ?? '', now: _clock());

  @override
  Future<void> save(Map<String, DraftSnapshot> drafts) =>
      _storage.write(key: storageKey, value: encodeDrafts(drafts));
}

class InMemoryDraftStore implements DraftStore {
  InMemoryDraftStore([Map<String, DraftSnapshot> initial = const {}])
    : _raw = encodeDrafts(initial);

  String _raw;

  @override
  Future<Map<String, DraftSnapshot>> load() async =>
      decodeDrafts(_raw, now: DateTime.now());

  @override
  Future<void> save(Map<String, DraftSnapshot> drafts) async {
    // Round-tripped through JSON so a value that does not serialise fails in a
    // test rather than on a device restart. The queue's in-memory store does
    // the same, for the same reason.
    _raw = encodeDrafts(drafts);
  }
}

/// Reads and writes one wizard's draft without any wizard knowing about the
/// other eighteen.
///
/// Serialised through a single chained future: the store keeps all drafts
/// under one key, so two wizards saving at once would otherwise each write a
/// map built before the other's change and one save would vanish.
class DraftPersistence {
  DraftPersistence(this._store);

  final DraftStore _store;
  Future<void> _queue = Future.value();

  Future<T> _serialise<T>(Future<T> Function() action) {
    final result = _queue.then((_) => action());
    _queue = result.then((_) {}, onError: (_) {});
    return result;
  }

  Future<DraftSnapshot?> read(String permitKey) =>
      _serialise(() async => (await _store.load())[permitKey]);

  Future<void> write(DraftSnapshot snapshot) => _serialise(() async {
    final drafts = await _store.load();
    drafts[snapshot.permitKey] = snapshot;
    await _store.save(drafts);
  });

  Future<void> remove(String permitKey) => _serialise(() async {
    final drafts = await _store.load();
    drafts.remove(permitKey);
    await _store.save(drafts);
  });
}
