import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/models/document_model.dart';
import '../../../../core/models/saved_document_model.dart';
import '../../../../core/services/document_picker_service.dart';
import '../../../../core/services/document_storage_service.dart';
import '../../../../core/services/local_storage_service.dart';
import '../../../../core/services/permission_service.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/dialogs/permission_dialogs.dart';
import '../my_documents_screen.dart';
import 'privacy_consent_gate.dart';

/// Signature of [showAttachDocumentOptions], so widget tests can swap the
/// whole chooser out via [debugAttachDocumentOverride].
typedef AttachDocumentHandler =
    Future<DocumentModel?> Function(
      BuildContext context, {
      required String label,
    });

/// When set, [showAttachDocumentOptions] delegates to this instead of
/// showing the real sheet. Camera, gallery, and the system file picker all
/// need platform channels that are unavailable under `flutter test`, so
/// wizard tests install a handler that returns a fabricated document —
/// mirroring what `createMockDocument` did before these wizards moved to
/// real attachments. Never set this in production code.
@visibleForTesting
AttachDocumentHandler? debugAttachDocumentOverride;

/// Result of the "attach a document" chooser: either a freshly-picked
/// file (camera/gallery/files) or an existing "My Documents" item,
/// normalized to the same [DocumentModel] shape every permit upload slot
/// already expects, so it can be dropped straight into existing step
/// state without any other changes to that step.
Future<DocumentModel?> showAttachDocumentOptions(
  BuildContext context, {
  required String label,
}) async {
  final override = debugAttachDocumentOverride;
  if (override != null) return override(context, label: label);

  // Consent before collection, not after. Declining simply cancels the
  // attachment — it is not a dead end, and the applicant can agree next time.
  if (!await ensurePrivacyConsent(context)) return null;
  if (!context.mounted) return null;

  final choice = await showModalBottomSheet<_AttachSource>(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetContext) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(
                      AppConstants.borderRadiusPill,
                    ),
                  ),
                ),
              ),
              Text(
                'Attach $label',
                textAlign: TextAlign.center,
                style: AppTypography.cardTitle,
              ),
              const SizedBox(height: AppSpacing.sm),
              _AttachOptionTile(
                icon: Icons.camera_alt_outlined,
                label: 'Take Photo',
                onTap: () =>
                    Navigator.of(sheetContext).pop(_AttachSource.camera),
              ),
              _AttachOptionTile(
                icon: Icons.photo_library_outlined,
                label: 'Choose from Gallery',
                onTap: () =>
                    Navigator.of(sheetContext).pop(_AttachSource.gallery),
              ),
              _AttachOptionTile(
                icon: Icons.folder_open_outlined,
                label: 'Choose from Files',
                onTap: () =>
                    Navigator.of(sheetContext).pop(_AttachSource.files),
              ),
              _AttachOptionTile(
                icon: Icons.description_outlined,
                label: 'Choose from My Documents',
                onTap: () =>
                    Navigator.of(sheetContext).pop(_AttachSource.myDocuments),
              ),
              const SizedBox(height: AppSpacing.xs),
              _AttachOptionTile(
                icon: Icons.close,
                label: 'Cancel',
                onTap: () => Navigator.of(sheetContext).pop(),
              ),
            ],
          ),
        ),
      );
    },
  );

  if (choice == null || !context.mounted) return null;
  return _resolve(context, choice, label);
}

enum _AttachSource { camera, gallery, files, myDocuments }

Future<DocumentModel?> _resolve(
  BuildContext context,
  _AttachSource source,
  String label,
) async {
  final messenger = ScaffoldMessenger.of(context);
  void showMessage(String message) {
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }

  if (source == _AttachSource.myDocuments) {
    final selected = await Navigator.of(context).push<SavedDocumentModel>(
      MaterialPageRoute(
        builder: (_) => const MyDocumentsScreen(selectionMode: true),
      ),
    );
    if (selected == null) return null;
    return DocumentModel(
      id: selected.id,
      label: label,
      fileName: selected.name,
      uploadedAt: DateTime.now(),
      fileSizeBytes: selected.fileSizeBytes,
      filePath: selected.localPath,
    );
  }

  final permissionService = PermissionService();
  final pickerService = DocumentPickerService();
  final storageService = DocumentStorageService();

  if (source == _AttachSource.camera) {
    final status = await requestPermissionWithPriming(
      context,
      permissionService: permissionService,
      kind: AppPermissionKind.camera,
      primerTitle: cameraPermissionPrimerTitle,
      primerMessage: cameraPermissionPrimerMessage,
    );
    if (status != AppPermissionStatus.granted) {
      if (status == AppPermissionStatus.denied) {
        showMessage('Camera permission is required.');
      }
      return null;
    }
  } else if (source == _AttachSource.gallery) {
    final status = await requestPermissionWithPriming(
      context,
      permissionService: permissionService,
      kind: AppPermissionKind.photos,
      primerTitle: fileAccessPermissionPrimerTitle,
      primerMessage: fileAccessPermissionPrimerMessage,
      deniedMessage: fileAccessPermissionDeniedMessage,
      showPrimerOnlyOnce: true,
    );
    if (status != AppPermissionStatus.granted) {
      if (status == AppPermissionStatus.denied) {
        showMessage('Photo access is required.');
      }
      return null;
    }
  } else if (source == _AttachSource.files) {
    // The system file picker (Storage Access Framework on Android,
    // document picker on iOS) needs no runtime OS permission, but the
    // one-time privacy explanation still applies before the very first
    // file-selection attempt of any kind.
    final localStorage = LocalStorageService();
    if (!(await localStorage.isFileAccessPrimerShown())) {
      if (!context.mounted) return null;
      final agreed = await showPermissionPrimerDialog(
        context,
        title: fileAccessPermissionPrimerTitle,
        message: fileAccessPermissionPrimerMessage,
      );
      await localStorage.setFileAccessPrimerShown();
      if (!agreed) return null;
    }
  }

  final result = switch (source) {
    _AttachSource.camera => await pickerService.pickFromCamera(),
    _AttachSource.gallery => await pickerService.pickFromGallery(),
    _AttachSource.files => await pickerService.pickFromFiles(),
    _AttachSource.myDocuments => throw StateError('handled above'),
  };

  switch (result.outcome) {
    case DocumentPickOutcome.cancelled:
      showMessage('No document was selected.');
      return null;
    case DocumentPickOutcome.invalidFile:
      showMessage('Unsupported file format.');
      return null;
    case DocumentPickOutcome.error:
      showMessage('The selected file could not be opened.');
      return null;
    case DocumentPickOutcome.success:
      final picked = result.picked!;
      // Copied into the app's own directory rather than referenced where the
      // picker left it.
      //
      // `image_picker` and the system file picker both hand back a path in a
      // temporary container that the OS may reclaim WITHIN a session — an
      // applicant who attaches a photograph at step 3 of a nine-step wizard
      // and files at step 9 can lose it in between, and the failure would
      // arrive as "the file to upload could not be read" with nothing to
      // point at. It is also the precondition for queuing an upload: bytes
      // that may vanish cannot be retried later.
      //
      // The My Documents flow has always done this; the wizard attachments
      // did not.
      final File stored;
      try {
        stored = await storageService.saveCopy(
          picked.file,
          originalFileName: picked.originalFileName,
        );
      } on Exception {
        showMessage('The selected file could not be saved.');
        return null;
      }
      final size = await stored.length();
      return DocumentModel(
        id: 'doc-${DateTime.now().microsecondsSinceEpoch}',
        label: label,
        fileName: picked.originalFileName,
        uploadedAt: DateTime.now(),
        fileSizeBytes: size,
        filePath: stored.path,
      );
  }
}

class _AttachOptionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _AttachOptionTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
        child: Container(
          constraints: const BoxConstraints(
            minHeight: AppConstants.minTouchTarget,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Row(
            children: [
              Icon(icon, size: 22, color: AppColors.textSecondary),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: Text(label, style: AppTypography.body)),
            ],
          ),
        ),
      ),
    );
  }
}
