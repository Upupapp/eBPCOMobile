import 'dart:io';

import '../services/document_storage_service.dart';

/// Supported file types for imported "My Documents" items — the same set
/// accepted by the import file picker.
enum SavedDocumentFileType { pdf, jpg, jpeg, png }

extension SavedDocumentFileTypeX on SavedDocumentFileType {
  String get label {
    switch (this) {
      case SavedDocumentFileType.pdf:
        return 'PDF';
      case SavedDocumentFileType.jpg:
        return 'JPG';
      case SavedDocumentFileType.jpeg:
        return 'JPEG';
      case SavedDocumentFileType.png:
        return 'PNG';
    }
  }

  bool get isImage => this != SavedDocumentFileType.pdf;

  static SavedDocumentFileType? fromExtension(String extension) {
    switch (extension.toLowerCase().replaceAll('.', '')) {
      case 'pdf':
        return SavedDocumentFileType.pdf;
      case 'jpg':
        return SavedDocumentFileType.jpg;
      case 'jpeg':
        return SavedDocumentFileType.jpeg;
      case 'png':
        return SavedDocumentFileType.png;
      default:
        return null;
    }
  }
}

/// User-facing document categories for organizing "My Documents". The user
/// always chooses (or confirms) a category — nothing is inferred from file
/// content, per the "do not auto-classify using sensitive data" rule.
enum SavedDocumentCategory {
  validGovernmentId,
  proofOfAddress,
  barangayClearance,
  businessRegistration,
  taxDocument,
  propertyDocument,
  authorizationLetter,
  supportingDocument,
  other,
  uncategorized,
}

extension SavedDocumentCategoryX on SavedDocumentCategory {
  String get label {
    switch (this) {
      case SavedDocumentCategory.validGovernmentId:
        return 'Valid Government ID';
      case SavedDocumentCategory.proofOfAddress:
        return 'Proof of Address';
      case SavedDocumentCategory.barangayClearance:
        return 'Barangay Clearance';
      case SavedDocumentCategory.businessRegistration:
        return 'Business Registration';
      case SavedDocumentCategory.taxDocument:
        return 'Tax Document';
      case SavedDocumentCategory.propertyDocument:
        return 'Property Document';
      case SavedDocumentCategory.authorizationLetter:
        return 'Authorization Letter';
      case SavedDocumentCategory.supportingDocument:
        return 'Supporting Document';
      case SavedDocumentCategory.other:
        return 'Other';
      case SavedDocumentCategory.uncategorized:
        return 'Uncategorized';
    }
  }
}

/// A document the user has imported into "My Documents" — persisted
/// locally (metadata as JSON, file bytes copied into app storage) so it
/// survives app restarts and can be reused across permit applications
/// without re-importing from the device file system each time.
class SavedDocumentModel {
  final String id;
  final String originalFileName;
  final String? displayName;

  /// The file's NAME inside the app's own document storage.
  ///
  /// **An absolute path is not durable and must not be persisted.** On iOS the
  /// app's container is `/var/mobile/Containers/Data/Application/<UUID>/…` and
  /// that UUID changes on every app update — so a path saved today is dead
  /// tomorrow while the file itself is untouched under a different prefix.
  ///
  /// This library stored the absolute path in SharedPreferences until 31
  /// August 2026. Every entry would have broken at the first app update:
  /// the list would still show the documents, and none of them would open.
  ///
  /// The draft snapshots learned this first; this is the same fix applied to
  /// the other place the app remembers a file.
  final String storedName;

  /// A path this entry already knows, used only when [storedName] cannot be
  /// resolved.
  ///
  /// Two things arrive here and both are fallbacks, never the record: the
  /// absolute path an entry saved before the migration carries, and the path
  /// the file was just copied to at import, before anything has asked the
  /// platform where the documents directory is. **Never written back to
  /// storage** — writing a path again is the defect this replaced.
  final String? knownPath;
  final SavedDocumentFileType fileType;
  final int fileSizeBytes;
  final DateTime dateImported;
  final DateTime? lastUsedDate;
  final SavedDocumentCategory category;

  /// When this document stops being accepted, if it is time-bound.
  ///
  /// Several requirements have a shelf life an applicant is unlikely to have
  /// memorised — a barangay clearance and a tax clearance are annual, a
  /// Certified True Copy of a title is commonly refused beyond six months,
  /// and a PRC ID lapses on its own date. Attaching an expired one gets the
  /// application returned, and the applicant pays for that in weeks.
  final DateTime? expiryDate;

  const SavedDocumentModel({
    required this.id,
    required this.originalFileName,
    this.displayName,
    required this.storedName,
    this.knownPath,
    required this.fileType,
    required this.fileSizeBytes,
    required this.dateImported,
    this.lastUsedDate,
    this.category = SavedDocumentCategory.uncategorized,
    this.expiryDate,
  });

  bool get isTimeBound => expiryDate != null;

  bool isExpired(DateTime asOf) {
    final expiry = expiryDate;
    if (expiry == null) return false;
    return _day(expiry).isBefore(_day(asOf));
  }

  /// Days until it lapses; negative once it has. Null when not time-bound.
  int? daysUntilExpiry(DateTime asOf) {
    final expiry = expiryDate;
    if (expiry == null) return null;
    return _day(expiry).difference(_day(asOf)).inDays;
  }

  /// Worth warning about — expired, or lapsing within 30 days.
  ///
  /// Thirty rather than sixty: unlike a PRC licence, most of these are
  /// re-obtained in a single visit, so warning too early would nag without
  /// giving the applicant anything useful to do.
  bool needsAttention(DateTime asOf) {
    final days = daysUntilExpiry(asOf);
    return days != null && days <= 30;
  }

  static DateTime _day(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  static String _basenameOf(String path) =>
      path.contains('/') ? path.substring(path.lastIndexOf('/') + 1) : path;

  /// The name shown throughout the UI — the custom display name when set,
  /// otherwise the original imported file name.
  String get name => (displayName != null && displayName!.trim().isNotEmpty)
      ? displayName!
      : originalFileName;

  /// Where the file is now.
  ///
  /// Resolved against the CURRENT documents directory every time it is asked
  /// for, rather than remembered. Falls back to the pre-migration path when
  /// the name cannot be resolved — which covers a test with no storage root,
  /// and an entry whose file has genuinely gone.
  String get localPath =>
      DocumentStorageService.resolveStoredName(storedName) ??
      knownPath ??
      storedName;

  /// False when the file is not where the name says. The list still shows the
  /// entry — an applicant is owed the difference between "you never imported
  /// this" and "it is no longer on this device".
  bool get fileExists =>
      DocumentStorageService.resolveStoredName(storedName) != null;

  File get file => File(localPath);

  SavedDocumentModel copyWith({
    String? displayName,
    DateTime? lastUsedDate,
    SavedDocumentCategory? category,
    DateTime? expiryDate,
    bool clearExpiryDate = false,
  }) {
    return SavedDocumentModel(
      id: id,
      originalFileName: originalFileName,
      displayName: displayName ?? this.displayName,
      storedName: storedName,
      knownPath: knownPath,
      fileType: fileType,
      fileSizeBytes: fileSizeBytes,
      dateImported: dateImported,
      expiryDate: clearExpiryDate ? null : (expiryDate ?? this.expiryDate),
      lastUsedDate: lastUsedDate ?? this.lastUsedDate,
      category: category ?? this.category,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'originalFileName': originalFileName,
    'displayName': displayName,
    // The name, never the path. See [storedName].
    'storedName': storedName,
    'fileType': fileType.name,
    'fileSizeBytes': fileSizeBytes,
    'dateImported': dateImported.toIso8601String(),
    'lastUsedDate': lastUsedDate?.toIso8601String(),
    'category': category.name,
    'expiryDate': expiryDate?.toIso8601String(),
  };

  factory SavedDocumentModel.fromJson(Map<String, dynamic> json) {
    return SavedDocumentModel(
      id: json['id'] as String,
      originalFileName: json['originalFileName'] as String,
      displayName: json['displayName'] as String?,
      // `localPath` is what entries saved before 31 August 2026 carry. Its
      // basename is the file's name in our own storage, so the migration is a
      // read-time one and needs no separate pass: the next save writes
      // `storedName` and the absolute path is never written again.
      storedName: json['storedName'] is String
          ? json['storedName'] as String
          : _basenameOf(json['localPath'] as String? ?? ''),
      knownPath: json['localPath'] as String?,
      fileType: SavedDocumentFileType.values.firstWhere(
        (t) => t.name == json['fileType'],
        orElse: () => SavedDocumentFileType.pdf,
      ),
      fileSizeBytes: json['fileSizeBytes'] as int,
      dateImported: DateTime.parse(json['dateImported'] as String),
      lastUsedDate: json['lastUsedDate'] != null
          ? DateTime.parse(json['lastUsedDate'] as String)
          : null,
      // Absent in documents saved before expiry tracking existed, which is
      // correct — an unknown expiry is not an expired one.
      expiryDate: json['expiryDate'] != null
          ? DateTime.parse(json['expiryDate'] as String)
          : null,
      category: SavedDocumentCategory.values.firstWhere(
        (c) => c.name == json['category'],
        orElse: () => SavedDocumentCategory.uncategorized,
      ),
    );
  }
}
