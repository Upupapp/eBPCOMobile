import 'dart:io';

import 'scan_mode.dart';

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
  fireSafety,
  engineering,
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
      case SavedDocumentCategory.fireSafety:
        return 'Fire Safety';
      case SavedDocumentCategory.engineering:
        return 'Engineering';
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
  final String localPath;
  final SavedDocumentFileType fileType;
  final int fileSizeBytes;
  final DateTime dateImported;
  final DateTime? lastUsedDate;
  final SavedDocumentCategory category;
  final String? notes;

  /// Whether this document came from the built-in scanner rather than an
  /// imported file — drives the "Scanned" badge and the fields below.
  final bool isScanned;
  final ScanMode? scanMode;
  final int pageCount;
  final String? thumbnailPath;

  const SavedDocumentModel({
    required this.id,
    required this.originalFileName,
    this.displayName,
    required this.localPath,
    required this.fileType,
    required this.fileSizeBytes,
    required this.dateImported,
    this.lastUsedDate,
    this.category = SavedDocumentCategory.uncategorized,
    this.notes,
    this.isScanned = false,
    this.scanMode,
    this.pageCount = 1,
    this.thumbnailPath,
  });

  /// The name shown throughout the UI — the custom display name when set,
  /// otherwise the original imported file name.
  String get name =>
      (displayName != null && displayName!.trim().isNotEmpty)
      ? displayName!
      : originalFileName;

  File get file => File(localPath);

  File? get thumbnailFile => thumbnailPath != null ? File(thumbnailPath!) : null;

  SavedDocumentModel copyWith({
    String? displayName,
    DateTime? lastUsedDate,
    SavedDocumentCategory? category,
    String? notes,
  }) {
    return SavedDocumentModel(
      id: id,
      originalFileName: originalFileName,
      displayName: displayName ?? this.displayName,
      localPath: localPath,
      fileType: fileType,
      fileSizeBytes: fileSizeBytes,
      dateImported: dateImported,
      lastUsedDate: lastUsedDate ?? this.lastUsedDate,
      category: category ?? this.category,
      notes: notes ?? this.notes,
      isScanned: isScanned,
      scanMode: scanMode,
      pageCount: pageCount,
      thumbnailPath: thumbnailPath,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'originalFileName': originalFileName,
    'displayName': displayName,
    'localPath': localPath,
    'fileType': fileType.name,
    'fileSizeBytes': fileSizeBytes,
    'dateImported': dateImported.toIso8601String(),
    'lastUsedDate': lastUsedDate?.toIso8601String(),
    'category': category.name,
    'notes': notes,
    'isScanned': isScanned,
    'scanMode': scanMode?.name,
    'pageCount': pageCount,
    'thumbnailPath': thumbnailPath,
  };

  factory SavedDocumentModel.fromJson(Map<String, dynamic> json) {
    return SavedDocumentModel(
      id: json['id'] as String,
      originalFileName: json['originalFileName'] as String,
      displayName: json['displayName'] as String?,
      localPath: json['localPath'] as String,
      fileType: SavedDocumentFileType.values.firstWhere(
        (t) => t.name == json['fileType'],
        orElse: () => SavedDocumentFileType.pdf,
      ),
      fileSizeBytes: json['fileSizeBytes'] as int,
      dateImported: DateTime.parse(json['dateImported'] as String),
      lastUsedDate: json['lastUsedDate'] != null
          ? DateTime.parse(json['lastUsedDate'] as String)
          : null,
      category: SavedDocumentCategory.values.firstWhere(
        (c) => c.name == json['category'],
        orElse: () => SavedDocumentCategory.uncategorized,
      ),
      notes: json['notes'] as String?,
      isScanned: json['isScanned'] as bool? ?? false,
      scanMode: json['scanMode'] != null
          ? ScanMode.values.firstWhere(
              (m) => m.name == json['scanMode'],
              orElse: () => ScanMode.defaultMode,
            )
          : null,
      pageCount: json['pageCount'] as int? ?? 1,
      thumbnailPath: json['thumbnailPath'] as String?,
    );
  }
}
