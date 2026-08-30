import '../models/document_model.dart';

/// A wizard draft reduced to the part that can honestly be written to disk.
///
/// M-48. Nineteen wizards offer **Save as Draft** and, until this landed,
/// nothing reached disk: every draft lived in a `ChangeNotifier` and died with
/// the process, losing up to nine steps of typing. `docs/SCOPING-M-48-draft-
/// persistence.md` measured the alternatives and recommended persisting the
/// resumable core rather than the whole 2,624-field object graph.
///
/// **Where the line is drawn, and why it is drawn there.** Everything a draft
/// holds is persisted EXCEPT [DocumentModel] slots. That is a sharper boundary
/// than the scoping note's "scalars only", and it is drawn at a reason rather
/// than at a size: a `DocumentModel` carries a `filePath` into a file the
/// applicant picked, and a path captured before a restart is not reliably
/// readable after one — iOS in particular hands out paths into a temporary
/// container that the OS may reclaim. Persisting such a reference would trade
/// one silent loss for a worse one: a draft that claims to hold a document it
/// cannot open. So the file is dropped and the applicant is TOLD, by name,
/// which documents to re-attach — see [detachedDocuments].
///
/// Enforced by `test/architecture/draft_snapshot_completeness_test.dart`:
/// every field on a persisted draft class is either captured here or exempted
/// there with a reason.
class DraftSnapshot {
  /// Which wizard this belongs to. Stable across releases — it is the storage
  /// key, so renaming it orphans every draft on every device.
  final String permitKey;

  /// The step the applicant had reached, zero-based, as the wizard counts.
  final int step;

  final DateTime savedAt;

  /// Field values under dotted paths — `applicant.firstName`. Flat rather than
  /// nested so the completeness gate can match a key's last segment against a
  /// declared field name without walking a tree.
  final Map<String, Object?> fields;

  /// The human labels of document slots that held a file when this was saved.
  ///
  /// Not paths. The point is to be able to say *"you had attached the Land
  /// Title — please attach it again"*, which is the whole of the honesty this
  /// design rests on.
  final List<String> detachedDocuments;

  const DraftSnapshot({
    required this.permitKey,
    required this.step,
    required this.savedAt,
    required this.fields,
    this.detachedDocuments = const [],
  });

  Map<String, Object?> toJson() => {
    'permitKey': permitKey,
    'step': step,
    'savedAt': savedAt.toIso8601String(),
    'fields': fields,
    'detachedDocuments': detachedDocuments,
  };

  /// Throws [FormatException] on anything it cannot read, so a corrupt record
  /// is dropped by the store rather than half-restored into a wizard.
  factory DraftSnapshot.fromJson(Map<String, Object?> json) {
    final key = json['permitKey'];
    final savedAt = json['savedAt'];
    if (key is! String || savedAt is! String) {
      throw const FormatException('draft snapshot is missing its identity');
    }
    final parsed = DateTime.tryParse(savedAt);
    if (parsed == null) throw FormatException('savedAt: $savedAt');
    return DraftSnapshot(
      permitKey: key,
      step: json['step'] is int ? json['step'] as int : 0,
      savedAt: parsed,
      fields: Map<String, Object?>.from(
        (json['fields'] as Map?) ?? const <String, Object?>{},
      ),
      detachedDocuments: List<String>.from(
        (json['detachedDocuments'] as List?) ?? const <String>[],
      ),
    );
  }
}

/// Turns one wizard's draft into a [DraftSnapshot] and back.
///
/// One implementation per wizard. Hand-written rather than generated: the
/// draft classes are mutable with field initialisers and no all-field
/// constructors, so `json_serializable` would mean restructuring all nineteen
/// wizards and every step widget that mutates them — the largest blast radius
/// of the four options measured, for a mechanical gain the completeness gate
/// already provides.
abstract class DraftCodec<T> {
  const DraftCodec();

  /// Stable storage key. See [DraftSnapshot.permitKey].
  String get permitKey;

  /// How the Drafts list names this permit.
  String get permitLabel;

  void capture(T draft, SnapshotWriter out);
  void restore(T draft, SnapshotReader input);

  DraftSnapshot snapshot(T draft, {required int step, DateTime? savedAt}) {
    final writer = SnapshotWriter();
    capture(draft, writer);
    return DraftSnapshot(
      permitKey: permitKey,
      step: step,
      savedAt: savedAt ?? DateTime.now(),
      fields: writer.fields,
      detachedDocuments: writer.detachedDocuments,
    );
  }

  void apply(T draft, DraftSnapshot snapshot) =>
      restore(draft, SnapshotReader(snapshot.fields));
}

/// Collects field values under dotted paths.
class SnapshotWriter {
  final Map<String, Object?> fields = {};
  final List<String> detachedDocuments = [];

  /// A `String`, `bool`, `int` or `double`. Nulls are written, because a
  /// nullable field that the applicant deliberately cleared is not the same as
  /// one never touched, and only the first survives a round trip.
  void scalar(String path, Object? value) => fields[path] = value;

  void date(String path, DateTime? value) =>
      fields[path] = value?.toIso8601String();

  /// Stored by `name`, never by index. An enum reordered between releases
  /// would silently move every stored value one place along.
  void enumValue(String path, Enum? value) => fields[path] = value?.name;

  void enumSet(String path, Iterable<Enum> values) =>
      fields[path] = values.map((v) => v.name).toList();

  void strings(String path, Iterable<String> values) =>
      fields[path] = values.toList();

  /// Records that a slot held a file, and drops the file.
  ///
  /// [label] is what the applicant will be asked to re-attach, so it must read
  /// as the document's name — "Land Title", not "landTitleUpload".
  void document(String path, DocumentModel? value, String label) {
    if (value != null) detachedDocuments.add(label);
  }
}

/// Reads field values back, tolerating anything it does not recognise.
///
/// Every accessor falls back rather than throwing. A draft written by an older
/// release, or holding an enum value since renamed, must restore the fields it
/// still understands instead of failing whole — the applicant's alternative is
/// losing everything, which is the defect this class exists to end.
class SnapshotReader {
  const SnapshotReader(this._fields);

  final Map<String, Object?> _fields;

  bool has(String path) => _fields.containsKey(path);

  String string(String path, {String fallback = ''}) {
    final value = _fields[path];
    return value is String ? value : fallback;
  }

  /// For a `String?` field, where "never entered" and "entered then cleared"
  /// are different states the applicant can tell apart.
  String? nullableString(String path) {
    final value = _fields[path];
    return value is String ? value : null;
  }

  bool boolean(String path, {bool fallback = false}) {
    final value = _fields[path];
    return value is bool ? value : fallback;
  }

  bool? nullableBoolean(String path) {
    final value = _fields[path];
    return value is bool ? value : null;
  }

  DateTime? date(String path) {
    final value = _fields[path];
    return value is String ? DateTime.tryParse(value) : null;
  }

  T? enumValue<T extends Enum>(String path, List<T> values) {
    final value = _fields[path];
    if (value is! String) return null;
    for (final candidate in values) {
      if (candidate.name == value) return candidate;
    }
    return null;
  }

  Set<T> enumSet<T extends Enum>(
    String path,
    List<T> values, {
    Set<T> fallback = const {},
  }) {
    final raw = _fields[path];
    if (raw is! List) return fallback;
    final restored = <T>{};
    for (final name in raw) {
      for (final candidate in values) {
        if (candidate.name == name) restored.add(candidate);
      }
    }
    // An empty list is a real state — the applicant cleared every option — but
    // a list whose every name was dropped is not, so the fallback stands only
    // when nothing was stored at all.
    return raw.isEmpty ? <T>{} : (restored.isEmpty ? fallback : restored);
  }
}
