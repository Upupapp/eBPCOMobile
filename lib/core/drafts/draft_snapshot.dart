import '../models/document_model.dart';
import '../services/document_storage_service.dart';

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
  SnapshotWriter() : detachedDocuments = [];

  /// A row inside a collection. Shares the parent's detachment list, so a
  /// document held inside a repeated record is still named back to the
  /// applicant rather than vanishing with the row it sat in.
  SnapshotWriter._row(this.detachedDocuments);

  final Map<String, Object?> fields = {};
  final List<String> detachedDocuments;

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

  /// One record of a repeated collection. Written with the same accessors as
  /// the draft itself, and read back through a [SnapshotReader] over its own
  /// keys — so a row cannot drift from the rest of the format.
  SnapshotWriter row() => SnapshotWriter._row(detachedDocuments);

  /// A fixed-size or growable collection, as a list of rows.
  ///
  /// Every collection in these drafts is either keyed by an enum's values and
  /// pre-populated, or a short list the applicant adds to. Both restore by
  /// matching a key inside the row rather than by position, because a list
  /// index is not an identity — an enum reordered, or a row removed, would
  /// otherwise shift every value onto the wrong record.
  void rows(String path, List<SnapshotWriter> rows) =>
      fields[path] = [for (final row in rows) row.fields];

  /// Keeps an attachment if its bytes are somewhere durable, and records it
  /// as lost if they are not.
  ///
  /// **This used to drop every attachment**, and the reason was sound at the
  /// time: a `DocumentModel` carried a path into a file the picker had left in
  /// a temporary container the OS may reclaim, and persisting such a reference
  /// gives a draft that claims to hold a document it cannot open.
  ///
  /// Two things changed on 30 August 2026. Picked attachments are now copied
  /// into the app's own storage the moment they are chosen, so the bytes
  /// survive. And what is stored is the file's NAME rather than its path,
  /// because an absolute path into the app's container is not stable across an
  /// app update even though the file is.
  ///
  /// So: a file inside our storage is kept, by name. Anything else is dropped
  /// and named for the applicant to attach again — [label] must therefore read
  /// as the document's name, "Land Title", not "landTitleUpload".
  /// Every attachment the codec visited, in the order it visited them.
  ///
  /// **Added 31 August 2026, because nothing was collecting them.** The
  /// wizards gather a citizen's land title, survey plan and design plans, and
  /// `submitPermitApplication` passed `documents: const []` — so
  /// `_uploadAll` had nothing to upload and the office received an application
  /// with no documents at all. On a building permit that is twenty-four
  /// attachments the citizen watched themselves add.
  ///
  /// Collected here rather than in nineteen wizards because the codecs
  /// already visit every document field: that is how drafts persist them, and
  /// it is round-trip tested for every wizard.
  final List<DocumentModel> documents = [];

  void document(String path, DocumentModel? value, String label) {
    if (value == null) {
      fields[path] = null;
      return;
    }
    documents.add(value);
    final storedName = DocumentStorageService.storedNameOf(value.filePath);
    if (storedName == null) {
      // Bytes we cannot vouch for: a fabricated attachment with no file, or a
      // picker path from before attachments were copied.
      fields[path] = null;
      detachedDocuments.add(label);
      return;
    }
    fields[path] = {
      'id': value.id,
      'label': value.label,
      'fileName': value.fileName,
      'storedName': storedName,
      'uploadedAt': value.uploadedAt.toIso8601String(),
      'fileSizeBytes': value.fileSizeBytes,
      // Carried so the reader can name it if the file has gone missing since.
      'slotLabel': label,
    };
  }
}

/// Reads field values back, tolerating anything it does not recognise.
///
/// Every accessor falls back rather than throwing. A draft written by an older
/// release, or holding an enum value since renamed, must restore the fields it
/// still understands instead of failing whole — the applicant's alternative is
/// losing everything, which is the defect this class exists to end.
class SnapshotReader {
  SnapshotReader(this._fields) : unresolvedDocuments = [];

  /// A row inside a collection, sharing the parent's unresolved list.
  ///
  /// Without the sharing, an attachment held inside a repeated record — the
  /// demolition permit's per-utility disconnection proof, the applicant's own
  /// extra documents on a Certificate of Occupancy — would go missing without
  /// anyone being told, which is the one outcome this design refuses.
  SnapshotReader._row(this._fields, this.unresolvedDocuments);

  final Map<String, Object?> _fields;

  /// Attachments this snapshot held and could not give back.
  ///
  /// Filled as [document] is called, so it reflects the state of the device
  /// NOW rather than at save time — a file present when the draft was saved
  /// and cleared since is named here, which is the case a capture-time list
  /// gets wrong.
  final List<String> unresolvedDocuments;

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

  /// A whole number. `int` and `double` both survive JSON, but a `double`
  /// that happens to be integral comes back as an `int`, so both are accepted.
  int integer(String path, {int fallback = 0}) {
    final value = _fields[path];
    return value is int ? value : (value is double ? value.toInt() : fallback);
  }

  int? nullableInteger(String path) {
    final value = _fields[path];
    return value is int ? value : (value is double ? value.toInt() : null);
  }

  double decimal(String path, {double fallback = 0}) =>
      nullableDecimal(path) ?? fallback;

  double? nullableDecimal(String path) {
    final value = _fields[path];
    return value is num ? value.toDouble() : null;
  }

  /// The records of a repeated collection, each read exactly as the draft is.
  List<SnapshotReader> rows(String path) {
    final raw = _fields[path];
    if (raw is! List) return const [];
    return [
      for (final row in raw)
        if (row is Map)
          SnapshotReader._row(
            Map<String, Object?>.from(row),
            unresolvedDocuments,
          ),
    ];
  }

  /// An attachment, if its file is still where the snapshot said.
  ///
  /// Null when the record is absent — the attachment was never kept — or when
  /// the file has gone. In the second case the slot's label is added to
  /// [unresolvedDocuments], because an applicant whose document vanished
  /// between saving and resuming is owed the same sentence as one whose
  /// attachment was never persisted.
  DocumentModel? document(String path) {
    final raw = _fields[path];
    if (raw is! Map) return null;
    final record = Map<String, Object?>.from(raw);
    final resolved = DocumentStorageService.resolveStoredName(
      record['storedName'] as String?,
    );
    if (resolved == null) {
      final label = record['slotLabel'] ?? record['label'];
      if (label is String) unresolvedDocuments.add(label);
      return null;
    }
    return DocumentModel(
      id: record['id'] is String ? record['id'] as String : path,
      label: record['label'] is String ? record['label'] as String : '',
      fileName: record['fileName'] is String
          ? record['fileName'] as String
          : '',
      uploadedAt:
          DateTime.tryParse('${record['uploadedAt']}') ?? DateTime.now(),
      fileSizeBytes: record['fileSizeBytes'] is int
          ? record['fileSizeBytes'] as int
          : null,
      filePath: resolved,
    );
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
